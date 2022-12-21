//
// GLTFAnimationChannel.swift
//
// Animation Channel
// Targets an animation's sampler at a node's property.
//

import Foundation

struct GLTFAnimationChannel: GLTFPropertyProtocol {

  /** The index of a sampler in this animation used to compute the value for the target, e.g., a node's translation, rotation, or scale (TRS). */
  let sampler: GLTFGlTFid

  /** The index of the node and TRS property to target. */
  let target: GLTFAnimationChannelTarget

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case sampler
    case target
    case extensions
    case extras
  }
}

