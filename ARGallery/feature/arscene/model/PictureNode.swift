import Foundation
import SceneKit

class PictureNode {
    
    static let firstPictureNodeName = "first_picture_node"
    static let secondPictureNodeName = "second_picture_node"
    static let originalScale = SCNVector3(0.75, 0.75, 0.75)
    
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
        child1.position = SCNVector3(0, 0, 0.01)
        child1.name = PictureNode.firstPictureNodeName
        nodeInWall.addChildNode(child1)
        
        let child2 = createNode(material: material)
        child2.position = SCNVector3(0, 0, -0.01)
        child2.name = PictureNode.secondPictureNodeName
        nodeInWall.addChildNode(child2)
        
        let pictureNode1 = createPictureNode(material: material, rotateAngle: 0)
        child1.addChildNode(pictureNode1)
        
        let pictureNode2 = createPictureNode(material: material, rotateAngle: 180)
        child2.addChildNode(pictureNode2)
    
        return nodeInWall
    }
    
    class func resize(node: SCNNode, newWidth: CGFloat, newHeight: CGFloat) {
        resizeChildWithName(node: node, name: PictureNode.firstPictureNodeName, width: newWidth, height: newHeight)
        resizeChildWithName(node: node, name: PictureNode.secondPictureNodeName, width: newWidth, height: newHeight)
    }
    
    private class func resizeChildWithName(node: SCNNode, name: String, width: CGFloat, height: CGFloat) {
        let node = node.childNode(withName: name, recursively: true)!
        node.scale = SCNVector3(CGFloat(originalScale.x) * width, CGFloat(originalScale.y) * height, CGFloat(originalScale.z))
//        let plane = node.geometry as! SCNPlane
//        plane.width = width
//        plane.height = height
    }
    
    private class func createNode(material: SCNMaterial) -> SCNNode {
        let node = SCNNode()
//        node.geometry?.materials = [material]
        return node
    }
    
    private class func createPictureNode(material: SCNMaterial, rotateAngle: Float) -> SCNNode {
        let scene = SCNScene(named: "frame.scn")!
        scene.rootNode.worldPosition = SCNVector3(0, 0, -0.001)
        scene.rootNode.eulerAngles = SCNVector3(0, CGFloat(Int(rotateAngle)) * .pi / 180, 0)
        scene.rootNode.scale = SCNVector3(0.01, 0.01, 0.01)
        let canvas = scene.rootNode.childNode(withName: "canvas", recursively: true)!
        let geometry = canvas.geometry!
        geometry.replaceMaterial(at: 0, with: material)
        return scene.rootNode
    }
}

