//
//  GLTFSceneKit+BundleFinder.swift
//  
//
//  Created by Andrew Breckenridge on 9/6/21.
//

/// required to enable Swift previews in Xcode 12: https://github.com/pointfreeco/isowords/discussions/104

import Foundation

#if !DEBUG
extension Bundle {
    static var module_workaround: Bundle = {
        #if SWIFT_PACKAGE
        return .module
        #else
        return Bundle(for: GLTFUnarchiver.self)
        #endif
    }()
}
#else
private let moduleName = "GLTFSceneKit_GLTFSceneKit"

extension Foundation.Bundle {
  static var module_workaround: Bundle = {
    #if !SWIFT_PACKAGE
    return Bundle(for: GLTFUnarchiver.self)
    #else
    /* The name of your local package, prepended by "LocalPackages_" for iOS and "PackageName_" for macOS. You may have same PackageName and TargetName*/
    let bundleNameIOS = "LocalPackages_\(moduleName)"
    let bundleNameMacOs = "PackageName_\(moduleName)"
    let andrewSBBundleName = moduleName

    let candidates = [
      /* Bundle should be present here when the package is linked into an App. */
      Bundle.main.resourceURL,
      /* Bundle should be present here when the package is linked into a framework. */
      Bundle(for: GLTFUnarchiver.self).resourceURL,
      /* For command-line tools. */
      Bundle.main.bundleURL,

      // AndrewSB reverse engineered this one
      Bundle(for: GLTFUnarchiver.self).resourceURL?.appendingPathComponent("Bundle").appendingPathComponent("Application"),

      /* Bundle should be present here when running previews from a different package (this is the path to "…/Debug-iphonesimulator/"). */
      Bundle(for: GLTFUnarchiver.self).resourceURL?.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),
      Bundle(for: GLTFUnarchiver.self).resourceURL?.deletingLastPathComponent().deletingLastPathComponent(),
    ]

    for candidate in candidates {
      let bundlePathiOS = candidate?.appendingPathComponent(bundleNameIOS + ".bundle")
      let bundlePathMacOS = candidate?.appendingPathComponent(bundleNameMacOs + ".bundle")
      let andrewSBBundlePath = candidate?.appendingPathComponent(andrewSBBundleName + ".bundle")

      if let bundle = bundlePathiOS.flatMap(Bundle.init(url:)) {
        return bundle
      } else if let bundle = bundlePathMacOS.flatMap(Bundle.init(url:)) {
        return bundle
      } else if let bundle = andrewSBBundlePath.flatMap(Bundle.init(url:)) {
        return bundle
      }
    }
    fatalError("unable to find bundle")
    #endif
  }()
}
#endif
