protocol ReactorProviderType {
    
    var pictureListReactor: PictureListReactor { get }
    
    func createPictureListReactor() -> PictureListReactor
    
    func createPictureDetailReactor(initialPicture: Picture) -> PictureDetailReactor
    
    func createFilterReactor() -> FilterReactor
    
    func createArSceneReactor() -> ARSceneReactor
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
    
    func createPictureDetailReactor(initialPicture: Picture) -> PictureDetailReactor {
        return PictureDetailReactor(provider: serviceProvider, initialPicture: initialPicture)
    }
    
    func createFilterReactor() -> FilterReactor {
        return FilterReactor(provider: serviceProvider)
    }
    
    func createArSceneReactor() -> ARSceneReactor {
        return ARSceneReactor(provider: serviceProvider)
    }
}
