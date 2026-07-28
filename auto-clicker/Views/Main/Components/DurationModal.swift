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
                                ? Color(red: 217 / 255, green: 164 / 255, blue: 65 / 255).opacity(0.38)
                                : .clear
                        )
                )
            }

            Divider()
                .overlay(Color(red: 107 / 255, green: 93 / 255, blue: 70 / 255).opacity(0.35))
                .padding(.vertical, 2)

            Button("duration_modal_cancel_button") {
                self.presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, design: .serif))
            .foregroundColor(Color(red: 107 / 255, green: 93 / 255, blue: 70 / 255))
            .frame(maxWidth: .infinity)
            .frame(height: 28)
        }
        .padding(8)
        .frame(width: 180)
        .foregroundColor(Color(red: 33 / 255, green: 28 / 255, blue: 21 / 255))
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 251 / 255, green: 247 / 255, blue: 236 / 255))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 33 / 255, green: 28 / 255, blue: 21 / 255), lineWidth: 1.5)
        )
        .shadow(
            color: Color(red: 33 / 255, green: 28 / 255, blue: 21 / 255).opacity(0.16),
            radius: 8,
            x: 2,
            y: 4
        )
        .padding(6)
    }
}
