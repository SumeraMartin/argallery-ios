//
//  FilterReactorTest.swift
//  ARGalleryTests
//
//  Created by Martin Sumera on 15/05/2018.
//  Copyright © 2018 Martin Sumera. All rights reserved.
//

import XCTest
import RxSwift
import KenticoCloud
import RealmSwift
import RxTest
import ReactorKit

class FilterReactorTest: XCTestCase {
    
    var serviceProvider: MockServiceProvider!
    var reactor: FilterReactor!
    
    override func setUp() {
        super.setUp()
        
        serviceProvider = MockServiceProvider()
        reactor = FilterReactor(provider: serviceProvider)
        reactor.state.subscribe()
    }
    
    func testDefaultFilterState() {
        XCTAssertEqual(reactor.currentState.currentFilter, Filter.createDefault())
    }
    
    func testFirstCategoryChanged() {
        reactor.action.onNext(FilterReactor.Action.firstCategoryChanged)
        
        XCTAssertEqual(reactor.currentState.currentFilter.firstCategoryEnabled, false)
    }
    
    func testSecondCategoryChanged() {
        reactor.action.onNext(FilterReactor.Action.secondCategoryChanged)
        
        XCTAssertEqual(reactor.currentState.currentFilter.secondCategoryEnabled, false)
    }
    
    func testPriceChanged() {
        reactor.action.onNext(FilterReactor.Action.priceRangeChanged(minPrice: 50, maxPrice: 100))
        
        XCTAssertEqual(reactor.currentState.currentFilter.minPrice, 50)
        XCTAssertEqual(reactor.currentState.currentFilter.maxPrice, 100)
    }
    
    func testYearChanged() {
        reactor.action.onNext(FilterReactor.Action.yearRangeChanged(minYear: 1900, maxYear: 1910))
        
        XCTAssertEqual(reactor.currentState.currentFilter.minYear, 1900)
        XCTAssertEqual(reactor.currentState.currentFilter.maxYear, 1910)
    }
    
    func testReset() {
        reactor.action.onNext(FilterReactor.Action.firstCategoryChanged)
        reactor.action.onNext(FilterReactor.Action.secondCategoryChanged)
        reactor.action.onNext(FilterReactor.Action.priceRangeChanged(minPrice: 50, maxPrice: 100))
        reactor.action.onNext(FilterReactor.Action.yearRangeChanged(minYear: 1900, maxYear: 1910))
        reactor.action.onNext(FilterReactor.Action.reset)
        
        XCTAssertEqual(reactor.currentState.currentFilter, Filter.createDefault())
    }
}
