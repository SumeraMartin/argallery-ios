import UIKit
import NVActivityIndicatorView
import RxSwift
import RxCocoa

class LoadingMoreCell: BaseCollectionViewCell, SnappableCell {
    
    static let identifier = "loading_more_cell"
    
    @IBOutlet weak var loadingView: NVActivityIndicatorView!
    
    @IBOutlet weak var tryAgainButton: UIButton!
    
    @IBOutlet weak var errorContainer: UIStackView!
    
    func setLoadingState() {
        loadingView.isHidden = false
        loadingView.startAnimating()
        errorContainer.isHidden = true
    }
    
    func setErrorState() {
        loadingView.isHidden = true
        loadingView.stopAnimating()
        errorContainer.isHidden = false
    }
}
