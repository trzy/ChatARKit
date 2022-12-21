//
//  GLTFUnarhiver.swift
//  GLTFSceneKit
//
//  Created by magicien on 2017/08/17.
//  Copyright © 2017 DarkHorse. All rights reserved.
//

import SceneKit
import SpriteKit
import QuartzCore
import CoreGraphics

let glbMagic = 0x46546C67 // "glTF"
let chunkTypeJSON = 0x4E4F534A // "JSON"
let chunkTypeBIN = 0x004E4942 // "BIN"

let bundle = Bundle.module_workaround

public class GLTFUnarchiver {
    private var directoryPath: URL? = nil
    private var json: GLTFGlTF! = nil
    private var bin: Data?
    
    internal var scene: SCNScene?
    internal var scenes: [SCNScene?] = []
    internal var cameras: [SCNCamera?] = []
    internal var nodes: [SCNNode?] = []
    internal var skins: [SCNSkinner?] = []
    internal var animationChannels: [[CAAnimation?]?] = []
    internal var animationSamplers: [[CAAnimation?]?] = []
    internal var meshes: [SCNNode?] = []
    internal var accessors: [Any?] = []
    internal var durations: [CFTimeInterval?] = []
    internal var bufferViews: [Data?] = []
    internal var buffers: [Data?] = []
    internal var materials: [SCNMaterial?] = []
    internal var textures: [SCNMaterialProperty?] = []
    internal var images: [Image?] = []
    internal var maxAnimationDuration: CFTimeInterval = 0.0
    
    #if !os(watchOS)
    private var workingAnimationGroup: CAAnimationGroup! = nil
    #endif
    
    convenience public init(path: String, extensions: [String:Codable.Type]? = nil) throws {
        var url: URL?
        if let mainPath = Bundle.main.path(forResource: path, ofType: "") {
            url = URL(fileURLWithPath: mainPath)
        } else {
            url = URL(fileURLWithPath: path)
        }
        guard let _url = url else {
            throw URLError(.fileDoesNotExist)
        }
        try self.init(url: _url, extensions: extensions)
    }
    
    convenience public init(url: URL, extensions: [String:Codable.Type]? = nil) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data, extensions: extensions)
        self.directoryPath = url.deletingLastPathComponent()
    }
    
    public init(data: Data, extensions: [String:Codable.Type]? = nil) throws {
        let decoder = JSONDecoder()
        var _extensions = extensionList
        extensions?.forEach { (ext) in _extensions[ext.key] = ext.value }
        
        decoder.userInfo[GLTFExtensionCodingUserInfoKey] = _extensions
        
        let _extras = [
            "TargetNames": GLTFExtrasTargetNames.self
        ]
        
        decoder.userInfo[GLTFExtrasCodingUserInfoKey] = _extras

        var jsonData = data
        
        let magic: UInt32 = data.subdata(in: 0..<4).withUnsafeBytes { $0.pointee }
        if magic == glbMagic {
            let version: UInt32 = data.subdata(in: 4..<8).withUnsafeBytes { $0.pointee }
            if version != 2 {
                throw GLTFUnarchiveError.NotSupported("version \(version) is not supported")
            }
            let length: UInt32 = data.subdata(in: 8..<12).withUnsafeBytes { $0.pointee }
            
            let chunk0Length: UInt32 = data.subdata(in: 12..<16).withUnsafeBytes { $0.pointee }
            let chunk0Type: UInt32 = data.subdata(in: 16..<20).withUnsafeBytes { $0.pointee }
            if chunk0Type != chunkTypeJSON {
                throw GLTFUnarchiveError.NotSupported("chunkType \(chunk0Type) is not supported")
            }
            let chunk0EndPos = 20 + Int(chunk0Length)
            jsonData = data.subdata(in: 20..<chunk0EndPos)
            
            if length > chunk0EndPos {
                let chunk1Length: UInt32 = data.subdata(in: chunk0EndPos..<chunk0EndPos+4).withUnsafeBytes { $0.pointee }
                let chunk1Type: UInt32 = data.subdata(in: chunk0EndPos+4..<chunk0EndPos+8).withUnsafeBytes { $0.pointee }
                if chunk1Type != chunkTypeBIN {
                    throw GLTFUnarchiveError.NotSupported("chunkType \(chunk1Type) is not supported")
                }
                let chunk1EndPos = chunk0EndPos + 8 + Int(chunk1Length)
                self.bin = data.subdata(in: chunk0EndPos+8..<chunk1EndPos)
            }
        }
        
        // just throw the error to the user
        self.json = try decoder.decode(GLTFGlTF.self, from: jsonData)

        // Errors can be:
        // DecodingError.keyNotFound(let key, let context)
        // DecodingError.typeMismatch(let type, let context)
        // DecodingError.valueNotFound(let type, let context)

        self.initArrays()
    }
    
    private func initArrays() {
        if let scenes = self.json.scenes {
            self.scenes = [SCNScene?](repeating: nil, count: scenes.count)
        }
        
        if let cameras = self.json.cameras {
            self.cameras = [SCNCamera?](repeating: nil, count: cameras.count)
        }
        
        if let nodes = self.json.nodes {
            self.nodes = [SCNNode?](repeating: nil, count: nodes.count)
        }
        
        if let skins = self.json.skins {
            self.skins = [SCNSkinner?](repeating: nil, count: skins.count)
        }
        
        if let animations = self.json.animations {
            //if #available(OSX 10.13, *) {
            // self.animationChannels = [[SCNAnimation?]?](repeating: nil, count: animations.count)
            self.animationChannels = [[CAAnimation?]?](repeating: nil, count: animations.count)
            self.animationSamplers = [[CAAnimation?]?](repeating: nil, count: animations.count)
            //} else {
            //    print("GLTFAnimation is not supported for this OS version.")
            //}
        }
        
        if let meshes = self.json.meshes {
            self.meshes = [SCNNode?](repeating: nil, count: meshes.count)
        }
        
        if let accessors = self.json.accessors {
            self.accessors = [Any?](repeating: nil, count: accessors.count)
            self.durations = [CFTimeInterval?](repeating: nil, count: accessors.count)
        }
        
        if let bufferViews = self.json.bufferViews {
            self.bufferViews = [Data?](repeating: nil, count: bufferViews.count)
        }
        
        if let buffers = self.json.buffers {
            self.buffers = [Data?](repeating: nil, count: buffers.count)
        }
        
        if let materials = self.json.materials {
            self.materials = [SCNMaterial?](repeating: nil, count: materials.count)
        }
        
        if let textures = self.json.textures {
            self.textures = [SCNMaterialProperty?](repeating: nil, count: textures.count)
        }
        
        if let images = self.json.images {
            self.images = [Image?](repeating: nil, count: images.count)
        }
    }
    
    private func getBase64Str(from str: String) -> String? {
        guard str.starts(with: "data:") else { return nil }
        
        let mark = ";base64,"
        guard str.contains(mark) else { return nil }
        guard let base64Str = str.components(separatedBy: mark).last else { return nil }
        
        return base64Str
    }
    
    private func calcPrimitiveCount(ofCount count: Int, primitiveType: SCNGeometryPrimitiveType) -> Int {
        switch primitiveType {
        case .line:
            return count / 2
        case .point:
            return count
        case .polygon:
            // Is it correct?
            return count - 2
        case .triangles:
            return count / 3
        case .triangleStrip:
            return count - 2
        }
    }
    
    private func loadCamera(index: Int) throws -> SCNCamera {
        guard index < self.cameras.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadCamera: out of index: \(index) < \(self.cameras.count)")
        }
        
        if let camera = self.cameras[index] {
            return camera
        }
        
        guard let cameras = self.json.cameras else {
            throw GLTFUnarchiveError.DataInconsistent("loadCamera: cameras is not defined")
        }
        
        let glCamera = cameras[index]
        let camera = SCNCamera()
        
        if let name = glCamera.name {
            camera.name = name
        }
        switch glCamera.type {
        case "perspective":
            camera.usesOrthographicProjection = false
            guard let perspective = glCamera.perspective else {
                throw GLTFUnarchiveError.DataInconsistent("loadCamera: perspective is not defined")
            }

            // SceneKit automatically calculates the viewing angle in the other direction to match
            // the aspect ratio of the view displaying the scene
            camera.fieldOfView = CGFloat(perspective.yfov * 180.0 / Float.pi)
            camera.zNear = Double(perspective.znear)
            camera.zFar = Double(perspective.zfar ?? Float.infinity)
            
            perspective.didLoad(by: camera, unarchiver: self)
            
        case "orthographic":
            camera.usesOrthographicProjection = true
            guard let orthographic = glCamera.orthographic else {
                throw GLTFUnarchiveError.DataInconsistent("loadCamera: orthographic is not defined")
            }
            // TODO: use xmag
            camera.orthographicScale = Double(orthographic.ymag)
            camera.zNear = Double(orthographic.znear)
            camera.zFar = Double(orthographic.zfar)
            
            orthographic.didLoad(by: camera, unarchiver: self)
            
        default:
            throw GLTFUnarchiveError.NotSupported("loadCamera: type \(glCamera.type) is not supported")
        }
        
        glCamera.didLoad(by: camera, unarchiver: self)
        return camera
    }
    
    private func loadBuffer(index: Int) throws -> Data {
        guard index < self.buffers.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadBuffer: out of index: \(index) < \(self.buffers.count)")
        }
        
        if let buffer = self.buffers[index] {
            return buffer
        }
        
        guard let buffers = self.json.buffers else {
            throw GLTFUnarchiveError.DataInconsistent("loadBufferView: buffers is not defined")
        }
        
        let glBuffer = buffers[index]
        
        var _buffer: Data?
        if let uri = glBuffer.uri {
            if let base64Str = self.getBase64Str(from: uri) {
                _buffer = Data(base64Encoded: base64Str)
            } else {
                let url = URL(fileURLWithPath: uri, relativeTo: self.directoryPath)
                _buffer = try Data(contentsOf: url)
            }
        } else {
            _buffer = self.bin
        }
        
        guard let buffer = _buffer else {
            throw GLTFUnarchiveError.Unknown("loadBufferView: buffer \(index) load error")
        }
        
        guard buffer.count >= glBuffer.byteLength else {
            throw GLTFUnarchiveError.DataInconsistent("loadBuffer: buffer.count < byteLength: \(buffer.count) < \(glBuffer.byteLength)")
        }
        
        self.buffers[index] = buffer
        
        glBuffer.didLoad(by: buffer, unarchiver: self)
        return buffer
    }
    
    private func loadBufferView(index: Int, expectedTarget: Int? = nil) throws -> Data {
        guard index < self.bufferViews.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadBufferView: out of index: \(index) < \(self.bufferViews.count)")
        }
        
        if let bufferView = self.bufferViews[index] {
            return bufferView
        }
        
        guard let bufferViews = self.json.bufferViews else {
            throw GLTFUnarchiveError.DataInconsistent("loadBufferView: bufferViews is not defined")
        }
        let glBufferView = bufferViews[index]
        
        if let expectedTarget = expectedTarget {
            if let target = glBufferView.target {
                guard expectedTarget == target else {
                    throw GLTFUnarchiveError.DataInconsistent("loadBufferView: index \(index): target inconsistent")
                }
            }
        }
        
        let buffer = try self.loadBuffer(index: glBufferView.buffer)
        let bufferView = buffer.subdata(in: glBufferView.byteOffset..<glBufferView.byteOffset + glBufferView.byteLength)
        
        self.bufferViews[index] = bufferView
        
        glBufferView.didLoad(by: bufferView, unarchiver: self)
        return bufferView
    }
    
    private func iterateBufferView(index: Int, offset: Int, stride: Int, count: Int, block: @escaping (UnsafeRawPointer) -> Void) throws {
        guard count > 0 else { return }
        
        let bufferView = try self.loadBufferView(index: index)
        let glBufferView = self.json.bufferViews![index]
        var byteStride = stride
        if let glByteStride = glBufferView.byteStride {
            byteStride = glByteStride
        }

        guard offset + byteStride * count <= glBufferView.byteLength else {
            throw GLTFUnarchiveError.DataInconsistent("iterateBufferView: offset (\(offset)) + byteStride (\(byteStride)) * count (\(count)) shoule be equal or less than byteLength (\(glBufferView.byteLength)))")
        }
        
        bufferView.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
            var p = pointer.advanced(by: offset)
            for _ in 0..<count {
                block(UnsafeRawPointer(p))
                p = p.advanced(by: byteStride)
            }
        }
    }
    
    private func getDataStride(ofBufferViewIndex index: Int) throws -> Int? {
        guard let bufferViews = self.json.bufferViews else {
            throw GLTFUnarchiveError.DataInconsistent("getDataStride: bufferViews is not defined")
        }
        guard index < bufferViews.count else {
            throw GLTFUnarchiveError.DataInconsistent("getDataStride: out of index: \(index) < \(bufferViews.count)")
        }
        
        // it could be nil because it is not required.
        guard let stride = bufferViews[index].byteStride else { return nil }
        
        return stride
    }
    
    private func createIndexData(_ data: Data, offset: Int, size: Int, stride: Int, count: Int) -> Data {
        let dataSize = size * count
        if stride == size {
            if offset == 0 {
                return data
            }
            return data.subdata(in: offset..<offset + dataSize)
        }
        
        var indexData = Data(capacity: dataSize)
        
        data.withUnsafeBytes { (s: UnsafePointer<UInt8>) in
            indexData.withUnsafeMutableBytes { (d: UnsafeMutablePointer<UInt8>) in
                let srcStep = stride - size
                var srcPos = offset
                var dstPos = 0
                for _ in 0..<count {
                    for _ in 0..<size {
                        d[dstPos] = s[srcPos]
                        srcPos += 1
                        dstPos += 1
                    }
                    srcPos += srcStep
                }
            }
        }
        return indexData
    }
    
    private func loadVertexAccessor(index: Int, semantic: SCNGeometrySource.Semantic) throws -> SCNGeometrySource {
        guard index < self.accessors.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadVertexAccessor: out of index: \(index) < \(self.accessors.count)")
        }
        
        if let accessor = self.accessors[index] as? SCNGeometrySource {
            return accessor
        }
        if self.accessors[index] != nil {
            throw GLTFUnarchiveError.DataInconsistent("loadVertexAccessor: the accessor \(index) is not SCNGeometrySource")
        }
        
        guard let accessors = self.json.accessors else {
            throw GLTFUnarchiveError.DataInconsistent("loadVertexAccessor: accessors is not defined")
        }
        let glAccessor = accessors[index]
        
        let vectorCount = glAccessor.count
        guard let usesFloatComponents = usesFloatComponentsMap[glAccessor.componentType] else {
            throw GLTFUnarchiveError.NotSupported("loadVertexAccessor: user defined accessor.componentType is not supported")
        }
        guard let componentsPerVector = componentsPerVectorMap[glAccessor.type] else {
            throw GLTFUnarchiveError.NotSupported("loadVertexAccessor: user defined accessor.type is not supported")
        }
        guard let bytesPerComponent = bytesPerComponentMap[glAccessor.componentType] else {
            throw GLTFUnarchiveError.NotSupported("loadVertexAccessor: user defined accessor.componentType is not supported")
        }
        let dataOffset = glAccessor.byteOffset
        
        var bufferView: Data
        var dataStride: Int = bytesPerComponent * componentsPerVector
        var padding = 0
        if let bufferViewIndex = glAccessor.bufferView {
            let bv = try self.loadBufferView(index: bufferViewIndex)
            bufferView = bv
            if let ds = try self.getDataStride(ofBufferViewIndex: bufferViewIndex) {
                guard ds >= dataStride else {
                    throw GLTFUnarchiveError.DataInconsistent("loadVertexAccessor: dataStride is too small: \(ds) < \(dataStride)")
                }
                padding = ds - dataStride
                dataStride = ds
            }
        } else {
            let dataSize = dataStride * vectorCount
            bufferView = Data(count: dataSize)
        }
        
        /*
        print("==================================================")
        print("semantic: \(semantic)")
        print("vectorCount: \(vectorCount)")
        print("usesFloatComponents: \(usesFloatComponents)")
        print("componentsPerVector: \(componentsPerVector)")
        print("bytesPerComponent: \(bytesPerComponent)")
        print("dataOffset: \(dataOffset)")
        print("dataStride: \(dataStride)")
        print("bufferView.count: \(bufferView.count)")
        print("padding: \(padding)")
        print("dataOffset + dataStride * vectorCount - padding: \(dataOffset + dataStride * vectorCount - padding)")
        print("==================================================")
        */

        #if SEEMS_TO_HAVE_VALIDATE_VERTEX_ATTRIBUTE_BUG
            // Metal validateVertexAttribute function seems to have a bug, so dateOffset must be 0.
            bufferView = bufferView.subdata(in: dataOffset..<dataOffset + dataStride * vectorCount - padding)

            let geometrySource = SCNGeometrySource(data: bufferView, semantic: semantic, vectorCount: vectorCount, usesFloatComponents: usesFloatComponents, componentsPerVector: componentsPerVector, bytesPerComponent: bytesPerComponent, dataOffset: 0, dataStride: dataStride)

        #else
        let geometrySource = SCNGeometrySource(data: bufferView, semantic: semantic, vectorCount: vectorCount, usesFloatComponents: usesFloatComponents, componentsPerVector: componentsPerVector, bytesPerComponent: bytesPerComponent, dataOffset: dataOffset, dataStride: dataStride)
        #endif
        
        self.accessors[index] = geometrySource
        
        glAccessor.didLoad(by: geometrySource, unarchiver: self)
        return geometrySource
    }
    
    private func createIndexAccessor(for source: SCNGeometrySource, primitiveMode: Int) throws -> SCNGeometryElement {
        assert(source.semantic == .vertex)
        guard let primitiveType = primitiveTypeMap[primitiveMode] else {
            throw GLTFUnarchiveError.NotSupported("createIndexAccessor: primitve mode \(primitiveMode) is not supported")
        }
        
        if source.vectorCount <= 0xFFFF {
            var indices = [UInt16](repeating: 0, count: source.vectorCount)
            for i in 0..<source.vectorCount {
                indices[i] = UInt16(i)
            }
            let geometryElement = SCNGeometryElement(indices: indices, primitiveType: primitiveType)
            return geometryElement
        }
        
        if source.vectorCount <= 0xFFFFFFFF {
            var indices = [UInt32](repeating: 0, count: source.vectorCount)
            for i in 0..<source.vectorCount {
                indices[i] = UInt32(i)
            }
            let geometryElement = SCNGeometryElement(indices: indices, primitiveType: primitiveType)
            return geometryElement
        }
        
        var indices = [UInt64](repeating: 0, count: source.vectorCount)
        for i in 0..<source.vectorCount {
            indices[i] = UInt64(i)
        }
        let geometryElement = SCNGeometryElement(indices: indices, primitiveType: primitiveType)
        
        return geometryElement
    }
    
    private func loadIndexAccessor(index: Int, primitiveMode: Int) throws -> SCNGeometryElement {
        guard index < self.accessors.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadIndexAccessor: out of index: \(index) < \(self.accessors.count)")
        }
        
        if let accessor = self.accessors[index] as? SCNGeometryElement {
            return accessor
        }
        //if (self.accessors[index] as? SCNGeometrySource) != nil {
        //    throw GLTFUnarchiveError.DataInconsistent("loadIndexAccessor: the accessor \(index) is defined as SCNGeometrySource")
        //}
        if self.accessors[index] != nil {
            throw GLTFUnarchiveError.DataInconsistent("loadIndexAccessor: the accessor \(index) is not SCNGeometryElement")
        }
        
        guard let accessors = self.json.accessors else {
            throw GLTFUnarchiveError.DataInconsistent("loadIndexAccessor: accessors is not defined")
        }
        let glAccessor = accessors[index]
        
        guard let primitiveType = primitiveTypeMap[primitiveMode] else {
            throw GLTFUnarchiveError.NotSupported("loadIndexAccessor: primitve mode \(primitiveMode) is not supported")
        }
        let primitiveCount = self.calcPrimitiveCount(ofCount: glAccessor.count, primitiveType: primitiveType)
        
        guard let usesFloatComponents = usesFloatComponentsMap[glAccessor.componentType] else {
            throw GLTFUnarchiveError.NotSupported("loadIndexAccessor: user defined accessor.componentType is not supported")
        }
        if usesFloatComponents {
            throw GLTFUnarchiveError.DataInconsistent("loadIndexAccessor: cannot use Float for index accessor")
        }
        
        guard let componentsPerVector = componentsPerVectorMap[glAccessor.type] else {
            throw GLTFUnarchiveError.NotSupported("loadIndexAccessor: user defined accessor.type is not supported")
        }
        if componentsPerVector != 1 {
            throw GLTFUnarchiveError.DataInconsistent("loadIndexAccessor: accessor type must be SCALAR")
        }
        
        guard let bytesPerComponent = bytesPerComponentMap[glAccessor.componentType] else {
            throw GLTFUnarchiveError.NotSupported("loadndexIAccessor: user defined accessor.componentType is not supported")
        }
        
        let dataOffset = glAccessor.byteOffset
        
        var bufferView: Data
        var dataStride: Int = bytesPerComponent
        if let bufferViewIndex = glAccessor.bufferView {
            let bv = try self.loadBufferView(index: bufferViewIndex)
            bufferView = bv
            if let ds = try self.getDataStride(ofBufferViewIndex: bufferViewIndex) {
                dataStride = ds
            }
        } else {
            let dataSize = dataStride * glAccessor.count
            bufferView = Data(count: dataSize)
        }
        let data = self.createIndexData(bufferView, offset: dataOffset, size: bytesPerComponent, stride: dataStride, count: glAccessor.count)
        
        let geometryElement = SCNGeometryElement(data: data, primitiveType: primitiveType, primitiveCount: primitiveCount, bytesPerIndex: bytesPerComponent)
        self.accessors[index] = geometryElement
        
        glAccessor.didLoad(by: geometryElement, unarchiver: self)
        return geometryElement
    }
    
    private func createNormalSource(for vertexSource: SCNGeometrySource, elements: [SCNGeometryElement]) throws -> SCNGeometrySource {
        let vertexArray = try createVertexArray(from: vertexSource)
        let dummyNormal = SCNVector3()
        var normals = [SCNVector3](repeating: dummyNormal, count: vertexArray.count)
        var counts = [Int](repeating: 0, count: vertexArray.count)
        
        for element in elements {
            if element.primitiveType != .triangles {
                throw GLTFUnarchiveError.NotSupported("createNormalSource: only triangles primitveType is supported: \(element.primitiveType)")
            }
            
            let indexArray = createIndexArray(from: element)
            
            var indexPos = 0
            for _ in 0..<indexArray.count/3 {
                let i0 = indexArray[indexPos]
                let i1 = indexArray[indexPos+1]
                let i2 = indexArray[indexPos+2]
                
                let v0 = vertexArray[i0]
                let v1 = vertexArray[i1]
                let v2 = vertexArray[i2]
                
                let n = createNormal(v0, v1, v2)
                
                normals[i0] = add(normals[i0], n)
                normals[i1] = add(normals[i1], n)
                normals[i2] = add(normals[i2], n)
                
                counts[i0] += 1
                counts[i1] += 1
                counts[i2] += 1
                
                indexPos += 3
            }
        }
        for i in 0..<normals.count {
            if counts[i] != 0 {
                normals[i] = normalize(div(normals[i], SCNFloat(counts[i])))
            }
        }
        
        let normalSource = SCNGeometrySource(normals: normals)
        return normalSource
    }
    
    private func loadKeyTimeAccessor(index: Int) throws -> ([NSNumber], CFTimeInterval) {
        guard index < self.accessors.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadKeyTimeAccessor: out of index: \(index) < \(self.accessors.count)")
        }
        
        if let accessor = self.accessors[index] as? [NSNumber] {
            return (accessor, self.durations[index]!)
        }
        if self.accessors[index] != nil {
            throw GLTFUnarchiveError.DataInconsistent("loadKeyTimeAccessor: the accessor \(index) is not [Float]")
        }
        
        guard let accessors = self.json.accessors else {
            throw GLTFUnarchiveError.DataInconsistent("loadKeyTimeAccessor: accessors is not defined")
        }
        let glAccessor = accessors[index]
        
        guard let usesFloatComponents = usesFloatComponentsMap[glAccessor.componentType] else {
            throw GLTFUnarchiveError.NotSupported("loadKeyTimeAccessor: user defined accessor.componentType is not supported")
        }
        if !usesFloatComponents {
            throw GLTFUnarchiveError.DataInconsistent("loadKeyTimeAccessor: not Float keyTime accessor")
        }
        
        guard let componentsPerVector = componentsPerVectorMap[glAccessor.type] else {
            throw GLTFUnarchiveError.NotSupported("loadKeyTimeAccessor: user defined accessor.type is not supported")
        }
        if componentsPerVector != 1 {
            throw GLTFUnarchiveError.DataInconsistent("loadKeyTimeAccessor: accessor type must be SCALAR")
        }
        
        guard let bytesPerComponent = bytesPerComponentMap[glAccessor.componentType] else {
            throw GLTFUnarchiveError.NotSupported("loadndexIAccessor: user defined accessor.componentType is not supported")
        }
        
        let dataOffset = glAccessor.byteOffset
        
        var bufferView: Data
        var dataStride: Int = bytesPerComponent
        if let bufferViewIndex = glAccessor.bufferView {
            let bv = try self.loadBufferView(index: bufferViewIndex)
            bufferView = bv
            if let ds = try self.getDataStride(ofBufferViewIndex: bufferViewIndex) {
                dataStride = ds
            }
        } else {
            let dataSize = dataStride * glAccessor.count
            bufferView = Data(count: dataSize)
        }
        
        let (keyTimeArray, duration) = createKeyTimeArray(from: bufferView, offset: dataOffset, stride: dataStride, count: glAccessor.count)
        
        self.accessors[index] = keyTimeArray
        self.durations[index] = duration
        
        return (keyTimeArray, duration)
    }
    
    private func loadValueAccessor(index: Int, flipW: Bool = false) throws -> [Any] {
        guard index < self.accessors.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadValueAccessor: out of index: \(index) < \(self.accessors.count)")
        }
        
        if let accessor = self.accessors[index] as? [Any] {
            return accessor
        }
        if self.accessors[index] != nil {
            throw GLTFUnarchiveError.DataInconsistent("loadValueAccessor: the accessor \(index) is not [Float]")
        }
        
        guard let accessors = self.json.accessors else {
            throw GLTFUnarchiveError.DataInconsistent("loadValueAccessor: accessors is not defined")
        }
        let glAccessor = accessors[index]
        
        guard let bufferViewIndex = glAccessor.bufferView else {
            throw GLTFUnarchiveError.DataInconsistent("loadValueAccessor: bufferView is not defined")
        }
        
        /*
        guard let usesFloatComponents = usesFloatComponentsMap[glAccessor.componentType] else {
            throw GLTFUnarchiveError.NotSupported("loadValueAccessor: user defined accessor.componentType is not supported")
        }
        if usesFloatComponents {
            throw GLTFUnarchiveError.DataInconsistent("loadValueAccessor: not Float keyTime accessor")
        }

        guard let componentsPerVector = componentsPerVectorMap[glAccessor.type] else {
            throw GLTFUnarchiveError.NotSupported("loadValueAccessor: user defined accessor.type is not supported")
        }
        if componentsPerVector != 1 {
            throw GLTFUnarchiveError.DataInconsistent("loadValueAccessor: accessor type must be SCALAR")
        }

        guard let bytesPerComponent = bytesPerComponentMap[glAccessor.componentType] else {
            throw GLTFUnarchiveError.NotSupported("loadValueAccessor: user defined accessor.componentType is not supported")
        }
        */

        let dataOffset = glAccessor.byteOffset
        let bytesPerComponent = bytesPerComponentMap[glAccessor.componentType]!
        let componentsPerVector = componentsPerVectorMap[glAccessor.type]!
        let dataStride = bytesPerComponent * componentsPerVector
        
        /*
        var bufferView: Data
        var dataStride: Int = bytesPerComponent
        if let bufferViewIndex = glAccessor.bufferView {
            let bv = try self.loadBufferView(index: bufferViewIndex)
            bufferView = bv
            if let ds = try self.getDataStride(ofBufferViewIndex: bufferViewIndex) {
                dataStride = ds
            }
        } else {
            let dataSize = dataStride * glAccessor.count
            bufferView = Data(count: dataSize)
        }
        */

        //let valueArray = self.createValueArray(of: glAccessor)
        if glAccessor.type == "SCALAR" {
            var valueArray = [NSNumber]()
            valueArray.reserveCapacity(glAccessor.count)
            try self.iterateBufferView(index: bufferViewIndex, offset: dataOffset, stride: dataStride, count: glAccessor.count) { (p) in
                // TODO: it could be BYTE, UNSIGNED_BYTE, ...
                let value = p.load(fromByteOffset: 0, as: Float32.self)
                //let value = p.bindMemory(to: Float32.self, capacity: 1).pointee
                //print("value: \(value)")
                valueArray.append(NSNumber(value: value))
            }
            
            self.accessors[index] = valueArray
            return valueArray
            
        }
        
        var valueArray = [NSValue]()
        valueArray.reserveCapacity(glAccessor.count)
        if glAccessor.type == "VEC3" {
            try self.iterateBufferView(index: bufferViewIndex, offset: dataOffset, stride: dataStride, count: glAccessor.count) { (p) in
                let x = p.load(fromByteOffset: 0, as: Float32.self)
                let y = p.load(fromByteOffset: 4, as: Float32.self)
                let z = p.load(fromByteOffset: 8, as: Float32.self)
                let v = SCNVector3(x, y, z)
                
                valueArray.append(NSValue(scnVector3: v))
            }
        }
        else if glAccessor.type == "VEC4" {
            try self.iterateBufferView(index: bufferViewIndex, offset: dataOffset, stride: dataStride, count: glAccessor.count) { (p) in
                let x = p.load(fromByteOffset: 0, as: Float32.self)
                let y = p.load(fromByteOffset: 4, as: Float32.self)
                let z = p.load(fromByteOffset: 8, as: Float32.self)
                let w = p.load(fromByteOffset: 12, as: Float32.self)
                let v = SCNVector4(x, y, z, flipW ? -w : w)
                
                valueArray.append(NSValue(scnVector4: v))
            }
        }
        return valueArray
    }
    
    private func loadImage(index: Int) throws -> Image {
        guard index < self.images.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadImage: out of index: \(index) < \(self.images.count)")
        }
        
        if let image = self.images[index] {
            return image
        }
        
        guard let images = self.json.images else {
            throw GLTFUnarchiveError.DataInconsistent("loadImage: images is not defined")
        }
        let glImage = images[index]
        
        var image: Image?
        if let uri = glImage.uri {
            if let base64Str = self.getBase64Str(from: uri) {
                guard let data = Data(base64Encoded: base64Str) else {
                    throw GLTFUnarchiveError.Unknown("loadImage: cannot convert the base64 string to Data")
                }
                image = try loadImageData(from: data)
            } else {
                let url = URL(fileURLWithPath: uri, relativeTo: self.directoryPath)
                image = try loadImageFile(from: url)
            }
        } else if let bufferViewIndex = glImage.bufferView {
            let bufferView = try self.loadBufferView(index: bufferViewIndex)
            image = try loadImageData(from: bufferView)
        }
        
        guard let _image = image else {
            throw GLTFUnarchiveError.Unknown("loadImage: image \(index) is not loaded")
        }
        
        self.images[index] = _image
        
        glImage.didLoad(by: _image, unarchiver: self)
        return _image
    }
    
    private func setSampler(index: Int, to property: SCNMaterialProperty) throws {
        guard let samplers = self.json.samplers else {
            throw GLTFUnarchiveError.DataInconsistent("setSampler: samplers is not defined")
        }
        if index >= samplers.count {
            throw GLTFUnarchiveError.DataInconsistent("setSampler: out of index: \(index) < \(samplers.count)")
        }
        
        let sampler = samplers[index]
        
        if let magFilter = sampler.magFilter {
            guard let filter = filterModeMap[magFilter] else {
                throw GLTFUnarchiveError.NotSupported("setSampler: magFilter \(magFilter) is not supported")
            }
            property.magnificationFilter = filter
        }
        
        if let minFilter = sampler.minFilter {
            switch minFilter {
            case GLTF_NEAREST:
                property.minificationFilter = .nearest
                property.mipFilter = .none
            case GLTF_LINEAR:
                property.minificationFilter = .linear
                property.mipFilter = .none
            case GLTF_NEAREST_MIPMAP_NEAREST:
                property.minificationFilter = .nearest
                property.mipFilter = .nearest
            case GLTF_LINEAR_MIPMAP_NEAREST:
                property.minificationFilter = .linear
                property.mipFilter = .nearest
            case GLTF_NEAREST_MIPMAP_LINEAR:
                property.minificationFilter = .nearest
                property.mipFilter = .linear
            case GLTF_LINEAR_MIPMAP_LINEAR:
                property.minificationFilter = .linear
                property.mipFilter = .linear
            default:
                throw GLTFUnarchiveError.NotSupported("setSampler: minFilter \(minFilter) is not supported")
            }
        }
        
        guard let wrapS = wrapModeMap[sampler.wrapS] else {
            throw GLTFUnarchiveError.NotSupported("setSampler: wrapS \(sampler.wrapS) is not supported")
        }
        property.wrapS = wrapS
        
        guard let wrapT = wrapModeMap[sampler.wrapT] else {
            throw GLTFUnarchiveError.NotSupported("setSampler: wrapT \(sampler.wrapT) is not supported")
        }
        property.wrapT = wrapT
    }
    
    private func loadTexture(index: Int) throws -> SCNMaterialProperty {
        guard index < self.textures.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadTexture: out of index: \(index) < \(self.textures.count)")
        }
        
        if let texture = self.textures[index] {
            return texture
        }
        
        guard let textures = self.json.textures else {
            throw GLTFUnarchiveError.DataInconsistent("loadTexture: textures is not defined")
        }
        let glTexture = textures[index]
        
        guard let sourceIndex = glTexture.source else {
            throw GLTFUnarchiveError.NotSupported("loadTexture: texture without source is not supported")
        }
        let image = try self.loadImage(index: sourceIndex)
        
        let texture = SCNMaterialProperty(contents: image)
        // enable Texture filtering sample so we get less aliasing when they are farther away
        texture.mipFilter = .linear
        
        // TODO: retain glTexture.name somewhere
        
        if let sampler = glTexture.sampler {
            try self.setSampler(index: sampler, to: texture)
        } else {
            // set default values
            texture.wrapS = .repeat
            texture.wrapT = .repeat
        }
        
        self.textures[index] = texture
        
        glTexture.didLoad(by: texture, unarchiver: self)
        return texture
    }
    
    func setTexture(index: Int, to property: SCNMaterialProperty) throws {
        let texture = try self.loadTexture(index: index)
        guard let contents = texture.contents else {
            throw GLTFUnarchiveError.DataInconsistent("setTexture: contents of texture \(index) is nil")
        }
        
        property.contents = contents
        property.minificationFilter = texture.minificationFilter
        property.magnificationFilter = texture.magnificationFilter
        property.mipFilter = texture.mipFilter
        property.wrapS = texture.wrapS
        property.wrapT = texture.wrapT
        property.intensity = texture.intensity
        property.maxAnisotropy = texture.maxAnisotropy
        property.contentsTransform = texture.contentsTransform
        property.mappingChannel = texture.mappingChannel
        if #available(OSX 10.13, *) {
            property.textureComponents = texture.textureComponents
        }
    }
    
    var defaultMaterial: SCNMaterial {
        get {
            let material = SCNMaterial()
            
            material.lightingModel = .physicallyBased
            material.diffuse.contents = createColor([1.0, 1.0, 1.0, 1.0])
            material.metalness.contents = createGrayColor(white: 1.0)
            material.roughness.contents = createGrayColor(white: 1.0)
            material.isDoubleSided = false
            
            return material
        }
    }
    
    private func loadMaterial(index: Int) throws -> SCNMaterial {
        guard index < self.materials.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadMaterial: out of index: \(index) < \(self.materials.count)")
        }
        
        if let material = self.materials[index] {
            return material
        }
        
        guard let materials = self.json.materials else {
            throw GLTFUnarchiveError.DataInconsistent("loadMaterials: materials it not defined")
        }
        let glMaterial = materials[index]
        let material = SCNMaterial()
        self.materials[index] = material
        
        material.name = glMaterial.name
        material.setValue(Float(1.0), forKey: "baseColorFactorR")
        material.setValue(Float(1.0), forKey: "baseColorFactorG")
        material.setValue(Float(1.0), forKey: "baseColorFactorB")
        material.setValue(Float(1.0), forKey: "baseColorFactorA")
        material.setValue(Float(1.0), forKey: "metallicFactor")
        material.setValue(Float(1.0), forKey: "roughnessFactor")
        material.setValue(glMaterial.emissiveFactor[0], forKey: "emissiveFactorR")
        material.setValue(glMaterial.emissiveFactor[1], forKey: "emissiveFactorG")
        material.setValue(glMaterial.emissiveFactor[2], forKey: "emissiveFactorB")
        material.setValue(glMaterial.alphaCutoff, forKey: "alphaCutoff")
        
        if let pbr = glMaterial.pbrMetallicRoughness {
            material.lightingModel = .physicallyBased
            material.diffuse.contents = createColor(pbr.baseColorFactor)
            material.metalness.contents = createGrayColor(white: pbr.metallicFactor)
            material.roughness.contents = createGrayColor(white: pbr.roughnessFactor)
            
            if let baseTexture = pbr.baseColorTexture {
                try self.setTexture(index: baseTexture.index, to: material.diffuse)
                material.diffuse.mappingChannel = baseTexture.texCoord
                
                //let baseColorFactor = createVector4(pbr.baseColorFactor)
                //material.setValue(NSValue(scnVector4: baseColorFactor), forKeyPath: "baseColorFactor")
                material.setValue(pbr.baseColorFactor[0], forKey: "baseColorFactorR")
                material.setValue(pbr.baseColorFactor[1], forKey: "baseColorFactorG")
                material.setValue(pbr.baseColorFactor[2], forKey: "baseColorFactorB")
                material.setValue(pbr.baseColorFactor[3], forKey: "baseColorFactorA")
            }
            
            if let metallicTexture = pbr.metallicRoughnessTexture {
                try self.setTexture(index: metallicTexture.index, to: material.metalness)
                material.metalness.mappingChannel = metallicTexture.texCoord
                
                try self.setTexture(index: metallicTexture.index, to: material.roughness)
                material.roughness.mappingChannel = metallicTexture.texCoord
                
                if #available(OSX 10.13, *) {
                    material.metalness.textureComponents = .blue
                    material.roughness.textureComponents = .green
                } else {
                    // Fallback on earlier versions
                    if let image = material.metalness.contents as? Image {
                        let (metalness, roughness) = try getMetallicRoughnessTexture(from: image)
                        material.metalness.contents = metalness
                        material.roughness.contents = roughness
                    }
                }
                
                let metallicFactor = pbr.metallicFactor
                material.setValue(metallicFactor, forKey: "metallicFactor")
                
                let roughnessFactor = pbr.roughnessFactor
                material.setValue(roughnessFactor, forKey: "roughnessFactor")
            }
            
        }
        
        if let normalTexture = glMaterial.normalTexture {
            try self.setTexture(index: normalTexture.index, to: material.normal)
            material.normal.mappingChannel = normalTexture.texCoord
            
            // TODO: - use normalTexture.scale
        }
        
        if let occlusionTexture = glMaterial.occlusionTexture {
            try self.setTexture(index: occlusionTexture.index, to: material.ambientOcclusion)
            material.ambientOcclusion.mappingChannel = occlusionTexture.texCoord
            material.ambientOcclusion.intensity = CGFloat(occlusionTexture.strength)
        }
        
        if let emissiveTexture = glMaterial.emissiveTexture {
            if material.lightingModel == .physicallyBased {
                material.selfIllumination.contents = nil
            }
            try self.setTexture(index: emissiveTexture.index, to: material.emission)
            material.emission.mappingChannel = emissiveTexture.texCoord
        }
        
        material.isDoubleSided = glMaterial.doubleSided

        material.shaderModifiers = [
            .surface: try! String(contentsOf: URL(fileURLWithPath: bundle.path(forResource: "GLTFShaderModifierSurface", ofType: "shader")!), encoding: String.Encoding.utf8)
        ]
        #if SEEMS_TO_HAVE_DOUBLESIDED_BUG
            if material.isDoubleSided {
                material.shaderModifiers = [
                    .surface: try! String(contentsOf: URL(fileURLWithPath: bundle.path(forResource: "GLTFShaderModifierSurface_doubleSidedWorkaround", ofType: "shader")!), encoding: String.Encoding.utf8)
                ]
            }
        #endif
        
        switch glMaterial.alphaMode {
        case "OPAQUE":
            material.blendMode = .replace
        case "BLEND":
            material.blendMode = .alpha
            material.writesToDepthBuffer = false
            material.shaderModifiers![.surface] = try! String(contentsOf: URL(fileURLWithPath: bundle.path(forResource: "GLTFShaderModifierSurface_alphaModeBlend", ofType: "shader")!), encoding: String.Encoding.utf8)
        case "MASK":
            material.shaderModifiers![.fragment] = try! String(contentsOf: URL(fileURLWithPath: bundle.path(forResource: "GLTFShaderModifierFragment_alphaCutoff", ofType: "shader")!), encoding: String.Encoding.utf8)
        default:
            throw GLTFUnarchiveError.NotSupported("loadMaterial: alphaMode \(glMaterial.alphaMode) is not supported")
        }
        
        glMaterial.didLoad(by: material, unarchiver: self)
        return material
    }
    
    private func loadAttributes(_ attributes: [String: GLTFGlTFid]) throws -> [SCNGeometrySource] {
        var sources = [SCNGeometrySource]()
        // Sort attributes to keep correct semantic order
        for (attribute, accessorIndex) in attributes.sorted(by: { $0.0 < $1.0 }) {
            if let semantic = attributeMap[attribute] {
                let accessor = try self.loadVertexAccessor(index: accessorIndex, semantic: semantic)
                sources.append(accessor)
            } else {
                // user defined semantic
                throw GLTFUnarchiveError.NotSupported("loadMesh: user defined semantic is not supported: " + attribute)
            }
        }
        return sources
    }
    
    private func loadMesh(index: Int) throws -> SCNNode {
        guard index < self.meshes.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadMesh: out of index: \(index) < \(self.meshes.count)")
        }
        
        if let mesh = self.meshes[index] {
            return mesh.clone()
        }
        
        guard let meshes = self.json.meshes else {
            throw GLTFUnarchiveError.DataInconsistent("loadMesh: meshes it not defined")
        }
        let glMesh = meshes[index]
        let node = SCNNode()
        self.meshes[index] = node
        
        if let name = glMesh.name {
            node.name = name
        }
        
        var weightPaths = [String]()
        for i in 0..<glMesh.primitives.count {
            let primitive = glMesh.primitives[i]
            let primitiveNode = SCNNode()
            //var sources = [SCNGeometrySource]()
            //var vertexSource: SCNGeometrySource?
            //var normalSource: SCNGeometrySource?
            
            /*
            for (attribute, accessorIndex) in primitive.attributes {
                if let semantic = attributeMap[attribute] {
                    let accessor = try self.loadVertexAccessor(index: accessorIndex, semantic: semantic)
                    sources.append(accessor)
                    if semantic == .vertex {
                        vertexSource = accessor
                    } else if semantic == .normal {
                        normalSource = accessor
                    }
                } else {
                    // user defined semantic
                    throw GLTFUnarchiveError.NotSupported("loadMesh: user defined semantic is not supported: " + attribute)
                }
            }
 */
            var sources = try self.loadAttributes(primitive.attributes)
            let vertexSource = sources.first { $0.semantic == .vertex }
            var normalSource = sources.first { $0.semantic == .normal }
            
            var elements = [SCNGeometryElement]()
            if let indexIndex = primitive.indices {
                let accessor = try self.loadIndexAccessor(index: indexIndex, primitiveMode: primitive.mode)
                elements.append(accessor)
            } else if let vertexSource = vertexSource {
                let accessor = try self.createIndexAccessor(for: vertexSource, primitiveMode: primitive.mode)
                elements.append(accessor)
            } else {
                // Should it be error?
            }
            
            if normalSource == nil {
                if let vertexSource = vertexSource {
                    normalSource = try self.createNormalSource(for: vertexSource, elements: elements)
                    sources.append(normalSource!)
                } else {
                    // Should it be error?
                }
            }
            
            let geometry = SCNGeometry(sources: sources, elements: elements)
            primitiveNode.geometry = geometry
            
            if let materialIndex = primitive.material {
                let material = try self.loadMaterial(index: materialIndex)
                geometry.materials = [material]
            } else {
                let material = self.defaultMaterial
                geometry.materials = [material]
            }
            
            if let targets = primitive.targets {
                let morpher = SCNMorpher()
                for targetIndex in 0..<targets.count {
                    let target = targets[targetIndex]
                    let sources = try self.loadAttributes(target)
                    let geometry = SCNGeometry(sources: sources, elements: nil)

                    if let extras = glMesh.extras, let extrasTargetNames = extras.extensions["TargetNames"] as? GLTFExtrasTargetNames, let targetNames = extrasTargetNames.targetNames {
                        geometry.name = targetNames[targetIndex]
                    }
                    else if let accessor = self.json.accessors?[target["POSITION"]!], let name = accessor.name {
                        geometry.name = name
                    }

                    morpher.targets.append(geometry)
                    let weightPath = "childNodes[0].childNodes[\(i)].morpher.weights[\(targetIndex)]"
                    weightPaths.append(weightPath)
                    
                }
                morpher.calculationMode = .additive
                primitiveNode.morpher = morpher
            }
            
            node.addChildNode(primitiveNode)
        }
        
        // TODO: set default weights
        /*
        if let weights = glMesh.weights {
            for i in 0..<weights.count {
                print("keyPath: \(weightPaths[i])")
                node.setValue(0.123, forKeyPath: weightPaths[i])
                print("value: \(node.value(forKeyPath: weightPaths[i]))")
                //print("v: \(node.childNodes[0].childNodes[0].morpher?.wefight(forTargetAt: i))")

                node.setValue(weights[i], forKeyPath: weightPaths[i])
            }

            //node.setValue(0.234, forKeyPath: "childNodes[0].morpher.weights[")
            //print("value: \(node.childNodes[0].morpher?.weight(forTargetAt: 0))")
        }
        */
        //node.childNodes[0].morpher?.setWeight(1.0, forTargetAt: 0)
        //node.childNodes[0].morpher?.setWeight(1.0, forTargetAt: 1)
        
        
        glMesh.didLoad(by: node, unarchiver: self)
        return node
    }
    
    private func loadAnimationSampler(index: Int, sampler: Int, flipW: Bool = false) throws -> CAAnimationGroup {
        guard index < self.animationSamplers.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadAnimationSampler: out of index: \(index) < \(self.animationSamplers.count)")
        }
        
        if let animationSamplers = self.animationSamplers[index] {
            if animationSamplers.count > sampler, let animation = animationSamplers[sampler] {
                //return animation.copy() as! CAKeyframeAnimation
                return animation.copy() as! CAAnimationGroup
            }
        } else {
            self.animationSamplers[index] = [CAAnimation?]()
        }
        if self.animationSamplers[index]!.count <= sampler {
            for _ in self.animationSamplers[index]!.count...sampler {
                self.animationSamplers[index]!.append(nil)
            }
        }
        
        guard let animations = self.json.animations else {
            throw GLTFUnarchiveError.DataInconsistent("loadAnimationSampler: animations is not defined")
        }
        let glAnimation = animations[index]
        
        guard sampler < glAnimation.samplers.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadAnimationSampler: out of index: sampler \(sampler) < \(glAnimation.samplers.count)")
        }
        let glSampler = glAnimation.samplers[sampler]
        
        let animation = CAKeyframeAnimation()
        
        // LINEAR, STEP, CATMULLROMSPLINE, CUBICSPLINE
        let (keyTimes, duration) = try self.loadKeyTimeAccessor(index: glSampler.input)
        //let timingFunctions =
        let values = try self.loadValueAccessor(index: glSampler.output, flipW: flipW)
        
        animation.keyTimes = keyTimes
        animation.values = values
        animation.repeatCount = .infinity
        animation.duration = duration
        //animation.timingFunctions = timingFunctions
        
        let group = CAAnimationGroup()
        group.animations = [animation]
        group.duration = self.maxAnimationDuration
        group.repeatCount = .infinity
        
        self.animationSamplers[index]![sampler] = group
        
        return group
    }
    
    private func loadWeightAnimationsSampler(index: Int, sampler: Int, paths: [String]) throws -> CAAnimationGroup {
        guard index < self.animationSamplers.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadWeightAnimationsSampler: out of index: \(index) < \(self.animationSamplers.count)")
        }
        
        if let animationSamplers = self.animationSamplers[index] {
            if let animation = animationSamplers[sampler] {
                return animation.copy() as! CAAnimationGroup
            }
        }
        
        guard let glAnimations = self.json.animations else {
            throw GLTFUnarchiveError.DataInconsistent("loadWeightAnimationsSampler: animations is not defined")
        }
        let glAnimation = glAnimations[index]
        
        guard sampler < glAnimation.samplers.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadWeightAnimationsSampler: out of index: sampler \(sampler) < \(glAnimation.samplers.count)")
        }
        let glSampler = glAnimation.samplers[sampler]
        
        let (keyTimes, duration) = try self.loadKeyTimeAccessor(index: glSampler.input)
        guard let values = try self.loadValueAccessor(index: glSampler.output) as? [NSNumber] else {
            throw GLTFUnarchiveError.DataInconsistent("loadWeightAnimationsSampler: data type is not [NSNumber]")
        }
        
        let group = CAAnimationGroup()
        group.duration = duration
        //group.animations = []
        
        var animations = [CAKeyframeAnimation]()
        for path in paths {
            let animation = CAKeyframeAnimation()
            
            animation.keyPath = path
            animation.keyTimes = keyTimes
            //animation.values = [NSNumber]()
            //animation.repeatCount = .infinity
            animation.duration = duration
            
            animations.append(animation)
        }
        group.animations = animations
        group.repeatCount = .infinity
        
        let step = animations.count
        let dataLength = values.count / step
        guard dataLength == keyTimes.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadWeightAnimationsSampler: data count mismatch: \(dataLength) != \(keyTimes.count)")
        }
        for i in 0..<animations.count {
            var valueIndex = i
            var v = [NSNumber]()
            v.reserveCapacity(dataLength)
            for _ in 0..<dataLength {
                v.append(values[valueIndex])
                valueIndex += step
            }
            animations[i].values = v
        }
        
        return group
    }
    
    //private func loadAnimation(index: Int, channel: Int) throws -> SCNAnimation {
    private func loadAnimation(index: Int, channel: Int, weightPaths: [String]?) throws -> CAAnimation {
        guard index < self.animationChannels.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadAnimation: out of index: \(index) < \(self.animationChannels.count)")
        }
        
        if let animationChannels = self.animationChannels[index] {
            if let animation = animationChannels[channel] {
                return animation
            }
        }
        
        guard let animations = self.json.animations else {
            throw GLTFUnarchiveError.DataInconsistent("loadAnimation: animations is not defined")
        }
        let glAnimation = animations[index]
        
        guard channel < glAnimation.channels.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadAnimation: out of index: channel \(channel) < \(glAnimation.channels.count)")
        }
        let glChannel = glAnimation.channels[channel]
        
        // Animation Channel Target
        guard let nodeIndex = glChannel.target.node else {
            throw GLTFUnarchiveError.NotSupported("loadAnimation: animation without node target is not supported")
        }
        let node = try self.loadNode(index: nodeIndex)
        let keyPath = glAnimation.channels[channel].target.path
        //let animation = CAKeyframeAnimation(keyPath: keyPath)
        // Animation Sampler
        let samplerIndex = glChannel.sampler
        
        /*
        guard samplerIndex < glAnimation.samplers.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadAnimation: out of index: sampler \(samplerIndex) < \(glAnimation.samplers.count)")
        }
        let glSampler = glAnimation.samplers[samplerIndex]
        */
        var animation: CAAnimation
        if keyPath == "weights" {
            guard let weightPaths = weightPaths else {
                throw GLTFUnarchiveError.DataInconsistent("loadAnimation: morpher is not defined)")
            }
            animation = try self.loadWeightAnimationsSampler(index: index, sampler: samplerIndex, paths: weightPaths)
        } else {
            let flipW = false
            //let flipW = keyPath == "rotation"
            //let keyframeAnimation = try self.loadAnimationSampler(index: index, sampler: samplerIndex)
            let group = try self.loadAnimationSampler(index: index, sampler: samplerIndex, flipW: flipW)
            let keyframeAnimation = group.animations![0] as! CAKeyframeAnimation
            guard let animationKeyPath = keyPathMap[keyPath] else {
                throw GLTFUnarchiveError.NotSupported("loadAnimation: animation key \(keyPath) is not supported")
            }
            keyframeAnimation.keyPath = animationKeyPath
            animation = group
        }
        
        //let scnAnimation = SCNAnimation(caAnimation: animation)
        //node.addAnimation(scnAnimation, forKey: keyPath)
        node.addAnimation(animation, forKey: keyPath)
        
        //glAnimation.didLoad(by: scnAnimation, unarchiver: self)
        glAnimation.didLoad(by: animation, unarchiver: self)
        //return scnAnimation
        return animation
    }
    
    //@available(OSX 10.13, *)
    private func loadAnimation(forNode index: Int) throws {
        guard let animations = self.json.animations else { return }
        
        let node = try self.loadNode(index: index)
        let weightPaths = node.value(forUndefinedKey: "weightPaths") as? [String]
        for i in 0..<animations.count {
            let animation = animations[i]
            for j in 0..<animation.channels.count {
                let channel = animation.channels[j]
                if channel.target.node == index {
                    let animation = try self.loadAnimation(index: i, channel: j, weightPaths: weightPaths)
                    node.addAnimation(animation, forKey: nil)
                }
            }
        }
    }
    
    private func getMaxAnimationDuration() throws -> CFTimeInterval {
        guard let animations = self.json.animations else { return 0.0 }
        guard let accessors = self.json.accessors else { return 0.0 }
        var duration: CFTimeInterval = 0.0
        for animation in animations {
            for sampler in animation.samplers {
                let accessor = accessors[sampler.input]
                if let max = accessor.max {
                    guard max.count == 1 else {
                        throw GLTFUnarchiveError.DataInconsistent("getMaxAnimationDuration: keyTime must be SCALAR type")
                    }
                    if CFTimeInterval(max[0]) > duration {
                        duration = CFTimeInterval(max[0])
                    }
                }
            }
        }
        return duration
    }
    
    private func loadInverseBindMatrices(index: Int) throws -> [NSValue] {
        guard index < self.accessors.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadInverseBindMatrices: out of index: \(index) < \(self.accessors.count)")
        }
        
        if let accessor = self.accessors[index] as? [NSValue] {
            return accessor
        }
        if self.accessors[index] != nil {
            throw GLTFUnarchiveError.DataInconsistent("loadInverseBindMatrices: the accessor \(index) is not [SCNMatrix4]")
        }
        guard let accessors = self.json.accessors else {
            throw GLTFUnarchiveError.DataInconsistent("loadInverseBindMatrices: accessors is not defined")
        }
        let glAccessor = accessors[index]
        let vectorCount = glAccessor.count
        guard usesFloatComponentsMap[glAccessor.componentType] != nil else {
            throw GLTFUnarchiveError.NotSupported("loadInverseBindMatrices: user defined accessor.componentType is not supported")
        }
        guard glAccessor.type == "MAT4" else {
            throw GLTFUnarchiveError.DataInconsistent("loadInverseBindMatrices: type must be MAT4: \(glAccessor.type)")
        }
        guard let componentsPerVector = componentsPerVectorMap[glAccessor.type] else {
            throw GLTFUnarchiveError.NotSupported("loadInverseBindMatrices: user defined accessor.type is not supported")
        }
        guard let bytesPerComponent = bytesPerComponentMap[glAccessor.componentType] else {
            throw GLTFUnarchiveError.NotSupported("loadInverseBindMatrices: user defined accessor.componentType is not supported")
        }
        let dataOffset = glAccessor.byteOffset
        
        //var bufferView: Data
        let dataStride: Int = bytesPerComponent * componentsPerVector
        //var padding = 0
        var matrices = [NSValue]()
        guard let bufferViewIndex = glAccessor.bufferView else {
            for _ in 0..<vectorCount {
                matrices.append(NSValue(scnMatrix4: SCNMatrix4Identity))
            }
            self.accessors[index] = matrices
            
            glAccessor.didLoad(by: matrices, unarchiver: self)
            
            return matrices
        }
        
        try self.iterateBufferView(index: bufferViewIndex, offset: dataOffset, stride: dataStride, count: glAccessor.count) { (p) in
            // TODO: it could be BYTE, UNSIGNED_BYTE, ...
            var values = [Float]()
            for i in 0..<16 {
                let value = p.load(fromByteOffset: i*4, as: Float.self)
                values.append(value)
            }
            let v: [SCNFloat] = values.map { SCNFloat($0) }
            let matrix = SCNMatrix4(
                m11: v[0], m12: v[1], m13: v[2], m14: v[3],
                m21: v[4], m22: v[5], m23: v[6], m24: v[7],
                m31: v[8], m32: v[9], m33: v[10], m34: v[11],
                m41: v[12], m42: v[13], m43: v[14], m44: v[15])
            matrices.append(NSValue(scnMatrix4: matrix))
        }
        
        self.accessors[index] = matrices
        
        glAccessor.didLoad(by: matrices, unarchiver: self)
        
        return matrices
    }
    
    private func loadSkin(index: Int, meshNode: SCNNode) throws -> SCNSkinner {
        guard index < self.skins.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadSkin: out of index: \(index) < \(self.skins.count)")
        }
        
        if let skin = self.skins[index] {
            return skin
        }
        
        guard let skins = self.json.skins else {
            throw GLTFUnarchiveError.DataInconsistent("loadSkin: 'skins' is not defined")
        }
        let glSkin = skins[index]
        
        var joints = [SCNNode]()
        for joint in glSkin.joints {
            let node = try self.loadNode(index: joint)
            joints.append(node)
        }
        
        var boneInverseBindTransforms: [NSValue]?
        if let inverseBindMatrices = glSkin.inverseBindMatrices {
            boneInverseBindTransforms = try self.loadInverseBindMatrices(index: inverseBindMatrices)
        }
        
        //var baseNode: SCNNode?
        if let skeleton = glSkin.skeleton {
            _ = try self.loadNode(index: skeleton)
        }
        
        //var boneWeights: SCNGeometrySource?
        //var boneIndices: SCNGeometrySource?
        //var baseGeometry: SCNGeometry?
        //var skeleton: SCNNode?
        var _skinner: SCNSkinner?
        for primitive in meshNode.childNodes {
            if let weights = primitive.geometry?.sources(for: .boneWeights) {
                let boneWeights = weights[0]
                
                let baseGeometry = primitive.geometry!
                guard let _joints = primitive.geometry?.sources(for: .boneIndices) else {
                    throw GLTFUnarchiveError.DataInconsistent("loadSkin: JOINTS_0 is not defined")
                }
                let boneIndices = _joints[0]

                #if SEEMS_TO_HAVE_SKINNER_VECTOR_TYPE_BUG
                    // This code doesn't solve the problem.
                    #if false
                        if _joints[0].dataStride == 8 {
                            let device = MTLCreateSystemDefaultDevice()!
                            let numComponents = _joints[0].vectorCount * _joints[0].componentsPerVector
                            _joints[0].data.withUnsafeBytes { (ptr: UnsafePointer<UInt16>) in
                                let buffer = device.makeBuffer(bytes: ptr, length: 2 * numComponents, options: [])!
                                let source = SCNGeometrySource(buffer: buffer, vertexFormat: .ushort4, semantic: .boneIndices, vertexCount: _joints[0].vectorCount, dataOffset: 0, dataStride: _joints[0].dataStride)
                                boneIndices = source
                            }
                        }
                    #endif
                #endif
                
                let skinner = SCNSkinner(baseGeometry: baseGeometry, bones: joints, boneInverseBindTransforms: boneInverseBindTransforms, boneWeights: boneWeights, boneIndices: boneIndices)
                skinner.skeleton = primitive
                primitive.skinner = skinner
                _skinner = skinner
            }
        }
        /*
        guard let _boneWeights = boneWeights else {
            throw GLTFUnarchiveError.DataInconsistent("loadSkin: WEIGHTS_0 is not defined")
        }
        guard let _boneIndices = boneIndices else {
            throw GLTFUnarchiveError.DataInconsistent("loadSkin: JOINTS_0 is not defined")
        }

        let skinner = SCNSkinner(baseGeometry: baseGeometry, bones: joints, boneInverseBindTransforms: boneInverseBindTransforms, boneWeights: _boneWeights, boneIndices: _boneIndices)
        skinner.skeleton = skeleton
        skeleton?.skinner = skinner

        self.skins[index] = skinner
         */
        guard let skinner = _skinner else {
            throw GLTFUnarchiveError.DataInconsistent("loadSkin: skinner is not defined")
        }
        
        glSkin.didLoad(by: skinner, unarchiver: self)
        
        return skinner
    }
    
    private func loadNode(index: Int) throws -> SCNNode {
        guard index < self.nodes.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadNode: out of index: \(index) < \(self.nodes.count)")
        }
        
        if let node = self.nodes[index] {
            return node
        }
        
        guard let nodes = self.json.nodes else {
            throw GLTFUnarchiveError.DataInconsistent("loadNode: nodes is not defined")
        }
        let glNode = nodes[index]
        let scnNode = SCNNode()
        self.nodes[index] = scnNode
        
        if let name = glNode.name {
            scnNode.name = name
        }
        if let camera = glNode.camera {
            scnNode.camera = try self.loadCamera(index: camera)
        }
        if let mesh = glNode.mesh {
            let meshNode = try self.loadMesh(index: mesh)
            scnNode.addChildNode(meshNode)
            
            var weightPaths = [String]()
            for i in 0..<meshNode.childNodes.count {
                let primitive = meshNode.childNodes[i]
                if let morpher = primitive.morpher {
                    for j in 0..<morpher.targets.count {
                        let path = "childNodes[0].childNodes[\(i)].morpher.weights[\(j)]"
                        weightPaths.append(path)
                    }
                }
            }
            scnNode.setValue(weightPaths, forUndefinedKey: "weightPaths")
            
            if let skin = glNode.skin {
                _ = try self.loadSkin(index: skin, meshNode: meshNode)
                //scnNode.skinner = skinner
            }
        }
        
        if let matrix = glNode._matrix {
            scnNode.transform = createMatrix4(matrix)
            if glNode._rotation != nil || glNode._scale != nil || glNode._translation != nil {
                throw GLTFUnarchiveError.DataInconsistent("loadNode: both matrix and rotation/scale/translation are defined")
            }
        } else {
            //scnNode.orientation = createVector4ForOrientation(glNode.rotation)
            scnNode.orientation = createVector4(glNode.rotation)
            scnNode.scale = createVector3(glNode.scale)
            scnNode.position = createVector3(glNode.translation)
        }
        
        if glNode.weights != nil {
            // load weights
        }
        
        if let children = glNode.children {
            for child in children {
                let scnChild = try self.loadNode(index: child)
                scnNode.addChildNode(scnChild)
            }
        }
        
        try self.loadAnimation(forNode: index)
        
        glNode.didLoad(by: scnNode, unarchiver: self)
        return scnNode
    }
    
    func loadScene() throws -> SCNScene {
        if let sceneIndex = self.json.scene {
            return try self.loadScene(index: sceneIndex)
        }
        return try self.loadScene(index: 0)
    }
    
    private func loadScene(index: Int) throws -> SCNScene {
        guard index < self.scenes.count else {
            throw GLTFUnarchiveError.DataInconsistent("loadScene: out of index: \(index) < \(self.scenes.count)")
        }
        
        if let scene = self.scenes[index] {
            return scene
        }
        
        guard let scenes = self.json.scenes else {
            throw GLTFUnarchiveError.DataInconsistent("loadScene: scenes is not defined")
        }
        let glScene = scenes[index]
        let scnScene = SCNScene()
        
        self.maxAnimationDuration = try self.getMaxAnimationDuration()
        
        if let name = glScene.name {
            scnScene.setValue(name, forKey: "name")
        }
        if let nodes = glScene.nodes {
            for node in nodes {
                let scnNode = try self.loadNode(index: node)
                scnScene.rootNode.addChildNode(scnNode)
            }
        }
        
        self.scenes[index] = scnScene
        
        glScene.didLoad(by: scnScene, unarchiver: self)
        
        self.json.didLoad(by: scnScene, unarchiver: self)
        
        return scnScene
    }
    
    func loadScenes() throws {
        guard let scenes = self.json.scenes else { return }
        for index in 0..<scenes.count {
            _ = try self.loadScene(index: index)
        }
    }
}

