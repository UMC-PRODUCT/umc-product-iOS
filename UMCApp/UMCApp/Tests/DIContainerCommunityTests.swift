//
//  DIContainerCommunityTests.swift
//  UMCAppTests
//
//  Created by euijjang97 on 8/12/26.
//

import CommunityData
import CommunityDomain
import CoreDI
import CoreNetwork
import Foundation
import Testing
import UMCFoundation

@testable import UMCApp

// MARK: - Helpers

/// Community 의존성이 등록된 컨테이너를 만든다.
///
/// `DIContainer.configured(modelContext:)` 는 SwiftData 컨테이너를 요구하므로, Community 조립이
/// 실제로 소비하는 공유 인프라(`TokenStore`·`MoyaNetworkAdapter`)만 운영과 같은 방식으로 먼저
/// 등록한다. 등록·해석 시점에는 네트워크 왕복도 소켓 연결도 없어 실제 구현을 그대로 쓴다.
private func makeContainer(
    baseURL: URL? = nil,
    tokenStore: (any TokenStore)? = nil,
    onTokenStoreFactoryCall: @escaping () -> Void = {}
) throws -> DIContainer {
    // 요청을 보내지 않는 테스트용 base URL.
    let baseURL = try baseURL ?? #require(URL(string: "https://test.invalid"))
    let container = DIContainer()
    container.register(TokenStore.self) {
        onTokenStoreFactoryCall()
        return tokenStore ?? KeychainTokenStore()
    }
    container.register(MoyaNetworkAdapter.self) {
        MoyaNetworkAdapter(
            networkClient: AuthSystemFactory.makeNetworkClient(baseURL: baseURL),
            baseURL: baseURL
        )
    }
    // 채팅방 사진 전송이 공지와 같은 스토리지 저장소를 쓴다. 운영에서는 Notice 조립이 먼저 등록한다.
    container.register(StorageRepositoryProtocol.self) {
        StorageRepository(adapter: container.resolve(MoyaNetworkAdapter.self))
    }
    container.registerCommunityDependencies(baseURL: baseURL)
    return container
}

// MARK: - Tests

@Suite("DIContainer+Community — Community 의존성 조립")
struct DIContainerCommunityTests {

    // MARK: - Resolution

    @Test("스레드 UseCase 가 등록되어 해석된다")
    func resolvesThreadUseCases() throws {
        let container = try makeContainer()

        #expect(container.resolveIfRegistered(CommunityThreadListUseCaseProtocol.self) != nil)
        #expect(container.resolveIfRegistered(CommunityThreadRoomUseCaseProtocol.self) != nil)
    }

    @Test("Repository 가 등록되어 해석된다")
    func resolvesThreadRepository() throws {
        let container = try makeContainer()

        #expect(container.resolveIfRegistered(CommunityThreadRepositoryProtocol.self) != nil)
    }

    /// 온디바이스 유틸은 화면 진입 시점에 해석된다. 등록이 빠지면 채팅방·생성 폼을 여는 순간
    /// 크래시라 조립 단계에서 잠근다.
    @Test("대화 요약기가 등록되어 해석된다")
    func resolvesThreadSummarizer() throws {
        let container = try makeContainer()

        #expect(container.resolveIfRegistered(ThreadSummarizing.self) != nil)
    }

    @Test("스레드 분류기가 등록되어 해석된다")
    func resolvesThreadClassifier() throws {
        let container = try makeContainer()

        #expect(container.resolveIfRegistered(ThreadClassifying.self) != nil)
    }

    @Test("스레드 특징 다듬기가 등록되어 해석된다")
    func resolvesThreadDescriptionRefiner() throws {
        let container = try makeContainer()

        #expect(container.resolveIfRegistered(ThreadDescriptionRefining.self) != nil)
    }

    // MARK: - 프로세스 단일 인스턴스

    /// 구독 destination 이 유저별이라 실시간 클라이언트는 프로세스에 하나여야 한다.
    ///
    /// 팩토리가 매번 새 인스턴스를 만들면 두 번째 클라이언트의 `StompConnection.events()` 가
    /// 단일 소비자용인 앞 스트림을 조용히 `finish()` 해, 에러도 로그도 없이 이벤트만 끊긴다.
    /// 실패 증상이 보이지 않는 종류라 등록 단계에서 잠근다.
    @Test("실시간 클라이언트는 매번 같은 인스턴스로 해석된다")
    func realtimeClientResolvesToSameInstance() throws {
        let container = try makeContainer()

        let first = try #require(
            container.resolve(CommunityThreadRealtimeProtocol.self)
                as? CommunityThreadRealtimeClient
        )
        let second = try #require(
            container.resolve(CommunityThreadRealtimeProtocol.self)
                as? CommunityThreadRealtimeClient
        )

        #expect(first === second)
    }

    /// 실시간 클라이언트가 하나여도 그 아래 연결이 두 벌이면 같은 단일 소비자 계약이 깨진다.
    @Test("STOMP 연결은 매번 같은 인스턴스로 해석된다")
    func stompConnectionResolvesToSameInstance() throws {
        let container = try makeContainer()

        let first = try container.resolve(Result<StompConnection, any Error>.self).get()
        let second = try container.resolve(Result<StompConnection, any Error>.self).get()

        #expect(first === second)
    }

    // MARK: - 공유 인프라 재사용

    /// Community 등록이 `TokenStore` 를 자체 등록하면 미리 등록된 팩토리가 밀려나 호출 횟수가
    /// 0 이 된다. 1 이어야 운영 부트스트랩이 등록한 canonical 을 그대로 재사용했다는 뜻이다.
    @Test("STOMP 연결은 이미 등록된 TokenStore 를 재사용한다")
    func reusesRegisteredTokenStore() throws {
        var tokenStoreFactoryCallCount = 0
        let container = try makeContainer { tokenStoreFactoryCallCount += 1 }

        _ = try container.resolve(Result<StompConnection, any Error>.self).get()

        #expect(tokenStoreFactoryCallCount == 1)
    }

    @Test("STOMP CONNECT 토큰이 없으면 앱의 unauthorized 에러를 보고한다",
          .timeLimit(.minutes(1)))
    func reportsMissingConnectTokenAsUnauthorized() async throws {
        let container = try makeContainer(tokenStore: CommunityTokenStore())
        let connection = try container.resolve(Result<StompConnection, any Error>.self).get()
        var events = await connection.events().makeAsyncIterator()

        await connection.connect()

        guard case .disconnected(let error) = await events.next() else {
            Issue.record("인증 실패 이벤트가 오지 않음")
            await connection.disconnect()
            return
        }
        #expect(error as? UMCFoundation.NetworkError == .unauthorized)
        await connection.disconnect()
    }

    @Test("CONNECT 헤더는 토큰이 바뀔 때마다 저장소에서 다시 읽는다")
    func rereadsConnectToken() async throws {
        let tokenStore = CommunityTokenStore(accessToken: "token-before-refresh")
        let first = try await DIContainer.communityConnectHeaders(tokenStore: tokenStore)
        try await tokenStore.save(accessToken: "token-after-refresh", refreshToken: "refresh")
        let second = try await DIContainer.communityConnectHeaders(tokenStore: tokenStore)

        #expect(first == ["Authorization": "Bearer token-before-refresh"])
        #expect(second == ["Authorization": "Bearer token-after-refresh"])
    }

    @Test("빈 토큰으로 CONNECT 하지 않고 unauthorized 를 던진다")
    func rejectsEmptyConnectToken() async throws {
        let tokenStore = CommunityTokenStore(accessToken: "")
        await #expect(throws: UMCFoundation.NetworkError.unauthorized) {
            try await DIContainer.communityConnectHeaders(tokenStore: tokenStore)
        }
    }

    @Test("잘못된 WebSocket 설정은 DI 해석을 중단하지 않고 명령 실패로 전달된다",
          .timeLimit(.minutes(1)))
    func preservesInvalidConfigurationFailure() async throws {
        let baseURL = try #require(URL(string: "https:/missing-host"))
        let container = try makeContainer(baseURL: baseURL, tokenStore: CommunityTokenStore())
        let result = container.resolve(Result<StompConnection, any Error>.self)
        #expect(throws: StompConnectionError.invalidURL) { try result.get() }

        let client = container.resolve(CommunityThreadRealtimeProtocol.self)
        let signals = await client.signals()
        await client.start()
        await #expect(throws: StompConnectionError.invalidURL) {
            try await client.deleteMessage(threadId: "12", messageId: "10")
        }
        await client.stop()
        var received = signals.makeAsyncIterator()
        #expect(await received.next() == nil)
    }
}

#if DEBUG
private actor CommunityTokenStore: TokenStore {
    private var accessToken: String?

    init(accessToken: String? = nil) {
        self.accessToken = accessToken
    }

    func getAccessToken() async -> String? { accessToken }
    func getRefreshToken() async -> String? { nil }

    func save(accessToken: String, refreshToken: String) async throws {
        self.accessToken = accessToken
    }

    func clear() async throws { accessToken = nil }
}
#endif
