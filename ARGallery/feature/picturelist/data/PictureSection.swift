import RxDataSources

enum PictureSectionItem {
    case DataItem(item: Picture)
    case FooterItem(isLoading: Bool, isError: Bool)
}

extension PictureSectionItem: IdentifiableType, Equatable {
    var identity : UInt32 {
        switch self {
            case let .DataItem(picture):
                return picture.id
            case .FooterItem(_):
                return UInt32(1000000)
        }
    }
    
    public static func ==(lhs: PictureSectionItem, rhs: PictureSectionItem) -> Bool {
        switch (lhs, rhs) {
            case let (.DataItem(l), .DataItem(r)):
                return l.id == r.id
            case let (.FooterItem(leftLoading, leftError), .FooterItem(rightLoading, rightError)):
                return leftLoading == rightLoading && leftError == rightError
            default:
                return false
        }
    }
}


