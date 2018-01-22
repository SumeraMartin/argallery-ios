import UIKit
import Hero
import ReactorKit

class PictureDetailViewController: BaseViewController, ReactorKit.View  {
    
    static let sequeIdentifier = "show_picture_detail_seque"

    @IBOutlet weak var picture: UIImageView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isHeroEnabled = true
        
        picture.heroID = "Test"
        picture.heroModifiers = [.translate(y:100)]
        
        reactor = assembler.reactorProvider.createPictureDetailReactor()
    }
    
    func bind(reactor: PictureDetailReactor) {
    }
    
}
