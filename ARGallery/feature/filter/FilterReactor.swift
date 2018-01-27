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
                return changeFilter { oldFilter in
                    var filter = oldFilter
                    filter.minPrice = minPrice
                    filter.maxPrice = maxPrice
                    return filter
                }
            case let .yearRangeChanged(minYear, maxYear):
                return changeFilter { oldFilter in
                    var filter = oldFilter
                    filter.minYear = minYear
                    filter.maxYear = maxYear
                    return filter
            }
            case .firstCategoryChanged:
                return changeFilter { oldFilter in
                    var filter = oldFilter
                    filter.firstCategoryEnabled = !oldFilter.firstCategoryEnabled
                    return filter
                }
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
            case let .changeCurrentFilter(filter):
                state.currentFilter = filter
                break
        }
        return state
    }
    
    private func changeFilter(_ changeFilterAction: @escaping (Filter) -> Filter) -> Observable<Mutation> {
        return self.provider.filterService
            .getCurrentFilterOnce()
            .map { oldFilter in changeFilterAction(oldFilter) }
            .flatMap { newFilter in
                self.provider.filterService.setFilter(filter: newFilter)
            }
            .map { .changeCurrentFilter(filter: $0)  }
    }
}

extension FilterReactor {
    
    enum Action {
        case priceRangeChanged(minPrice: Int, maxPrice: Int)
        case yearRangeChanged(minYear: Int, maxYear: Int)
        case firstCategoryChanged
        case reset
    }
    
    enum Mutation {
        case changeCurrentFilter(filter: Filter)
    }
    
    struct State {
        var defaultFilter: Filter
        var currentFilter: Filter
    }
}
