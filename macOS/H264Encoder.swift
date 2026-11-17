import Foundation
import VideoToolbox
import CoreMedia

public protocol H264EncoderDelegate: AnyObject {
    func encoder(_ encoder: H264Encoder, didOutputParameterSets sps: Data, pps: Data)
    func encoder(_ encoder: H264Encoder, didOutputFrame data: Data, isKeyframe: Bool, timestampUs: UInt64)
}

public class H264Encoder {
    public weak var delegate: H264EncoderDelegate?
    
    private var compressionSession: VTCompressionSession?
    private var width: Int32 = 0
    private var height: Int32 = 0
    private var frameIndex: Int64 = 0
    private var hasSentParameterSets = false
    
    public init() {}
    
    public func setup(width: Int32, height: Int32, fps: Int32 = 60, bitrateKbps: Int32 = 6000) -> Bool {
        teardown()
        
        self.width = width
        self.height = height
        self.frameIndex = 0
        self.hasSentParameterSets = false
        
        let attributes: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferMetalCompatibilityKey: true
        ]
        
        let callback: VTCompressionOutputCallback = { outputCallbackRefCon, sourceFrameRefCon, status, infoFlags, sampleBuffer in
            guard status == noErr, let sampleBuffer = sampleBuffer, let refCon = outputCallbackRefCon else {
                return
            }
            let encoder = Unmanaged<H264Encoder>.fromOpaque(refCon).takeUnretainedValue()
            encoder.handleSampleBuffer(sampleBuffer)
        }
        
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: width,
            height: height,
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: attributes as CFDictionary,
            compressedDataAllocator: nil,
            outputCallback: callback,
            refcon: Unmanaged.passUnretained(self).toOpaque(),
            compressionSessionOut: &compressionSession
        )
        
        guard status == noErr, let session = compressionSession else {
            print("[Encoder] Error: VTCompressionSessionCreate failed with status \(status)")
            return false
        }
        
        // Low-latency streaming properties
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Main_AutoLevel)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AverageBitRate, value: (bitrateKbps * 1000) as CFNumber)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_DataRateLimits, value: [bitrateKbps * 1000 / 8, 1] as CFArray)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: fps as CFNumber)
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: (fps * 2) as CFNumber) // Keyframe every 2s
        VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
        
        VTCompressionSessionPrepareToEncodeFrames(session)
        print("[Encoder] ✅ H.264 Encoder initialized (\(width)x\(height) @ \(fps)fps, \(bitrateKbps) kbps)")
        return true
    }
    
    public func encode(pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        guard let session = compressionSession else { return }
        
        frameIndex += 1
        var flagsOut: VTEncodeInfoFlags = []
        
        let status = VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: pixelBuffer,
            presentationTimeStamp: timestamp,
            duration: .invalid,
            frameProperties: nil,
            sourceFrameRefcon: nil,
            infoFlagsOut: &flagsOut
        )
        
        if status != noErr {
            print("[Encoder] Error encoding frame \(frameIndex): status \(status)")
        }
    }
    
    private func handleSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
        
        // 1. Extract SPS/PPS on first keyframe or format description change
        if !hasSentParameterSets {
            var spsSize: Int = 0
            var spsCount: Int = 0
            var spsPointer: UnsafePointer<UInt8>?
            
            var ppsSize: Int = 0
            var ppsCount: Int = 0
            var ppsPointer: UnsafePointer<UInt8>?
            
            let spsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
                formatDescription,
                parameterSetIndex: 0,
                parameterSetPointerOut: &spsPointer,
                parameterSetSizeOut: &spsSize,
                parameterSetCountOut: &spsCount,
                nalUnitHeaderLengthOut: nil
            )
            
            let ppsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
                formatDescription,
                parameterSetIndex: 1,
                parameterSetPointerOut: &ppsPointer,
                parameterSetSizeOut: &ppsSize,
                parameterSetCountOut: &ppsCount,
                nalUnitHeaderLengthOut: nil
            )
            
            if spsStatus == noErr, ppsStatus == noErr,
               let spsPtr = spsPointer, let ppsPtr = ppsPointer {
                let spsData = Data(bytes: spsPtr, count: spsSize)
                let ppsData = Data(bytes: ppsPtr, count: ppsSize)
                delegate?.encoder(self, didOutputParameterSets: spsData, pps: ppsData)
                hasSentParameterSets = true
            }
        }
        
        // 2. Determine if frame is keyframe
        let isKeyframe: Bool
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[CFString: Any]],
           let first = attachments.first {
            let notSync = (first[kCMSampleAttachmentKey_NotSync] as? Bool) ?? false
            isKeyframe = !notSync
        } else {
            isKeyframe = false
        }
        
        // 3. Extract NALUs from BlockBuffer
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
        var lengthAtOffset: Int = 0
        var totalLength: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        
        let status = CMBlockBufferGetDataPointer(
            dataBuffer,
            atOffset: 0,
            lengthAtOffsetOut: &lengthAtOffset,
            totalLengthOut: &totalLength,
            dataPointerOut: &dataPointer
        )
        
        guard status == noErr, let ptr = dataPointer else { return }
        
        // VideoToolbox output uses AVCC format (4-byte length prefix per NALU)
        // Convert to annex-B or stream directly with length prefixes
        let rawData = Data(bytes: ptr, count: totalLength)
        let ptsUs = UInt64(CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds * 1_000_000)
        
        delegate?.encoder(self, didOutputFrame: rawData, isKeyframe: isKeyframe, timestampUs: ptsUs)
    }
    
    public func teardown() {
        if let session = compressionSession {
            VTCompressionSessionInvalidate(session)
            compressionSession = nil
        }
        hasSentParameterSets = false
    }
    
    deinit {
        teardown()
    }
}
