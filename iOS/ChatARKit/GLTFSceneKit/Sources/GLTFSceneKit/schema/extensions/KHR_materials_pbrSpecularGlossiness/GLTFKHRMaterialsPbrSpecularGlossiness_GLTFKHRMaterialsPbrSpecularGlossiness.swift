//
// GLTFKHRMaterialsPbrSpecularGlossiness_GLTFKHRMaterialsPbrSpecularGlossiness.swift
//

import Foundation
import SceneKit

struct GLTFKHRMaterialsPbrSpecularGlossiness_GLTFKHRMaterialsPbrSpecularGlossinessExtension: GLTFCodable {
    struct GLTFKHRMaterialsPbrSpecularGlossiness_GLTFKHRMaterialsPbrSpecularGlossiness: Codable {
        let _diffuseFactor: [Float]?
        var diffuseFactor: [Float] {
            get { return self._diffuseFactor ?? [1, 1, 1, 1] }
        }
        
        let diffuseTexture: GLTFTextureInfo?
        
        let _specularFactor: [Float]?
        var specularFactor: [Float] {
            get { return self._specularFactor ?? [1, 1, 1] }
        }

        let _glossinessFactor: Float?
        var glossinessFactor: Float {
            get { return self._glossinessFactor ?? 1.0 }
        }
        
        let specularGlossinessTexture: GLTFTextureInfo?
        
        private enum CodingKeys: String, CodingKey {
            case _diffuseFactor = "diffuseFactor"
            case diffuseTexture
            case _specularFactor = "specularFactor"
            case _glossinessFactor = "glossinessFactor"
            case specularGlossinessTexture
        }
    }
    let data: GLTFKHRMaterialsPbrSpecularGlossiness_GLTFKHRMaterialsPbrSpecularGlossiness?
    
    enum CodingKeys: String, CodingKey {
        case data = "KHR_materials_pbrSpecularGlossiness"
    }
    
    func didLoad(by object: Any, unarchiver: GLTFUnarchiver) {
        guard let data = self.data else { return }
        guard let material = object as? SCNMaterial else { return }
        
        material.lightingModel = .physicallyBased
        
        if let diffuseTexture = data.diffuseTexture {
            do {
                try unarchiver.setTexture(index: diffuseTexture.index, to: material.diffuse)
            } catch {
                print("\(error.localizedDescription)")
            }
            material.diffuse.mappingChannel = diffuseTexture.texCoord
            
            material.setValue(data.diffuseFactor[0], forKey: "diffuseFactorR")
            material.setValue(data.diffuseFactor[1], forKey: "diffuseFactorG")
            material.setValue(data.diffuseFactor[2], forKey: "diffuseFactorB")
            material.setValue(data.diffuseFactor[3], forKey: "diffuseFactorA")
        } else {
            material.diffuse.contents = createColor(data.diffuseFactor)

            material.setValue(1.0, forKey: "diffuseFactorR")
            material.setValue(1.0, forKey: "diffuseFactorG")
            material.setValue(1.0, forKey: "diffuseFactorB")
            material.setValue(1.0, forKey: "diffuseFactorA")
        }
        
        if let specularGlossinesTexture = data.specularGlossinessTexture {
            // Use a multiply texture as a specular texture
            // because a specular texture is overwritten by a metalness texture for PBR.
            do {
                try unarchiver.setTexture(index: specularGlossinesTexture.index, to: material.multiply)
            } catch {
                print("\(error.localizedDescription)")
            }
            material.multiply.mappingChannel = specularGlossinesTexture.texCoord

            material.setValue(data.specularFactor[0], forKey: "specularFactorR")
            material.setValue(data.specularFactor[1], forKey: "specularFactorG")
            material.setValue(data.specularFactor[2], forKey: "specularFactorB")
            material.setValue(data.glossinessFactor, forKey: "glossinessFactor")
            
            material.shaderModifiers = [
                .surface: try! String(contentsOf: URL(fileURLWithPath: Bundle.module_workaround.path(forResource: "GLTFShaderModifierSurface_pbrSpecularGlossiness_texture_doubleSidedWorkaround", ofType: "shader")!), encoding: String.Encoding.utf8)
            ]
        } else {
            material.specular.contents = createColor([
                data.specularFactor[0],
                data.specularFactor[1],
                data.specularFactor[2],
                data.glossinessFactor
            ])
            
            material.setValue(1.0, forKey: "specularFactorR")
            material.setValue(1.0, forKey: "specularFactorG")
            material.setValue(1.0, forKey: "specularFactorB")
            material.setValue(1.0, forKey: "glossinessFactor")

            material.shaderModifiers = [
                .surface: try! String(contentsOf: URL(fileURLWithPath: Bundle.module_workaround.path(forResource: "GLTFShaderModifierSurface_pbrSpecularGlossiness", ofType: "shader")!), encoding: String.Encoding.utf8)
            ]
            
            #if SEEMS_TO_HAVE_DOUBLESIDED_BUG
                if material.isDoubleSided {
                    material.shaderModifiers = [
                        .surface: try! String(contentsOf: URL(fileURLWithPath: Bundle.module_workaround.path(forResource: "GLTFShaderModifierSurface_pbrSpecularGlossiness_doubleSidedWorkaround", ofType: "shader")!), encoding: String.Encoding.utf8)
                    ]
                }
            #endif
        }
    }
}


