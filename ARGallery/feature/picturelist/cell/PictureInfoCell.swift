import UIKit

class PictureInfoCell: BaseCollectionViewCell {
    
    static let identifier = "picture_info_cell"
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var author: UILabel!
    
    func bind(picture: Picture) {
        contentView.layer.cornerRadius = 100
        
        title.text = picture.title
        author.text = picture.author + " (" + String(format: "%.0f", picture.year) + ")"
    }
}
