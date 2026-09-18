//
//  CommunityThreadRepositoryTests.swift
//  CommunityDataTests
//
//  Created by euijjang97 on 8/12/26.
//
//  진짜 `CommunityThreadRepository` 를 대상으로, 네트워크 계층만 가짜(`StubCommunityThreadNetwork`)로
//  주입해 6개 엔드포인트의 라우터 호출 계약 · page size 클램프 · 에러 변환 분기를 검증한다.
//

import Foundation
import Testing
import Moya
import CoreNetwork
import UMCFoundation
import CommunityDomain
@testable import CommunityData

// MARK: - Test Doubles

/// ``CommunityThreadNetworkRequesting`` 가짜 구현.
///
/// 미리 설정한 결과(성공 본문 / 던질 에러)를 반환하고, 호출된 라우터의 경로·메서드·타깃을
/// 기록해 엔드포인트 계약을 검증할 수 있게 합니다. `target.path`/`target.method`만 읽어
/// `NetworkConfig.baseURL`(테스트 번들 `fatalError`)을 건드리지 않습니다.
private final class StubCommunityThreadNetwork:
    CommunityThreadNetworkRequesting, @unchecked Sendable {

    enum Outcome {
        case success(Data)
        case failure(Error)
    }

    enum StubError: Error, Equatable {
        case offline
    }

    /// 호출 순서대로 하나씩 꺼내 쓰고, 마지막 하나는 이후 호출에도 계속 돌려준다.
    private var outcomes: [Outcome]
    private(set) var requestCount = 0
    private(set) var lastPath: String?
    private(set) var lastMethod: Moya.Method?
    private(set) var targets: [CommunityThreadRouter] = []

    var lastTarget: CommunityThreadRouter? { targets.last }

    init(_ outcome: Outcome) {
        self.outcomes = [outcome]
    }

    /// 페이지를 이어 받는 요청용 — `pages` 를 순서대로 응답한다.
    init(pages: [Data]) {
        self.outcomes = pages.map(Outcome.success)
    }

    func request<T: TargetType>(_ target: T) async throws -> Response {
        requestCount += 1
        lastPath = target.path
        lastMethod = target.method
        if let target = target as? CommunityThreadRouter {
            targets.append(target)
        }
        let outcome = outcomes.count > 1 ? outcomes.removeFirst() : outcomes[0]
        switch outcome {
        case .success(let data):
            return Response(statusCode: 200, data: data)
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Fixtures

private enum Fixture {
    static let threadList = Data("""
    {
      "success": true, "code": "200", "message": "성공",
      "result": {
        "pinned": [], "threads": [{"threadId": "12", "title": "iOS 스터디",
        "category": "STUDY", "createdBy": "5", "createdAt": "2026-08-01T00:00:00Z",
        "updatedAt": "2026-08-01T00:00:00Z"}],
        "nextOffset": null, "total": "1"
      }
    }
    """.utf8)

    static let thread = Data("""
    {
      "success": true, "code": "200", "message": "성공",
      "result": {"threadId": "12", "title": "iOS 스터디", "category": "STUDY",
      "createdBy": "5", "createdAt": "2026-08-01T00:00:00Z",
      "updatedAt": "2026-08-01T00:00:00Z"}
    }
    """.utf8)

    static let messagePage = Data("""
    {
      "success": true, "code": "200", "message": "성공",
      "result": {"messages": [], "hasMore": false, "nextBefore": null}
    }
    """.utf8)

    /// 참여자 첫 페이지 — `nextOffset` 이 다음 요청 오프셋이다.
    static let memberFirstPage = Data("""
    {
      "success": true, "code": "200", "message": "성공",
      "result": {
        "items": [
          {"memberId": "5", "name": "정의진", "part": "IOS", "generation": "9",
           "role": "OWNER", "joinedAt": "2026-08-01T00:00:00Z", "state": "ACTIVE"},
          {"memberId": "9", "name": "김하늘", "part": "WEB", "generation": "9",
           "role": "MEMBER", "joinedAt": "2026-08-02T00:00:00Z", "state": "ACTIVE"}
        ],
        "nextOffset": "100", "total": "101"
      }
    }
    """.utf8)

    /// 참여자 마지막 페이지 — `nextOffset` 이 null 이다.
    static let memberLastPage = Data("""
    {
      "success": true, "code": "200", "message": "성공",
      "result": {
        "items": [
          {"memberId": "11", "name": "이바다", "part": "ANDROID", "generation": "9",
           "role": "MEMBER", "joinedAt": "2026-08-03T00:00:00Z", "state": "ACTIVE"}
        ],
        "nextOffset": null, "total": "101"
      }
    }
    """.utf8)

    /// 초대 후보 한 페이지 — 원소에 `role` 이 없다.
    static let invitablePage = Data("""
    {
      "success": true, "code": "200", "message": "성공",
      "result": {
        "items": [
          {"memberId": "12", "challengerId": "340", "name": "박솔", "part": "WEB",
           "generation": "9"}
        ],
        "nextOffset": null, "total": "1"
      }
    }
    """.utf8)

    /// 토글·나가기 성공 응답 — `result` 자체가 없다.
    static let empty = Data("""
    {"success": true, "code": "200", "message": "성공"}
    """.utf8)

    static let failure = Data("""
    {"success": false, "code": "THREAD403", "message": "권한이 없습니다"}
    """.utf8)

    /// JSON 조차 아닌 본문 — 디코딩 분기를 강제한다.
    static let malformed = Data("<html>gateway timeout</html>".utf8)
}

// MARK: - Tests

@Suite("CommunityThreadRepository — 라우터 결선·클램프·에러 변환")
struct CommunityThreadRepositoryTests {

    private func makeRepository(
        _ outcome: StubCommunityThreadNetwork.Outcome
    ) -> (CommunityThreadRepository, StubCommunityThreadNetwork) {
        let network = StubCommunityThreadNetwork(outcome)
        return (CommunityThreadRepository(networkRequesting: network), network)
    }

    // MARK: - 라우터 결선

    @Test("fetchThreads 가 getThreads 로 가고 filter·검색어·오프셋을 변형 없이 싣는다")
    func fetchThreadsCallsGetThreads() async throws {
        let (repository, network) = makeRepository(.success(Fixture.threadList))

        let page = try await repository.fetchThreads(
            filter: "STUDY",
            query: "스터디",
            offset: 20,
            limit: 20
        )

        #expect(page.threads.map(\.id) == ["12"])
        #expect(network.requestCount == 1)
        #expect(network.lastPath == "/api/v1/community/threads")
        #expect(network.lastMethod == .get)
        guard case .getThreads(let query) = network.lastTarget else {
            Issue.record(
                "lastTarget 이 getThreads 가 아닙니다: \(String(describing: network.lastTarget))"
            )
            return
        }
        #expect(query.filter == "STUDY")
        #expect(query.query == "스터디")
        #expect(query.offset == 20)
    }

    @Test("fetchThread 가 getThread 로 간다")
    func fetchThreadCallsGetThread() async throws {
        let (repository, network) = makeRepository(.success(Fixture.thread))

        let thread = try await repository.fetchThread(threadId: "12")

        #expect(thread.id == "12")
        #expect(network.lastPath == "/api/v1/community/threads/12")
        #expect(network.lastMethod == .get)
        guard case .getThread(let threadId) = network.lastTarget else {
            Issue.record(
                "lastTarget 이 getThread 가 아닙니다: \(String(describing: network.lastTarget))"
            )
            return
        }
        #expect(threadId == "12")
    }

    @Test("fetchMembers 는 nextOffset 이 null 이 될 때까지 최대 page size 로 이어 받아 합친다")
    func fetchMembersFollowsNextOffset() async throws {
        let network = StubCommunityThreadNetwork(
            pages: [Fixture.memberFirstPage, Fixture.memberLastPage]
        )
        let repository = CommunityThreadRepository(networkRequesting: network)

        let members = try await repository.fetchMembers(threadId: "1")

        #expect(members.map(\.id) == ["5", "9", "11"])
        #expect(network.requestCount == 2)
        #expect(network.lastPath == "/api/v1/community/threads/1/members")
        let queries = network.targets.compactMap { target -> ThreadMemberPageQuery? in
            guard case .getMembers("1", let query) = target else { return nil }
            return query
        }
        #expect(queries.map(\.offset) == [0, 100])
        #expect(queries.map(\.limit) == [100, 100])
    }

    @Test("fetchInvitableMembers 는 getInvitableMembers 로 가고 role 없는 후보를 일반 참여자로 받는다")
    func fetchInvitableMembersCallsGetInvitable() async throws {
        let (repository, network) = makeRepository(.success(Fixture.invitablePage))

        let members = try await repository.fetchInvitableMembers(threadId: "1")

        #expect(members.map(\.id) == ["12"])
        #expect(members.first?.role == .member)
        #expect(network.requestCount == 1)
        #expect(network.lastPath == "/api/v1/community/threads/1/invitable")
        #expect(network.lastMethod == .get)
        guard case .getInvitableMembers("1", let query) = network.lastTarget else {
            Issue.record(
                "lastTarget 이 getInvitableMembers 가 아닙니다: "
                    + String(describing: network.lastTarget)
            )
            return
        }
        #expect(query.offset == 0)
        #expect(query.limit == 100)
    }

    @Test("createThread 가 POST /threads 로 가고 본문을 변형 없이 싣는다")
    func createThreadCallsPostThreads() async throws {
        let (repository, network) = makeRepository(.success(Fixture.thread))

        let thread = try await repository.createThread(
            title: "iOS 스터디",
            description: "매주 화요일 8시",
            category: "STUDY",
            icon: "📚",
            memberIds: ["7", "11", "숫자아님"]
        )

        #expect(thread.id == "12")
        #expect(network.lastPath == "/api/v1/community/threads")
        #expect(network.lastMethod == .post)
        guard case .createThread(let body) = network.lastTarget else {
            Issue.record(
                "lastTarget 이 createThread 가 아닙니다: \(String(describing: network.lastTarget))"
            )
            return
        }
        #expect(body.title == "iOS 스터디")
        #expect(body.description == "매주 화요일 8시")
        #expect(body.category == "STUDY")
        #expect(body.icon == "📚")
        // Domain 의 String 식별자를 여기서만 Int 로 바꾼다. 숫자가 아닌 값은 서버가 모르는
        // 식별자라 보내 봐야 400 이므로 버린다(`InviteMembersBody` 와 같은 판단).
        #expect(body.memberIds == [7, 11])
    }

    @Test("fetchMessages 가 getMessages 로 가고 배타적 커서를 그대로 싣는다")
    func fetchMessagesCallsGetMessages() async throws {
        let (repository, network) = makeRepository(.success(Fixture.messagePage))

        _ = try await repository.fetchMessages(threadId: "12", before: "99", limit: 30)

        #expect(network.lastPath == "/api/v1/community/threads/12/messages")
        #expect(network.lastMethod == .get)
        guard case .getMessages(let threadId, let query) = network.lastTarget else {
            Issue.record(
                "lastTarget 이 getMessages 가 아닙니다: \(String(describing: network.lastTarget))"
            )
            return
        }
        #expect(threadId == "12")
        #expect(query.before == "99")
    }

    /// `pin` 과 `mute` 는 경로만 다르고 POST/DELETE 구조가 같아 오배선이 눈에 띄지 않는다.
    @Test(
        "setPinned 는 setPin 라우터로만 가고 on/off 가 POST/DELETE 로 갈린다",
        arguments: [true, false]
    )
    func setPinnedCallsSetPin(isPinned: Bool) async throws {
        let (repository, network) = makeRepository(.success(Fixture.empty))

        try await repository.setPinned(threadId: "12", isPinned: isPinned)

        #expect(network.lastPath == "/api/v1/community/threads/12/pin")
        #expect(network.lastMethod == (isPinned ? .post : .delete))
        guard case .setPin(let threadId, let sentFlag) = network.lastTarget else {
            Issue.record("lastTarget 이 setPin 이 아닙니다: \(String(describing: network.lastTarget))")
            return
        }
        #expect(threadId == "12")
        #expect(sentFlag == isPinned)
    }

    @Test(
        "setMuted 는 setMute 라우터로만 가고 on/off 가 POST/DELETE 로 갈린다",
        arguments: [true, false]
    )
    func setMutedCallsSetMute(isMuted: Bool) async throws {
        let (repository, network) = makeRepository(.success(Fixture.empty))

        try await repository.setMuted(threadId: "12", isMuted: isMuted)

        #expect(network.lastPath == "/api/v1/community/threads/12/mute")
        #expect(network.lastMethod == (isMuted ? .post : .delete))
        guard case .setMute(let threadId, let sentFlag) = network.lastTarget else {
            Issue.record("lastTarget 이 setMute 가 아닙니다: \(String(describing: network.lastTarget))")
            return
        }
        #expect(threadId == "12")
        #expect(sentFlag == isMuted)
    }

    @Test("leaveThread 가 leave 로 간다")
    func leaveThreadCallsLeave() async throws {
        let (repository, network) = makeRepository(.success(Fixture.empty))

        try await repository.leaveThread(threadId: "12")

        #expect(network.lastPath == "/api/v1/community/threads/12/leave")
        #expect(network.lastMethod == .post)
        guard case .leave(let threadId) = network.lastTarget else {
            Issue.record("lastTarget 이 leave 가 아닙니다: \(String(describing: network.lastTarget))")
            return
        }
        #expect(threadId == "12")
    }

    /// 신고만 `/threads` 하위가 아니다. 다른 엔드포인트를 따라 스레드 밑으로 붙이면 서버는
    /// 그런 경로를 모른다 — 경로를 여기서 못 박아 둔다.
    @Test("reportMessage 는 /messages/{id}/report 로 가고 사유 코드를 그대로 싣는다")
    func reportMessageCallsMessagesReport() async throws {
        let (repository, network) = makeRepository(.success(Fixture.empty))

        try await repository.reportMessage(messageId: "77", reason: "SPAM")

        #expect(network.lastPath == "/api/v1/community/messages/77/report")
        #expect(network.lastMethod == .post)
        guard case .reportMessage(let messageId, let body) = network.lastTarget else {
            Issue.record(
                "lastTarget 이 reportMessage 가 아닙니다: \(String(describing: network.lastTarget))"
            )
            return
        }
        #expect(messageId == "77")
        #expect(body.reason == "SPAM")
    }

    // MARK: - page size 클램프

    @Test(
        "page size 는 서버 상한 1...100 에 맞춰 보낸다",
        arguments: [(-5, 1), (0, 1), (1, 1), (20, 20), (100, 100), (101, 100), (1_000, 100)]
    )
    func clampsLimitToServerRange(requested: Int, sent: Int) async throws {
        let (listRepository, listNetwork) = makeRepository(.success(Fixture.threadList))
        _ = try await listRepository.fetchThreads(
            filter: "all",
            query: nil,
            offset: 0,
            limit: requested
        )
        guard case .getThreads(let listQuery) = listNetwork.lastTarget else {
            Issue.record("lastTarget 이 getThreads 가 아닙니다")
            return
        }
        #expect(listQuery.limit == sent)

        let (messageRepository, messageNetwork) = makeRepository(.success(Fixture.messagePage))
        _ = try await messageRepository.fetchMessages(
            threadId: "12",
            before: nil,
            limit: requested
        )
        guard case .getMessages(_, let messageQuery) = messageNetwork.lastTarget else {
            Issue.record("lastTarget 이 getMessages 가 아닙니다")
            return
        }
        #expect(messageQuery.limit == sent)
    }

    // MARK: - 에러 변환

    @Test("본문을 디코딩하지 못하면 decodingError 로 바꾼다")
    func convertsDecodingFailure() async {
        let (repository, _) = makeRepository(.success(Fixture.malformed))

        await #expect(throws: RepositoryError.self) {
            _ = try await repository.fetchThreads(filter: "all", query: nil, offset: 0, limit: 20)
        }

        do {
            _ = try await repository.fetchThread(threadId: "12")
            Issue.record("디코딩 실패가 던져지지 않았습니다")
        } catch let error as RepositoryError {
            guard case .decodingError(let detail) = error else {
                Issue.record("decodingError 가 아닙니다: \(error)")
                return
            }
            #expect(detail?.contains("/api/v1/community/threads/12") == true)
        } catch {
            Issue.record("RepositoryError 가 아닙니다: \(error)")
        }
    }

    @Test("실패 envelope 은 serverError 로 전파한다 — decodingError 로 덮지 않는다")
    func propagatesServerError() async {
        let (repository, _) = makeRepository(.success(Fixture.failure))

        await #expect(
            throws: RepositoryError.serverError(code: "THREAD403", message: "권한이 없습니다")
        ) {
            try await repository.leaveThread(threadId: "12")
        }
    }

    @Test("네트워크 계층 에러는 변환 없이 그대로 올린다")
    func propagatesNetworkError() async {
        let offline = StubCommunityThreadNetwork.StubError.offline
        let (repository, _) = makeRepository(.failure(offline))

        await #expect(throws: StubCommunityThreadNetwork.StubError.offline) {
            _ = try await repository.fetchMessages(threadId: "12", before: nil, limit: 30)
        }
    }

    // MARK: - 초대 거절 사유

    @Test(
        "초대 거절 코드를 ThreadInviteError 로 바꾼다",
        arguments: [
            ("COMMUNITY-0038", ThreadInviteError.alreadyJoined),
            ("COMMUNITY-0039", ThreadInviteError.kicked),
            ("COMMUNITY-0044", ThreadInviteError.notEligible),
            ("COMMUNITY-0036", ThreadInviteError.capacityExceeded)
        ]
    )
    func mapsInviteRejection(code: String, expected: ThreadInviteError) async {
        let body = Data(#"{"success":false,"code":"\#(code)","message":"거절"}"#.utf8)
        let (repository, _) = makeRepository(
            .failure(NetworkError.requestFailed(statusCode: 409, data: body))
        )

        await #expect(throws: expected) {
            try await repository.inviteMembers(threadId: "12", memberIds: ["11"])
        }
    }

    @Test("모르는 초대 거절 코드는 원래 에러를 그대로 올린다")
    func keepsUnknownInviteRejection() async {
        let (repository, _) = makeRepository(.success(Fixture.failure))

        await #expect(
            throws: RepositoryError.serverError(code: "THREAD403", message: "권한이 없습니다")
        ) {
            try await repository.inviteMembers(threadId: "12", memberIds: ["11"])
        }
    }
}
