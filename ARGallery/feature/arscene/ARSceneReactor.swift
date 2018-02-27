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
            anchorIdentifier: nil,
            initialTrackingNode: nil,
            nextTrackingNode: nil,
            pictureNode: nil,
            anchoredWallNodes: []
        )
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch(action) {
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
                state.initialTrackingNode = nil
                state.nextTrackingNode = nil
                state.pictureNode = nil
                state.anchoredWallNodes = []
                break
            case let .anchorDetected(identifier):
                state.isAnchorDetected = true
                state.anchorIdentifier = identifier
                state.isTrackingFirstNode = true
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
                state.anchoredWallNodes += [nextNode.childNode(withName: "end_node", recursively: true)!]
                state.nextTrackingNode = nextNode.childNode(withName: "end_node", recursively: true)!
                break
            case let .lastTrackingNodeAnchored(lastNode):
                state.anchoredWallNodes += [lastNode]
                state.nextTrackingNode = lastNode
                state.isTrackingNextNode = false
                state.isTrackingPicture = true
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
        }
        return state
    }
}

extension ARSceneReactor {
    
    enum Action {
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
    }
    
    struct State {
        var isAnchorDetected: Bool
        var isTrackingFirstNode: Bool
        var isTrackingNextNode: Bool
        var isTrackingPicture: Bool
        var isPictureIdle: Bool
        var anchorIdentifier: UUID?
        var initialTrackingNode: SCNNode?
        var nextTrackingNode: SCNNode?
        var pictureNode: SCNNode?
        var anchoredWallNodes: [SCNNode]
    }
}

extension ARSceneReactor.State {
    func lastAnchoredWallNode() -> SCNNode {
        return self.anchoredWallNodes.last!
    }
}

