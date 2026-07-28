//
//  SettingsView.swift
//  auto-clicker
//
//  Created by Ben Tindall on 30/03/2022.
//

import SwiftUI

struct SettingsView: View {
    @State private var frameHeight: CGFloat = 100

    var body: some View {
        TabView {
            GeneralSettingsTabView()
                .tabItem {
                    Label("settings_general", systemImage: "gear")
                }
                .onAppear {
                    self.frameHeight = 700
                }

            KeyboardShortcutsSettingsTabView()
                .tabItem {
                    Label("settings_shortcuts", systemImage: "keyboard")
                }
                .onAppear {
                    self.frameHeight = 350
                }

            AppearanceSettingsTabView()
                .tabItem {
                    Label("settings_appearance", systemImage: "paintpalette")
                }
                .onAppear {
                    self.frameHeight = 250
                }
        }
        .frame(width: WindowStateService.settingsMinWidth, height: self.frameHeight)
        .padding()
    }
}
