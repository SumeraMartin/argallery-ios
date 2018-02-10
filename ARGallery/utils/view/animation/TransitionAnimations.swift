import UIKit

struct Transitions {
    
    enum TransitionType {
        case rollUp
    }
    
    struct Transition {
        let type: TransitionType
        let containerView: UIView
        let sourceView: UIView
        let destinationView: UIView
        let duration: TimeInterval
        let mainView: UIView?
        let info: [String: Any]
        let context: UIViewControllerContextTransitioning
        let mode: TransitionAnimator.TransitionMode
    }
    
    static func animate(_ transition: Transition) {
        switch transition.type {
        case .rollUp:
            Transitions.RollUp(transition)
        }
    }
    
    static var RollUp: (Transition) -> Void {
        return { transition in
            guard let contentViewBottomConstraint = transition.info["contentViewBottomConstraint"] as? NSLayoutConstraint,
                let contentViewHeight = transition.info["contentViewHeight"] as? CGFloat
                else {
                    return
            }
            if transition.mode == .presenting {
                if let snapshotViewOfSource = transition.sourceView.snapshotView(afterScreenUpdates: false) {
                    transition.containerView.addSubview(snapshotViewOfSource)
                }
                transition.containerView.addSubview(transition.destinationView)
                
                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: {
                    transition.mainView?.alpha = 1.0
                }) { _ in
                    UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: {
                        contentViewBottomConstraint.constant = 0.0
                        transition.destinationView.layoutIfNeeded()
                    }) { _ in
                        transition.context.completeTransition(true)
                    }
                }
            } else {
                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseIn, animations: {
                    contentViewBottomConstraint.constant = contentViewHeight
                    transition.destinationView.layoutIfNeeded()
                }) { _ in
                    UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseIn, animations: {
                        transition.mainView?.alpha = 0.0
                    }) { _ in
                        transition.context.completeTransition(true)
                    }
                }
            }
        }
    }
}
