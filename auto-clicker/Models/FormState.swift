//
//  FormState.swift
//  auto-clicker
//
//  Created by Ben Tindall on 10/04/2022.
//

import Defaults

enum IntervalMode: String, Codable, CaseIterable, Identifiable {
    case staticInterval
    case rangeInterval

    var id: String { self.rawValue }
}

enum StartMode: String, Codable, CaseIterable, Identifiable {
    case delay
    case targetTime

    var id: String { self.rawValue }
}

struct FormState: Codable, Defaults.Serializable {
    var intervalMode: IntervalMode // new: static or range
    var pressInterval: Int
    var pressIntervalMin: Int? // new: for range
    var pressIntervalMax: Int? // new: for range
    var pressIntervalDuration: Duration
    var pressInput: Input
    var pressAmount: Int
    var startDelay: Int
    var startMode: StartMode
    var targetTime: String
    var repeatAmount: Int
}

extension FormState {
    private static let defaultTargetTime = "00:00:00"

    init() {
        self.intervalMode = .staticInterval
        self.pressInterval = DEFAULT_PRESS_INTERVAL
        self.pressIntervalMin = nil
        self.pressIntervalMax = nil
        self.pressIntervalDuration = Duration.milliseconds
        self.pressInput = Input()
        self.pressAmount = DEFAULT_PRESS_AMOUNT
        self.startDelay = DEFAULT_START_DELAY
        self.startMode = .delay
        self.targetTime = Self.defaultTargetTime
        self.repeatAmount = DEFAULT_REPEAT_AMOUNT
    }

    private enum CodingKeys: String, CodingKey {
        case intervalMode
        case pressInterval
        case pressIntervalMin
        case pressIntervalMax
        case pressIntervalDuration
        case pressInput
        case pressAmount
        case startDelay
        case startMode
        case targetTime
        case repeatAmount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.intervalMode = try container.decodeIfPresent(IntervalMode.self, forKey: .intervalMode) ?? .staticInterval
        self.pressInterval = try container.decode(Int.self, forKey: .pressInterval)
        self.pressIntervalMin = try container.decodeIfPresent(Int.self, forKey: .pressIntervalMin)
        self.pressIntervalMax = try container.decodeIfPresent(Int.self, forKey: .pressIntervalMax)
        self.pressIntervalDuration = try container.decode(Duration.self, forKey: .pressIntervalDuration)
        self.pressInput = try container.decode(Input.self, forKey: .pressInput)
        self.pressAmount = try container.decode(Int.self, forKey: .pressAmount)
        self.startDelay = try container.decode(Int.self, forKey: .startDelay)
        self.startMode = try container.decodeIfPresent(StartMode.self, forKey: .startMode) ?? .delay
        let storedTargetTime = try container.decodeIfPresent(String.self, forKey: .targetTime)
            ?? Self.defaultTargetTime
        self.targetTime = Self.migrateLegacyTargetTime(storedTargetTime)
        self.repeatAmount = try container.decode(Int.self, forKey: .repeatAmount)
    }

    private static func migrateLegacyTargetTime(_ value: String) -> String {
        let timeParts = value.split(separator: ":", omittingEmptySubsequences: false)
        guard timeParts.count == 3,
              timeParts[0].count == 2,
              timeParts[1].count == 2 else {
            return value
        }

        let secondParts = timeParts[2].split(separator: ".", omittingEmptySubsequences: false)
        guard secondParts.count == 2,
              secondParts[0].count == 2,
              secondParts[1].count == 3,
              let hour = Int(timeParts[0]),
              let minute = Int(timeParts[1]),
              let second = Int(secondParts[0]),
              let millisecond = Int(secondParts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute),
              (0...59).contains(second),
              (0...999).contains(millisecond) else {
            return value
        }

        return "\(timeParts[0]):\(timeParts[1]):\(secondParts[0])"
    }
}
