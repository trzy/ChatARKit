//
//  Engine.swift
//  ChatARKit
//
//  Created by Bart Trzynadlowski on 12/11/22.
//
//  Handles the entire AR experience as well as the JavaScript environment.
//  All entities are managed here.
//

import ARKit
import JavaScriptCore

public class Engine: NSObject, ARSCNViewDelegate, ARSessionDelegate {
    private let _jsContext = JSContext()!
    private let _sceneView: ARSCNView
    private var _lastFrameTime: TimeInterval?
    private var _cameraTransform: simd_float4x4?
    private var _entities: [Entity] = []
    private var _jsEntities: [JSValue] = []
    private var _planes: [Plane] = []
    private var _manuallyPlacedEntities: [Entity] = []

    /// This should be called in a view controller's viewDidLoad()
    public init(sceneView: ARSCNView) {
        _sceneView = sceneView
        super.init()
        _sceneView.delegate = self
        _sceneView.showsStatistics = true
        setupJavaScriptEnvironment()

        // Create a cube entity
        //let cube = createEntity(type: "Cube")
        //_jsContext.setObject(cube, forKeyedSubscript: "cube" as NSString)
    }

    /// Start the engine, which starts ARKit
    public func start() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [ .horizontal ]
        _sceneView.session.delegate = self
        _sceneView.session.run(configuration)
    }

    public func pause() {
        _sceneView.session.pause()
    }

    /// Wraps the user prompt in more context about the system to help ChatGPT generate usable code.
    public func augmentPrompt(prompt: String) -> String {
        return """
Assume:
- A function createEntity() exists that takes only a string describing the object (for example, 'tree frog', 'cube', or 'rocket ship'). The return value is the object.
- Objects returned by createEntity() have only three properties, each of them an array of length 3: 'position' (the position), 'scale' (the scale), and 'euler' (rotation specified as Euler angles in degrees).
- Objects returned by createEntity() may be assigned a function to 'onUpdate' that takes the seconds elapsed since the last frame, 'deltaTime'. This function is executed each frame.
- Objects returned by createEntity() must have their properties initialized after the object is created.
- A function getPlanes() exists that returns an array of plane objects. The array may be empty.
- Each plane object has two properties: 'center', the center position of the plane, and 'size', the size of the plane in each dimension. Each of these is an array of numbers of length 3.
- A global variable 'cameraPosition' containing the camera position, which is the user position, as a 3-element float array.
- The function getNearestPlane() returns the closest plane to the user or null if no planes exist.
- The function getGroundPlane() returns the plane that corresponds to the floor or ground, or null if no planes exist.

Write Javascript code for the user that:

\(prompt)

The code must obey the following constraints:
- Is wrapped in an anonymous function that is then executed.
- Does not define any new functions.
- Defines all variables and constants used.
- Does not call any functions besides those given above and those defined by the base language spec.
"""
    }

    public func runCode(code: String) {
        _jsContext.evaluateScript(code)
    }

    /// Debug function that simply creates a Sketchfab object using the given query to find a model
    public func placeSketchfabEntity(query: String) {
        let entity = SketchfabEntity(name: query, scene: _sceneView.scene)
        var position = Vector3.zero
        if let cameraTransform = _cameraTransform {
            position = cameraTransform.position - 1 * cameraTransform.forward
            let raycast = ARRaycastQuery(origin: cameraTransform.position, direction: -cameraTransform.forward, allowing: .existingPlaneGeometry, alignment: .horizontal)
            let results = _sceneView.session.raycast(raycast)
            if results.count > 0 {
                position = results[0].worldTransform.position
            }
        }
        entity.node.simdWorldPosition = position
        _manuallyPlacedEntities.append(entity)
    }

    private func onUpdateFrame(deltaTime: TimeInterval, frame: ARFrame) {
        // Update global variables
        updateGlobalVariables(frame: frame)

        // Update entities using internal update method
        assert(_entities.count == _jsEntities.count)
        for i in 0..<_entities.count {
            _entities[i].onUpdateFrame(deltaTime: deltaTime, object: _jsEntities[i])
        }
    }

    // MARK: - JavaScript

    private func setupJavaScriptEnvironment() {
        // Define print() function for logging
        let printFn: @convention(block) (String) -> Void = { message in print(message) }
        _jsContext.setObject(printFn, forKeyedSubscript: "print" as NSString)

        // Define function to get planes
        let getPlanesFn: @convention(block) () -> [Plane] = { return self.getPlanes() }
        _jsContext.setObject(getPlanesFn, forKeyedSubscript: "getPlanes" as NSString)

        // Define function to get nearest plane to user
        let getNearestPlaneFn: @convention(block) () -> Plane? = { return self.getNearestPlane() }
        _jsContext.setObject(getNearestPlaneFn, forKeyedSubscript: "getNearestPlane" as NSString)

        // Define function to get ground plane
        let getGroundPlaneFn: @convention(block) () -> Plane? = { return self.getGroundPlane() }
        _jsContext.setObject(getGroundPlaneFn, forKeyedSubscript: "getGroundPlane" as NSString)

        // Define function to create entities
        let createEntityFn: @convention(block) (String) -> JSValue = { type in return self.createEntity(type: type) }
        _jsContext.setObject(createEntityFn, forKeyedSubscript: "createEntity" as NSString)

        // ChatGPT often insists on using a distance() function even when we tell it not to
        let distanceFn: @convention(block) ([NSNumber], [NSNumber]) -> Float = { return self.distance($0, $1) }
        _jsContext.setObject(distanceFn, forKeyedSubscript: "distance" as NSString)
    }

    private func updateGlobalVariables(frame: ARFrame) {
        _cameraTransform = frame.camera.transform
        let cameraPosition = frame.camera.transform.position
        _jsContext.setObject([ cameraPosition.x, cameraPosition.y, cameraPosition.z ], forKeyedSubscript: "cameraPosition" as NSString)
    }

    private func getPlanes() -> [Plane] {
        return _planes
    }

    private func getNearestPlane() -> Plane? {
        if let cameraPosition = _cameraTransform?.position {
            return _planes.sorted(by: { Vector3.distance($0.centerPosition, cameraPosition) < Vector3.distance($1.centerPosition, cameraPosition) }).first
        }
        return nil
    }

    private func getGroundPlane() -> Plane? {
        return _planes.sorted(by: { $0.centerPosition.y < $1.centerPosition.y }).first
    }

    private func createEntity(type: String) -> JSValue {
        print("[Engine] createEntity called: \(type)")
        let type = (type.count > 0 && type != "undefined") ? type.lowercased() : "cube"

        // Check to see if an existing entity exists (because follow-up prompts will often reproduce the
        // original code) and return that if so
        for i in 0..<_entities.count {
            if _entities[i].name == type {
                return _jsEntities[i]
            }
        }

        // Create a new one
        var entity: Entity?
        switch type {
        case "cube":
            entity = CubeEntity(name: type, scene: _sceneView.scene)
        default:
            entity = SketchfabEntity(name: type, scene: _sceneView.scene)
        }
        let value = JSValue(object: entity!, in: _jsContext)!
        _entities.append(entity!)
        _jsEntities.append(value)
        return value
    }

    private func distance(_ a: [NSNumber], _ b: [NSNumber]) -> Float {
        if a.count != 3 || b.count != 3 {
            return 0
        }
        let dx = a[0].floatValue - b[0].floatValue
        let dy = a[1].floatValue - b[1].floatValue
        let dz = a[2].floatValue - b[2].floatValue
        return sqrt(dx * dx + dy * dy + dz * dz)
    }

    // MARK: - ARSessionDelegate

    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let lastFrameTime = _lastFrameTime ?? frame.timestamp
        onUpdateFrame(deltaTime: frame.timestamp - lastFrameTime, frame: frame)
        _lastFrameTime = frame.timestamp
    }

    public func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }

    public func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }

    public func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }

    // MARK: - ARSCNViewDelegate

    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let plane = Plane(anchor: planeAnchor, in: _sceneView)
        node.addChildNode(plane)
        _planes.append(plane)
    }

    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Only update anchors and nodes set up by `renderer(_:didAdd:for:)`
        guard let planeAnchor = anchor as? ARPlaneAnchor, let plane = node.childNodes.first as? Plane else {
            return
        }
        plane.update(planeAnchor: planeAnchor)
    }

    public func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        _planes.removeAll { $0 == node }
    }
}
