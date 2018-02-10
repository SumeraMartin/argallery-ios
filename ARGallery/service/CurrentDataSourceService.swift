import RxSwift

enum DataSourceType {
    case all
    case filtered
    case favourites
}

protocol CurrentDataSourceServiceType {
    
    func getCurrentDataSource() -> PictureDataSourceServiceType
    
    func getCurrentDataSourceSingle() -> Single<PictureDataSourceServiceType>
    
    func getCurrentDataSourceObservable() -> Observable<PictureDataSourceServiceType>
    
    func changeCurrentDataSource(_ dataSourceType: DataSourceType) -> Single<Void>
}

class CurrentDataSourceService: BaseService, CurrentDataSourceServiceType {
 
    private let currentDataSource = BehaviorSubject<DataSourceType>(value: DataSourceType.all)
    
    func getCurrentDataSource() -> PictureDataSourceServiceType {
        do {
            let sourceType = try currentDataSource.value()
            return selectDataSource(forType: sourceType)
        } catch {
            fatalError("Behaviour subject without default data")
        }
    }
    
    func getCurrentDataSourceSingle() -> Single<PictureDataSourceServiceType> {
        return getCurrentDataSourceObservable()
            .take(1)
            .asSingle()
    }
    
    func getCurrentDataSourceObservable() -> Observable<PictureDataSourceServiceType> {
        return currentDataSource
            .asObservable()
            .flatMapLatest { dataSourceType in Observable.just(self.selectDataSource(forType: dataSourceType)) }
            .do(onNext: { dataSource in dataSource.wasSelected() })
    }
    
    func changeCurrentDataSource(_ dataSource: DataSourceType) -> Single<Void> {
        return createVoidSingle {
            self.currentDataSource.onNext(dataSource)
        }
    }
    
    private func selectDataSource(forType dataSourceType: DataSourceType) -> PictureDataSourceServiceType {
        switch(dataSourceType) {
            case .all:
                return self.provider.allPicturesCloudService
            case .filtered:
                return self.provider.filteredPicturesCloudService
            case .favourites:
                return self.provider.favouritePicturesService
        }
    }
}
