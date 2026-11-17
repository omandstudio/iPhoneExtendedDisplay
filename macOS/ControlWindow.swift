import SwiftUI
import AppKit

public class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var isServerRunning: Bool = true
    @Published public var connectedDeviceName: String = "Belum ada perangkat terhubung"
    @Published public var isDeviceConnected: Bool = false
    @Published public var fps: Int = 60
    @Published public var targetFps: Int = 60
    @Published public var quality: Double = 0.65
    @Published public var displayMode: String = "extended" // "extended" or "mirror"
    @Published public var port: UInt16 = 8080
    @Published public var usbIP: String = "192.168.2.1"
    @Published public var wifiIP: String = "192.168.0.183"
    @Published public var hasScreenPermission: Bool = true
    
    public init() {
        refreshIPs()
        checkPermission()
    }
    
    public func checkPermission() {
        self.hasScreenPermission = CGPreflightScreenCaptureAccess()
    }
    
    public func refreshIPs() {
        // Find active IPv4 interfaces
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        
        var foundUsb = false
        var foundWifi = false
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee
            
            // Look for IPv4 addresses
            if (flags & (IFF_UP|IFF_RUNNING)) != 0 && addr.sa_family == UInt8(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                    let ipStr = String(cString: hostname)
                    let name = String(cString: ptr.pointee.ifa_name)
                    
                    if ipStr != "127.0.0.1" {
                        if name.starts(with: "bridge") || ipStr.starts(with: "192.168.2.") {
                            self.usbIP = ipStr
                            foundUsb = true
                        } else if name.starts(with: "en") && !foundWifi {
                            self.wifiIP = ipStr
                            foundWifi = true
                        }
                    }
                }
            }
        }
        freeifaddrs(ifaddr)
    }
}

public struct ControlWindowView: View {
    @ObservedObject var state = AppState.shared
    @State private var copyNotice: String? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack(spacing: 14) {
                ZStack {
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "iphone.and.arrow.forward")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("iPhone Extended Display")
                            .font(.system(size: 16, weight: .bold))
                        
                        Text("v1.0.0")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(6)
                    }
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(state.isDeviceConnected ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(state.isDeviceConnected ? "Terhubung ke \(state.connectedDeviceName)" : "Server Aktif • Menunggu Koneksi")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(18)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // MARK: - Permission Warning (if needed)
            if !state.hasScreenPermission {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 18))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Izin Perekaman Layar Diperlukan")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Aktifkan di System Settings agar Mac dapat menampilkan layar ke iPhone.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Buka Pengaturan") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.small)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .border(Color.orange.opacity(0.2), width: 1)
            }
            
            // MARK: - Body Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 1. Connection Addresses Box
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ALAMAT AKSES DI IPHONE (SAFARI)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        // USB Option
                        HStack {
                            Label("Kabel USB (Latensi Nol):", systemImage: "cable.connector")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("http://\(state.usbIP):\(String(state.port))")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.accentColor)
                            
                            Button(action: {
                                copyToClipboard("http://\(state.usbIP):\(state.port)")
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(10)
                        .background(Color.secondary.opacity(0.06))
                        .cornerRadius(8)
                        
                        // Wi-Fi Option
                        HStack {
                            Label("Nirkabel Wi-Fi:", systemImage: "wifi")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("http://\(state.wifiIP):\(String(state.port))")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.accentColor)
                            
                            Button(action: {
                                copyToClipboard("http://\(state.wifiIP):\(state.port)")
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(10)
                        .background(Color.secondary.opacity(0.06))
                        .cornerRadius(8)
                    }
                    
                    // 2. Settings Group
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PENGATURAN DISPLAY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        // Mode
                        HStack {
                            Text("Mode Monitor:")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $state.displayMode) {
                                Text("Extended Display (Layar Kedua)").tag("extended")
                                Text("Mirror Display (Duplikat)").tag("mirror")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 260)
                        }
                        
                        // FPS
                        HStack {
                            Text("Target Frame Rate:")
                                .font(.system(size: 12))
                            Spacer()
                            Picker("", selection: $state.targetFps) {
                                Text("60 FPS (Mulus)").tag(60)
                                Text("30 FPS (Hemat Daya)").tag(30)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 220)
                        }
                    }
                    .padding(14)
                    .background(Color.secondary.opacity(0.04))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                    )
                }
                .padding(18)
            }
            
            Divider()
            
            // MARK: - Footer
            HStack {
                Button(action: {
                    if let url = URL(string: "https://github.com/omandstudio/iPhoneExtendedDisplay") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "link")
                            .font(.system(size: 10))
                        Text("omandstudio/iPhoneExtendedDisplay")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if let msg = copyNotice {
                    Text(msg)
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
                
                Button("Muat Ulang IP") {
                    state.refreshIPs()
                    state.checkPermission()
                }
                .controlSize(.small)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 520, height: 420)
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        withAnimation {
            copyNotice = "Tersalin ke Clipboard!"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { copyNotice = nil }
        }
    }
}
