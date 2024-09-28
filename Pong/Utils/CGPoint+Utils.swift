
import UIKit

extension CGPoint {

    func inverted() -> CGPoint {
        return CGPoint(x: -self.x, y: -self.y)
    }

    func multiplied(by factor: CGFloat) -> CGPoint {
        return CGPoint(x: self.x * factor, y: self.y * factor)
    }
}
