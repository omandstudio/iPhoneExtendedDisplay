#if canImport(UIKit) && canImport(SwiftUI)
import SwiftUI

struct DisplayContainerView: UIViewRepresentable {
    let decoderView: H264DecoderView
    let onTouch: (_ phase: TouchPhase, _ x: Double, _ y: Double, _ isRightClick: Bool) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        decoderView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(decoderView)
        
        let touchView = TouchInputView()
        touchView.onTouch = onTouch
        touchView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(touchView)
        
        NSLayoutConstraint.activate([
            decoderView.topAnchor.constraint(equalTo: container.topAnchor),
            decoderView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            decoderView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            decoderView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            touchView.topAnchor.constraint(equalTo: container.topAnchor),
            touchView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            touchView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            touchView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

public struct ContentView: View, NetworkClientDelegate {
    @StateObject private var client = NetworkClient()
    private let decoderView = H264DecoderView()
    
    @State private var hostInput: String = "127.0.0.1" // Default localhost for USB via iproxy
    @State private var portInput: String = "7788"
    @State private var displayInfo: String = "Not connected"
    @State private var isControlsHidden: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if client.isConnected {
                DisplayContainerView(decoderView: decoderView) { phase, x, y, isRightClick in
                    client.sendTouch(phase: phase, normalizedX: x, normalizedY: y, isRightClick: isRightClick)
                }
                .ignoresSafeArea()
                .onTapGesture(count: 3) {
                    // Triple tap anywhere to toggle controls overlay
                    withAnimation { isControlsHidden.toggle() }
                }
            }
            
            if !client.isConnected || !isControlsHidden {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iPhone Extended Display")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text(displayInfo)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        if client.isConnected {
                            Button("Disconnect") {
                                client.disconnect()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(12)
                    
                    if !client.isConnected {
                        VStack(spacing: 12) {
                            // USB or Manual IP Connection
                            HStack {
                                TextField("Mac IP or 127.0.0.1 (USB)", text: $hostInput)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.none)
                                TextField("Port", text: $portInput)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                Button("Connect") {
                                    if let port = UInt16(portInput) {
                                        client.connect(host: hostInput, port: port)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            
                            // Discovered Wi-Fi / Bonjour Macs
                            if !client.discoveredServers.isEmpty {
                                Divider().background(Color.gray)
                                Text("Discovered Macs on Wi-Fi:")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                ForEach(client.discoveredServers, id: \.self) { server in
                                    Button(action: {
                                        // Connect via Bonjour hostname
                                        client.connect(host: "\(server).local", port: ProtocolConstants.defaultPort)
                                    }) {
                                        HStack {
                                            Image(systemName: "display")
                                            Text(server)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            
                            Text("💡 For USB: Connect Lightning/Type-C cable, run `iproxy 7788 7788` on Mac, and click Connect to 127.0.0.1")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                        }
                        .padding()
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            client.delegate = self
            client.startDiscovery()
        }
        .onDisappear {
            client.stopDiscovery()
            client.disconnect()
        }
    }
    
    // MARK: - NetworkClientDelegate
    public func clientDidConnect(_ client: NetworkClient, ack: HandshakeAck) {
        DispatchQueue.main.async {
            self.displayInfo = "Connected: \(ack.virtualWidth)x\(ack.virtualHeight) @ \(ack.fps) FPS"
            withAnimation { self.isControlsHidden = true }
        }
    }
    
    public func clientDidDisconnect(_ client: NetworkClient, error: Error?) {
        DispatchQueue.main.async {
            self.displayInfo = error != nil ? "Disconnected: \(error!.localizedDescription)" : "Disconnected"
            withAnimation { self.isControlsHidden = false }
        }
    }
    
    public func client(_ client: NetworkClient, didReceiveVideoConfig sps: Data, pps: Data) {
        decoderView.setFormatDescription(sps: sps, pps: pps)
    }
    
    public func client(_ client: NetworkClient, didReceiveFrame data: Data, isKeyframe: Bool, timestampUs: UInt64) {
        decoderView.enqueueFrame(data: data, isKeyframe: isKeyframe, timestampUs: timestampUs)
    }
    
    public func client(_ client: NetworkClient, didDiscoverServers servers: [String]) {}
}
#endif

