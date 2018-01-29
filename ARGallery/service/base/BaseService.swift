import RxSwift

class BaseService {
    
    unowned let provider: ServiceProviderType
    
    let disposeBag = DisposeBag()
    
    init(provider: ServiceProviderType) {
        self.provider = provider
    }
}

