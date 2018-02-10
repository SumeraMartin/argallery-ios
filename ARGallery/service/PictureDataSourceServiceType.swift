import RxSwift

protocol PictureDataSourceServiceType {
    
    func getLoadingStateWithDataObservable() -> Observable<LoadingStateWithPictures>
    
    func getLoadingStateWithDataSingle() -> Single<LoadingStateWithPictures>
    
    func getPictures() -> [Picture]
    
    func loadMore()
    
    func reload()
    
    func wasSelected()
}
