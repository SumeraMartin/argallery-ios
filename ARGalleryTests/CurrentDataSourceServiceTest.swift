//
//  CurrentDataSourceService.swift
//  ARGalleryTests
//
//  Created by Martin Sumera on 16/05/2018.
//  Copyright © 2018 Martin Sumera. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

class CurrentDataSourceServiceTest: XCTestCase {
    
    var provider: ServiceProviderType!
    var currentDataSourceService: CurrentDataSourceServiceType!
    var observer: TestableObserver<PictureDataSourceServiceType>!
    
    override func setUp() {
        super.setUp()
        
        let scheduler = TestScheduler(initialClock: 0)
        observer = scheduler.createObserver(PictureDataSourceServiceType.self)
        
        provider =  MockServiceProvider()
        currentDataSourceService = CurrentDataSourceService(provider: provider)
    }
    
    func testSetPictureDataSourceServiceSingle() {
        // WHEN
        currentDataSourceService.changeCurrentDataSource(.favourites).subscribe().disposed(by:  DisposeBag())
        
        // THEN
        var event: PictureDataSourceServiceType? = nil
        currentDataSourceService.getCurrentDataSourceSingle().subscribe(onSuccess: { value in
            event = value
        }).disposed(by:  DisposeBag())
        XCTAssert(event === provider.favouritePicturesService as PictureDataSourceServiceType)
    }
    
    func testSetPictureDataSourceServiceObservable() {
        // WHEN
        currentDataSourceService.changeCurrentDataSource(.favourites).subscribe().disposed(by:  DisposeBag())
        currentDataSourceService.changeCurrentDataSource(.filtered).subscribe().disposed(by:  DisposeBag())
        
        // THEN
        currentDataSourceService.getCurrentDataSourceObservable().subscribe(observer).disposed(by:  DisposeBag())
        XCTAssertEqual(observer.events.count, 1)
        XCTAssert(observer.events[0].value.element! === provider.filteredPicturesCloudService)
    }
    
}
