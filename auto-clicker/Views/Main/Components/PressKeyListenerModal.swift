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
                .foregroundColor(.autoClickerPrimary)

            Text("key_listener_modal_instruction")
                .font(.system(size: 14, design: .serif))

            Text("key_listener_modal_cancel_hint")
                .font(.system(size: 12, design: .serif))
                .foregroundColor(.autoClickerSecondaryText)
        }
        .multilineTextAlignment(.center)
        .frame(width: 340, height: 190)
        .padding(18)
        .foregroundColor(.autoClickerBodyText)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.autoClickerPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.autoClickerInk, lineWidth: 1.5)
        )
        .shadow(
            color: Color.autoClickerInk.opacity(0.16),
            radius: 10,
            x: 3,
            y: 5
        )
        .padding(12)
        .background(Color.autoClickerBackground)
        .ignoresSafeArea()
        .overlay(InputAwareView(onPress: self.handleInputEvent))
    }
}
