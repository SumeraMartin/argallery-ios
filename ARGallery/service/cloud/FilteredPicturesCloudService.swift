class FilteredPicturesCloudService : AllPicturesCloudService {
    
    override init(provider: ServiceProviderType) {
        super.init(provider: provider)
        
        self.dataSource = .filtered
        
        subscribeToFitlerChanges()
    }
    
    override func buildQuery(_ query: Query) -> Query {
        let filter = self.provider.filterService.getCurrentFilter()
        return query
            .add(key: "elements.price[gte]", value: filter.minPrice)
            .add(key: "elements.price[lte]", value: filter.maxPrice)
//            .add(key: "system.id[in]", value: "f99e2d6f-f6a4-4cc9-8ecd-02e10f1501c9")
    }
    
    private func subscribeToFitlerChanges() {
        self.provider.filterService
            .getFilterChanges()
            .do(onNext: { _ in self.reload() })
            .subscribe()
            .disposed(by: disposeBag)
    }
}
