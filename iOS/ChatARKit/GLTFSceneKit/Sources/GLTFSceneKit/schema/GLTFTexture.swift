//
// GLTFTexture.swift
//
// Texture
// A texture and its sampler.
//

import Foundation

struct GLTFTexture: GLTFPropertyProtocol {

  /** The index of the sampler used by this texture. When undefined, a sampler with repeat wrapping and auto filtering should be used. */
  let sampler: GLTFGlTFid?

  /** The index of the image used by this texture. */
  let source: GLTFGlTFid?

  /** The user-defined name of this object.  This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name. */
  let name: String?

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case sampler
    case source
    case name
    case extensions
    case extras
  }
}

