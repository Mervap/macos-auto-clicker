//
//  FieldConstants.swift
//  auto-clicker
//
//  Created by Ben Tindall on 26/02/2022.
//

// swiftlint:disable identifier_name

import Foundation

// MARK: - Press Interval

let MIN_PRESS_INTERVAL: Int = 1
let MAX_PRESS_INTERVAL: Int = 100_000_000

let DEFAULT_PRESS_INTERVAL: Int = 50

// MARK: - Press Amount

let MIN_PRESS_AMOUNT: Int = 1
let MAX_PRESS_AMOUNT: Int = 100_000_000

let DEFAULT_PRESS_AMOUNT: Int = 1

// MARK: - Amount of times to repeat all actions

let MIN_REPEAT_AMOUNT: Int = 1
let MAX_REPEAT_AMOUNT: Int = 100_000_000

let DEFAULT_REPEAT_AMOUNT: Int = 100

// MARK: - Start Delay

let MIN_START_DELAY: Int = 0
let MAX_START_DELAY: Int = 100_000_000

let DEFAULT_START_DELAY: Int = 1

// MARK: - Mouse coord diffs
let MOUSE_DX: Int = 54
let MOUSE_DY: Int = 27

// MARK: - Cells

let DEFAULT_LEFT_CELLS = 8
let DEFAULT_RIGHT_CELLS = 2
let MIN_CELLS: Int = 0
let MAX_CELLS: Int = 32
