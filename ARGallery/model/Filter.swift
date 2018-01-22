struct Filter: CustomStringConvertible {
    
    var minPrice: Int
    
    var maxPrice: Int
    
    static func createDefault() -> Filter {
        return Filter(
            minPrice: 0,
            maxPrice: 10_000_000_000
        )
    }
    
    var description: String {
        return "Filter minPrice:\(minPrice) and maxPrice\(maxPrice)"
    }
}

extension Filter: Equatable {
    static func == (lhs: Filter, rhs: Filter) -> Bool {
        return lhs.minPrice == rhs.minPrice && lhs.maxPrice == rhs.maxPrice
    }
}
