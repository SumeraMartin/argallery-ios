import ARKit
import RxSwift

class ARSessionRxDelegate : NSObject, ARSCNViewDelegate {
    
    typealias DidAddNodeValue = (rederer: SCNSceneRenderer, node: SCNNode, anchor: ARAnchor)
    typealias DidUpdateNodeValue = (renderer: SCNSceneRenderer, node: SCNNode, anchor: ARAnchor)
    typealias UpdateAtTimeValue = (renderer: SCNSceneRenderer, time: TimeInterval)
    typealias DidRemoveNodeValue = (rederer: SCNSceneRenderer, node: SCNNode, anchor: ARAnchor)
    
    let didAddNodeSubject = PublishSubject<DidAddNodeValue>()
    
    let didUpdateNodeSubject = PublishSubject<DidUpdateNodeValue>()
    
    let updateAtTimeSubject = PublishSubject<UpdateAtTimeValue>()
    
    let didRemoveNodeSubject = PublishSubject<DidRemoveNodeValue>()
    
    var didAddNode: Observable<DidAddNodeValue> {
        return didAddNodeSubject.asObservable()
    }
    
    var didUpdateNode: Observable<DidUpdateNodeValue> {
        return didUpdateNodeSubject.asObservable()
    }
    
    var updateAtTime: Observable<UpdateAtTimeValue> {
        return updateAtTimeSubject.asObservable()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        didAddNodeSubject.onNext((renderer, node, anchor))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        didUpdateNodeSubject.onNext((renderer, node, anchor))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateAtTimeSubject.onNext((renderer, time))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        didRemoveNodeSubject.onNext((renderer, node, anchor))
    }
}
