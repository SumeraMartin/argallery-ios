//
//  FilterServiceTest.swift
//  ARGalleryTests
//
//  Created by Martin Sumera on 16/05/2018.
//  Copyright © 2018 Martin Sumera. All rights reserved.
//

import XCTest
import RxSwift
import RxTest

class FilterServiceTest: XCTestCase {
    
    var filterService: FilterServiceType!
    var observer: TestableObserver<Filter>!
    
    override func setUp() {
        super.setUp()
        
        let scheduler = TestScheduler(initialClock: 0)
        observer = scheduler.createObserver(Filter.self)
        
        filterService = FilterService(provider: MockServiceProvider())
    }
    
    func testDefaultFilter() {
        XCTAssertEqual(filterService.getCurrentFilter(), Filter.createDefault())
    }
    
    func testChangeFilter() {
        // WHEN
        filterService.setFilter(filter: mockFilter(minPrice: 10, maxPrice: 20)).subscribe().disposed(by:  DisposeBag())
        
        // THEN
        XCTAssertEqual(filterService.getCurrentFilter(), mockFilter(minPrice: 10, maxPrice: 20))
    }
    
    func testGetFilterOnce() {
        // WHEN
        filterService.setFilter(filter: mockFilter(minPrice: 20, maxPrice: 30)).subscribe().disposed(by:  DisposeBag())
        
        // THEN
        filterService.getFilterChanges().subscribe(observer).disposed(by:  DisposeBag())
        XCTAssertEqual(observer.events.count, 1)
        XCTAssertEqual(observer.events[0].value.element!, mockFilter(minPrice: 20, maxPrice: 30))
    }
    
    func testSetPictureDataSourceServiceObservable() {
        // GIVEN
        let disposeBag = DisposeBag()
        filterService.setFilter(filter: mockFilter(minPrice: 20, maxPrice: 30)).subscribe().disposed(by: disposeBag)
        
        // WHEN
        filterService.getFilterChanges().subscribe(observer).disposed(by: disposeBag)
        
        // THEN
        XCTAssertEqual(observer.events.count, 1)
        XCTAssertEqual(observer.events[0].value.element!, mockFilter(minPrice: 20, maxPrice: 30))
    }
    
    func mockFilter(minPrice: Int, maxPrice: Int) -> Filter {
        return Filter(minPrice: 1, maxPrice: 2, minYear: 3, maxYear: 4, firstCategoryEnabled: true, secondCategoryEnabled: true)
    }
}
