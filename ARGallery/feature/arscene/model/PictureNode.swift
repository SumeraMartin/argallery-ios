import Foundation
import SceneKit

class PictureNode {
    
    static let firstPictureNodeName = "first_picture_node"
    static let secondPictureNodeName = "second_picture_node"
    
    class private func startNode() -> SCNNode {
        let sphere = SCNSphere(radius: 0.02)
        sphere.firstMaterial?.diffuse.contents = UIColor.black
        return SCNNode(geometry: sphere)
    }
    
    class func node(at position:SCNVector3, eulerAngles: SCNVector3, withMaterial material: SCNMaterial) -> SCNNode {
        let nodeInWall = SCNNode()
        nodeInWall.position = position
        nodeInWall.eulerAngles = eulerAngles
        
        let child1 = createNode(material: material)
        child1.position = SCNVector3(0, 0, 0.001)
        child1.name = PictureNode.firstPictureNodeName
        nodeInWall.addChildNode(child1)
        
        let child2 = createNode(material: material)
        child2.position = SCNVector3(0, 0, -0.001)
        child2.name = PictureNode.secondPictureNodeName
        nodeInWall.addChildNode(child2)
        
        return nodeInWall
    }
    
    private class func createNode(material: SCNMaterial) -> SCNNode {
        let cube: SCNGeometry? = SCNPlane(width: 0.5, height: 0.5)
        let node = SCNNode(geometry: cube)
        node.geometry?.materials = [material]
        return node
    }
}

