protocol ServiceProviderType: class {
    
    var kenticoClientService: KenticoClientServiceType { get }
    
    var pictureCloudService: PictureCloudServiceType { get }
    
    var filterService: FilterService { get }
}

final class ServiceProvider: ServiceProviderType {
    
    lazy var kenticoClientService: KenticoClientServiceType = KenticoClientService(provider: self)
    
    lazy var pictureCloudService: PictureCloudServiceType = PictureCloudService(provider: self)
    
    lazy var filterService: FilterService = FilterService(provider: self)
}

