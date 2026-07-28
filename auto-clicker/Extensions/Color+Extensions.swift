//
//  Color+Extensions.swift
//  auto-clicker
//
//  Created by Ben Tindall on 29/03/2022.
//

import SwiftUI

extension Color {
    static let autoClickerBackground = Color(
        red: 244 / 255,
        green: 239 / 255,
        blue: 227 / 255
    )
    static let autoClickerPanel = Color(
        red: 251 / 255,
        green: 247 / 255,
        blue: 236 / 255
    )
    static let autoClickerInk = Color(
        red: 33 / 255,
        green: 28 / 255,
        blue: 21 / 255
    )
    static let autoClickerBodyText = Color(
        red: 58 / 255,
        green: 50 / 255,
        blue: 38 / 255
    )
    static let autoClickerSecondaryText = Color(
        red: 107 / 255,
        green: 93 / 255,
        blue: 70 / 255
    )
    static let autoClickerPrimary = Color(
        red: 193 / 255,
        green: 68 / 255,
        blue: 14 / 255
    )
    static let autoClickerOchre = Color(
        red: 217 / 255,
        green: 164 / 255,
        blue: 65 / 255
    )
    static let autoClickerBlue = Color(
        red: 60 / 255,
        green: 110 / 255,
        blue: 165 / 255
    )
    static let autoClickerSynchronizationGreen = Color(
        red: 129 / 255,
        green: 157 / 255,
        blue: 104 / 255
    )

    func changeBrightness(_ newBrightness: CGFloat) -> Color {
        NSColor(self)
            .changeBrightness(newBrightness)
            .color
    }
}
