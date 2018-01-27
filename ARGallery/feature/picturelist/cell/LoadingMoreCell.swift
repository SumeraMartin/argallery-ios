import UIKit
import NVActivityIndicatorView
import RxSwift
import RxCocoa

class LoadingMoreCell: BaseCollectionViewCell {
    
    static let identifier = "loading_more_cell"
    
    @IBOutlet weak var loadingView: NVActivityIndicatorView!
    
    @IBOutlet weak var tryAgainButton: UIButton!
    
    func setLoadingState() {
        loadingView.isHidden = false
        loadingView.startAnimating()
        tryAgainButton.isHidden = true
    }
    
    func setErrorState() {
        loadingView.isHidden = true
        loadingView.stopAnimating()
        tryAgainButton.isHidden = false
    }
}
