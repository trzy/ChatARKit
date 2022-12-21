//
//  Connection.swift
//  ChatARKit
//
//  Connection definition and delegate protocol. Sends and receives JSON-encoded messages with the
//  following wire format:
//
//  Offset
//  ------
//  0       4       Total message size, including this header. Little endian.
//  4       1       The ASCII character 'J'.
//  5       N       N bytes of UTF-8-encoded JSON payload, where N is the total
//                  message size at offset 0 minus 5. The JSON payload must have
//                  a field named "__id" that defines the message ID.
//
//  Created by Bart Trzynadlowski on 9/19/22.
//

import Foundation
import Network

public protocol ConnectionDelegate: AnyObject {
    func onMessageReceived(from connection: Connection, id: String, data: Data)
    func onConnect(from connection: Connection)
    func onDisconnect(from connection: Connection)
}

extension ConnectionDelegate {
    public func onMessageReceived(from connection: Connection, id: String, data: Data) {
    }

    public func onConnect(from connection: Connection) {
    }
    
    public func onDisconnect(from connection: Connection) {
    }
}

public class Connection: Hashable, CustomStringConvertible {
    internal init() {
    }
    
    public var queue: DispatchQueue {
        return .main
    }
    
    public var isReliable: Bool {
        return true
    }
    
    public var description: String {
        return "null://null"
    }
    
    public func send(_ data: Data) {
    }
    
    public func send(_ data: Data, completion: ((NWError?) -> Void)?) {
        completion?(nil)
    }

    public final func send(_ message: Codable, completion: ((NWError?) -> Void)? = nil) {
        if let data = Self.serialize(message) {
            send(data, completion: completion)
        }
        else {
            print("[Connection] Error: Unable to encode message")
        }
    }
    
    public func close() {
    }

    public static func serialize(_ message: Codable) -> Data? {
        let encoder = JSONEncoder()
        do {
            let payload = try encoder.encode(message)
            if var totalSize = UInt32(exactly: 5 + payload.count) {
                var data = Data(capacity: Int(totalSize))
                withUnsafePointer(to: &totalSize) {
                    data.append(UnsafeBufferPointer(start: $0, count: 1))
                }
                data.append(0x4a)       // 'J'
                data.append(payload)
                return data
            }
        }
        catch {
        }
        return nil
    }
    
    public static func == (lhs: Connection, rhs: Connection) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
}
