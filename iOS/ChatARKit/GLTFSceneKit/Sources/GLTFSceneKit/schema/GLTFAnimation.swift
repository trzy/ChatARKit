//
// GLTFAnimation.swift
//
// Animation
// A keyframe animation.
//

import Foundation

struct GLTFAnimation: GLTFPropertyProtocol {

  /** An array of channels, each of which targets an animation's sampler at a node's property. Different channels of the same animation can't have equal targets. */
  let channels: [GLTFAnimationChannel]

  /** An array of samplers that combines input and output accessors with an interpolation algorithm to define a keyframe graph (but not its target). */
  let samplers: [GLTFAnimationSampler]

  /** The user-defined name of this object.  This is not necessarily unique, e.g., an accessor and a buffer could have the same name, or two accessors could even have the same name. */
  let name: String?

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case channels
    case samplers
    case name
    case extensions
    case extras
  }
}

