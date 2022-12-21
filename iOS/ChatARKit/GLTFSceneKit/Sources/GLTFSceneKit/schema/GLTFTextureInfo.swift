//
// GLTFTextureInfo.swift
//
// Texture Info
// Reference to a texture.
//

import Foundation

struct GLTFTextureInfo: GLTFPropertyProtocol {

  /** The index of the texture. */
  let index: GLTFGlTFid

  let _texCoord: Int?
  /** This integer value is used to construct a string in the format TEXCOORD_<set index> which is a reference to a key in mesh.primitives.attributes (e.g. A value of 0 corresponds to TEXCOORD_0). */
  var texCoord: Int {
    get { return self._texCoord ?? 0 }
  }

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case index
    case _texCoord = "texCoord"
    case extensions
    case extras
  }
}

