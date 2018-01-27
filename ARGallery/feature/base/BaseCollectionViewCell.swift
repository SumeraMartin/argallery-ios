import UIKit
import RxSwift

class BaseCollectionViewCell: UICollectionViewCell {
    
    var disposeBagCell = DisposeBag()
    
    override func prepareForReuse() {
        disposeBagCell = DisposeBag()
    }
}
