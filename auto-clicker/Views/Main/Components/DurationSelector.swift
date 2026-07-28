//
//  DurationSelector.swift
//  auto-clicker
//
//  Created by Ben Tindall on 27/03/2022.
//

import SwiftUI

struct DurationSelector: View {
    @State private var showingDurationModal = false

    @Binding var selectedDuration: Duration

    var body: some View {
        Button {
            self.showingDurationModal = true
        } label: {
            HStack(spacing: 8) {
                Text(self.selectedDuration.localised)
                    .lineLimit(1)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .medium))
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(CompactFormButtonStyle())
        .popover(isPresented: self.$showingDurationModal, arrowEdge: .bottom, content: {
            DurationModal(selected: self.$selectedDuration)
        })
    }
}
