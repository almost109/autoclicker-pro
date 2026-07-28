//
//  NSColor+Extensions.swift
//  auto-clicker
//
//  Created by Ben Tindall on 29/03/2022.
//

import SwiftUI

extension NSColor {
    var color: Color {
        SwiftUI.Color(self)
    }

    func changeBrightness(_ newBrightness: CGFloat) -> NSColor {
        var hue: CGFloat = 0,
            saturation: CGFloat = 0,
            brightness: CGFloat = 0,
            alpha: CGFloat = 0

        guard let convertedColor = self.usingColorSpace(.extendedSRGB) else {
            return self
        }

        convertedColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return NSColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
    }
}
