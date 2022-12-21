//
// GLTFSampler.swift
//
// Sampler
// Texture sampler properties for filtering and wrapping modes.
//

import Foundation

struct GLTFSampler: GLTFPropertyProtocol {

  /** Magnification filter.  Valid values correspond to WebGL enums: `9728` (NEAREST) and `9729` (LINEAR). */
  let magFilter: Int?

  /** Minification filter.  All valid values correspond to WebGL enums. */
  let minFilter: Int?

  let _wrapS: Int?
  /** s wrapping mode.  All valid values correspond to WebGL enums. */
  var wrapS: Int {
    get { return self._wrapS ?? 10497 }
  }

  let _wrapT: Int?
  /** t wrapping mode.  All valid values correspond to WebGL enums. */
  var wrapT: Int {
    get { return self._wrapT ?? 10497 }
  }

  /** The user-defined name of this object.  This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name. */
  let name: String?

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case magFilter
    case minFilter
    case _wrapS = "wrapS"
    case _wrapT = "wrapT"
    case name
    case extensions
    case extras
  }
}

