//
//  NetworkTimeDashboard.swift
//  auto-clicker
//

import SwiftUI

struct NetworkTimeDashboard: View {
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
                color: .autoClickerSecondaryText
            )
        case .synchronizing:
            return StatusPresentation(
                title: "network_time_status_synchronizing",
                color: .autoClickerOchre
            )
        case .synchronized:
            return StatusPresentation(
                title: "network_time_status_synchronized",
                color: .autoClickerSynchronizationGreen
            )
        case .failed:
            return StatusPresentation(
                title: "network_time_status_failed",
                color: .autoClickerPrimary
            )
        }
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
            localized: self.snapshot.hasUsableOffset
                ? "network_time_source_network"
                : "network_time_source_local"
        )
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
            .foregroundColor(.autoClickerBodyText)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 11)
                    .fill(Color.autoClickerBackground.opacity(0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .stroke(Color.autoClickerInk, lineWidth: 1.5)
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
                .foregroundColor(.autoClickerSecondaryText)

            Spacer(minLength: 12)

            Text(self.value)
                .font(
                    self.monospaced
                        ? .system(size: 13, weight: .medium, design: .monospaced)
                        : .system(size: 14, weight: .medium, design: .serif)
                )
                .foregroundColor(.autoClickerInk)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

private extension NetworkTimeDashboard {
    struct StatusPresentation {
        let title: LocalizedStringKey
        let color: Color
    }
}
