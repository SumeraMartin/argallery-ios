//func ==<T: Equatable>(lhs: [T]?, rhs: [T]?) -> Bool {
//    switch (lhs, rhs) {
//        case let (l?, r?):
//            return l == r
//        case (.none, .none):
//            return true
//        default:
//            return false
//    }
//}

func !=<T: Equatable>(lhs: T?, rhs: T?) -> Bool {
    return !(lhs == rhs)
}
