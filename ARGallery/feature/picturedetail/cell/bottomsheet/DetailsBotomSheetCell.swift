import UIKit

class DetailsBottomSheetCell: BaseTableViewCell {
    
    static let identifier = "bottom_sheet_details_cell"
    
    @IBOutlet weak var year: UILabel!
    
    func bind(_ picture: Picture) {
        year.text = String(picture.price)
    }
}
