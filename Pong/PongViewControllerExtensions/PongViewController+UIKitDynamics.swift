

import UIKit

extension PongViewController {
    
  
    func enableDynamics() {
        ballView.tag = Constants.ballTag
        userPaddleView.tag = Constants.userPaddleTag
        enemyPaddleView.tag = Constants.enemyPaddleTag

        let dynamicAnimator = UIDynamicAnimator(referenceView: self.view)
        self.dynamicAnimator = dynamicAnimator

        let collisionBehavior = UICollisionBehavior(items: [ballView, userPaddleView, enemyPaddleView])
        collisionBehavior.collisionDelegate = self
        collisionBehavior.collisionMode = .everything
        collisionBehavior.translatesReferenceBoundsIntoBoundary = true
        self.collisionBehavior = collisionBehavior
        dynamicAnimator.addBehavior(collisionBehavior)

        let ballDynamicBehavior = UIDynamicItemBehavior(items: [ballView])
        ballDynamicBehavior.allowsRotation = false
        ballDynamicBehavior.elasticity = 1.0
        ballDynamicBehavior.friction = 0.0
        ballDynamicBehavior.resistance = 0.0
        self.ballDynamicBehavior = ballDynamicBehavior
        dynamicAnimator.addBehavior(ballDynamicBehavior)

        let userPaddleDynamicBehavior = UIDynamicItemBehavior(items: [userPaddleView])
        userPaddleDynamicBehavior.allowsRotation = false
        userPaddleDynamicBehavior.density = 100000
        self.userPaddleDynamicBehavior = userPaddleDynamicBehavior
        dynamicAnimator.addBehavior(userPaddleDynamicBehavior)

        let enemyPaddleDynamicBehavior = UIDynamicItemBehavior(items: [enemyPaddleView])
        enemyPaddleDynamicBehavior.allowsRotation = false
        enemyPaddleDynamicBehavior.density = 100000
        self.enemyPaddleDynamicBehavior = enemyPaddleDynamicBehavior
        dynamicAnimator.addBehavior(enemyPaddleDynamicBehavior)

        let attachmentBehavior = UIAttachmentBehavior.slidingAttachment(
            with: enemyPaddleView,
            attachmentAnchor: .zero,
            axisOfTranslation: CGVector(dx: 1.0, dy: 0.0)
        )
        dynamicAnimator.addBehavior(attachmentBehavior)
    }
}

extension PongViewController: UICollisionBehaviorDelegate {


    /// Эта функция обрабатывает столкновения объектов
    func collisionBehavior(
        _ behavior: UICollisionBehavior,
        beganContactFor item1: UIDynamicItem,
        with item2: UIDynamicItem,
        at p: CGPoint
    ) {
        /// Пытаемся опеределить являются ли столкнувшиеся объекты элементами отображения
        guard
            let view1 = item1 as? UIView,
            let view2 = item2 as? UIView
        else { return }

        /// Получаем имена столкнувшихся элементов по тэгу
        let view1Name: String = getNameFromViewTag(view1)
        let view2Name: String = getNameFromViewTag(view2)

        /// Печатаем названия столкнувшихся элементов
        print("\(view1Name) has hit \(view2Name)")

        if let ballDynamicBehavior = self.ballDynamicBehavior {
            ballDynamicBehavior.addLinearVelocity(
                ballDynamicBehavior.linearVelocity(for: self.ballView).multiplied(by: Constants.ballAccelerationFactor),
                for: self.ballView
            )
        }

        if view1.tag == Constants.ballTag || view2.tag == Constants.ballTag {
            animateBallHit(at: p)
            playHitSound(.mid)
            lightImpactFeedbackGenerator.impactOccurred()
        }
    }

    func collisionBehavior(
        _ behavior: UICollisionBehavior,
        beganContactFor item: UIDynamicItem,
        withBoundaryIdentifier identifier: NSCopying?,
        at p: CGPoint
    ) {
        guard
            identifier == nil,
            let itemView = item as? UIView,
            itemView.tag == Constants.ballTag
        else { return }

        animateBallHit(at: p)

        var shouldResetBall: Bool = false
        if abs(p.y) <= Constants.contactThreshold {
         
            userScore += 1
            shouldResetBall = true
            print("Ball has hit enemy side. User score is now: \(userScore)")
        } else if abs(p.y - view.bounds.height) <= Constants.contactThreshold {
           
            shouldResetBall = true
            print("Ball has hit user side.")
        }

        if shouldResetBall {
            resetBallWithAnimation()
            playHitSound(.high)
            rigidImpactFeedbackGenerator.impactOccurred()
        } else {
            playHitSound(.low)
            softImpactFeedbackGenerator.impactOccurred()
        }
    }


    private func getNameFromViewTag(_ view: UIView) -> String {
        switch view.tag {
        case Constants.ballTag:
            return "Ball"

        case Constants.userPaddleTag:
            return "User Paddle"

        case Constants.enemyPaddleTag:
            return "Enemy Paddle"

        default:
            return "?"
        }
    }
}

extension PongViewController {

    
    private func resetBallWithAnimation() {
        stopBallMovement()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.resetBallViewPositionAndAnimateBallAppear()
        }
    }

    private func stopBallMovement() {
        if let ballPushBehavior = self.ballPushBehavior {
            self.ballPushBehavior = nil
            ballPushBehavior.active = false
            dynamicAnimator?.removeBehavior(ballPushBehavior)
        }

        if let ballDynamicBehavior = self.ballDynamicBehavior {
            ballDynamicBehavior.addLinearVelocity(
                ballDynamicBehavior.linearVelocity(for: self.ballView).inverted(),
                for: self.ballView
            )
        }

        dynamicAnimator?.updateItem(usingCurrentState: self.ballView)
    }

    private func resetBallViewPositionAndAnimateBallAppear() {
        resetBallViewPosition()
        dynamicAnimator?.updateItem(usingCurrentState: self.ballView)

        ballView.alpha = 0.0
        ballView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)

        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                self.ballView.alpha = 1.0
                self.ballView.transform = .identity
            },
            completion: { [weak self] _ in
                self?.hasLaunchedBall = false
            }
        )
    }

    private func resetBallViewPosition() {
        ballView.transform = .identity

        let ballSize: CGSize = ballView.frame.size
        ballView.frame = CGRect(
            origin: CGPoint(
                x: (view.bounds.width - ballSize.width) / 2,
                y: (view.bounds.height - ballSize.height) / 2
            ),
            size: ballSize
        )
    }
}
