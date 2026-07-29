//
//  HighPrecisionScheduler.swift
//  auto-clicker
//

import Darwin
import Foundation

/// Schedules a one-shot action using synchronized time for alignment and
/// monotonic uptime for all subsequent waiting.
final class HighPrecisionScheduler {
    typealias Timestamp = TimeInterval
    typealias Clock = () -> Timestamp

    private struct Schedule {
        let generation: UInt
        let deadline: DispatchTime
        let completion: () -> Void
    }

    private static let coarseThreshold: TimeInterval = 1
    private static let fineThreshold: TimeInterval = 0.1
    private static let tightSpinThreshold: TimeInterval = 0.000_25

    private static let coarseCheckInterval: TimeInterval = 0.5
    private static let fineCheckInterval: TimeInterval = 0.01
    private static let preciseCheckInterval: TimeInterval = 0.001
    private static let timerLeeway: DispatchTimeInterval = .milliseconds(1)

    private let schedulingQueue: DispatchQueue
    private let completionQueue: DispatchQueue
    private let synchronizedClock: Clock
    private let spinThreshold: TimeInterval
    private let stateLock = NSLock()
    private let timer: DispatchSourceTimer

    private var schedule: Schedule?
    private var generation: UInt = 0

    init(
        spinThreshold: TimeInterval = 0.005,
        schedulingQueue: DispatchQueue = DispatchQueue(
            label: "com.autoclicker.high-precision-scheduler",
            qos: .userInteractive
        ),
        completionQueue: DispatchQueue = .main,
        clock: @escaping Clock
    ) {
        self.spinThreshold = max(spinThreshold, Self.tightSpinThreshold)
        self.schedulingQueue = schedulingQueue
        self.completionQueue = completionQueue
        self.synchronizedClock = clock

        let timer = DispatchSource.makeTimerSource(queue: schedulingQueue)
        self.timer = timer
        timer.setEventHandler { [weak self] in
            self?.evaluate()
        }
        timer.resume()
    }

    deinit {
        self.timer.cancel()
    }

    func schedule(
        at target: Timestamp,
        completion: @escaping () -> Void
    ) {
        let delay = max(0, target - self.synchronizedClock())
        let deadline = DispatchTime.now() + delay

        self.stateLock.lock()
        self.generation &+= 1
        self.schedule = Schedule(
            generation: self.generation,
            deadline: deadline,
            completion: completion
        )
        self.timer.schedule(deadline: .now())
        self.stateLock.unlock()
    }

    func cancel() {
        self.stateLock.lock()
        self.generation &+= 1
        self.schedule = nil
        self.stateLock.unlock()
    }

    private func evaluate() {
        guard let schedule = self.currentSchedule else {
            return
        }

        let remaining = Self.remainingTime(until: schedule.deadline)
        guard remaining > self.spinThreshold else {
            self.waitForDeadline(schedule)
            return
        }

        self.reschedule(
            after: self.waitInterval(for: remaining),
            generation: schedule.generation
        )
    }

    private func waitInterval(for remaining: TimeInterval) -> TimeInterval {
        if remaining > Self.coarseThreshold {
            return min(Self.coarseCheckInterval, remaining - Self.coarseThreshold)
        }

        if remaining > Self.fineThreshold {
            return min(Self.fineCheckInterval, remaining - Self.fineThreshold)
        }

        return min(Self.preciseCheckInterval, remaining - self.spinThreshold)
    }

    private func waitForDeadline(_ schedule: Schedule) {
        while self.isCurrent(schedule.generation) {
            let remaining = Self.remainingTime(until: schedule.deadline)
            guard remaining > 0 else {
                self.complete(schedule)
                return
            }

            if remaining > Self.tightSpinThreshold {
                sched_yield()
                continue
            }

            while Self.remainingTime(until: schedule.deadline) > 0 {
                // The tight spin is intentionally limited to a few hundred microseconds.
            }
            self.complete(schedule)
            return
        }
    }

    private var currentSchedule: Schedule? {
        self.stateLock.lock()
        defer { self.stateLock.unlock() }
        return self.schedule
    }

    private func isCurrent(_ generation: UInt) -> Bool {
        self.stateLock.lock()
        defer { self.stateLock.unlock() }
        return self.schedule?.generation == generation
    }

    private func reschedule(after delay: TimeInterval, generation: UInt) {
        self.stateLock.lock()
        guard self.schedule?.generation == generation else {
            self.stateLock.unlock()
            return
        }
        self.timer.schedule(
            deadline: .now() + max(0, delay),
            leeway: Self.timerLeeway
        )
        self.stateLock.unlock()
    }

    private func complete(_ completedSchedule: Schedule) {
        self.stateLock.lock()
        guard self.schedule?.generation == completedSchedule.generation else {
            self.stateLock.unlock()
            return
        }
        self.schedule = nil
        self.stateLock.unlock()

        self.completionQueue.async { [weak self] in
            guard let self else {
                return
            }

            self.stateLock.lock()
            let shouldComplete = self.generation == completedSchedule.generation
            self.stateLock.unlock()

            guard shouldComplete else {
                return
            }

            guard TimingDiagnostics.isEnabled else {
                completedSchedule.completion()
                return
            }

            let actualExecutionTime = DispatchTime.now()
            completedSchedule.completion()

            TimingDiagnostics.record(
                scheduled: completedSchedule.deadline,
                actual: actualExecutionTime
            )
        }
    }

    private static func remainingTime(until deadline: DispatchTime) -> TimeInterval {
        let now = DispatchTime.now().uptimeNanoseconds
        let target = deadline.uptimeNanoseconds
        guard target > now else {
            return 0
        }
        return TimeInterval(target - now) / 1_000_000_000
    }
}
