import UIKit
import RxSwift

extension Reactive where Base: UITableView {
    
    func reachedBottom() -> Observable<Void> {
        return contentOffset
            .throttle(0.3, scheduler: MainScheduler.instance)
            .filter { offset in offset.y + self.base.frame.size.height + 20.0 > self.base.contentSize.height }
            .map { _ in Void() }
    }
}
