

import UIKit

extension PongViewController {


    func enabledPanGestureHandling() {
        let panGestureRecognizer = UIPanGestureRecognizer()

        view.addGestureRecognizer(panGestureRecognizer)

        panGestureRecognizer.addTarget(self, action: #selector(self.handlePanGesture(_:)))

        self.panGestureRecognizer = panGestureRecognizer
    }

    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
           
            lastUserPaddleOriginLocation = userPaddleView.frame.origin.x

        case .changed:
           
            let translation: CGPoint = recognizer.translation(in: view)
            let translatedOriginX: CGFloat = lastUserPaddleOriginLocation + translation.x

            let platformWidthRatio = userPaddleView.frame.width / view.bounds.width
            let minX: CGFloat = 0
            let maxX: CGFloat = view.bounds.width * (1 - platformWidthRatio)
            userPaddleView.frame.origin.x = min(max(translatedOriginX, minX), maxX)
            dynamicAnimator?.updateItem(usingCurrentState: userPaddleView)

        default:
            break
        }
    }
}
