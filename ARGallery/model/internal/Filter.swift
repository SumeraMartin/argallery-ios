struct Filter: CustomStringConvertible {
    
    var minPrice: Int
    
    var maxPrice: Int
    
    var minYear: Int
    
    var maxYear: Int
    
    var firstCategoryEnabled: Bool
    
    var secondCategoryEnabled: Bool
    
    var thirdCategoryEnabled: Bool
    
    static func createDefault() -> Filter {
        return Filter(
            minPrice: 100,
            maxPrice: 10_000,
            minYear: 1850,
            maxYear: 2018,
            firstCategoryEnabled: true,
            secondCategoryEnabled: true,
            thirdCategoryEnabled: true
        )
    }
    
    var description: String {
        return "Filter  minPrice:\(minPrice) and maxPrice\(maxPrice) " +
        "minYear:\(minYear) maxYear:\(maxYear) firstCategoryEnabled:\(firstCategoryEnabled) " +
        " secondCategoryEnabled:\(secondCategoryEnabled) thirdCategoryEnabled:\(thirdCategoryEnabled) "
    }
}

extension Filter: Equatable {
    static func == (lhs: Filter, rhs: Filter) -> Bool {
        return lhs.minPrice == rhs.minPrice
            && lhs.maxPrice == rhs.maxPrice
            && lhs.minYear == rhs.minYear
            && lhs.maxYear == rhs.maxYear
            && lhs.firstCategoryEnabled == rhs.firstCategoryEnabled
            && lhs.secondCategoryEnabled == rhs.secondCategoryEnabled
            && lhs.thirdCategoryEnabled == rhs.thirdCategoryEnabled
    }
}
