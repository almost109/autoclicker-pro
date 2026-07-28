//
//  ACWindow.swift
//  auto-clicker
//
//  Created by Ben Tindall on 16/07/2022.
//

import SwiftUI

struct ACWindow: View {
    @StateObject private var permissionsService = PermissionsService.shared

    var body: some View {
        ZStack {
            Color.autoClickerBackground
                .ignoresSafeArea()

            if self.permissionsService.isTrusted {
                MainView()
                    .transition(.opacity)
            } else {
                PermissionsView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: self.permissionsService.isTrusted)
        .onAppear {
            self.permissionsService.pollAccessibilityPrivileges(onTrusted: {
                MenuBarService.enableAllMenuBarItems()
            })
        }
    }
}
