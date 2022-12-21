//
// GLTFMaterialOcclusionTextureInfo.swift
//
// Material Occlusion Texture Info
//

import Foundation

struct GLTFMaterialOcclusionTextureInfo: GLTFPropertyProtocol {

  /** The index of the texture. */
  let index: GLTFGlTFid

  let _texCoord: Int?
  /** This integer value is used to construct a string in the format TEXCOORD_<set index> which is a reference to a key in mesh.primitives.attributes (e.g. A value of 0 corresponds to TEXCOORD_0). */
  var texCoord: Int {
    get { return self._texCoord ?? 0 }
  }

  let _strength: Float?
  /** A scalar multiplier controlling the amount of occlusion applied. A value of 0.0 means no occlusion. A value of 1.0 means full occlusion. This value affects the resulting color using the formula: `occludedColor = lerp(color, color * <sampled occlusion texture value>, <occlusion strength>)`. This value is ignored if the corresponding texture is not specified. This value is linear. */
  var strength: Float {
    get { return self._strength ?? 1 }
  }

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case index
    case _texCoord = "texCoord"
    case _strength = "strength"
    case extensions
    case extras
  }
}

