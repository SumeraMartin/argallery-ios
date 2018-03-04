import ReactorKit
import RxSwift

class PictureDetailReactor: BaseReactor {
    
    let provider: ServiceProviderType
    let initialState: State
    
    init(provider: ServiceProviderType, initialPicture: Picture) {
        self.provider = provider
        
        let pictures = self.provider.currentDataSourceService.getCurrentDataSource().getPictures()
        if let index = pictures.index(of: initialPicture) {
            self.initialState = State(
                initialPictureIndex: index,
                pictures: pictures,
                popularPictures: []
            )
        } else {
            fatalError("Unknown picture: \(initialPicture)")
        }
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
            case .initialize:
                let dataObservable = self.provider.currentDataSourceService
                    .getCurrentDataSourceObservable()
                    .flatMapLatest { $0.getLoadingStateWithDataObservable() }
                    .map { loadingStateWithPictures in loadingStateWithPictures.data}
                    .map { data in Mutation.picturesChanged(data) }
                
                let popularObservable = self.provider.favouritePicturesService
                    .getLoadingStateWithDataObservable()
                    .map { loadingStateWithPictures in loadingStateWithPictures.data }
                    .map { Mutation.popularPicturesChanged($0)}

                return Observable.merge([dataObservable, popularObservable])
            case let .focusedItemChanged(picture):
                let setSelectedPicture = self.provider.selectedPictureService
                    .setSelectedPicture(picture)
                    .map { _ in Mutation.ignore }
                let setFocusedPicture = self.provider.focusedPictureService
                    .setFocusedPicture(picture)
                    .map { _ in Mutation.ignore }
                return Observable.merge(setSelectedPicture, setFocusedPicture)
            case let .popularItemChanged(picture):
                return self.provider.favouritePicturesService
                    .togglePopular(forPicture: picture)
                    .asObservable()
                    .map { _ in .ignore }
            case let .arSceneClicked(picture):
                return self.provider.selectedPictureService
                    .setSelectedPicture(picture)
                    .map { _ in .ignore }
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
            case let .popularPicturesChanged(popularPictures):
                state.popularPictures = popularPictures
                break
            case let .picturesChanged(pictures):
                state.pictures = pictures
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
        case arSceneClicked(picture: Picture)
    }
    
    enum Mutation {
        case ignore
        case picturesChanged([Picture])
        case popularPicturesChanged([Picture])
    }
    
    struct State {
        var initialPictureIndex: Int
        var pictures: [Picture]
        var popularPictures: [Picture]
    }
}

