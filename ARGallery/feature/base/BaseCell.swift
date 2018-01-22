import UIKit
import RxSwift

class BaseCell: UITableViewCell {
    
    var disposeBagCell = DisposeBag()
    
    override func prepareForReuse() {
        disposeBagCell = DisposeBag()
    }
}
