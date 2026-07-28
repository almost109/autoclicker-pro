//
//  Bundle+AppInfo.swift
//  auto-clicker
//
//  Created by Ben Tindall on 14/07/2023.
//

import Foundation

extension Bundle {
    var appName: String { self.info("CFBundleName") }
    var displayName: String { self.info("CFBundleDisplayName") }
    var copyright: String { self.info("NSHumanReadableCopyright") }

    var appBuild: String { self.info("CFBundleVersion") }
    var appVersionLong: String { self.info("CFBundleShortVersionString") }

    private func info(_ key: String) -> String {
        self.infoDictionary?[key] as? String ?? "N/A"
    }
}
