import RxSwift

class FilterReactor: BaseReactor {
    
    let provider: ServiceProviderType
    let initialState: State
    
    init(provider: ServiceProviderType) {
        self.provider = provider
        self.initialState = State(
            defaultFilter: Filter.createDefault(),
            currentFilter: provider.filterService.getCurrentFilter()
        )
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch(action) {
            case let .priceRangeChanged(minPrice, maxPrice):
                return self.provider.filterService
                    .getCurrentFilterOnce()
                    .map { oldFilter in
                        var filter = oldFilter
                        filter.minPrice = minPrice
                        filter.maxPrice = maxPrice
                        return filter
                    }
                    .flatMap { newFilter in
                        self.provider.filterService.setFilter(filter: newFilter)
                    }
                    .map { .changeCurrentFilter(filter: $0)  }
            case .reset:
                return Observable.just(Filter.createDefault())
                    .flatMap { newFilter in
                        self.provider.filterService.setFilter(filter: newFilter)
                    }
                    .map { .changeCurrentFilter(filter: $0) }
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch(mutation) {
            case .ignore:
                break
            case let .changeCurrentFilter(filter):
                state.currentFilter = filter
                break
        }
        return state
    }
}

extension FilterReactor {
    
    enum Action {
        case priceRangeChanged(minPrice: Int, maxPrice: Int)
        case reset
    }
    
    enum Mutation {
        case ignore
        case changeCurrentFilter(filter: Filter)
    }
    
    struct State {
        var defaultFilter: Filter
        var currentFilter: Filter
    }
}
