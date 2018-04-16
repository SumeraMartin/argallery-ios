import RxDataSources

enum PictureThumbnailSectionItem {
    case picture(picture: Picture)
}

extension PictureThumbnailSectionItem: IdentifiableType, Equatable {
    var identity : String {
        switch self {
            case let .picture(picture):
                return picture.id
        }
    }
    
    public static func ==(lhs: PictureThumbnailSectionItem, rhs: PictureThumbnailSectionItem) -> Bool {
        switch (lhs, rhs) {
            case let (.picture(l), .picture(r)):
                return l.id == r.id
        }
    }
}

