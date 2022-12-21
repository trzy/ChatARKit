//
// GLTFGlTFChildOfRootProperty.swift
//
// glTF Child of Root Property
//

import Foundation

struct GLTFGlTFChildOfRootProperty: Codable {

  /** The user-defined name of this object.  This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name. */
  let name: String?

  private enum CodingKeys: String, CodingKey {
    case name
  }
}

