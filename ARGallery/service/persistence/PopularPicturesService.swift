import RxSwift
import RealmSwift
import RxRealm

protocol PopularPicturesServiceType {
    
    func togglePopular(forPicture picture: Picture) -> Single<Picture>
    
    func getPopularPictures() -> Observable<[Picture]>
}

class PopularPicturesService: BaseService, PopularPicturesServiceType {
    
    func togglePopular(forPicture picture: Picture) -> Single<Picture> {
        return getPopularPicturesSingle()
            .map { popularPictures in popularPictures.contains(picture) }
            .flatMap { isPopular in
                if isPopular {
                    return self.removePopularPicture(picture)
                } else {
                    return self.savePopularPicture(picture)
                }
            }
    }
    
    func getPopularPictures() -> Observable<[Picture]> {
        return self.provider.realmProviderService
            .getDefaultRealmInstance()
            .asObservable()
            .flatMap { realm -> Observable<(AnyRealmCollection<PopularPicture>, RealmChangeset?)> in
                let query = realm.objects(PopularPicture.self)
                return Observable.changeset(from: query)
            }
            .map { results, _ in results.map { picture in picture.toPicture() }}
    }
    
    private func getPopularPicturesSingle() -> Single<[Picture]> {
        return getPopularPictures()
            .take(1)
            .asSingle()
    }
    
    private func removePopularPicture(_ picture: Picture) -> Single<Picture> {
        return self.provider.realmProviderService
            .getDefaultRealmInstance()
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
            .getDefaultRealmInstance()
            .flatMap { realm in
                let popular = PopularPicture.from(picture: picture)
                try! realm.write {
                    realm.add(popular)
                }
                return Single.just(picture)
            }
    }
}

