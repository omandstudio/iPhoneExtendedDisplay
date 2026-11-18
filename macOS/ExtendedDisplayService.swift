import Foundation
import CoreGraphics
import CoreMedia

public class ExtendedDisplayService: NetworkServerDelegate, H264EncoderDelegate, ScreenCaptureManagerDelegate, WebServerDelegate {
    private let virtualDisplayManager = VirtualDisplayManager()
    private let screenCaptureManager = ScreenCaptureManager()
    private let encoder = H264Encoder()
    private let server = NetworkServer()
    private let webServer = WebServer()
    private let inputInjector = InputInjector()
    
    private var isStreaming = false
    private var fpsCounter = 0
    private var lastFpsTime: CFAbsoluteTime = 0
    
    public init() {
        server.delegate = self
        webServer.delegate = self
        encoder.delegate = self
        screenCaptureManager.delegate = self
    }
    
    public func start() {
        print("==================================================")
        print("🚀 iPhone Extended Display (by omandstudio)")
        print("==================================================")
        
        let webPort: UInt16 = 8080
        AppState.shared.port = webPort
        AppState.shared.isServerRunning = true
        
        // 1. Start Native TCP Listener (port 7789)
        _ = server.start(port: 7789)
        
        // 2. Start Web Receiver Server (port 8080 for Safari on iPhone)
        _ = webServer.start(port: webPort)
        
        print("")
        print("📱 AKSES DI SAFARI IPHONE XR:")
        print("   👉 Kabel USB : http://\(AppState.shared.usbIP):\(webPort)")
        print("   👉 Wi-Fi    : http://\(AppState.shared.wifiIP):\(webPort)")
        print("==================================================")
    }
    
    public func stop() {
        print("[Service] 🛑 Stopping Extended Display Service...")
        screenCaptureManager.stopCapture()
        virtualDisplayManager.destroyDisplay()
        server.stop()
        webServer.stop()
        isStreaming = false
        DispatchQueue.main.async {
            AppState.shared.isServerRunning = false
            AppState.shared.isDeviceConnected = false
            AppState.shared.connectedDeviceName = "Layanan Dimatikan"
        }
    }
    
    // MARK: - WebServerDelegate (iPhone Safari)
    public func webServer(_ server: WebServer, didClientHandshake width: UInt32, height: UInt32, scale: Double) {
        print("[Service] 🌐 Safari Handshake received! Setting up display for iPhone...")
        
        DispatchQueue.main.async {
            AppState.shared.isDeviceConnected = true
            AppState.shared.connectedDeviceName = "iPhone (\(width)x\(height) @\(scale)x)"
        }
        
        let targetWidth = width > 0 ? width * (scale >= 2.0 ? 2 : 1) : 1792
        let targetHeight = height > 0 ? height * (scale >= 2.0 ? 2 : 1) : 828
        let fps = AppState.shared.targetFps
        
        setupDisplayAndCapture(targetWidth: targetWidth, targetHeight: targetHeight, fps: fps, isHiDPI: scale >= 2.0)
        
        // Immediately force an initial frame capture to send to iPhone Safari
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.screenCaptureManager.forceCaptureFrame()
        }
    }
    
    public func webServer(_ server: WebServer, didReceiveTouch phase: UInt8, x: Double, y: Double, isRightClick: Bool) {
        let packet = TouchPacket(phase: phase, normalizedX: x, normalizedY: y, touchId: 0, isRightClick: isRightClick)
        inputInjector.handleTouch(packet: packet)
    }
    
    public func webServerClientDidDisconnect(_ server: WebServer) {
        print("[Service] 🌐 Safari client disconnected.")
        DispatchQueue.main.async {
            AppState.shared.isDeviceConnected = false
            AppState.shared.connectedDeviceName = "Belum ada perangkat terhubung"
        }
    }
    
    // MARK: - NetworkServerDelegate (Native iOS App)
    public func server(_ server: NetworkServer, didReceiveHandshake handshake: DeviceHandshake) {
        print("[Service] Processing handshake from \(handshake.deviceName)...")
        
        DispatchQueue.main.async {
            AppState.shared.isDeviceConnected = true
            AppState.shared.connectedDeviceName = "\(handshake.deviceName) (\(handshake.model))"
        }
        
        let targetWidth = UInt32(handshake.screenWidth * (handshake.scaleFactor >= 2.0 ? 2.0 : 1.0))
        let targetHeight = UInt32(handshake.screenHeight * (handshake.scaleFactor >= 2.0 ? 2.0 : 1.0))
        let fps = AppState.shared.targetFps
        
        setupDisplayAndCapture(targetWidth: targetWidth, targetHeight: targetHeight, fps: fps, isHiDPI: handshake.scaleFactor >= 2.0)
        
        // Send Ack to native app
        self.server.sendHandshakeAck(
            displayID: self.virtualDisplayManager.displayID != 0 ? self.virtualDisplayManager.displayID : CGMainDisplayID(),
            width: targetWidth,
            height: targetHeight,
            fps: fps
        )
    }
    
    private func setupDisplayAndCapture(targetWidth: UInt32, targetHeight: UInt32, fps: Int, isHiDPI: Bool) {
        var activeDisplayID: CGDirectDisplayID = 0
        
        if AppState.shared.displayMode == "extended" {
            // Try to create dedicated Virtual Display
            let created = virtualDisplayManager.createDisplay(
                width: targetWidth,
                height: targetHeight,
                name: "iPhone Extended Display",
                refreshRate: Double(fps),
                hiDPI: isHiDPI
            )
            
            if created && virtualDisplayManager.displayID != 0 {
                activeDisplayID = virtualDisplayManager.displayID
                print("[Service] ✅ Dedicated Virtual Display active! ID: \(activeDisplayID)")
            } else {
                print("[Service] ⚠️ CGVirtualDisplay unavailable in current context. Falling back to Main Display (Mirror Mode)...")
                activeDisplayID = CGMainDisplayID()
            }
        } else {
            // Mirror mode selected
            activeDisplayID = CGMainDisplayID()
            print("[Service] Mirror Mode selected. Display ID: \(activeDisplayID)")
        }
        
        inputInjector.setTargetDisplay(displayID: activeDisplayID)
        
        // Setup H.264 Encoder (for native client)
        _ = encoder.setup(
            width: Int32(targetWidth),
            height: Int32(targetHeight),
            fps: Int32(fps),
            bitrateKbps: 8000
        )
        
        // Start Screen Capture via ScreenCaptureKit
        let displayToCapture = activeDisplayID
        Task {
            do {
                try await self.screenCaptureManager.startCapture(
                    displayID: displayToCapture,
                    width: Int(targetWidth),
                    height: Int(targetHeight),
                    fps: fps
                )
                self.isStreaming = true
                self.lastFpsTime = CFAbsoluteTimeGetCurrent()
                print("[Service] 📺 Virtual monitor streaming is LIVE to iPhone!")
            } catch {
                print("[Service] Error starting screen capture: \(error)")
            }
        }
    }
    
    public func server(_ server: NetworkServer, didReceiveTouch packet: TouchPacket) {
        inputInjector.handleTouch(packet: packet)
    }
    
    public func serverClientDidDisconnect(_ server: NetworkServer) {
        print("[Service] ⚠️ Native client disconnected.")
        DispatchQueue.main.async {
            AppState.shared.isDeviceConnected = false
            AppState.shared.connectedDeviceName = "Belum ada perangkat terhubung"
        }
    }
    
    // MARK: - ScreenCaptureManagerDelegate
    public func captureManager(_ manager: ScreenCaptureManager, didCapturePixelBuffer pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        encoder.encode(pixelBuffer: pixelBuffer, timestamp: timestamp)
        webServer.sendFrame(pixelBuffer: pixelBuffer)
        
        fpsCounter += 1
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastFpsTime >= 1.0 {
            let measuredFps = fpsCounter
            fpsCounter = 0
            lastFpsTime = now
            DispatchQueue.main.async {
                AppState.shared.fps = measuredFps
            }
        }
    }
    
    public func captureManager(_ manager: ScreenCaptureManager, didCaptureCGImage cgImage: CGImage) {
        webServer.sendFrame(cgImage: cgImage)
    }
    
    public func captureManagerDidFailPermission(_ manager: ScreenCaptureManager) {
        DispatchQueue.main.async {
            AppState.shared.hasScreenPermission = false
        }
        webServer.sendTextMessage("{\"type\": \"permission_needed\"}")
    }
    
    // MARK: - H264EncoderDelegate
    public func encoder(_ encoder: H264Encoder, didOutputParameterSets sps: Data, pps: Data) {
        server.sendVideoConfig(sps: sps, pps: pps)
    }
    
    public func encoder(_ encoder: H264Encoder, didOutputFrame data: Data, isKeyframe: Bool, timestampUs: UInt64) {
        server.sendVideoFrame(data: data, isKeyframe: isKeyframe, timestampUs: timestampUs)
    }
}
