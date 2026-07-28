//
//  CompactFormButtonStyle.swift
//  auto-clicker
//
//  Created by Ben Tindall on 26/02/2022.
//

import SwiftUI
struct CompactFormButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14))
            .foregroundColor(.autoClickerInk)
            .padding(.horizontal, 10)
            .frame(minHeight: 32, maxHeight: 32)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.autoClickerPanel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color.autoClickerInk, lineWidth: 2)
            )
            .opacity(self.isEnabled ? 1 : 0.48)
            .brightness(configuration.isPressed ? -0.06 : 0)
    }
}
