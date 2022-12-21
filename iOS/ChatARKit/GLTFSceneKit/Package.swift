// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GLTFSceneKit",
    platforms: [.iOS(.v11), .macOS(.v10_13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GLTFSceneKit",
            targets: ["GLTFSceneKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GLTFSceneKit",
            dependencies: [],
            exclude: ["Info.plist"],
            resources: [
              .copy("Resources/GLTFShaderModifierFragment_alphaCutoff.shader"),
              .copy("Resources/GLTFShaderModifierSurface.shader"),
              .copy("Resources/GLTFShaderModifierSurface_alphaModeBlend.shader"),
              .copy("Resources/GLTFShaderModifierSurface_doubleSidedWorkaround.shader"),
              .copy("Resources/KHR_materials_pbrSpecularGlossiness/GLTFShaderModifierSurface_pbrSpecularGlossiness.shader"),
              .copy("Resources/KHR_materials_pbrSpecularGlossiness/GLTFShaderModifierSurface_pbrSpecularGlossiness_doubleSidedWorkaround.shader"),
              .copy("Resources/KHR_materials_pbrSpecularGlossiness/GLTFShaderModifierSurface_pbrSpecularGlossiness_texture_doubleSidedWorkaround.shader"),
              .copy("Resources/VRM/GLTFShaderModifierFragment_VRMUnlitTexture.shader"),
              .copy("Resources/VRM/GLTFShaderModifierFragment_VRMUnlitTexture_Cutoff.shader"),
              .copy("Resources/VRM/GLTFShaderModifierSurface_VRMMToon.shader"),
            ]
        ),
    ]
)
