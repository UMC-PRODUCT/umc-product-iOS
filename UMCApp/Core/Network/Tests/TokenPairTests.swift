//
//  TokenPairTests.swift
//  CoreNetworkTests
//
//  Created by euijjang97 on 4/25/26.
//

import Foundation
import Testing
@testable import CoreNetwork

@Suite("TokenPair")
struct TokenPairTests {

    @Test("init으로 생성한 토큰의 프로퍼티가 그대로 노출된다")
    func initSetsProperties() {
        let pair = TokenPair(accessToken: "access-1", refreshToken: "refresh-1")

        #expect(pair.accessToken == "access-1")
        #expect(pair.refreshToken == "refresh-1")
    }

    @Test(
        "Equatable 비교가 두 필드를 모두 검사한다",
        arguments: [
            (TokenPair(accessToken: "A", refreshToken: "R"),
             TokenPair(accessToken: "A", refreshToken: "R"), true),
            (TokenPair(accessToken: "A", refreshToken: "R"),
             TokenPair(accessToken: "A2", refreshToken: "R"), false),
            (TokenPair(accessToken: "A", refreshToken: "R"),
             TokenPair(accessToken: "A", refreshToken: "R2"), false),
        ]
    )
    func equatable(lhs: TokenPair, rhs: TokenPair, expected: Bool) {
        #expect((lhs == rhs) == expected)
    }
}
