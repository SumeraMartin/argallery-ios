import ReactorKit
import ARKit

class ARSceneViewController: BaseViewController, ReactorKit.View  {
  
    static let sequeIdentifier = "show_arscene_seque"
    
    @IBOutlet weak var scene: ARSCNView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        scene.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        scene.session.pause()
    }
    
    func bind(reactor: ARSceneReactor) {
        
    }
}


