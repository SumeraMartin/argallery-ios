import ReactorKit
import RxSwift

class PictureListReactor: BaseReactor {
    
    let provider: ServiceProviderType
    let initialState: State
    
    init(provider: ServiceProviderType) {
        self.provider = provider
        self.initialState = State(
            isLoadMoreEnabled: false,
            isLoadingMain: true,
            isLoadingMainError: false,
            isLoadingMore: false,
            isLoadingMoreError: false,
            data: []
        )
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
            case .initialize:
                let initialLoadingObservable = self.provider.pictureCloudService
                    .getLoadingStateObservable()
                    .filter { $0 == .InitialLoading }
                    .map { _ in Mutation.showMainLoading }
            
                let initialErrorObservable = self.provider.pictureCloudService
                    .getLoadingStateObservable()
                    .filter { $0 == .InitialError }
                    .map { _ in Mutation.showMainError }
            
                let moreLoadingObservable = self.provider.pictureCloudService
                    .getLoadingStateObservable()
                    .filter { $0 == .MoreLoading }
                    .map { _ in Mutation.showLoadMoreLoading }
            
                let moreErrorObservable = self.provider.pictureCloudService
                    .getLoadingStateObservable()
                    .filter { $0 == .MoreError }
                    .map { _ in Mutation.showMainError }
                
                let hideLoadingsAndErrorsObservable = self.provider.pictureCloudService
                    .getLoadingStateObservable()
                    .filter { $0 == .Inactive }
                    .map { _ in Mutation.hideLoadingsAndErrors }
            
                let dataObservable = self.provider.pictureCloudService
                    .getPicturesObservable()
                    .map { data in Mutation.showData(data) }
                
                let startLoadingObservable = self.provider.pictureCloudService
                    .load()
                    .map { _ in Mutation.ignore }
                
                return Observable.merge([
                    initialLoadingObservable,
                    initialErrorObservable,
                    moreLoadingObservable,
                    moreErrorObservable,
                    hideLoadingsAndErrorsObservable,
                    dataObservable,
                    startLoadingObservable
                ])
//                return loadDataAndMapThemToMutation(
//                        offset: 0,
//                        success: { .showNewData($0) },
//                        failure: { .showMainError($0) }
//                    )
//                    .startWith(.showMainLoading)
            case .loadMore:
                return self.provider.pictureCloudService
                    .loadMore()
                    .map { Mutation.ignore }
            case .refresh:
                return self.provider.pictureCloudService
                    .loadMore()
                    .map { Mutation.ignore }
        }
    }
//
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch(mutation) {
            case let .showData(pictures):
                state.data = pictures
                break
            case .showMainError:
                state.isLoadMoreEnabled = false
                state.isLoadingMain = false
                state.isLoadingMainError = true
                state.isLoadingMore = false
                state.isLoadingMoreError = false
                break
            case .showMainLoading:
                state.isLoadMoreEnabled = false
                state.isLoadingMain = true
                state.isLoadingMainError = false
                state.isLoadingMore = false
                state.isLoadingMoreError = false
                break
            case .showLoadMoreError:
                state.isLoadMoreEnabled = false
                state.isLoadingMain = false
                state.isLoadingMainError = false
                state.isLoadingMore = false
                state.isLoadingMoreError = true
                break
            case .showLoadMoreLoading:
                state.isLoadMoreEnabled = false
                state.isLoadingMain = false
                state.isLoadingMainError = false
                state.isLoadingMore = true
                state.isLoadingMoreError = false
                break
            case .hideLoadingsAndErrors:
                state.isLoadMoreEnabled = true
                state.isLoadingMain = false
                state.isLoadingMainError = false
                state.isLoadingMore = false
                state.isLoadingMoreError = false
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
        case hideLoadingsAndErrors
        case showMainLoading
        case showMainError
        case showLoadMoreError
        case showLoadMoreLoading
    }
    
    struct State {
        var isLoadMoreEnabled: Bool
        var isLoadingMain: Bool
        var isLoadingMainError: Bool
        var isLoadingMore: Bool
        var isLoadingMoreError: Bool
        var data: [Picture]
    }
}

