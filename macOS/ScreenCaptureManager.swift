import Foundation
import ScreenCaptureKit
import CoreMedia
import CoreGraphics
import CoreVideo

public protocol ScreenCaptureManagerDelegate: AnyObject {
    func captureManager(_ manager: ScreenCaptureManager, didCapturePixelBuffer pixelBuffer: CVPixelBuffer, timestamp: CMTime)
    func captureManager(_ manager: ScreenCaptureManager, didCaptureCGImage cgImage: CGImage)
    func captureManagerDidFailPermission(_ manager: ScreenCaptureManager)
}

public extension ScreenCaptureManagerDelegate {
    func captureManager(_ manager: ScreenCaptureManager, didCaptureCGImage cgImage: CGImage) {}
    func captureManagerDidFailPermission(_ manager: ScreenCaptureManager) {}
}

public class ScreenCaptureManager: NSObject, SCStreamOutput, SCStreamDelegate {
    public weak var delegate: ScreenCaptureManagerDelegate?
    
    private var stream: SCStream?
    private var isCapturing = false
    private let captureQueue = DispatchQueue(label: "com.openextended.captureQueue", qos: .userInteractive)
    
    private var fallbackTimer: DispatchSourceTimer?
    private var idleWatchdogTimer: DispatchSourceTimer?
    private var lastFrameTime: CFAbsoluteTime = 0
    private var targetDisplayID: CGDirectDisplayID = 0
    private var permissionPollTimer: Timer?
    
    public override init() {
        super.init()
    }
    
    public func checkAndRequestPermission() -> Bool {
        let hasAccess = CGPreflightScreenCaptureAccess()
        if !hasAccess {
            print("================================================================")
            print("⚠️  IZIN DIPERLUKAN: SCREEN RECORDING (PEREKAMAN LAYAR)")
            print("   macOS memblokir pembacaan layar untuk aplikasi ini.")
            print("   👉 Buka System Settings > Privacy & Security > Screen Recording")
            print("   👉 Berikan centang / Aktifkan untuk 'Terminal'")
            print("================================================================")
            _ = CGRequestScreenCaptureAccess()
            delegate?.captureManagerDidFailPermission(self)
            return false
        }
        return true
    }
    
    public func startCapture(displayID: CGDirectDisplayID, width: Int, height: Int, fps: Int = 60) async throws {
        stopCapture()
        self.targetDisplayID = displayID
        
        // 1. Verify TCC Screen Recording Permission FIRST to prevent assertions
        guard checkAndRequestPermission() else {
            print("[Capture] Waiting for user to grant Screen Recording permission in System Settings...")
            return
        }
        
        // 2. Try ScreenCaptureKit (Modern macOS 13+)
        do {
            print("[Capture] Starting ScreenCaptureKit stream for display \(displayID)...")
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            let targetDisplay = content.displays.first(where: { $0.displayID == displayID }) ?? content.displays.first
            guard let display = targetDisplay else {
                throw NSError(domain: "ScreenCaptureManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "No display found"])
            }
            
            let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
            
            let config = SCStreamConfiguration()
            config.width = (width / 2) * 2
            config.height = (height / 2) * 2
            config.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(fps))
            config.pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            config.showsCursor = true
            config.queueDepth = 3
            
            let newStream = SCStream(filter: filter, configuration: config, delegate: self)
            try newStream.addStreamOutput(self, type: .screen, sampleHandlerQueue: captureQueue)
            
            try await newStream.startCapture()
            self.stream = newStream
            self.isCapturing = true
            self.lastFrameTime = CFAbsoluteTimeGetCurrent()
            self.startIdleWatchdog()
            print("[Capture] ✅ ScreenCaptureKit active on display \(display.displayID) (\(config.width)x\(config.height) @ \(fps)fps)")
            
            // Immediately force an initial frame capture
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.forceCaptureFrame()
            }
        } catch {
            print("[Capture] ⚠️ ScreenCaptureKit failed (\(error.localizedDescription)). Using CoreGraphics fallback...")
            startFallbackCapture(displayID: displayID, fps: fps)
        }
    }
    
    public func forceCaptureFrame() {
        guard CGPreflightScreenCaptureAccess() else { return }
        let id = self.targetDisplayID != 0 ? self.targetDisplayID : CGMainDisplayID()
        if let image = CGDisplayCreateImage(id) {
            self.lastFrameTime = CFAbsoluteTimeGetCurrent()
            self.delegate?.captureManager(self, didCaptureCGImage: image)
        }
    }
    
    private func startIdleWatchdog() {
        idleWatchdogTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: captureQueue)
        timer.schedule(deadline: .now() + 0.5, repeating: 0.5)
        timer.setEventHandler { [weak self] in
            guard let self = self, self.isCapturing else { return }
            let now = CFAbsoluteTimeGetCurrent()
            if now - self.lastFrameTime >= 0.8 {
                self.forceCaptureFrame()
            }
        }
        timer.resume()
        self.idleWatchdogTimer = timer
    }
    
    private func startFallbackCapture(displayID: CGDirectDisplayID, fps: Int) {
        guard CGPreflightScreenCaptureAccess() else {
            print("[Capture] CoreGraphics capture skipped: Screen Recording permission missing.")
            return
        }
        
        let timer = DispatchSource.makeTimerSource(queue: captureQueue)
        let interval = 1.0 / Double(fps > 0 ? fps : 30)
        timer.schedule(deadline: .now(), repeating: interval)
        
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.forceCaptureFrame()
        }
        
        timer.resume()
        self.fallbackTimer = timer
        self.isCapturing = true
        print("[Capture] ✅ CoreGraphics capture timer active at \(fps) FPS.")
    }
    
    public func stopCapture() {
        idleWatchdogTimer?.cancel()
        idleWatchdogTimer = nil
        
        fallbackTimer?.cancel()
        fallbackTimer = nil
        
        if isCapturing, let activeStream = stream {
            activeStream.stopCapture { _ in }
            self.stream = nil
        }
        self.isCapturing = false
    }
    
    // MARK: - SCStreamOutput
    public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen,
              let imageBuffer = sampleBuffer.imageBuffer,
              CMSampleBufferIsValid(sampleBuffer) else {
            return
        }
        
        self.lastFrameTime = CFAbsoluteTimeGetCurrent()
        let pts = sampleBuffer.presentationTimeStamp
        delegate?.captureManager(self, didCapturePixelBuffer: imageBuffer, timestamp: pts)
    }
    
    // MARK: - SCStreamDelegate
    public func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("[Capture] SCStream stopped: \(error.localizedDescription)")
        isCapturing = false
        if CGPreflightScreenCaptureAccess() {
            startFallbackCapture(displayID: targetDisplayID, fps: 30)
        }
    }
}
