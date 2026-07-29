//
//  TimingDiagnostics.swift
//  auto-clicker
//

import Foundation
import os.log

/// Read-only timing data that an optional compensation component can consume.
///
/// Consumers depend on this protocol rather than the scheduler, keeping future
/// compensation entirely outside the scheduling implementation.
protocol TimingStatisticsProviding {
    func currentTimingSnapshot() -> TimingDiagnostics.Snapshot
}

/// Reserved configuration for a future diagnostics consumer.
///
/// No compensation is currently applied.
enum AdaptiveCompensationConfiguration {
    static let isEnabled = false
    static let minimumSampleCount: UInt64 = 100
}

/// Development-only measurements for scheduled click timing.
///
/// Deltas are expressed in seconds and are positive when execution is late.
/// Set `isEnabled` to `true` for development diagnostics. It is intentionally
/// disabled by default so production scheduling has no diagnostic overhead.
enum TimingDiagnostics {
    static let isEnabled = false
    static let summaryInterval: UInt64 = 100

    struct Measurement {
        let scheduledTime: DispatchTime
        let actualExecutionTime: DispatchTime
        let delta: TimeInterval
    }

    struct Statistics {
        let sampleCount: UInt64
        let averageDelta: TimeInterval
        let minimumDelta: TimeInterval
        let maximumDelta: TimeInterval
        let standardDeviation: TimeInterval

        fileprivate static let empty = Statistics(
            sampleCount: 0,
            averageDelta: 0,
            minimumDelta: 0,
            maximumDelta: 0,
            standardDeviation: 0
        )
    }

    struct Snapshot {
        let statistics: Statistics
        let averageExecutionDelta: TimeInterval
        let hasSufficientSamples: Bool
    }

    /// Read-only diagnostics source for a future compensation component.
    static let statisticsProvider = StatisticsProvider()

    private static let recorder = Recorder()

    /// Records a scheduled deadline and its actual execution timestamp.
    ///
    /// Both values must use `DispatchTime` so the measurement is unaffected by
    /// wall-clock adjustments. Recording and logging occur off the click path.
    @inline(__always)
    static func record(scheduled: DispatchTime, actual: DispatchTime?) {
        guard isEnabled, let actual else {
            return
        }

        recorder.record(
            scheduledNanoseconds: scheduled.uptimeNanoseconds,
            actualNanoseconds: actual.uptimeNanoseconds
        )
    }

    /// Returns a thread-safe snapshot of all measurements in this process.
    static func currentStatistics() -> Statistics {
        guard isEnabled else {
            return .empty
        }
        return recorder.currentStatistics()
    }

    /// Returns the most recently processed measurement, if one exists.
    static func latestMeasurement() -> Measurement? {
        guard isEnabled else {
            return nil
        }
        return recorder.latestMeasurement()
    }

    /// Clears all measurements collected in this process.
    static func reset() {
        guard isEnabled else {
            return
        }
        recorder.reset()
    }

    final class StatisticsProvider: TimingStatisticsProviding {
        fileprivate init() {}

        func currentTimingSnapshot() -> Snapshot {
            let statistics = TimingDiagnostics.currentStatistics()
            return Snapshot(
                statistics: statistics,
                averageExecutionDelta: statistics.averageDelta,
                hasSufficientSamples: statistics.sampleCount
                    >= AdaptiveCompensationConfiguration.minimumSampleCount
            )
        }
    }
}

private extension TimingDiagnostics {
    final class Recorder {
        private static let nanosecondsPerSecond = 1_000_000_000.0

        private let queue = DispatchQueue(
            label: "com.autoclicker.timing-diagnostics",
            qos: .utility
        )
        private let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "AutoClickerPro",
            category: "TimingDiagnostics"
        )

        private var sampleCount: UInt64 = 0
        private var averageDelta: TimeInterval = 0
        private var squaredDeviationSum: TimeInterval = 0
        private var minimumDelta = TimeInterval.infinity
        private var maximumDelta = -TimeInterval.infinity
        private var lastMeasurement: Measurement?

        func record(
            scheduledNanoseconds: UInt64,
            actualNanoseconds: UInt64
        ) {
            queue.async { [self] in
                let delta = Self.interval(
                    from: scheduledNanoseconds,
                    to: actualNanoseconds
                )
                lastMeasurement = Measurement(
                    scheduledTime: DispatchTime(
                        uptimeNanoseconds: scheduledNanoseconds
                    ),
                    actualExecutionTime: DispatchTime(
                        uptimeNanoseconds: actualNanoseconds
                    ),
                    delta: delta
                )
                updateStatistics(with: delta)
                logSummaryIfNeeded()
            }
        }

        func currentStatistics() -> Statistics {
            queue.sync {
                statistics
            }
        }

        func latestMeasurement() -> Measurement? {
            queue.sync {
                lastMeasurement
            }
        }

        func reset() {
            queue.async { [self] in
                sampleCount = 0
                averageDelta = 0
                squaredDeviationSum = 0
                minimumDelta = .infinity
                maximumDelta = -.infinity
                lastMeasurement = nil
            }
        }

        private var statistics: Statistics {
            guard sampleCount > 0 else {
                return .empty
            }

            return Statistics(
                sampleCount: sampleCount,
                averageDelta: averageDelta,
                minimumDelta: minimumDelta,
                maximumDelta: maximumDelta,
                standardDeviation: sqrt(
                    squaredDeviationSum / Double(sampleCount)
                )
            )
        }

        private func updateStatistics(with delta: TimeInterval) {
            sampleCount += 1

            let difference = delta - averageDelta
            averageDelta += difference / Double(sampleCount)
            let updatedDifference = delta - averageDelta
            squaredDeviationSum += difference * updatedDifference

            minimumDelta = min(minimumDelta, delta)
            maximumDelta = max(maximumDelta, delta)
        }

        private func logSummaryIfNeeded() {
            guard sampleCount.isMultiple(
                of: TimingDiagnostics.summaryInterval
            ) else {
                return
            }

            let averageMilliseconds = String(
                format: "%+.3f",
                averageDelta * 1_000
            )
            let minimumMilliseconds = String(
                format: "%+.3f",
                minimumDelta * 1_000
            )
            let maximumMilliseconds = String(
                format: "%+.3f",
                maximumDelta * 1_000
            )
            let standardDeviationMilliseconds = String(
                format: "%.3f",
                statistics.standardDeviation * 1_000
            )

            logger.debug(
                """
                Timing Diagnostics | Samples: \(self.sampleCount) | \
                Average: \(averageMilliseconds, privacy: .public) ms | \
                Minimum: \(minimumMilliseconds, privacy: .public) ms | \
                Maximum: \(maximumMilliseconds, privacy: .public) ms | \
                StdDev: \(standardDeviationMilliseconds, privacy: .public) ms
                """
            )
        }

        private static func interval(
            from startNanoseconds: UInt64,
            to endNanoseconds: UInt64
        ) -> TimeInterval {
            if endNanoseconds >= startNanoseconds {
                return Double(endNanoseconds - startNanoseconds)
                    / nanosecondsPerSecond
            }
            return -Double(startNanoseconds - endNanoseconds)
                / nanosecondsPerSecond
        }
    }
}
