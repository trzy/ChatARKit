//
// GLTFBuffer.swift
//
// Buffer
// A buffer points to binary geometry, animation, or skins.
//

import Foundation

struct GLTFBuffer: GLTFPropertyProtocol {

  /** The uri of the buffer.  Relative paths are relative to the .gltf file.  Instead of referencing an external file, the uri can also be a data-uri. */
  let uri: String?

  /** The length of the buffer in bytes. */
  let byteLength: Int

  /** The user-defined name of this object.  This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name. */
  let name: String?

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case uri
    case byteLength
    case name
    case extensions
    case extras
  }
}

