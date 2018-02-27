import Foundation
import SceneKit

class PictureNode {
    class private func startNode() -> SCNNode {
        let sphere = SCNSphere(radius: 0.02)
        sphere.firstMaterial?.diffuse.contents = UIColor.black
        return SCNNode(geometry: sphere)
    }
    
    class func node(at position:SCNVector3, eulerAngles: SCNVector3) -> SCNNode {
        let imageMaterial = SCNMaterial()
        imageMaterial.isDoubleSided = false
        imageMaterial.diffuse.contents = UIColor.red
        let cube: SCNGeometry? = SCNBox(width: 0.3, height: 0.3, length: 0.05, chamferRadius: 0)
        let node = SCNNode(geometry: cube)
        node.geometry?.materials = [imageMaterial]
        node.position = position
        node.eulerAngles = eulerAngles
        
        return node
    }
}

