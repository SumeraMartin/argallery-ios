import ReactorKit
import RxSwift

class PictureListReactor: BaseReactor {
    
    let provider: ServiceProviderType
    let initialState: State
    
    init(provider: ServiceProviderType) {
        self.provider = provider
        self.initialState = State(
            isRefreshEnabled: false,
            isLoadMoreEnabled: false,
            isLoadingMain: true,
            isLoadingMore: false,
            isLoadingRefresh: false,
            isLoadingMoreError: false,
            isMainError: false,
            data: []
        )
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
            case .viewWillAppear:
                return loadDataAndMapThemToMutation(
                        offset: 0,
                        success: { .showNewData($0) },
                        failure: { .showMainError($0) }
                    )
                    .startWith(.showMainLoading)
            case .loadMore:
                return self.state
                    .map { $0.data.count }
                    .take(1)
                    .flatMap { self.loadDataAndMapThemToMutation(
                        offset: $0,
                        success: { .appendNewData($0) },
                        failure: { _ in .showLoadMoreError() }
                    )}
                    .map { _ in .showLoadMoreError() }
                    .takeUntil(self.action.filter { $0 == .refresh })
                    .startWith(.showMoreLoading)
            case .refresh:
                return loadDataAndMapThemToMutation(
                        offset: 0,
                        success: { .showNewData($0) },
                        failure: { .showMainError($0) })
                    .startWith(.showRefreshLoading)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch(mutation) {
        case let .showNewData(pictures):
            state.isRefreshEnabled = true
            state.isLoadMoreEnabled = true
            state.isLoadingMain = false
            state.isLoadingMore = false
            state.isLoadingRefresh = false
            state.isMainError = false
            state.isLoadingMoreError = false
            state.data = pictures
            break
        case let .appendNewData(pictures):
            state.isLoadMoreEnabled = true
            state.isLoadingMore = false
            state.isLoadingMoreError = false
            state.data = (state.data) + pictures
            break
        case .showMainError(_):
            state.isRefreshEnabled = false
            state.isLoadMoreEnabled = false
            state.isLoadingMain = false
            state.isLoadingMore = false
            state.isLoadingRefresh = false
            state.isMainError = true
            state.isLoadingMoreError = false
            break
        case .showLoadMoreError():
            state.isLoadMoreEnabled = false
            state.isLoadingMore = false
            state.isLoadingMoreError = true
            break
        case .showMainLoading:
            state.isRefreshEnabled = false
            state.isLoadMoreEnabled = false
            state.isLoadingMain = true
            state.isLoadingMore = false
            state.isLoadingRefresh = false
            state.isMainError = false
            state.isLoadingMoreError = false
            break
        case .showRefreshLoading:
            state.isLoadingMore = false
            state.isLoadingRefresh = true
            state.isMainError = false
            state.isLoadingMoreError = false
        case .showMoreLoading:
            state.isLoadingMore = true
            state.isLoadingMoreError = false
            state.isLoadMoreEnabled = false
        }
        return state
    }

    private func loadDataAndMapThemToMutation(offset: Int, success: @escaping (([Picture]) -> Mutation), failure: @escaping ((Error) -> Mutation)) -> Observable<Mutation> {
        return self.provider.filterService
            .getCurrentFilterOnce()
            .flatMap { filter in
                return self.provider.pictureCloudService
                    .getPictures(offset: 0, limit: 10, filter: filter)
                    .map { $0.either(success: success, failure: failure) }
            }
                
    }
}

extension PictureListReactor {
    
    enum Action {
        case viewWillAppear
        case refresh
        case loadMore
    }
    
    enum Mutation {
        case showNewData([Picture])
        case appendNewData([Picture])
        case showMainError(Error)
        case showLoadMoreError()
        case showMainLoading
        case showRefreshLoading
        case showMoreLoading
    }
    
    struct State {
        var isRefreshEnabled: Bool
        var isLoadMoreEnabled: Bool
        var isLoadingMain: Bool
        var isLoadingMore: Bool
        var isLoadingRefresh: Bool
        var isLoadingMoreError: Bool
        var isMainError: Bool
        var data: [Picture]
    }
}

