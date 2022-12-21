//
// GLTFVRM_VRMTypes.swift
//

import SceneKit

struct GLTFVRM_VRMSphereCollider{
  let offset: SIMD3<Float>
  let radius: Float
}

struct GLTFVRM_VRMSpringBoneColliderGroup {
  let node: SCNNode
  let colliders: [GLTFVRM_VRMSphereCollider]
}

struct GLTFVRM_VRMPhysicsSettings {
  let colliderGroups: [GLTFVRM_VRMSpringBoneColliderGroup]
  let springBones: [GLTFVRM_VRMSpringBone]
}

func getWorldScale(_ node: SCNNode) -> SCNVector3 {
  // Rotation is not considered
  if let parent = node.parent {
    let parentScale = getWorldScale(parent)
    return SCNVector3(parentScale.x * node.scale.x, parentScale.y * node.scale.y, parentScale.z * node.scale.z)
  }
  return node.scale
}
