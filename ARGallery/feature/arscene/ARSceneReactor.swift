import RxSwift

class ARSceneReactor: BaseReactor {
    
    let provider: ServiceProviderType
    let initialState: State
    
    init(provider: ServiceProviderType) {
        self.provider = provider
        self.initialState = State()
    }
}

extension ARSceneReactor {
    
    enum Action {
    }
    
    enum Mutation {
    }
    
    struct State {
    }
}

