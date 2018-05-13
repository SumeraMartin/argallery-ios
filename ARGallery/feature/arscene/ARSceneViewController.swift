import ReactorKit
import RxDataSources
import RxSwift
import ARKit

class ARSceneViewController: BaseViewController, ReactorKit.View  {
  
    typealias PictureSectionType = AnimatableSectionModel<String, PictureThumbnailSectionItem>
    typealias RxPictureDataSource = RxCollectionViewSectionedAnimatedDataSource<PictureSectionType>
    
    static let sequeIdentifier = "show_arscene_seque"
    
    var trackState = WallTrackState.findFirstPoint
    
    var pictureNode: SCNNode?
    
    var trackPictureMovement = true
    
    // MARK: main content views
    
    @IBOutlet weak var scene: ARSCNView!
    
    @IBOutlet weak var menuButton: UIButton!

    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var trackingSurroundingDescription: UILabel!
    
    @IBOutlet weak var addWallDescription: UILabel!
    
    @IBOutlet weak var wallTrackingCompletedButton: UIButton!
    
    @IBOutlet weak var changePictureView: UIImageView!
    
    @IBOutlet weak var screenOverlay: UIView!
    
    @IBOutlet weak var screenshotView: UIImageView!
    
    @IBOutlet weak var anchorPictureButton: UIButton!
    
    @IBOutlet weak var releasePictureButton: UIButton!
    
    @IBOutlet weak var picturesView: UIView!
    
    @IBOutlet weak var picturesViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var picturesViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var allPicturesCollectionView: UICollectionView!
    
    var allPicturesDataSource: RxPictureDataSource!
    
    let timeInterval = RxTimeInterval(0.016) // 60 FPS
    
    let sessionDelegate = ARSessionRxDelegate()
    
    private let pictureMaterial = SCNMaterial()
    
    private var pictureSize = CGSize(width: 1, height: 1)
    
    internal let imageThumbnailClick = PublishSubject<Picture>()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        allPicturesDataSource = createAllPicturesDataSource()
        allPicturesCollectionView.delegate = self
        
        reactor = assembler.reactorProvider.createArSceneReactor()
        
        configureLighting()
        
        picturesViewBottomConstraint.constant = -picturesViewHeightConstraint.constant
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
        
        let anchorIsNotDetected = reactor.state
            .getChange { state in state.isAnchorDetected }
            .filter { isAnchorDetected in isAnchorDetected == false }
        
        let areWallsHidden = reactor.state
            .getChange { state in state.areWallsHidden }
            .filter { areWallsHidden in areWallsHidden == true }
        
        let areWallsShown = reactor.state
            .getChange { state in state.areWallsHidden }
            .filter { areWallsHidden in areWallsHidden == false }
        
        let isPictureListShown = reactor.state
            .getChange { state in state.isPictureListShown }
            .filter { areWallsHidden in areWallsHidden == true }
        
        let isNotPictureListShown = reactor.state
            .getChange { state in state.isPictureListShown }
            .filter { areWallsHidden in areWallsHidden == false }
        
        self.rx.viewWillAppear
            .map { _ in .viewWillAppear }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Close view controller
        closeButton.rx.tapGesture().when(.recognized)
            .subscribe(onNext: { _ in
                self.dismiss(animated: true)
            })
            .disposed(by: self.disposeBag)
        
        // Show all pictures in bottom sheet dialog
        reactor.state.getChange { $0.allPictures }
            .map { allPictures in allPictures.map { picture in
                    let item = PictureThumbnailSectionItem.picture(picture:picture)
                    return AnimatableSectionModel(model: item.identity, items: [item])
                }
            }
            .bind(to: allPicturesCollectionView.rx.items(dataSource: allPicturesDataSource))
            .disposed(by: self.disposeBag)

        // Send viewDidLoad action to reactor
        Observable.just(Void())
            .map { _ in .viewDidLoad }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Open action sheet
        menuButton.rx.tapGesture().when(.recognized)
            .withLatestFrom(reactor.state)
            .flatMapLatest { state in self.showActionSheet(forState: state) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Detect anchor and create floor plane
        anchorIsNotDetected
            .flatMapLatest { _ in self.sessionDelegate.didAddNodeSubject.take(1) }
            .flatMap { (_, node, anchor) in self.createFloorPlane(node, anchor) }
            .map { anchorIdentifier in ARSceneReactor.Action.anchorDetected(identifier: anchorIdentifier) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Perform tracking of initial wall node
        isTrackingFirstNode
            .flatMap { _ in Observable<Int>.interval(self.timeInterval, scheduler: MainScheduler.instance).takeUntil(isNotTrackingFirstNode) }
            .observeOn(MainScheduler.asyncInstance)
            .flatMapLatest { _ in reactor.state.take(1).filter { $0.anchorIdentifier != nil } }
            .flatMapLatest { state in self.trackFirstWallNode(for: state.anchorIdentifier!, previousNode: state.initialTrackingNode) }
            .map { node in ARSceneReactor.Action.initialTrackingNodeUpdated(trackingNode: node) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Anchor initial wall node
        isTrackingFirstNode
            .flatMapLatest{ _ in self.view.rx.tapGesture().when(.recognized).take(1) }
            .withLatestFrom(self.reactor!.state)
            .map { state in state.initialTrackingNode!.clone() }
            .map { newNode in ARSceneReactor.Action.initialTrackingNodeAnchored(nextTrackingNode: newNode) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Perform tracking of another wall node
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
        
        // Anchor another wall node
        isTrackingNextNode
            .flatMapLatest { _ in self.view.rx.tapGesture().when(.recognized).takeUntil(isNotTrackingNextNode) }
            .withLatestFrom(self.reactor!.state)
            .map { state in state.nextTrackingNode!.childNode(withName: "end_node", recursively: true)!.clone()  }
            .map { node in ARSceneReactor.Action.nextTrackingNodeAnchored(nextTrackingNode: node) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Finish anchoring of wall nodes
        wallTrackingCompletedButton.rx.tapGesture().when(.recognized)
            .withLatestFrom(self.reactor!.state)
            .map { state in state.nextTrackingNode!.clone()  }
            .map { node in ARSceneReactor.Action.lastTrackingNodeAnchored(lastTrackingNode: node) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Move picture node across the walls
        isTrackingPictureNode
            .flatMapLatest { _ in isNotPictureNodeIdle }
            .flatMapLatest { _ in Observable<Int>.interval(self.timeInterval, scheduler: MainScheduler.instance)
                .takeUntil(isNotTrackingPictureNode)
                .takeUntil(isPictureNodeIdle)
            }
            .withLatestFrom(self.reactor!.state)
            .observeOn(MainScheduler.asyncInstance)
            .flatMapLatest { state in self.trackingPictureNode(pictureNode: state.pictureNode, selectedPicture: state.selectedPicture) }
            .map { node in ARSceneReactor.Action.pictureNodeUpdated(pictureNode: node) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Anchor picture
        isTrackingPictureNode
            .flatMapLatest { _ in isNotPictureNodeIdle }
            .flatMapLatest { _ in self.releasePictureButton.rx.tapGesture().when(.recognized).take(1) }
            .map { node in ARSceneReactor.Action.pausePictureNodeTracking }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Release picture
        isPictureNodeIdle
            .flatMapLatest{ _ in self.anchorPictureButton.rx.tapGesture().when(.recognized).take(1) }
            .map { node in ARSceneReactor.Action.resumePictureNodeTracking }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
         // Show/Hide anchor picture button
         reactor.state.map { state in state.isTrackingPicture && state.isPictureIdle }
            .subscribe(onNext: { isTrackingAndAnchored in
                if isTrackingAndAnchored {
                    UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                        self.anchorPictureButton.alpha = CGFloat(1.0)
                    }, completion: nil)
                } else {
                    UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                        self.anchorPictureButton.alpha = CGFloat(0.0)
                    }, completion: nil)
                }
            })
            .disposed(by: self.disposeBag)
        
        // Show/Hide release picture button
        reactor.state.map { state in state.isTrackingPicture && !state.isPictureIdle }
            .subscribe(onNext: { isTrackingAndReleased in
                if isTrackingAndReleased {
                    UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                        self.releasePictureButton.alpha = CGFloat(1.0)
                    }, completion: nil)
                } else {
                    UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                        self.releasePictureButton.alpha = CGFloat(0.0)
                    }, completion: nil)
                }
            })
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
        
        // Show/Hide initial description label
        reactor.state.getChange { $0.isAnchorDetected }
            .subscribe(onNext: { isAnchorDetected in
                if isAnchorDetected {
                    UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                        self.trackingSurroundingDescription.alpha = CGFloat(0.0)
                    }, completion: nil)
                } else {
                    UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                        self.trackingSurroundingDescription.alpha = CGFloat(1.0)
                    }, completion: nil)
                }
            })
            .disposed(by: self.disposeBag)
        
        // Show finish wall tracking button
        reactor.state.getChange { $0.anchoredWallNodes }
            .filter { walls in walls.count >= 2 }
            .withLatestFrom(isTrackingNextNode)
            .subscribe(onNext: { _ in
                UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                    self.wallTrackingCompletedButton.alpha = CGFloat(1.0)
                }, completion: nil)
            })
            .disposed(by: self.disposeBag)
        
        // Hide finish wall tracking button
        isNotTrackingNextNode
            .subscribe(onNext: { _ in
                UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                    self.wallTrackingCompletedButton.alpha = CGFloat(0.0)
                }, completion: nil)
            })
            .disposed(by: self.disposeBag)
        
        // Hide walls
        areWallsHidden
            .subscribe(onNext: { _ in
                let fadeOutAction = SCNAction.fadeOpacity(to: 0.001, duration: 0.5)
                let walls = self.scene.scene.rootNode.childNodes(passingTest: { node, _ in node.name == TrackingNode.TRACKING_NODE_NAME })
                walls.forEach { $0.runAction(fadeOutAction) }
            })
            .disposed(by: self.disposeBag)
        
        // Show walls
        areWallsShown
            .subscribe(onNext: { _ in
                let fadeInAction = SCNAction.fadeIn(duration: 0.5)
                let walls = self.scene.scene.rootNode.childNodes(passingTest: { node, _ in node.name == TrackingNode.TRACKING_NODE_NAME })
                walls.forEach { $0.runAction(fadeInAction) }
            })
            .disposed(by: self.disposeBag)
        
        // Show picture
        isTrackingPictureNode
            .subscribe(onNext: { _ in
                self.changePictureView.alpha = CGFloat(1.0)
                self.screenshotView.alpha = CGFloat(1.0)
            }).disposed(by: self.disposeBag)
        
        // Hide picture
        isNotTrackingPictureNode
            .subscribe(onNext: { _ in
                self.changePictureView.alpha = CGFloat(0.0)
                self.screenshotView.alpha = CGFloat(0.0)
            }).disposed(by: self.disposeBag)
        
        // Send showPictureList action to reactor
        changePictureView.rx.tapGesture().when(.recognized)
            .map { _ in .showPictureList }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Take and share screenshot
        screenshotView.rx.tapGesture().when(.recognized)
            .map { _ in self.scene.snapshot() }
            .subscribe(onNext: { image in
                let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                self.present(controller, animated: true, completion: nil)
            }).disposed(by: self.disposeBag)
        
        // Send hidePictureList action to reactor
        screenOverlay.rx.tapGesture().when(.recognized)
            .map { _ in .hidePictureList }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Show list of pictures
        isPictureListShown
            .subscribe(onNext: { _ in
                self.showPicturesView()
            })
            .disposed(by: self.disposeBag)
        
        // Hide list of pictures
        isNotPictureListShown
            .subscribe(onNext: { _ in
                self.hidePicturesView()
            })
            .disposed(by: self.disposeBag)
        
        // Update picture when is changed
        reactor.state.getChange { $0.selectedPicture }
            .withLatestFrom(reactor.state)
            .subscribe(onNext: { state in
                self.changePictureMaterialAndResize(picture: state.selectedPicture)
            })
            .disposed(by: self.disposeBag)
        
        // Send action that will change the selected picture
        imageThumbnailClick
            .map { picture in .selectedPictureChanged(picture: picture) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        // Show add wall description
        isTrackingFirstNode
            .subscribe(onNext: { _ in
                UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                    self.addWallDescription.alpha = CGFloat(1.0)
                }, completion: nil)
            })
            .disposed(by: self.disposeBag)
        
        // Hide add wall description
        isNotTrackingFirstNode
            .subscribe(onNext: { _ in
                UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                    self.addWallDescription.alpha = CGFloat(0.0)
                }, completion: nil)
            })
            .disposed(by: self.disposeBag)
    }
    
    func trackingPictureNode(pictureNode: SCNNode?, selectedPicture: Picture?) -> Observable<SCNNode> {
        return Observable.create { observer in
            if let node = pictureNode {
                PictureNode.resize(node: node, newWidth: self.pictureSize.width, newHeight: self.pictureSize.height)
            }
            
            if let planeData = self.test(location: self.view.center) {
                var node = pictureNode
                if node == nil {
                    node = PictureNode.node(at: planeData.1, eulerAngles: planeData.2, withMaterial: self.pictureMaterial)
                    self.scene.scene.rootNode.addChildNode(node!)
                }
                let actionMove = SCNAction.move(to: planeData.1, duration: 0.1)
                let actionRotate = SCNAction.rotateTo(x: CGFloat(planeData.2.x), y: CGFloat(planeData.2.y), z: CGFloat(planeData.2.z), duration: 0.0001)
                let actionSequence = SCNAction.group([actionMove, actionRotate])
                node!.runAction(actionSequence)
                
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
    }
    
    private func pauseSession() {
        scene.session.pause()
    }
    
    private func resetSession() {
        pauseSession()
        scene.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }
        startSession()
    }
    
    private func showActionSheet(forState state: ARSceneReactor.State) -> Observable<ARSceneReactor.Action> {
        return Observable.create { observer in
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            if state.isTrackingPicture && state.areWallsHidden {
                let action = UIAlertAction(title: "Show walls", style: .default) { (action:UIAlertAction) in
                    observer.onNext(.showWalls)
                }
                alertController.addAction(action)
            }
            
            if state.isTrackingPicture && state.areWallsHidden == false {
                let action = UIAlertAction(title: "Hide walls", style: .default) { (action:UIAlertAction) in
                    observer.onNext(.hideWalls)
                }
                alertController.addAction(action)
            }
            
            let resetAction = UIAlertAction(title: "Reset", style: .default) { (action:UIAlertAction) in
                self.resetSession()
                observer.onNext(.resetSessionClicked)
            }
            alertController.addAction(resetAction)
            
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
            
            return Disposables.create()
        }
    }
    
    private func changePictureMaterialAndResize(picture: Picture?) {
        if let picture = picture {
            loadImage(fromUrl: picture.pictureUrl) { image in
                self.pictureMaterial.diffuse.contents = image
                self.pictureMaterial.isDoubleSided = true
                self.setPictureSize(image: image!)
            }
        } else {
            pictureMaterial.isDoubleSided = true
            pictureMaterial.diffuse.contents = UIImage(named: "grid-material.png")
        }
    }
    
    private func setPictureSize(image: UIImage) {
        let height = image.size.height
        let width = image.size.width
        
        let maxSize = CGFloat(1)
        let scale = (width <= height) ? maxSize / height : maxSize / width
        let newWidth = width * scale
        let newHeight = height * scale
        
        self.pictureSize = CGSize(width: newWidth, height: newHeight)
    }
    
    private func configureLighting() {
        scene.autoenablesDefaultLighting = true
        scene.automaticallyUpdatesLighting = true
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
        let results = scene.hitTest(location, options: [SCNHitTestOption.searchMode: 1])
        let wallResult = results.first { $0.node.name == Wall.NAME }
        guard wallResult != nil else { return nil }
        
        let node = wallResult!.node
        return (node, wallResult!.worldCoordinates, node.eulerAngles)
    }
    
    private func showPicturesView() {
        self.view.layoutIfNeeded()
        self.picturesViewBottomConstraint.constant = 0
        self.screenOverlay.alpha = 0.0
        UIView.animate(withDuration: 0.3    , animations: {
            self.picturesViewBottomConstraint.constant += 0
            self.screenOverlay.alpha = 1.0
            self.view.layoutIfNeeded()
        })
    }
    
    private func hidePicturesView() {
        self.view.layoutIfNeeded()
        self.picturesViewBottomConstraint.constant = 0
        self.screenOverlay.alpha = 1.0
        UIView.animate(withDuration: 0.3, animations: {
            self.picturesViewBottomConstraint.constant -= self.picturesViewHeightConstraint.constant
            self.screenOverlay.alpha = 0.0
            self.view.layoutIfNeeded()
        })
    }
}

extension ARSceneViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }

        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height

        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
}

extension ARSceneViewController {
    func createAllPicturesDataSource() -> RxPictureDataSource {
        return RxPictureDataSource(configureCell: { dataSource, tableView, indexPath, _ in
            switch(dataSource[indexPath]) {
                case .picture(let picture):
                    let cell = self.allPicturesCollectionView.dequeueReusableCell(withReuseIdentifier: PicureThumbnailCell.identifier, for: indexPath) as! PicureThumbnailCell
                    cell.bind(picture, onClick: { picture in
                        self.imageThumbnailClick.onNext(picture)
                    })
                    return cell
            }
        }, configureSupplementaryView: { (dataSource, collectionView, kind, indexPath) in
            return collectionView.getDummyReusableCell(ofKind: kind, forIndex: indexPath)
        })
    }
}

extension ARSceneViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: collectionView.frame.height)
    }
}
