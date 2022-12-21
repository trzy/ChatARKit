//
//  GLTFShaderModifierFragment_VRMUnlitTexture.shader
//  GLTFSceneKit
//
//  Created magicien on 8/12/18.
//  Copyright © 2018 DarkHorse. All rights reserved.
//

#pragma arguments

float4 baseColor;

#pragma body

_output.color = baseColor * _surface.diffuse;
