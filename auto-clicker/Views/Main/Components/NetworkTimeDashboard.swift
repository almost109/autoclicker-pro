//
//  NetworkTimeDashboard.swift
//  auto-clicker
//

import Defaults
import SwiftUI

struct NetworkTimeDashboard: View {
    @Default(.appearanceSelectedTheme) private var activeTheme
    @ObservedObject var service: SNTPService

    private static let currentTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    private var snapshot: TimeSynchronizationSnapshot {
        self.service.synchronization
    }

    private var statusPresentation: StatusPresentation {
        switch self.snapshot.status {
        case .idle:
            return StatusPresentation(
                title: "network_time_status_offline",
                color: Color(red: 107 / 255, green: 93 / 255, blue: 70 / 255)
            )
        case .synchronizing:
            return StatusPresentation(
                title: "network_time_status_synchronizing",
                color: Color(red: 217 / 255, green: 164 / 255, blue: 65 / 255)
            )
        case .synchronized:
            return StatusPresentation(
                title: "network_time_status_synchronized",
                color: Color(red: 129 / 255, green: 157 / 255, blue: 104 / 255)
            )
        case .failed:
            return StatusPresentation(
                title: "network_time_status_failed",
                color: Color(red: 193 / 255, green: 68 / 255, blue: 14 / 255)
            )
        }
    }

    private var usesNetworkTime: Bool {
        guard self.snapshot.lastSynchronizedTime != nil else {
            return false
        }

        if case .failed = self.snapshot.status {
            return false
        }
        return true
    }

    private var offsetText: String {
        String(format: "%+.3f ms", self.snapshot.clockOffset * 1_000)
    }

    private var roundTripDelayText: String {
        String(format: "%.1f ms", self.snapshot.roundTripDelay * 1_000)
    }

    private var currentTimeText: String {
        Self.currentTimeFormatter.string(from: self.service.currentNetworkTime())
    }

    private var accessibilitySummary: String {
        [
            self.localizedStatus,
            self.localizedTimeSource,
            "\(String(localized: "network_time_current_time")): \(self.currentTimeText)",
            "\(String(localized: "network_time_server")): \(self.snapshot.server ?? String(localized: "network_time_not_available"))",
            "\(String(localized: "network_time_offset")): \(self.offsetText)",
            "\(String(localized: "network_time_rtt")): \(self.roundTripDelayText)"
        ].joined(separator: ". ")
    }

    private var localizedStatus: String {
        switch self.snapshot.status {
        case .idle:
            return String(localized: "network_time_status_offline")
        case .synchronizing:
            return String(localized: "network_time_status_synchronizing")
        case .synchronized:
            return String(localized: "network_time_status_synchronized")
        case .failed:
            return String(localized: "network_time_status_failed")
        }
    }

    private var localizedTimeSource: String {
        String(
            localized: self.usesNetworkTime
                ? "network_time_source_network"
                : "network_time_source_local"
        )
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("network_time_title")
                        .font(.system(size: 18, weight: .semibold, design: .serif))

                    Spacer()

                    HStack(spacing: 5) {
                        Circle()
                            .fill(self.statusPresentation.color)
                            .frame(width: 8, height: 8)

                        Text(self.statusPresentation.title)
                            .font(.system(size: 14, design: .serif))
                            .foregroundColor(self.statusPresentation.color)
                    }
                }

                NetworkMetricRow(
                    title: "network_time_current_time",
                    value: self.currentTimeText,
                    monospaced: true
                )
                NetworkMetricRow(
                    title: "network_time_server",
                    value: self.snapshot.server ?? String(localized: "network_time_not_available")
                )
                NetworkMetricRow(
                    title: "network_time_offset",
                    value: self.offsetText,
                    monospaced: true
                )
                NetworkMetricRow(
                    title: "network_time_rtt",
                    value: self.roundTripDelayText,
                    monospaced: true
                )
            }
            .foregroundColor(Color(red: 58 / 255, green: 50 / 255, blue: 38 / 255))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 11)
                    .fill(Color(red: 244 / 255, green: 239 / 255, blue: 227 / 255).opacity(0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .stroke(Color(red: 33 / 255, green: 28 / 255, blue: 21 / 255), lineWidth: 1.5)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("accessibility_network_time_dashboard")
            .accessibilityValue(self.accessibilitySummary)
        }
    }
}

private struct NetworkMetricRow: View {
    let title: LocalizedStringKey
    let value: String
    let monospaced: Bool

    init(
        title: LocalizedStringKey,
        value: String,
        monospaced: Bool = false
    ) {
        self.title = title
        self.value = value
        self.monospaced = monospaced
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(self.title)
                .font(.system(size: 14, design: .serif))
                .foregroundColor(Color(red: 107 / 255, green: 93 / 255, blue: 70 / 255))

            Spacer(minLength: 12)

            Text(self.value)
                .font(
                    self.monospaced
                        ? .system(size: 13, weight: .medium, design: .monospaced)
                        : .system(size: 14, weight: .medium, design: .serif)
                )
                .foregroundColor(Color(red: 33 / 255, green: 28 / 255, blue: 21 / 255))
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

struct NetworkTimeFooter: View {
    @Default(.appearanceSelectedTheme) private var activeTheme
    @ObservedObject var service: SNTPService

    private var snapshot: TimeSynchronizationSnapshot {
        self.service.synchronization
    }

    private var status: (LocalizedStringKey, String, Color) {
        switch self.snapshot.status {
        case .idle:
            return (
                "network_time_status_offline",
                "circle.fill",
                Color(red: 107 / 255, green: 93 / 255, blue: 70 / 255)
            )
        case .synchronizing:
            return (
                "network_time_status_synchronizing",
                "circle.fill",
                Color(red: 217 / 255, green: 164 / 255, blue: 65 / 255)
            )
        case .synchronized:
            return (
                "network_time_status_synchronized",
                "checkmark.circle.fill",
                Color(red: 129 / 255, green: 157 / 255, blue: 104 / 255)
            )
        case .failed:
            return (
                "network_time_status_failed",
                "exclamationmark.circle.fill",
                Color(red: 193 / 255, green: 68 / 255, blue: 14 / 255)
            )
        }
    }

    private var usesNetworkTime: Bool {
        guard self.snapshot.lastSynchronizedTime != nil else {
            return false
        }
        if case .failed = self.snapshot.status {
            return false
        }
        return true
    }

    private var detailText: String {
        guard self.snapshot.lastSynchronizedTime != nil else {
            return String(
                localized: "network_time_waiting",
                comment: "Waiting for the first successful network time synchronization"
            )
        }

        let offset = String(format: "%+.3f ms", self.snapshot.clockOffset * 1_000)
        let roundTrip = String(format: "%.1f ms", self.snapshot.roundTripDelay * 1_000)
        return "\(offset)  •  \(roundTrip)"
    }

    private var accessibilitySummary: String {
        [
            self.localizedStatus,
            self.localizedTimeSource,
            "\(String(localized: "network_time_server")): \(self.snapshot.server ?? String(localized: "network_time_not_available"))",
            self.detailText
        ].joined(separator: ". ")
    }

    private var localizedStatus: String {
        switch self.snapshot.status {
        case .idle:
            return String(localized: "network_time_status_offline")
        case .synchronizing:
            return String(localized: "network_time_status_synchronizing")
        case .synchronized:
            return String(localized: "network_time_status_synchronized")
        case .failed:
            return String(localized: "network_time_status_failed")
        }
    }

    private var localizedTimeSource: String {
        String(
            localized: self.usesNetworkTime
                ? "network_time_source_network"
                : "network_time_source_local"
        )
    }

    var body: some View {
        HStack(spacing: 14) {
            Label(self.status.0, systemImage: self.status.1)
                .foregroundColor(self.status.2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(self.usesNetworkTime ? "network_time_source_network" : "network_time_source_local")
                .foregroundColor(Color(red: 107 / 255, green: 93 / 255, blue: 70 / 255))
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .trailing, spacing: 2) {
                Text(self.detailText)
                    .font(.system(size: 10, design: .monospaced))

                Text(self.snapshot.server ?? "—")
                    .font(.system(size: 9))
                    .foregroundColor(Color(red: 107 / 255, green: 93 / 255, blue: 70 / 255))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundColor(self.activeTheme.backgroundColour.lighter)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("accessibility_network_time_footer")
        .accessibilityValue(self.accessibilitySummary)
    }
}

private extension NetworkTimeDashboard {
    struct StatusPresentation {
        let title: LocalizedStringKey
        let color: Color
    }

    struct DashboardLabel: View {
        let title: LocalizedStringKey

        init(_ title: LocalizedStringKey) {
            self.title = title
        }

        var body: some View {
            Text(self.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(red: 107 / 255, green: 93 / 255, blue: 70 / 255))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    struct DashboardValue: View {
        let value: String
        let monospaced: Bool

        init(_ value: String, monospaced: Bool = false) {
            self.value = value
            self.monospaced = monospaced
        }

        var body: some View {
            Text(self.value)
                .font(
                    self.monospaced
                        ? .system(size: 12, weight: .regular, design: .monospaced)
                        : .system(size: 12, weight: .regular)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .textSelection(.enabled)
        }
    }
}
