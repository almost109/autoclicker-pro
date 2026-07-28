//
//  SNTPService.swift
//  auto-clicker
//

import Combine
import Foundation
import Network

enum TimeSynchronizationStatus: Equatable {
    case idle
    case synchronizing
    case synchronized(server: String)
    case failed
}

struct TimeSynchronizationSnapshot: Equatable {
    var lastSynchronizedTime: Date?
    var clockOffset: TimeInterval
    var roundTripDelay: TimeInterval
    var status: TimeSynchronizationStatus

    static let initial = TimeSynchronizationSnapshot(
        lastSynchronizedTime: nil,
        clockOffset: 0,
        roundTripDelay: 0,
        status: .idle
    )
}

final class SNTPService: ObservableObject {
    static let shared = SNTPService()

    @Published private(set) var synchronization = TimeSynchronizationSnapshot.initial

    private static let ntpEpochOffset: TimeInterval = 2_208_988_800
    private static let ntpEraDuration: TimeInterval = 4_294_967_296
    private static let packetLength = 48
    private static let synchronizationInterval: DispatchTimeInterval = .seconds(10 * 60)
    private static let synchronizationLeeway: DispatchTimeInterval = .seconds(15)
    private static let requestTimeout: DispatchTimeInterval = .seconds(3)

    private let servers = [
        "time.apple.com",
        "time.cloudflare.com",
        "pool.ntp.org"
    ]
    private let queue = DispatchQueue(label: "com.autoclicker.sntp", qos: .utility)
    private let stateLock = NSLock()

    private var state = TimeSynchronizationSnapshot.initial
    private var synchronizationTimer: DispatchSourceTimer?
    private var activeRequest: RequestContext?
    private var isSynchronizationInProgress = false

    private init() {}

    func startSynchronizing() {
        self.queue.async { [weak self] in
            guard let self, self.synchronizationTimer == nil else {
                return
            }

            let timer = DispatchSource.makeTimerSource(queue: self.queue)
            timer.schedule(
                deadline: .now(),
                repeating: Self.synchronizationInterval,
                leeway: Self.synchronizationLeeway
            )
            timer.setEventHandler { [weak self] in
                self?.synchronizeIfNeeded()
            }
            self.synchronizationTimer = timer
            timer.resume()
        }
    }

    func synchronizeNow() {
        self.queue.async { [weak self] in
            self?.synchronizeIfNeeded()
        }
    }

    func stopSynchronizing() {
        self.queue.sync {
            self.synchronizationTimer?.cancel()
            self.synchronizationTimer = nil

            if let activeRequest = self.activeRequest {
                self.cancel(activeRequest)
            }

            self.isSynchronizationInProgress = false
            self.updateState { $0.status = .idle }
        }
    }

    func currentNetworkTime() -> Date {
        Date().addingTimeInterval(self.currentOffset())
    }

    func currentOffset() -> TimeInterval {
        self.withState { snapshot in
            snapshot.hasUsableOffset ? snapshot.clockOffset : 0
        }
    }

    func isSynchronized() -> Bool {
        self.withState(\.hasUsableOffset)
    }

    func currentSynchronization() -> TimeSynchronizationSnapshot {
        self.withState { $0 }
    }

    private func synchronizeIfNeeded() {
        guard !self.isSynchronizationInProgress else {
            return
        }

        self.isSynchronizationInProgress = true
        self.updateState { $0.status = .synchronizing }
        self.tryServer(at: 0)
    }

    private func tryServer(at index: Int) {
        guard self.servers.indices.contains(index) else {
            self.completeWithFailure()
            return
        }

        let server = self.servers[index]
        self.query(server: server) { [weak self] result in
            guard let self else {
                return
            }

            switch result {
            case let .success(measurement):
                self.complete(with: measurement)
            case let .failure(error):
                LoggerService.sntpFailure(server: server, error: error)
                self.tryServer(at: index + 1)
            }
        }
    }

    private func complete(with measurement: Measurement) {
        self.isSynchronizationInProgress = false
        self.updateState {
            $0.lastSynchronizedTime = measurement.synchronizedAt
            $0.clockOffset = measurement.clockOffset
            $0.roundTripDelay = measurement.roundTripDelay
            $0.status = .synchronized(server: measurement.server)
        }
        LoggerService.sntpSuccess(
            server: measurement.server,
            offset: measurement.clockOffset,
            roundTripDelay: measurement.roundTripDelay
        )
    }

    private func completeWithFailure() {
        self.isSynchronizationInProgress = false
        self.updateState {
            $0.clockOffset = 0
            $0.roundTripDelay = 0
            $0.status = .failed
        }
    }

    private func query(
        server: String,
        completion: @escaping (Result<Measurement, Error>) -> Void
    ) {
        guard let ntpPort = NWEndpoint.Port(rawValue: 123) else {
            completion(.failure(SNTPError.invalidPort))
            return
        }

        let connection = NWConnection(
            host: NWEndpoint.Host(server),
            port: ntpPort,
            using: .udp
        )
        let request = RequestContext(server: server, connection: connection, completion: completion)
        self.activeRequest = request

        let timeout = DispatchWorkItem { [weak self, weak request] in
            guard let self, let request else {
                return
            }
            self.finish(request, with: .failure(SNTPError.timedOut))
        }
        request.timeout = timeout
        self.queue.asyncAfter(deadline: .now() + Self.requestTimeout, execute: timeout)

        connection.stateUpdateHandler = { [weak self, weak request] state in
            guard let self, let request else {
                return
            }

            switch state {
            case .ready:
                self.sendRequest(request)
            case let .failed(error):
                self.finish(request, with: .failure(error))
            default:
                break
            }
        }
        connection.start(queue: self.queue)
    }

    private func sendRequest(_ request: RequestContext) {
        guard !request.hasSentRequest else {
            return
        }
        request.hasSentRequest = true

        let transmitTime = Date().timeIntervalSince1970
        let packet = Self.makeRequestPacket(transmitTime: transmitTime)
        request.transmitTime = transmitTime
        request.transmitTimestamp = Array(packet[40..<48])

        request.connection.send(content: packet, completion: .contentProcessed { [weak self, weak request] error in
            guard let self, let request else {
                return
            }

            if let error {
                self.finish(request, with: .failure(error))
                return
            }

            request.connection.receiveMessage { [weak self, weak request] data, _, _, error in
                guard let self, let request else {
                    return
                }

                if let error {
                    self.finish(request, with: .failure(error))
                    return
                }

                let receiveTime = Date().timeIntervalSince1970
                do {
                    let measurement = try Self.measurement(
                        from: data,
                        server: request.server,
                        transmitTime: request.transmitTime,
                        receiveTime: receiveTime,
                        expectedOriginateTimestamp: request.transmitTimestamp
                    )
                    self.finish(request, with: .success(measurement))
                } catch {
                    self.finish(request, with: .failure(error))
                }
            }
        })
    }

    private func finish(
        _ request: RequestContext,
        with result: Result<Measurement, Error>
    ) {
        guard !request.isComplete else {
            return
        }

        request.isComplete = true
        request.timeout?.cancel()
        request.timeout = nil
        request.connection.stateUpdateHandler = nil
        request.connection.cancel()

        if self.activeRequest === request {
            self.activeRequest = nil
        }

        request.completion(result)
    }

    private func cancel(_ request: RequestContext) {
        guard !request.isComplete else {
            return
        }

        request.isComplete = true
        request.timeout?.cancel()
        request.timeout = nil
        request.connection.stateUpdateHandler = nil
        request.connection.cancel()

        if self.activeRequest === request {
            self.activeRequest = nil
        }
    }

    private func updateState(_ update: (inout TimeSynchronizationSnapshot) -> Void) {
        self.stateLock.lock()
        update(&self.state)
        let updatedState = self.state
        self.stateLock.unlock()

        DispatchQueue.main.async { [weak self] in
            self?.synchronization = updatedState
        }
    }

    private func withState<T>(_ read: (TimeSynchronizationSnapshot) -> T) -> T {
        self.stateLock.lock()
        defer { self.stateLock.unlock() }
        return read(self.state)
    }

    private static func makeRequestPacket(transmitTime: TimeInterval) -> Data {
        var bytes = [UInt8](repeating: 0, count: Self.packetLength)
        bytes[0] = 0x23 // No leap warning, NTP v4, client mode.
        Self.writeTimestamp(transmitTime, to: &bytes, at: 40)
        return Data(bytes)
    }

    private static func measurement(
        from data: Data?,
        server: String,
        transmitTime: TimeInterval,
        receiveTime: TimeInterval,
        expectedOriginateTimestamp: [UInt8]
    ) throws -> Measurement {
        guard let data, data.count >= Self.packetLength else {
            throw SNTPError.invalidPacket
        }

        let bytes = [UInt8](data)
        let leapIndicator = bytes[0] >> 6
        let version = (bytes[0] >> 3) & 0x07
        let mode = bytes[0] & 0x07
        let stratum = bytes[1]
        guard leapIndicator != 3,
              version == 3 || version == 4,
              mode == 4 || mode == 5,
              (1...15).contains(stratum),
              expectedOriginateTimestamp.count == 8,
              Array(bytes[24..<32]) == expectedOriginateTimestamp,
              bytes[32..<40].contains(where: { $0 != 0 }),
              bytes[40..<48].contains(where: { $0 != 0 }) else {
            throw SNTPError.invalidPacket
        }

        let serverReceiveTime = try Self.readTimestamp(
            from: bytes,
            at: 32,
            relativeTo: transmitTime
        )
        let serverTransmitTime = try Self.readTimestamp(
            from: bytes,
            at: 40,
            relativeTo: transmitTime
        )
        let clockOffset = (
            (serverReceiveTime - transmitTime)
            + (serverTransmitTime - receiveTime)
        ) / 2
        let roundTripDelay = max(
            0,
            (receiveTime - transmitTime)
            - (serverTransmitTime - serverReceiveTime)
        )

        return Measurement(
            server: server,
            synchronizedAt: Date(timeIntervalSince1970: receiveTime),
            clockOffset: clockOffset,
            roundTripDelay: roundTripDelay
        )
    }

    private static func writeTimestamp(
        _ unixTime: TimeInterval,
        to bytes: inout [UInt8],
        at offset: Int
    ) {
        let ntpTime = unixTime + Self.ntpEpochOffset
        let eraSeconds = ntpTime.truncatingRemainder(dividingBy: Self.ntpEraDuration)
        let seconds = UInt32(eraSeconds)
        let fraction = UInt32(
            floor((ntpTime - floor(ntpTime)) * Self.ntpEraDuration)
        )
        Self.write(seconds, to: &bytes, at: offset)
        Self.write(fraction, to: &bytes, at: offset + 4)
    }

    private static func write(_ value: UInt32, to bytes: inout [UInt8], at offset: Int) {
        let bigEndian = value.bigEndian
        withUnsafeBytes(of: bigEndian) { rawBytes in
            bytes.replaceSubrange(offset..<(offset + 4), with: rawBytes)
        }
    }

    private static func readTimestamp(
        from bytes: [UInt8],
        at offset: Int,
        relativeTo referenceTime: TimeInterval
    ) throws -> TimeInterval {
        guard bytes.count >= offset + 8 else {
            throw SNTPError.invalidPacket
        }

        let seconds = TimeInterval(Self.readUInt32(from: bytes, at: offset))
        let fraction = Self.readUInt32(from: bytes, at: offset + 4)
        let referenceNTPTime = referenceTime + Self.ntpEpochOffset
        let era = round((referenceNTPTime - seconds) / Self.ntpEraDuration)
        return seconds
            + era * Self.ntpEraDuration
            - Self.ntpEpochOffset
            + TimeInterval(fraction) / Self.ntpEraDuration
    }

    private static func readUInt32(from bytes: [UInt8], at offset: Int) -> UInt32 {
        (UInt32(bytes[offset]) << 24)
            | (UInt32(bytes[offset + 1]) << 16)
            | (UInt32(bytes[offset + 2]) << 8)
            | UInt32(bytes[offset + 3])
    }
}

private extension TimeSynchronizationSnapshot {
    var hasUsableOffset: Bool {
        guard self.lastSynchronizedTime != nil else {
            return false
        }

        if case .failed = self.status {
            return false
        }
        return true
    }
}

private extension SNTPService {
    struct Measurement {
        let server: String
        let synchronizedAt: Date
        let clockOffset: TimeInterval
        let roundTripDelay: TimeInterval
    }

    final class RequestContext {
        let server: String
        let connection: NWConnection
        let completion: (Result<Measurement, Error>) -> Void

        var transmitTime: TimeInterval = 0
        var transmitTimestamp: [UInt8] = []
        var timeout: DispatchWorkItem?
        var isComplete = false
        var hasSentRequest = false

        init(
            server: String,
            connection: NWConnection,
            completion: @escaping (Result<Measurement, Error>) -> Void
        ) {
            self.server = server
            self.connection = connection
            self.completion = completion
        }
    }

    enum SNTPError: LocalizedError {
        case invalidPacket
        case invalidPort
        case timedOut

        var errorDescription: String? {
            switch self {
            case .invalidPacket:
                return "The server returned an invalid SNTP packet."
            case .invalidPort:
                return "The NTP service port is unavailable."
            case .timedOut:
                return "The SNTP request timed out."
            }
        }
    }
}
