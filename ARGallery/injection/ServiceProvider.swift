protocol ServiceProviderType: class {
    
    var kenticoClientService: KenticoClientServiceType { get }
    
    var filterService: FilterServiceType { get }
    
    var focusedPictureService: FocusedPictureServiceType { get }
    
    var realmProviderService: RealmProviderServiceType { get }
    
    var currentDataSourceService: CurrentDataSourceServiceType { get }
    
    var allPicturesCloudService: PictureDataSourceServiceType { get }
    
    var filteredPicturesCloudService: PictureDataSourceServiceType { get }
    
    var favouritePicturesService: FavouriteDataSourceServiceType { get }
    
    var selectedPictureService: SelectedPictureServiceType { get }
}

final class ServiceProvider: ServiceProviderType {

    lazy var kenticoClientService: KenticoClientServiceType = KenticoClientService(provider: self)
    
    lazy var allPicturesCloudService: PictureDataSourceServiceType = AllPicturesCloudService(provider: self)
    
    lazy var filteredPicturesCloudService: PictureDataSourceServiceType = FilteredPicturesCloudService(provider: self)
    
    lazy var filterService: FilterServiceType = FilterService(provider: self)
    
    lazy var focusedPictureService: FocusedPictureServiceType = FocusedPictureService(provider: self)
    
    lazy var realmProviderService: RealmProviderServiceType = RealmProviderService(provider: self)
    
    lazy var favouritePicturesService: FavouriteDataSourceServiceType = FavouritePicturesService(provider: self)
    
    lazy var currentDataSourceService: CurrentDataSourceServiceType = CurrentDataSourceService(provider: self)
    
    lazy var selectedPictureService: SelectedPictureServiceType = SelectedImageService(provider: self)
}

