import Foundation
import Network
import CoreGraphics
import CoreImage
import CoreVideo

public protocol WebServerDelegate: AnyObject {
    func webServer(_ server: WebServer, didClientHandshake width: UInt32, height: UInt32, scale: Double)
    func webServer(_ server: WebServer, didReceiveTouch phase: UInt8, x: Double, y: Double, isRightClick: Bool)
    func webServerClientDidDisconnect(_ server: WebServer)
}

public class WebServer {
    public weak var delegate: WebServerDelegate?
    
    private var listener: NWListener?
    private var activeWsConnection: NWConnection?
    private var lastSentJpegData: Data?
    private let queue = DispatchQueue(label: "com.openextended.webserver", qos: .userInteractive)
    
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    private var isSendingFrame = false
    private var lastSentTime: CFAbsoluteTime = 0
    private var targetFps: Double = 60.0
    
    public init() {}
    
    public func start(port: UInt16 = 8080) -> Bool {
        stop()
        
        do {
            let tcpOptions = NWProtocolTCP.Options()
            tcpOptions.noDelay = true
            tcpOptions.enableFastOpen = true
            
            let params = NWParameters(tls: nil, tcp: tcpOptions)
            params.allowLocalEndpointReuse = true
            
            guard let nwPort = NWEndpoint.Port(rawValue: port) else { return false }
            listener = try NWListener(using: params, on: nwPort)
            
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("[WebServer] 🌐 Web Server active on port \(port)")
                case .failed(let err):
                    print("[WebServer] Error starting web listener: \(err)")
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleIncomingConnection(connection)
            }
            
            listener?.start(queue: queue)
            return true
        } catch {
            print("[WebServer] Error: \(error)")
            return false
        }
    }
    
    private func handleIncomingConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self] state in
            if case .ready = state {
                self?.readHttpRequest(connection: connection)
            }
        }
        connection.start(queue: queue)
    }
    
    private func readHttpRequest(connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4096) { [weak self] data, _, _, error in
            guard let self = self, let data = data, error == nil,
                  let requestStr = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }
            
            // Check if WebSocket upgrade request (case-insensitive check RFC 6455)
            let lower = requestStr.lowercased()
            let isWsUpgrade = (lower.contains("upgrade") && lower.contains("websocket")) || lower.contains("sec-websocket-key")
            
            if isWsUpgrade {
                self.handleWebSocketUpgrade(connection: connection, request: requestStr)
            } else {
                // Regular HTTP GET request - serve the Web Client HTML/JS or Web Icons
                self.serveHttpPage(connection: connection, request: requestStr)
            }
        }
    }
    
    private func serveHttpPage(connection: NWConnection, request: String) {
        let firstLine = request.components(separatedBy: "\r\n").first?.lowercased() ?? ""
        
        // Serve Web Icon & Favicon for iOS Safari Bookmarks / Add to Home Screen
        if firstLine.contains("favicon") || firstLine.contains("apple-touch-icon") || firstLine.contains("icon.png") {
            let iconData = WebIcon.data
            let header = "HTTP/1.1 200 OK\r\n" +
                "Content-Type: image/png\r\n" +
                "Content-Length: \(iconData.count)\r\n" +
                "Connection: close\r\n" +
                "Cache-Control: public, max-age=604800\r\n\r\n"
            
            var fullData = header.data(using: .utf8) ?? Data()
            fullData.append(iconData)
            
            connection.send(content: fullData, completion: .contentProcessed({ _ in
                connection.cancel()
            }))
            return
        }
        
        let html = WebClientHTML.content
        let response = "HTTP/1.1 200 OK\r\n" +
            "Content-Type: text/html; charset=utf-8\r\n" +
            "Content-Length: \(html.utf8.count)\r\n" +
            "Connection: close\r\n" +
            "Cache-Control: no-cache\r\n\r\n" +
            html
        
        let responseData = response.data(using: .utf8) ?? Data()
        connection.send(content: responseData, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
    
    private func handleWebSocketUpgrade(connection: NWConnection, request: String) {
        // Extract Sec-WebSocket-Key
        guard let keyLine = request.components(separatedBy: "\r\n").first(where: { $0.lowercased().hasPrefix("sec-websocket-key:") }),
              let colonIdx = keyLine.firstIndex(of: ":") else {
            connection.cancel()
            return
        }
        let clientKey = keyLine[keyLine.index(after: colonIdx)...].trimmingCharacters(in: .whitespaces)
        
        // Compute Sec-WebSocket-Accept
        let magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        let fullKey = clientKey + magic
        guard let fullKeyData = fullKey.data(using: .utf8) else { connection.cancel(); return }
        
        var digest = [UInt8](repeating: 0, count: 20)
        fullKeyData.withUnsafeBytes { ptr in
            _ = CC_SHA1(ptr.baseAddress, CC_LONG(fullKeyData.count), &digest)
        }
        let acceptKey = Data(digest).base64EncodedString()
        
        let upgradeResponse = "HTTP/1.1 101 Switching Protocols\r\n" +
            "Upgrade: websocket\r\n" +
            "Connection: Upgrade\r\n" +
            "Sec-WebSocket-Accept: \(acceptKey)\r\n\r\n"
        
        connection.send(content: upgradeResponse.data(using: .utf8)!, completion: .contentProcessed({ [weak self] error in
            guard let self = self, error == nil else {
                connection.cancel()
                return
            }
            
            print("[WebServer] 📱 iPhone Safari WebSocket connected!")
            self.activeWsConnection?.cancel()
            self.activeWsConnection = connection
            self.readWebSocketFrames(connection: connection)
            
            // Deliver last captured frame immediately so screen never stays black
            if let cached = self.lastSentJpegData {
                self.sendWsBinaryData(cached)
            }
        }))
    }
    
    // Read raw WebSocket framing (RFC 6455)
    private func readWebSocketFrames(connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 2, maximumLength: 2) { [weak self] headerData, _, isComplete, error in
            guard let self = self, let header = headerData, header.count == 2, error == nil else {
                self?.handleWsDisconnection()
                return
            }
            
            let b0 = header[0]
            let b1 = header[1]
            let opcode = b0 & 0x0F
            let isMasked = (b1 & 0x80) != 0
            var payloadLen = UInt64(b1 & 0x7F)
            
            // Handle close opcode
            if opcode == 0x08 {
                self.handleWsDisconnection()
                return
            }
            
            // Read extended length if needed
            let lengthExtraBytes: Int
            if payloadLen == 126 {
                lengthExtraBytes = 2
            } else if payloadLen == 127 {
                lengthExtraBytes = 8
            } else {
                lengthExtraBytes = 0
            }
            
            let maskBytesCount = isMasked ? 4 : 0
            let extraToRead = lengthExtraBytes + maskBytesCount
            
            if extraToRead > 0 {
                connection.receive(minimumIncompleteLength: extraToRead, maximumLength: extraToRead) { extraData, _, _, extraErr in
                    guard let extraData = extraData, extraData.count == extraToRead, extraErr == nil else {
                        self.handleWsDisconnection()
                        return
                    }
                    
                    var offset = 0
                    if lengthExtraBytes == 2 {
                        let len16 = extraData.subdata(in: 0..<2).withUnsafeBytes { $0.load(as: UInt16.self) }.bigEndian
                        payloadLen = UInt64(len16)
                        offset = 2
                    } else if lengthExtraBytes == 8 {
                        let len64 = extraData.subdata(in: 0..<8).withUnsafeBytes { $0.load(as: UInt64.self) }.bigEndian
                        payloadLen = len64
                        offset = 8
                    }
                    
                    var maskKey: [UInt8] = []
                    if isMasked {
                        maskKey = [UInt8](extraData.subdata(in: offset..<offset+4))
                    }
                    
                    self.readWsPayload(connection: connection, length: Int(payloadLen), maskKey: maskKey, opcode: opcode)
                }
            } else {
                self.readWsPayload(connection: connection, length: Int(payloadLen), maskKey: [], opcode: opcode)
            }
        }
    }
    
    private func readWsPayload(connection: NWConnection, length: Int, maskKey: [UInt8], opcode: UInt8) {
        if length == 0 {
            readWebSocketFrames(connection: connection)
            return
        }
        
        connection.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] content, _, _, error in
            guard let self = self, var payload = content, payload.count == length, error == nil else {
                self?.handleWsDisconnection()
                return
            }
            
            // Unmask if client sent masked data
            if !maskKey.isEmpty {
                payload.withUnsafeMutableBytes { ptr in
                    let bytes = ptr.bindMemory(to: UInt8.self)
                    for i in 0..<length {
                        bytes[i] ^= maskKey[i % 4]
                    }
                }
            }
            
            // Text frame (JSON message from Safari)
            if opcode == 0x01, let text = String(data: payload, encoding: .utf8) {
                self.processClientJson(text)
            }
            
            self.readWebSocketFrames(connection: connection)
        }
    }
    
    private func processClientJson(_ jsonStr: String) {
        guard let data = jsonStr.data(using: .utf8),
              let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return
        }
        
        let type = dict["type"] as? String ?? ""
        
        switch type {
        case "handshake":
            let widthNum = (dict["width"] as? NSNumber)?.doubleValue ?? (dict["width"] as? Double ?? 896.0)
            let heightNum = (dict["height"] as? NSNumber)?.doubleValue ?? (dict["height"] as? Double ?? 414.0)
            let scaleNum = (dict["scale"] as? NSNumber)?.doubleValue ?? (dict["scale"] as? Double ?? 2.0)
            
            let width = UInt32(widthNum)
            let height = UInt32(heightNum)
            let scale = scaleNum
            print("[WebServer] 📱 Safari Handshake: \(width)x\(height) @\(scale)x")
            delegate?.webServer(self, didClientHandshake: width, height: height, scale: scale)
            
        case "touch":
            let phase = UInt8((dict["phase"] as? NSNumber)?.intValue ?? (dict["phase"] as? Int ?? 1))
            let x = (dict["x"] as? NSNumber)?.doubleValue ?? (dict["x"] as? Double ?? 0.0)
            let y = (dict["y"] as? NSNumber)?.doubleValue ?? (dict["y"] as? Double ?? 0.0)
            let right = dict["rightClick"] as? Bool ?? false
            delegate?.webServer(self, didReceiveTouch: phase, x: x, y: y, isRightClick: right)
            
        default:
            break
        }
    }
    
    // Send text message (e.g. permission notice or JSON status)
    public func sendTextMessage(_ text: String) {
        guard let conn = activeWsConnection, let textData = text.data(using: .utf8) else { return }
        
        var frame = Data()
        frame.append(0x81) // FIN + Text Opcode
        
        let len = textData.count
        if len <= 125 {
            frame.append(UInt8(len))
        } else if len <= 65535 {
            frame.append(126)
            var len16 = UInt16(len).bigEndian
            frame.append(Data(bytes: &len16, count: 2))
        } else {
            frame.append(127)
            var len64 = UInt64(len).bigEndian
            frame.append(Data(bytes: &len64, count: 8))
        }
        
        frame.append(textData)
        conn.send(content: frame, completion: .contentProcessed({ _ in }))
    }
    
    // Send binary JPEG frame over WebSocket from CVPixelBuffer
    public func sendFrame(pixelBuffer: CVPixelBuffer) {
        guard let _ = activeWsConnection, !isSendingFrame else { return }
        
        let now = CFAbsoluteTimeGetCurrent()
        guard (now - lastSentTime) >= (1.0 / targetFps) else { return }
        
        isSendingFrame = true
        lastSentTime = now
        
        // Encode CVPixelBuffer to JPEG
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let jpegData = ciContext.jpegRepresentation(
            of: ciImage,
            colorSpace: colorSpace,
            options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.65]
        ) else {
            isSendingFrame = false
            return
        }
        
        self.lastSentJpegData = jpegData
        sendWsBinaryData(jpegData)
    }
    
    // Send binary JPEG frame over WebSocket from CGImage (Fallback mode)
    public func sendFrame(cgImage: CGImage) {
        guard let _ = activeWsConnection, !isSendingFrame else { return }
        
        let now = CFAbsoluteTimeGetCurrent()
        guard (now - lastSentTime) >= (1.0 / targetFps) else { return }
        
        isSendingFrame = true
        lastSentTime = now
        
        let ciImage = CIImage(cgImage: cgImage)
        guard let jpegData = ciContext.jpegRepresentation(
            of: ciImage,
            colorSpace: colorSpace,
            options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.65]
        ) else {
            isSendingFrame = false
            return
        }
        
        self.lastSentJpegData = jpegData
        sendWsBinaryData(jpegData)
    }
    
    private func sendWsBinaryData(_ data: Data) {
        guard let conn = activeWsConnection else {
            isSendingFrame = false
            return
        }
        
        // Construct WebSocket Binary Frame (Opcode 0x02)
        var frame = Data()
        frame.append(0x82) // FIN + Binary Opcode
        
        let len = data.count
        if len <= 125 {
            frame.append(UInt8(len))
        } else if len <= 65535 {
            frame.append(126)
            var len16 = UInt16(len).bigEndian
            frame.append(Data(bytes: &len16, count: 2))
        } else {
            frame.append(127)
            var len64 = UInt64(len).bigEndian
            frame.append(Data(bytes: &len64, count: 8))
        }
        
        frame.append(data)
        
        conn.send(content: frame, completion: .contentProcessed({ [weak self] _ in
            self?.isSendingFrame = false
        }))
    }
    
    private func handleWsDisconnection() {
        activeWsConnection?.cancel()
        activeWsConnection = nil
        delegate?.webServerClientDidDisconnect(self)
    }
    
    public func stop() {
        activeWsConnection?.cancel()
        activeWsConnection = nil
        listener?.cancel()
        listener = nil
    }
}

// CommonCrypto C declaration for SHA1
import CommonCrypto

