import RxDataSources

enum PictureSectionItem {
    case DataItem(item: Picture)
    case FooterItem(isLoading: Bool, isError: Bool)
    case startEdgePadding
    case endEdgePadding
}

extension PictureSectionItem: IdentifiableType, Equatable {
    var identity : String {
        switch self {
            case let .DataItem(picture):
                return picture.id
            case .FooterItem(_):
                return "FOOTER_ID"
            case .startEdgePadding:
                return "START_EDGE_PADDING"
            case .endEdgePadding:
                return "END_EDGE_PADDING"
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


