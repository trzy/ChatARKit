//
// GLTFMesh.swift
//
// Mesh
// A set of primitives to be rendered.  A node can contain one mesh.  A node's transform places the mesh in the scene.
//

import Foundation

struct GLTFMesh: GLTFPropertyProtocol {

  /** An array of primitives, each defining geometry to be rendered with a material. */
  let primitives: [GLTFMeshPrimitive]

  /** Array of weights to be applied to the Morph Targets. */
  let weights: [Float]?

  /** The user-defined name of this object.  This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name. */
  let name: String?

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case primitives
    case weights
    case name
    case extensions
    case extras
  }
}

