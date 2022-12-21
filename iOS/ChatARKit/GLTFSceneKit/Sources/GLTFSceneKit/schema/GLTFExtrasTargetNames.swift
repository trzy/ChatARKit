//
// GLTFExtrasTargetNames.swift
//
// GLTFMesh.Extras.TargetNames
// An extra field to store morph target names
//

import Foundation

struct GLTFExtrasTargetNames : Codable {

  /** An array of morph target names */
  let targetNames: [String]?

  private enum CodingKeys: String, CodingKey {
    case targetNames
  }
}
