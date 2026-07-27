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
    static let shared: AutoClickSimulator = .init()
    private init() {}

    private static let clickTimerLeeway: DispatchTimeInterval = .milliseconds(1)

    @Published private(set) var isAutoClicking = false
    @Published private(set) var remainingIterations: Int = 0
    @Published private(set) var nextClickAt: Date = .init()
    @Published private(set) var finalClickAt: Date = .init()

    // Said weird behaviour is still occuring in 12.2.1, thus having these defined in here instead of Published, I hate this though so much
    private var duration: Duration = .milliseconds
    private var interval: Int = DEFAULT_PRESS_INTERVAL
    private var amountOfPresses: Int = DEFAULT_REPEAT_AMOUNT
    private var input = Input()

    private var clickTimer: DispatchSourceTimer?
    private var nextClickDeadline: DispatchTime?
    private var scheduleReferenceDate: Date?
    private var scheduleReferenceDeadline: DispatchTime?
    private var mouseLocation: NSPoint { NSEvent.mouseLocation }
    private var activity: Cancellable?

    private var monitorObject: Any?
    private var startMonitorObject: Any?
    private var initialMousePosition: NSPoint?
    private var mouseDeltaThreshold: CGFloat = 0.0

    func start(immediateFirstClick: Bool = false) {
        self.isAutoClicking = true

        // Stop mouse start monitoring if it's running
        self.stopMouseStartMonitoring()

        self.updateMenuState(isClicking: true)

        MenuBarService.changeImageColour(newColor: .systemBlue)

        self.activity = ProcessInfo.processInfo.beginActivity(.autoClicking)

        self.duration = Defaults[.autoClickerState].pressIntervalDuration
        self.updateInterval()
        self.input = Defaults[.autoClickerState].pressInput
        self.amountOfPresses = Defaults[.autoClickerState].pressAmount
        self.remainingIterations = Defaults[.autoClickerState].repeatAmount

        let timeInterval = self.duration.asTimeInterval(interval: self.interval)
        let now = Date()
        self.nextClickAt = now
        let intervalsUntilFinalClick = immediateFirstClick
            ? max(0, self.remainingIterations - 1)
            : self.remainingIterations
        self.finalClickAt = .init(
            timeInterval: self.duration.asTimeInterval(interval: self.interval * intervalsUntilFinalClick),
            since: now
        )

        if immediateFirstClick {
            self.remainingIterations -= 1
            self.press()

            if self.remainingIterations <= 0 {
                self.stop()
                return
            }
        }

        self.startClickTimer(after: timeInterval)

        if Defaults[.mouseStopOnMove] {
            self.initialMousePosition = nil
            self.mouseDeltaThreshold = CGFloat(Defaults[.mouseDeltaThreshold])
            startMouseMonitoring()
        }

        if Defaults[.notifyOnStart] {
            NotificationService.scheduleNotification(title: "Started", date: self.nextClickAt)
        }

        if Defaults[.notifyOnFinish] {
            NotificationService.scheduleNotification(title: "Finished", date: self.finalClickAt)
        }
    }

    func stop(triggeredByMouseMovement: Bool = false) {
        self.isAutoClicking = false

        if let monitorObject = self.monitorObject {
            NSEvent.removeMonitor(monitorObject)
            self.monitorObject = nil
        }

        self.updateMenuState(isClicking: false)

        MenuBarService.resetImage()

        self.activity?.cancel()
        self.activity = nil

        // Force zero, as the user could stop the timer early
        self.remainingIterations = 0

        self.cancelClickTimer()

        NotificationService.removePendingNotifications()

        if triggeredByMouseMovement {
            if Defaults[.notifyOnFinish] {
                NotificationService.scheduleNotification(title: "Finished", date: Date())
            }
        }

        // Re-enable mouse start monitoring if it was enabled
        if Defaults[.mouseStartOnMove] && !self.isAutoClicking {
            self.startMouseStartMonitoring()
        }
    }

    func startMouseStartMonitoring() {
        // Stop any existing monitoring
        if let startMonitorObject = self.startMonitorObject {
            NSEvent.removeMonitor(startMonitorObject)
            self.startMonitorObject = nil
        }

        self.initialMousePosition = nil
        self.mouseDeltaThreshold = CGFloat(Defaults[.mouseDeltaThreshold])

        self.startMonitorObject = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.mouseMovedForStart(event)
        }
    }

    func stopMouseStartMonitoring() {
        if let startMonitorObject = self.startMonitorObject {
            NSEvent.removeMonitor(startMonitorObject)
            self.startMonitorObject = nil
        }
    }

    private func tick() {
        guard self.isAutoClicking,
              let currentDeadline = self.nextClickDeadline else {
            return
        }

        self.remainingIterations -= 1

        self.press()

        if self.remainingIterations <= 0 {
            self.stop()
            return
        }

        // Update interval if in range mode
        self.updateInterval()

        let timeInterval = self.duration.asTimeInterval(interval: self.interval)
        self.scheduleNextClick(at: currentDeadline + timeInterval)
    }

    private func updateInterval() {
        let intervalMode = Defaults[.autoClickerState].intervalMode
        if intervalMode == .rangeInterval {
            let min = Defaults[.autoClickerState].pressIntervalMin ?? DEFAULT_PRESS_INTERVAL_MIN
            let max = Defaults[.autoClickerState].pressIntervalMax ?? DEFAULT_PRESS_INTERVAL_MAX
            self.interval = Int.random(in: min...max)
        } else {
            self.interval = Defaults[.autoClickerState].pressInterval
        }
    }

    private func startClickTimer(after timeInterval: TimeInterval) {
        let referenceDeadline = DispatchTime.now()
        self.scheduleReferenceDeadline = referenceDeadline
        self.scheduleReferenceDate = Date()

        let firstDeadline = referenceDeadline + timeInterval
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.setEventHandler { [weak self] in
            self?.tick()
        }
        self.clickTimer = timer
        self.scheduleNextClick(at: firstDeadline)
        timer.resume()
    }

    private func scheduleNextClick(at deadline: DispatchTime) {
        self.nextClickDeadline = deadline
        if let scheduledDate = self.date(for: deadline) {
            self.nextClickAt = scheduledDate
        }
        self.clickTimer?.schedule(deadline: deadline, leeway: Self.clickTimerLeeway)
    }

    private func date(for deadline: DispatchTime) -> Date? {
        guard let referenceDate = self.scheduleReferenceDate,
              let referenceDeadline = self.scheduleReferenceDeadline else {
            return nil
        }

        let referenceNanoseconds = referenceDeadline.uptimeNanoseconds
        let deadlineNanoseconds = deadline.uptimeNanoseconds
        let offsetNanoseconds = deadlineNanoseconds >= referenceNanoseconds
            ? deadlineNanoseconds - referenceNanoseconds
            : 0

        return referenceDate.addingTimeInterval(TimeInterval(offsetNanoseconds) / 1_000_000_000)
    }

    private func cancelClickTimer() {
        self.clickTimer?.cancel()
        self.clickTimer = nil
        self.nextClickDeadline = nil
        self.scheduleReferenceDate = nil
        self.scheduleReferenceDeadline = nil
    }

    private func updateMenuState(isClicking: Bool) {
        MenuBarService.startMenuItem?.isEnabled = !isClicking
        MenuBarService.stopMenuItem?.isEnabled = isClicking
    }

    private func startMouseMonitoring() {
        self.monitorObject = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.mouseMoved(event)
        }
    }

    private func mouseMoved(_ event: NSEvent) {
        let position = event.locationInWindow
        if let initialPosition = self.initialMousePosition {
            let deltaX = position.x - initialPosition.x
            let deltaY = position.y - initialPosition.y
            let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
            if distance > mouseDeltaThreshold {
                self.stop(triggeredByMouseMovement: true)
            }
        } else {
            self.initialMousePosition = position
        }
    }

    private func mouseMovedForStart(_ event: NSEvent) {
        let position = event.locationInWindow
        if let initialPosition = self.initialMousePosition {
            let deltaX = position.x - initialPosition.x
            let deltaY = position.y - initialPosition.y
            let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
            if distance > mouseDeltaThreshold {
                // Stop monitoring and start the auto clicker
                self.stopMouseStartMonitoring()
                self.start()
            }
        } else {
            self.initialMousePosition = position
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

    private func generateMouseClickEvents(source: CGEventSource?) -> [CGEvent] {
        let mouseX = self.mouseLocation.x
        let mouseY = NSScreen.screens[0].frame.height - mouseLocation.y

        let clickingAtPoint = CGPoint(x: mouseX, y: mouseY)

        guard let mouseDownType = self.mouseDownEventMap[self.input.type],
              let mouseUpType = self.mouseUpEventMap[self.input.type],
              let mouseButton = self.mouseButtonEventMap[self.input.type],
              let mouseDown = CGEvent(
                mouseEventSource: source,
                mouseType: mouseDownType,
                mouseCursorPosition: clickingAtPoint,
                mouseButton: mouseButton
              ),
              let mouseUp = CGEvent(
                mouseEventSource: source,
                mouseType: mouseUpType,
                mouseCursorPosition: clickingAtPoint,
                mouseButton: mouseButton
              ) else {
            return []
        }

        return [mouseDown, mouseUp]
    }

    private func generateKeyPressEvents(source: CGEventSource?) -> [CGEvent] {
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

        return [keyDown, keyUp].compactMap { $0 }
    }

    private func press() {
        let source: CGEventSource? = CGEventSource(stateID: .hidSystemState)

        let pressEvents = self.input.isMouseInput
                            ? generateMouseClickEvents(source: source)
                            : generateKeyPressEvents(source: source)

        var completedPressesThisAction = 0

        while completedPressesThisAction < self.amountOfPresses {
            for event in pressEvents {
                event.post(tap: .cghidEventTap)

                LoggerService.simPress(input: self.input, location: event.location)
            }

            completedPressesThisAction += 1
        }
    }
}
