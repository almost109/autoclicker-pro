//
//  DelayTimer.swift
//  auto-clicker
//
//  Created by Ben Tindall on 12/05/2021.
//

import Foundation
import Defaults
import Combine

@MainActor
final class DelayTimer: ObservableObject {
    static let shared: DelayTimer = .init()
    private init() {}

    private static let defaultCountdownText: String = "-"
    private static let countdownInterval: DispatchTimeInterval = .milliseconds(40)
    private static let countdownLeeway: DispatchTimeInterval = .milliseconds(2)

    @Published private(set) var isCountingDown = false
    @Published private(set) var countdownText: String = DelayTimer.defaultCountdownText

    private var onFinish: (() -> Void)?
    private var remainingDelaySeconds: Int = DEFAULT_START_DELAY
    private var delayTimer: Timer?
    private var countdownTimer: DispatchSourceTimer?
    private var targetTimestamp: TimeInterval?
    private var activity: Cancellable?
    private lazy var targetScheduler = HighPrecisionScheduler(
        spinThreshold: 0.005
    ) {
        SNTPService.shared.currentNetworkTimestamp()
    }

    func start(onFinish: @escaping () -> Void) {
        if Defaults[.autoClickerState].startMode == .targetTime {
            self.startAtTargetTime(onFinish: onFinish)
            return
        }

        let delayInSeconds = Defaults[.autoClickerState].startDelay

        self.onFinish = onFinish
        MenuBarService.updateExecutionState(isRunning: true)

        if delayInSeconds > 0 {
            self.remainingDelaySeconds = delayInSeconds
            self.isCountingDown = true
            self.activity = ProcessInfo.processInfo.beginActivity(.delayTimer)

            self.updateButtonText()

            self.delayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.tick()
                }
            }
        } else {
            self.finish()
        }
    }

    nonisolated static func targetDate(for time: String, now: Date = Date(), calendar: Calendar = .current) -> Date? {
        let parts = time.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 2,
              parts[1].count == 2,
              parts[2].count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              let second = Int(parts[2]),
              (0...23).contains(hour),
              (0...59).contains(minute),
              (0...59).contains(second) else {
            return nil
        }

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = second
        components.nanosecond = 0

        guard let today = calendar.date(from: components) else {
            return nil
        }

        if today > now {
            return today
        }

        return calendar.date(byAdding: .day, value: 1, to: today)
    }

    private func startAtTargetTime(onFinish: @escaping () -> Void) {
        let networkClockNow = SNTPService.shared.currentNetworkTime()
        guard let targetDate = Self.targetDate(
            for: Defaults[.autoClickerState].targetTime,
            now: networkClockNow
        ) else {
            return
        }

        self.onFinish = onFinish
        self.isCountingDown = true
        self.activity = ProcessInfo.processInfo.beginActivity(.delayTimer)
        MenuBarService.updateExecutionState(isRunning: true)

        let targetTimestamp = targetDate.timeIntervalSinceReferenceDate
        self.targetTimestamp = targetTimestamp
        self.updateTargetCountdown()

        self.targetScheduler.schedule(at: targetTimestamp) { [weak self] in
            self?.targetTimeReached()
        }

        let countdownTimer = DispatchSource.makeTimerSource(queue: .main)
        countdownTimer.schedule(
            deadline: .now(),
            repeating: Self.countdownInterval,
            leeway: Self.countdownLeeway
        )
        countdownTimer.setEventHandler { [weak self] in
            self?.updateTargetCountdown()
        }
        self.countdownTimer = countdownTimer
        countdownTimer.resume()
    }

    private func targetTimeReached() {
        self.finish()
    }

    private func tick() {
        self.remainingDelaySeconds -= 1

        self.updateButtonText()

        if self.remainingDelaySeconds <= 0 {
            self.finish()
        }
    }

    func stop() {
        self.delayTimer?.invalidate()
        self.delayTimer = nil

        self.targetScheduler.cancel()
        self.cancelDispatchTimer(&self.countdownTimer)
        self.resetCountdownState()
        self.onFinish = nil

        self.activity?.cancel()
        self.activity = nil
    }

    private func updateButtonText() {
        self.countdownText = String(self.remainingDelaySeconds)
    }

    private func updateTargetCountdown() {
        guard let targetTimestamp = self.targetTimestamp else {
            return
        }

        let remaining = max(
            0,
            targetTimestamp - SNTPService.shared.currentNetworkTimestamp()
        )
        let millisecondsRemaining = Int(ceil(remaining * 1_000))
        let minutes = millisecondsRemaining / 60_000
        let seconds = (millisecondsRemaining % 60_000) / 1_000
        let milliseconds = millisecondsRemaining % 1_000
        self.countdownText = String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }

    private func finish() {
        let completion = self.onFinish
        self.stop()
        completion?()
    }

    private func cancelDispatchTimer(_ timer: inout DispatchSourceTimer?) {
        timer?.cancel()
        timer = nil
    }

    private func resetCountdownState() {
        self.targetTimestamp = nil
        self.remainingDelaySeconds = DEFAULT_START_DELAY
        self.countdownText = Self.defaultCountdownText
        self.isCountingDown = false
    }
}
