import ReactorKit
import RxSwift

class PictureDetailReactor: BaseReactor {
    
    let provider: ServiceProviderType
    let initialState: State
    
    init(provider: ServiceProviderType, initialPictureIndex: Int) {
        self.provider = provider
        self.initialState = State(
            initialPictureIndex: initialPictureIndex,
            pictures: self.provider.pictureCloudService.getPictures()
        )
    }
    
//    func mutate(action: Action) -> Observable<Mutation> {
//
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
        var initialPictureIndex: Int
        var pictures: [Picture]
    }
}

