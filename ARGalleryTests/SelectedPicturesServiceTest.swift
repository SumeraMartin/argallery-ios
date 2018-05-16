//
//  SelectedPicturesServiceTest.swift
//  ARGalleryTests
//
//  Created by Martin Sumera on 16/05/2018.
//  Copyright © 2018 Martin Sumera. All rights reserved.
//

import XCTest
import RxTest
import RxSwift

class SelectedPicturesServiceTest: XCTestCase {
    
    var selectedPicturesService: SelectedPictureServiceType!
    var observer: TestableObserver<Picture?>!

    override func setUp() {
        super.setUp()
        
        let scheduler = TestScheduler(initialClock: 0)
        observer = scheduler.createObserver(Picture?.self)
        
        selectedPicturesService = SelectedImageService(provider: MockServiceProvider())
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSingleSet() {
        // WHEN
        selectedPicturesService.setSelectedPicture(mockPicture(id: "1")).subscribe().disposed(by:  DisposeBag())
        
        // THEN
        selectedPicturesService.getSelectedPictureObservable().subscribe(observer).disposed(by:  DisposeBag())
        XCTAssertEqual(observer.events.count, 1)
        XCTAssertEqual(observer.events[0].value.element!, mockPicture(id: "1"))
    }
    
    func testMultipleSet() {
        // WHEN
        selectedPicturesService.setSelectedPicture(mockPicture(id: "1")).subscribe().disposed(by:  DisposeBag())
        selectedPicturesService.setSelectedPicture(mockPicture(id: "2")).subscribe().disposed(by:  DisposeBag())
        
        // THEN
            selectedPicturesService.getSelectedPictureObservable().subscribe(observer).disposed(by:  DisposeBag())
        XCTAssertEqual(observer.events.count, 1)
        XCTAssertEqual(observer.events[0].value.element!, mockPicture(id: "2"))
    }
}
