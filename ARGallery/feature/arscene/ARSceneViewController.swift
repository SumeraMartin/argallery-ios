import ReactorKit
import RxSwift
import ARKit

class ARSceneViewController: BaseViewController, ReactorKit.View  {
  
    static let sequeIdentifier = "show_arscene_seque"
    
    var trackState = WallTrackState.findFirstPoint
    
    var wandIsRecharging = false
    var walls = [(wallNode:SCNNode, wallStartPosition:SCNVector3, wallEndPosition:SCNVector3, wallId:String)]()
    var ambientLightNode:SCNNode?
    var carryNode:SCNNode!
    
    var pictureNode: SCNNode?
    
    var trackPictureMovement = true
    
    @IBOutlet weak var scene: ARSCNView!
    
    @IBOutlet weak var resetButton: UIButton!
    
    let timeInterval = RxTimeInterval(0.016) // 60 FPS
    
    let sessionDelegate = ARSessionRxDelegate()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addTapGestureToSceneView()
        configureLighting()
        
        reactor = assembler.reactorProvider.createArSceneReactor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        pauseSession()
    }
    
    func bind(reactor: ARSceneReactor) {
        let isTrackingFirstNode = reactor.state
            .getChange { state in state.isTrackingFirstNode }
            .filter { $0 }
        
        let isNotTrackingFirstNode = reactor.state
            .getChange { state in state.isTrackingFirstNode }
            .filter { $0 == false }
        
        let isTrackingNextNode = reactor.state
            .getChange { state in state.isTrackingNextNode }
            .filter { $0 }
        
        let isNotTrackingNextNode = reactor.state
            .getChange { state in state.isTrackingNextNode }
            .filter { $0 == false }
        
        let isTrackingPictureNode = reactor.state
            .getChange { state in state.isTrackingPicture }
            .filter { $0 }
        
        let isNotTrackingPictureNode = reactor.state
            .getChange { state in state.isTrackingPicture }
            .filter { $0 == false }
        
        let isPictureNodeIdle = reactor.state
            .getChange { state in state.isPictureIdle }
            .filter { $0 }
        
        let isNotPictureNodeIdle = reactor.state
            .getChange { state in state.isPictureIdle }
            .filter { $0 == false }
        
        self.rx.viewWillAppear
            .map { _ in .viewWillAppear }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        resetButton.rx.tapGesture().when(.recognized)
            .map { _ in .resetSessionClicked }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Reset ar session
        resetButton.rx.tapGesture().when(.recognized)
            .subscribe(onNext: { _ in
                self.pauseSession()
                self.startSession()
            })
            .disposed(by: self.disposeBag)
        
        // Detect anchor and create floor plane
        reactor.state
            .getChange { state in state.isAnchorDetected }
            .filter { isAnchorDetected in isAnchorDetected == false }
            .flatMapLatest { _ in self.sessionDelegate.didAddNodeSubject.take(1) }
            .flatMap { (_, node, anchor) in self.createFloorPlane(node, anchor) }
            .map { anchorIdentifier in ARSceneReactor.Action.anchorDetected(identifier: anchorIdentifier) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        isTrackingFirstNode
            .flatMap { _ in Observable<Int>.interval(self.timeInterval, scheduler: MainScheduler.instance).takeUntil(isNotTrackingFirstNode) }
            .observeOn(MainScheduler.asyncInstance)
            .flatMapLatest { _ in reactor.state.take(1).filter { $0.anchorIdentifier != nil } }
            .flatMapLatest { state in self.trackFirstWallNode(for: state.anchorIdentifier!, previousNode: state.initialTrackingNode) }
            .map { node in ARSceneReactor.Action.initialTrackingNodeUpdated(trackingNode: node) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        isTrackingFirstNode
            .flatMapLatest{ _ in self.view.rx.tapGesture().when(.recognized).take(1) }
            .withLatestFrom(self.reactor!.state)
            .map { state in state.initialTrackingNode!.clone() }
//              .map { state in
//                let node = state.initialTrackingNode!
//                let newNode = TrackingNode.nodeWithoutWall(position: node.position)
//            }
            .map { newNode in ARSceneReactor.Action.initialTrackingNodeAnchored(nextTrackingNode: newNode) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        isTrackingNextNode
            .flatMap { _ in Observable<Int>.interval(self.timeInterval, scheduler: MainScheduler.instance).takeUntil(isNotTrackingNextNode) }
            .observeOn(MainScheduler.asyncInstance)
            .flatMapLatest { _ in reactor.state.take(1).filter { $0.anchorIdentifier != nil } }
            .flatMapLatest { state in
                self.trackNextWallNode(for: state.anchorIdentifier!, previousNode: state.lastAnchoredWallNode(), currentNode: state.nextTrackingNode)
            }
            .map { node in ARSceneReactor.Action.nextTrackingNodeUpdated(trackingNode: node) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        isTrackingNextNode
            .flatMapLatest { _ in self.view.rx.tapGesture().when(.recognized).takeUntil(isNotTrackingNextNode) }
            .withLatestFrom(self.reactor!.state)
            .filter { state in state.anchoredWallNodes.count < 5 }
            .map { state in state.nextTrackingNode!.clone()  }
//            .map { state in state.nextTrackingNode!.childNode(withName: "end_node", recursively: true)!.clone() }
            .map { node in ARSceneReactor.Action.nextTrackingNodeAnchored(nextTrackingNode: node) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        isTrackingNextNode
            .flatMapLatest { _ in self.view.rx.tapGesture().when(.recognized).takeUntil(isNotTrackingNextNode) }
            .withLatestFrom(self.reactor!.state)
            .filter { state in state.anchoredWallNodes.count >= 5 }
            .map { state in state.nextTrackingNode!.clone()  }
            //            .map { state in state.nextTrackingNode!.childNode(withName: "end_node", recursively: true)!.clone() }
            .map { node in ARSceneReactor.Action.lastTrackingNodeAnchored(lastTrackingNode: node) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        isTrackingPictureNode
            .flatMapLatest { _ in isNotPictureNodeIdle }
            .flatMapLatest { _ in Observable<Int>.interval(self.timeInterval, scheduler: MainScheduler.instance)
                .takeUntil(isNotTrackingPictureNode)
                .takeUntil(isPictureNodeIdle)
            }
            .withLatestFrom(self.reactor!.state)
            .observeOn(MainScheduler.asyncInstance)
            .flatMapLatest { state in self.trackingPictureNode(pictureNode: state.pictureNode) }
            .map { node in ARSceneReactor.Action.pictureNodeUpdated(pictureNode: node) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        isTrackingPictureNode
            .flatMapLatest { _ in isNotPictureNodeIdle }
            .flatMapLatest { _ in self.view.rx.tapGesture().when(.recognized).take(1) }
            .map { node in ARSceneReactor.Action.pausePictureNodeTracking }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        isPictureNodeIdle
            .flatMapLatest{ _ in self.view.rx.tapGesture().when(.recognized).take(1) }
            .map { node in ARSceneReactor.Action.resumePictureNodeTracking }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Show/Hide featured points
        reactor.state.getChange { $0.isAnchorDetected }
            .subscribe(onNext: { isAnchorDetected in
                if isAnchorDetected {
                    self.scene.debugOptions = []
                } else {
                    self.scene.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    var addedNodes = 0
    var trackingNode = SCNNode()
    
    @objc func didTap(_ sender:UITapGestureRecognizer) {
    //        let location = sender.location(in: scene)
        
//        if addedNodes < 5 {
//            guard let planeData = anyPlaneFrom(location: self.view.center) else { return }
//
//            trackingNode = TrackingNode.node(from: planeData.1,
//                                                 to: nil)
//            scene.scene.rootNode.addChildNode(trackingNode)
//
//            trackState = .findScondPoint(trackingNode: trackingNode,
//                                         wallStartPosition: planeData.1,
//                                         originAnchor: planeData.2)
//
//            addedNodes += 1
//        }
        
        trackPictureMovement = !trackPictureMovement
    }
    
    func trackingPictureNode(pictureNode: SCNNode?) -> Observable<SCNNode> {
        return Observable.create { observer in
            if let planeData = self.test(location: self.view.center) {
                
                var node = pictureNode
                if node == nil {
                    node = PictureNode.node(at: planeData.1, eulerAngles: planeData.2)
                    self.scene.scene.rootNode.addChildNode(node!)
                }
                
                let actionMove = SCNAction.move(to: planeData.1, duration: 0.1)
                let actionRotate = SCNAction.rotateTo(x: CGFloat(planeData.2.x), y: CGFloat(planeData.2.y), z: CGFloat(planeData.2.z), duration: 0.1    )
                let actionSequence = SCNAction.group([actionMove, actionRotate])
                node!.runAction(actionSequence)
                //        pictureNode?.position = planeData.1
                //        pictureNode?.eulerAngles = planeData.2
                
                observer.onNext(node!)
            }
            return Disposables.create()
        }
    }
    
    private func createFloorPlane(_ node: SCNNode, _ anchor: ARAnchor) -> Observable<UUID> {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { fatalError("Unknown anchor type") }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        plane.cornerRadius = CGFloat(100)
        plane.materials.first?.diffuse.contents = UIImage(named: "grid-material.png")
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.scale = SCNVector3(3, 3, 0)
        
        node.addChildNode(planeNode)
        
        planeNode.opacity = 0
        let fadeIn = SCNAction.fadeIn(duration: 0.5)
        let fadeOut = SCNAction.fadeOut(duration: 2)
//        planeNode.runAction(SCNAction.sequence([fadeIn, fadeOut]))
        
        return Observable.just(anchor.identifier)
    }
    
    private func trackFirstWallNode(for anchorIdentifier: UUID, previousNode: SCNNode?) -> Observable<SCNNode> {
        return Observable.create { observer in
            let resultOrNil = self.anyPlaneFrom(location: self.view.center, for: anchorIdentifier)
            if let (_, hitLocation, _) = resultOrNil {
                previousNode?.removeFromParentNode()
                
                let node = TrackingNode.nodeWithWall(from: hitLocation, to: hitLocation)
                self.scene.scene.rootNode.addChildNode(node)
                observer.onNext(node)
            }
            return Disposables.create()
        }
    }
    
    private func trackNextWallNode(for anchorIdentifier: UUID, previousNode: SCNNode, currentNode: SCNNode?) -> Observable<SCNNode> {
        return Observable.create { observer in
            let resultOrNil = self.anyPlaneFrom(location: self.view.center, for: anchorIdentifier)
            if let (_, hitLocation, _) = resultOrNil {
                currentNode?.removeFromParentNode()

                var nodeWithPosition = previousNode.childNode(withName: "end_node", recursively: true)
                if nodeWithPosition == nil {
                    nodeWithPosition = previousNode
                }
                
                let node = TrackingNode.nodeWithWall(from: nodeWithPosition!.position, to: hitLocation)
                self.scene.scene.rootNode.addChildNode(node)
                observer.onNext(node)
            }
            return Disposables.create()
        }
    }
    
    private func startSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        scene.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        scene.delegate = sessionDelegate
        scene.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    private func pauseSession() {
        scene.session.pause()
    }
    
    private func configureLighting() {
        scene.autoenablesDefaultLighting = true
        scene.automaticallyUpdatesLighting = true
    }
    
    private func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
        scene.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func anyPlaneFrom(location: CGPoint, for anchorIdentifier: UUID) -> (SCNNode, SCNVector3, ARPlaneAnchor)? {
        let results = scene.hitTest(location, types: ARHitTestResult.ResultType.existingPlane)
        guard results.count > 0 else { return nil }
        
        let resultOrNil = results.first(where: { $0.anchor?.identifier == anchorIdentifier })
        guard let result = resultOrNil else { return nil }
        
        let anchorOrNil = result.anchor as? ARPlaneAnchor
        guard let anchor = anchorOrNil else { return nil }
        
        let nodeOrNil = scene.node(for: anchor)
        guard let node = nodeOrNil else { return nil }
        
        let location = SCNVector3Make(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
        return (node, location, anchor)
    }
    
    func updateWallTracking(anchordIdentifier: UUID) {
        guard case .findScondPoint(let trackingNode, let wallStartPosition, let originAnchor) = trackState,
            let planeData = anyPlaneFrom(location: self.view.center, for: anchordIdentifier),
            planeData.2 == originAnchor else { return }
        
        trackingNode.removeFromParentNode()
        let newTrackingNode = TrackingNode.nodeWithWall(from: wallStartPosition,
                                                to: planeData.1)
        scene.scene.rootNode.addChildNode(newTrackingNode)
        trackState = .findScondPoint(trackingNode: newTrackingNode,
                                     wallStartPosition: wallStartPosition,
                                     originAnchor: originAnchor)
    }
    
    private func test(location:CGPoint, usingExtent:Bool = false) -> (SCNNode, SCNVector3, SCNVector3)? {
        let results = scene.hitTest(location)
        
        print("results")
        print(results.count)
        
        if results.count == 0 { return nil }
        
        guard results[0].node.name == Wall.NAME else { return nil }
        
        let node = results[0].node
        return (node,results[0].worldCoordinates,  results[0].node.eulerAngles)
    }
    
    var nodeAdded = false
    
    var anchorId = UUID()
}

extension ARSceneViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        
//        if (nodeAdded) {
//            return
//        }
//
//        nodeAdded = true
//
//        anchorId = anchor.identifier
//
//        // 1
//        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
//
//        // 2
//        let width = CGFloat(planeAnchor.extent.x)
//        let height = CGFloat(planeAnchor.extent.z)
//        let plane = SCNPlane(width: width, height: height)
//        plane.cornerRadius = CGFloat(100)
//
//        // 3
//        plane.materials.first?.diffuse.contents = UIImage(named: "grid-material.png")
//
//        // 4
//        let planeNode = SCNNode(geometry: plane)
//
//        // 5
//        let x = CGFloat(planeAnchor.center.x)
//        let y = CGFloat(planeAnchor.center.y)
//        let z = CGFloat(planeAnchor.center.z)
//        planeNode.position = SCNVector3(x,y,z)
//        planeNode.eulerAngles.x = -.pi / 2
//        planeNode.scale = SCNVector3(3, 3, 0)
//
//        // 6
//        node.addChildNode(planeNode)
//
//        scene.debugOptions = []
//
//        planeNode.opacity = 0
//        let fadeIn = SCNAction.fadeIn(duration: 0.5)
//        let fadeOut = SCNAction.fadeOut(duration: 2)
//        planeNode.runAction(SCNAction.sequence([fadeIn, fadeOut]))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let lightEstimate = scene.session.currentFrame?.lightEstimate,
            let ambientLight = ambientLightNode?.light {
            ambientLight.temperature = lightEstimate.ambientColorTemperature
            ambientLight.intensity = lightEstimate.ambientIntensity
        }
        
        if addedNodes < 5 {
            //TODO: DO NOT do this for every frame, that is kind of crazy. Do it via a timer!
//            DispatchQueue.main.async(execute: updateWallTracking)
        } else if trackPictureMovement {
//            DispatchQueue.main.async(execute: trackImage)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }

        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height

        // 3
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
}
