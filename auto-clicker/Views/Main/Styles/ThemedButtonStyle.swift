//
//  ThemedButtonStyle.swift
//  auto-clicker
//
//  Created by Ben Tindall on 26/02/2022.
//

import SwiftUI
import Defaults

struct ThemedButtonStyle: ButtonStyle {
    var fontSize: CGFloat = 24
    var width: CGFloat = 100
    var height: CGFloat = 45

    func makeBody(configuration: Self.Configuration) -> some View {
        SuperAmazingButton(configuration: configuration,
                           fontSize: self.fontSize,
                           width: self.width,
                           height: self.height)
    }

    struct SuperAmazingButton: View {
        let configuration: ButtonStyle.Configuration

        @Default(.appearanceSelectedTheme) private var activeTheme

        @Environment(\.isEnabled) private var isEnabled: Bool

        @State private var isHover = false

        let fontSize: CGFloat
        let width: CGFloat
        let height: CGFloat

        var body: some View {
            withAnimation(.easeOut) {
                configuration.label
                    .frame(minWidth: self.width, minHeight: self.height)
                    .foregroundColor(isEnabled ? self.activeTheme.fontColour : self.activeTheme.backgroundColour.darker)
                    .padding(.horizontal)
                    .padding(.bottom, 1)
                    .font(.system(size: self.fontSize))
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isEnabled ? isHover ? self.activeTheme.backgroundColour.lighter : self.activeTheme.backgroundColour.darker : self.activeTheme.backgroundColour)
                    )
                    .onHover(perform: { hover in
                        isHover = hover
                    })
            }
        }
    }
}

struct CompactFormButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let panelColor = Color(red: 251 / 255, green: 247 / 255, blue: 236 / 255)
        let inkColor = Color(red: 33 / 255, green: 28 / 255, blue: 21 / 255)

        configuration.label
            .font(.system(size: 14))
            .foregroundColor(inkColor)
            .padding(.horizontal, 10)
            .frame(minHeight: 32, maxHeight: 32)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(panelColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(inkColor, lineWidth: 2)
            )
            .opacity(self.isEnabled ? 1 : 0.48)
            .brightness(configuration.isPressed ? -0.06 : 0)
    }
}
