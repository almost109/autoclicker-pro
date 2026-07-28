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
        NSLog(">~  Who: \(file) ~ \(function)")

        for line in lines {
            NSLog(">~ What: \(line)")
        }
        #endif
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
        LoggerService.log(file: callingFile, function: callingFunction, [
            "Is trusted: \(AXIsProcessTrusted())"
        ])
    }

    static func pressInputEvent(event: NSEvent, callingFile: String = #fileID, callingFunction: String = #function) {
        LoggerService.log(file: callingFile, function: callingFunction, [
            "Pressed: \(event.inputString)"
        ])
    }

    static func simPress(input: Input, location: CGPoint, callingFile: String = #fileID, callingFunction: String = #function) {
        LoggerService.log(file: callingFile, function: callingFunction, [
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
