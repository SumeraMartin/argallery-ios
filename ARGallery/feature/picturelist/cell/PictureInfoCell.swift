import UIKit

class PictureInfoCell: BaseCollectionViewCell {
    
    static let identifier = "picture_info_cell"
    
    @IBOutlet weak var title: UILabel!
    
    func bind(picture: Picture) {
        contentView.layer.cornerRadius = 100
        
        title.text = picture.title
    }
}
