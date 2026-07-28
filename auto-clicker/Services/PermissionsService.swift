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

    private init() {}

    func pollAccessibilityPrivileges(onTrusted: @escaping () -> Void) {
        LoggerService.permissionTrustedState()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else {
                return
            }

            self.isTrusted = AXIsProcessTrusted()

            if self.isTrusted {
                onTrusted()
            } else {
                self.pollAccessibilityPrivileges(onTrusted: onTrusted)
            }
        }
    }

    static func acquireAccessibilityPrivileges() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        let enabled = AXIsProcessTrustedWithOptions(options)

        LoggerService.permissionState(enabled: enabled)
    }

    static func acquireNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { enabled, _ in
            LoggerService.notificationState(enabled: enabled)
        }
    }
}
