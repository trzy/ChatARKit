//
// GLTFScene.swift
//
// Scene
// The root nodes of a scene.
//

import Foundation

struct GLTFScene: GLTFPropertyProtocol {

  /** The indices of each root node. */
  let nodes: [GLTFGlTFid]?

  /** The user-defined name of this object.  This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name. */
  let name: String?

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case nodes
    case name
    case extensions
    case extras
  }
}

