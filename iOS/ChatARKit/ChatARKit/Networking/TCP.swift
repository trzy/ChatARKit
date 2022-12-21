//
//  TCP.swift
//  ChatARKit
//
//  Implementation of TCP connections.
//
//  Created by Bart Trzynadlowski on 9/19/22.
//

import Foundation
import Network

public class TCPConnection: Connection {
    private let _connection: NWConnection
    private weak var _delegate: ConnectionDelegate?
    private let _queue: DispatchQueue

    // For inbound connections (server accept)
    fileprivate init(_ connection: NWConnection, delegate: ConnectionDelegate, queue: DispatchQueue) {
        _connection = connection
        _delegate = delegate
        _queue = queue
        
        super.init()
    
        connection.stateUpdateHandler = { [weak self] in
            self?.onState($0)
        }
        connection.start(queue: _queue)
    }
    
    // Outbound connections
    public init?(host: String, port: UInt16, delegate: ConnectionDelegate, queue: DispatchQueue) {
        _delegate = delegate
        _queue = queue
        
        let host = NWEndpoint.Host(host)
        guard let port = NWEndpoint.Port(rawValue: port) else {
            return nil
        }
        
        let options = NWProtocolTCP.Options()
        options.noDelay = true
        let params = NWParameters(tls: nil, tcp: options)
        _connection = NWConnection(host: host, port: port, using: params)
        
        super.init()
        
        print("[TCPConnection] Connecting to \(self)...")
        
        _connection.stateUpdateHandler = { [weak self] in
            self?.onState($0)
        }
        _connection.start(queue: _queue)
    }
    
    override public var queue: DispatchQueue {
        return _queue
    }
    
    override public var isReliable: Bool {
        return true
    }
    
    override public var description: String {
        return "tcp://\(_connection.endpoint)"
    }
    
    override public func send(_ data: Data) {
        _connection.send(content: data, completion: .idempotent)
    }
    
    override public func send(_ data: Data, completion: ((NWError?) -> Void)?) {
        _connection.send(content: data, completion: .contentProcessed(completion ?? { _ in }))
    }
    
    override public func close() {
        _connection.forceCancel()
    }
    
    private func onState(_ newState: NWConnection.State) {
        switch (newState) {
        case .ready:
            print("[TCPConnection] Connection \(self) established")
            self._queue.async { [weak self] in
                if let self = self {
                    self._delegate?.onConnect(from: self)
                }
            }
            receiveMessageHeader()
        
        case .cancelled:
            _queue.async {
                self._delegate?.onDisconnect(from: self)
            }
            
        case .failed(let error):
            print("[TCPConnection] Error: Connection \(self) failed: \(error.localizedDescription)")
            _connection.cancel()
            
        case .waiting(let error):
            print("[TCPConnection] Error: Connection \(self) could not be established: \(error.localizedDescription)")
            _connection.cancel()
            
        default:
            // Don't care
            break
        }
    }
    
    private func receiveMessageHeader() {
        let headerSize = 5  // header is: 4 bytes total payload length plus 'J' byte
        _connection.receive(minimumIncompleteLength: headerSize, maximumLength: headerSize) { [weak self] (content: Data?, _: NWConnection.ContentContext?, _: Bool, error: NWError?) in
            guard let self = self else { return }
            
            var bodySize: Int = 0
            if let content = content {
                // 'J' must follow the length
                if content[4] != 0x4a {
                    print("[TCPConnection] Received message with invalid header")
                    self._connection.cancel()
                    return
                }
                
                // Extract total message length
                let totalSize = UInt32(littleEndian: content.withUnsafeBytes { $0.load(as: UInt32.self) })
                if totalSize < 5 || totalSize > Int.max {
                    // Size must at least be equal to header
                    print("[TCPConnection[ Received message with invalid header")
                    self._connection.cancel()
                    return
                }
                
                bodySize = Int(totalSize - 5)
            }

            if let error = error {
                print("[TCPConnection] Error: \(error.localizedDescription)")
                self._connection.cancel()
            } else {
                self.receiveMessageBody(bodySize: bodySize)
            }
        }
    }
    
    private func receiveMessageBody(bodySize: Int) {
        // 0-length messages are a special case
        if bodySize == 0 {
            // Always succeeds. Because message ID is contained in body, we have nothing to notify
            // delegate of and may simply proceed to the next message
            receiveMessageHeader()
            return
        }
        
        // Message has body
        _connection.receive(minimumIncompleteLength: bodySize, maximumLength: bodySize) { [weak self] (content: Data?, _: NWConnection.ContentContext?, _: Bool, error: NWError?) in
            guard let self = self else { return }
            
            if let content = content {
                // Pass to delegate
                self._queue.async { [weak self] in
                    if let self = self, let id = self.decodeMessageID(data: content) {
                        self._delegate?.onMessageReceived(from: self, id: id, data: content)
                    }
                }
            }

            if error == nil {
                // Next message
                self.receiveMessageHeader()
            }
        }
    }
    
    private struct RequiredFields: Decodable {
        public let __id: String
    }
    
    private func decodeMessageID(data: Data) -> String? {
        let decoder = JSONDecoder()
        do {
            let requiredFields = try decoder.decode(RequiredFields.self, from: data)
            return requiredFields.__id
        }
        catch {
            return nil
        }
    }
}
