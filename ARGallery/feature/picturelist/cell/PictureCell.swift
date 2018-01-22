import UIKit

class PictureCell : BaseCell {
    
    static let identifier = "picture_cell"
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var background: UIImageView!
    
    @IBOutlet weak var picture: UIImageView!
}

