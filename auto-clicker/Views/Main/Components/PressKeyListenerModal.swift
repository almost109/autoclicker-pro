//
//  PressKeyListenerModal.swift
//  auto-clicker
//
//  Created by Ben Tindall on 07/04/2022.
//

import SwiftUI
import Defaults
import Carbon.HIToolbox

struct PressKeyListenerModal: View {
    @Environment(\.presentationMode) private var presentationMode

    @Default(.autoClickerState) private var formState

    func handleInputEvent(input: Input) {
        if input.keyCode == kVK_Escape {
            self.presentationMode.wrappedValue.dismiss()
            return
        }

        guard input.isMouseInput || !input.readable.isEmpty else {
            return
        }

        self.formState.pressInput = input
        self.presentationMode.wrappedValue.dismiss()
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("key_listener_modal_title")
                .font(.system(size: 20, weight: .semibold, design: .serif))

            Text("key_listener_modal_waiting")
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(Color(red: 193 / 255, green: 68 / 255, blue: 14 / 255))

            Text("key_listener_modal_instruction")
                .font(.system(size: 14, design: .serif))

            Text("key_listener_modal_cancel_hint")
                .font(.system(size: 12, design: .serif))
                .foregroundColor(Color(red: 107 / 255, green: 93 / 255, blue: 70 / 255))
        }
        .multilineTextAlignment(.center)
        .frame(width: 340, height: 190)
        .padding(18)
        .foregroundColor(Color(red: 58 / 255, green: 50 / 255, blue: 38 / 255))
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 251 / 255, green: 247 / 255, blue: 236 / 255))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(red: 33 / 255, green: 28 / 255, blue: 21 / 255), lineWidth: 1.5)
        )
        .shadow(
            color: Color(red: 33 / 255, green: 28 / 255, blue: 21 / 255).opacity(0.16),
            radius: 10,
            x: 3,
            y: 5
        )
        .padding(12)
        .background(Color(red: 244 / 255, green: 239 / 255, blue: 227 / 255))
        .ignoresSafeArea()
        .overlay(InputAwareView(onPress: self.handleInputEvent))
    }
}
