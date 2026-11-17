import Foundation
import CoreGraphics

public class VirtualDisplayManager {
    public private(set) var virtualDisplay: AnyObject?
    public private(set) var displayID: CGDirectDisplayID = 0
    public private(set) var width: UInt32 = 0
    public private(set) var height: UInt32 = 0
    public private(set) var refreshRate: Double = 60.0
    public private(set) var isHiDPI: Bool = true
    
    public init() {}
    
    public var isActive: Bool {
        return virtualDisplay != nil && displayID != 0
    }
    
    public func createDisplay(
        width: UInt32,
        height: UInt32,
        name: String = "iOS Extended Display",
        refreshRate: Double = 60.0,
        hiDPI: Bool = true
    ) -> Bool {
        destroyDisplay()
        
        guard let descriptorClass = NSClassFromString("CGVirtualDisplayDescriptor") as? NSObject.Type,
              let displayClass = NSClassFromString("CGVirtualDisplay") as? NSObject.Type,
              let settingsClass = NSClassFromString("CGVirtualDisplaySettings") as? NSObject.Type,
              let modeClass = NSClassFromString("CGVirtualDisplayMode") as? NSObject.Type else {
            print("[VirtualDisplay] Error: CGVirtualDisplay classes not found in runtime.")
            return false
        }
        
        print("[VirtualDisplay] Initializing \(width)x\(height) @ \(refreshRate)Hz (HiDPI: \(hiDPI))...")
        
        // 1. Create Descriptor using verified CoreGraphics properties
        let descriptor = descriptorClass.init()
        let serialQueue = DispatchQueue(label: "com.openextended.vdqueue", qos: .userInteractive)
        descriptor.setValue(serialQueue, forKey: "queue")
        descriptor.setValue(name, forKey: "name")
        descriptor.setValue(max(width, 1920), forKey: "maxPixelsWide")
        descriptor.setValue(max(height, 1080), forKey: "maxPixelsHigh")
        descriptor.setValue(CGSize(width: 300, height: 200), forKey: "sizeInMillimeters")
        descriptor.setValue(UInt32(0x1337), forKey: "vendorID")
        descriptor.setValue(UInt32(0x4242), forKey: "productID")
        descriptor.setValue(UInt32(1), forKey: "serialNum")
        
        // 2. Instantiate Virtual Display
        let selInitWithDesc = NSSelectorFromString("initWithDescriptor:")
        guard let displayObj = displayClass.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue() else {
            print("[VirtualDisplay] Error: Failed to allocate CGVirtualDisplay.")
            return false
        }
        
        guard displayObj.responds(to: selInitWithDesc) else {
            print("[VirtualDisplay] Error: initWithDescriptor: selector not found on CGVirtualDisplay.")
            return false
        }
        
        let displayInit = displayObj.perform(selInitWithDesc, with: descriptor)?.takeRetainedValue()
        guard let display = displayInit else {
            print("[VirtualDisplay] Error: Failed to initialize CGVirtualDisplay.")
            return false
        }
        
        // 3. Create Display Modes & Settings
        let settings = settingsClass.init()
        
        // Primary mode
        let modeInstance = createMode(modeClass: modeClass, width: width, height: height, rate: refreshRate)
        if let modeInstance = modeInstance {
            settings.setValue([modeInstance], forKey: "modes")
        }
        settings.setValue(hiDPI ? 1 : 0, forKey: "hiDPI")
        
        // 4. Apply Settings
        let selApply = NSSelectorFromString("applySettings:")
        if display.responds(to: selApply) {
            let applied = display.perform(selApply, with: settings) != nil
            if !applied {
                print("[VirtualDisplay] Warning: applySettings returned false or nil")
            }
        }
        
        // 5. Query displayID
        if let idVal = display.value(forKey: "displayID") as? UInt32 {
            self.displayID = idVal
            self.virtualDisplay = display
            self.width = width
            self.height = height
            self.refreshRate = refreshRate
            self.isHiDPI = hiDPI
            print("[VirtualDisplay] ✅ Virtual display created successfully! CGDirectDisplayID: \(self.displayID)")
            return true
        } else {
            print("[VirtualDisplay] Error: Could not read displayID property.")
            return false
        }
    }
    
    private func createMode(modeClass: NSObject.Type, width: UInt32, height: UInt32, rate: Double) -> NSObject? {
        let allocMode = modeClass.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue()
        
        typealias InitModeFunc = @convention(c) (AnyObject, Selector, UInt32, UInt32, Double) -> AnyObject
        let sel = NSSelectorFromString("initWithWidth:height:refreshRate:")
        
        if let method = allocMode?.method(for: sel) {
            let fn = unsafeBitCast(method, to: InitModeFunc.self)
            let instance = fn(allocMode!, sel, width, height, rate)
            return instance as? NSObject
        }
        return nil
    }
    
    public func getDisplayBounds() -> CGRect? {
        guard displayID != 0 else { return nil }
        return CGDisplayBounds(displayID)
    }
    
    public func destroyDisplay() {
        if virtualDisplay != nil {
            print("[VirtualDisplay] Unplugging virtual display ID: \(displayID)...")
            virtualDisplay = nil
            displayID = 0
            width = 0
            height = 0
        }
    }
    
    deinit {
        destroyDisplay()
    }
}
