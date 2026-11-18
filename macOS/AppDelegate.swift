import Cocoa
import SwiftUI

public class AppDelegate: NSObject, NSApplicationDelegate {
    public var window: NSWindow!
    public let service = ExtendedDisplayService()
    
    public func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Wire AppState actions to service
        AppState.shared.onToggleServer = { [weak self] in
            guard let self = self else { return }
            if AppState.shared.isServerRunning {
                self.service.stop()
            } else {
                self.service.start()
            }
        }
        
        AppState.shared.onQuitApp = { [weak self] in
            self?.service.stop()
            NSApp.terminate(nil)
        }
        
        // 1. Setup UI Window
        let contentView = ControlWindowView()
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 530, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "iPhone Extended Display"
        window.contentView = NSHostingView(rootView: contentView)
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        
        // 2. Start Service
        service.start()
        
        // 3. Bring to front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true // Menutup jendela pop up (tombol X merah) akan mematikan aplikasi secara bersih
    }
    
    public func applicationWillTerminate(_ aNotification: Notification) {
        print("[App] Terminating iPhone Extended Display...")
        service.stop()
    }
}
