import XCTest

class PictureListReactorTest: XCTestCase {
    
    var serviceProvider: MockServiceProvider!
    var reactor: PictureListReactor!
    
    override func setUp() {
        super.setUp()
        
        serviceProvider = MockServiceProvider()
        reactor = PictureListReactor(provider: serviceProvider)
        reactor.state.subscribe()
    }
    
    func testDefaultState() {
        assertDefaultState()
    }
    
    func testDefaultFilterState() {
        reactor.action.onNext(PictureListReactor.Action.initialize)
        
        assertDefaultState()
        
        
        assertDefaultState()
    }
    
    func testInitializeWithChangedLoadingState() {
        // GIVEN
        reactor.action.onNext(PictureListReactor.Action.initialize)
        
        // WHEN
        serviceProvider.mockedCurrentDataSourceService.mockDataSource.getLoadingStateWithDataObservableSubject.onNext(
            LoadingStateWithPictures(dataSource: .favourites, loadingState: .loading, data: [mockPicture(id: "1")])
        )

        // THEN
        XCTAssertEqual(reactor.currentState.data, [mockPicture(id: "1")])
        XCTAssertEqual(reactor.currentState.isMoreLoadingEnabled, true)
        XCTAssertEqual(reactor.currentState.isLoading, true)
        XCTAssertEqual(reactor.currentState.isError, false)
        XCTAssertEqual(reactor.currentState.dataSource, .favourites)
        XCTAssertEqual(reactor.currentState.focusedPicture, nil)
    }
    
    func testInitializeWithChangedErrorState() {
        // GIVEN
        reactor.action.onNext(PictureListReactor.Action.initialize)
        
        // WHEN
        serviceProvider.mockedCurrentDataSourceService.mockDataSource.getLoadingStateWithDataObservableSubject.onNext(
            LoadingStateWithPictures(dataSource: .favourites, loadingState: .error, data: [mockPicture(id: "1")])
        )
        
        // THEN
        XCTAssertEqual(reactor.currentState.data, [mockPicture(id: "1")])
        XCTAssertEqual(reactor.currentState.isMoreLoadingEnabled, true)
        XCTAssertEqual(reactor.currentState.isLoading, false)
        XCTAssertEqual(reactor.currentState.isError, true)
        XCTAssertEqual(reactor.currentState.dataSource, .favourites)
        XCTAssertEqual(reactor.currentState.focusedPicture, nil)
    }
    
    func testInitializeWithChangedCompleteState() {
        // GIVEN
        reactor.action.onNext(PictureListReactor.Action.initialize)
        
        // WHEN
        serviceProvider.mockedCurrentDataSourceService.mockDataSource.getLoadingStateWithDataObservableSubject.onNext(
            LoadingStateWithPictures(dataSource: .favourites, loadingState: .completed, data: [mockPicture(id: "1")])
        )
        
        // THEN
        XCTAssertEqual(reactor.currentState.data, [mockPicture(id: "1")])
        XCTAssertEqual(reactor.currentState.isMoreLoadingEnabled, false)
        XCTAssertEqual(reactor.currentState.isLoading, false)
        XCTAssertEqual(reactor.currentState.isError, false)
        XCTAssertEqual(reactor.currentState.dataSource, .favourites)
        XCTAssertEqual(reactor.currentState.focusedPicture, nil)
        XCTAssertEqual(serviceProvider.mockedCurrentDataSourceService.mockDataSource.realoadWasCalled, true)
    }
    
    func testInitializeWithFocusedItemChange() {
        // GIVEN
        reactor.action.onNext(PictureListReactor.Action.initialize)
        
        // WHEN
        serviceProvider.mockedFocusedPictureService.getFocusedPictureObservableSubject.onNext(
            mockPicture(id: "2")
        )
        
        // THEN
         XCTAssertEqual(reactor.currentState.focusedPicture, mockPicture(id: "2"))
    }
    
    func testLoadMoreWithIgnore() {
        // GIVEN
        reactor.action.onNext(PictureListReactor.Action.loadMore)
        
        // WHEN
        serviceProvider.mockedCurrentDataSourceService.mockDataSource.getLoadingStateWithDataObservableSubject.onNext(
            LoadingStateWithPictures(dataSource: .favourites, loadingState: .loading, data: [mockPicture(id: "1")])
        )
        
        // THEN
        assertDefaultState()
        XCTAssertEqual(serviceProvider.mockedCurrentDataSourceService.mockDataSource.loadMoreWasCalled, false)
    }
    
    func testChangeDataSourceAll() {
        // GIVEN
        reactor.action.onNext(PictureListReactor.Action.allDataSelected)
        
        // THEN
        assertDefaultState()
        XCTAssertEqual(serviceProvider.mockedCurrentDataSourceService.currectDataSource, .all)
    }
    
    func testChangeDataSourceFavourties() {
        // GIVEN
        reactor.action.onNext(PictureListReactor.Action.favouriteDataSelected)
        
        // THEN
        XCTAssertEqual(serviceProvider.mockedCurrentDataSourceService.currectDataSource, .favourites)
    }
    
    func testChangeDataSourceFilter() {
        // GIVEN
        reactor.action.onNext(PictureListReactor.Action.filteredDataSelected)
        
        // THEN
        XCTAssertEqual(serviceProvider.mockedCurrentDataSourceService.currectDataSource, .filtered)
    }
    
    private func assertDefaultState() {
        XCTAssertEqual(reactor.currentState.data, [])
        XCTAssertEqual(reactor.currentState.isMoreLoadingEnabled, true)
        XCTAssertEqual(reactor.currentState.isLoading, false)
        XCTAssertEqual(reactor.currentState.isError, false)
        XCTAssertEqual(reactor.currentState.dataSource, .all)
        XCTAssertEqual(reactor.currentState.focusedPicture, nil)
    }
}
