//
//  PermissionsView.swift
//  auto-clicker
//
//  Created by Ben Tindall on 10/04/2022.
//

import AppKit
import SwiftUI

struct PermissionsView: View {
    @ObservedObject private var permissionsService = PermissionsService.shared

    private let backgroundColor = Color(red: 244 / 255, green: 239 / 255, blue: 227 / 255)
    private let panelColor = Color(red: 251 / 255, green: 247 / 255, blue: 236 / 255)
    private let inkColor = Color(red: 33 / 255, green: 28 / 255, blue: 21 / 255)
    private let bodyTextColor = Color(red: 58 / 255, green: 50 / 255, blue: 38 / 255)
    private let secondaryTextColor = Color(red: 107 / 255, green: 93 / 255, blue: 70 / 255)
    private let primaryColor = Color(red: 193 / 255, green: 68 / 255, blue: 14 / 255)
    private let amberColor = Color(red: 217 / 255, green: 164 / 255, blue: 65 / 255)
    private let blueColor = Color(red: 60 / 255, green: 110 / 255, blue: 165 / 255)
    private let grantedColor = Color(red: 129 / 255, green: 157 / 255, blue: 104 / 255)

    var body: some View {
        ZStack {
            self.painterlyBackground
                .ignoresSafeArea()

            VStack(spacing: 22) {
                VStack(spacing: 8) {
                    Text("permissions_help_title")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundColor(self.inkColor)

                    Text("permissions_help_first_paragraph")
                        .font(.system(size: 15, design: .serif))
                        .foregroundColor(self.bodyTextColor)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("permissions_help_second_paragraph")
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(self.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                self.permissionStatus

                HStack(spacing: 12) {
                    Button(action: self.openSystemPreferences) {
                        Text("permissions_help_open_sys_pref_btn")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(
                        MockupActionButtonStyle(
                            isPrimary: true,
                            primaryColor: self.primaryColor,
                            inkColor: self.inkColor
                        )
                    )

                    Button(action: self.quit) {
                        Text("permissions_help_quit_btn")
                            .font(.system(size: 15, design: .serif))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(
                        MockupActionButtonStyle(
                            isPrimary: false,
                            primaryColor: self.primaryColor,
                            inkColor: self.inkColor
                        )
                    )
                }
            }
            .padding(.horizontal, 34)
            .padding(.vertical, 32)
            .frame(maxWidth: 540)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(self.panelColor)
                    .shadow(color: self.inkColor.opacity(0.14), radius: 10, x: 5, y: 7)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(self.inkColor, lineWidth: 1.5)
            )
            .padding(24)
        }
    }

    private var permissionStatus: some View {
        HStack(spacing: 8) {
            Text(self.permissionsService.isTrusted ? "✓" : "●")
                .font(.system(size: 13, weight: .semibold, design: .serif))

            Text(
                self.permissionsService.isTrusted
                    ? LocalizedStringKey("permissions_status_granted")
                    : LocalizedStringKey("permissions_status_required")
            )
            .font(.system(size: 15, weight: .medium, design: .serif))
        }
        .foregroundColor(
            self.permissionsService.isTrusted
                ? self.grantedColor
                : self.amberColor
        )
        .padding(.horizontal, 16)
        .frame(height: 36)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(self.backgroundColor.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(self.inkColor.opacity(0.45), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var painterlyBackground: some View {
        ZStack {
            self.backgroundColor

            LinearGradient(
                colors: [
                    self.blueColor.opacity(0.10),
                    self.backgroundColor.opacity(0.18),
                    self.primaryColor.opacity(0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    .clear,
                    self.grantedColor.opacity(0.08)
                ],
                startPoint: .center,
                endPoint: .bottomTrailing
            )
        }
    }

    private func openSystemPreferences() {
        guard let accessibilitySettingsURL = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else {
            return
        }

        NSWorkspace.shared.open(accessibilitySettingsURL)
    }

    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

struct PermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionsView()
            .frame(width: 560, height: 760)
    }
}
