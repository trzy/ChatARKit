//TODO: sometimes explanations are generated and we need to extract code form ``` <code> ```

//
//  ChatGPT.swift
//  ChatARKit
//
//  Created by Bart Trzynadlowski on 3/28/23.
//
//  ChatGPT interface. Wraps user commands with additional context and talks to the OpenAI
//  servers.
//

import UIKit

public class ChatGPT {
    private var _task: URLSessionDataTask?

    public func send(command: String, completion: @escaping (String) -> Void) {
        let requestHeader = [
            "Authorization": "Bearer \(APIKeys.openAI)",
            "Content-Type": "application/json"
        ]

        let payload: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                [
                    "role": "system",
                    "content":
"""
You are a smart assistant that writes JavaScript code. Generate code with no explanations.
The code must be wrapped in an anonymous function that is then executed.
The code must not define any new functions.
The code must define all variables and constants used.
The code must not call any functions or use any data types besides those defined by the base language spec and the following:"
- A function createEntity() that takes only a string describing the object (for example, 'tree frog', 'cube', or 'rocket ship'). The return value is the object.
- Objects returned by createEntity() have only three properties, each of them an array of length 3: 'position' (the position), 'scale' (the scale), and 'euler' (rotation specified as Euler angles in degrees).
- Objects returned by createEntity() may be assigned a function to 'onUpdate' that takes the seconds elapsed since the last frame, 'deltaTime'. This function is executed each frame.
- Objects returned by createEntity() must have their properties initialized after the object is created.
- A function getPlanes() exists that takes no arguments and returns an array of plane objects. The array may be empty.
- Each plane object has two properties: 'center', the center position of the plane, and 'size', the size of the plane in each dimension. Each of these is an array of numbers of length 3.
- A global variable 'cameraPosition' containing the camera position, which is the user position, as a 3-element float array.
- The function getNearestPlane() takes no arguments and returns the closest plane to the user or null if no planes exist.
- The function getGroundPlane() takes no arguments and returns the plane that corresponds to the floor or ground, or null if no planes exist.
"""
                ],
                [
                    "role": "user",
                    "content": "Write JavaScript code, without any explanation, that: \(command)"
                ]
            ]
        ]

        let jsonPayload = try? JSONSerialization.data(withJSONObject: payload)
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = requestHeader
        request.httpBody = jsonPayload
        _task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let code = self.extractCodeFromResponse(data: data) {
                    completion(code)
                }
            }
        }
        _task?.resume()
    }

    private func extractCodeFromResponse(data: Data) -> String? {
        do {
            let jsonString = String(decoding: data, as: UTF8.self)
            if jsonString.count > 0 {
                print("[ChatGPT] Response payload: \(jsonString)")
            }
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let response = json as? [String: AnyObject],
               let choices = response["choices"] as? [AnyObject],
               choices.count > 0,
               let first = choices[0] as? [String: AnyObject],
               let message = first["message"] as? [String: AnyObject],
               let content = message["content"] as? String {
                print("[ChatGPT] Code: \(content)")
                return content
            }
            print("[ChatGPT] Error: Unable to parse response")
        } catch {
            print("[ChatGPT] Error: Unable to deserialize response: \(error)")
        }
        return nil
    }
}
