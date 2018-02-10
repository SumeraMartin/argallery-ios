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
            dataSource: .all,
            data: [],
            focusedPicture: nil
        )
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
            case .initialize:
                let startLoadingObservable = self.provider.currentDataSourceService
                    .getCurrentDataSourceSingle()
                    .asObservable()
                    .do(onNext: { dataSource in dataSource.reload()})
                    .map { _ in Mutation.ignore }
                
                let loadingStateObservable = self.provider.currentDataSourceService
                    .getCurrentDataSourceObservable()
                    .flatMapLatest { dataSource in dataSource.getLoadingStateWithDataObservable() }
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
            
                let picturesObservable = self.provider.currentDataSourceService
                    .getCurrentDataSourceObservable()
                    .flatMapLatest { dataSource in dataSource.getLoadingStateWithDataObservable() }
                    .map { loadingStateWithData in loadingStateWithData.data }
                    .map { data in Mutation.showData(data)}
                
                let dataSourceObservable = self.provider.currentDataSourceService
                    .getCurrentDataSourceObservable()
                    .flatMapLatest { dataSource in dataSource.getLoadingStateWithDataObservable() }
                    .map { loadingStateWithData in loadingStateWithData.dataSource }
                    .map { dataSourceType in Mutation.setDataSource(dataSourceType) }
                
                let observeFocusedItemObservable = self.provider.focusedPictureService
                    .getFocusedPictureObservable()
                    .filter { $0 != nil }
                    .map { Mutation.setFocusedPicture($0!) }
            
                return Observable.merge(
                        startLoadingObservable,
                        loadingStateObservable,
                        picturesObservable,
                        observeFocusedItemObservable,
                        dataSourceObservable
                    )
            case .loadMore:
                return self.provider.currentDataSourceService
                    .getCurrentDataSourceSingle()
                    .flatMap { dataSource in dataSource.getLoadingStateWithDataSingle() }
                    .asObservable()
                    .map { loadingStateWithPictures in loadingStateWithPictures.loadingState }
                    .flatMapLatest { loadingState -> Observable<Mutation> in
                        if loadingState != .loading {
                            return self.provider.currentDataSourceService
                                .getCurrentDataSourceSingle()
                                .asObservable()
                                .do(onNext: { dataSource in dataSource.loadMore() })
                                .map { _ in Mutation.ignore }
                        }
                        return Observable.just(Mutation.ignore)
                    }
                    .asObservable()
            case .refresh:
                return self.provider.currentDataSourceService
                    .getCurrentDataSourceSingle()
                    .asObservable()
                    .do(onNext: { dataSource in dataSource.reload() })
                    .map { _ in Mutation.ignore }
            case .allDataSelected:
                return self.provider.currentDataSourceService
                    .changeCurrentDataSource(.all)
                    .asObservable()
                    .map { _ in Mutation.ignore }
            case .filteredDataSelected:
                return self.provider.currentDataSourceService
                    .changeCurrentDataSource(.filtered)
                    .asObservable()
                    .map { _ in Mutation.ignore }
            case .favouriteDataSelected:
                return self.provider.currentDataSourceService
                    .changeCurrentDataSource(.favourites)
                    .asObservable()
                    .map { _ in Mutation.ignore }
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
                state.isMoreLoadingEnabled = true
                state.isLoading = false
                state.isError = false
            case let .setDataSource(dataSourceType):
                state.dataSource = dataSourceType
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
        case allDataSelected
        case favouriteDataSelected
        case filteredDataSelected
    }
    
    enum Mutation {
        case ignore
        case showData([Picture])
        case showLoading
        case showError
        case showCompleted
        case hideErrorAndLoading
        case setDataSource(DataSourceType)
        case setFocusedPicture(Picture)
    }
    
    struct State {
        var isMoreLoadingEnabled: Bool
        var isLoading: Bool
        var isError: Bool
        var dataSource: DataSourceType
        var data: [Picture]
        var focusedPicture: Picture?
        
        func isEmptyState() -> Bool {
            return data.count == 0 && isError == false && isLoading == false
        }
    }
}

