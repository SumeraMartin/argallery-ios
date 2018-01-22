import ReactorKit

class PictureDetailReactor: BaseReactor {
    
    let provider: ServiceProviderType
    let initialState: State
    
    init(provider: ServiceProviderType) {
        self.provider = provider
        self.initialState = State()
    }
    
//    func mutate(action: Action) -> Observable<Mutation> {
//       return Observable.just()
//    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
    
        return state
    }
}

extension PictureDetailReactor {
    
    enum Action {
        
    }
    
    enum Mutation {
    
    }
    
    struct State {
        
    }
}

