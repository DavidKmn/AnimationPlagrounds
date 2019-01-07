import UIKit

private enum State {
    case opened
    case closed
}


extension State {
    var oposite: State {
        switch self {
        case .opened:
            return .closed
        case .closed:
            return .opened
        }
    }
}

class InstantPanGestureRecognizer: UIPanGestureRecognizer {
    // Allows us to enter the began state on touch down
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if (self.state == .began) { return }
        super.touchesBegan(touches, with: event)
        self.state = .began
    }
}

class ViewController: UIViewController {
    
    // UI Elements
    private let popupView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 10
        return view
    }()
    
    private lazy var overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0
        return view
    }()
    
    private lazy var closedTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Reviews"
        label.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium)
        label.textColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var openTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Reviews"
        label.font = UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.heavy)
        label.textColor = .black
        label.textAlignment = .center
        label.alpha = 0
        label.transform = CGAffineTransform(scaleX: 0.65, y: 0.65).concatenating(CGAffineTransform(translationX: 0, y: -15))
        return label
    }()
    
    
    private lazy var instantPanGestureRecognizer: InstantPanGestureRecognizer = { [unowned self] in
        let ipg = InstantPanGestureRecognizer(target: self, action: #selector(handlePopUpViewPan(_:)))
        return ipg
        }()
    
    // Constants
    private let popUpOffset: CGFloat = 440
    private let animationDuration: Double = 1

    // Layout Related
    private var popUpViewBottomConstraint: NSLayoutConstraint?
    
    // Animation Related
    private var currentState: State = .closed
    private var runningAnimators = [UIViewPropertyAnimator]()
    private var animationProgress: [CGFloat] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        popupView.addGestureRecognizer(instantPanGestureRecognizer)
    }
    
    private func setupUI() {
        
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        overlayView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        popupView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(popupView)
        popupView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        popupView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        popUpViewBottomConstraint = popupView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 440)
        popUpViewBottomConstraint?.isActive = true
        popupView.heightAnchor.constraint(equalToConstant: 510).isActive = true
        
        closedTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(closedTitleLabel)
        closedTitleLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor).isActive = true
        closedTitleLabel.trailingAnchor.constraint(equalTo: popupView.trailingAnchor).isActive = true
        closedTitleLabel.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 10).isActive = true
        
        openTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(openTitleLabel)
        openTitleLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor).isActive = true
        openTitleLabel.trailingAnchor.constraint(equalTo: popupView.trailingAnchor).isActive = true
        openTitleLabel.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 20).isActive = true
    }
    
    @objc private func handlePopUpViewPan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            animateTransitionIfNeeded(toState: currentState.oposite, withDuration: animationDuration)
            runningAnimators.forEach { $0.pauseAnimation() }
            animationProgress = runningAnimators.map { $0.fractionComplete }
        case .changed:
            let translation = recognizer.translation(in: popupView)
            var fraction = -translation.y / popUpOffset
            
            // adjust the fraction for the current state and reversed state
            if currentState == .opened { fraction *= -1 }
            if runningAnimators[0].isReversed { fraction *= -1 }
            
            // apply the new fraction
            for (idx, animator) in runningAnimators.enumerated() {
                animator.fractionComplete = fraction + self.animationProgress[idx]
            }
        case .ended:
            let yVelocity = recognizer.velocity(in: popupView).y
            let shouldClose = yVelocity > 0
            
            if yVelocity == 0 {
                runningAnimators.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
                break
            }
            
            switch currentState {
            case .opened:
                if !shouldClose && !runningAnimators[0].isReversed {
                    runningAnimators.forEach { $0.isReversed = !$0.isReversed }
                }
                if shouldClose && runningAnimators[0].isReversed {
                     runningAnimators.forEach { $0.isReversed = !$0.isReversed }
                }
            case .closed:
                if shouldClose && !runningAnimators[0].isReversed {
                     runningAnimators.forEach { $0.isReversed = !$0.isReversed }
                }
                if !shouldClose && runningAnimators[0].isReversed {
                    runningAnimators.forEach { $0.isReversed = !$0.isReversed }
                }
            }
            
            runningAnimators.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
        default: ()
        }
    }

    private func animateTransitionIfNeeded(toState: State, withDuration duration: Double) {
        guard runningAnimators.isEmpty else { return }
        
        // animator for the transition
        let transitionAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
            switch toState {
            case .opened:
                self.popUpViewBottomConstraint?.constant = 0
                self.popupView.layer.cornerRadius = 20
                self.overlayView.alpha = 0.5
                self.closedTitleLabel.transform = CGAffineTransform(scaleX: 1.6, y: 1.6).concatenating(CGAffineTransform(translationX: 0, y: 15))
                self.openTitleLabel.transform = .identity
            case .closed:
                self.popUpViewBottomConstraint?.constant = 440
                self.popupView.layer.cornerRadius = 0
                self.overlayView.alpha = 0
                self.closedTitleLabel.transform = .identity
                self.closedTitleLabel.transform = .identity
                self.openTitleLabel.transform = CGAffineTransform(scaleX: 0.65, y: 0.65).concatenating(CGAffineTransform(translationX: 0, y: -15))
            }
            self.view.layoutIfNeeded()
        }
        
        // Manually update the value of the constraint when the animation is complete, should be done automatically by the animator but explicitly setting it fixes some edge case bugs
        transitionAnimator.addCompletion { (position) in
            switch position {
            case .start: self.currentState = toState.oposite
            case .end: self.currentState = toState
            case .current: ()
            }
            switch self.currentState {
            case .opened: self.popUpViewBottomConstraint?.constant = 0
            case .closed: self.popUpViewBottomConstraint?.constant = self.popUpOffset
            }
            
            self.runningAnimators.removeAll()
        }

        // animator for the title that is transitioning into the view
        let inTitleAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeIn) {
            switch toState {
            case .opened: self.openTitleLabel.alpha = 1
            case .closed: self.closedTitleLabel.alpha = 1
            }
        }
        inTitleAnimator.scrubsLinearly = false
        
        let outTitleAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeOut) {
            switch toState {
            case .opened: self.closedTitleLabel.alpha = 0
            case .closed: self.openTitleLabel.alpha = 0
            }
        }
        outTitleAnimator.scrubsLinearly = false
        
        // start all of the animators
        transitionAnimator.startAnimation()
        inTitleAnimator.startAnimation()
        outTitleAnimator.startAnimation()
        
        runningAnimators.append(transitionAnimator)
        runningAnimators.append(inTitleAnimator)
        runningAnimators.append(outTitleAnimator)
    }
}

import PlaygroundSupport

let vc = ViewController()
vc.preferredContentSize = CGSize(width: 350, height: 812)
PlaygroundPage.current.liveView = vc
