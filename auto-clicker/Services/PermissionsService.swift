//
//  PermissionsService.swift
//  auto-clicker
//
//  Created by Ben Tindall on 10/04/2022.
//

import Cocoa
import UserNotifications

enum AccessibilityCheckOrigin: String {
    case initialization
    case launch
    case applicationDidBecomeActive
    case polling
    case permissionRequest
    case confirmationTimer
    case other
}

final class PermissionsService: ObservableObject {
    static let shared = PermissionsService()

    @Published private(set) var isTrusted: Bool

    var isRevocationConfirmationPending: Bool {
        self.revocationConfirmationWorkItem != nil
    }

    private var pollingWorkItem: DispatchWorkItem?
    private var revocationConfirmationWorkItem: DispatchWorkItem?
    private var onTrusted: (() -> Void)?

    private init() {
        let isInitiallyTrusted = AXIsProcessTrusted()
        self.isTrusted = isInitiallyTrusted
        LoggerService.accessibilityCheck(
            origin: .initialization,
            caller: "PermissionsService.init",
            result: isInitiallyTrusted,
            previousPublishedValue: isInitiallyTrusted,
            newPublishedValue: isInitiallyTrusted,
            confirmationPendingBefore: false,
            confirmationPendingAfter: false
        )
    }

    @discardableResult
    func refreshAccessibilityPrivileges(
        origin: AccessibilityCheckOrigin = .other,
        caller: String = #function,
        confirmingRevocationWith confirmation: (() -> Void)? = nil
    ) -> Bool {
        let previousPublishedValue = self.isTrusted
        let confirmationPendingBefore = self.revocationConfirmationWorkItem != nil
        let isCurrentlyTrusted = AXIsProcessTrusted()
        if !isCurrentlyTrusted,
           self.isTrusted,
           let confirmation {
            self.scheduleRevocationConfirmation(
                confirmation,
                origin: origin,
                caller: caller
            )
            LoggerService.accessibilityCheck(
                origin: origin,
                caller: caller,
                result: isCurrentlyTrusted,
                previousPublishedValue: previousPublishedValue,
                newPublishedValue: self.isTrusted,
                confirmationPendingBefore: confirmationPendingBefore,
                confirmationPendingAfter: self.revocationConfirmationWorkItem != nil
            )
            return true
        }

        self.cancelRevocationConfirmation(caller: caller, origin: origin)
        if self.isTrusted != isCurrentlyTrusted {
            self.isTrusted = isCurrentlyTrusted
        }

        LoggerService.accessibilityCheck(
            origin: origin,
            caller: caller,
            result: isCurrentlyTrusted,
            previousPublishedValue: previousPublishedValue,
            newPublishedValue: self.isTrusted,
            confirmationPendingBefore: confirmationPendingBefore,
            confirmationPendingAfter: self.revocationConfirmationWorkItem != nil
        )
        LoggerService.accessibilityTransitionIfNeeded(
            from: previousPublishedValue,
            to: self.isTrusted,
            origin: origin,
            caller: caller
        )

        if isCurrentlyTrusted {
            self.finishPolling()
        }

        return isCurrentlyTrusted
    }

    private func scheduleRevocationConfirmation(
        _ confirmation: @escaping () -> Void,
        origin: AccessibilityCheckOrigin,
        caller: String
    ) {
        guard self.revocationConfirmationWorkItem == nil else {
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.revocationConfirmationWorkItem = nil
            LoggerService.accessibilityConfirmationTimer(
                event: "fired",
                origin: origin,
                caller: caller
            )
            confirmation()
        }
        self.revocationConfirmationWorkItem = workItem
        LoggerService.accessibilityConfirmationTimer(
            event: "scheduled",
            origin: origin,
            caller: caller
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
    }

    private func cancelRevocationConfirmation(
        caller: String,
        origin: AccessibilityCheckOrigin
    ) {
        guard self.revocationConfirmationWorkItem != nil else {
            return
        }

        self.revocationConfirmationWorkItem?.cancel()
        self.revocationConfirmationWorkItem = nil
        LoggerService.accessibilityConfirmationTimer(
            event: "cancelled",
            origin: origin,
            caller: caller
        )
    }

    func pollAccessibilityPrivileges(onTrusted: @escaping () -> Void) {
        self.onTrusted = onTrusted
        guard !self.refreshAccessibilityPrivileges(
            origin: .polling,
            caller: #function
        ) else {
            return
        }

        self.schedulePermissionCheck()
    }

    func requestAccessibilityPrivilegesIfNeeded() {
        guard !self.refreshAccessibilityPrivileges(
            origin: .permissionRequest,
            caller: #function
        ) else {
            return
        }

        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        let previousPublishedValue = self.isTrusted
        let confirmationPending = self.revocationConfirmationWorkItem != nil
        let enabled = AXIsProcessTrustedWithOptions(options)
        self.isTrusted = enabled
        LoggerService.accessibilityCheck(
            origin: .permissionRequest,
            caller: #function,
            result: enabled,
            previousPublishedValue: previousPublishedValue,
            newPublishedValue: self.isTrusted,
            confirmationPendingBefore: confirmationPending,
            confirmationPendingAfter: self.revocationConfirmationWorkItem != nil
        )
        LoggerService.accessibilityTransitionIfNeeded(
            from: previousPublishedValue,
            to: self.isTrusted,
            origin: .permissionRequest,
            caller: #function
        )
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
            if !self.refreshAccessibilityPrivileges(
                origin: .polling,
                caller: #function
            ) {
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
