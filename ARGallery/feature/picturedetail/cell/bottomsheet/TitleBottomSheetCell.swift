import UIKit

class TitleBottomSheetCell: BaseTableViewCell {
    
    static let identifier = "bottom_sheet_title_cell"
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var arSceneIcon: UIImageView!
    
    var delegate: ARIconTapDelegate? = nil
    
    func bind(_ picture: Picture) {
        title.text = picture.title
        
        arSceneIcon.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { _ in
                self.delegate?.tap()
            })
            .disposed(by: self.disposeBagCell)
    }
}

protocol ARIconTapDelegate {
    
    func tap()
}
