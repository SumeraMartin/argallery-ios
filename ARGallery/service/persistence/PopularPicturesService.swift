import RxSwift
import RealmSwift
import RxRealm

protocol FavouriteDataSourceServiceType: PictureDataSourceServiceType {
    
    func togglePopular(forPicture picture: Picture) -> Completable
}

class FavouritePicturesService: BaseService, FavouriteDataSourceServiceType {
    
    private let startLoadingSubject = PublishSubject<Void>()
    
    private let stateSubject = BehaviorSubject(value: LoadingStateWithPictures.createDefault())
    
    override init(provider: ServiceProviderType) {
        super.init(provider: provider)
        
        initializeSubscription()
        
        reload()
    }
    
    func getLoadingStateWithDataObservable() -> Observable<LoadingStateWithPictures> {
        return stateSubject.asObservable()
    }
    
    func getLoadingStateWithDataSingle() -> PrimitiveSequence<SingleTrait, LoadingStateWithPictures> {
        return stateSubject.take(1).asSingle()
    }
    
    func getPictures() -> [Picture] {
        return self.provider.realmProviderService
            .getDefaultRealmInstance()
            .objects(PopularPicture.self)
            .map { picture in picture.toPicture() }
    }
    
    func loadMore() {
        self.startLoadingSubject.onNext(Void())
    }
    
    func reload() {
        self.startLoadingSubject.onNext(Void())
    }
    
    func wasSelected() {
        self.startLoadingSubject.onNext(Void())
    }
    
    func togglePopular(forPicture picture: Picture) -> Completable {
        return getLoadingStateWithDataSingle()
            .map { loadingStateWithData in loadingStateWithData.data }
            .map { popularPictures in popularPictures.contains(picture) }
            .flatMap { isPopular -> Single<Picture> in
                if isPopular {
                    return self.removePopularPicture(picture)
                } else {
                    return self.savePopularPicture(picture)
                }
            }
            .asCompletable()
    }
    
    private func initializeSubscription() {
        return self.startLoadingSubject
            .flatMapLatest { _ in
                self.provider.realmProviderService
                    .getDefaultRealmInstanceSingle()
                    .asObservable()
            }
            .flatMapLatest { realm -> Observable<(AnyRealmCollection<PopularPicture>, RealmChangeset?)> in
                let query = realm.objects(PopularPicture.self)
                return Observable.changeset(from: query)
            }
            .map { results, _ in results.map { picture in picture.toPicture() }}
            .map { pictures in LoadingStateWithPictures(dataSource: .favourites, loadingState: .completed, data: pictures) }
            .subscribe(onNext: { loadingStateWithPictures in
                self.stateSubject.onNext(loadingStateWithPictures)
            })
            .disposed(by: disposeBag)
    }
    
    private func removePopularPicture(_ picture: Picture) -> Single<Picture> {
        return self.provider.realmProviderService
            .getDefaultRealmInstanceSingle()
            .flatMap { realm in
                try! realm.write {
                    let popular = realm.object(ofType: PopularPicture.self, forPrimaryKey: picture.id)
                    if let popular = popular {
                        realm.delete(popular)
                    }
                }
                return Single.just(picture)
            }
    }
    
    private func savePopularPicture(_ picture: Picture) -> Single<Picture> {
        return self.provider.realmProviderService
            .getDefaultRealmInstanceSingle()
            .flatMap { realm in
                let popular = PopularPicture.from(picture: picture)
                try! realm.write {
                    realm.add(popular)
                }
                return Single.just(picture)
            }
    }
}

