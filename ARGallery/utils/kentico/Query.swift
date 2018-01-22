class Query {
    
    struct QueryParam {
        
        let key: String
        
        let value: String
        
        var stringRepresentation: String {
            return key + "=" + value
        }
        
        init(key: String, value: String) {
            self.key = key
            self.value = value
        }
    }
    
    let type: String
    
    var queryParams: [QueryParam] = []
    
    init(type: String = "items", systemType: String) {
        self.type = type
        addInternal(key: "system.type", value: systemType)
    }
    
    func add(key: String, value: String) -> Query {
        addInternal(key: key, value: value)
        return self
    }
    
    func add(key: String, value: Int) -> Query {
        addInternal(key: key, value: String(value))
        return self
    }
    
    func build() -> String {
        if queryParams.count == 0 {
            return ""
        }
        
        var queryString = self.type + "?"
        for (index, param) in queryParams.enumerated() {
            queryString.append(param.stringRepresentation)
            if index != queryParams.count - 1 {
                queryString.append("&")
            }
        }
        
        return queryString
    }
    
    private func addInternal(key: String, value: String) {
        queryParams.append(QueryParam(key: key, value: value))
    }
}
