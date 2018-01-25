import ObjectMapper
import KenticoCloud
import RxDataSources

class Picture: Mappable {
    
    var id: String = "XXX"
    
    let title: TextElement
    
    let author: TextElement
    
    let picture: AssetElement
    
    let description: TextElement
    
    let price: NumberElement
    
    var pictureURL: URL? {
        guard let value = picture.value else { return nil }
        guard value.count > 0 else { return nil }
        
        let urlString = value[0].url ?? ""
        if urlString != "" {
            return URL(string: urlString)
        }
        return nil
    }
    
    required init?(map: Map){
        let mapper = MapElement.init(map: map)
        
        id <- map["system.id"]
        title = mapper.map(elementName: "title", elementType: TextElement.self)
        author = mapper.map(elementName: "author", elementType: TextElement.self)
        picture = mapper.map(elementName: "picture", elementType: AssetElement.self)
        description = mapper.map(elementName: "description", elementType: TextElement.self)
        price = mapper.map(elementName: "price", elementType: NumberElement.self)
    }
    
    func mapping(map: Map) {
    }
}

extension Picture: Equatable {
    static func == (lhs: Picture, rhs: Picture) -> Bool {
        return lhs.title.value == rhs.title.value // TODO this should be replaced with ID
    }
    
    static func != (lhs: Picture, rhs: Picture) -> Bool {
        return !(lhs == rhs)
    }
}
