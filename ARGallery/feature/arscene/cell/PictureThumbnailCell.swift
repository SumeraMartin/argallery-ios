import UIKit

class PicureThumbnailCell : BaseCollectionViewCell {
    
    static let identifier = "picture_thumbnail_cell"
    
    @IBOutlet weak var pictureView: UIImageView!
    
    func bind(_ picture: Picture, onClick: @escaping (Picture) -> Void) {
        if let url = picture.url {
            pictureView.af_setImage(withURL: url, completion: { _ in
                
            })
        }
        
        pictureView.rx.tapGesture().when(.recognized)
            .subscribe(onNext: { _ in onClick(picture) })
            .disposed(by: self.disposeBagCell)
    }
}


