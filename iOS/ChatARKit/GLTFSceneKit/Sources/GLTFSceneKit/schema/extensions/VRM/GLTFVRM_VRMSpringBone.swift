//
// GLTFVRM_VRMSpringBone.swift
//

import SceneKit
import simd

public class GLTFVRM_VRMSpringBone {
  static let colliderNodeName = "GLTFVRM_Collider"

  public let comment: String?
  public let stiffnessForce: Float
  public let gravityPower: Float
  public let gravityDir: SIMD3<Float>
  public let dragForce: Float
  public let hitRadius: Float

  public let center: SCNNode?
  public let rootBones: [SCNNode]

  private var initialLocalRotationMap: [SCNNode: simd_quatf] = [:]
  private let colliderGroups: [GLTFVRM_VRMSpringBoneColliderGroup]
  private var verlet: [GLTFVRM_VRMSpringBoneLogic] = []
  private var colliderList: [GLTFVRM_VRMSphereCollider] = []

  init(center: SCNNode?,
       rootBones: [SCNNode],
       comment: String? = nil,
       stiffnessForce: Float = 1.0,
       gravityPower: Float = 0.0,
       gravityDir: SIMD3<Float> = .init(0, -1, 0),
       dragForce: Float = 0.4,
       hitRadius: Float = 0.02,
       colliderGroups: [GLTFVRM_VRMSpringBoneColliderGroup] = []) {
    self.center = center
    self.rootBones = rootBones
    self.comment = comment
    self.stiffnessForce = stiffnessForce
    self.gravityPower = gravityPower
    self.gravityDir = gravityDir
    self.dragForce = dragForce
    self.hitRadius = hitRadius
    self.colliderGroups = colliderGroups

    self.setup()
  }

  private func setup() {
    for (node, orientation) in self.initialLocalRotationMap {
      node.simdOrientation = orientation
    }

    self.initialLocalRotationMap = [:]
    self.verlet = []

    for bone in self.rootBones {
      bone.enumerateHierarchy { x, _ in
        self.initialLocalRotationMap[x] = x.simdOrientation
      }
      self.setupRecursive(self.center, bone)
    }
  }

  private func setupRecursive(_ center: SCNNode?, _ parent: SCNNode) {
    if parent.childNodes.isEmpty {
      let parentWorldPos = simd_float3(parent.worldPosition)
      let grandParentWorldPos = simd_float3(parent.parent!.worldPosition)
      let delta = parentWorldPos - grandParentWorldPos
      let childPosition = parentWorldPos + simd.normalize(delta) * 0.07
      let localChildPosV4 = parent.simdWorldTransform.inverse * simd_float4(childPosition, 1)
      let localChildPos = simd_float3(
        localChildPosV4.x / localChildPosV4.w,
        localChildPosV4.y / localChildPosV4.w,
        localChildPosV4.z / localChildPosV4.w
      )

      let logic = GLTFVRM_VRMSpringBoneLogic(center: center, node: parent, localChildPosition: localChildPos)
      self.verlet.append(logic)
    } else {
      let firstChild = parent.childNodes.first!
      let localPosition = firstChild.simdPosition
      let logic = GLTFVRM_VRMSpringBoneLogic(center: center, node: parent, localChildPosition: localPosition)
      self.verlet.append(logic)
    }

    for child in parent.childNodes {
      self.setupRecursive(center, child)
    }
  }

  func update(deltaTime: TimeInterval, colliders: [GLTFVRM_VRMSpringBoneColliderGroup]) {
    if self.verlet.isEmpty {
      if self.rootBones.isEmpty {
        return
      }
      self.setup()
    }

    self.colliderList = []
    for group in colliders {
      for collider in group.colliders {
        self.colliderList.append(GLTFVRM_VRMSphereCollider(
          offset: group.node.presentation.simdConvertPosition(collider.offset, to: nil),
          radius: collider.radius
        ))
      }
    }

    let stiffness = min(1, self.stiffnessForce * Float(deltaTime))
    let external = self.gravityDir * (self.gravityPower * Float(deltaTime))

    for verlet in self.verlet {
      verlet.radius = self.hitRadius
      verlet.update(
        center: self.center,
        stiffnessForce: stiffness,
        dragForce: self.dragForce,
        external: external,
        colliders: self.colliderList
      )
    }
  }

  func reset() {
    self.setup()
  }

  // MARK: - DEBUG

  func renderColliders(rootNode: SCNNode) {
    self.verlet.forEach {
      let color = $0.node.childNodes.isEmpty ? Color.green : Color.blue
      let worldPos = $0.currentTail
      let geometry = SCNSphere(radius: CGFloat($0.radius))
      geometry.firstMaterial?.diffuse.contents = color
      geometry.firstMaterial?.readsFromDepthBuffer = false
      geometry.firstMaterial?.writesToDepthBuffer = false
      geometry.firstMaterial?.fillMode = .lines
      geometry.firstMaterial?.lightingModel = .constant
      let node = SCNNode(geometry: geometry)
      node.name = GLTFVRM_VRMSpringBone.colliderNodeName
      node.simdPosition = worldPos
      node.renderingOrder = 1100

      rootNode.addChildNode(node)

      let line = self.createLine(from: $0.node.presentation.worldPosition, to: SCNVector3(worldPos))
      line.geometry?.firstMaterial?.diffuse.contents = color
      rootNode.addChildNode(line)
    }
  }

  func createLine(from p0: SCNVector3, to p1: SCNVector3) -> SCNNode {
    let indices: [Int32] = [0, 1]
    let source = SCNGeometrySource(vertices: [p0, p1])
    let element = SCNGeometryElement(indices: indices, primitiveType: .line)
    let geometry = SCNGeometry(sources: [source], elements: [element])
    geometry.firstMaterial?.diffuse.contents = Color.blue
    geometry.firstMaterial?.readsFromDepthBuffer = false
    geometry.firstMaterial?.writesToDepthBuffer = false
    geometry.firstMaterial?.fillMode = .lines
    geometry.firstMaterial?.lightingModel = .constant
    let node = SCNNode(geometry: geometry)
    node.name = GLTFVRM_VRMSpringBone.colliderNodeName
    node.renderingOrder = 1100

    return SCNNode(geometry: geometry)
  }
}
