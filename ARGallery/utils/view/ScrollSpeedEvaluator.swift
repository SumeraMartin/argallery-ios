import UIKit

class ScrollSpeedEvaluator {
    
    let captureInterval = 0.1
    
    let slowScrollingThreshold = Float(0.5)
    
    var lastOffset = CGPoint(x: 0, y: 0)
    
    var lastOffsetTime = TimeInterval(0)
    
    var lastIsSrollingSlowlyState = false
    
    func isScrollingSlowly(_ scrollView: UIScrollView) -> Bool {
        let currentOffset = scrollView.contentOffset
        let currentTime = NSDate().timeIntervalSinceReferenceDate
        let timeDifference = currentTime - lastOffsetTime
        
        if timeDifference > captureInterval {
            let distance = currentOffset.x - lastOffset.x
            let scrollSpeed = fabsf(Float((distance * 10) / 1000))
            
            print(scrollSpeed)
            
            lastIsSrollingSlowlyState = scrollSpeed < slowScrollingThreshold
            lastOffset = currentOffset
            lastOffsetTime = currentTime
        }
        
        return lastIsSrollingSlowlyState
    }
}
