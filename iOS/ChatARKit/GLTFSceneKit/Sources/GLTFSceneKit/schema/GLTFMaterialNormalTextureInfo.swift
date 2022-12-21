//
// GLTFMaterialNormalTextureInfo.swift
//
// Material Normal Texture Info
//

import Foundation

struct GLTFMaterialNormalTextureInfo: GLTFPropertyProtocol {

  /** The index of the texture. */
  let index: GLTFGlTFid

  let _texCoord: Int?
  /** This integer value is used to construct a string in the format TEXCOORD_<set index> which is a reference to a key in mesh.primitives.attributes (e.g. A value of 0 corresponds to TEXCOORD_0). */
  var texCoord: Int {
    get { return self._texCoord ?? 0 }
  }

  let _scale: Float?
  /** The scalar multiplier applied to each normal vector of the texture. This value scales the normal vector using the formula: `scaledNormal =  normalize((normalize(<sampled normal texture value>) * 2.0 - 1.0) * vec3(<normal scale>, <normal scale>, 1.0))`. This value is ignored if normalTexture is not specified. This value is linear. */
  var scale: Float {
    get { return self._scale ?? 1 }
  }

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case index
    case _texCoord = "texCoord"
    case _scale = "scale"
    case extensions
    case extras
  }
}

