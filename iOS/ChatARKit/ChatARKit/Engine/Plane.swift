//
//  Plane.swift
//  ChatARKit
//
//  Created by Bart Trzynadlowski on 12/12/22.
//
//  Represents a plane detected by ARKit. This code is mostly from Apple's
//  plane detection sample. Uncomment the lines that add meshNode and exentNode
//  as children in order to visualize the planes.
//

import ARKit
import JavaScriptCore

@objc public protocol PlaneJSExports: JSExport {
    var center: [Float] { get set }
    var size: [Float] { get set }
}

@objc public class Plane: SCNNode, PlaneJSExports {
    private static let planeColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
    
    public dynamic var center: [Float]
    public dynamic var size: [Float]

    public var centerPosition: Vector3 {
        get { return _centerPosition }
    }

    public let meshNode: SCNNode
    public let extentNode: SCNNode
    public var classificationNode: SCNNode?

    private var _centerPosition: Vector3
    
    /// - Tag: VisualizePlane
    init(anchor: ARPlaneAnchor, in sceneView: ARSCNView) {
        #if targetEnvironment(simulator)
        #error("ARKit is not supported in iOS Simulator. Connect a physical iOS device and select it as your Xcode run destination, or select Generic iOS Device as a build-only destination.")
        #else
        
        // JS exports
        let center = simd_float4(anchor.center, 1)
        let position = anchor.transform * center
        _centerPosition = Vector3(x: position.x, y: position.y, z: position.z)
        self.center = [ position.x, position.y, position.z ]
        self.size = [ anchor.extent.x, anchor.extent.y, anchor.extent.z ]

        // Create a mesh to visualize the estimated shape of the plane.
        guard let meshGeometry = ARSCNPlaneGeometry(device: sceneView.device!)
            else { fatalError("Can't create plane geometry") }
        meshGeometry.update(from: anchor.geometry)
        meshNode = SCNNode(geometry: meshGeometry)
        
        // Create a node to visualize the plane's bounding rectangle.
        let extentPlane: SCNPlane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        extentNode = SCNNode(geometry: extentPlane)
        extentNode.simdPosition = anchor.center
        
        // `SCNPlane` is vertically oriented in its local coordinate space, so
        // rotate it to match the orientation of `ARPlaneAnchor`.
        extentNode.eulerAngles.x = -.pi / 2

        super.init()

        self.setupMeshVisualStyle()
        self.setupExtentVisualStyle()

        // Add the plane extent and plane geometry as child nodes so they appear in the scene.
        //addChildNode(meshNode)
        //addChildNode(extentNode)
        
        // Display the plane's classification, if supported on the device
        if #available(iOS 12.0, *), ARPlaneAnchor.isClassificationSupported {
            let classification = anchor.classification.description
            let textNode = self.makeTextNode(classification)
            classificationNode = textNode
            // Change the pivot of the text node to its center
            textNode.centerAlign()
            // Add the classification node as a child node so that it displays the classification
            extentNode.addChildNode(textNode)
        }
        #endif
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func update(planeAnchor: ARPlaneAnchor) {
        let plane = self

        // Update ARSCNPlaneGeometry to the anchor's new estimated shape.
        if let planeGeometry = plane.meshNode.geometry as? ARSCNPlaneGeometry {
            planeGeometry.update(from: planeAnchor.geometry)
        }

        // Update extent visualization to the anchor's new bounding rectangle.
        if let extentGeometry = plane.extentNode.geometry as? SCNPlane {
            extentGeometry.width = CGFloat(planeAnchor.extent.x)
            extentGeometry.height = CGFloat(planeAnchor.extent.z)
            plane.extentNode.simdPosition = planeAnchor.center
        }
        
        // Update the plane's classification and the text position
        if #available(iOS 12.0, *),
            let classificationNode = plane.classificationNode,
            let classificationGeometry = classificationNode.geometry as? SCNText {
            let currentClassification = planeAnchor.classification.description
            if let oldClassification = classificationGeometry.string as? String, oldClassification != currentClassification {
                classificationGeometry.string = currentClassification
                classificationNode.centerAlign()
            }
        }
        
        // JS exports
        let center = simd_float4(planeAnchor.center, 1)
        let position = planeAnchor.transform * center
        _centerPosition = Vector3(x: position.x, y: position.y, z: position.z)
        self.center = [ position.x, position.y, position.z ]
        self.size = [ planeAnchor.extent.x, planeAnchor.extent.y, planeAnchor.extent.z ]
    }
    
    private func setupMeshVisualStyle() {
        // Make the plane visualization semitransparent to clearly show real-world placement.
        meshNode.opacity = 0.25
        
        // Use color and blend mode to make planes stand out.
        guard let material = meshNode.geometry?.firstMaterial
            else { fatalError("ARSCNPlaneGeometry always has one material") }
        material.diffuse.contents = Self.planeColor
    }
    
    private func setupExtentVisualStyle() {
        // Make the extent visualization semitransparent to clearly show real-world placement.
        extentNode.opacity = 0.6

        guard let material = extentNode.geometry?.firstMaterial
            else { fatalError("SCNPlane always has one material") }
        
        material.diffuse.contents = Self.planeColor

        // Use a SceneKit shader modifier to render only the borders of the plane.
        guard let path = Bundle.main.path(forResource: "wireframe_shader", ofType: "metal", inDirectory: "Assets.scnassets")
            else { fatalError("Can't find wireframe shader") }
        do {
            let shader = try String(contentsOfFile: path, encoding: .utf8)
            material.shaderModifiers = [.surface: shader]
        } catch {
            fatalError("Can't load wireframe shader: \(error)")
        }
    }
    
    private func makeTextNode(_ text: String) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 1)
        textGeometry.font = UIFont(name: "Futura", size: 75)

        let textNode = SCNNode(geometry: textGeometry)
        // scale down the size of the text
        textNode.simdScale = SIMD3<Float>(repeating: 0.0005)
        
        return textNode
    }
}
