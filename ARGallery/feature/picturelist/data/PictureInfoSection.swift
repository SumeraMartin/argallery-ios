import RxDataSources

enum PictureInfoSectionItem {
    case pictureInfo(picture: Picture)
}

extension PictureInfoSectionItem: IdentifiableType, Equatable {
    var identity : String {
        switch self {
            case let .pictureInfo(picture):
                return picture.id
        }
    }
    
    public static func ==(lhs: PictureInfoSectionItem, rhs: PictureInfoSectionItem) -> Bool {
        switch (lhs, rhs) {
            case let (.pictureInfo(l), .pictureInfo(r)):
                return l.id == r.id
        }
    }
}



