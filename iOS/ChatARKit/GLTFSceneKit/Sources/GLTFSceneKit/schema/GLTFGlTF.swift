//
// GLTFGlTF.swift
//
// glTF
// The root object for a glTF asset.
//

import Foundation

struct GLTFGlTF: GLTFPropertyProtocol {

  /** Names of glTF extensions used somewhere in this asset. */
  let extensionsUsed: [String]?

  /** Names of glTF extensions required to properly load this asset. */
  let extensionsRequired: [String]?

  /** An array of accessors.  An accessor is a typed view into a bufferView. */
  let accessors: [GLTFAccessor]?

  /** An array of keyframe animations. */
  let animations: [GLTFAnimation]?

  /** Metadata about the glTF asset. */
  let asset: GLTFAsset

  /** An array of buffers.  A buffer points to binary geometry, animation, or skins. */
  let buffers: [GLTFBuffer]?

  /** An array of bufferViews.  A bufferView is a view into a buffer generally representing a subset of the buffer. */
  let bufferViews: [GLTFBufferView]?

  /** An array of cameras.  A camera defines a projection matrix. */
  let cameras: [GLTFCamera]?

  /** An array of images.  An image defines data used to create a texture. */
  let images: [GLTFImage]?

  /** An array of materials.  A material defines the appearance of a primitive. */
  let materials: [GLTFMaterial]?

  /** An array of meshes.  A mesh is a set of primitives to be rendered. */
  let meshes: [GLTFMesh]?

  /** An array of nodes. */
  let nodes: [GLTFNode]?

  /** An array of samplers.  A sampler contains properties for texture filtering and wrapping modes. */
  let samplers: [GLTFSampler]?

  /** The index of the default scene. */
  let scene: GLTFGlTFid?

  /** An array of scenes. */
  let scenes: [GLTFScene]?

  /** An array of skins.  A skin is defined by joints and matrices. */
  let skins: [GLTFSkin]?

  /** An array of textures. */
  let textures: [GLTFTexture]?

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case extensionsUsed
    case extensionsRequired
    case accessors
    case animations
    case asset
    case buffers
    case bufferViews
    case cameras
    case images
    case materials
    case meshes
    case nodes
    case samplers
    case scene
    case scenes
    case skins
    case textures
    case extensions
    case extras
  }
}

