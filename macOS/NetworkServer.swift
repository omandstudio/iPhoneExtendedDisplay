import Foundation
import Network

public protocol NetworkServerDelegate: AnyObject {
    func server(_ server: NetworkServer, didReceiveHandshake handshake: DeviceHandshake)
    func server(_ server: NetworkServer, didReceiveTouch packet: TouchPacket)
    func serverClientDidDisconnect(_ server: NetworkServer)
}

public class NetworkServer {
    public weak var delegate: NetworkServerDelegate?
    
    private var listener: NWListener?
    private var activeConnection: NWConnection?
    private let queue = DispatchQueue(label: "com.openextended.networkServer", qos: .userInteractive)
    
    public init() {}
    
    public func start(port: UInt16 = ProtocolConstants.defaultPort) -> Bool {
        stop()
        
        do {
            let tcpOptions = NWProtocolTCP.Options()
            tcpOptions.enableFastOpen = true
            tcpOptions.noDelay = true // Disable Nagle's algorithm for minimum latency
            
            let params = NWParameters(tls: nil, tcp: tcpOptions)
            params.allowLocalEndpointReuse = true
            params.includePeerToPeer = true // Enable Wi-Fi direct / AWDL support
            
            guard let nwPort = NWEndpoint.Port(rawValue: port) else { return false }
            listener = try NWListener(using: params, on: nwPort)
            
            // Advertise Bonjour service for auto-discovery
            listener?.service = NWListener.Service(
                name: "iPhoneExtendedDisplay-\(Host.current().localizedName ?? "Mac")",
                type: ProtocolConstants.bonjourServiceType,
                domain: ProtocolConstants.bonjourDomain
            )
            
            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    print("[NetworkServer] ✅ Listening on port \(port), Bonjour service advertised.")
                case .failed(let error):
                    print("[NetworkServer] Error: Listener failed: \(error)")
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            listener?.start(queue: queue)
            return true
        } catch {
            print("[NetworkServer] Error starting listener: \(error)")
            return false
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Close existing connection if any
            if let old = self.activeConnection {
                old.cancel()
            }
            
            print("[NetworkServer] New client connecting from \(connection.endpoint)...")
            self.activeConnection = connection
            
            connection.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    print("[NetworkServer] ✅ Client connected successfully.")
                    self?.receiveNextPacket()
                case .failed(let error):
                    print("[NetworkServer] Client connection error: \(error)")
                    self?.handleDisconnection()
                case .cancelled:
                    print("[NetworkServer] Client connection cancelled.")
                    self?.handleDisconnection()
                default:
                    break
                }
            }
            
            connection.start(queue: self.queue)
        }
    }
    
    private func receiveNextPacket() {
        guard let connection = activeConnection else { return }
        
        // 1. Read Header (9 bytes)
        connection.receive(minimumIncompleteLength: ProtocolConstants.headerSize, maximumLength: ProtocolConstants.headerSize) { [weak self] content, _, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                print("[NetworkServer] Read header error: \(error)")
                self.handleDisconnection()
                return
            }
            
            guard let headerData = content, let header = PacketCodec.decodeHeader(from: headerData) else {
                if !isComplete {
                    self.receiveNextPacket()
                }
                return
            }
            
            // 2. Read Payload
            if header.payloadLength == 0 {
                self.processPacket(type: header.type, payload: Data())
                self.receiveNextPacket()
            } else {
                self.readPayload(length: header.payloadLength, type: header.type)
            }
        }
    }
    
    private func readPayload(length: Int, type: MessageType) {
        guard let connection = activeConnection else { return }
        
        connection.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] content, _, isComplete, error in
            guard let self = self else { return }
            
            if let payload = content, payload.count == length {
                self.processPacket(type: type, payload: payload)
            }
            
            if !isComplete && error == nil {
                self.receiveNextPacket()
            } else if error != nil {
                self.handleDisconnection()
            }
        }
    }
    
    private func processPacket(type: MessageType, payload: Data) {
        switch type {
        case .handshake:
            if let handshake = try? JSONDecoder().decode(DeviceHandshake.self, from: payload) {
                print("[NetworkServer] 📱 Handshake received from: \(handshake.deviceName) (\(handshake.model), \(handshake.screenWidth)x\(handshake.screenHeight)@\(handshake.scaleFactor)x)")
                delegate?.server(self, didReceiveHandshake: handshake)
            }
            
        case .touchEvent:
            if let touch = try? JSONDecoder().decode(TouchPacket.self, from: payload) {
                delegate?.server(self, didReceiveTouch: touch)
            }
            
        case .ping:
            send(type: .pong, payload: Data())
            
        case .disconnect:
            handleDisconnection()
            
        default:
            break
        }
    }
    
    public func send(type: MessageType, payload: Data) {
        guard let connection = activeConnection else { return }
        let packetData = PacketCodec.encode(type: type, payload: payload)
        
        connection.send(content: packetData, completion: .contentProcessed({ error in
            if let error = error {
                print("[NetworkServer] Send error: \(error)")
            }
        }))
    }
    
    public func sendHandshakeAck(displayID: UInt32, width: UInt32, height: UInt32, fps: Int) {
        let ack = HandshakeAck(displayID: displayID, virtualWidth: width, virtualHeight: height, fps: fps, message: "OK")
        if let data = try? JSONEncoder().encode(ack) {
            send(type: .handshakeAck, payload: data)
        }
    }
    
    public func sendVideoConfig(sps: Data, pps: Data) {
        var payload = Data()
        var spsLen = UInt16(sps.count).bigEndian
        var ppsLen = UInt16(pps.count).bigEndian
        
        payload.append(Data(bytes: &spsLen, count: 2))
        payload.append(sps)
        payload.append(Data(bytes: &ppsLen, count: 2))
        payload.append(pps)
        
        send(type: .videoConfig, payload: payload)
    }
    
    public func sendVideoFrame(data: Data, isKeyframe: Bool, timestampUs: UInt64) {
        var payload = Data(capacity: 1 + 8 + data.count)
        var keyByte: UInt8 = isKeyframe ? 1 : 0
        var ts = timestampUs.bigEndian
        
        payload.append(Data(bytes: &keyByte, count: 1))
        payload.append(Data(bytes: &ts, count: 8))
        payload.append(data)
        
        send(type: .videoFrame, payload: payload)
    }
    
    private func handleDisconnection() {
        activeConnection?.cancel()
        activeConnection = nil
        delegate?.serverClientDidDisconnect(self)
    }
    
    public func stop() {
        activeConnection?.cancel()
        activeConnection = nil
        listener?.cancel()
        listener = nil
    }
    
    deinit {
        stop()
    }
}

