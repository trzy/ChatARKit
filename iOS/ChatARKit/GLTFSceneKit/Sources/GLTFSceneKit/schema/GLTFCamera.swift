//
// GLTFCamera.swift
//
// Camera
// A camera's projection.  A node can reference a camera to apply a transform to place the camera in the scene.
//

import Foundation

struct GLTFCamera: GLTFPropertyProtocol {

  /** An orthographic camera containing properties to create an orthographic projection matrix. */
  let orthographic: GLTFCameraOrthographic?

  /** A perspective camera containing properties to create a perspective projection matrix. */
  let perspective: GLTFCameraPerspective?

  /** Specifies if the camera uses a perspective or orthographic projection.  Based on this, either the camera's `perspective` or `orthographic` property will be defined. */
  let type: String

  /** The user-defined name of this object.  This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name. */
  let name: String?

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case orthographic
    case perspective
    case type
    case name
    case extensions
    case extras
  }
}

