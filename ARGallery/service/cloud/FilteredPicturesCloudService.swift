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
            .add(key: "elements.year[gte]", value: filter.minYear)
            .add(key: "elements.year[lte]", value: filter.maxYear)
            .add(key: "elements.categories[any]", value: createCategoriesArray(filter: filter))
    }
    
    private func subscribeToFitlerChanges() {
        self.provider.filterService
            .getFilterChanges()
            .do(onNext: { _ in self.reload() })
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    private func createCategoriesArray(filter: Filter) -> String {
        var array: [String] = []
        if filter.firstCategoryEnabled {
            array.append("is_animal_picture")
        }
        if filter.secondCategoryEnabled {
            array.append("is_nature_picture")
        }
        return array.joined(separator: ",")
    }
}
