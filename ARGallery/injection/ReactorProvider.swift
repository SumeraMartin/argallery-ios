protocol ReactorProviderType {
    
    var pictureListReactor: PictureListReactor { get }
    
    func createPictureListReactor() -> PictureListReactor
    
    func createPictureDetailReactor() -> PictureDetailReactor
    
    func createFilterReactor() -> FilterReactor
}

class ReactorProvider: ReactorProviderType {
    
    var serviceProvider: ServiceProviderType
    
    var pictureListReactor: PictureListReactor
    
    required init(serviceProvider: ServiceProviderType) {
        self.serviceProvider = serviceProvider
        self.pictureListReactor = PictureListReactor(provider: serviceProvider)
    }
    
    func createPictureListReactor() -> PictureListReactor {
        return PictureListReactor(provider: serviceProvider)
    }
    
    func createPictureDetailReactor() -> PictureDetailReactor {
        return PictureDetailReactor(provider: serviceProvider)
    }
    
    func createFilterReactor() -> FilterReactor {
        return FilterReactor(provider: serviceProvider)
    }
}
