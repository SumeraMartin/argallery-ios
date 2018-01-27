import ObjectMapper
import KenticoCloud
import RxDataSources

class Picture: Mappable {
    
    let id: String
    
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
        
        var systemId = ""
        systemId <- map["system.id"]
//        id = systemId
        id = randomString(length: 20)
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
        return lhs.id == rhs.id
    }
    
    static func != (lhs: Picture, rhs: Picture) -> Bool {
        return !(lhs == rhs)
    }
}

func randomString(length: Int) -> String {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let len = UInt32(letters.length)
    
    var randomString = ""
    
    for _ in 0 ..< length {
        let rand = arc4random_uniform(len)
        var nextChar = letters.character(at: Int(rand))
        randomString += NSString(characters: &nextChar, length: 1) as String
    }
    
    return randomString
}
