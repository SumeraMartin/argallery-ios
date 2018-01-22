protocol AppAssemblerType {
    
    var serviceProvider: ServiceProviderType { get }
    
    var reactorProvider: ReactorProviderType { get }
}

class AppAssembler: AppAssemblerType {
  
    var serviceProvider: ServiceProviderType
    
    var reactorProvider: ReactorProviderType
    
    required init() {
        serviceProvider = ServiceProvider()
        reactorProvider = ReactorProvider(serviceProvider: serviceProvider)
    }
}

protocol AppAssemblerClient {
    
    var assembler: AppAssemblerType! { set get }
}
