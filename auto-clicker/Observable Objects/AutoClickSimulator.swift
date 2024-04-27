//
//  AutoClickSimulator.swift
//  auto-clicker
//
//  Created by Ben Tindall on 12/05/2021.
//

import Foundation
import Combine
import SwiftUI
import Defaults
import UserNotifications

final class AutoClickSimulator: ObservableObject {
    static var shared: AutoClickSimulator = .init()
    private init() {}

    @Published var isAutoClicking = false

    @Published var remainingInterations: Int = 0

    @Published var nextClickAt: Date = .init()
    @Published var finalClickAt: Date = .init()

    // Said weird behaviour is still occuring in 12.2.1, thus having these defined in here instead of Published, I hate this though so much
    private var duration: Duration = .milliseconds
    private var interval: Int = DEFAULT_PRESS_INTERVAL
    private var amountOfPresses: Int = DEFAULT_REPEAT_AMOUNT
    private var input = Input()
    
    private var nextX: CGFloat = CGFloat.zero
    private var nextY: CGFloat = CGFloat.zero
    private var iter: Int = 0
    private var isDown: Bool = true
    private var leftCells: Int = DEFAULT_LEFT_CELLS
    private var rightCells: Int = DEFAULT_RIGHT_CELLS

    private var timer: Timer?
    private var mouseLocation: NSPoint { NSEvent.mouseLocation }
    private var activity: Cancellable?

    func start() {
        startTimer(selector: #selector(self.tick))
    }
    
    func sow() {
        startTimer(selector: #selector(self.sowTick))
    }
    
    private func startTimer(selector: Selector) {
        self.isAutoClicking = true

        if let startMenuItem = MenuBarService.startMenuItem {
            startMenuItem.isEnabled = false
        }
        
        if let rectMenuItem = MenuBarService.sowMenuItem {
            rectMenuItem.isEnabled = false
        }

        if let stopMenuItem = MenuBarService.stopMenuItem {
            stopMenuItem.isEnabled = true
        }

        MenuBarService.changeImageColour(newColor: .systemBlue)

        self.activity = ProcessInfo.processInfo.beginActivity(.autoClicking)

        self.duration = Defaults[.autoClickerState].pressIntervalDuration
        self.interval = Defaults[.autoClickerState].pressInterval
        self.input = Defaults[.autoClickerState].pressInput
        self.amountOfPresses = Defaults[.autoClickerState].pressAmount
        self.remainingInterations = Defaults[.autoClickerState].repeatAmount
        
        self.nextX = self.mouseLocation.x
        self.nextY = NSScreen.main!.frame.height - self.mouseLocation.y
        self.iter = 0
        self.isDown = true
        self.leftCells = Defaults[.autoClickerState].leftCells
        self.rightCells = Defaults[.autoClickerState].rightCells

        self.finalClickAt = .init(timeInterval: self.duration.asTimeInterval(interval: self.interval * self.remainingInterations), since: .init())

        let timeInterval = self.duration.asTimeInterval(interval: self.interval)
        self.nextClickAt = .init(timeInterval: timeInterval, since: .init())
        self.timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                          target: self,
                                          selector: selector,
                                          userInfo: nil,
                                          repeats: true)

        if Defaults[.notifyOnStart] {
            NotificationService.scheduleNotification(title: "Started", date: self.nextClickAt)
        }

        if Defaults[.notifyOnFinish] {
            NotificationService.scheduleNotification(title: "Finished", date: self.finalClickAt)
        }
    }

    func stop() {
        self.isAutoClicking = false

        if let startMenuItem = MenuBarService.startMenuItem {
            startMenuItem.isEnabled = true
        }
        
        if let rectMenuItem = MenuBarService.sowMenuItem {
            rectMenuItem.isEnabled = true
        }

        if let stopMenuItem = MenuBarService.stopMenuItem {
            stopMenuItem.isEnabled = false
        }

        MenuBarService.resetImage()

        self.activity?.cancel()
        self.activity = nil

        // Force zero, as the user could stop the timer early
        self.remainingInterations = 0

        if let timer = self.timer {
            timer.invalidate()
        }

        NotificationService.removePendingNotifications()
    }

    @objc private func tick() {
        self.remainingInterations -= 1

        self.press()

        self.nextClickAt = .init(timeInterval: self.duration.asTimeInterval(interval: self.interval), since: .init())

        if self.remainingInterations <= 0 {
            self.stop()
        }
    }
    
    @objc private func sowTick() {
        self.iter += 1
        self.pressSow(mouseX: self.nextX, mouseY: self.nextY)

        if self.iter % leftCells == 0 {
            self.nextX += CGFloat(MOUSE_DX)
            self.nextY += CGFloat(MOUSE_DY)
            self.isDown = !self.isDown
        }
        else if self.isDown {
            self.nextX += CGFloat(-MOUSE_DX)
            self.nextY += CGFloat(MOUSE_DY)
        }
        else {
            self.nextX += CGFloat(MOUSE_DX)
            self.nextY += CGFloat(-MOUSE_DY)
        }
        
        self.nextClickAt = .init(timeInterval: self.duration.asTimeInterval(interval: self.interval), since: .init())

        if self.iter >= self.leftCells * self.rightCells {
            self.stop()
        }
    }

    private let mouseDownEventMap: [NSEvent.EventType: CGEventType] = [
        .leftMouseDown: .leftMouseDown,
        .leftMouseUp: .leftMouseDown,
        .rightMouseDown: .rightMouseDown,
        .rightMouseUp: .rightMouseDown,
        .otherMouseDown: .otherMouseDown,
        .otherMouseUp: .otherMouseDown
    ]

    private let mouseUpEventMap: [NSEvent.EventType: CGEventType] = [
        .leftMouseDown: .leftMouseUp,
        .leftMouseUp: .leftMouseUp,
        .rightMouseDown: .rightMouseUp,
        .rightMouseUp: .rightMouseUp,
        .otherMouseDown: .otherMouseUp,
        .otherMouseUp: .otherMouseUp
    ]

    private let mouseButtonEventMap: [NSEvent.EventType: CGMouseButton] = [
        .leftMouseDown: .left,
        .leftMouseUp: .left,
        .rightMouseDown: .right,
        .rightMouseUp: .right,
        .otherMouseDown: .center,
        .otherMouseUp: .center
    ]

    private func generateMouseClickEvents(source: CGEventSource?) -> [CGEvent?] {
        let mouseX = self.mouseLocation.x
        let mouseY = NSScreen.main!.frame.height - self.mouseLocation.y

        let clickingAtPoint = CGPoint(x: mouseX, y: mouseY)

        let mouseDownType: CGEventType = mouseDownEventMap[self.input.type]!
        let mouseUpType: CGEventType = mouseUpEventMap[self.input.type]!
        let mouseButton: CGMouseButton = mouseButtonEventMap[self.input.type]!

        let mouseDown = CGEvent(mouseEventSource: source,
                                mouseType: mouseDownType,
                                mouseCursorPosition: clickingAtPoint,
                                mouseButton: mouseButton)

        let mouseUp = CGEvent(mouseEventSource: source,
                              mouseType: mouseUpType,
                              mouseCursorPosition: clickingAtPoint,
                              mouseButton: mouseButton)

        return [mouseDown, mouseUp]
    }

    private func generateKeyPressEvents(source: CGEventSource?) -> [CGEvent?] {
        let keyDown = CGEvent(keyboardEventSource: source,
                              virtualKey: CGKeyCode(self.input.keyCode),
                              keyDown: true)

        let keyUp = CGEvent(keyboardEventSource: source,
                            virtualKey: CGKeyCode(self.input.keyCode),
                            keyDown: false)

        if self.input.modifiers.contains(.command) {
            keyDown?.flags = CGEventFlags.maskCommand
            keyUp?.flags = CGEventFlags.maskCommand
        }

        if self.input.modifiers.contains(.control) {
            keyDown?.flags = CGEventFlags.maskControl
            keyUp?.flags = CGEventFlags.maskControl
        }

        if self.input.modifiers.contains(.option) {
            keyDown?.flags = CGEventFlags.maskAlternate
            keyUp?.flags = CGEventFlags.maskAlternate
        }

        if self.input.modifiers.contains(.shift) {
            keyDown?.flags = CGEventFlags.maskShift
            keyUp?.flags = CGEventFlags.maskShift
        }

        return [keyDown, keyUp]
    }

    private func press() {
        let source: CGEventSource? = CGEventSource(stateID: .hidSystemState)

        let pressEvents = self.input.isMouseInput
                            ? generateMouseClickEvents(source: source)
                            : generateKeyPressEvents(source: source)

        var completedPressesThisAction = 0

        while completedPressesThisAction < self.amountOfPresses {
            for event in pressEvents {
                event!.post(tap: .cghidEventTap)

                LoggerService.simPress(input: self.input, location: event!.location)
            }

            completedPressesThisAction += 1
        }
    }
    
    private func pressSow(mouseX: CGFloat, mouseY: CGFloat) {
        let source: CGEventSource? = CGEventSource(stateID: .hidSystemState)
        let clickingAtPoint = CGPoint(x: mouseX, y: mouseY)

        let mouseDownType: CGEventType = .leftMouseDown
        let mouseUpType: CGEventType = .leftMouseUp
        let mouseButton: CGMouseButton = .left
        
        let mouseMoved = CGEvent(mouseEventSource: source,
                                 mouseType: .mouseMoved,
                                 mouseCursorPosition: clickingAtPoint,
                                 mouseButton: mouseButton)

        let mouseDown = CGEvent(mouseEventSource: source,
                                mouseType: mouseDownType,
                                mouseCursorPosition: clickingAtPoint,
                                mouseButton: mouseButton)

        let mouseUp = CGEvent(mouseEventSource: source,
                              mouseType: mouseUpType,
                              mouseCursorPosition: clickingAtPoint,
                              mouseButton: mouseButton)

        mouseMoved!.post(tap: .cghidEventTap)
        mouseDown!.post(tap: .cghidEventTap)
        mouseUp!.post(tap: .cghidEventTap)
    }
}
