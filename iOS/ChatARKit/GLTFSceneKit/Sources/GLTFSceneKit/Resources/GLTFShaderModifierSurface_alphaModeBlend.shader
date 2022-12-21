//
//  GLTFShaderModifierSurface.shader
//  GLTFSceneKit
//
//  Created by Johanos [Wayfair NEXT] on 2017/12/04.
//  Based on GLTFShaderModifierSurface.shader
//

#pragma arguments

float baseColorFactorR;
float baseColorFactorG;
float baseColorFactorB;
float baseColorFactorA;
float metallicFactor;
float roughnessFactor;
float emissiveFactorR;
float emissiveFactorG;
float emissiveFactorB;

#pragma body
#pragma transparent

_surface.diffuse *= float4(baseColorFactorR, baseColorFactorG, baseColorFactorB, baseColorFactorA);
_surface.metalness *= metallicFactor;
_surface.roughness *= roughnessFactor;
_surface.emission.rgb *= float3(emissiveFactorR, emissiveFactorG, emissiveFactorB);
