import UIKit

struct Picture {
    
    let id: String
    
    let title: String
    
    let author: String
    
    let pictureUrl: String
    
    let description: String
    
    let price: Double
    
    let year: Double
    
    var url: URL? {
        get { return URL(string: pictureUrl) }
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
