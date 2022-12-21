//
// GLTFMaterialPbrMetallicRoughness.swift
//
// Material PBR Metallic Roughness
// A set of parameter values that are used to define the metallic-roughness material model from Physically-Based Rendering (PBR) methodology.
//

import Foundation

struct GLTFMaterialPbrMetallicRoughness: GLTFPropertyProtocol {

  let _baseColorFactor: [Float]?
  /** The RGBA components of the base color of the material. The fourth component (A) is the alpha coverage of the material. The `alphaMode` property specifies how alpha is interpreted. These values are linear. If a baseColorTexture is specified, this value is multiplied with the texel values. */
  var baseColorFactor: [Float] {
    get { return self._baseColorFactor ?? [1,1,1,1] }
  }

  /** The base color texture. This texture contains RGB(A) components in sRGB color space. The first three components (RGB) specify the base color of the material. If the fourth component (A) is present, it represents the alpha coverage of the material. Otherwise, an alpha of 1.0 is assumed. The `alphaMode` property specifies how alpha is interpreted. The stored texels must not be premultiplied. */
  let baseColorTexture: GLTFTextureInfo?

  let _metallicFactor: Float?
  /** The metalness of the material. A value of 1.0 means the material is a metal. A value of 0.0 means the material is a dielectric. Values in between are for blending between metals and dielectrics such as dirty metallic surfaces. This value is linear. If a metallicRoughnessTexture is specified, this value is multiplied with the metallic texel values. */
  var metallicFactor: Float {
    get { return self._metallicFactor ?? 1 }
  }

  let _roughnessFactor: Float?
  /** The roughness of the material. A value of 1.0 means the material is completely rough. A value of 0.0 means the material is completely smooth. This value is linear. If a metallicRoughnessTexture is specified, this value is multiplied with the roughness texel values. */
  var roughnessFactor: Float {
    get { return self._roughnessFactor ?? 1 }
  }

  /** The metallic-roughness texture. The metalness values are sampled from the B channel. The roughness values are sampled from the G channel. These values are linear. If other channels are present (R or A), they are ignored for metallic-roughness calculations. */
  let metallicRoughnessTexture: GLTFTextureInfo?

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case _baseColorFactor = "baseColorFactor"
    case baseColorTexture
    case _metallicFactor = "metallicFactor"
    case _roughnessFactor = "roughnessFactor"
    case metallicRoughnessTexture
    case extensions
    case extras
  }
}

