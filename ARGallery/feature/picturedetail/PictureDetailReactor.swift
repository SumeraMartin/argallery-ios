import ReactorKit
import RxSwift

class PictureDetailReactor: BaseReactor {
    
    let provider: ServiceProviderType
    let initialState: State
    
    init(provider: ServiceProviderType, initialPicture: Picture) {
        self.provider = provider
        
        if let index = self.provider.pictureCloudService.getPictures().index(of: initialPicture) {
            self.initialState = State(
                initialPictureIndex: index,
                pictures: self.provider.pictureCloudService.getPictures(),
                popularPictures: []
            )
        } else {
            fatalError("Unknown picture: \(initialPicture)")
        }
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
            case .initialize:
                return self.provider.popularPicturesService
                    .getPopularPictures()
                    .map { Mutation.popularPicturesChanged($0)}
            case let .focusedItemChanged(picture):
                return self.provider.focusedPictureService
                    .setFocusedPicture(picture)
                    .map { .ignore }
            case let .popularItemChanged(picture):
                return self.provider.popularPicturesService
                    .togglePopular(forPicture: picture)
                    .map { _ in .ignore }
                    .asObservable()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
            case let .popularPicturesChanged(popularPictures):
                state.popularPictures = popularPictures
                break
            case .ignore:
                break
        }
        return state
    }
}

extension PictureDetailReactor {
    
    enum Action {
        case initialize
        case focusedItemChanged(picture: Picture)
        case popularItemChanged(picture: Picture)
    }
    
    enum Mutation {
        case ignore
        case popularPicturesChanged([Picture])
    }
    
    struct State {
        var initialPictureIndex: Int
        var pictures: [Picture]
        var popularPictures: [Picture]
    }
}

