//
//  PressKeyListener.swift
//  auto-clicker
//
//  Created by Ben Tindall on 07/04/2022.
//

import SwiftUI
import Defaults

struct PressKeyListener: View {
    @State private var showingPressKeyListenerModal = false

    @Default(.autoClickerState) private var formState

    var body: some View {
        Button {
            self.showingPressKeyListenerModal = true
        } label: {
            HStack(spacing: 8) {
                Text(self.formState.pressInput.readable)
                    .lineLimit(1)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .medium))
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(CompactFormButtonStyle())
        .frame(minWidth: 150)
        .sheet(isPresented: self.$showingPressKeyListenerModal, content: {
            PressKeyListenerModal()
        })
    }
}
