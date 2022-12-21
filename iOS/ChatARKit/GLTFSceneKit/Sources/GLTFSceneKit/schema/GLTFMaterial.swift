//
// GLTFMaterial.swift
//
// Material
// The material appearance of a primitive.
//

import Foundation

struct GLTFMaterial: GLTFPropertyProtocol {

  /** The user-defined name of this object.  This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name. */
  let name: String?

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  /** A set of parameter values that are used to define the metallic-roughness material model from Physically-Based Rendering (PBR) methodology. When not specified, all the default values of `pbrMetallicRoughness` apply. */
  let pbrMetallicRoughness: GLTFMaterialPbrMetallicRoughness?

  /** A tangent space normal map. The texture contains RGB components in linear space. Each texel represents the XYZ components of a normal vector in tangent space. Red [0 to 255] maps to X [-1 to 1]. Green [0 to 255] maps to Y [-1 to 1]. Blue [128 to 255] maps to Z [1/255 to 1]. The normal vectors use OpenGL conventions where +X is right and +Y is up. +Z points toward the viewer. In GLSL, this vector would be unpacked like so: `float3 normalVector = tex2D(<sampled normal map texture value>, texCoord) * 2 - 1`. */
  let normalTexture: GLTFMaterialNormalTextureInfo?

  /** The occlusion map texture. The occlusion values are sampled from the R channel. Higher values indicate areas that should receive full indirect lighting and lower values indicate no indirect lighting. These values are linear. If other channels are present (GBA), they are ignored for occlusion calculations. */
  let occlusionTexture: GLTFMaterialOcclusionTextureInfo?

  /** The emissive map controls the color and intensity of the light being emitted by the material. This texture contains RGB components in sRGB color space. If a fourth component (A) is present, it is ignored. */
  let emissiveTexture: GLTFTextureInfo?

  let _emissiveFactor: [Float]?
  /** The RGB components of the emissive color of the material. These values are linear. If an emissiveTexture is specified, this value is multiplied with the texel values. */
  var emissiveFactor: [Float] {
    get { return self._emissiveFactor ?? [0,0,0] }
  }

  let _alphaMode: String?
  /** The material's alpha rendering mode enumeration specifying the interpretation of the alpha value of the main factor and texture. */
  var alphaMode: String {
    get { return self._alphaMode ?? "OPAQUE" }
  }

  let _alphaCutoff: Float?
  /** Specifies the cutoff threshold when in `MASK` mode. If the alpha value is greater than or equal to this value then it is rendered as fully opaque, otherwise, it is rendered as fully transparent. A value greater than 1.0 will render the entire material as fully transparent. This value is ignored for other modes. */
  var alphaCutoff: Float {
    get { return self._alphaCutoff ?? 0.5 }
  }

  let _doubleSided: Bool?
  /** Specifies whether the material is double sided. When this value is false, back-face culling is enabled. When this value is true, back-face culling is disabled and double sided lighting is enabled. The back-face must have its normals reversed before the lighting equation is evaluated. */
  var doubleSided: Bool {
    get { return self._doubleSided ?? false }
  }

  private enum CodingKeys: String, CodingKey {
    case name
    case extensions
    case extras
    case pbrMetallicRoughness
    case normalTexture
    case occlusionTexture
    case emissiveTexture
    case _emissiveFactor = "emissiveFactor"
    case _alphaMode = "alphaMode"
    case _alphaCutoff = "alphaCutoff"
    case _doubleSided = "doubleSided"
  }
}

