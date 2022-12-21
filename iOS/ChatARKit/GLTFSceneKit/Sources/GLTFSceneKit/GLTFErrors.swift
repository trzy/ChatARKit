//
//  GLTFErrors.swift
//  GLTFSceneKit
//
//  Created by magicien on 2017/08/18.
//  Copyright © 2017 DarkHorse. All rights reserved.
//

import Foundation

public enum GLTFUnarchiveError: Error {
    case DataInconsistent(String)
    case NotSupported(String)
    case Unknown(String)
}

extension GLTFUnarchiveError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .DataInconsistent(let message):
            return NSLocalizedString("DataInconsistent: " + message, comment: "")
        case .NotSupported(let message):
            return NSLocalizedString("NotSupported: " + message, comment: "")
        case .Unknown(let message):
            return NSLocalizedString(message, comment: "")
        }
    }
}

public enum GLTFArchiveError: Error {
    case Unknown(String)
}

extension GLTFArchiveError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .Unknown(let message):
            return NSLocalizedString(message, comment: "")
        }
    }
}
