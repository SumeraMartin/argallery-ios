protocol ServiceProviderType: class {
    
    var kenticoClientService: KenticoClientServiceType { get }
    
    var pictureCloudService: PictureCloudServiceType { get }
    
    var filterService: FilterServiceType { get }
    
    var focusedPictureService: FocusedPictureServiceType { get }
    
    var realmProviderService: RealmProviderServiceType { get }
    
    var popularPicturesService: PopularPicturesServiceType { get }
}

final class ServiceProvider: ServiceProviderType {

    lazy var kenticoClientService: KenticoClientServiceType = KenticoClientService(provider: self)
    
    lazy var pictureCloudService: PictureCloudServiceType = PictureCloudService(provider: self)
    
    lazy var filterService: FilterServiceType = FilterService(provider: self)
    
    lazy var focusedPictureService: FocusedPictureServiceType = FocusedPictureService(provider: self)
    
    lazy var realmProviderService: RealmProviderServiceType = RealmProviderService(provider: self)
    
    lazy var popularPicturesService: PopularPicturesServiceType = PopularPicturesService(provider: self)
}

