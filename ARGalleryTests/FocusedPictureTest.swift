//
//  FocusedPictureTest.swift
//  ARGalleryTests
//
//  Created by Martin Sumera on 16/05/2018.
//  Copyright © 2018 Martin Sumera. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

class FocusedPictureTest: XCTestCase {
    
    var focusedPicturesService: FocusedPictureServiceType!
    var observer: TestableObserver<Picture?>!
    
    override func setUp() {
        super.setUp()
        
        let scheduler = TestScheduler(initialClock: 0)
        observer = scheduler.createObserver(Picture?.self)
        
        focusedPicturesService = FocusedPictureService(provider: MockServiceProvider())
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSingleSet() {
        // WHEN
        focusedPicturesService.setFocusedPicture(mockPicture(id: "1")).subscribe().disposed(by:  DisposeBag())
        
        // THEN
        focusedPicturesService.getFocusedPictureObservable().subscribe(observer).disposed(by:  DisposeBag())
        XCTAssertEqual(observer.events.count, 1)
        XCTAssertEqual(observer.events[0].value.element!, mockPicture(id: "1"))
    }
    
    func testMultipleSet() {
        // WHEN
        focusedPicturesService.setFocusedPicture(mockPicture(id: "1")).subscribe().disposed(by:  DisposeBag())
        focusedPicturesService.setFocusedPicture(mockPicture(id: "2")).subscribe().disposed(by:  DisposeBag())
        
        // THEN
        focusedPicturesService.getFocusedPictureObservable().subscribe(observer).disposed(by:  DisposeBag())
        XCTAssertEqual(observer.events.count, 1)
        XCTAssertEqual(observer.events[0].value.element!, mockPicture(id: "2"))
    }
}

