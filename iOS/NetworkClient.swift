import Foundation
import Network
#if canImport(UIKit)
import UIKit
#endif

public protocol NetworkClientDelegate: AnyObject {
    func clientDidConnect(_ client: NetworkClient, ack: HandshakeAck)
    func clientDidDisconnect(_ client: NetworkClient, error: Error?)
    func client(_ client: NetworkClient, didReceiveVideoConfig sps: Data, pps: Data)
    func client(_ client: NetworkClient, didReceiveFrame data: Data, isKeyframe: Bool, timestampUs: UInt64)
    func client(_ client: NetworkClient, didDiscoverServers servers: [String])
}

public class NetworkClient: ObservableObject {
    public weak var delegate: NetworkClientDelegate?
    
    @Published public var isConnected = false
    @Published public var discoveredServers: [String] = []
    
    private var connection: NWConnection?
    private var browser: NWBrowser?
    private let queue = DispatchQueue(label: "com.openextended.ios.client", qos: .userInteractive)
    
    public init() {}
    
    // MARK: - Auto-Discovery (Bonjour)
    public func startDiscovery() {
        let params = NWParameters()
        params.includePeerToPeer = true
        
        let descriptor = NWBrowser.Descriptor.bonjour(type: ProtocolConstants.bonjourServiceType, domain: ProtocolConstants.bonjourDomain)
        browser = NWBrowser(for: descriptor, using: params)
        
        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self = self else { return }
            let serverNames = results.compactMap { result -> String? in
                if case .service(let name, _, _, _) = result.endpoint {
                    return name
                }
                return nil
            }
            DispatchQueue.main.async {
                self.discoveredServers = serverNames
                self.delegate?.didDiscoverServers(serverNames)
            }
        }
        
        browser?.start(queue: queue)
        print("[iOS Client] Bonjour discovery started...")
    }
    
    public func stopDiscovery() {
        browser?.cancel()
        browser = nil
    }
    
    // MARK: - Connect (Wi-Fi or USB localhost)
    public func connect(host: String, port: UInt16 = ProtocolConstants.defaultPort) {
        disconnect()
        
        print("[iOS Client] Connecting to \(host):\(port)...")
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.noDelay = true
        tcpOptions.enableFastOpen = true
        
        let params = NWParameters(tls: nil, tcp: tcpOptions)
        params.includePeerToPeer = true
        
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!)
        let conn = NWConnection(to: endpoint, using: params)
        self.connection = conn
        
        conn.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                print("[iOS Client] ✅ Connected to host! Sending handshake...")
                DispatchQueue.main.async { self.isConnected = true }
                self.sendHandshake()
                self.receiveNextPacket()
            case .failed(let error):
                print("[iOS Client] Connection failed: \(error)")
                self.handleDisconnection(error: error)
            case .cancelled:
                self.handleDisconnection(error: nil)
            default:
                break
            }
        }
        
        conn.start(queue: queue)
    }
    
    private func sendHandshake() {
        #if canImport(UIKit)
        let screen = UIScreen.main
        let bounds = screen.bounds
        let scale = Double(screen.scale)
        let name = UIDevice.current.name
        let model = UIDevice.current.model
        #else
        let bounds = CGRect(x: 0, y: 0, width: 1024, height: 768)
        let scale = 2.0
        let name = "iPad"
        let model = "iPad"
        #endif
        
        let handshake = DeviceHandshake(
            deviceName: name,
            model: model,
            screenWidth: Double(bounds.width),
            screenHeight: Double(bounds.height),
            scaleFactor: scale,
            preferredFps: 60
        )
        
        if let data = try? JSONEncoder().encode(handshake) {
            send(type: .handshake, payload: data)
        }
    }
    
    // MARK: - Packet Receiving Loop
    private func receiveNextPacket() {
        guard let conn = connection else { return }
        
        conn.receive(minimumIncompleteLength: ProtocolConstants.headerSize, maximumLength: ProtocolConstants.headerSize) { [weak self] content, _, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                print("[iOS Client] Read error: \(error)")
                self.handleDisconnection(error: error)
                return
            }
            
            guard let headerData = content, let header = PacketCodec.decodeHeader(from: headerData) else {
                if !isComplete { self.receiveNextPacket() }
                return
            }
            
            if header.payloadLength == 0 {
                self.processPacket(type: header.type, payload: Data())
                self.receiveNextPacket()
            } else {
                self.readPayload(length: header.payloadLength, type: header.type)
            }
        }
    }
    
    private func readPayload(length: Int, type: MessageType) {
        guard let conn = connection else { return }
        
        conn.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] content, _, isComplete, error in
            guard let self = self else { return }
            
            if let payload = content, payload.count == length {
                self.processPacket(type: type, payload: payload)
            }
            
            if !isComplete && error == nil {
                self.receiveNextPacket()
            } else if error != nil {
                self.handleDisconnection(error: error)
            }
        }
    }
    
    private func processPacket(type: MessageType, payload: Data) {
        switch type {
        case .handshakeAck:
            if let ack = try? JSONDecoder().decode(HandshakeAck.self, from: payload) {
                print("[iOS Client] ✅ Handshake acknowledged by Mac! Virtual display ID: \(ack.displayID), Res: \(ack.virtualWidth)x\(ack.virtualHeight)@\(ack.fps)fps")
                delegate?.clientDidConnect(self, ack: ack)
            }
            
        case .videoConfig:
            // Format: [2 bytes sps length][SPS bytes][2 bytes pps length][PPS bytes]
            guard payload.count >= 4 else { return }
            let spsLen = Int(payload.subdata(in: 0..<2).withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian)
            let spsEnd = 2 + spsLen
            guard payload.count >= spsEnd + 2 else { return }
            let sps = payload.subdata(in: 2..<spsEnd)
            
            let ppsLen = Int(payload.subdata(in: spsEnd..<spsEnd+2).withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian)
            let ppsStart = spsEnd + 2
            guard payload.count >= ppsStart + ppsLen else { return }
            let pps = payload.subdata(in: ppsStart..<ppsStart+ppsLen)
            
            delegate?.client(self, didReceiveVideoConfig: sps, pps: pps)
            
        case .videoFrame:
            // Format: [1 byte keyframe][8 bytes timestampUs][H.264 NALU payload]
            guard payload.count > 9 else { return }
            let isKeyframe = payload[0] == 1
            let ts = payload.subdata(in: 1..<9).withUnsafeBytes { $0.load(as: UInt64.self) }.bigEndian
            let frameData = payload.subdata(in: 9..<payload.count)
            
            delegate?.client(self, didReceiveFrame: frameData, isKeyframe: isKeyframe, timestampUs: ts)
            
        default:
            break
        }
    }
    
    // MARK: - Sending
    public func send(type: MessageType, payload: Data) {
        guard let conn = connection else { return }
        let packet = PacketCodec.encode(type: type, payload: payload)
        conn.send(content: packet, completion: .contentProcessed({ _ in }))
    }
    
    public func sendTouch(phase: TouchPhase, normalizedX: Double, normalizedY: Double, touchId: Int = 0, isRightClick: Bool = false) {
        let touch = TouchPacket(
            phase: phase.rawValue,
            normalizedX: normalizedX,
            normalizedY: normalizedY,
            touchId: touchId,
            isRightClick: isRightClick
        )
        if let data = try? JSONEncoder().encode(touch) {
            send(type: .touchEvent, payload: data)
        }
    }
    
    private func handleDisconnection(error: Error?) {
        connection?.cancel()
        connection = nil
        DispatchQueue.main.async { self.isConnected = false }
        delegate?.clientDidDisconnect(self, error: error)
    }
    
    public func disconnect() {
        if connection != nil {
            send(type: .disconnect, payload: Data())
            connection?.cancel()
            connection = nil
            DispatchQueue.main.async { self.isConnected = false }
        }
    }
}

