import RxSwift
import KenticoCloud

protocol PictureCloudServiceType {
    
    func getPictures(offset: Int, limit: Int, filter: Filter) -> Observable<Result<[Picture]>>
}

class PictureCloudService: BaseService, PictureCloudServiceType {
    
    func getPictures(offset: Int, limit: Int, filter: Filter = Filter.createDefault()) -> Observable<Result<[Picture]>> {
        return provider.kenticoClientService
            .getClient()
            .flatMap { client in
                return Observable.create { observer in
                    let query = Query(systemType: "picture")
                        .add(key: "limit", value: "10")
                        .add(key: "skip", value: "0")
                        .add(key: "elements.price[gte]", value: filter.minPrice)
                        .add(key: "elements.price[lte]", value: filter.maxPrice)
                        .build()
    
                    client.getItems(modelType: Picture.self, customQuery: query) { (isSuccess, itemsResponse, error) in
                        if isSuccess {
                            if let pictures = itemsResponse?.items {
                                observer.onNext(Result.Success(pictures))
                            } else {
                               fatalError("Kentico client successful response without items")
                            }
                        } else {
                            if let error = error {
                                observer.onNext(Result.Failure(error))
                            } else {
                                fatalError("Kentico client unsuccessful response without error")
                            }
                        }
                        observer.onCompleted()
                    }
                    
                    return Disposables.create()
                }
            }
            .delay(RxTimeInterval(5), scheduler: MainScheduler.instance)
    }
}
