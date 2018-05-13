import UIKit

protocol TransitionAnimatorDelegate: class {
    var transitionType: Transitions.TransitionType { get }
    var duration: TimeInterval { get }
    var mainView: UIView? { get }
    var info: [String: Any] { get }
}

extension TransitionAnimatorDelegate {
    var duration: TimeInterval? { return nil }
    var mainView: UIView? { return nil }
    var constraints: [String: NSLayoutConstraint?] { return [:] }
}

class TransitionAnimator: NSObject {
    
    weak var delegate: TransitionAnimatorDelegate?
    
    enum TransitionMode {
        case presenting
        case dismissing
    }
    
    fileprivate var transitionMode: TransitionMode = .presenting
    fileprivate let defaultDuration: TimeInterval = 0.2
}

extension TransitionAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard let duration = delegate?.duration else {
            return defaultDuration
        }
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let oldView = transitionContext.view(forKey: .from) else {
            return
        }
        guard let newView = transitionContext.view(forKey: .to) else {
            return
        }
        guard let delegate = delegate else {
            return
        }
        let containerView = transitionContext.containerView
        let sourceView = transitionMode == .presenting ? oldView : newView
        let destinationView = transitionMode == .presenting ? newView : oldView
        
        let transition = Transitions.Transition(type: delegate.transitionType, containerView: containerView, sourceView: sourceView, destinationView: destinationView, duration: delegate.duration, mainView: delegate.mainView, info: delegate.info, context: transitionContext, mode: transitionMode)
        
        Transitions.animate(transition)
    }
}

extension TransitionAnimator: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionMode = .presenting
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionMode = .dismissing
        return self
    }
}
