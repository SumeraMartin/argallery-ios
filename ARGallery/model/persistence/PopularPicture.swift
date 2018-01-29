import RealmSwift

class PopularPicture: Object {
    
    @objc dynamic var id = ""
    
    @objc dynamic var title = ""
    
    @objc dynamic var author = ""
    
    @objc dynamic var pictureUrl = ""
    
    @objc dynamic var pictureDescription = ""
    
    @objc dynamic var price: Double = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
