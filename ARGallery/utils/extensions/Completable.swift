import RxSwift

func createCompletable(_ action: @escaping () -> Void) -> Completable {
    return Completable.create { completable in
        action()
        completable(.completed)
        return Disposables.create {}
    }
}

func createVoidSingle(_ action: @escaping () -> Void) -> Single<Void> {
    return Single.create { single in
        action()
        single(.success(Void()))
        return Disposables.create {}
    }
}
