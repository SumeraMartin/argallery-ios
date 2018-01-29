import RxSwift

extension ObservableType where E: Sequence, E.Iterator.Element: Equatable {
    func distinctUntilChanged() -> Observable<E> {
        return distinctUntilChanged { (lhs, rhs) -> Bool in
            return Array(lhs) == Array(rhs)
        }
    }
}

extension ObservableType where E: Equatable {
    func distinctUntilChanged() -> Observable<E> {
        return distinctUntilChanged { (lhs, rhs) -> Bool in
            return lhs == rhs
        }
    }
}

extension ObservableType where E: Any {
    func getChange<R: Equatable>(_ transform: @escaping (Self.E) throws -> R)  -> RxSwift.Observable<R> {
        return self.map(transform).distinctUntilChanged()
    }
    
    func getChange<R: Equatable>(_ transform: @escaping (Self.E) throws -> R?)  -> RxSwift.Observable<R?> {
        return self.map(transform).distinctUntilChanged { lhs, rhs in lhs == rhs }
    }
    
    func getChange<R>(_ transform: @escaping (Self.E) throws -> R)  -> RxSwift.Observable<R> where R:Sequence, R.Iterator.Element: Equatable {
        return self.map(transform).distinctUntilChanged()
    }
}

