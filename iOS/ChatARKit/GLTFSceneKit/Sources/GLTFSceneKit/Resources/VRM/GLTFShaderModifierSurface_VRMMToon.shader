//
//  GLTFShaderModifierSurface_VRMMToon.shader
//  GLTFSceneKit
//
//  Created magicien on 8/7/18.
//  Copyright © 2017 DarkHorse. All rights reserved.
//

constant float3 dielectricSpecular = float3(0.04, 0.04, 0.04);
constant float invDielect = 1.0 - dielectricSpecular.r;
constant float epsilon = 1e-6;

constant float alphaCutoff = 0.5;
constant float4 litColor = float4(1, 1, 1, 1);
constant float4 shadeColor = float4(0.97, 0.81, 0.86, 1);
constant float normalScale = 1.0;
constant float shadeShift = 0;
constant float shadeToony = 0.9;
constant float lightAttenuation = 0;
constant float outlineWidth = 0.5;
constant float outlineScaledMaxDistance = 1;
constant float4 outlineColor = float4(0, 0, 0, 1);
constant float outlineLightingMix = 1;

#pragma arguments

float diffuseFactorR;
float diffuseFactorG;
float diffuseFactorB;
float diffuseFactorA;
float specularFactorR;
float specularFactorG;
float specularFactorB;
float emissiveFactorR;
float emissiveFactorG;
float emissiveFactorB;

#pragma body

float4 diffuse = _surface.diffuse * float4(diffuseFactorR, diffuseFactorG, diffuseFactorB, diffuseFactorA);
float3 specular = _surface.specular.r * float3(specularFactorR, specularFactorG, specularFactorB);
