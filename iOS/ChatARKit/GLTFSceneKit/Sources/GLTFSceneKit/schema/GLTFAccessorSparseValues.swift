//
// GLTFAccessorSparseValues.swift
//
// Accessor Sparse Values
// Array of size `accessor.sparse.count` times number of components storing the displaced accessor attributes pointed by `accessor.sparse.indices`.
//

import Foundation

struct GLTFAccessorSparseValues: GLTFPropertyProtocol {

  /** The index of the bufferView with sparse values. Referenced bufferView can't have ARRAY_BUFFER or ELEMENT_ARRAY_BUFFER target. */
  let bufferView: GLTFGlTFid

  let _byteOffset: Int?
  /** The offset relative to the start of the bufferView in bytes. Must be aligned. */
  var byteOffset: Int {
    get { return self._byteOffset ?? 0 }
  }

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case bufferView
    case _byteOffset = "byteOffset"
    case extensions
    case extras
  }
}

