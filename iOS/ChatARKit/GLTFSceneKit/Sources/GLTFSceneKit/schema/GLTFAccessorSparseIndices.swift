//
// GLTFAccessorSparseIndices.swift
//
// Accessor Sparse Indices
// Indices of those attributes that deviate from their initialization value.
//

import Foundation

struct GLTFAccessorSparseIndices: GLTFPropertyProtocol {

  /** The index of the bufferView with sparse indices. Referenced bufferView can't have ARRAY_BUFFER or ELEMENT_ARRAY_BUFFER target. */
  let bufferView: GLTFGlTFid

  let _byteOffset: Int?
  /** The offset relative to the start of the bufferView in bytes. Must be aligned. */
  var byteOffset: Int {
    get { return self._byteOffset ?? 0 }
  }

  /** The indices data type.  Valid values correspond to WebGL enums: `5121` (UNSIGNED_BYTE), `5123` (UNSIGNED_SHORT), `5125` (UNSIGNED_INT). */
  let componentType: Int

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case bufferView
    case _byteOffset = "byteOffset"
    case componentType
    case extensions
    case extras
  }
}

