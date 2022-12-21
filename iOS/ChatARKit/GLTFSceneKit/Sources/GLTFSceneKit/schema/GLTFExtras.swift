//
// GLTFExtras.swift
//
// Extras
// Application-specific data.
//

import Foundation

let GLTFExtrasCodingUserInfoKey = CodingUserInfoKey(rawValue: "GLTFSceneKit.GLTFExtras")!

struct GLTFExtras: Codable {
    var extensions: [String:Codable] = [:]
    
    init(from decoder: Decoder) throws {
        if let extensions = decoder.userInfo[GLTFExtrasCodingUserInfoKey] as? [String:Codable.Type] {
            for (key, ExtensionCodable) in extensions {
                self.extensions[key] = try ExtensionCodable.init(from: decoder)
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        // TODO: implement
    }
}

