//
// GLTFAccessor.swift
//
// Accessor
// A typed view into a bufferView.  A bufferView contains raw binary data.  An accessor provides a typed view into a bufferView or a subset of a bufferView similar to how WebGL's `vertexAttribPointer()` defines an attribute in a buffer.
//

import Foundation

struct GLTFAccessor: GLTFPropertyProtocol {

  /** The index of the bufferView. When not defined, accessor must be initialized with zeros; `sparse` property or extensions could override zeros with actual values. */
  let bufferView: GLTFGlTFid?

  let _byteOffset: Int?
  /** The offset relative to the start of the bufferView in bytes.  This must be a multiple of the size of the component datatype. */
  var byteOffset: Int {
    get { return self._byteOffset ?? 0 }
  }

  /** The datatype of components in the attribute.  All valid values correspond to WebGL enums.  The corresponding typed arrays are `Int8Array`, `Uint8Array`, `Int16Array`, `Uint16Array`, `Uint32Array`, and `Float32Array`, respectively.  5125 (UNSIGNED_INT) is only allowed when the accessor contains indices, i.e., the accessor is only referenced by `primitive.indices`. */
  let componentType: Int

  let _normalized: Bool?
  /** Specifies whether integer data values should be normalized (`true`) to [0, 1] (for unsigned types) or [-1, 1] (for signed types), or converted directly (`false`) when they are accessed. This property is defined only for accessors that contain vertex attributes or animation output data. */
  var normalized: Bool {
    get { return self._normalized ?? false }
  }

  /** The number of attributes referenced by this accessor, not to be confused with the number of bytes or number of components. */
  let count: Int

  /** Specifies if the attribute is a scalar, vector, or matrix. */
  let type: String

  /** Maximum value of each component in this attribute.  Array elements must be treated as having the same data type as accessor's `componentType`. Both min and max arrays have the same length.  The length is determined by the value of the type property; it can be 1, 2, 3, 4, 9, or 16.

`normalized` property has no effect on array values: they always correspond to the actual values stored in the buffer. When accessor is sparse, this property must contain max values of accessor data with sparse substitution applied. */
  let max: [Float]?

  /** Minimum value of each component in this attribute.  Array elements must be treated as having the same data type as accessor's `componentType`. Both min and max arrays have the same length.  The length is determined by the value of the type property; it can be 1, 2, 3, 4, 9, or 16.

`normalized` property has no effect on array values: they always correspond to the actual values stored in the buffer. When accessor is sparse, this property must contain min values of accessor data with sparse substitution applied. */
  let min: [Float]?

  /** Sparse storage of attributes that deviate from their initialization value. */
  let sparse: GLTFAccessorSparse?

  /** The user-defined name of this object.  This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name. */
  let name: String?

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case bufferView
    case _byteOffset = "byteOffset"
    case componentType
    case _normalized = "normalized"
    case count
    case type
    case max
    case min
    case sparse
    case name
    case extensions
    case extras
  }
}

