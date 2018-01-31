import UIKit
import RxSwift

class BaseTableViewCell: UITableViewCell {
    
    var disposeBagCell = DisposeBag()
    
    override func prepareForReuse() {
        disposeBagCell = DisposeBag()
    }
}
