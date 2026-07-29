//
//  MainView.swift
//  auto-clicker
//
//  Created by Ben Tindall on 27/03/2022.
//

import Defaults
import KeyboardShortcuts
import SwiftUI

struct MainView: View {
    @Default(.autoClickerState) private var formState

    @StateObject private var autoClickSimulator = AutoClickSimulator.shared
    @StateObject private var delayTimer = DelayTimer.shared
    @StateObject private var sntpService = SNTPService.shared

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    private var hasStarted: Bool {
        self.autoClickSimulator.isAutoClicking || self.delayTimer.isCountingDown
    }

    private var hasStopped: Bool {
        !self.autoClickSimulator.isAutoClicking && !self.delayTimer.isCountingDown
    }

    private var isTargetTimeValid: Bool {
        DelayTimer.targetDate(for: self.formState.targetTime) != nil
    }

    private var representativeInterval: Int {
        switch self.formState.intervalMode {
        case .staticInterval:
            return self.formState.pressInterval
        case .rangeInterval:
            let minimum = self.formState.pressIntervalMin ?? DEFAULT_PRESS_INTERVAL_MIN
            let maximum = self.formState.pressIntervalMax ?? DEFAULT_PRESS_INTERVAL_MAX
            return (minimum + maximum) / 2
        }
    }

    private var representativeIntervalSeconds: TimeInterval {
        self.formState.pressIntervalDuration.asTimeInterval(interval: self.representativeInterval)
    }

    private var clickRate: Double {
        guard self.representativeIntervalSeconds > 0 else {
            return 0
        }
        return 1 / self.representativeIntervalSeconds
    }

    private var estimatedDuration: TimeInterval {
        self.representativeIntervalSeconds * Double(self.formState.repeatAmount)
    }

    private var estimatedStartDate: Date? {
        switch self.formState.startMode {
        case .delay:
            return Date().addingTimeInterval(TimeInterval(self.formState.startDelay))
        case .targetTime:
            return DelayTimer.targetDate(
                for: self.formState.targetTime,
                now: self.sntpService.currentNetworkTime()
            )
        }
    }

    private var estimatedFinishDate: Date? {
        self.estimatedStartDate?.addingTimeInterval(self.estimatedDuration)
    }

    private var targetSummary: String {
        switch self.formState.startMode {
        case .delay:
            return String(
                format: NSLocalizedString(
                    "main_window_summary_delay_value",
                    comment: "Summary value for a delayed start"
                ),
                self.formState.startDelay
            )
        case .targetTime:
            return self.isTargetTimeValid ? self.formState.targetTime : "—"
        }
    }

    private var estimatedFinishSummary: String {
        guard let estimatedFinishDate else {
            return "—"
        }
        return Self.timeFormatter.string(from: estimatedFinishDate)
    }

    private var clickRateText: String {
        String(
            format: NSLocalizedString(
                "main_window_click_rate",
                comment: "Calculated clicks per second"
            ),
            self.clickRate
        )
    }

    private var estimatedDurationText: String {
        String(
            format: NSLocalizedString(
                "main_window_estimated_duration_value",
                comment: "Estimated duration in seconds"
            ),
            self.estimatedDuration
        )
    }

    private var synchronizationStatus: (LocalizedStringKey, Color) {
        switch self.sntpService.synchronization.status {
        case .idle:
            return ("network_time_status_offline", .autoClickerSecondaryText)
        case .synchronizing:
            return ("network_time_status_synchronizing", .autoClickerOchre)
        case .synchronized:
            return ("network_time_status_synchronized", .autoClickerSynchronizationGreen)
        case .failed:
            return ("network_time_status_failed", .autoClickerPrimary)
        }
    }

    func start() {
        if !self.hasStarted {
            let immediateFirstClick = self.formState.startMode == .targetTime
            self.delayTimer.start {
                self.autoClickSimulator.start(immediateFirstClick: immediateFirstClick)
            }
            MenuBarService.changeImageColour(newColor: .systemOrange)
        }
    }

    func stop() {
        self.delayTimer.stop()
        self.autoClickSimulator.stop()
    }

    func registerKeyboardShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .pressStartButton) { [self] in
            self.start()
        }

        KeyboardShortcuts.onKeyUp(for: .pressStopButton) { [self] in
            self.stop()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            self.header
                .padding(.bottom, 12)

            self.clickSettingsSection

            MockupDivider(color: Color.autoClickerSecondaryText.opacity(0.35))
                .padding(.vertical, 12)

            self.startModeSection

            NetworkTimeDashboard(service: self.sntpService)
                .padding(.top, 12)

            self.summaryStrip
                .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: 620)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.autoClickerPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.autoClickerInk, lineWidth: 2)
        )
        .overlay(alignment: .topTrailing) {
            DecorativeStar()
                .padding(.top, 10)
                .padding(.trailing, 14)
        }
        .overlay(alignment: .topTrailing) {
            DecorativeAccentStroke()
                .frame(width: 28, height: 14)
                .offset(x: -45, y: -7)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(self.painterlyBackground.ignoresSafeArea())
        .foregroundColor(.autoClickerBodyText)
        .onAppear(perform: self.registerKeyboardShortcuts)
    }

    private var painterlyBackground: some View {
        Color.autoClickerBackground
    }

    private var header: some View {
        HStack(spacing: 12) {
            BrandTargetMark()

            VStack(alignment: .leading, spacing: 0) {
                Text(Bundle.main.displayName)
                    .font(.system(size: 23, weight: .medium, design: .serif))
                    .italic()
                    .foregroundColor(.autoClickerInk)

                Text("main_window_tagline")
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(.autoClickerSecondaryText)
            }

            Spacer(minLength: 12)

            HStack(spacing: 7) {
                Circle()
                    .fill(self.synchronizationStatus.1)
                    .frame(width: 9, height: 9)

                Text(self.synchronizationStatus.0)
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(self.synchronizationStatus.1)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var clickSettingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            MockupSectionTitle(
                title: "main_window_click_settings",
                color: .autoClickerPrimary
            )

            self.clickIntervalRow

            MockupSettingsRow(title: "main_window_click_action") {
                HStack(spacing: 8) {
                    PressKeyListener()
                        .disabled(self.hasStarted)

                    CompactNumberField(
                        number: self.$formState.pressAmount,
                        minimum: MIN_PRESS_AMOUNT,
                        maximum: MAX_PRESS_AMOUNT,
                        accessibilityLabel: "accessibility_press_amount"
                    )
                    .frame(width: 70)
                    .disabled(self.hasStarted)

                    Text(
                        self.formState.pressAmount == 1
                            ? LocalizedStringKey("main_window_click")
                            : LocalizedStringKey("main_window_clicks")
                    )
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.autoClickerSecondaryText)
                }
            }

            MockupSettingsRow(title: "main_window_repeat_count") {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 7) {
                        CompactNumberField(
                            number: self.$formState.repeatAmount,
                            minimum: MIN_REPEAT_AMOUNT,
                            maximum: MAX_REPEAT_AMOUNT,
                            accessibilityLabel: "accessibility_repeat_amount"
                        )
                        .frame(width: 82)
                        .disabled(self.hasStarted)

                        Text(
                            self.formState.repeatAmount == 1
                                ? LocalizedStringKey("main_window_time")
                                : LocalizedStringKey("main_window_times")
                        )
                            .font(.system(size: 14, design: .serif))
                            .italic()
                            .foregroundColor(.autoClickerSecondaryText)
                    }

                    Text(self.estimatedDurationText)
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(.autoClickerSecondaryText)
                }
            }
        }
    }

    private var clickIntervalRow: some View {
        MockupSettingsRow(title: "main_window_click_interval") {
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 8) {
                    if self.formState.intervalMode == .rangeInterval {
                        CompactNumberField(
                            number: Binding(
                                get: { self.formState.pressIntervalMin ?? DEFAULT_PRESS_INTERVAL_MIN },
                                set: { self.formState.pressIntervalMin = $0 }
                            ),
                            minimum: MIN_PRESS_INTERVAL,
                            maximum: MAX_PRESS_INTERVAL,
                            accessibilityLabel: "accessibility_minimum_click_interval"
                        )
                        .frame(width: 78)

                        Text("main_window_to")

                        CompactNumberField(
                            number: Binding(
                                get: { self.formState.pressIntervalMax ?? DEFAULT_PRESS_INTERVAL_MAX },
                                set: { self.formState.pressIntervalMax = $0 }
                            ),
                            minimum: MIN_PRESS_INTERVAL,
                            maximum: MAX_PRESS_INTERVAL,
                            accessibilityLabel: "accessibility_maximum_click_interval"
                        )
                        .frame(width: 78)
                    } else {
                        CompactNumberField(
                            number: self.$formState.pressInterval,
                            minimum: MIN_PRESS_INTERVAL,
                            maximum: MAX_PRESS_INTERVAL,
                            accessibilityLabel: "accessibility_click_interval"
                        )
                        .frame(width: 82)
                    }

                    DurationSelector(selectedDuration: self.$formState.pressIntervalDuration)
                        .disabled(self.hasStarted)
                }

                Text(self.clickRateText)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .italic()
                    .foregroundColor(.autoClickerSecondaryText)
            }
        }
        .disabled(self.hasStarted)
    }

    private var startModeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            MockupSectionTitle(
                title: "main_window_start_mode",
                color: .autoClickerOchre
            )

            HStack(spacing: 8) {
                StartModeOptionButton(
                    title: "main_window_start_mode_delay",
                    isSelected: self.formState.startMode == .delay,
                    selectedColor: .autoClickerOchre
                ) {
                    self.formState.startMode = .delay
                }

                StartModeOptionButton(
                    title: "main_window_start_mode_target_time",
                    isSelected: self.formState.startMode == .targetTime,
                    selectedColor: .autoClickerOchre
                ) {
                    self.formState.startMode = .targetTime
                }
            }
            .disabled(self.hasStarted)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("accessibility_start_mode")
            .accessibilityHint("accessibility_start_mode_hint")

            if self.formState.startMode == .targetTime {
                MockupSettingsRow(title: "main_window_target_time_24_hour") {
                    TargetTimeFields(targetTime: self.$formState.targetTime)
                        .disabled(self.hasStarted)
                }
            } else {
                MockupSettingsRow(title: "main_window_delay_seconds") {
                    CompactNumberField(
                        number: self.$formState.startDelay,
                        minimum: MIN_START_DELAY,
                        maximum: MAX_START_DELAY,
                        accessibilityLabel: "accessibility_start_delay"
                    )
                    .frame(width: 92)
                    .disabled(self.hasStarted)
                }
            }

            HStack(spacing: 10) {
                Button(action: self.start) {
                    HStack(spacing: 7) {
                        Image(systemName: "play.fill")
                        Text(
                            self.hasStarted
                                ? self.delayTimer.countdownText
                                : String(localized: "main_window_start_btn")
                        )
                        .font(
                            self.hasStarted
                                ? .system(size: 17, weight: .bold, design: .monospaced)
                                : .system(size: 17, weight: .bold, design: .serif)
                        )
                        .monospacedDigit()
                        .fixedSize(horizontal: true, vertical: false)

                        if !self.hasStarted,
                           let shortcut = KeyboardShortcuts.Name.pressStartButton.shortcut
                            ?? KeyboardShortcuts.Name.pressStartButton.defaultShortcut {
                            Text(shortcut.description)
                                .font(.system(size: 12))
                                .opacity(0.85)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(MockupActionButtonStyle(
                    isPrimary: true,
                    primaryColor: .autoClickerPrimary,
                    inkColor: .autoClickerInk
                ))
                .disabled(
                    self.hasStarted
                        || (self.formState.startMode == .targetTime && !self.isTargetTimeValid)
                )
                .accessibilityLabel(
                    self.hasStarted
                        ? LocalizedStringKey("accessibility_start_countdown")
                        : LocalizedStringKey("main_window_start_btn")
                )
                .accessibilityHint(
                    self.hasStarted
                        ? LocalizedStringKey("accessibility_start_countdown_hint")
                        : LocalizedStringKey("accessibility_start_button_hint")
                )

                Button(action: self.stop) {
                    HStack(spacing: 7) {
                        Image(systemName: "stop.fill")
                        Text("main_window_stop_btn")
                            .font(.system(size: 17, design: .serif))

                        if let shortcut = KeyboardShortcuts.Name.pressStopButton.shortcut
                            ?? KeyboardShortcuts.Name.pressStopButton.defaultShortcut {
                            Text(shortcut.description)
                                .font(.system(size: 12))
                                .opacity(0.62)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(MockupActionButtonStyle(
                    isPrimary: false,
                    primaryColor: .autoClickerPrimary,
                    inkColor: .autoClickerInk
                ))
                .disabled(self.hasStopped)
                .accessibilityLabel("main_window_stop_btn")
                .accessibilityHint("accessibility_stop_button_hint")
            }

            Text("main_window_start_caption")
                .font(.system(size: 13, design: .serif))
                .italic()
                .foregroundColor(.autoClickerSecondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: 6) {
            SummaryTile(
                title: "main_window_summary_target_time",
                value: self.targetSummary
            )

            SummaryDivider()

            SummaryTile(
                title: "main_window_summary_estimated_finish",
                value: self.estimatedFinishSummary
            )

            SummaryDivider()

            SummaryTile(
                title: "main_window_summary_estimated_duration",
                value: self.estimatedDurationText
            )
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.autoClickerPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.autoClickerInk, lineWidth: 1.5)
        )
    }
}

private struct MockupSectionTitle: View {
    let title: LocalizedStringKey
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(self.title)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .italic()
                .foregroundColor(self.color)

            HandDrawnUnderline(color: self.color)
                .frame(width: 54, height: 8)
                .accessibilityHidden(true)
        }
    }
}

private struct BrandTargetMark: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.autoClickerPrimary)

            Circle()
                .fill(Color.autoClickerBlue)
                .padding(6)

            Circle()
                .fill(Color.autoClickerInk)
                .padding(10)
        }
        .frame(width: 28, height: 28)
        .accessibilityHidden(true)
    }
}

private struct DecorativeStar: View {
    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.autoClickerBlue)
            .accessibilityHidden(true)
    }
}

private struct DecorativeAccentStroke: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 1, y: 11))
            path.addCurve(
                to: CGPoint(x: 13, y: 5),
                control1: CGPoint(x: 5, y: 3),
                control2: CGPoint(x: 10, y: 2)
            )
            path.addCurve(
                to: CGPoint(x: 20, y: 12),
                control1: CGPoint(x: 16, y: 7),
                control2: CGPoint(x: 16, y: 13)
            )
            path.addCurve(
                to: CGPoint(x: 27, y: 8),
                control1: CGPoint(x: 23, y: 11),
                control2: CGPoint(x: 24, y: 7)
            )
        }
        .stroke(
            Color.autoClickerBlue,
            style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
        )
        .accessibilityHidden(true)
    }
}

private struct HandDrawnUnderline: View {
    let color: Color

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 5))
            path.addCurve(
                to: CGPoint(x: 18, y: 4),
                control1: CGPoint(x: 7, y: 1),
                control2: CGPoint(x: 12, y: 7)
            )
            path.addCurve(
                to: CGPoint(x: 36, y: 4),
                control1: CGPoint(x: 25, y: 1),
                control2: CGPoint(x: 30, y: 7)
            )
            path.addCurve(
                to: CGPoint(x: 54, y: 3),
                control1: CGPoint(x: 43, y: 1),
                control2: CGPoint(x: 49, y: 5)
            )
        }
        .stroke(
            self.color,
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
        )
    }
}

private struct MockupSettingsRow<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    init(
        title: LocalizedStringKey,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.content = content
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(self.title)
                .font(.system(size: 15, design: .serif))
                .frame(maxWidth: .infinity, alignment: .leading)

            self.content()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

private struct MockupDivider: View {
    let color: Color

    var body: some View {
        Rectangle()
            .fill(self.color)
            .frame(height: 1)
    }
}

private struct StartModeOptionButton: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            Text(self.title)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(.autoClickerInk)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(self.isSelected ? self.selectedColor : .autoClickerPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.autoClickerInk, lineWidth: 2)
        )
        .accessibilityAddTraits(self.isSelected ? .isSelected : [])
    }
}

struct MockupActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let isPrimary: Bool
    let primaryColor: Color
    let inkColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(self.isPrimary ? .autoClickerPanel : self.inkColor)
            .padding(.vertical, 13)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(self.isPrimary ? self.primaryColor : .autoClickerPanel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(self.inkColor, lineWidth: 1.5)
            )
            .opacity(self.isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct CompactNumberField: View {
    @Binding var number: Int

    let minimum: Int
    let maximum: Int
    let accessibilityLabel: LocalizedStringKey

    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", text: self.$draft)
            .textFieldStyle(.plain)
            .font(.system(size: 15, design: .monospaced))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .frame(height: 32)
            .foregroundColor(.autoClickerInk)
            .background(Color.autoClickerPanel)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color.autoClickerInk, lineWidth: 2)
            )
            .focused(self.$isFocused)
            .onAppear {
                self.draft = String(self.number)
            }
            .onChange(of: self.number) { newValue in
                if !self.isFocused {
                    self.draft = String(newValue)
                }
            }
            .onChange(of: self.draft) { newValue in
                let filtered = newValue.filter(\.isWholeNumber)
                if filtered != newValue {
                    self.draft = filtered
                }
            }
            .onChange(of: self.isFocused) { focused in
                if !focused {
                    self.commit()
                }
            }
            .onSubmit(self.commit)
            .accessibilityLabel(self.accessibilityLabel)
            .accessibilityValue(self.draft)
            .accessibilityHint(
                String(
                    format: NSLocalizedString(
                        "accessibility_number_range_hint",
                        comment: "Accessibility hint describing the allowed numeric range"
                    ),
                    self.minimum,
                    self.maximum
                )
            )
    }

    private func commit() {
        guard let value = Int(self.draft) else {
            self.draft = String(self.number)
            return
        }

        let clamped = min(max(value, self.minimum), self.maximum)
        self.number = clamped
        self.draft = String(clamped)
    }
}

private struct TargetTimeFields: View {
    @Binding var targetTime: String

    var body: some View {
        HStack(spacing: 5) {
            self.field(
                index: 0,
                maximum: 23,
                accessibilityLabel: "accessibility_target_time_hours"
            )

            Text(":")
                .font(.system(size: 17, design: .monospaced))

            self.field(
                index: 1,
                maximum: 59,
                accessibilityLabel: "accessibility_target_time_minutes"
            )

            Text(":")
                .font(.system(size: 17, design: .monospaced))

            self.field(
                index: 2,
                maximum: 59,
                accessibilityLabel: "accessibility_target_time_seconds"
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("accessibility_target_time")
        .accessibilityHint("accessibility_target_time_hint")
    }

    private func field(
        index: Int,
        maximum: Int,
        accessibilityLabel: LocalizedStringKey
    ) -> some View {
        return TextField(
            "",
            text: Binding(
                get: {
                    self.components[index]
                },
                set: { newValue in
                    self.updateComponent(
                        at: index,
                        value: newValue,
                        maximum: maximum
                    )
                }
            )
        )
        .textFieldStyle(.plain)
        .font(.system(size: 15, design: .monospaced))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 5)
        .frame(width: 46, height: 32)
        .foregroundColor(.autoClickerInk)
        .background(Color.autoClickerPanel)
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color.autoClickerInk, lineWidth: 2)
        )
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(self.components[index])
    }

    private var components: [String] {
        let parts = self.targetTime.split(
            separator: ":",
            omittingEmptySubsequences: false
        )
        guard parts.count == 3 else {
            return ["", "", ""]
        }
        return parts.map(String.init)
    }

    private func updateComponent(
        at index: Int,
        value: String,
        maximum: Int
    ) {
        let filtered = String(value.filter(\.isWholeNumber).prefix(2))
        guard filtered.isEmpty
                || (Int(filtered).map { $0 <= maximum } ?? false) else {
            return
        }

        var updated = self.components
        updated[index] = filtered
        self.targetTime = updated.joined(separator: ":")
    }
}

private struct SummaryTile: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(self.title)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(.autoClickerSecondaryText)
                .multilineTextAlignment(.center)

            Text(self.value)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(.horizontal, 5)
    }
}

private struct SummaryDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.autoClickerSecondaryText.opacity(0.28))
            .frame(width: 1, height: 32)
    }
}
