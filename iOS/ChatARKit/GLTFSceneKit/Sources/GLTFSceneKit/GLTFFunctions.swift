//
//  GLTFFunctions.swift
//  GLTFSceneKit
//  Utility functions for internal use
//
//  Created by magicien on 2017/08/20.
//  Copyright © 2017 DarkHorse. All rights reserved.
//

import SceneKit
import SpriteKit
import CoreGraphics

func add(_ v0: SCNVector3, _ v1: SCNVector3) -> SCNVector3 {
    return SCNVector3(v0.x + v1.x, v0.y + v1.y, v0.z + v1.z)
}

func sub(_ v0: SCNVector3, _ v1: SCNVector3) -> SCNVector3 {
    return SCNVector3(v0.x - v1.x, v0.y - v1.y, v0.z - v1.z)
}

func mul(_ v: SCNVector3, _ n: SCNFloat) -> SCNVector3 {
    return SCNVector3(v.x * n, v.y * n, v.z * n)
}

func div(_ v: SCNVector3, _ n: SCNFloat) -> SCNVector3 {
    return mul(v, 1.0 / n)
}

func cross(_ v0: SCNVector3, _ v1: SCNVector3) -> SCNVector3 {
    return SCNVector3(v0.y * v1.z - v0.z * v1.y, v0.z * v1.x - v0.x * v1.z, v0.x * v1.y - v0.y * v1.x)
}

func length(_ v: SCNVector3) -> SCNFloat {
    let l2 = v.x * v.x + v.y * v.y + v.z * v.z
    #if os(macOS)
        // CGFloat = Double
        return sqrt(l2)
    #else
        // CGFloat = Float
        return SCNFloat(sqrtf(l2))
    #endif    
}

func normalize(_ v: SCNVector3) -> SCNVector3 {
    return mul(v, 1.0 / length(v))
}

func createNormal(_ v0: SCNVector3, _ v1: SCNVector3, _ v2: SCNVector3) -> SCNVector3 {
    let e1 = sub(v1, v0)
    let e2 = sub(v2, v0)
    let n = cross(e1, e2)
    
    return normalize(n)
}

func createVertexArray(from source: SCNGeometrySource) throws -> [SCNVector3] {
    if source.componentsPerVector != 3 {
        throw GLTFUnarchiveError.NotSupported("createVertexArray: only 3 component vector is supported: \(source.componentsPerVector)")
    }
    if !source.usesFloatComponents || source.bytesPerComponent != 4 {
        throw GLTFUnarchiveError.NotSupported("createVertexArray: only float source is supported")
    }
    
    let dummy = SCNVector3()
    var vertices = [SCNVector3](repeating: dummy, count: source.vectorCount)
    
    source.data.withUnsafeBytes { (p: UnsafePointer<Float32>) in
        var index = source.dataOffset / 4
        let step = source.dataStride / 4
        for i in 0..<source.vectorCount {
            let v0 = p[index + 0]
            let v1 = p[index + 1]
            let v2 = p[index + 2]
            index += step
            vertices[i] = SCNVector3(v0, v1, v2)
        }
    }
    return vertices
}

func createIndexArray(from element: SCNGeometryElement) -> [Int] {
    //var indices = [Int](repeating: 0, count: element.primitiveCount)
    let indexCount = element.primitiveCount * 3  // FIXME: check primitiveType
    var indices = [Int]()
    indices.reserveCapacity(indexCount)
    if element.bytesPerIndex == 2 {
        element.data.withUnsafeBytes { (p: UnsafePointer<UInt16>) in
            //var index = 0
            //let step = 2
            for i in 0..<indexCount {
                //indices[i] = Int(p[index])
                //index += step
                indices.append(Int(p[i]))
            }
        }
    } else if element.bytesPerIndex == 4 {
        element.data.withUnsafeBytes { (p: UnsafePointer<UInt32>) in
            //var index = 0
            //let step = 4
            for i in 0..<indexCount {
                //indices[i] = Int(p[index])
                //index += step
                indices.append(Int(p[i]))
            }
        }
    } else if element.bytesPerIndex == 8 {
        element.data.withUnsafeBytes { (p: UnsafePointer<UInt64>) in
            //var index = 0
            //let step = 8
            for i in 0..<indexCount {
                //indices[i] = Int(p[index])
                //index += step
                indices.append(Int(p[i]))
            }
        }
    }
    
    return indices
}

func createKeyTimeArray(from data: Data, offset: Int, stride: Int, count: Int) -> ([NSNumber], CFTimeInterval) {
    assert(stride == 4) // TODO: implement for other strides
    guard count > 0 else { return ([], 0) }
    
    //var floatArray = [Float32]()
    //floatArray.reserveCapacity(count)
    var floatArray = [Float32](repeating: 0.0, count: count)
    floatArray.withUnsafeMutableBufferPointer {
        data.copyBytes(to: $0, from: data.startIndex + offset..<data.startIndex + offset + count * 4)
    }
    let duration = Float(floatArray.last!)
    print("duration: \(duration)")
    for val in floatArray {
        print("dur val: \(val)")
    }
    
    let numberArray: [NSNumber] = floatArray.map { NSNumber(value: $0 / duration) }
    return (numberArray, CFTimeInterval(duration))
}

/*
func createValueArray<T>(from data: Data, stride: Int, count: Int, type: T.Type) -> [T] {
    var arr = [T]()
    arr.reserveCapacity(count)
    return arr
}
 */

func createColor(_ color: [Float]) -> SKColor {
    let c: [CGFloat] = color.map { CGFloat($0) }
    assert(c.count >= 4)
    return SKColor.init(red: c[0], green: c[1], blue: c[2], alpha: c[3])
}

func createGrayColor(white: Float) -> SKColor {
    return SKColor(white: CGFloat(white), alpha: 1.0)
}

func createVector3(_ vector: [Float]) -> SCNVector3 {
    let v: [SCNFloat] = vector.map { SCNFloat($0) }
    assert(v.count >= 3)
    return SCNVector3(x: v[0], y: v[1], z: v[2])
}

func createVector4(_ vector: [Float]) -> SCNVector4 {
    let v: [SCNFloat] = vector.map { SCNFloat($0) }
    assert(v.count >= 4)
    return SCNVector4(x: v[0], y: v[1], z: v[2], w: v[3])
}

func createVector4ForOrientation(_ vector: [Float]) -> SCNVector4 {
    let v: [SCNFloat] = vector.map { SCNFloat($0) }
    assert(v.count >= 4)
    return SCNVector4(x: v[0], y: v[1], z: v[2], w: -v[3])
}

func createMatrix4(_ matrix: [Float]) -> SCNMatrix4 {
    let m: [SCNFloat] = matrix.map { SCNFloat($0) }
    assert(m.count >= 16)
    return SCNMatrix4(
        m11: m[0], m12: m[1], m13: m[2], m14: m[3],
        m21: m[4], m22: m[5], m23: m[6], m24: m[7],
        m31: m[8], m32: m[9], m33: m[10], m34: m[11],
        m41: m[12], m42: m[13], m43: m[14], m44: m[15])
}

func loadImageFile(from url: URL) throws -> Image? {
    let data = try Data.init(contentsOf: url)
    return try loadImageData(from: data)
}

//func loadImageData(from data: Data) throws -> CGImage? {
func loadImageData(from data: Data) throws -> Image? {
    #if SEEMS_TO_HAVE_PNG_LOADING_BUG
        let magic: UInt64 = data.subdata(in: 0..<8).withUnsafeBytes { $0.pointee }
        if magic == 0x0A1A0A0D474E5089 {
            // PNG file
            let cgDataProvider = CGDataProvider(data: data as CFData)
            guard let cgImage = CGImage(pngDataProviderSource: cgDataProvider!, decode: nil, shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent) else {
                print("loadImage error: cannot create CGImage")
                return nil
            }
            #if os(macOS)
                let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                return NSImage(cgImage: cgImage, size: imageSize)
            #else
                // FIXME: this workaround doesn't work for iOS...
                return UIImage(cgImage: cgImage)
            #endif
        }
    #endif
    return Image(data: data)
}

/*
func getStride(of accessor: GLTFAccessor) -> Int {
    let bytesPerComponent = bytesPerComponentMap[accessor.componentType]
    let componentsPerVector = componentsPerVectorMap[accessor.type]
    return bytesPerComponent * componentsPerVector
}
*/

#if os(macOS)
    func getMetallicRoughnessTexture(from image: NSImage) throws -> (NSImage, NSImage) {
        var rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
            throw GLTFUnarchiveError.Unknown("getMetallicRoughnessTexture: failed to create CGImage")
        }
        let (metalCGImage, roughCGImage) = try getMetallicRoughnessTexture(from: cgImage)
        let metalImage = NSImage(cgImage: metalCGImage, size: rect.size)
        let roughImage = NSImage(cgImage: roughCGImage, size: rect.size)
        return (metalImage, roughImage)
    }
#else
    func getMetallicRoughnessTexture(from image: UIImage) throws -> (UIImage, UIImage) {
        guard let cgImage = image.cgImage else {
            throw GLTFUnarchiveError.Unknown("getMetallicRoughnessTexture: failed to create CGImage")
        }
        let (metalCGImage, roughCGImage) = try getMetallicRoughnessTexture(from: cgImage)
        let metalImage = UIImage(cgImage: metalCGImage)
        let roughImage = UIImage(cgImage: roughCGImage)
        return (metalImage, roughImage)
    }
#endif

func getMetallicRoughnessTexture(from image: CGImage) throws -> (CGImage, CGImage) {
    let w = image.width
    let h = image.height
    let rect = CGRect(x: 0, y: 0, width: w, height: h)
    let bitsPerComponent = 8
    let componentsPerPixel = 4 // RGBA
    let srcBytesPerPixel = bitsPerComponent * componentsPerPixel / 8
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let srcDataSize = w * h * srcBytesPerPixel
    let rawPtr: UnsafeMutableRawPointer = malloc(srcDataSize)
    defer { free(rawPtr) }
    
    let dstBytesPerPixel = bitsPerComponent / 8
    let dstDataSize = w * h * dstBytesPerPixel
    let metalRawPtr: UnsafeMutableRawPointer = malloc(dstDataSize)
    defer { free(metalRawPtr) }
    let roughRawPtr: UnsafeMutableRawPointer = malloc(dstDataSize)
    defer { free(roughRawPtr) }
    
    guard let context = CGContext(data: rawPtr, width: w, height: h, bitsPerComponent: bitsPerComponent, bytesPerRow: srcBytesPerPixel * w, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        throw GLTFUnarchiveError.Unknown("getMetallicRoughnessTexture: failed to make textures")
    }
    context.draw(image, in: rect)
    
    let ptr = rawPtr.bindMemory(to: UInt8.self, capacity: srcDataSize)
    let metalPtr = metalRawPtr.bindMemory(to: UInt8.self, capacity: dstDataSize)
    let roughPtr = roughRawPtr.bindMemory(to: UInt8.self, capacity: dstDataSize)
    var srcPos = 0
    var dstPos = 0
    for _ in 0..<h {
        for _ in 0..<w {
            metalPtr[dstPos] = ptr[srcPos + 2] // blue
            roughPtr[dstPos] = ptr[srcPos + 1] // green
            srcPos += srcBytesPerPixel
            dstPos += dstBytesPerPixel
        }
    }
    let dstColorSpace = CGColorSpaceCreateDeviceGray()
    
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
    guard let metalData = CFDataCreate(nil, metalPtr, dstDataSize) else {
        throw GLTFUnarchiveError.Unknown("getMetallicRoughnessTexture: failed to make metalData")
    }
    guard let metalProvider = CGDataProvider(data: metalData) else {
        throw GLTFUnarchiveError.Unknown("getMetallicRoughnessTexture: failed to make metalProvider")
    }
    guard let metalImage = CGImage(
        width: w, height: h,
        bitsPerComponent: bitsPerComponent,
        bitsPerPixel: bitsPerComponent,
        bytesPerRow: w * dstBytesPerPixel,
        space: dstColorSpace,
        bitmapInfo: bitmapInfo,
        provider: metalProvider,
        decode: nil,
        shouldInterpolate: false,
        intent: CGColorRenderingIntent.defaultIntent) else {
        throw GLTFUnarchiveError.Unknown("getMetallicRoughnessTexture: failed to make metalImage")
    }
    
    guard let roughData = CFDataCreate(nil, roughPtr, dstDataSize) else {
        throw GLTFUnarchiveError.Unknown("getMetallicRoughnessTexture: failed to make roughData")
    }
    guard let roughProvider = CGDataProvider(data: roughData) else {
        throw GLTFUnarchiveError.Unknown("getMetallicRoughnessTexture: failed to make roughProvider")
    }
    guard let roughImage = CGImage(
        width: w, height: h,
        bitsPerComponent: bitsPerComponent,
        bitsPerPixel: bitsPerComponent,
        bytesPerRow: w * dstBytesPerPixel,
        space: dstColorSpace,
        bitmapInfo: bitmapInfo,
        provider: roughProvider,
        decode: nil,
        shouldInterpolate: false,
        intent: CGColorRenderingIntent.defaultIntent) else {
        throw GLTFUnarchiveError.Unknown("getMetallicRoughnessTexture: failed to make roughImage")
    }
    
    return (metalImage, roughImage)
}
