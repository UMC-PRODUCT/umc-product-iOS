//
//  AuthDTOTests.swift
//  AppProductTests
//
//  Created by jaewon Lee on 2/9/26.
//

import Testing
@testable import AppProduct
import Foundation

// MARK: - OAuthLoginResponseDTO Tests

@Suite("OAuthLoginResponseDTO Tests")
@MainActor
struct OAuthLoginResponseDTOTests {

    @Test("기존회원_응답_toDomain_existingMember_반환")
    func 기존회원_응답_toDomain_existingMember_반환() {
        // Given
        let dto = OAuthLoginResponseDTO(
            accessToken: "test-access-token",
            refreshToken: "test-refresh-token",
            oAuthVerificationToken: nil
        )

        // When
        let result = dto.toDomain()

        // Then
        if case .existingMember(let tokenPair) = result {
            #expect(tokenPair.accessToken == "test-access-token")
            #expect(tokenPair.refreshToken == "test-refresh-token")
        } else {
            Issue.record("Expected existingMember but got \(result)")
        }
    }

    @Test("신규회원_응답_toDomain_newMember_반환")
    func 신규회원_응답_toDomain_newMember_반환() {
        // Given
        let dto = OAuthLoginResponseDTO(
            accessToken: nil,
            refreshToken: nil,
            oAuthVerificationToken: "test-verification-token"
        )

        // When
        let result = dto.toDomain()

        // Then
        if case .newMember(let verificationToken) = result {
            #expect(verificationToken == "test-verification-token")
        } else {
            Issue.record("Expected newMember but got \(result)")
        }
    }

    @Test("빈_응답_toDomain_빈_verificationToken")
    func 빈_응답_toDomain_빈_verificationToken() {
        // Given
        let dto = OAuthLoginResponseDTO(
            accessToken: nil,
            refreshToken: nil,
            oAuthVerificationToken: nil
        )

        // When
        let result = dto.toDomain()

        // Then
        if case .newMember(let verificationToken) = result {
            #expect(verificationToken == "")
        } else {
            Issue.record("Expected newMember with empty token but got \(result)")
        }
    }

    @Test("JSON_디코딩_기존회원")
    func JSON_디코딩_기존회원() throws {
        // Given
        let json = """
        {
            "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
            "refreshToken": "refresh-token-123"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let dto = try JSONDecoder().decode(OAuthLoginResponseDTO.self, from: data)

        // Then
        #expect(dto.accessToken == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
        #expect(dto.refreshToken == "refresh-token-123")
        #expect(dto.oAuthVerificationToken == nil)

        // toDomain 검증
        let result = dto.toDomain()
        if case .existingMember(let tokenPair) = result {
            #expect(tokenPair.accessToken == "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
        } else {
            Issue.record("Expected existingMember")
        }
    }

    @Test("JSON_디코딩_신규회원")
    func JSON_디코딩_신규회원() throws {
        // Given
        let json = """
        {
            "oAuthVerificationToken": "oauth-verify-token-456"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let dto = try JSONDecoder().decode(OAuthLoginResponseDTO.self, from: data)

        // Then
        #expect(dto.accessToken == nil)
        #expect(dto.refreshToken == nil)
        #expect(dto.oAuthVerificationToken == "oauth-verify-token-456")

        // toDomain 검증
        let result = dto.toDomain()
        if case .newMember(let verificationToken) = result {
            #expect(verificationToken == "oauth-verify-token-456")
        } else {
            Issue.record("Expected newMember")
        }
    }
}

// MARK: - TokenRenewResponseDTO Tests

@Suite("TokenRenewResponseDTO Tests")
@MainActor
struct TokenRenewResponseDTOTests {

    @Test("toDomain_TokenPair_변환")
    func toDomain_TokenPair_변환() {
        // Given
        let dto = TokenRenewResponseDTO(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token"
        )

        // When
        let tokenPair = dto.toDomain()

        // Then
        #expect(tokenPair.accessToken == "new-access-token")
        #expect(tokenPair.refreshToken == "new-refresh-token")
    }

    @Test("JSON_디코딩")
    func JSON_디코딩() throws {
        // Given
        let json = """
        {
            "accessToken": "renewed-access-123",
            "refreshToken": "renewed-refresh-456"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let dto = try JSONDecoder().decode(TokenRenewResponseDTO.self, from: data)

        // Then
        #expect(dto.accessToken == "renewed-access-123")
        #expect(dto.refreshToken == "renewed-refresh-456")

        // toDomain 검증
        let tokenPair = dto.toDomain()
        #expect(tokenPair.accessToken == "renewed-access-123")
        #expect(tokenPair.refreshToken == "renewed-refresh-456")
    }
}

// MARK: - MemberOAuthDTO Tests

@Suite("MemberOAuthDTO Tests")
@MainActor
struct MemberOAuthDTOTests {

    @Test("toDomain_MemberOAuth_변환")
    func toDomain_MemberOAuth_변환() {
        // Given
        let dto = MemberOAuthDTO(
            memberOAuthId: 100,
            memberId: 200,
            provider: "KAKAO"
        )

        // When
        let memberOAuth = dto.toDomain()

        // Then
        #expect(memberOAuth.memberOAuthId == 100)
        #expect(memberOAuth.memberId == 200)
        #expect(memberOAuth.provider == "KAKAO")
    }

    @Test("JSON_디코딩")
    func JSON_디코딩() throws {
        // Given
        let json = """
        {
            "memberOAuthId": 42,
            "memberId": 1001,
            "provider": "APPLE"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let dto = try JSONDecoder().decode(MemberOAuthDTO.self, from: data)

        // Then
        #expect(dto.memberOAuthId == 42)
        #expect(dto.memberId == 1001)
        #expect(dto.provider == "APPLE")

        // toDomain 검증
        let memberOAuth = dto.toDomain()
        #expect(memberOAuth.memberOAuthId == 42)
        #expect(memberOAuth.memberId == 1001)
        #expect(memberOAuth.provider == "APPLE")
    }
}

// MARK: - APIResponse 래핑 디코딩 Tests

@Suite("APIResponse 래핑 디코딩 Tests")
@MainActor
struct APIResponseWrapTests {

    @Test("성공_응답_unwrap")
    func 성공_응답_unwrap() throws {
        // Given
        let dto = OAuthLoginResponseDTO(
            accessToken: "access-123",
            refreshToken: "refresh-456",
            oAuthVerificationToken: nil
        )
        let response = APIResponse(
            isSuccess: true,
            code: "200",
            message: "성공",
            result: dto
        )

        // When
        let unwrappedDTO = try response.unwrap()

        // Then
        #expect(unwrappedDTO.accessToken == "access-123")
        #expect(unwrappedDTO.refreshToken == "refresh-456")
    }

    @Test("실패_응답_unwrap_에러")
    func 실패_응답_unwrap_에러() {
        // Given
        let response = APIResponse<OAuthLoginResponseDTO>(
            isSuccess: false,
            code: "AUTH001",
            message: "인증에 실패했습니다",
            result: nil
        )

        // When/Then
        #expect(throws: RepositoryError.self) {
            _ = try response.unwrap()
        }

        // 에러 상세 검증
        do {
            _ = try response.unwrap()
            Issue.record("Expected RepositoryError to be thrown")
        } catch let error as RepositoryError {
            if case .serverError(let code, let message) = error {
                #expect(code == "AUTH001")
                #expect(message == "인증에 실패했습니다")
            } else {
                Issue.record("Expected serverError case")
            }
        } catch {
            Issue.record("Expected RepositoryError but got \(error)")
        }
    }

    @Test("OAuthLogin_응답_전체_디코딩")
    func OAuthLogin_응답_전체_디코딩() throws {
        // Given - 기존 회원 응답
        let existingMemberJSON = """
        {
            "success": true,
            "code": "200",
            "message": "로그인 성공",
            "result": {
                "accessToken": "jwt-access-token",
                "refreshToken": "jwt-refresh-token"
            }
        }
        """

        // When
        let data = existingMemberJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(
            APIResponse<OAuthLoginResponseDTO>.self,
            from: data
        )

        // Then
        #expect(response.isSuccess == true)
        #expect(response.code == "200")
        #expect(response.message == "로그인 성공")

        let dto = try response.unwrap()
        #expect(dto.accessToken == "jwt-access-token")
        #expect(dto.refreshToken == "jwt-refresh-token")

        // toDomain 검증
        let result = dto.toDomain()
        if case .existingMember(let tokenPair) = result {
            #expect(tokenPair.accessToken == "jwt-access-token")
        } else {
            Issue.record("Expected existingMember")
        }
    }

    @Test("OAuthLogin_신규회원_응답_전체_디코딩")
    func OAuthLogin_신규회원_응답_전체_디코딩() throws {
        // Given - 신규 회원 응답
        let newMemberJSON = """
        {
            "success": true,
            "code": "200",
            "message": "신규 회원",
            "result": {
                "oAuthVerificationToken": "verify-token-789"
            }
        }
        """

        // When
        let data = newMemberJSON.data(using: .utf8)!
        let response = try JSONDecoder().decode(
            APIResponse<OAuthLoginResponseDTO>.self,
            from: data
        )

        // Then
        #expect(response.isSuccess == true)
        let dto = try response.unwrap()
        #expect(dto.oAuthVerificationToken == "verify-token-789")

        // toDomain 검증
        let result = dto.toDomain()
        if case .newMember(let verificationToken) = result {
            #expect(verificationToken == "verify-token-789")
        } else {
            Issue.record("Expected newMember")
        }
    }
}

