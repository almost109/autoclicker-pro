//
//  PermissionsService.swift
//  auto-clicker
//
//  Created by Ben Tindall on 10/04/2022.
//

import Cocoa
import UserNotifications

final class PermissionsService: ObservableObject {
    static let shared = PermissionsService()

    @Published private(set) var isTrusted = AXIsProcessTrusted()

    private var pollingWorkItem: DispatchWorkItem?
    private var onTrusted: (() -> Void)?

    private init() {}

    @discardableResult
    func refreshAccessibilityPrivileges() -> Bool {
        let isCurrentlyTrusted = AXIsProcessTrusted()
        if self.isTrusted != isCurrentlyTrusted {
            self.isTrusted = isCurrentlyTrusted
        }

        if isCurrentlyTrusted {
            self.finishPolling()
        }

        return isCurrentlyTrusted
    }

    func pollAccessibilityPrivileges(onTrusted: @escaping () -> Void) {
        self.onTrusted = onTrusted
        guard !self.refreshAccessibilityPrivileges() else {
            return
        }

        self.schedulePermissionCheck()
    }

    func requestAccessibilityPrivilegesIfNeeded() {
        guard !self.refreshAccessibilityPrivileges() else {
            return
        }

        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        let enabled = AXIsProcessTrustedWithOptions(options)
        self.isTrusted = enabled
        LoggerService.permissionState(enabled: enabled)

        if enabled {
            self.finishPolling()
        }
    }

    private func schedulePermissionCheck() {
        guard self.pollingWorkItem == nil else {
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }

            self.pollingWorkItem = nil
            if !self.refreshAccessibilityPrivileges() {
                self.schedulePermissionCheck()
            }
        }
        self.pollingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
    }

    private func finishPolling() {
        self.pollingWorkItem?.cancel()
        self.pollingWorkItem = nil

        let completion = self.onTrusted
        self.onTrusted = nil
        completion?()
    }

    static func acquireNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { enabled, _ in
            LoggerService.notificationState(enabled: enabled)
        }
    }
}
