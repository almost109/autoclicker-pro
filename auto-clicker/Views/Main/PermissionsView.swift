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

    var body: some View {
        ZStack {
            self.painterlyBackground
                .ignoresSafeArea()

            VStack(spacing: 22) {
                VStack(spacing: 8) {
                    Text("permissions_help_title")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundColor(.autoClickerInk)

                    Text("permissions_help_first_paragraph")
                        .font(.system(size: 15, design: .serif))
                        .foregroundColor(.autoClickerBodyText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("permissions_help_second_paragraph")
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(.autoClickerSecondaryText)
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
                            primaryColor: .autoClickerPrimary,
                            inkColor: .autoClickerInk
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
                            primaryColor: .autoClickerPrimary,
                            inkColor: .autoClickerInk
                        )
                    )
                }
            }
            .padding(.horizontal, 34)
            .padding(.vertical, 32)
            .frame(maxWidth: 540)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.autoClickerPanel)
                    .shadow(color: Color.autoClickerInk.opacity(0.14), radius: 10, x: 5, y: 7)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.autoClickerInk, lineWidth: 1.5)
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
                ? .autoClickerSynchronizationGreen
                : .autoClickerOchre
        )
        .padding(.horizontal, 16)
        .frame(height: 36)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.autoClickerBackground.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.autoClickerInk.opacity(0.45), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var painterlyBackground: some View {
        ZStack {
            Color.autoClickerBackground

            LinearGradient(
                colors: [
                    Color.autoClickerBlue.opacity(0.10),
                    Color.autoClickerBackground.opacity(0.18),
                    Color.autoClickerPrimary.opacity(0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    .clear,
                    Color.autoClickerSynchronizationGreen.opacity(0.08)
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
