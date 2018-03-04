import RxSwift
import ARKit

class ARSceneReactor: BaseReactor {
    
    let provider: ServiceProviderType
    let initialState: State
    
    init(provider: ServiceProviderType) {
        self.provider = provider
        self.initialState = State(
            isAnchorDetected: false,
            isTrackingFirstNode: false,
            isTrackingNextNode: false,
            isTrackingPicture: false,
            isPictureIdle: false,
            isPictureListShown: false,
            areWallsHidden: true,
            anchorIdentifier: nil,
            initialTrackingNode: nil,
            nextTrackingNode: nil,
            pictureNode: nil,
            anchoredWallNodes: [],
            selectedPicture: nil
        )
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch(action) {
            case .viewDidLoad:
                return self.provider.selectedPictureService.getSelectedPictureObservable()
                    .map { picture in .setSelectedPicture(picture: picture) }
            case .resetSessionClicked:
                return Observable.just(.resetSession)
            case .viewWillAppear:
                return Observable.just(.resetSession)
            case let .anchorDetected(identifier):
                return Observable.just(.anchorDetected(identifier: identifier))
            case let .initialTrackingNodeUpdated(node):
                return Observable.just(Mutation.initialTrackingNodeUpdated(trackingNode: node))
            case let .initialTrackingNodeAnchored(nextNode):
                return Observable.just(Mutation.initialTrackingNodeAnchored(nextTrackingNode: nextNode))
            case let .nextTrackingNodeUpdated(node):
                return Observable.just(Mutation.nextTrackingNodeUpdated(trackingNode: node))
            case let .nextTrackingNodeAnchored(nextNode):
                return Observable.just(Mutation.nextTrackingNodeAnchored(nextTrackingNode: nextNode))
            case let .lastTrackingNodeAnchored(lastNode):
                return Observable.just(Mutation.lastTrackingNodeAnchored(lastTrackingNode: lastNode))
            case let .pictureNodeUpdated(node):
                return Observable.just(Mutation.pictureNodeUpdated(pictureNode: node))
            case .pausePictureNodeTracking:
                return Observable.just(Mutation.pausePictureNodeTracking)
            case .resumePictureNodeTracking:
                return Observable.just(Mutation.resumePictureNodeTracking)
            case .hideWalls:
                return Observable.just(Mutation.hideWalls)
            case .showWalls:
                return Observable.just(Mutation.showWalls)
            case .hidePictureList:
                return Observable.just(Mutation.hidePictureList)
            case .showPictureList:
                return Observable.just(Mutation.showPictureList)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch(mutation) {
            case .resetSession:
                state.isAnchorDetected = false
                state.anchorIdentifier = nil
                state.isTrackingFirstNode = false
                state.isTrackingNextNode = false
                state.isTrackingPicture = false
                state.areWallsHidden = true
                state.initialTrackingNode = nil
                state.nextTrackingNode = nil
                state.pictureNode = nil
                state.anchoredWallNodes = []
                break
            case let .anchorDetected(identifier):
                state.isAnchorDetected = true
                state.anchorIdentifier = identifier
                state.isTrackingFirstNode = true
                state.areWallsHidden = false
                break
            case let .initialTrackingNodeUpdated(node):
                state.initialTrackingNode = node
                break
            case let .initialTrackingNodeAnchored(node):
                state.anchoredWallNodes = [state.initialTrackingNode!]
                state.nextTrackingNode = node
                state.isTrackingFirstNode = false
                state.isTrackingNextNode = true
                break
            case let .nextTrackingNodeUpdated(node):
                state.nextTrackingNode = node
                break
            case let .nextTrackingNodeAnchored(nextNode):
                state.anchoredWallNodes += [nextNode]
                state.nextTrackingNode = nextNode
                break
            case let .lastTrackingNodeAnchored(lastNode):
                state.anchoredWallNodes += [lastNode]
                state.nextTrackingNode = lastNode
                state.isTrackingNextNode = false
                state.isTrackingPicture = true
                state.isPictureIdle = false
                state.areWallsHidden = true
                break
            case let .pictureNodeUpdated(node):
                state.pictureNode = node
                break
            case .pausePictureNodeTracking:
                state.isPictureIdle = true
                break
            case .resumePictureNodeTracking:
                state.isPictureIdle = false
                break
            case .hideWalls:
                state.areWallsHidden = true
                break
            case .showWalls:
                state.areWallsHidden = false
                break
            case .showPictureList:
                state.isPictureListShown = true
                break
            case .hidePictureList:
                state.isPictureListShown = false
                break
            case let .setSelectedPicture(picture):
                state.selectedPicture = picture
                break
        }
        return state
    }
}

extension ARSceneReactor {
    
    enum Action {
        case viewDidLoad
        case viewWillAppear
        case resetSessionClicked
        case anchorDetected(identifier: UUID)
        case initialTrackingNodeUpdated(trackingNode: SCNNode)
        case initialTrackingNodeAnchored(nextTrackingNode: SCNNode)
        case nextTrackingNodeUpdated(trackingNode: SCNNode)
        case nextTrackingNodeAnchored(nextTrackingNode: SCNNode)
        case lastTrackingNodeAnchored(lastTrackingNode: SCNNode)
        case pictureNodeUpdated(pictureNode: SCNNode)
        case pausePictureNodeTracking
        case resumePictureNodeTracking
        case hideWalls
        case showWalls
        case showPictureList
        case hidePictureList
    }
    
    enum Mutation {
        case resetSession
        case anchorDetected(identifier: UUID)
        case initialTrackingNodeUpdated(trackingNode: SCNNode)
        case initialTrackingNodeAnchored(nextTrackingNode: SCNNode)
        case nextTrackingNodeUpdated(trackingNode: SCNNode)
        case nextTrackingNodeAnchored(nextTrackingNode: SCNNode)
        case lastTrackingNodeAnchored(lastTrackingNode: SCNNode)
        case pictureNodeUpdated(pictureNode: SCNNode)
        case pausePictureNodeTracking
        case resumePictureNodeTracking
        case hideWalls
        case showWalls
        case showPictureList
        case hidePictureList
        case setSelectedPicture(picture: Picture?)
    }
    
    struct State {
        var isAnchorDetected: Bool
        var isTrackingFirstNode: Bool
        var isTrackingNextNode: Bool
        var isTrackingPicture: Bool
        var isPictureIdle: Bool
        var isPictureListShown: Bool
        var areWallsHidden: Bool
        var anchorIdentifier: UUID?
        var initialTrackingNode: SCNNode?
        var nextTrackingNode: SCNNode?
        var pictureNode: SCNNode?
        var anchoredWallNodes: [SCNNode]
        var selectedPicture: Picture?
    }
}

extension ARSceneReactor.State {
    func lastAnchoredWallNode() -> SCNNode {
        return self.anchoredWallNodes.last!
    }
}

