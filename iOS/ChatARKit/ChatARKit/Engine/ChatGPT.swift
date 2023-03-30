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
    private var _payload: [String: Any] = [
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
The code must not call any functions or use any data types besides those defined by the base language spec and the following:
- A function createEntity() that takes only a string describing the object (for example, 'tree frog', 'cube', or 'rocket ship'). The return value is the object.
- Objects returned by createEntity() have only three properties, each of them an array of length 3: 'position' (the position), 'scale' (the scale), and 'euler' (rotation specified as Euler angles in degrees).
- Objects returned by createEntity() may be assigned a function to 'onUpdate' that takes the seconds elapsed since the last frame, 'deltaTime'. This function is executed each frame.
- Objects returned by createEntity() must have their properties initialized after the object is created.
- A function getPlanes() exists that takes no arguments and returns an array of plane objects. The array may be empty.
- Each plane object has two properties: 'center', the center position of the plane, and 'size', the size of the plane in each dimension. Each of these is an array of numbers of length 3.
- A global variable 'cameraPosition' containing the camera position, which is the user position, as a 3-element float array.
- The function getNearestPlane() takes no arguments and returns the closest plane to the user or null if no planes exist.
- The function getGroundPlane() takes no arguments and returns the plane that corresponds to the floor or ground, or null if no planes exist.
- Only planes returned by getPlanes() that are not the same as the plane returned by getGroundPlane() may be considered tables.
- Make cubes have size [0.25,0.25,0.25].
- When placing objects on planes, do not add any offset from the plane.
"""
            ]
        ]
    ]

    public func send(command: String, completion: @escaping (String) -> Void) {
        let requestHeader = [
            "Authorization": "Bearer \(APIKeys.openAI)",
            "Content-Type": "application/json"
        ]

        if var messages = _payload["messages"] as? [[String: String]] {
            // Append user prompts to maintain some sort of state. Note that we do not send back the agent responses because
            // they won't add much.
            messages.append([ "role": "user", "content": "Write JavaScript code, without any explanation, that: \(command)" ])
            _payload["messages"] = messages
        }

        let jsonPayload = try? JSONSerialization.data(withJSONObject: _payload)
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
                if let code = extractCodeFromContent(content: content) {
                    print("[ChatGPT] Code: \(code)")
                    return code
                }
            }
            print("[ChatGPT] Error: Unable to parse response")
        } catch {
            print("[ChatGPT] Error: Unable to deserialize response: \(error)")
        }
        return nil
    }

    private func extractCodeFromContent(content: String) -> String? {
        // Sometimes, code is returned wrapped in ``` ``` and we need to extract it
        let parts = content.split(separator: "```", omittingEmptySubsequences: false)
        if parts.count == 1 {
            // There was no ``` ```
            return content
        } else if parts.count >= 2 {
            // Get only the first code snippet
            return String(parts[1])
        }
        return nil
    }
}
