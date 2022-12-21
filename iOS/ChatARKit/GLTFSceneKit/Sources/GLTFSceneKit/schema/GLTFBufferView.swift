//
// GLTFBufferView.swift
//
// Buffer View
// A view into a buffer generally representing a subset of the buffer.
//

import Foundation

struct GLTFBufferView: GLTFPropertyProtocol {

  /** The index of the buffer. */
  let buffer: GLTFGlTFid

  let _byteOffset: Int?
  /** The offset into the buffer in bytes. */
  var byteOffset: Int {
    get { return self._byteOffset ?? 0 }
  }

  /** The length of the bufferView in bytes. */
  let byteLength: Int

  /** The stride, in bytes, between vertex attributes.  When this is not defined, data is tightly packed. When two or more accessors use the same bufferView, this field must be defined. */
  let byteStride: Int?

  /** The target that the GPU buffer should be bound to. */
  let target: Int?

  /** The user-defined name of this object.  This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name. */
  let name: String?

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case buffer
    case _byteOffset = "byteOffset"
    case byteLength
    case byteStride
    case target
    case name
    case extensions
    case extras
  }
}

