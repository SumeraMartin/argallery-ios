import UIKit

class TitleBottomSheetCell: BaseTableViewCell {
    
    static let identifier = "bottom_sheet_title_cell"
    
    @IBOutlet weak var title: UILabel!
    
    func bind(_ picture: Picture) {
        title.text = picture.title
    }
}
