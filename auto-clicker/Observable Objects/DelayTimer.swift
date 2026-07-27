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
    private static let targetTimerLeeway: DispatchTimeInterval = .milliseconds(1)
    private static let countdownInterval: DispatchTimeInterval = .milliseconds(40)
    private static let countdownLeeway: DispatchTimeInterval = .milliseconds(2)

    @Published private(set) var isCountingDown = false
    @Published private(set) var remainingDelaySeconds: Int = DEFAULT_START_DELAY
    @Published private(set) var countdownText: String = DelayTimer.defaultCountdownText

    private var onFinish: (() -> Void)?
    private var delayTimer: Timer?
    private var targetTimer: DispatchSourceTimer?
    private var countdownTimer: DispatchSourceTimer?
    private var targetDeadline: DispatchTime?
    private var activity: Cancellable?

    func start(onFinish: @escaping () -> Void) {
        if Defaults[.autoClickerState].startMode == .targetTime {
            self.startAtTargetTime(onFinish: onFinish)
            return
        }

        let delayInSeconds = Defaults[.autoClickerState].startDelay

        self.onFinish = onFinish
        self.updateMenuState(isWaiting: true)

        if delayInSeconds > 0 {
            self.remainingDelaySeconds = delayInSeconds
            self.isCountingDown = true
            self.activity = ProcessInfo.processInfo.beginActivity(.delayTimer)

            self.updateButtonText()

            self.delayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
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
              parts[1].count == 2 else {
            return nil
        }

        let secondParts = parts[2].split(separator: ".", omittingEmptySubsequences: false)
        guard secondParts.count == 2,
              secondParts[0].count == 2,
              secondParts[1].count == 3,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              let second = Int(secondParts[0]),
              let millisecond = Int(secondParts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute),
              (0...59).contains(second) else {
            return nil
        }

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = second
        components.nanosecond = millisecond * 1_000_000

        guard let today = calendar.date(from: components) else {
            return nil
        }

        if today > now {
            return today
        }

        return calendar.date(byAdding: .day, value: 1, to: today)
    }

    private func startAtTargetTime(onFinish: @escaping () -> Void) {
        let wallClockNow = Date()
        guard let targetDate = Self.targetDate(
            for: Defaults[.autoClickerState].targetTime,
            now: wallClockNow
        ) else {
            return
        }

        self.onFinish = onFinish
        self.isCountingDown = true
        self.activity = ProcessInfo.processInfo.beginActivity(.delayTimer)
        self.updateMenuState(isWaiting: true)

        let remaining = max(0, targetDate.timeIntervalSince(wallClockNow))
        let deadline = DispatchTime.now() + remaining
        self.targetDeadline = deadline
        self.updateTargetCountdown()

        let targetTimer = DispatchSource.makeTimerSource(queue: .main)
        targetTimer.schedule(deadline: deadline, leeway: Self.targetTimerLeeway)
        targetTimer.setEventHandler { [weak self] in
            self?.targetTimeReached()
        }
        self.targetTimer = targetTimer
        targetTimer.resume()

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

    func tick() {
        self.remainingDelaySeconds -= 1

        self.updateButtonText()

        if self.remainingDelaySeconds <= 0 {
            self.finish()
        }
    }

    func stop() {
        self.delayTimer?.invalidate()
        self.delayTimer = nil

        self.cancelDispatchTimer(&self.targetTimer)
        self.cancelDispatchTimer(&self.countdownTimer)
        self.resetCountdownState()
        self.onFinish = nil

        self.activity?.cancel()
        self.activity = nil
    }

    func updateButtonText() {
        self.countdownText = String(self.remainingDelaySeconds)
    }

    private func updateTargetCountdown() {
        guard let targetDeadline = self.targetDeadline else {
            return
        }

        let now = DispatchTime.now().uptimeNanoseconds
        let deadline = targetDeadline.uptimeNanoseconds
        let nanosecondsRemaining = deadline > now ? deadline - now : 0
        let millisecondsRemaining = Int((nanosecondsRemaining + 999_999) / 1_000_000)
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

    private func updateMenuState(isWaiting: Bool) {
        MenuBarService.startMenuItem?.isEnabled = !isWaiting
        MenuBarService.stopMenuItem?.isEnabled = isWaiting
    }

    private func cancelDispatchTimer(_ timer: inout DispatchSourceTimer?) {
        timer?.cancel()
        timer = nil
    }

    private func resetCountdownState() {
        self.targetDeadline = nil
        self.remainingDelaySeconds = DEFAULT_START_DELAY
        self.countdownText = Self.defaultCountdownText
        self.isCountingDown = false
    }
}
