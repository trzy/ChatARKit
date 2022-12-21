//
// GLTFKHRMaterialsCommon_GLTFKHRMaterialsCommon.swift
//

import Foundation
import SceneKit

struct GLTFKHRMaterialsCommon_GLTFKHRMaterialsCommonExtension: GLTFCodable {
    struct GLTFKHRMaterialsCommon_GLTFKHRMaterialsCommon: Codable {
        struct MaterialsCommon: Codable {
            let _ambient: [Float]?
            var ambient: [Float] {
                get { return self._ambient ?? [0, 0, 0, 1] }
            }
            
            let _diffuse: [Float]?
            var diffuse: [Float] {
                get { return self._diffuse ?? [0, 0, 0, 1] }
            }
            
            /*
            let _doubleSided: Bool?
            var doubleSided: Bool {
                get { return self._doubleSided ?? false }
            }
            */
            
            let _emission: [Float]?
            var emission: [Float] {
                get { return self._emission ?? [0, 0, 0, 1] }
            }
            
            let _specular: [Float]?
            var specular: [Float] {
                get { return self._specular ?? [0, 0, 0, 1] }
            }
            
            let _shininess: [Float]?
            var shininess: Float {
                get { return self._shininess?[0] ?? 0 }
            }
            
            let _transparency: [Float]?
            var transparency: Float {
                get { return self._transparency?[0] ?? 1 }
            }
            
            /*
            let _transparent: Bool?
            var transparent: Bool {
                get { return self._transparent ?? false }
            }
             */
            private enum CodingKeys: String, CodingKey {
                case _ambient = "ambient"
                case _diffuse = "diffuse"
                case _emission = "emission"
                case _specular = "specuar"
                case _shininess = "shininess"
                case _transparency = "transparency"
            }
        }
        
        let _doubleSided: Bool?
        var doubleSided: Bool {
            get { return self._doubleSided ?? false }
        }
        
        let technique: String
        
        let _transparent: Bool?
        var transparent: Bool {
            get { return self._transparent ?? false }
        }
        
        let values: MaterialsCommon
        
        let name: String?
        
        private enum CodingKeys: String, CodingKey {
            case _doubleSided = "doubleSided"
            case technique
            case _transparent = "transparent"
            case values
            case name
        }
    }
    let data: GLTFKHRMaterialsCommon_GLTFKHRMaterialsCommon?
    
    enum CodingKeys: String, CodingKey {
        case data = "KHR_materials_common"
    }
    
    /*
    init(from decoder: Decoder) throws {
        
    }
    */
    
    func didLoad(by object: Any, unarchiver: GLTFUnarchiver) {
        guard let data = self.data else { return }
        guard let material = object as? SCNMaterial else { return }
        
        if data.technique == "PHONG" {
            material.lightingModel = .phong
            
            material.ambient.contents = createColor(data.values.ambient)
            material.diffuse.contents = createColor(data.values.diffuse)
            material.emission.contents = createColor(data.values.emission)
            material.shininess = CGFloat(data.values.shininess)
            material.specular.contents = createColor(data.values.specular)
            if data.transparent {
                material.transparency = CGFloat(data.values.transparency)
            }
        }
        material.isDoubleSided = data.doubleSided
        material.name = data.name
    }
}


