//
//  GLTFTypes.swift
//  GLTFSceneKit
//
//  Created by magicien on 2017/08/18.
//  Copyright © 2017 DarkHorse. All rights reserved.
//

import SceneKit

let attributeMap: [String: SCNGeometrySource.Semantic] = [
    "POSITION": SCNGeometrySource.Semantic.vertex,
    "NORMAL": SCNGeometrySource.Semantic.normal,
    "TANGENT": SCNGeometrySource.Semantic.tangent,
    "TEXCOORD_0": SCNGeometrySource.Semantic.texcoord,
    "TEXCOORD_1": SCNGeometrySource.Semantic.texcoord,
    "TEXCOORD_2": SCNGeometrySource.Semantic.texcoord,
    "TEXCOORD_3": SCNGeometrySource.Semantic.texcoord,
    "COLOR_0": SCNGeometrySource.Semantic.color,
    "JOINTS_0": SCNGeometrySource.Semantic.boneIndices,
    "JOINTS_1": SCNGeometrySource.Semantic.boneIndices,
    "WEIGHTS_0": SCNGeometrySource.Semantic.boneWeights,
    "WEIGHTS_1": SCNGeometrySource.Semantic.boneWeights
]

let GLTF_BYTE = Int(GL_BYTE)
let GLTF_UNSIGNED_BYTE = Int(GL_UNSIGNED_BYTE)
let GLTF_SHORT = Int(GL_SHORT)
let GLTF_UNSIGNED_SHORT = Int(GL_UNSIGNED_SHORT)
let GLTF_UNSIGNED_INT = Int(GL_UNSIGNED_INT)
let GLTF_FLOAT = Int(GL_FLOAT)

let GLTF_ARRAY_BUFFER = Int(GL_ARRAY_BUFFER)
let GLTF_ELEMENT_ARRAY_BUFFER = Int(GL_ELEMENT_ARRAY_BUFFER)

let GLTF_POINTS = Int(GL_POINTS)
let GLTF_LINES = Int(GL_LINES)
let GLTF_LINE_LOOP = Int(GL_LINE_LOOP)
let GLTF_LINE_STRIP = Int(GL_LINE_STRIP)
let GLTF_TRIANGLES = Int(GL_TRIANGLES)
let GLTF_TRIANGLE_STRIP = Int(GL_TRIANGLE_STRIP)
let GLTF_TRIANGLE_FAN = Int(GL_TRIANGLE_FAN)

let GLTF_NEAREST = Int(GL_NEAREST)
let GLTF_LINEAR = Int(GL_LINEAR)
let GLTF_NEAREST_MIPMAP_NEAREST = Int(GL_NEAREST_MIPMAP_NEAREST)
let GLTF_LINEAR_MIPMAP_NEAREST = Int(GL_LINEAR_MIPMAP_NEAREST)
let GLTF_NEAREST_MIPMAP_LINEAR = Int(GL_NEAREST_MIPMAP_LINEAR)
let GLTF_LINEAR_MIPMAP_LINEAR = Int(GL_LINEAR_MIPMAP_LINEAR)

let GLTF_CLAMP_TO_EDGE = Int(GL_CLAMP_TO_EDGE)
let GLTF_MIRRORED_REPEAT = Int(GL_MIRRORED_REPEAT)
let GLTF_REPEAT = Int(GL_REPEAT)

let usesFloatComponentsMap: [Int: Bool] = [
    GLTF_BYTE: false,
    GLTF_UNSIGNED_BYTE: false,
    GLTF_SHORT: false,
    GLTF_UNSIGNED_SHORT: false,
    GLTF_UNSIGNED_INT: false,
    GLTF_FLOAT: true
]

let bytesPerComponentMap: [Int: Int] = [
    GLTF_BYTE: 1,
    GLTF_UNSIGNED_BYTE: 1,
    GLTF_SHORT: 2,
    GLTF_UNSIGNED_SHORT: 2,
    GLTF_UNSIGNED_INT: 4,
    GLTF_FLOAT: 4
]

let componentsPerVectorMap: [String: Int] = [
    "SCALAR": 1,
    "VEC2": 2,
    "VEC3": 3,
    "VEC4": 4,
    "MAT2": 4,
    "MAT3": 9,
    "MAT4": 16
]

// GLTF_LINE_LOOP, GLTF_LINE_STRIP, GLTF_TRIANGEL_FAN: need to convert
let primitiveTypeMap: [Int: SCNGeometryPrimitiveType] = [
    GLTF_POINTS: SCNGeometryPrimitiveType.point,
    GLTF_LINES: SCNGeometryPrimitiveType.line,
    GLTF_TRIANGLES: SCNGeometryPrimitiveType.triangles,
    GLTF_TRIANGLE_STRIP: SCNGeometryPrimitiveType.triangleStrip
]

let filterModeMap: [Int: SCNFilterMode] = [
    GLTF_NEAREST: SCNFilterMode.nearest,
    GLTF_LINEAR: SCNFilterMode.linear
]

let wrapModeMap: [Int: SCNWrapMode] = [
    GLTF_CLAMP_TO_EDGE: SCNWrapMode.clamp,
    GLTF_MIRRORED_REPEAT: SCNWrapMode.mirror,
    GLTF_REPEAT: SCNWrapMode.repeat
]

let keyPathMap: [String: String] = [
    "translation": "position",
    "rotation": "orientation",
    "scale": "scale"
]

#if os(macOS)
    typealias Image = NSImage
    typealias Color = NSColor
#elseif os(iOS) || os(tvOS) || os(watchOS)
    typealias Image = UIImage
    typealias Color = UIColor
#endif

public protocol GLTFCodable: Codable {
    func didLoad(by object: Any, unarchiver: GLTFUnarchiver)
}

protocol GLTFPropertyProtocol: GLTFCodable {
    /** Dictionary object with extension-specific objects. */
    var extensions: GLTFExtension? { get }
    
    /** Application-specific data. */
    var extras: GLTFExtras? { get }
}

extension GLTFPropertyProtocol {
    func didLoad(by object: Any, unarchiver: GLTFUnarchiver) {
        if let extensions = self.extensions?.extensions {
            for ext in extensions.values {
                if let codable = ext as? GLTFCodable {
                    codable.didLoad(by: object, unarchiver: unarchiver)
                }
            }
        }
    }
}


