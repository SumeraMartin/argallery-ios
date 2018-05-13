import RxSwift
import KenticoCloud

class AllPicturesCloudService: BaseService, PictureDataSourceServiceType {
    
    typealias ReloadData = Bool
    
    var dataSource = DataSourceType.all
    
    private static let limit = 30
    
    private let startLoadingSubject = PublishSubject<ReloadData>()
    
    private let stateSubject = BehaviorSubject(value: LoadingStateWithPictures.createDefault())
    
    override init(provider: ServiceProviderType) {
        super.init(provider: provider)
        
        initializeSubscription()
    }
    
    func getLoadingStateWithDataObservable() -> Observable<LoadingStateWithPictures> {
        return stateSubject.asObservable()
    }
    
    func getLoadingStateWithDataSingle() -> Single<LoadingStateWithPictures> {
        return stateSubject.take(1).asSingle()
    }
    
    func getPictures() -> [Picture] {
        do {
            let state = try stateSubject.value()
            return state.data
        } catch {
            fatalError("Picture subject without data")
        }
    }
    
    func loadMore() {
        self.startLoadingSubject.onNext(false)
    }
    
    func reload() {
        self.startLoadingSubject.onNext(true)
    }
    
    func wasSelected() {
        // Do nothing
    }
    
    func buildQuery(_ query: Query) -> Query {
        return query
    }
    
    private func initializeSubscription() {
        startLoadingSubject
            .withLatestFrom(self.stateSubject) { reloadData, state -> LoadingStateWithPictures in
                var state = state
                if reloadData {
                    state.data = []
                }
                return state
            }
            .flatMapLatest { state -> Observable<LoadingStateWithPictures> in
                var state = state
                state.loadingState = .loading
                let loadingStateWithPreviousDataObservable = Observable.just(state)
                let loadPicturesObservable = self.getPictures(loadingStateWithPictures: state)
                return Observable.merge(loadPicturesObservable, loadingStateWithPreviousDataObservable)
            }
            .subscribe(onNext: { loadingStateWithPictures in
                self.stateSubject.onNext(loadingStateWithPictures)
            })
            .disposed(by: disposeBag)
    }
    
    private func getPictures(loadingStateWithPictures: LoadingStateWithPictures) -> Observable<LoadingStateWithPictures> {
        return provider.kenticoClientService.getClient()
            .flatMapLatest { client -> Observable<Result<[CloudPicture]>> in
                let limit = AllPicturesCloudService.limit
                let offset = loadingStateWithPictures.data.count
                return self.fetchData(offset: offset, limit: limit, client: client)
            }
            .map { result in result.map { pictures in pictures.map { $0.toPicture() } } }
            .map { result in
                switch result {
                    case let .Success(data):
                        if data.count == 0 {
                            return LoadingStateWithPictures(dataSource: self.dataSource, loadingState: .completed, data: loadingStateWithPictures.data)
                        }
                        return LoadingStateWithPictures(dataSource: self.dataSource, loadingState: .inactive, data: loadingStateWithPictures.data + data)
                    case .Failure(_):
                        return LoadingStateWithPictures(dataSource: self.dataSource, loadingState: .error, data: loadingStateWithPictures.data)
                }
            }
    }
    
    private func fetchData(offset: Int, limit: Int, client: DeliveryClient) -> Observable<Result<[CloudPicture]>> {
        return Observable.create { observer in
            let query = self.buildQuery(self.createLimitOffsetQuery(offset: offset, limit: limit)).build()
            client.getItems(modelType: CloudPicture.self, customQuery: query) { (isSuccess, itemsResponse, error) in
                if isSuccess {
                    if let pictures = itemsResponse?.items {
                        observer.onNext(Result.Success(pictures))
                    } else {
                        fatalError("Kentico client successful response without items")
                    }
                } else {
                    if let error = error {
                        observer.onNext(Result.Failure(error))
                    } else {
                        fatalError("Kentico client unsuccessful response without error")
                    }
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    private func createLimitOffsetQuery(offset: Int, limit: Int) -> Query {
        return Query(systemType: "picture")
            .add(key: "limit", value: limit)
            .add(key: "skip", value: offset)
    }
}
