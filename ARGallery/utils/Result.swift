enum Result<VALUE> {
    
    case Success(VALUE)
    case Failure(Error)
    
    func isSuccess() -> Bool {
        switch self { case .Success: return true; case .Failure: return false }
    }
    
    func isFailure() -> Bool {
        return !isSuccess()
    }
    
    func either<R>(success : ((VALUE) -> R), failure : ((Error) -> R)) -> R {
        switch self {
        case let .Success(a): return success(a)
        case let .Failure(b) : return failure(b)
        }
    }
}

