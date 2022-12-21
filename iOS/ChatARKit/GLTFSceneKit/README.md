[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# GLTFSceneKit
glTF loader for SceneKit

![ScreenShot](https://raw.githubusercontent.com/magicien/GLTFSceneKit/master/screenshot.png)

## Installation
### Using [CocoaPods](http://cocoapods.org/)

Add the following to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html):

```rb
pod 'GLTFSceneKit'
```

### Using [Carthage](https://github.com/Carthage/Carthage)

Add the following to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

```
github "magicien/GLTFSceneKit" ~> 0.4.0
```

### Using [Swift Package Manager](https://swift.org/package-manager/)

1. Open your project with Xcode
2. Select `File` > `Swift Packages` > `Add Package Dependency...`
3. Put `https://github.com/magicien/GLTFSceneKit` in the search box and click `Next`

## Usage

### Swift
```
import GLTFSceneKit

var scene: SCNScene
do {
  let sceneSource = try GLTFSceneSource(named: "art.scnassets/Box/glTF/Box.gltf")
  scene = try sceneSource.scene()
} catch {
  print("\(error.localizedDescription)")
  return
}
```

### Objective-C
```
@import GLTFSceneKit;

GLTFSceneSource *source = [[GLTFSceneSource alloc] initWithURL:url options:nil];
NSError *error;
SCNScene *scene = [source sceneWithOptions:nil error:&error];
if (error != nil) {
  NSLog(@"%@", error);
  return;
}
```

## See also

[GLTFQuickLook](https://github.com/magicien/GLTFQuickLook) - QuickLook plugin for glTF files
