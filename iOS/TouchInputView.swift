#if canImport(UIKit)
import UIKit

public class TouchInputView: UIView {
    public var onTouch: ((_ phase: TouchPhase, _ normalizedX: Double, _ normalizedY: Double, _ isRightClick: Bool) -> Void)?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        emit(touch: touch, phase: .began)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        emit(touch: touch, phase: .moved)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        emit(touch: touch, phase: .ended)
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        emit(touch: touch, phase: .cancelled)
    }
    
    private func emit(touch: UITouch, phase: TouchPhase) {
        let loc = touch.location(in: self)
        let normX = Double(max(0.0, min(1.0, loc.x / bounds.width)))
        let normY = Double(max(0.0, min(1.0, loc.y / bounds.height)))
        let isTwoFinger = (touch.gestureRecognizers?.count ?? 0) > 1
        
        onTouch?(phase, normX, normY, isTwoFinger)
    }
}
#endif

