import RxSwift

protocol FocusedPictureServiceType {
    
    func setFocusedPicture(_ picture: Picture) -> Observable<Void>
    
    func getFocusedPictureObservable() -> Observable<Picture?>
}

class FocusedPictureService: BaseService, FocusedPictureServiceType {
    
    private let focusedPictureSubject = BehaviorSubject<Picture?>(value: nil)
    
    func setFocusedPicture(_ picture: Picture) -> Observable<Void> {
        focusedPictureSubject.onNext(picture)
        print()
        print(picture.title)
        print(picture.id)
        print()
        return Observable.just(Void())
    }
    
    func getFocusedPictureObservable() -> Observable<Picture?> {
        return focusedPictureSubject.asObservable()
    }
}
