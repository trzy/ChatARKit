//
// GLTFExtension.swift
//
// Extension
// Dictionary object with extension-specific objects.
//

import Foundation

let GLTFExtensionCodingUserInfoKey = CodingUserInfoKey(rawValue: "GLTFSceneKit.GLTFExtension")!

struct GLTFExtension: Codable {
    var extensions: [String:Codable] = [:]
    
    init(from decoder: Decoder) throws {
        if let extensions = decoder.userInfo[GLTFExtensionCodingUserInfoKey] as? [String:Codable.Type] {
            for (key, ExtensionCodable) in extensions {
                self.extensions[key] = try ExtensionCodable.init(from: decoder)
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        // TODO: implement
    }
}

