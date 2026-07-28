//
//  HelpCommands.swift
//  auto-clicker
//
//  Created by Ben Tindall on 06/07/2022.
//

import SwiftUI

struct HelpCommands: Commands {
    private static let issueURL = URL(
        string: "https://github.com/almost109/AutoClicker-Pro/issues"
    )

    var body: some Commands {
        CommandGroup(replacing: .help, addition: {
            Button("help_commands_request_a_feature") {
                self.openIssuesPage()
            }
            Button("help_commands_report_a_bug") {
                self.openIssuesPage()
            }
        })
    }

    private func openIssuesPage() {
        guard let url = Self.issueURL else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
