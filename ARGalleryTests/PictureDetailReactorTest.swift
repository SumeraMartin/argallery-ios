//
//  PictureDetailReactorTest.swift
//  ARGalleryTests
//
//  Created by Martin Sumera on 16/05/2018.
//  Copyright © 2018 Martin Sumera. All rights reserved.
//

import XCTest

class PictureDetailReactorTest: XCTestCase {
    
    var serviceProvider: MockServiceProvider!
    var reactor: PictureDetailReactor!
    var initialPicture: Picture!
    
    override func setUp() {
        super.setUp()
        
        serviceProvider = MockServiceProvider()
        initialPicture = mockPicture(id: "2")
        serviceProvider.mockedCurrentDataSourceService.mockDataSource.pictures = [mockPicture(id: "1"), mockPicture(id: "2")]
        reactor = PictureDetailReactor(provider: serviceProvider, initialPicture: initialPicture)
        reactor.state.subscribe()
    }
    
    func testDefaultState() {
        XCTAssertEqual(reactor.currentState.initialPictureIndex, 1)
        XCTAssertEqual(reactor.currentState.pictures, [mockPicture(id: "1"), mockPicture(id: "2")])
        XCTAssertEqual(reactor.currentState.popularPictures, [])
    }
    
    func testInitializeWithChangedLoadingState() {
        // GIVEN
        reactor.action.onNext(PictureDetailReactor.Action.initialize)
        
        // WHEN
        serviceProvider.mockedCurrentDataSourceService.mockDataSource.getLoadingStateWithDataObservableSubject.onNext(
            LoadingStateWithPictures(dataSource: .favourites, loadingState: .loading, data: [mockPicture(id: "1"), mockPicture(id: "2"), mockPicture(id: "3")])
        )
        
        // THEN
        XCTAssertEqual(reactor.currentState.initialPictureIndex, 1)
        XCTAssertEqual(reactor.currentState.pictures, [mockPicture(id: "1"), mockPicture(id: "2"),  mockPicture(id: "3")])
        XCTAssertEqual(reactor.currentState.popularPictures, [])
    }
    
    func testInitializeWithFavoritePictureChanges() {
        // GIVEN
        reactor.action.onNext(PictureDetailReactor.Action.initialize)
        
        // WHEN
        self.serviceProvider.mockedFavouritePicturesService.getLoadingStateWithDataObservableSubject.onNext(
            LoadingStateWithPictures(dataSource: .favourites, loadingState: .completed, data: [mockPicture(id: "1"), mockPicture(id: "2"), mockPicture(id: "3")])
        )
        
        // THEN
        XCTAssertEqual(reactor.currentState.initialPictureIndex, 1)
        XCTAssertEqual(reactor.currentState.pictures, [mockPicture(id: "1"), mockPicture(id: "2")])
        XCTAssertEqual(reactor.currentState.popularPictures, [mockPicture(id: "1"), mockPicture(id: "2"), mockPicture(id: "3")])
    }
    
    func testPictureChanged() {
        // WHEN
        reactor.action.onNext(PictureDetailReactor.Action.focusedItemChanged(picture: mockPicture(id: "10")))
        
        // THEN
        XCTAssertEqual(serviceProvider.mockedFocusedPictureService.focusedPicture, mockPicture(id: "10"))
        XCTAssertEqual(serviceProvider.mockedSelectedPictureService.selectedPicture, mockPicture(id: "10"))
    }
    
    func testPopularPictureChange() {
        // WHEN
        reactor.action.onNext(PictureDetailReactor.Action.popularItemChanged(picture: mockPicture(id: "10")))
        
        // THEN
        XCTAssertEqual(serviceProvider.mockedFavouritePicturesService.toggledPicture, mockPicture(id: "10"))
    }
    
    func testArClicked() {
        // WHEN
        reactor.action.onNext(PictureDetailReactor.Action.arSceneClicked(picture: mockPicture(id: "11")))
        
        // THEN
        XCTAssertEqual(serviceProvider.mockedSelectedPictureService.selectedPicture, mockPicture(id: "11"))
    }
}
