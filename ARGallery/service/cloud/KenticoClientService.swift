import RxSwift
import KenticoCloud

protocol KenticoClientServiceType {
    
    func getClient() -> Observable<DeliveryClient>
}

class KenticoClientService: BaseService, KenticoClientServiceType {
    
    let client = DeliveryClient.init(projectId: "17bbb0c7-e46c-45ab-b1d2-177ab5f9244f")
    
    func getClient() -> Observable<DeliveryClient> {
        return Observable.just(client)
    }
}
