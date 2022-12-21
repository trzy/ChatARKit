//
// GLTFVRM_VRMSpringBoneLogic.swift
//

import SceneKit

class GLTFVRM_VRMSpringBoneLogic {
  let node: SCNNode
  private let length: Float
  private(set) var currentTail: SIMD3<Float>
  private var prevTail: SIMD3<Float>
  private let localRotation: simd_quatf
  private let boneAxis: SIMD3<Float>
  private var parentRotation: simd_quatf {
    self.node.parent?.presentation.simdWorldOrientation ?? simd_quatf(matrix_identity_float4x4)
  }

  var radius: Float = 0.5

  init(center: SCNNode?, node: SCNNode, localChildPosition: SIMD3<Float>) {
    self.node = node
    let worldChildPosition = node.simdConvertPosition(localChildPosition, to: nil)
    self.currentTail = center?.simdConvertPosition(worldChildPosition, from: nil) ?? worldChildPosition
    self.prevTail = self.currentTail
    self.localRotation = node.simdOrientation
    self.boneAxis = simd_normalize(localChildPosition)
    self.length = simd_length(localChildPosition) * Float(getWorldScale(node).x)
  }

  func update(center: SCNNode?, stiffnessForce: Float, dragForce: Float, external: SIMD3<Float>, colliders: [GLTFVRM_VRMSphereCollider]) {
    let currentTail: SIMD3<Float> = center?.simdConvertPosition(self.currentTail, to: nil) ?? self.currentTail
    let prevTail: SIMD3<Float> = center?.simdConvertPosition(self.prevTail, to: nil) ?? self.prevTail

    // Verlet integration
    let dx = (currentTail - prevTail) * max(1.0 - dragForce, 0)
    let dr = simd_act(simd_normalize(self.parentRotation * self.localRotation), self.boneAxis) * stiffnessForce
    var nextTail: SIMD3<Float> = currentTail + dx + dr + external

    nextTail = self.node.presentation.simdWorldPosition + simd_normalize(nextTail - self.node.presentation.simdWorldPosition) * self.length

    nextTail = self.collision(colliders, nextTail)

    self.prevTail = center?.simdConvertPosition(currentTail, from: nil) ?? currentTail
    self.currentTail = center?.simdConvertPosition(nextTail, from: nil) ?? nextTail

    self.node.simdOrientation = self.applyRotation(nextTail)
  }

  private func applyRotation(_ nextTail: SIMD3<Float>) -> simd_quatf {
    // Reset the rotation to simplify the calculation
    self.node.simdOrientation = self.localRotation
    let nextLocalPos = self.node.presentation.convertPosition(SCNVector3(nextTail), from: nil)
    let quat = simd_quatf(from: self.boneAxis, to: simd_normalize(simd_float3(nextLocalPos)))

    return simd_normalize(self.localRotation * quat)
  }

  private func collision(_ colliders: [GLTFVRM_VRMSphereCollider], _ nextTail: SIMD3<Float>) -> SIMD3<Float> {
    var nextTail = nextTail
    for collider in colliders {
      let r = self.radius + collider.radius
      if simd_length_squared(nextTail - collider.offset) <= (r * r) {
        let normal = simd_normalize(nextTail - collider.offset)
        let posFromCollider = collider.offset + normal * (self.radius + collider.radius)
        nextTail = self.node.presentation.simdWorldPosition + simd_normalize(posFromCollider - self.node.presentation.simdWorldPosition) * self.length
      }
    }
    return nextTail
  }
}
