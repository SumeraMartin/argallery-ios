import RxSwift

protocol FilterServiceType {
    
    func getCurrentFilter() -> Filter
    
    func getCurrentFilterOnce() -> Observable<Filter>
    
    func getFilterChanges() -> Observable<Filter>
    
    func setFilter(filter: Filter) -> Observable<Filter>
    
    func resetFilter()
}

class FilterService: BaseService, FilterServiceType {
    
    let filterSubject = BehaviorSubject<Filter>(value: Filter.createDefault())
    
    func getCurrentFilter() -> Filter {
        do {
            return try filterSubject.value()
        } catch {
            fatalError("BehaviourSubject in FilterService can't emit value")
        }
    }
    
    func getCurrentFilterOnce() -> Observable<Filter> {
        return filterSubject.take(1)
    }
    
    func getFilterChanges() -> Observable<Filter> {
        return filterSubject
    }
    
    func setFilter(filter: Filter) -> Observable<Filter> {
        print(filter)
        
        filterSubject.on(.next(filter))
        return Observable.just(filter)
    }
    
    func resetFilter() {
        filterSubject.on(.next(Filter.createDefault()))
    }
}
