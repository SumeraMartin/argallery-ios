import ObjectMapper
import KenticoCloud
import RxDataSources

class CloudPicture: Mappable {
    
    let id: String
    
    let title: String
    
    let author: String
    
    let pictureUrl: String
    
    let description: String
    
    let price: Double
    
    let year: Double
    
    required init?(map: Map){
        let mapper = MapElement.init(map: map)
        
        id = CloudPicture.getId(from: map)
        pictureUrl = CloudPicture.getPictureUrl(from: mapper)
        title = mapper.map(elementName: "title", elementType: TextElement.self).value ?? ""
        author = mapper.map(elementName: "author", elementType: TextElement.self).value ?? ""
        description = mapper.map(elementName: "description", elementType: TextElement.self).value ?? ""
        price = mapper.map(elementName: "price", elementType: NumberElement.self).value ?? 0
        year = mapper.map(elementName: "year", elementType: NumberElement.self).value ?? 0
    }
    
    func mapping(map: Map) {
    }
    
    private static func getId(from map: Map) -> String {
        var systemId = ""
        systemId <- map["system.id"]
        return systemId
    }
    
    private static func getPictureUrl(from mapper: MapElement) -> String {
        var url = ""
        let pictureAssets = mapper.map(elementName: "picture", elementType: AssetElement.self).value
        if let assets = pictureAssets {
            if assets.count > 0 {
                url = assets[0].url ?? ""
            }
        }
        return url
    }
}
