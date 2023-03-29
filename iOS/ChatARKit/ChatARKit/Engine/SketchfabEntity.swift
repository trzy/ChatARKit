//
//  SketchfabEntity.swift
//  ChatARKit
//
//  Created by Bart Trzynadlowski on 12/18/22.
//
//  A Sketchfab model. Using the Sketchfab REST API, searches for and imports
//  GLTF models. Sketchfab's search feature is next to useless and the code
//  here could be improved to compensate. Sometimes, models fail to import or
//  crash the app because of their large size.
//
//  Make sure you copy your authorization token from the "Passwords & API"
//  section of your Sketchfab account settings.
//

import SceneKit
import UIKit

@objc public class SketchfabEntity: Entity {
    private let _rootNode = SCNNode()
    private let _jsonPayloadHeader = [
        "Authorization": "Token \(APIKeys.sketchfab)",
        "Content-Type": "application/json"
    ]
    private var _task: URLSessionDataTask?

    public init(name: String, scene: SCNScene) {
        super.init(name: name, node: _rootNode, scene: scene)
        downloadModel(query: name)
    }

    private func downloadModel(query: String) {
        guard let query = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("[SketchfabEntity] Error: Cannot encode query: \(query)")
            return
        }

        // Search URL
        guard let url = URL(string: "https://api.sketchfab.com/v3/search?type=models&q=" + query + "&downloadable=true&file_format=gltf&archives_flavours=false&pbr_type=false") else {
            print("[SketchfabEntity] Error: Cannot encode search URL")
            return
        }

        // Perform search
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = _jsonPayloadHeader
        _task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                //let str = String(decoding: data, as: UTF8.self)
                //print(str)
                self.processSearchResponse(data: data)
            } else if let error = error {
                print("[SketchfabEntity] HTTP Request Failed \(error)")
            }
        }
        _task?.resume()
    }

    private func processSearchResponse(data: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let response = json as? [String: AnyObject] {
                if response["results"] != nil {
                    if let results = response["results"] as? [AnyObject] {
                        print("[Sketchfab] Received \(results.count) results")
                        if results.count > 0, let result = results[0] as? [String: AnyObject] {
                            if let uri = result["uri"] as? String {
                                getModelDownloadInformation(uri: uri)
                                return
                            }
                        }
                    }
                }
            }
            print("[SketchfabEntity] Error: Unable to parse search results")
        } catch {
            print("[SketchfabEntity] Error: Unable to deserialize search response: \(error)")
        }
    }

    private func getModelDownloadInformation(uri: String) {
        guard let url = URL(string: uri + "/download") else {
            print("[SketchfabEntity] Error: Cannot encode download URL from URI: \(uri)")
            return
        }

        // Get model download information
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = _jsonPayloadHeader
        _task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                //let str = String(decoding: data, as: UTF8.self)
                //print(str)
                self.processDownloadInformationResponse(data: data)
            } else if let error = error {
                print("[SketchfabEntity] HTTP Request Failed \(error)")
            }
        }
        _task?.resume()
    }

    private func processDownloadInformationResponse(data: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let response = json as? [String: AnyObject] {
                if let gltfModelInfo = response["gltf"] as? [String: AnyObject] {
                    if let url = gltfModelInfo["url"] as? String {
                        print("[SketchfabEntity] Model asset URL: \(url)")
                        if let size = gltfModelInfo["size"] as? Int {
                            print("[SketchfabEntity] Model asset size: \(size) bytes")
                        }
                        self.downloadModelAsset(url: url)
                        return
                    }
                }
            }
            print("[SketchfabEntity] Error: Unable to parse download information")
        } catch {
            print("[SketchfabEntity] Error: Unable to deserialize download information response: \(error)")
        }
    }

    private func downloadModelAsset(url: String) {
        guard let url = URL(string: url) else {
            print("[SketchfabEntity] Error: Cannot encode download URL: \(url)")
            return
        }

        // Download model
        let request = URLRequest(url: url)  // no headers needed (not even Content-Type)
        print("[SketchfabEntity] Downloading model...")
        _task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                print("[SketchfabEntity] Downloaded \(data.count) bytes")
                if let zipFileURL = self.saveZipFile(data: data) {
                    self.loadModel(from: zipFileURL)
                }
            } else if let error = error {
                print("[SketchfabEntity] Error: Download failed: \(error)")
            }
        }
        _task?.resume()
    }

    private func saveZipFile(data: Data) -> URL? {
        let dir = FileManager.default.temporaryDirectory
        let fileURL = dir.appendingPathComponent(name).appendingPathExtension("zip")
        do {
            try data.write(to: fileURL, options: .atomic)
            print("[SketchfabEntity] Wrote \(data.count) bytes to: \(fileURL)")
        } catch {
            print("[SketchfabEntity] Unable to write download model to: \(fileURL)")
            return nil
        }
        return fileURL
    }

    private func loadModel(from zipFileURL: URL) {
        do {
            let unzipDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().description)
            try Zip.unzipFile(zipFileURL, destination: unzipDirectory, overwrite: true, password: nil)
            for fileURL in try FileManager.default.contentsOfDirectory(at: unzipDirectory, includingPropertiesForKeys: nil) {
                if fileURL.pathExtension == "gltf" {
                    print("[SketchfabEntity] Found model file: \(fileURL)")
                    loadGLTF(from: fileURL)
                    return
                }
            }
            print("[SketchfabEntity] No model file found to load")
        } catch {
            print("[SketchfabEntity] Error loading mode: \(error.localizedDescription)")
        }
    }

    private func loadGLTF(from fileURL: URL) {
        do {
            let sceneSource = GLTFSceneSource(url: fileURL)
            let scene = try sceneSource.scene()
            let rootNode = scene.rootNode

            let bounds = Vector3(rootNode.boundingBox.max) - Vector3(rootNode.boundingBox.min)
            let scaleFactor = 1.0 / bounds.max()

            let newRootNode = SCNNode()
            newRootNode.simdScale *= scaleFactor
            for node in rootNode.childNodes {
                newRootNode.addChildNode(node)
            }

            DispatchQueue.main.async { [weak self] in
                self?._rootNode.addChildNode(newRootNode)
            }
        } catch {
            print("[SketchfabEntity] Unable to load GLTF assset: \(error.localizedDescription)")
            return
        }
    }
}
