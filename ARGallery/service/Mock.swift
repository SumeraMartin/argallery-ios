import RxSwift
import KenticoCloud
import RealmSwift
import ReactorKit

class MockServiceProvider : ServiceProviderType {
    
    var kenticoClientService: KenticoClientServiceType = MockKenticoClientService()
    
    var filterService: FilterServiceType = MockFilterService()
    
    var focusedPictureService: FocusedPictureServiceType = MockFocusedPicturesService()
    
    var realmProviderService: RealmProviderServiceType  = MockRealmProviderService()
    
    var currentDataSourceService: CurrentDataSourceServiceType = MockCurrectDataSourceService()
    
    var allPicturesCloudService: PictureDataSourceServiceType = MockPictureDataSourceService()
    
    var filteredPicturesCloudService: PictureDataSourceServiceType = MockPictureDataSourceService()
    
    var favouritePicturesService: FavouriteDataSourceServiceType = MockFavoriteDataSourceType()
    
    var selectedPictureService: SelectedPictureServiceType = MockSelectedPictureService()
    
    var mockedCurrentDataSourceService: MockCurrectDataSourceService {
        get {
            return currentDataSourceService as! MockCurrectDataSourceService
        }
    }
    
    var mockedFocusedPictureService: MockFocusedPicturesService {
        get {
            return focusedPictureService as! MockFocusedPicturesService
        }
    }
    
    var mockedFavouritePicturesService: MockFavoriteDataSourceType {
        get {
            return favouritePicturesService as! MockFavoriteDataSourceType
        }
    }
    
    var mockedSelectedPictureService: MockSelectedPictureService {
        get {
            return selectedPictureService as! MockSelectedPictureService
        }
    }
    
    var mockedAllPicturesCloudService: MockPictureDataSourceService {
        get {
            return allPicturesCloudService as! MockPictureDataSourceService
        }
    }
}

class MockKenticoClientService : KenticoClientServiceType {
    
    func getClient() -> Observable<DeliveryClient> {
        return Observable.just(DeliveryClient.init(projectId: "XXX"))
    }
}

class MockFilterService : FilterServiceType {
    
    let getCurrentFilterOnceSubject = PublishSubject<Filter>()
    
    let getFilterChangesSubject = PublishSubject<Filter>()
    
    func getCurrentFilter() -> Filter {
        return Filter.createDefault()
    }
    
    func getCurrentFilterOnce() -> Observable<Filter> {
        return getCurrentFilterOnceSubject
    }
    
    func getFilterChanges() -> Observable<Filter> {
        return getFilterChangesSubject
    }
    
    func setFilter(filter: Filter) -> Observable<Filter> {
        return Observable.just(filter)
    }
    
    func resetFilter() {
        // Pass
    }
}

class MockFocusedPicturesService : FocusedPictureServiceType {
    
    let getFocusedPictureObservableSubject = PublishSubject<Picture?>()
    
    var focusedPicture: Picture? = nil
    
    func setFocusedPicture(_ picture: Picture) -> Observable<Void> {
        focusedPicture = picture
        return Observable.just(Void())
    }
    
    func getFocusedPictureObservable() -> Observable<Picture?> {
        return getFocusedPictureObservableSubject
    }
}

class MockRealmProviderService : RealmProviderServiceType {
    
    func getDefaultRealmInstanceSingle() -> Single<Realm> {
        return Single.just(try! Realm())
    }
    
    func getDefaultRealmInstance() -> Realm {
        return  try! Realm()
    }
}

class MockCurrectDataSourceService : CurrentDataSourceServiceType {
    
    var mockDataSource = MockPictureDataSourceService()
    
    var currectDataSource: DataSourceType? = nil
    
    func getCurrentDataSource() -> PictureDataSourceServiceType {
        return mockDataSource
    }
    
    func getCurrentDataSourceSingle() -> Single<PictureDataSourceServiceType> {
        return Single.just(mockDataSource)
    }
    
    func getCurrentDataSourceObservable() -> Observable<PictureDataSourceServiceType> {
        return Observable.just(mockDataSource)
    }
    
    func changeCurrentDataSource(_ dataSourceType: DataSourceType) -> Single<Void> {
        currectDataSource = dataSourceType
        return Single.just(Void())
    }
}

class MockPictureDataSourceService : PictureDataSourceServiceType {
    
    var loadMoreWasCalled = false
    
    var realoadWasCalled = false
    
    var pictures: [Picture] = []
    
    let getLoadingStateWithDataObservableSubject = PublishSubject<LoadingStateWithPictures>()
    
    func getLoadingStateWithDataObservable() -> Observable<LoadingStateWithPictures> {
        return getLoadingStateWithDataObservableSubject
    }
    
    func getLoadingStateWithDataSingle() -> Single<LoadingStateWithPictures> {
        return getLoadingStateWithDataObservableSubject.asSingle()
    }
    
    func getPictures() -> [Picture] {
        return pictures
    }
    
    func loadMore() {
        loadMoreWasCalled = true
    }
    
    func reload() {
        realoadWasCalled = true
    }
    
    func wasSelected() {
        
    }
}

class MockFavoriteDataSourceType : MockPictureDataSourceService, FavouriteDataSourceServiceType {
    
    var toggledPicture: Picture? = nil
    
    func togglePopular(forPicture picture: Picture) -> Completable {
        toggledPicture = picture
        return Completable.empty()
    }
}

class MockSelectedPictureService : SelectedPictureServiceType {
    
    var getSelectedPictureObservableSubject = PublishSubject<Picture?>()
    
    var selectedPicture: Picture? = nil
    
    func setSelectedPicture(_ picture: Picture) -> Observable<Void> {
        selectedPicture = picture
        return Observable.just(Void())
    }
    
    func getSelectedPictureObservable() -> Observable<Picture?> {
        return getSelectedPictureObservableSubject
    }
}

func mockPicture(id: String) -> Picture {
    return Picture(id: id, title: "Title", author: "Author", pictureUrl: "ww.ggg.com", description: "Desc", price: 100, year: 1800)
}

