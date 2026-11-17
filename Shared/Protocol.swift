import Foundation
import CoreGraphics

// MARK: - Packet Framing Magic & Constants
public enum ProtocolConstants {
    public static let magic: UInt32 = 0x49455844 // "IEXD" (iPhoneExtendedDisplay)
    public static let defaultPort: UInt16 = 7788
    public static let bonjourServiceType: String = "_openextended._tcp"
    public static let bonjourDomain: String = "local."
    public static let headerSize: Int = 9 // 4 bytes magic + 1 byte type + 4 bytes payload length
}

// MARK: - Message Types
public enum MessageType: UInt8 {
    case handshake       = 0x01
    case handshakeAck    = 0x02
    case videoConfig     = 0x10
    case videoFrame      = 0x11
    case touchEvent      = 0x20
    case mouseEvent      = 0x21
    case ping            = 0x30
    case pong            = 0x31
    case disconnect      = 0xFF
}

// MARK: - Touch Phase
public enum TouchPhase: UInt8 {
    case began     = 0
    case moved     = 1
    case stationary = 2
    case ended     = 3
    case cancelled = 4
}

// MARK: - Handshake Data (iOS -> macOS)
public struct DeviceHandshake: Codable {
    public let deviceName: String
    public let model: String
    public let screenWidth: Double
    public let screenHeight: Double
    public let scaleFactor: Double
    public let preferredFps: Int

    public init(deviceName: String, model: String, screenWidth: Double, screenHeight: Double, scaleFactor: Double, preferredFps: Int) {
        self.deviceName = deviceName
        self.model = model
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.scaleFactor = scaleFactor
        self.preferredFps = preferredFps
    }
}

// MARK: - Handshake Acknowledge (macOS -> iOS)
public struct HandshakeAck: Codable {
    public let displayID: UInt32
    public let virtualWidth: UInt32
    public let virtualHeight: UInt32
    public let fps: Int
    public let message: String

    public init(displayID: UInt32, virtualWidth: UInt32, virtualHeight: UInt32, fps: Int, message: String) {
        self.displayID = displayID
        self.virtualWidth = virtualWidth
        self.virtualHeight = virtualHeight
        self.fps = fps
        self.message = message
    }
}

// MARK: - Touch Event Payload (iOS -> macOS)
public struct TouchPacket: Codable {
    public let phase: UInt8
    public let normalizedX: Double // 0.0 ... 1.0 relative to display
    public let normalizedY: Double // 0.0 ... 1.0 relative to display
    public let touchId: Int
    public let isRightClick: Bool

    public init(phase: UInt8, normalizedX: Double, normalizedY: Double, touchId: Int, isRightClick: Bool = false) {
        self.phase = phase
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.touchId = touchId
        self.isRightClick = isRightClick
    }
}

// MARK: - Frame Packet Header
public struct VideoFrameHeader {
    public let isKeyframe: Bool
    public let timestampUs: UInt64
    public let payloadLength: UInt32

    public static let size = 1 + 8 + 4 // 13 bytes
}

// MARK: - Packet Serializer & Deserializer
public class PacketCodec {
    public static func encode(type: MessageType, payload: Data) -> Data {
        var data = Data(capacity: ProtocolConstants.headerSize + payload.count)
        
        var magic = ProtocolConstants.magic.bigEndian
        data.append(Data(bytes: &magic, count: 4))
        
        var msgType = type.rawValue
        data.append(Data(bytes: &msgType, count: 1))
        
        var length = UInt32(payload.count).bigEndian
        data.append(Data(bytes: &length, count: 4))
        
        data.append(payload)
        return data
    }
    
    public static func decodeHeader(from data: Data) -> (type: MessageType, payloadLength: Int)? {
        guard data.count >= ProtocolConstants.headerSize else { return nil }
        
        let magic = data.subdata(in: 0..<4).withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
        guard magic == ProtocolConstants.magic else { return nil }
        
        let typeRaw = data[4]
        guard let type = MessageType(rawValue: typeRaw) else { return nil }
        
        let length = Int(data.subdata(in: 5..<9).withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian)
        return (type, length)
    }
}

