import RxDataSources

enum PictureSectionItem {
    case DataItem(item: Picture)
    case FooterItem(isLoading: Bool, isError: Bool)
    case startEdgePadding
    case endEdgePadding
}

class PictureSectionItemId {
    
    static let startEdgePaddingId = "START_EDGE_PADDING"
    static let endEdgePaddingId = "END_EDGE_PADDING"
    static let loadMoreId = "LOAD_MORE_ID"
}

extension PictureSectionItem: IdentifiableType, Equatable {
    var identity : String {
        switch self {
            case let .DataItem(picture):
                return picture.id
            case .FooterItem(_):
                return PictureSectionItemId.loadMoreId
            case .startEdgePadding:
                return PictureSectionItemId.startEdgePaddingId
            case .endEdgePadding:
                return PictureSectionItemId.endEdgePaddingId
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


