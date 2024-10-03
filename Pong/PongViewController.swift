import UIKit
import AVFoundation

class PongViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    @IBOutlet var ballView: UIView!
    @IBOutlet var userPaddleView: UIView!
    @IBOutlet var enemyPaddleView: UIView!
    @IBOutlet var lineView: UIView!
    @IBOutlet var userScoreLabel: UILabel!

    var panGestureRecognizer: UIPanGestureRecognizer?
    var lastUserPaddleOriginLocation: CGFloat = 0
    var enemyPaddleUpdateTimer: Timer?
    var shouldLaunchBallOnNextTap: Bool = false
    var hasLaunchedBall: Bool = false
    var enemyPaddleUpdatesCounter: UInt8 = 0

    var dynamicAnimator: UIDynamicAnimator?
    var ballPushBehavior: UIPushBehavior?
    var ballDynamicBehavior: UIDynamicItemBehavior?
    var userPaddleDynamicBehavior: UIDynamicItemBehavior?
    var enemyPaddleDynamicBehavior: UIDynamicItemBehavior?
    var collisionBehavior: UICollisionBehavior?

    var audioPlayers: [AVAudioPlayer] = []
    var audioPlayersLock = NSRecursiveLock()
    var softImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    var lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    var rigidImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)

    var backgroundSoundAudioPlayer: AVAudioPlayer? = {
        guard let backgroundSoundURL = Bundle.main.url(forResource: "background", withExtension: "wav"),
              let audioPlayer = try? AVAudioPlayer(contentsOf: backgroundSoundURL) else { return nil }
        audioPlayer.volume = 0.5
        audioPlayer.numberOfLoops = -1
        return audioPlayer
    }()

    var userScore: Int = 0 {
        didSet {
            updateUserScoreLabel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configurePongGame()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.enableDynamics()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ballView.layer.cornerRadius = ballView.bounds.size.height / 2
    }

    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        super.touchesBegan(touches, with: event)
        if shouldLaunchBallOnNextTap, !hasLaunchedBall {
            hasLaunchedBall = true
            launchBall()
        }
    }

    private func configurePongGame() {
        updateUserScoreLabel()
        self.enabledPanGestureHandling()
        self.enableEnemyPaddleFollowBehavior()
        self.shouldLaunchBallOnNextTap = true
        self.backgroundSoundAudioPlayer?.prepareToPlay()
        self.backgroundSoundAudioPlayer?.play()
    }

    private func updateUserScoreLabel() {
        userScoreLabel.text = "\(userScore)"
    }
}
