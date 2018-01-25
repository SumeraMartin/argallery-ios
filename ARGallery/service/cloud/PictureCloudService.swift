import RxSwift
import KenticoCloud

protocol PictureCloudServiceType {
    
    func getLoadingStateObservable() -> Observable<PictureLoadingState>
    
    func getPicturesObservable() -> Observable<[Picture]>
    
    func getPictures() -> [Picture]
    
    func load() -> Observable<Void>
    
    func loadMore() -> Observable<Void>
}

class PictureCloudService: BaseService, PictureCloudServiceType {
    
    typealias ClearPreviousData = Bool
    
    static let limit = 1
    
    let disposeBag = DisposeBag()
    
    let startLoadingSubject = PublishSubject<ClearPreviousData>()
    
    let pictureSubject = BehaviorSubject<[Picture]>(value: [])
    
    let pictureLoadingStateSubject = BehaviorSubject(value: PictureLoadingState.Inactive)
    
    override init(provider: ServiceProviderType) {
        super.init(provider: provider)
        
        subscribeToNotifier()
    }
    
    func getLoadingStateObservable() -> Observable<PictureLoadingState> {
        return pictureLoadingStateSubject.asObservable()
    }
    
    func getPicturesObservable() -> Observable<[Picture]> {
        return pictureSubject.asObservable()
    }
    
    func getPictures() -> [Picture] {
        do {
            return try pictureSubject.value()
        } catch {
            fatalError("Picture subject without data")
        }
    }
    
    func load() -> Observable<Void> {
        startLoadingSubject.onNext(true)
        return Observable.just(Void())
    }
    
    func loadMore() -> Observable<Void> {
        startLoadingSubject.onNext(false)
        return Observable.just(Void())
    }
    
    private func subscribeToNotifier() {
        startLoadingSubject
            .flatMap { clearPreviousData -> Observable<[Picture]> in
                if clearPreviousData == false {
                    return self.getLoadingStateObservable()
                        .take(1)
                        .flatMap { state -> Observable<[Picture]> in
                            if state.isAllowedToLoadMore() {
                                return self.getPicturesObservable().take(1)
                            }
                            fatalError("This should never happen")
                        }
                }
                return Observable.just([])
            }
            .do(onNext: { previousData in
                if previousData.count == 0 {
                    self.pictureLoadingStateSubject.onNext(.InitialLoading)
                } else {
                    self.pictureLoadingStateSubject.onNext(.MoreLoading)
                }
            })
            .flatMapLatest { previousData in
                return self.provider.filterService
                    .getCurrentFilterOnce()
                    .flatMap { filter -> Observable<Result<[Picture]>> in
                        let limit = PictureCloudService.limit
                        let offset = previousData.count
                        return self.getPictures(offset: offset, limit: limit, filter: filter)
                    }
                    .do(onNext: { result in
                        result.flatMap(success: { pictures in
                            self.pictureLoadingStateSubject.onNext(.Inactive)
                            let newData = previousData + pictures
                            self.pictureSubject.onNext(newData)
                        }, failure: { _ in
                            if previousData.count == 0 {
                                self.pictureLoadingStateSubject.onNext(.InitialError)
                            } else {
                                self.pictureLoadingStateSubject.onNext(.MoreError)
                            }
                        })
                    })
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    private func getPictures(offset: Int, limit: Int, filter: Filter = Filter.createDefault()) -> Observable<Result<[Picture]>> {
        return provider.kenticoClientService
            .getClient()
            .flatMap { client in
                return Observable.create { observer in
                    let query = Query(systemType: "picture")
                        .add(key: "limit", value: limit)
                        .add(key: "skip", value: offset)
                        .add(key: "elements.price[gte]", value: filter.minPrice)
                        .add(key: "elements.price[lte]", value: filter.maxPrice)
//                        .add(key: "system.id[in]", value: "f99e2d6f-f6a4-4cc9-8ecd-02e10f1501c9" )
                        .build()
    
                    client.getItems(modelType: Picture.self, customQuery: query) { (isSuccess, itemsResponse, error) in
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
            .delay(RxTimeInterval(5), scheduler: MainScheduler.instance)
    }
}
