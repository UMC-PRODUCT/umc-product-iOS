//
//  MemberBlockDecodingTests.swift
//  CoreNetworkTests
//
//  Created by euijjang97 on 10/29/26.
//

import Foundation
import Testing
@testable import CoreNetwork

@Suite("회원 차단 API 응답")
struct MemberBlockDecodingTests {
    @Test("차단 목록은 문자열·숫자 식별자를 모두 읽는다")
    func decodesFlexibleIdentifiers() throws {
        let json = #"{"members":[{"memberId":"21","name":"홍길동"},{"memberId":22}]}"#
        let result = try JSONDecoder().decode(BlockedMemberListDTO.self, from: Data(json.utf8))
        #expect(result.members.map(\.memberId) == ["21", "22"])
    }

    @Test("손상된 차단 목록은 일부 회원을 버리는 대신 전체 실패한다")
    func rejectsMalformedBlockedMember() {
        let json = #"{"members":[{"memberId":"21"},{}]}"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(BlockedMemberListDTO.self, from: Data(json.utf8))
        }
    }

    @Test("차단 결과의 isBlocked 계약을 읽는다")
    func decodesMutationResult() throws {
        let json = #"{"memberId":21,"isBlocked":false}"#
        let result = try JSONDecoder().decode(MemberBlockResultDTO.self, from: Data(json.utf8))
        #expect(result.memberId == "21")
        #expect(!result.isBlocked)
    }
}
