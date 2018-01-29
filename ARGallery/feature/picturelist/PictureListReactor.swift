import ReactorKit
import RxSwift

class PictureListReactor: BaseReactor {
        
    let provider: ServiceProviderType
    let initialState: State
    
    init(provider: ServiceProviderType) {
        self.provider = provider
        self.initialState = State(
            isMoreLoadingEnabled: true,
            isLoading: false,
            isError: false,
            data: [],
            focusedPicture: nil
        )
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
            case .initialize:
                let picturesObservable = self.provider.pictureCloudService
                    .getLoadingStateWithDataObservable()
                    .map { loadingStateWithData in loadingStateWithData.data }
                    .map { data in Mutation.showData(data)}
            
                let loadingStateObservable = self.provider.pictureCloudService
                    .getLoadingStateWithDataObservable()
                    .map { loadingStateWithData in loadingStateWithData.loadingState }
                    .map { loadingState -> PictureListReactor.Mutation in
                        switch loadingState {
                            case .loading:
                                return Mutation.showLoading
                            case .error:
                                return Mutation.showError
                            case .inactive:
                                return Mutation.hideErrorAndLoading
                            case .completed:
                                return Mutation.showCompleted
                        }
                    }
                
                let startLoadingObservable = self.provider.pictureCloudService
                    .reload()
                    .map { _ in Mutation.ignore }
                    .asObservable()
                
                let focusedPictureObservable = self.provider.focusedPictureService
                    .getFocusedPictureObservable()
                    .filter { $0 != nil }
                    .map { Mutation.setFocusedPicture($0!) }
                
                return Observable.merge([
                    picturesObservable,
                    loadingStateObservable,
                    startLoadingObservable,
                    focusedPictureObservable
                ])
            case .loadMore:
                return self.provider.pictureCloudService
                    .getLoadingStateWithDataSingle()
                    .flatMap { loadingStateWithData in
                        if loadingStateWithData.loadingState != .loading {
                            return self.provider.pictureCloudService
                                .loadMore()
                                .map { Mutation.ignore }
                        }
                        return Single.just(Mutation.ignore)
                    }
                    .asObservable()
            case .refresh:
                return self.provider.pictureCloudService
                    .reload()
                    .map { Mutation.ignore }
                    .asObservable()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch(mutation) {
            case let .showData(pictures):
                state.data = pictures
                break
            case .showError:
                state.isLoading = false
                state.isError = true
                break
            case .showLoading:
                state.isLoading = true
                state.isError = false
                break
            case .hideErrorAndLoading:
                state.isLoading = false
                state.isError = false
                break
            case let .setFocusedPicture(picture):
                state.focusedPicture = picture
                break
            case .showCompleted:
                state.isMoreLoadingEnabled = false
                state.isLoading = false
                state.isError = false
                break
            case .ignore:
                break
        }
        return state
    }
}

extension PictureListReactor {
    
    enum Action {
        case initialize
        case refresh
        case loadMore
    }
    
    enum Mutation {
        case ignore
        case showData([Picture])
        case showLoading
        case showError
        case hideErrorAndLoading
        case showCompleted
        case setFocusedPicture(Picture)
    }
    
    struct State {
        var isMoreLoadingEnabled: Bool
        var isLoading: Bool
        var isError: Bool
        var data: [Picture]
        var focusedPicture: Picture?
    }
}

