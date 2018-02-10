import RxSwift
import RealmSwift

protocol RealmProviderServiceType {

    func getDefaultRealmInstanceSingle() -> Single<Realm>
    
    func getDefaultRealmInstance() -> Realm
}

class RealmProviderService: BaseService, RealmProviderServiceType {

    var realm = try! Realm()

    func getDefaultRealmInstanceSingle() -> Single<Realm> {
        return Single.just(realm)
    }
    
    func getDefaultRealmInstance() -> Realm {
        return realm
    }
}
