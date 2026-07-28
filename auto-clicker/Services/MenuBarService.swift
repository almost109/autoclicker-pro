//
//  MenuBarService.swift
//  auto-clicker
//
//  Created by Ben Tindall on 16/07/2022.
//

import Cocoa
import Defaults
import KeyboardShortcuts
import SwiftUI

final class MenuBarService {
    private(set) static var statusBarItem: NSStatusItem?

    private(set) static var startMenuItem: NSMenuItem?
    private(set) static var stopMenuItem: NSMenuItem?
    private(set) static var hideOrShowMenuItem: NSMenuItem?
    private(set) static var preferencesMenuItem: NSMenuItem?
    private(set) static var aboutMenuItem: NSMenuItem?
    private(set) static var quitMenuItem: NSMenuItem?

    private init() {}

    static func create() {
        guard self.statusBarItem == nil else {
            return
        }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusBarItem = item
        item.menu = self.buildMenu()
        self.resetImage()

        if !PermissionsService.shared.isTrusted {
            self.disableAllMenuBarItems()
        }
    }

    static func destroy() {
        guard let statusBarItem = self.statusBarItem else {
            return
        }

        NSStatusBar.system.removeStatusItem(statusBarItem)
        self.statusBarItem = nil
        self.startMenuItem = nil
        self.stopMenuItem = nil
        self.hideOrShowMenuItem = nil
        self.preferencesMenuItem = nil
        self.aboutMenuItem = nil
        self.quitMenuItem = nil
    }

    static func toggle(_ isEnabled: Bool) {
        isEnabled ? self.create() : self.destroy()
    }

    static func refreshState() {
        self.toggle(Defaults[.menuBarShowIcon])
    }

    static func resetImage() {
        self.statusBarItem?.button?.image = NSImage(
            systemSymbolName: "cursorarrow.click.badge.clock",
            accessibilityDescription: "AutoClicker Pro"
        )
    }

    static func changeImageColour(newColor: NSColor) {
        guard Defaults[.menuBarShowDynamicIcon],
              let button = self.statusBarItem?.button,
              let image = NSImage(
                systemSymbolName: "cursorarrow.click.2",
                accessibilityDescription: "AutoClicker Pro"
              ) else {
            return
        }

        button.image = image.withSymbolConfiguration(
            NSImage.SymbolConfiguration(
                paletteColors: [NSColor(Color.primary), newColor]
            )
        )
    }

    static func updateExecutionState(isRunning: Bool) {
        self.startMenuItem?.isEnabled = !isRunning
        self.stopMenuItem?.isEnabled = isRunning
    }

    static func disableAllMenuBarItems() {
        [
            self.startMenuItem,
            self.stopMenuItem,
            self.hideOrShowMenuItem,
            self.preferencesMenuItem
        ].forEach { $0?.isEnabled = false }

        self.aboutMenuItem?.isEnabled = true
        self.quitMenuItem?.isEnabled = true
    }

    static func enableAllMenuBarItems() {
        [
            self.startMenuItem,
            self.hideOrShowMenuItem,
            self.preferencesMenuItem,
            self.aboutMenuItem,
            self.quitMenuItem
        ].forEach { $0?.isEnabled = true }

        self.stopMenuItem?.isEnabled = false
    }

    private static func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let startItem = NSMenuItem(
            title: NSLocalizedString(
                "menu_bar_item_start",
                comment: "Menu bar item start option"
            ),
            action: #selector(self.menuActionStart),
            keyEquivalent: KeyboardShortcuts.Name.pressStartButton.shortcut?
                .descriptionKeyOnly.lowercased() ?? ""
        )
        startItem.target = self
        self.startMenuItem = startItem
        menu.addItem(startItem)

        let stopItem = NSMenuItem(
            title: NSLocalizedString(
                "menu_bar_item_stop",
                comment: "Menu bar item stop option"
            ),
            action: #selector(self.menuActionStop),
            keyEquivalent: KeyboardShortcuts.Name.pressStopButton.shortcut?
                .descriptionKeyOnly.lowercased() ?? ""
        )
        stopItem.isEnabled = false
        stopItem.target = self
        self.stopMenuItem = stopItem
        menu.addItem(stopItem)

        menu.addItem(.separator())

        let hideOrShowItem = NSMenuItem(
            title: NSApp.isHidden
                ? NSLocalizedString(
                    "menu_bar_item_hide_show_show",
                    comment: "Menu bar item show option"
                )
                : NSLocalizedString(
                    "menu_bar_item_hide_show_hide",
                    comment: "Menu bar item hide option"
                ),
            action: #selector(self.menuActionHideOrShow),
            keyEquivalent: "h"
        )
        hideOrShowItem.target = self
        self.hideOrShowMenuItem = hideOrShowItem
        menu.addItem(hideOrShowItem)

        menu.addItem(.separator())

        let preferencesItem = NSMenuItem(
            title: NSLocalizedString(
                "menu_bar_item_preferences",
                comment: "Menu bar item preferences option"
            ),
            action: #selector(self.menuActionPreferences),
            keyEquivalent: ","
        )
        preferencesItem.target = self
        self.preferencesMenuItem = preferencesItem
        menu.addItem(preferencesItem)

        let aboutItem = NSMenuItem(
            title: NSLocalizedString(
                "menu_bar_item_about",
                comment: "Menu bar item about option"
            ),
            action: #selector(self.menuActionAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        self.aboutMenuItem = aboutItem
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: NSLocalizedString(
                "menu_bar_item_quit",
                comment: "Menu bar item quit option"
            ),
            action: #selector(self.menuActionQuit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        self.quitMenuItem = quitItem
        menu.addItem(quitItem)

        return menu
    }

    @objc private static func menuActionStart(_ sender: NSMenuItem) {
        AutoClickSimulator.shared.start()
    }

    @objc private static func menuActionStop(_ sender: NSMenuItem) {
        AutoClickSimulator.shared.stop()
    }

    @objc private static func menuActionHideOrShow(_ sender: NSMenuItem) {
        if NSApp.isHidden {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.unhide(sender)
        } else {
            NSApp.hide(sender)
        }
    }

    @objc private static func menuActionPreferences(_ sender: NSMenuItem) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(
            Selector(("showSettingsWindow:")),
            to: nil,
            from: nil
        )
    }

    @objc private static func menuActionAbout(_ sender: NSMenuItem) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(sender)
    }

    @objc private static func menuActionQuit(_ sender: NSMenuItem) {
        NSApp.terminate(sender)
    }
}
