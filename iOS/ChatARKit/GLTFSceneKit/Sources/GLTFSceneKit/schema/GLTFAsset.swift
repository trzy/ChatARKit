//
// GLTFAsset.swift
//
// Asset
// Metadata about the glTF asset.
//

import Foundation

struct GLTFAsset: GLTFPropertyProtocol {

  /** A copyright message suitable for display to credit the content creator. */
  let copyright: String?

  /** Tool that generated this glTF model.  Useful for debugging. */
  let generator: String?

  /** The glTF version that this asset targets. */
  let version: String

  /** The minimum glTF version that this asset targets. */
  let minVersion: String?

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case copyright
    case generator
    case version
    case minVersion
    case extensions
    case extras
  }
}

