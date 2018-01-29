import UIKit
import RxSwift
import ReactorKit

class BaseViewController: UIViewController, AppAssemblerClient {
    
    var assembler: AppAssemblerType!
    
    var disposeBag = DisposeBag()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if var destinationViewController = segue.destination as? AppAssemblerClient {
            destinationViewController.assembler = self.assembler
        }
    }
}
