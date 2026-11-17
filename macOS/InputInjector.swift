import Foundation
import CoreGraphics

public class InputInjector {
    private var targetDisplayID: CGDirectDisplayID = 0
    private var isMouseDown: Bool = false
    
    public init() {}
    
    public func setTargetDisplay(displayID: CGDirectDisplayID) {
        self.targetDisplayID = displayID
    }
    
    public func handleTouch(packet: TouchPacket) {
        guard targetDisplayID != 0 else { return }
        
        let bounds = CGDisplayBounds(targetDisplayID)
        guard bounds.width > 0 && bounds.height > 0 else { return }
        
        // Map normalized (0.0...1.0) coordinates to virtual screen desktop coordinates
        let screenX = bounds.origin.x + (CGFloat(packet.normalizedX) * bounds.width)
        let screenY = bounds.origin.y + (CGFloat(packet.normalizedY) * bounds.height)
        let point = CGPoint(x: screenX, y: screenY)
        
        let phase = TouchPhase(rawValue: packet.phase) ?? .moved
        
        switch phase {
        case .began:
            let eventType: CGEventType = packet.isRightClick ? .rightMouseDown : .leftMouseDown
            let mouseButton: CGMouseButton = packet.isRightClick ? .right : .left
            
            // Move cursor first
            if let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left) {
                moveEvent.post(tap: .cghidEventTap)
            }
            
            if let downEvent = CGEvent(mouseEventSource: nil, mouseType: eventType, mouseCursorPosition: point, mouseButton: mouseButton) {
                downEvent.post(tap: .cghidEventTap)
                isMouseDown = true
            }
            
        case .moved:
            let eventType: CGEventType = isMouseDown ? .leftMouseDragged : .mouseMoved
            let mouseButton: CGMouseButton = .left
            
            if let moveEvent = CGEvent(mouseEventSource: nil, mouseType: eventType, mouseCursorPosition: point, mouseButton: mouseButton) {
                moveEvent.post(tap: .cghidEventTap)
            }
            
        case .ended, .cancelled:
            let eventType: CGEventType = packet.isRightClick ? .rightMouseUp : .leftMouseUp
            let mouseButton: CGMouseButton = packet.isRightClick ? .right : .left
            
            if let upEvent = CGEvent(mouseEventSource: nil, mouseType: eventType, mouseCursorPosition: point, mouseButton: mouseButton) {
                upEvent.post(tap: .cghidEventTap)
                isMouseDown = false
            }
            
        case .stationary:
            break
        }
    }
}

