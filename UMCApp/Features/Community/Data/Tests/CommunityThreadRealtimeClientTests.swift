//
//  CommunityThreadRealtimeClientTests.swift
//  CommunityDataTests
//
//  Created by euijjang97 on 8/12/26.
//

import CommunityDomain
import CoreNetwork
import Foundation
import Synchronization
import Testing
@testable import CommunityData

#if DEBUG
@Suite("CommunityThreadRealtimeClient — 연결 수명주기와 앱 이벤트 처리")
struct CommunityThreadRealtimeClientTests {

    // MARK: - Property

    private static let acknowledgedEvent = """
        {"eventId":"e-1","type":"command.acknowledged","threadId":"12",\
        "payload":{"commandId":"c-1"}}
        """

    private static let rateLimitError = """
        {"status":"429","code":"RATE_LIMITED","message":"too many","retryable":true}
        """

    // MARK: - Test

    @Test("동시 start 는 이벤트 펌프와 구독을 한 벌만 만든다", .timeLimit(.minutes(1)))
    func concurrentStartKeepsSingleConsumer() async throws {
        let connection = StubStompConnection()
        let client = CommunityThreadRealtimeClient(connection: connection)
        let signals = await client.signals()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<8 { group.addTask { await client.start() } }
        }
        await waitUntil { connection.connectCallCount == 1 }
        connection.deliver(.connected)
        await waitUntil { connection.subscriptions.count == 2 }

        #expect(connection.eventStreamCount == 1)
        #expect(connection.subscriptions == [
            "/user/queue/community/threads/events", "/user/queue/errors"
        ])

        var received = signals.makeAsyncIterator()
        connection.deliver(message(body: Self.acknowledgedEvent))
        guard case .event(let event) = await received.next() else {
            Issue.record("이벤트 신호가 오지 않음")
            await client.stop()
            return
        }
        #expect(event.threadId == "12")
        await client.stop()
        #expect(await received.next() == nil)
    }

    @Test("stop 은 독립 연결 Task 를 취소해 연결 완료를 기다리지 않는다",
          .timeLimit(.minutes(1)))
    func stopDrainsPendingConnection() async throws {
        let opening = PendingOpening()
        let connection = StubStompConnection(
            disconnectOperation: { await opening.disconnect() },
            connectOperation: { await opening.connect() }
        )
        let client = CommunityThreadRealtimeClient(connection: connection)
        await client.start()
        await opening.waitUntilSuspended()

        let didStop = Mutex(false)
        let stopping = Task {
            await client.stop()
            didStop.withLock { $0 = true }
        }
        let completed = await waitUntil({ didStop.withLock { $0 } }, timeout: .seconds(1))
        #expect(completed)
        if !completed { await connection.disconnect() }
        await stopping.value
        #expect(connection.disconnectCallCount == 2)
    }

    @Test("stop 대기 중 재시작한 연결과 신호 스트림은 유지된다", .timeLimit(.minutes(1)))
    func stopKeepsConnectionOpenedWhileWaiting() async throws {
        let gate = ConnectGate()
        let connection = StubStompConnection(disconnectOperation: { await gate.wait() })
        let client = CommunityThreadRealtimeClient(connection: connection)
        let signals = await client.signals()
        await client.start()
        await waitUntil { connection.connectCallCount == 1 }

        let stopping = Task { await client.stop() }
        await gate.waitUntilSuspended()
        await client.start()
        let openedBeforeShutdown = await waitUntil(
            { connection.eventStreamCount == 2 }, timeout: .milliseconds(250)
        )
        #expect(!openedBeforeShutdown)
        #expect(connection.connectCallCount == 1)
        await gate.release()
        await stopping.value
        await waitUntil { connection.connectCallCount == 2 }
        #expect(connection.disconnectCallCount == 2)

        connection.deliver(.connected)
        await waitUntil { connection.subscriptions.count == 2 }
        var received = signals.makeAsyncIterator()
        connection.deliver(message(body: Self.acknowledgedEvent))
        guard case .event = await received.next() else {
            Issue.record("재시작한 연결에서 이벤트가 오지 않음")
            await client.stop()
            return
        }
        await client.stop()
    }

    @Test("stop 이후 다시 start 하면 새 이벤트 스트림으로 재개된다",
          .timeLimit(.minutes(1)))
    func restartsAfterStop() async throws {
        let connection = StubStompConnection()
        let client = CommunityThreadRealtimeClient(connection: connection)
        await client.start()
        await waitUntil { connection.connectCallCount == 1 }
        await client.stop()

        let signals = await client.signals()
        await client.start()
        await waitUntil { connection.connectCallCount == 2 }
        #expect(connection.eventStreamCount == 2)
        var received = signals.makeAsyncIterator()
        connection.deliver(.reconnected)
        guard case .reconnected = await received.next() else {
            Issue.record("REST 백필을 위한 재연결 신호가 오지 않음")
            await client.stop()
            return
        }
        #expect(connection.subscriptions.isEmpty)
        connection.deliver(message(body: Self.acknowledgedEvent))
        guard case .event = await received.next() else {
            Issue.record("재개 후 이벤트가 오지 않음")
            await client.stop()
            return
        }
        await client.stop()
    }

    @Test("모든 커뮤니티 명령은 JSON 헤더와 앱 destination 을 명시한다")
    func sendsJSONCommands() async throws {
        let connection = StubStompConnection()
        let client = CommunityThreadRealtimeClient(connection: connection)
        let editCommandID = "5f26d7c4-4967-4b76-8381-26926d4a2f31"

        try await client.sendMessage(
            threadId: "12", clientMessageId: "client-1", content: "hello",
            fileMetadataIds: ["file-1"], replyToId: "9", mentionedMemberIds: ["3"]
        )
        try await client.updateReadWatermark(threadId: "12", lastReadMessageId: "10")
        try await client.addReaction(threadId: "12", messageId: "10", emoji: "👍")
        try await client.removeReaction(threadId: "12", messageId: "10", emoji: "👍")
        try await client.deleteMessage(threadId: "12", messageId: "10")
        try await client.editMessage(
            threadId: "12", messageId: "10", commandId: editCommandID, content: "updated"
        )

        let sent = connection.sent
        #expect(sent.map { $0.headers["destination"] } == [
            "/app/community/threads/12/messages",
            "/app/community/threads/12/read",
            "/app/community/threads/12/messages/10/reactions/add",
            "/app/community/threads/12/messages/10/reactions/remove",
            "/app/community/threads/12/messages/10/delete",
            "/app/community/threads/12/messages/10/edit"
        ])
        #expect(sent.allSatisfy { $0.headers["content-type"] == "application/json" })
        let commandIDs = sent.compactMap { $0.headers["x-command-id"] }
        #expect(Set(commandIDs).count == 6)
        #expect(commandIDs.allSatisfy {
            UUID(uuidString: $0) != nil && $0 == $0.lowercased()
        })
        #expect(commandIDs.last == editCommandID)

        let bodies = try sent.map {
            try #require(JSONSerialization.jsonObject(with: $0.body) as? [String: Any])
        }
        #expect(bodies[0]["clientMessageId"] as? String == "client-1")
        #expect(bodies[0]["content"] as? String == "hello")
        #expect(bodies[0]["type"] as? String == "IMAGE")
        #expect(bodies[0]["fileMetadataIds"] as? [String] == ["file-1"])
        #expect(bodies[0]["replyToId"] as? Int == 9)
        #expect(bodies[0]["mentionedMemberIds"] as? [Int] == [3])
        #expect(bodies[1]["lastReadMessageId"] as? String == "10")
        #expect(bodies[2]["emoji"] as? String == "👍")
        #expect(bodies[3]["emoji"] as? String == "👍")
        #expect(bodies[4].isEmpty)
        #expect(bodies[5]["content"] as? String == "updated")
    }

    @Test("연결 전 명령 전송 실패는 호출자에게 그대로 전달된다")
    func propagatesSendFailure() async throws {
        let connection = StubStompConnection(sendError: StompConnectionError.notConnected)
        let client = CommunityThreadRealtimeClient(connection: connection)
        await #expect(throws: StompConnectionError.notConnected) {
            try await client.deleteMessage(threadId: "12", messageId: "10")
        }
    }

    @Test("구독 실패가 이벤트 펌프와 다른 구독을 끝내지 않는다", .timeLimit(.minutes(1)))
    func keepsPumpAfterSubscriptionFailure() async throws {
        let connection = StubStompConnection(subscriptionError: StompConnectionError.notConnected)
        let client = CommunityThreadRealtimeClient(connection: connection)
        let signals = await client.signals()
        await client.start()
        await waitUntil { connection.connectCallCount == 1 }
        connection.deliver(.connected)
        await waitUntil { connection.subscriptions.count == 2 }
        var received = signals.makeAsyncIterator()
        connection.deliver(message(body: Self.acknowledgedEvent))
        guard case .event = await received.next() else {
            Issue.record("구독 실패 후 이벤트 펌프가 끝남")
            await client.stop()
            return
        }
        await client.stop()
    }

    @Test("릴레이 errors destination 과 STOMP ERROR 모두 commandFailed 로 해석한다",
          .timeLimit(.minutes(1)), arguments: [false, true])
    func routesServerErrors(isStompError: Bool) async throws {
        let connection = StubStompConnection()
        let client = CommunityThreadRealtimeClient(connection: connection)
        let signals = await client.signals()
        await client.start()
        await waitUntil { connection.connectCallCount == 1 }
        let frame = StompFrame(
            command: isStompError ? .error : .message,
            headers: ["destination": "/queue/errors-userabc123"],
            body: Data(Self.rateLimitError.utf8)
        )
        connection.deliver(isStompError ? .error(frame) : .message(frame))
        var received = signals.makeAsyncIterator()
        guard case .commandFailed(let failure) = await received.next() else {
            Issue.record("commandFailed 신호가 오지 않음")
            await client.stop()
            return
        }
        #expect(failure.isRateLimited)
        #expect(failure.code == "RATE_LIMITED")
        #expect(failure.retryable)
        await client.stop()
    }

    @Test("중복 이벤트와 잘못된 JSON 은 버리고 다음 이벤트를 처리한다",
          .timeLimit(.minutes(1)))
    func dropsDuplicateAndMalformedEvents() async throws {
        let connection = StubStompConnection()
        let client = CommunityThreadRealtimeClient(connection: connection)
        let signals = await client.signals()
        await client.start()
        await waitUntil { connection.connectCallCount == 1 }
        connection.deliver(message(body: Self.acknowledgedEvent))
        connection.deliver(message(body: Self.acknowledgedEvent))
        connection.deliver(message(body: "invalid-json"))
        connection.deliver(.error(StompFrame(command: .error, body: Data("plain error".utf8))))
        connection.deliver(.reconnected)

        var received = signals.makeAsyncIterator()
        guard case .event = await received.next() else {
            Issue.record("정상 이벤트가 오지 않음")
            await client.stop()
            return
        }
        guard case .reconnected = await received.next() else {
            Issue.record("중복 또는 잘못된 프레임이 신호로 흘러옴")
            await client.stop()
            return
        }
        await client.stop()
    }

    // MARK: - Function

    private func message(body: String) -> StompEvent {
        .message(StompFrame(
            command: .message,
            headers: ["destination": "/user/queue/community/threads/events"],
            body: Data(body.utf8)
        ))
    }

    private func waitUntil(_ condition: @Sendable () -> Bool) async {
        while !condition(), !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(2))
        }
    }

    private func waitUntil(
        _ condition: @Sendable () -> Bool,
        timeout: Duration
    ) async -> Bool {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while !condition(), ContinuousClock.now < deadline, !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(2))
        }
        return condition()
    }
}

// MARK: - Test Double

private final class StubStompConnection: CommunityStompConnecting {
    private struct State {
        var continuation: AsyncStream<StompEvent>.Continuation?
        var eventStreamCount = 0
        var connectCallCount = 0
        var disconnectCallCount = 0
        var subscriptions: [String] = []
        var sent: [StompFrame] = []
    }

    private let state = Mutex(State())
    private let connectOperation: @Sendable () async -> Void
    private let disconnectOperation: @Sendable () async -> Void
    private let subscriptionError: (any Error)?
    private let sendError: (any Error)?

    init(
        subscriptionError: (any Error)? = nil,
        sendError: (any Error)? = nil,
        disconnectOperation: @escaping @Sendable () async -> Void = {},
        connectOperation: @escaping @Sendable () async -> Void = {}
    ) {
        self.subscriptionError = subscriptionError
        self.sendError = sendError
        self.connectOperation = connectOperation
        self.disconnectOperation = disconnectOperation
    }

    var eventStreamCount: Int { state.withLock { $0.eventStreamCount } }
    var connectCallCount: Int { state.withLock { $0.connectCallCount } }
    var disconnectCallCount: Int { state.withLock { $0.disconnectCallCount } }
    var subscriptions: [String] { state.withLock { $0.subscriptions } }
    var sent: [StompFrame] { state.withLock { $0.sent } }

    func events() async -> AsyncStream<StompEvent> {
        AsyncStream { continuation in
            state.withLock {
                $0.continuation?.finish()
                $0.continuation = continuation
                $0.eventStreamCount += 1
            }
        }
    }

    func connect() async {
        state.withLock { $0.connectCallCount += 1 }
        await connectOperation()
    }

    func disconnect() async {
        state.withLock { $0.disconnectCallCount += 1 }
        await disconnectOperation()
    }

    func subscribe(destination: String, headers: [String: String]) async throws {
        state.withLock { $0.subscriptions.append(destination) }
        if let subscriptionError { throw subscriptionError }
    }

    func send(destination: String, headers: [String: String], body: Data) async throws {
        if let sendError { throw sendError }
        var headers = headers
        headers["destination"] = destination
        state.withLock { $0.sent.append(StompFrame(command: .send, headers: headers, body: body)) }
    }

    func deliver(_ event: StompEvent) {
        state.withLock { $0.continuation }?.yield(event)
    }
}

private actor PendingOpening {
    private let gate = ConnectGate()
    private var openingTask: Task<Void, Never>?

    func connect() async {
        let opening = Task { await gate.wait() }
        openingTask = opening
        await opening.value
    }

    func disconnect() async {
        openingTask?.cancel()
        await gate.release()
    }

    func waitUntilSuspended() async {
        await gate.waitUntilSuspended()
    }
}

private actor ConnectGate {
    private var gate: CheckedContinuation<Void, Never>?
    private var suspensionWaiter: CheckedContinuation<Void, Never>?
    private var isSuspended = false
    func wait() async {
        guard !isSuspended else { return }
        await withCheckedContinuation { continuation in
            gate = continuation
            isSuspended = true
            suspensionWaiter?.resume()
            suspensionWaiter = nil
        }
    }

    func waitUntilSuspended() async {
        guard !isSuspended else { return }
        await withCheckedContinuation { suspensionWaiter = $0 }
    }

    func release() {
        gate?.resume()
        gate = nil
    }
}
#endif
