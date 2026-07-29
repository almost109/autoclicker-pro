//
//  LoggerService.swift
//  auto-clicker
//
//  Created by Ben Tindall on 12/04/2022.
//

import AppKit
import Foundation

enum LoggerService {
    private static func log(file: String, function: String, _ lines: [String]) {
        #if DEBUG
        let timestampMilliseconds = Date().timeIntervalSince1970 * 1_000
        let thread = Thread.isMainThread
            ? "main"
            : Thread.current.name ?? String(describing: Thread.current)
        NSLog(">~  Who: \(file) ~ \(function)")
        NSLog(">~ When: \(String(format: "%.3f", timestampMilliseconds)) ms | Thread: \(thread)")

        for line in lines {
            NSLog(">~ What: \(line)")
        }
        #endif
    }

    static func accessibilityCheck(
        origin: AccessibilityCheckOrigin,
        caller: String,
        result: Bool,
        previousPublishedValue: Bool,
        newPublishedValue: Bool,
        confirmationPendingBefore: Bool,
        confirmationPendingAfter: Bool,
        callingFile: String = #fileID,
        callingFunction: String = #function
    ) {
        self.log(file: callingFile, function: callingFunction, [
            "Accessibility check origin: \(origin.rawValue)",
            "Caller: \(caller)",
            "AX result: \(result)",
            "Previous isTrusted: \(previousPublishedValue)",
            "New published isTrusted: \(newPublishedValue)",
            "Confirmation pending before: \(confirmationPendingBefore)",
            "Confirmation pending after: \(confirmationPendingAfter)"
        ])
    }

    static func accessibilityTransitionIfNeeded(
        from previousValue: Bool,
        to newValue: Bool,
        origin: AccessibilityCheckOrigin,
        caller: String,
        callingFile: String = #fileID,
        callingFunction: String = #function
    ) {
        guard previousValue != newValue else {
            return
        }

        self.log(file: callingFile, function: callingFunction, [
            "Accessibility transition: \(previousValue) -> \(newValue)",
            "Origin: \(origin.rawValue)",
            "Caller: \(caller)"
        ])
    }

    static func accessibilityConfirmationTimer(
        event: String,
        origin: AccessibilityCheckOrigin,
        caller: String,
        callingFile: String = #fileID,
        callingFunction: String = #function
    ) {
        self.log(file: callingFile, function: callingFunction, [
            "Accessibility confirmation timer: \(event)",
            "Origin: \(origin.rawValue)",
            "Caller: \(caller)"
        ])
    }

    static func permissionsViewPresented(
        isTrusted: Bool,
        callingFile: String = #fileID,
        callingFunction: String = #function
    ) {
        self.log(file: callingFile, function: callingFunction, [
            "PermissionsView presented",
            "Published isTrusted: \(isTrusted)"
        ])
    }

    static func autoClickState(
        isActive: Bool,
        remainingIterations: Int,
        callingFile: String = #fileID,
        callingFunction: String = #function
    ) {
        self.log(file: callingFile, function: callingFunction, [
            "AutoClickSimulator active: \(isActive)",
            "Remaining iterations: \(remainingIterations)"
        ])
    }

    static func permissionState(enabled: Bool, callingFile: String = #fileID, callingFunction: String = #function) {
        LoggerService.log(file: callingFile, function: callingFunction, [
            "App permissions \(enabled ? "" : "not ")granted"
        ])
    }

    static func notificationState(enabled: Bool, callingFile: String = #fileID, callingFunction: String = #function) {
        LoggerService.log(file: callingFile, function: callingFunction, [
            "Notification permissions \(enabled ? "" : "not ")granted"
        ])
    }

    static func logNotification(title: String, body: String? = nil, date: Date, interval: TimeInterval, callingFile: String = #fileID, callingFunction: String = #function) {
        LoggerService.log(file: callingFile, function: callingFunction, [
            "Title: \(title)",
            "Body: \(String(describing: body))",
            "Date: \(date)",
            "Interval: \(interval)",
            "Current Date: \(Date())"
        ])
    }

    static func permissionTrustedState(callingFile: String = #fileID, callingFunction: String = #function) {
        let permissionsService = PermissionsService.shared
        let previousPublishedValue = permissionsService.isTrusted
        let confirmationPending = permissionsService.isRevocationConfirmationPending
        let isCurrentlyTrusted = AXIsProcessTrusted()
        self.accessibilityCheck(
            origin: .other,
            caller: callingFunction,
            result: isCurrentlyTrusted,
            previousPublishedValue: previousPublishedValue,
            newPublishedValue: previousPublishedValue,
            confirmationPendingBefore: confirmationPending,
            confirmationPendingAfter: confirmationPending,
            callingFile: callingFile,
            callingFunction: callingFunction
        )
    }

    static func pressInputEvent(event: NSEvent, callingFile: String = #fileID, callingFunction: String = #function) {
        LoggerService.log(file: callingFile, function: callingFunction, [
            "Pressed: \(event.inputString)"
        ])
    }

    static func simPress(input: Input, location: CGPoint, callingFile: String = #fileID, callingFunction: String = #function) {
        LoggerService.log(file: callingFile, function: callingFunction, [
            "AutoClickSimulator actively clicking: true",
            "Key: \(input.readable)",
            "Mod: \(input.modifiers)",
            "Loc. X: \(location.x)",
            "Loc. Y: \(location.y)"
        ])
    }

    static func sntpSuccess(
        server: String,
        offset: TimeInterval,
        roundTripDelay: TimeInterval,
        callingFile: String = #fileID,
        callingFunction: String = #function
    ) {
        LoggerService.log(file: callingFile, function: callingFunction, [
            "SNTP synchronization succeeded",
            "Server: \(server)",
            "Clock offset: \(offset) seconds",
            "Round trip delay: \(roundTripDelay) seconds"
        ])
    }

    static func sntpFailure(
        server: String,
        error: Error,
        callingFile: String = #fileID,
        callingFunction: String = #function
    ) {
        LoggerService.log(file: callingFile, function: callingFunction, [
            "SNTP synchronization failed",
            "Server: \(server)",
            "Error: \(error.localizedDescription)"
        ])
    }
}
