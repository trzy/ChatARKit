//
//  simd_float4x4+Extensions.swift
//  ChatARKit
//
//  Created by Bart Trzynadlowski on 9/20/22.
//

import simd

extension simd_float4x4
{
    public var position: simd_float3 {
        return simd_float3(x: self.columns.3.x, y: self.columns.3.y, z: self.columns.3.z)
    }

    public var forward: simd_float3 {
        return simd_float3(x: self.columns.2.x, y: self.columns.2.y, z: self.columns.2.z)
    }

    public var up: simd_float3 {
        return simd_float3(x: self.columns.1.x, y: self.columns.1.y, z: self.columns.1.z)
    }

    public var right: simd_float3 {
        return simd_float3(x: self.columns.0.x, y: self.columns.0.y, z: self.columns.0.z)
    }

    public init(translation: simd_float3, rotation: simd_quatf, scale: simd_float3) {
        let rotationMatrix = simd_matrix4x4(rotation)
        let scaleMatrix = simd_float4x4(diagonal: simd_float4(scale, 1.0))
        let translationMatrix = simd_float4x4(
        [
            simd_float4(x: 1, y: 0, z: 0, w: 0),
            simd_float4(x: 0, y: 1, z: 0, w: 0),
            simd_float4(x: 0, y: 0, z: 1, w: 0),
            simd_float4(translation, 1)
        ])
        let trs = translationMatrix * rotationMatrix * scaleMatrix
        self.init(columns: trs.columns)
    }
}
