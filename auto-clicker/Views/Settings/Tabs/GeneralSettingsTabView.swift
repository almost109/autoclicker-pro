//
//  GeneralSettingsTabView.swift
//  auto-clicker
//
//  Created by Ben Tindall on 30/03/2022.
//

import Defaults
import LaunchAtLogin
import SwiftUI

struct GeneralSettingsTabView: View {
    @Default(.menuBarShowIcon) private var menuBarShowIcon
    @Default(.autoClickerState) private var formState

    var body: some View {
        SettingsTabView {
            SettingsTabItemView(
                title: "settings_general_interval_mode_title",
                help: "settings_general_interval_mode_help",
                divider: true
            ) {
                Picker("", selection: self.$formState.intervalMode) {
                    Text("static", comment: "Static interval mode").tag(IntervalMode.staticInterval)
                    Text("range", comment: "Range interval mode").tag(IntervalMode.rangeInterval)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
                .accessibilityLabel("accessibility_click_interval_mode")
                .accessibilityHint("accessibility_click_interval_mode_hint")
            }

            SettingsTabItemView(
                title: "settings_general_app_should_quit_on_close_title",
                help: "settings_general_app_should_quit_on_close_help"
            ) {
                Defaults.Toggle(
                    " " + String(localized: "settings_general_app_should_quit_on_close"),
                    key: .appShouldQuitOnClose
                )
            }

            SettingsTabItemView(
                help: "settings_general_launch_on_login_help",
                divider: true
            ) {
                LaunchAtLogin.Toggle {
                    Text(" " + String(localized: "settings_general_launch_on_login"))
                }
            }

            SettingsTabItemView(
                title: "settings_general_menu_bar_show_icon_title",
                help: "settings_general_menu_bar_show_icon_help"
            ) {
                HStack {
                    Defaults.Toggle(
                        " " + String(localized: "settings_general_menu_bar_show_icon"),
                        key: .menuBarShowIcon
                    )
                    .onChange { isOn in
                        MenuBarService.toggle(isOn)

                        // If the menu bar icon is turned off, enforce that the dock icon is restored
                        //  otherwise the user can get stuck!
                        if !isOn {
                            Defaults[.menuBarHideDock] = false
                            WindowStateService.refreshDockIconState()
                        }
                    }

                    Image(systemName: "cursorarrow.click.badge.clock")
                }
            }

            SettingsTabItemView(
                help: "settings_general_menu_bar_show_dynamic_icon_help"
            ) {
                HStack {
                    Defaults.Toggle(
                        " " + String(localized: "settings_general_menu_bar_show_dynamic_icon"),
                        key: .menuBarShowDynamicIcon
                    )
                    .disabled(!self.menuBarShowIcon)

                    Image(systemName: "cursorarrow.click.badge.clock")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .orange)
                    Image(systemName: "cursorarrow.click.badge.clock")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .green)
                }
            }

            SettingsTabItemView(
                help: "settings_general_menu_bar_hide_dock_help",
                divider: true
            ) {
                Defaults.Toggle(
                    " " + String(localized: "settings_general_menu_bar_hide_dock"),
                    key: .menuBarHideDock
                )
                .onChange { _ in
                    WindowStateService.refreshDockIconState()
                }
                .disabled(!self.menuBarShowIcon)
            }

            SettingsTabItemView(
                title: "settings_general_notify_title",
                divider: true
            ) {
                Defaults.Toggle(
                    " " + String(localized: "settings_general_notify_on_start"),
                    key: .notifyOnStart
                )
                .onChange { isOn in
                    if isOn {
                        PermissionsService.acquireNotificationPermissions()
                    }
                }

                Defaults.Toggle(
                    " " + String(localized: "settings_general_notify_on_finish"),
                    key: .notifyOnFinish
                )
                .onChange { isOn in
                    if isOn {
                        PermissionsService.acquireNotificationPermissions()
                    }
                }
            }

            SettingsTabItemView(
                title: "settings_window_stay_ontop_title",
                help: "settings_window_stay_ontop_help"
            ) {
                Defaults.Toggle(
                    " " + String(localized: "settings_window_stay_ontop"),
                    key: .windowShouldKeepOnTop
                )
                .onChange { isOn in
                    WindowStateService.toggleKeepWindowOnTop(isOn)
                }
            }
        }
    }
}

struct GeneralSettingsTabView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsTabView()
    }
}
