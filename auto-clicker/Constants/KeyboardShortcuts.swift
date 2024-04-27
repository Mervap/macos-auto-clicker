//
//  KeyboardShortcuts.swift
//  auto-clicker
//
//  Created by Ben Tindall on 30/03/2022.
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let pressStartButton = Self("pressStartButton", default: .init(.s, modifiers: [.command, .option]))
    static let pressSowButton = Self("pressSowButton", default: .init(.r, modifiers: [.command, .option]))
    static let pressStopButton  = Self("pressStopButton", default: .init(.x, modifiers: [.command, .option]))
}
