//
//  SCNNode+Extensions.swift
//  ChatARKit
//
//  Created by Bart Trzynadlowski on 12/12/22.
//

import SceneKit

extension SCNNode {
    func centerAlign() {
        let (min, max) = boundingBox
        let extents = SIMD3<Float>(max) - SIMD3<Float>(min)
        simdPivot = float4x4(translation: ((extents / 2) + SIMD3<Float>(min)))
    }
}
