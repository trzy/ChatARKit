//
//  GameViewController.swift
//  GameSample
//
//  Created by magicien on 2017/08/17.
//  Copyright © 2017年 DarkHorse. All rights reserved.
//

import SceneKit
import QuartzCore
import GLTFSceneKit

class GameViewController: NSViewController {
    
    @IBOutlet weak var gameView: GameView!
    @IBOutlet weak var openFileButton: NSButton!
    @IBOutlet weak var cameraSelect: NSPopUpButton!
    
    var cameraNodes: [SCNNode] = []
    let defaultCameraTag: Int = 99
    
    override func awakeFromNib(){
        super.awakeFromNib()
        
        var scene: SCNScene
        do {
            let sceneSource = try GLTFSceneSource(named: "art.scnassets/car/scene.gltf")
            scene = try sceneSource.scene()
        } catch {
            print("\(error.localizedDescription)")
            return
        }
        
        self.setScene(scene)
        
        self.gameView!.autoenablesDefaultLighting = true
        
        // allows the user to manipulate the camera
        self.gameView!.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        self.gameView!.showsStatistics = true
        
        // configure the view
        self.gameView!.backgroundColor = NSColor.gray
        
        self.gameView!.addObserver(self, forKeyPath: "pointOfView", options: [.new], context: nil)

        self.gameView!.delegate = self
    }
    
    func setScene(_ scene: SCNScene) {
        // update camera names
        self.cameraNodes = scene.rootNode.childNodes(passingTest: { (node, finish) -> Bool in
            return node.camera != nil
        })
        
        // set the scene to the view
        self.gameView!.scene = scene

        // set the camera menu
        self.cameraSelect.menu?.removeAllItems()
        if self.cameraNodes.count > 0 {
            self.cameraSelect.removeAllItems()
            let titles = self.cameraNodes.map { $0.camera?.name ?? "untitled" }
            for title in titles {
                self.cameraSelect.menu?.addItem(withTitle: title, action: nil, keyEquivalent: "")
            }
            self.gameView!.pointOfView = self.cameraNodes[0]
        }
        
        //to give nice reflections :)
        scene.lightingEnvironment.contents = "art.scnassets/shinyRoom.jpg"
        scene.lightingEnvironment.intensity = 2;
        
        let defaultCameraItem = NSMenuItem(title: "SCNViewFreeCamera", action: nil, keyEquivalent: "")
        defaultCameraItem.tag = self.defaultCameraTag
        defaultCameraItem.isEnabled = false
        self.cameraSelect.menu?.addItem(defaultCameraItem)
        
        self.cameraSelect.autoenablesItems = false
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "pointOfView", let change = change {
            if let cameraNode = change[.newKey] as? SCNNode {
                // It must use the main thread to change the UI.
                DispatchQueue.main.async {
                    if let index = self.cameraNodes.index(of: cameraNode) {
                        self.cameraSelect.selectItem(at: index)
                    } else {
                        self.cameraSelect.selectItem(withTag: self.defaultCameraTag)
                    }
                }
            }
        }
    }
    
    @IBAction func openFileButtonClicked(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["gltf", "glb", "vrm"]
        openPanel.message = "Choose glTF file"
        openPanel.begin { (response) in
            if response == .OK {
                guard let url = openPanel.url else { return }
                do {
                    let sceneSource = GLTFSceneSource.init(url: url)
                    let scene = try sceneSource.scene()
                    self.setScene(scene)
                } catch {
                    print("\(error.localizedDescription)")
                }
            }
        }
    }
    
    @IBAction func selectCamera(_ sender: Any) {
        let index = self.cameraSelect.indexOfSelectedItem
        let cameraNode = self.cameraNodes[index]
        self.gameView!.pointOfView = cameraNode
    }
}

extension GameViewController: SCNSceneRendererDelegate {
  func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
    self.gameView.scene?.rootNode.updateVRMSpringBones(time: time)
  }
}
