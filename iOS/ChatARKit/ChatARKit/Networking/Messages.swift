//
//  Messages.swift
//  ChatARKit
//
//  Created by Bart Trzynadlowski on 9/21/22.
//

public struct HelloMessage: Codable {
    public static let id = String(describing: Self.self)
    public let __id = Self.id
    public var message: String
}

public struct ChatGPTPromptMessage: Codable {
    public static let id = String(describing: Self.self)
    public let __id = Self.id
    public var prompt: String
}

public struct ChatGPTResponseMessage: Codable {
    public static let id = String(describing: Self.self)
    public let __id = Self.id
    public var prose: String
    public var code: String
}
