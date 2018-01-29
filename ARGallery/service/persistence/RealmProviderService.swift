import RxSwift
import RealmSwift

protocol RealmProviderServiceType {

    func getDefaultRealmInstance() -> Single<Realm>
}

class RealmProviderService: BaseService, RealmProviderServiceType {

    var realm = try! Realm()

    func getDefaultRealmInstance() -> Single<Realm> {
        return Single.just(realm)
    }
}
