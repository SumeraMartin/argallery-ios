//
//  ARSceneReactorTest.swift
//  ARGalleryTests
//
//  Created by Martin Sumera on 16/05/2018.
//  Copyright © 2018 Martin Sumera. All rights reserved.
//

import XCTest
import SceneKit

class ARSceneReactorTest: XCTestCase {
    
    var serviceProvider: MockServiceProvider!
    var reactor: ARSceneReactor!
    
    override func setUp() {
        super.setUp()
        
        serviceProvider = MockServiceProvider()
        reactor = ARSceneReactor(provider: serviceProvider)
        reactor.state.subscribe()
    }
    
    func testDefaultFilterState() {
        XCTAssertEqual(reactor.currentState.isAnchorDetected, false)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, false)
        XCTAssertEqual(reactor.currentState.isPictureIdle, false)
        XCTAssertEqual(reactor.currentState.isPictureListShown, false)
        XCTAssertEqual(reactor.currentState.areWallsHidden, true)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, nil)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.pictureNode, nil)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [])
        XCTAssertEqual(reactor.currentState.selectedPicture, nil)
        XCTAssertEqual(reactor.currentState.allPictures, [])
    }
    
    func testViewDidLoadSelectedPictureChange() {
        // GIVEN
        reactor.action.onNext(ARSceneReactor.Action.viewDidLoad)
        
        // WHEN
        serviceProvider.mockedSelectedPictureService.getSelectedPictureObservableSubject.onNext(mockPicture(id: "13"))
        
        // THEN
        XCTAssertEqual(reactor.currentState.isAnchorDetected, false)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, false)
        XCTAssertEqual(reactor.currentState.isPictureIdle, false)
        XCTAssertEqual(reactor.currentState.isPictureListShown, false)
        XCTAssertEqual(reactor.currentState.areWallsHidden, true)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, nil)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.pictureNode, nil)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [])
        XCTAssertEqual(reactor.currentState.selectedPicture, mockPicture(id: "13"))
        XCTAssertEqual(reactor.currentState.allPictures, [])
    }
    
    func testViewDidLoadAllPicturesChange() {
        // GIVEN
        reactor.action.onNext(ARSceneReactor.Action.viewDidLoad)
        
        // WHEN
        serviceProvider.mockedAllPicturesCloudService.getLoadingStateWithDataObservableSubject.onNext(
            LoadingStateWithPictures(dataSource: .favourites, loadingState: .loading, data: [mockPicture(id: "1"), mockPicture(id: "2")])
        )
        
        // THEN
        XCTAssertEqual(reactor.currentState.isAnchorDetected, false)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, false)
        XCTAssertEqual(reactor.currentState.isPictureIdle, false)
        XCTAssertEqual(reactor.currentState.isPictureListShown, false)
        XCTAssertEqual(reactor.currentState.areWallsHidden, true)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, nil)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.pictureNode, nil)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [])
        XCTAssertEqual(reactor.currentState.selectedPicture, nil)
        XCTAssertEqual(reactor.currentState.allPictures, [mockPicture(id: "1"), mockPicture(id: "2")])
    }
    
    func testAnchorDetected() {
        // WHEN
        let uuid = UUID.init()
        reactor.action.onNext(ARSceneReactor.Action.anchorDetected(identifier: uuid))
        
        // THEN
        XCTAssertEqual(reactor.currentState.isAnchorDetected, true)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, true)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, false)
        XCTAssertEqual(reactor.currentState.isPictureIdle, false)
        XCTAssertEqual(reactor.currentState.isPictureListShown, false)
        XCTAssertEqual(reactor.currentState.areWallsHidden, false)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, uuid)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.pictureNode, nil)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [])
        XCTAssertEqual(reactor.currentState.selectedPicture, nil)
        XCTAssertEqual(reactor.currentState.allPictures, [])
    }
    
    func testInitialTrackingNodeUpdate() {
        // WHEN
        let uuid = UUID.init()
        reactor.action.onNext(ARSceneReactor.Action.anchorDetected(identifier: uuid))
        let node = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.initialTrackingNodeUpdated(trackingNode: node))
        
        // THEN
        XCTAssertEqual(reactor.currentState.isAnchorDetected, true)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, true)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, false)
        XCTAssertEqual(reactor.currentState.isPictureIdle, false)
        XCTAssertEqual(reactor.currentState.isPictureListShown, false)
        XCTAssertEqual(reactor.currentState.areWallsHidden, false)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, uuid)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, node)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.pictureNode, nil)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [])
        XCTAssertEqual(reactor.currentState.selectedPicture, nil)
        XCTAssertEqual(reactor.currentState.allPictures, [])
    }
    
    func testInitialTrackingNodeAnchored() {
        // WHEN
        let uuid = UUID.init()
        reactor.action.onNext(ARSceneReactor.Action.anchorDetected(identifier: uuid))
        let node1 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.initialTrackingNodeUpdated(trackingNode: node1))
        let node2 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.initialTrackingNodeAnchored(nextTrackingNode: node2))
        
        // THEN
        XCTAssertEqual(reactor.currentState.isAnchorDetected, true)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, true)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, false)
        XCTAssertEqual(reactor.currentState.isPictureIdle, false)
        XCTAssertEqual(reactor.currentState.isPictureListShown, false)
        XCTAssertEqual(reactor.currentState.areWallsHidden, false)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, uuid)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, node1)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, node2)
        XCTAssertEqual(reactor.currentState.pictureNode, nil)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [node1])
        XCTAssertEqual(reactor.currentState.selectedPicture, nil)
        XCTAssertEqual(reactor.currentState.allPictures, [])
    }
    
    func testNextTrackingNodeUpdated() {
        // WHEN
        let uuid = UUID.init()
        reactor.action.onNext(ARSceneReactor.Action.anchorDetected(identifier: uuid))
        let node1 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.initialTrackingNodeUpdated(trackingNode: node1))
        let node2 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.initialTrackingNodeAnchored(nextTrackingNode: node2))
        let node3 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.nextTrackingNodeUpdated(trackingNode: node3))
        
        // THEN
        XCTAssertEqual(reactor.currentState.isAnchorDetected, true)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, true)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, false)
        XCTAssertEqual(reactor.currentState.isPictureIdle, false)
        XCTAssertEqual(reactor.currentState.isPictureListShown, false)
        XCTAssertEqual(reactor.currentState.areWallsHidden, false)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, uuid)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, node1)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, node3)
        XCTAssertEqual(reactor.currentState.pictureNode, nil)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [node1])
        XCTAssertEqual(reactor.currentState.selectedPicture, nil)
        XCTAssertEqual(reactor.currentState.allPictures, [])
    }
    
    func testAnotherTrackingNodeUpdated() {
        // WHEN
        let uuid = UUID.init()
        reactor.action.onNext(ARSceneReactor.Action.anchorDetected(identifier: uuid))
        let node1 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.initialTrackingNodeUpdated(trackingNode: node1))
        let node2 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.initialTrackingNodeAnchored(nextTrackingNode: node2))
        let node3 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.nextTrackingNodeUpdated(trackingNode: node3))
        let node4 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.nextTrackingNodeAnchored(nextTrackingNode: node4))
        
        // THEN
        XCTAssertEqual(reactor.currentState.isAnchorDetected, true)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, true)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, false)
        XCTAssertEqual(reactor.currentState.isPictureIdle, false)
        XCTAssertEqual(reactor.currentState.isPictureListShown, false)
        XCTAssertEqual(reactor.currentState.areWallsHidden, false)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, uuid)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, node1)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, node4)
        XCTAssertEqual(reactor.currentState.pictureNode, nil)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [node1, node4])
        XCTAssertEqual(reactor.currentState.selectedPicture, nil)
        XCTAssertEqual(reactor.currentState.allPictures, [])
    }
    
    func testLastTrackingNodeAnchored() {
        // WHEN
        let uuid = UUID.init()
        reactor.action.onNext(ARSceneReactor.Action.anchorDetected(identifier: uuid))
        let node0 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.initialTrackingNodeUpdated(trackingNode: node0))
        let node1 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.initialTrackingNodeAnchored(nextTrackingNode: node1))
        let node2 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.nextTrackingNodeAnchored(nextTrackingNode: node2))
        let node3 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.lastTrackingNodeAnchored(lastTrackingNode: node3))
        
        // THEN
        XCTAssertEqual(reactor.currentState.isAnchorDetected, true)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, true)
        XCTAssertEqual(reactor.currentState.isPictureIdle, false)
        XCTAssertEqual(reactor.currentState.isPictureListShown, false)
        XCTAssertEqual(reactor.currentState.areWallsHidden, true)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, uuid)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, node0)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, node3)
        XCTAssertEqual(reactor.currentState.pictureNode, nil)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [node0, node2, node3])
        XCTAssertEqual(reactor.currentState.selectedPicture, nil)
        XCTAssertEqual(reactor.currentState.allPictures, [])
    }
    
    func testUpdatePictureNode() {
        // WHEN
        let uuid = UUID.init()
        reactor.action.onNext(ARSceneReactor.Action.anchorDetected(identifier: uuid))
        let node0 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.initialTrackingNodeUpdated(trackingNode: node0))
        let node1 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.initialTrackingNodeAnchored(nextTrackingNode: node1))
        let node2 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.nextTrackingNodeAnchored(nextTrackingNode: node2))
        let node3 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.lastTrackingNodeAnchored(lastTrackingNode: node3))
        let node4 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.pictureNodeUpdated(pictureNode: node4))
        
        // THEN
        XCTAssertEqual(reactor.currentState.isAnchorDetected, true)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, true)
        XCTAssertEqual(reactor.currentState.isPictureIdle, false)
        XCTAssertEqual(reactor.currentState.isPictureListShown, false)
        XCTAssertEqual(reactor.currentState.areWallsHidden, true)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, uuid)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, node0)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, node3)
        XCTAssertEqual(reactor.currentState.pictureNode, node4)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [node0, node2, node3])
        XCTAssertEqual(reactor.currentState.selectedPicture, nil)
        XCTAssertEqual(reactor.currentState.allPictures, [])
    }
    
    func testPausePictureTracking() {
        // WHEN
        let uuid = UUID.init()
        reactor.action.onNext(ARSceneReactor.Action.anchorDetected(identifier: uuid))
        let node0 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.initialTrackingNodeUpdated(trackingNode: node0))
        let node1 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.initialTrackingNodeAnchored(nextTrackingNode: node1))
        let node2 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.nextTrackingNodeAnchored(nextTrackingNode: node2))
        let node3 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.lastTrackingNodeAnchored(lastTrackingNode: node3))
        let node4 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.pictureNodeUpdated(pictureNode: node4))
        reactor.action.onNext(ARSceneReactor.Action.pausePictureNodeTracking)
        
        // THEN
        XCTAssertEqual(reactor.currentState.isAnchorDetected, true)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, true)
        XCTAssertEqual(reactor.currentState.isPictureIdle, true)
        XCTAssertEqual(reactor.currentState.isPictureListShown, false)
        XCTAssertEqual(reactor.currentState.areWallsHidden, true)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, uuid)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, node0)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, node3)
        XCTAssertEqual(reactor.currentState.pictureNode, node4)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [node0, node2, node3])
        XCTAssertEqual(reactor.currentState.selectedPicture, nil)
        XCTAssertEqual(reactor.currentState.allPictures, [])
    }
    
    func testResumePictureTracking() {
        // WHEN
        let uuid = UUID.init()
        reactor.action.onNext(ARSceneReactor.Action.anchorDetected(identifier: uuid))
        let node0 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.initialTrackingNodeUpdated(trackingNode: node0))
        let node1 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.initialTrackingNodeAnchored(nextTrackingNode: node1))
        let node2 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.nextTrackingNodeAnchored(nextTrackingNode: node2))
        let node3 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.lastTrackingNodeAnchored(lastTrackingNode: node3))
        let node4 = SCNNode()
        reactor.action.onNext(ARSceneReactor.Action.pictureNodeUpdated(pictureNode: node4))
        reactor.action.onNext(ARSceneReactor.Action.resumePictureNodeTracking)
        
        // THEN
        XCTAssertEqual(reactor.currentState.isAnchorDetected, true)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, true)
        XCTAssertEqual(reactor.currentState.isPictureIdle, false)
        XCTAssertEqual(reactor.currentState.isPictureListShown, false)
        XCTAssertEqual(reactor.currentState.areWallsHidden, true)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, uuid)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, node0)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, node3)
        XCTAssertEqual(reactor.currentState.pictureNode, node4)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [node0, node2, node3])
        XCTAssertEqual(reactor.currentState.selectedPicture, nil)
        XCTAssertEqual(reactor.currentState.allPictures, [])
    }

    func testHideWalls() {
        // WHEN
        reactor.action.onNext(ARSceneReactor.Action.showWalls)
        reactor.action.onNext(ARSceneReactor.Action.hideWalls)
        
        // THEN
        XCTAssertEqual(reactor.currentState.isAnchorDetected, false)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, false)
        XCTAssertEqual(reactor.currentState.isPictureIdle, false)
        XCTAssertEqual(reactor.currentState.isPictureListShown, false)
        XCTAssertEqual(reactor.currentState.areWallsHidden, true)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, nil)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.pictureNode, nil)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [])
        XCTAssertEqual(reactor.currentState.selectedPicture, nil)
        XCTAssertEqual(reactor.currentState.allPictures, [])
    }
    
    func testShowWalls() {
        // WHEN
        reactor.action.onNext(ARSceneReactor.Action.showWalls)
        
        // THEN
        XCTAssertEqual(reactor.currentState.isAnchorDetected, false)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, false)
        XCTAssertEqual(reactor.currentState.isPictureIdle, false)
        XCTAssertEqual(reactor.currentState.isPictureListShown, false)
        XCTAssertEqual(reactor.currentState.areWallsHidden, false)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, nil)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.pictureNode, nil)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [])
        XCTAssertEqual(reactor.currentState.selectedPicture, nil)
        XCTAssertEqual(reactor.currentState.allPictures, [])
    }

    func testShowPictureList() {
        // WHEN
        reactor.action.onNext(ARSceneReactor.Action.showPictureList)
        
        // THEN
        XCTAssertEqual(reactor.currentState.isAnchorDetected, false)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, false)
        XCTAssertEqual(reactor.currentState.isPictureIdle, false)
        XCTAssertEqual(reactor.currentState.isPictureListShown, true)
        XCTAssertEqual(reactor.currentState.areWallsHidden, true)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, nil)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.pictureNode, nil)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [])
        XCTAssertEqual(reactor.currentState.selectedPicture, nil)
        XCTAssertEqual(reactor.currentState.allPictures, [])
    }
    
    func testHidePictureList() {
        // WHEN
        reactor.action.onNext(ARSceneReactor.Action.showPictureList)
        reactor.action.onNext(ARSceneReactor.Action.hidePictureList)
        
        // THEN
        XCTAssertEqual(reactor.currentState.isAnchorDetected, false)
        XCTAssertEqual(reactor.currentState.isTrackingFirstNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingNextNode, false)
        XCTAssertEqual(reactor.currentState.isTrackingPicture, false)
        XCTAssertEqual(reactor.currentState.isPictureIdle, false)
        XCTAssertEqual(reactor.currentState.isPictureListShown, false)
        XCTAssertEqual(reactor.currentState.areWallsHidden, true)
        XCTAssertEqual(reactor.currentState.anchorIdentifier, nil)
        XCTAssertEqual(reactor.currentState.initialTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.nextTrackingNode, nil)
        XCTAssertEqual(reactor.currentState.pictureNode, nil)
        XCTAssertEqual(reactor.currentState.anchoredWallNodes, [])
        XCTAssertEqual(reactor.currentState.selectedPicture, nil)
        XCTAssertEqual(reactor.currentState.allPictures, [])
    }
}
