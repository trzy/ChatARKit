//
// GLTFAnimationSampler.swift
//
// Animation Sampler
// Combines input and output accessors with an interpolation algorithm to define a keyframe graph (but not its target).
//

import Foundation

struct GLTFAnimationSampler: GLTFPropertyProtocol {

  /** The index of an accessor containing keyframe input values, e.g., time. That accessor must have componentType `FLOAT`. The values represent time in seconds with `time[0] >= 0.0`, and strictly increasing values, i.e., `time[n + 1] > time[n]`. */
  let input: GLTFGlTFid

  let _interpolation: String?
  /** Interpolation algorithm. */
  var interpolation: String {
    get { return self._interpolation ?? "LINEAR" }
  }

  /** The index of an accessor containing keyframe output values. When targeting TRS target, the `accessor.componentType` of the output values must be `FLOAT`. When targeting morph weights, the `accessor.componentType` of the output values must be `FLOAT` or normalized integer where each output element stores values with a count equal to the number of morph targets. */
  let output: GLTFGlTFid

  /** Dictionary object with extension-specific objects. */
  let extensions: GLTFExtension?

  /** Application-specific data. */
  let extras: GLTFExtras?

  private enum CodingKeys: String, CodingKey {
    case input
    case _interpolation = "interpolation"
    case output
    case extensions
    case extras
  }
}

