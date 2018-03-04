import RxSwift

protocol SelectedPictureServiceType {
    
    func setSelectedPicture(_ picture: Picture) -> Observable<Void>
    
    func getSelectedPictureObservable() -> Observable<Picture?>
}

class SelectedImageService : BaseService, SelectedPictureServiceType {
    
    private let selectedPictureSubject = BehaviorSubject<Picture?>(value: nil)
    
    func setSelectedPicture(_ picture: Picture) -> Observable<Void> {
        selectedPictureSubject.onNext(picture)
        return Observable.just(Void())
    }
    
    func getSelectedPictureObservable() -> Observable<Picture?> {
        return selectedPictureSubject
    }
}
