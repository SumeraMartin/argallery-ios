import RxDataSources

enum PictureDetailSectionItem {
    case pictureDetail(picture: Picture)
}

extension PictureDetailSectionItem: IdentifiableType, Equatable {
    var identity: String {
        switch self {
            case let .pictureDetail(picture):
                return picture.id
        }
    }
    
    public static func ==(lhs: PictureDetailSectionItem, rhs: PictureDetailSectionItem) -> Bool {
        switch (lhs, rhs) {
            case let (.pictureDetail(l), .pictureDetail(r)):
                return l.id == r.id
            default:
                return false
        }
    }
}
