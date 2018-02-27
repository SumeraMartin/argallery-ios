import Foundation
import SceneKit

class TrackingNode {
    
    class func nodeWithWall(from: SCNVector3, to: SCNVector3) -> SCNNode {
        let startNode = createNode()
        startNode.position = from
        startNode.name = "start_node"
        
        let endNode = createNode2()
        endNode.position = to
        endNode.name = "end_node"
        
        let node = SCNNode()
        node.addChildNode(startNode)
        node.addChildNode(endNode)
        node.addChildNode(Wall.node(from: from, to: to))
        
        return node
    }
    
    class func nodeWithoutWall(position: SCNVector3) -> SCNNode {
        let node = createNode()
        node.position = position
        node.name = "end_node"
        return node
    }
    
    class private func createNode() -> SCNNode {
        let sphere = SCNSphere(radius: 0.01)
        sphere.firstMaterial?.diffuse.contents = UIColor.black
        return SCNNode(geometry: sphere)
    }
    
    class private func createNode2() -> SCNNode {
        let sphere = SCNSphere(radius: 0.01)
        sphere.firstMaterial?.diffuse.contents = UIColor.red
        return SCNNode(geometry: sphere)
    }
}
