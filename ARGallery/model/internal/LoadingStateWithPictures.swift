struct LoadingStateWithPictures {
    
    var loadingState: LoadingState
    
    var data: [Picture]

    static func createDefault() -> LoadingStateWithPictures {
        return LoadingStateWithPictures(loadingState: LoadingState.inactive, data: [])
    }
}
