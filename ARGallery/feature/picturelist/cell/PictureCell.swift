import UIKit

class PictureCell : BaseCollectionViewCell, TransformableCell, SnappableCell {
    
    static let identifier = "picture_cell"
    
    @IBOutlet weak var picture: UIImageView!
    
    func applyTransform(resizePercentage: Float) {
        let scale = CGFloat(1 - resizePercentage)
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: scale, y: scale)
        picture.transform = transform
 
        picture.alpha = CGFloat(1 - resizePercentage)
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Float(1 - resizePercentage * 4)
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = 5
    }
}

