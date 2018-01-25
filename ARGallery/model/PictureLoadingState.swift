enum PictureLoadingState {
    
    case InitialLoading
    case InitialError
    case MoreLoading
    case MoreError
    case Inactive
    
    func isAllowedToLoadMore() -> Bool {
        let isInitialLoading = self == .InitialLoading
        let isInitialError = self == .InitialError
        return !isInitialLoading && !isInitialError
    }
}
