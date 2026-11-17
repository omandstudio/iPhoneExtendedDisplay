import Cocoa
import SwiftUI

public class AppDelegate: NSObject, NSApplicationDelegate {
    public var window: NSWindow!
    public let service = ExtendedDisplayService()
    
    public func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 1. Setup UI Window
        let contentView = ControlWindowView()
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
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
        return false // Keep running in background even if window is closed
    }
    
    public func applicationWillTerminate(_ aNotification: Notification) {
        print("[App] Terminating iPhone Extended Display...")
    }
}
