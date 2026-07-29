//
//  Color+Extensions.swift
//  auto-clicker
//
//  Created by Ben Tindall on 29/03/2022.
//

import SwiftUI

extension Color {
    static let autoClickerBackground = Color(
        red: 251 / 255,
        green: 246 / 255,
        blue: 237 / 255
    )
    static let autoClickerPanel = Color(
        red: 251 / 255,
        green: 247 / 255,
        blue: 236 / 255
    )
    static let autoClickerInk = Color(
        red: 43 / 255,
        green: 43 / 255,
        blue: 43 / 255
    )
    static let autoClickerBodyText = Color(
        red: 43 / 255,
        green: 43 / 255,
        blue: 43 / 255
    )
    static let autoClickerSecondaryText = Color(
        red: 107 / 255,
        green: 98 / 255,
        blue: 86 / 255
    )
    static let autoClickerPrimary = Color(
        red: 211 / 255,
        green: 84 / 255,
        blue: 0 / 255
    )
    static let autoClickerOchre = Color(
        red: 201 / 255,
        green: 152 / 255,
        blue: 43 / 255
    )
    static let autoClickerBlue = Color(
        red: 47 / 255,
        green: 109 / 255,
        blue: 181 / 255
    )
    static let autoClickerSynchronizationGreen = Color(
        red: 90 / 255,
        green: 143 / 255,
        blue: 99 / 255
    )

    func changeBrightness(_ newBrightness: CGFloat) -> Color {
        NSColor(self)
            .changeBrightness(newBrightness)
            .color
    }
}
