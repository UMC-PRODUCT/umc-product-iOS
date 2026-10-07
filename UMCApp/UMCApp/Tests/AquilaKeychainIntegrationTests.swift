//
//  AquilaKeychainIntegrationTests.swift
//  UMCAppTests
//
//  Created by euijjang97 on 10/7/26.
//

import CoreNetwork
import Foundation
import Testing

@Suite("Aquila Keychain 앱 호스트 통합")
struct AquilaKeychainIntegrationTests {
    @Test("저장한 토큰 쌍은 새 인스턴스에서 읽히고 삭제 후 기존 인스턴스에도 남지 않는다")
    func persistsAndClearsAcrossInstances() async throws {
        let service = "com.umc.product.tests.aquila.\(UUID().uuidString)"
        let writer = CoreNetwork.KeychainTokenStore(service: service)
        let expected = TokenPair(accessToken: "test-access", refreshToken: "test-refresh")

        try await writer.save(
            accessToken: expected.accessToken, refreshToken: expected.refreshToken
        )
        let reader = CoreNetwork.KeychainTokenStore(service: service)
        let stored = try await reader.readTokens()
        try await reader.clear()

        #expect(stored == expected)
        #expect(try await writer.readTokens() == nil)
    }
}
