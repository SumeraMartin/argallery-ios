struct LoadingStateWithPictures {
    
    var dataSource: DataSourceType
    
    var loadingState: LoadingState
    
    var data: [Picture]

    static func createDefault() -> LoadingStateWithPictures {
        return LoadingStateWithPictures(dataSource: .all, loadingState: LoadingState.inactive, data: [])
    }
}
