#if canImport(UIKit)
import UIKit
import AVFoundation
import VideoToolbox

public class H264DecoderView: UIView {
    private var displayLayer: AVSampleBufferDisplayLayer?
    private var formatDescription: CMVideoFormatDescription?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    private func setupLayer() {
        backgroundColor = .black
        
        let layer = AVSampleBufferDisplayLayer()
        layer.videoGravity = .resizeAspect
        layer.isOpaque = true
        self.layer.addSublayer(layer)
        self.displayLayer = layer
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        displayLayer?.frame = bounds
    }
    
    public func setFormatDescription(sps: Data, pps: Data) {
        var spsPtr: UnsafePointer<UInt8>?
        var ppsPtr: UnsafePointer<UInt8>?
        
        sps.withUnsafeBytes { raw in
            spsPtr = raw.bindMemory(to: UInt8.self).baseAddress
        }
        pps.withUnsafeBytes { raw in
            ppsPtr = raw.bindMemory(to: UInt8.self).baseAddress
        }
        
        guard let spsBase = spsPtr, let ppsBase = ppsPtr else { return }
        
        let pointers = [spsBase, ppsBase]
        let sizes = [sps.count, pps.count]
        
        var newFormatDesc: CMFormatDescription?
        let status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
            allocator: kCFAllocatorDefault,
            parameterSetCount: 2,
            parameterSetPointers: pointers,
            parameterSetSizes: sizes,
            nalUnitHeaderLength: 4,
            formatDescriptionOut: &newFormatDesc
        )
        
        if status == noErr, let desc = newFormatDesc {
            self.formatDescription = desc
            print("[Decoder] ✅ CMVideoFormatDescription initialized from SPS/PPS!")
            
            DispatchQueue.main.async {
                self.displayLayer?.flushAndRemoveImage()
            }
        } else {
            print("[Decoder] Error: CMVideoFormatDescriptionCreateFromH264ParameterSets failed with status \(status)")
        }
    }
    
    public func enqueueFrame(data: Data, isKeyframe: Bool, timestampUs: UInt64) {
        guard let formatDesc = self.formatDescription,
              let layer = self.displayLayer,
              layer.isReadyForMoreMediaData else {
            return
        }
        
        var blockBuffer: CMBlockBuffer?
        let memoryBlock = UnsafeMutableRawPointer.allocate(byteCount: data.count, alignment: 1)
        data.copyBytes(to: memoryBlock.assumingMemoryBound(to: UInt8.self), count: data.count)
        
        let customBlockAllocator: CFAllocator = kCFAllocatorDefault
        
        let blockStatus = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: memoryBlock,
            blockLength: data.count,
            blockAllocator: customBlockAllocator,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: data.count,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        
        guard blockStatus == noErr, let buffer = blockBuffer else {
            memoryBlock.deallocate()
            return
        }
        
        var sampleBuffer: CMSampleBuffer?
        var sampleSizeArray = [data.count]
        
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime.invalid,
            presentationTimeStamp: CMTime(value: CMTimeValue(timestampUs), timescale: 1_000_000),
            decodeTimeStamp: CMTime.invalid
        )
        
        let sampleStatus = CMSampleBufferCreateReady(
            allocator: kCFAllocatorDefault,
            dataBuffer: buffer,
            formatDescription: formatDesc,
            sampleCount: 1,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timingInfo,
            sampleSizeEntryCount: 1,
            sampleSizeArray: &sampleSizeArray,
            sampleBufferOut: &sampleBuffer
        )
        
        guard sampleStatus == noErr, let sBuffer = sampleBuffer else {
            return
        }
        
        // Attach sync / keyframe flags
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sBuffer, createIfNecessary: true) as? [[CFString: Any]] {
            var dict = attachments[0]
            dict[kCMSampleAttachmentKey_DisplayImmediately] = true
            dict[kCMSampleAttachmentKey_DoNotDisplay] = false
            if !isKeyframe {
                dict[kCMSampleAttachmentKey_NotSync] = true
            }
        }
        
        DispatchQueue.main.async {
            layer.enqueue(sBuffer)
        }
    }
}
#endif

