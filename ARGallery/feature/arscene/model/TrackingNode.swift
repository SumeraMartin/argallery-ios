import Foundation
import SceneKit

class TrackingNode {
    
    static let START_NODE_NAME = "start_node"
    
    static let END_NODE_NAME = "end_node"
    
    static let TRACKING_NODE_NAME = "tracking_node"
    
    class func nodeWithWall(from: SCNVector3, to: SCNVector3) -> SCNNode {
        let startNode = createNode()
        startNode.position = from
        startNode.name = TrackingNode.START_NODE_NAME
        
        let endNode = createNode()
        endNode.position = to
        endNode.name = TrackingNode.END_NODE_NAME
        
        let cylinder = SCNCylinder(radius: 0.03, height: 0.005)
        cylinder.firstMaterial?.diffuse.contents = UIColor.darkGray
        cylinder.firstMaterial?.transparency = 0.5
        let cylinderNode = SCNNode(geometry: cylinder)
        cylinderNode.position = to
        
        let node = SCNNode()
        node.addChildNode(startNode)
        node.addChildNode(endNode)
        node.addChildNode(Wall.node(from: from, to: to))
        node.addChildNode(cylinderNode)
        node.name = TrackingNode.TRACKING_NODE_NAME
        
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
}
