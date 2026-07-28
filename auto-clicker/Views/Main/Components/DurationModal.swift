//
//  DurationModal.swift
//  auto-clicker
//
//  Created by Ben Tindall on 27/03/2022.
//

import SwiftUI

struct DurationModal: View {
    @Environment(\.presentationMode) private var presentationMode

    @Binding var selected: Duration

    var body: some View {
        VStack(spacing: 4) {
            ForEach(Duration.allCases) { unit in
                Button {
                    self.selected = unit
                    self.presentationMode.wrappedValue.dismiss()
                } label: {
                    Text(unit.localised)
                        .font(.system(size: 14, weight: unit == self.selected ? .medium : .regular, design: .serif))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            unit == self.selected
                                ? Color.autoClickerOchre.opacity(0.38)
                                : .clear
                        )
                )
            }

            Divider()
                .overlay(Color.autoClickerSecondaryText.opacity(0.35))
                .padding(.vertical, 2)

            Button("duration_modal_cancel_button") {
                self.presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, design: .serif))
            .foregroundColor(.autoClickerSecondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 28)
        }
        .padding(8)
        .frame(width: 180)
        .foregroundColor(.autoClickerInk)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.autoClickerPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.autoClickerInk, lineWidth: 1.5)
        )
        .shadow(
            color: Color.autoClickerInk.opacity(0.16),
            radius: 8,
            x: 2,
            y: 4
        )
        .padding(6)
    }
}
