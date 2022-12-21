//
// GLTFCameraPerspective.swift
//
// Camera Perspective
// A perspective camera containing properties to create a perspective projection matrix.
//

import Foundation

struct GLTFCameraPerspective: GLTFPropertyProtocol {

  /** The floating-point aspect ratio of the field of view. When this is undefined, the aspect ratio of the canvas is used. */
  let aspectRatio: Float?

  /** The floating-point vertical field of view in radians. */
  let yfov: Float

  /** The floating-point distance to the far clipping plane. When defined, `zfar` must be greater than `znear`. If `zfar` is undefined, runtime must use infinite projection matrix. */
  let zfar: Float?

  /** The floating-point distance to the near clipping plane. */
  let znear: Float

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case aspectRatio
    case yfov
    case zfar
    case znear
    case extensions
    case extras
  }
}

