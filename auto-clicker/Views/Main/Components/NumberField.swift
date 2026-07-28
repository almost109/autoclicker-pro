//
//  NumberField.swift
//  auto-clicker
//
//  Created by Ben Tindall on 12/05/2021.
//

import SwiftUI

struct NumberField: View {
    var text: String
    var accessibilityLabel: LocalizedStringKey
    var accessibilityHint: LocalizedStringKey
    var min: Int
    var max: Int

    @Binding var number: Int

    @State private var rawString: String = ""

    private func validate(_ newValue: String) {
        let newValueNumbersOnly = newValue.filter(\.isWholeNumber)

        guard newValue == newValueNumbersOnly else {
            self.rawString = newValueNumbersOnly
            return
        }

        guard let newValueInt = Int(newValueNumbersOnly) else {
            self.rawString = String(self.number)
            return
        }

        guard newValueInt >= self.min else {
            self.rawString = String(self.min)
            return
        }

        guard newValueInt <= self.max else {
            self.rawString = String(self.max)
            return
        }

        // Hacky way to stop leading and stacked zeros
        self.rawString = String(newValueInt)

        self.number = newValueInt
    }

    var body: some View {
        TextField(self.text, text: self.$rawString)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .accessibilityLabel(self.accessibilityLabel)
            .accessibilityValue(self.rawString)
            .accessibilityHint(self.accessibilityHint)
            .onChange(of: self.rawString, perform: self.validate)
            .onAppear {
                self.rawString = String(self.number)
            }
    }
}
