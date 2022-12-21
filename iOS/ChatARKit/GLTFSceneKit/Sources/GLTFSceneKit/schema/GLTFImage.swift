//
// GLTFImage.swift
//
// Image
// Image data used to create a texture. Image can be referenced by URI or `bufferView` index. `mimeType` is required in the latter case.
//

import Foundation

struct GLTFImage: GLTFPropertyProtocol {

  /** The uri of the image.  Relative paths are relative to the .gltf file.  Instead of referencing an external file, the uri can also be a data-uri.  The image format must be jpg or png. */
  let uri: String?

  /** The image's MIME type. */
  let mimeType: String?

  /** The index of the bufferView that contains the image. Use this instead of the image's uri property. */
  let bufferView: GLTFGlTFid?

  /** The user-defined name of this object.  This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name. */
  let name: String?

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case uri
    case mimeType
    case bufferView
    case name
    case extensions
    case extras
  }
}

