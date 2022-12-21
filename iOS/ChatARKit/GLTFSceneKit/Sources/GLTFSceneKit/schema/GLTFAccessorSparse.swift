//
// GLTFAccessorSparse.swift
//
// Accessor Sparse
// Sparse storage of attributes that deviate from their initialization value.
//

import Foundation

struct GLTFAccessorSparse: GLTFPropertyProtocol {

  /** The number of attributes encoded in this sparse accessor. */
  let count: Int

  /** Index array of size `count` that points to those accessor attributes that deviate from their initialization value. Indices must strictly increase. */
  let indices: GLTFAccessorSparseIndices

  /** Array of size `count` times number of components, storing the displaced accessor attributes pointed by `indices`. Substituted values must have the same `componentType` and number of components as the base accessor. */
  let values: GLTFAccessorSparseValues

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case count
    case indices
    case values
    case extensions
    case extras
  }
}

