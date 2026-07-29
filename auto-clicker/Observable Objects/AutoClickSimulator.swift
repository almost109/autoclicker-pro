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

final class AutoClickSimulator: ObservableObject {
    static let shared: AutoClickSimulator = .init()
    private init() {}

    private static let clickTimerLeeway: DispatchTimeInterval = .milliseconds(1)

    @Published private(set) var isAutoClicking = false

    private var duration: Duration = .milliseconds
    private var interval: Int = DEFAULT_PRESS_INTERVAL
    private var pressesPerIteration: Int = DEFAULT_REPEAT_AMOUNT
    private var remainingIterations = 0
    private var input = Input()

    private var clickTimer: DispatchSourceTimer?
    private var nextClickDeadline: DispatchTime?
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

        MenuBarService.updateExecutionState(isRunning: true)

        MenuBarService.changeImageColour(newColor: .systemBlue)

        self.activity = ProcessInfo.processInfo.beginActivity(.autoClicking)

        self.duration = Defaults[.autoClickerState].pressIntervalDuration
        self.updateInterval()
        self.input = Defaults[.autoClickerState].pressInput
        self.pressesPerIteration = Defaults[.autoClickerState].pressAmount
        self.remainingIterations = Defaults[.autoClickerState].repeatAmount
        LoggerService.autoClickState(
            isActive: self.isAutoClicking,
            remainingIterations: self.remainingIterations
        )

        let timeInterval = self.duration.asTimeInterval(interval: self.interval)
        let now = Date()
        let intervalsUntilFinalClick = immediateFirstClick
            ? max(0, self.remainingIterations - 1)
            : self.remainingIterations
        let finalClickAt = Date(
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

        let nextClickAt = self.startClickTimer(after: timeInterval)

        if Defaults[.mouseStopOnMove] {
            self.initialMousePosition = nil
            self.mouseDeltaThreshold = CGFloat(Defaults[.mouseDeltaThreshold])
            startMouseMonitoring()
        }

        if Defaults[.notifyOnStart] {
            NotificationService.scheduleNotification(title: "Started", date: nextClickAt)
        }

        if Defaults[.notifyOnFinish] {
            NotificationService.scheduleNotification(title: "Finished", date: finalClickAt)
        }
    }

    func stop(triggeredByMouseMovement: Bool = false) {
        let wasAutoClicking = self.isAutoClicking
        self.isAutoClicking = false
        if wasAutoClicking {
            LoggerService.autoClickState(
                isActive: self.isAutoClicking,
                remainingIterations: self.remainingIterations
            )
        }

        Self.removeMonitor(&self.monitorObject)

        MenuBarService.updateExecutionState(isRunning: false)

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
        Self.removeMonitor(&self.startMonitorObject)

        self.initialMousePosition = nil
        self.mouseDeltaThreshold = CGFloat(Defaults[.mouseDeltaThreshold])

        self.startMonitorObject = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.mouseMovedForStart(event)
        }
    }

    func stopMouseStartMonitoring() {
        Self.removeMonitor(&self.startMonitorObject)
    }

    private func tick() {
        guard self.isAutoClicking,
              let currentDeadline = self.nextClickDeadline else {
            return
        }

        self.remainingIterations -= 1

        let actualExecutionTime = TimingDiagnostics.isEnabled
            ? DispatchTime.now()
            : nil
        self.press()

        if self.remainingIterations <= 0 {
            self.stop()
            TimingDiagnostics.record(
                scheduled: currentDeadline,
                actual: actualExecutionTime
            )
            return
        }

        // Update interval if in range mode
        self.updateInterval()

        let timeInterval = self.duration.asTimeInterval(interval: self.interval)
        self.scheduleNextClick(at: currentDeadline + timeInterval)
        TimingDiagnostics.record(
            scheduled: currentDeadline,
            actual: actualExecutionTime
        )
    }

    private func updateInterval() {
        let intervalMode = Defaults[.autoClickerState].intervalMode
        if intervalMode == .rangeInterval {
            let first = Defaults[.autoClickerState].pressIntervalMin ?? DEFAULT_PRESS_INTERVAL_MIN
            let second = Defaults[.autoClickerState].pressIntervalMax ?? DEFAULT_PRESS_INTERVAL_MAX
            self.interval = Int.random(in: min(first, second)...max(first, second))
        } else {
            self.interval = Defaults[.autoClickerState].pressInterval
        }
    }

    private func startClickTimer(after timeInterval: TimeInterval) -> Date {
        let referenceDeadline = DispatchTime.now()
        let firstDeadline = referenceDeadline + timeInterval
        let firstClickAt = Date().addingTimeInterval(timeInterval)

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.setEventHandler { [weak self] in
            self?.tick()
        }
        self.clickTimer = timer
        self.scheduleNextClick(at: firstDeadline)
        timer.resume()

        return firstClickAt
    }

    private func scheduleNextClick(at deadline: DispatchTime) {
        self.nextClickDeadline = deadline
        self.clickTimer?.schedule(deadline: deadline, leeway: Self.clickTimerLeeway)
    }

    private func cancelClickTimer() {
        self.clickTimer?.cancel()
        self.clickTimer = nil
        self.nextClickDeadline = nil
    }

    private func startMouseMonitoring() {
        self.monitorObject = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.mouseMoved(event)
        }
    }

    private func mouseMoved(_ event: NSEvent) {
        if self.hasExceededMouseMovementThreshold(event) {
            self.stop(triggeredByMouseMovement: true)
        }
    }

    private func mouseMovedForStart(_ event: NSEvent) {
        if self.hasExceededMouseMovementThreshold(event) {
            self.stopMouseStartMonitoring()
            self.start()
        }
    }

    private func hasExceededMouseMovementThreshold(_ event: NSEvent) -> Bool {
        let position = event.locationInWindow
        guard let initialPosition = self.initialMousePosition else {
            self.initialMousePosition = position
            return false
        }

        let deltaX = position.x - initialPosition.x
        let deltaY = position.y - initialPosition.y
        return hypot(deltaX, deltaY) > self.mouseDeltaThreshold
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
        guard let screen = NSScreen.screens.first else {
            return []
        }

        let mouseX = self.mouseLocation.x
        let mouseY = screen.frame.height - self.mouseLocation.y

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

        while completedPressesThisAction < self.pressesPerIteration {
            for event in pressEvents {
                event.post(tap: .cghidEventTap)

                LoggerService.simPress(input: self.input, location: event.location)
            }

            completedPressesThisAction += 1
        }
    }

    private static func removeMonitor(_ monitor: inout Any?) {
        guard let monitorToken = monitor else {
            return
        }
        NSEvent.removeMonitor(monitorToken)
        monitor = nil
    }
}
