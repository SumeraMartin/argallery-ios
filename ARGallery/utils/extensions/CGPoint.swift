import Foundation
import SceneKit

func +(left:SCNVector3, right:SCNVector3) -> SCNVector3 {
    
    return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
}

func -(left:SCNVector3, right:SCNVector3) -> SCNVector3 {
    
    return left + (right * -1.0)
}

func *(vector:SCNVector3, multiplier:SCNFloat) -> SCNVector3 {
    
    return SCNVector3(vector.x * multiplier, vector.y * multiplier, vector.z * multiplier)
}

func +(left:CGPoint, right:CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x,
                   y: left.y + right.y)
}

func -(left:CGPoint, right:CGPoint) -> CGPoint {
    
    return left + (right * -1.0)
}

func *(vector:CGPoint, multiplier:CGFloat) -> CGPoint {
    
    return CGPoint(x: vector.x * multiplier,
                   y: vector.y * multiplier)
}

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func distance(vector: CGPoint) -> CGFloat {
        return (self - vector).length()
    }
}
