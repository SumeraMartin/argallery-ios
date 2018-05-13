import UIKit
import RxSwift

class DescriptionBottomSheetCell: BaseTableViewCell {
    
    static let identifier = "bottom_sheet_description_cell"

    @IBOutlet weak var descriptionText: UILabel!
    
    func bind(_ picture: Picture) {
        descriptionText.text = picture.description
    }
}
