import UIKit

class DetailsBottomSheetCell: BaseTableViewCell {
    
    static let identifier = "bottom_sheet_details_cell"
    
    @IBOutlet weak var year: UILabel!
    
    @IBOutlet weak var price: UILabel!
    
    func bind(_ picture: Picture) {
        year.text = String(format: "%.0f", picture.year)
        price.text = String(format: "%.0f", picture.price)
    }
}
