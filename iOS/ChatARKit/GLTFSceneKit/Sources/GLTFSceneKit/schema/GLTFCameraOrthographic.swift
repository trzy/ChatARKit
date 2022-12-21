//
// GLTFCameraOrthographic.swift
//
// Camera Orthographic
// An orthographic camera containing properties to create an orthographic projection matrix.
//

import Foundation

struct GLTFCameraOrthographic: GLTFPropertyProtocol {

  /** The floating-point horizontal magnification of the view. Must not be zero. */
  let xmag: Float

  /** The floating-point vertical magnification of the view. Must not be zero. */
  let ymag: Float

  /** The floating-point distance to the far clipping plane. `zfar` must be greater than `znear`. */
  let zfar: Float

  /** The floating-point distance to the near clipping plane. */
  let znear: Float

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case xmag
    case ymag
    case zfar
    case znear
    case extensions
    case extras
  }
}

