import Foundation
import SceneKit
import SpriteKit

let WALL_TEXT_SIZE_MULP:CGFloat = 100

class Wall {
    
    static let HEIGHT:CGFloat = 3.0
    
    static let NAME = "Wall"
    
    class func wallMaterial() -> SCNMaterial {
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.darkGray
        mat.transparency = 0.5
        mat.isDoubleSided = true
        return mat
    }
    
    class func maskMaterial() -> SCNMaterial {
        let maskMaterial = SCNMaterial()
        maskMaterial.diffuse.contents = UIColor.white
        maskMaterial.colorBufferWriteMask = SCNColorMask(rawValue: 0)
        maskMaterial.isDoubleSided = true
        return maskMaterial
    }
    
    class func node(from:SCNVector3,
                    to:SCNVector3) -> SCNNode {
        let distance = from.distance(vector: to)
        
        let wall = SCNPlane(width: CGFloat(distance),
                            height: HEIGHT)
        wall.firstMaterial = wallMaterial()
        let node = SCNNode(geometry: wall)
        node.name = NAME
        node.renderingOrder = -10
        node.position = SCNVector3(from.x + (to.x - from.x) * 0.5, from.y + Float(HEIGHT) * 0.5, from.z + (to.z - from.z) * 0.5)
        
        node.eulerAngles = SCNVector3(0,
                                      -atan2(to.x - node.position.x, from.z - node.position.z) - Float.pi * 0.5,
                                      0)
        
//        let v = from - to
//        let p1 = SCNVector3(-v.x, 0, v.z) / sqrt(v.x * v.x + v.y * v.y) * 0.1
//        let p2 = SCNVector3(v.x, 0, v.z) / sqrt(v.x * v.x + v.y * v.y) * -0.1
//        let p1 = SCNVector3(0, 0, 0.1)
//        let p2 = SCNVector3(0, 0, -0.1)
        
//        let test1 = createNode1()
//        test1.position =  p1
//        test1.name = "test1"
//        node.addChildNode(test1)
//
//        let test2 = createNode2()
//        test2.position = p2
//        test2.name = "test2"
//        node.addChildNode(test2)
        
        return node
    }
    
    class private func createNode1() -> SCNNode {
        let sphere = SCNSphere(radius: 0.01)
        sphere.firstMaterial?.diffuse.contents = UIColor.blue
        return SCNNode(geometry: sphere)
    }
    
    class private func createNode2() -> SCNNode {
        let sphere = SCNSphere(radius: 0.01)
        sphere.firstMaterial?.diffuse.contents = UIColor.red
        return SCNNode(geometry: sphere)
    }
}

extension SCNVector3 {
    
    func dotProduct(_ vectorB:SCNVector3) -> SCNFloat {
        
        return (x * vectorB.x) + (y * vectorB.y) + (z * vectorB.z)
    }
    
    var magnitude:SCNFloat {
        get {
            return sqrt(dotProduct(self))
        }
    }
    
    var normalized:SCNVector3 {
        get {
            let localMagnitude = magnitude
            let localX = x / localMagnitude
            let localY = y / localMagnitude
            let localZ = z / localMagnitude
            
            return SCNVector3(localX, localY, localZ)
        }
    }
    
    func length() -> Float {
        return sqrtf(x*x + y*y + z*z)
    }
    
    func distance(vector: SCNVector3) -> Float {
        return (self - vector).length()
    }
}

