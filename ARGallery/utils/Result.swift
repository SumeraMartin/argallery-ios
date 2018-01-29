enum Result<VALUE> {
    
    case Success(VALUE)
    case Failure(Error)
    
    func isSuccess() -> Bool {
        switch self { case .Success: return true; case .Failure: return false }
    }
    
    func isFailure() -> Bool {
        return !isSuccess()
    }
    
    func either<R>(success: ((VALUE) -> R), failure: ((Error) -> R)) -> R {
        switch self {
        case let .Success(a): return success(a)
        case let .Failure(b) : return failure(b)
        }
    }
    
    func map<R>(block: (VALUE) -> R) -> Result<R> {
        switch self {
            case let .Success(value): return .Success(block(value))
            case let .Failure(error) : return .Failure(error)
        }
    }
    
    func flatMap(success: ((VALUE) -> ()), failure: ((Error) -> ())) {
        switch self {
            case let .Success(a):
                success(a)
                break
            case let .Failure(b) :
                failure(b)
                break
        }
    }
}

