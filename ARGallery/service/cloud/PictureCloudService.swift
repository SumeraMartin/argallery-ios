import RxSwift
import KenticoCloud

protocol PictureCloudServiceType {
    
    func getLoadingStateWithDataObservable() -> Observable<LoadingStateWithPictures>
    
    func getLoadingStateWithDataSingle() -> Single<LoadingStateWithPictures>
    
    func getPictures() -> [Picture]
    
    func loadMore() -> Single<Void>
    
    func reload() -> Single<Void>
}

class PictureCloudService: BaseService, PictureCloudServiceType {
    
    typealias ReloadData = Bool
    
    static let limit = 1
    
    let startLoadingSubject = PublishSubject<ReloadData>()
    
    let stateSubject = BehaviorSubject(value: LoadingStateWithPictures.createDefault())
    
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
    
    func loadMore() -> Single<Void> {
        startLoadingSubject.onNext(false)
        return Single.just(Void())
    }
    
    func reload() -> Single<Void> {
        startLoadingSubject.onNext(true)
        return Single.just(Void())
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
            .withLatestFrom(self.provider.filterService.getCurrentFilterOnce()) { state, filter in
                return (state, filter)
            }
            
            .flatMapLatest { stateAndFilter -> Observable<LoadingStateWithPictures> in
                var (state, filter) = stateAndFilter
                state.loadingState = .loading
                
                let loadingStateWithPreviousDataObservable = Observable.just(state)
                let loadPicturesObservable = self.getPictures(loadingStateWithPictures: state, filter: filter)
                return Observable.merge(loadPicturesObservable, loadingStateWithPreviousDataObservable)
            }
            .subscribe(onNext: { loadingStateWithPictures in
                self.stateSubject.onNext(loadingStateWithPictures)
            })
            .disposed(by: disposeBag)
    }
    
    private func getPictures(loadingStateWithPictures: LoadingStateWithPictures, filter: Filter) -> Observable<LoadingStateWithPictures> {
        return provider.kenticoClientService
            .getClient()
            .flatMap { client -> Observable<Result<[CloudPicture]>> in
                let limit = PictureCloudService.limit
                let offset = loadingStateWithPictures.data.count + 1
                return self.fetchData(offset: offset, limit: limit, filter: filter, client: client)
            }
            .map { result in result.map { pictures in pictures.map { $0.toPicture() } } }
            .map { result in
                switch result {
                    case let .Success(data):
                        if data.count == 0 {
                            return LoadingStateWithPictures(loadingState: .completed, data: loadingStateWithPictures.data)
                        }
                        return LoadingStateWithPictures(loadingState: .inactive, data: loadingStateWithPictures.data + data)
                    case .Failure(_):
                        return LoadingStateWithPictures(loadingState: .error, data: loadingStateWithPictures.data)
                }
            }
            .delay(RxTimeInterval(5), scheduler: MainScheduler.instance)
    }
    
    private func fetchData(offset: Int, limit: Int, filter: Filter, client: DeliveryClient) -> Observable<Result<[CloudPicture]>> {
        return Observable.create { observer in
            let query = self.createQuery(offset: offset, limit: limit, filter: filter)
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
    
    private func createQuery(offset: Int, limit: Int, filter: Filter) -> String {
        return Query(systemType: "picture")
            .add(key: "limit", value: limit)
            .add(key: "skip", value: offset)
            //                        .add(key: "elements.price[gte]", value: filter.minPrice)
            //                        .add(key: "elements.price[lte]", value: filter.maxPrice)
            //                        .add(key: "system.id[in]", value: "f99e2d6f-f6a4-4cc9-8ecd-02e10f1501c9" )
            .build()
    }
}
