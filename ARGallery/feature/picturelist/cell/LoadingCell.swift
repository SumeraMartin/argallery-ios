import UIKit
import NVActivityIndicatorView
import RxSwift
import RxCocoa

class LoadingCell: BaseCell {
    
    static let identifier = "loading_cell"
    
    @IBOutlet weak var loading: NVActivityIndicatorView!
    
    @IBOutlet weak var error: UIStackView!
    
    @IBOutlet weak var errorButton: UIButton!
    
    func setLoadingState() {
        loading.isHidden = false
        loading.startAnimating()
        error.isHidden = true
    }
    
    func setErrorState() {
        loading.isHidden = true
        loading.stopAnimating()
        error.isHidden = false
    }
}
