//
//  MyPageRouterTest.swift
//  MyPageData
//
//  Created by One on 5/10/26.
//

import Foundation
import Testing
import Moya
import CoreNetwork
import MyPageDomain
@testable import MyPageData

@Suite("MyPageRouter")
struct MyPageRouterTests {

    // MARK: - getTerms case

    @Suite("getTerms")
    struct GetTermsTests {

        @Test("path는 /api/v1/terms/type/{termsType} 형식이다",
              arguments: ["PRIVACY", "SERVICE", "MARKETING"])
        func path(termsType: String) {
            let router = MyPageRouter.getTerms(termsType: termsType)
            #expect(router.path == "/api/v1/terms/type/\(termsType)")
        }

        @Test("method는 .get이다")
        func method() {
            let router = MyPageRouter.getTerms(termsType: "PRIVACY")
            #expect(router.method == .get)
        }

        @Test("task는 .requestPlain이다")
        func task() {
            let router = MyPageRouter.getTerms(termsType: "PRIVACY")

            guard case .requestPlain = router.task else {
                Issue.record("Expected .requestPlain, got \(router.task)")
                return
            }
        }
    }

    // MARK: - BaseTargetType extension defaults

    @Suite("BaseTargetType 기본 구현")
    struct BaseTargetTypeDefaultsTests {

        // NOTE: baseURL/headers는 NetworkConfig → Info.plist의 BASE_URL을 읽는데,
        //       UMCApp Secret 인프라(Secrets.xcconfig + Project.swift infoPlist 주입)가
        //       아직 미구축 상태라 테스트 번들에서 fatalError가 발생합니다.
        //       후속 Secret 인프라 PR에서 인프라 구축 후 .disabled를 제거하세요.
        @Test(
            "baseURL은 NetworkConfig.baseURL을 사용한다",
            .disabled("UMCApp Secret 인프라 구축 후 활성화")
        )
        func baseURL() {
            let router = MyPageRouter.getTerms(termsType: "PRIVACY")
            #expect(router.baseURL == NetworkConfig.baseURL)
        }

        @Test(
            "headers는 NetworkConfig.defaultHeaders를 사용한다",
            .disabled("UMCApp Secret 인프라 구축 후 활성화")
        )
        func headers() {
            let router = MyPageRouter.getTerms(termsType: "PRIVACY")
            #expect(router.headers == NetworkConfig.defaultHeaders)
        }

        @Test("validationType은 .successCodes다")
        func validationType() {
            let router = MyPageRouter.getTerms(termsType: "PRIVACY")

            guard case .successCodes = router.validationType else {
                Issue.record("Expected .successCodes, got \(router.validationType)")
                return
            }
        }
    }
}

// MARK: - 이식 케이스: path / method

/// `refac/803`에서 이식된 케이스(멤버·챌린저 프로필, 회원 수정·탈퇴, 활동 게시글)의
/// path·method 계약을 검증합니다.
/// (`getTerms`는 위 `MyPageRouterTests` 스위트에서 별도 검증. `getMyProfile`은 `refac/961`에서
/// 정본 파이프라인(``CoreNetwork/MemberProfileRouter``)으로 대체되어 제거됨)
@Suite("MyPageRouter — 이식 케이스 path/method 계약")
struct MyPageRouterMigratedPathMethodTests {

    @Test("getMemberProfile — memberId가 path에 보간되고 method는 .get")
    func getMemberProfile() {
        let router = MyPageRouter.getMemberProfile(memberId: 7)
        #expect(router.path == "/api/v1/member/profile/7")
        #expect(router.method == .get)
    }

    @Test("getChallengerProfile — challengerId가 path에 보간되고 method는 .get")
    func getChallengerProfile() {
        let router = MyPageRouter.getChallengerProfile(challengerId: 3)
        #expect(router.path == "/api/v1/challenger/3")
        #expect(router.method == .get)
    }

    @Test("addChallengerRecord — path는 /api/v1/challenger-record/member, method는 .post")
    func addChallengerRecord() {
        let router = MyPageRouter.addChallengerRecord(code: "ABC123")
        #expect(router.path == "/api/v1/challenger-record/member")
        #expect(router.method == .post)
    }

    @Test("patchMember — path는 /api/v1/member, method는 .patch")
    func patchMember() {
        let router = MyPageRouter.patchMember(
            request: UpdateMemberProfileImageRequestDTO(profileImageId: "img-1")
        )
        #expect(router.path == "/api/v1/member")
        #expect(router.method == .patch)
    }

    @Test("getMyBusinessCardEdit — path는 /api/v1/member/me/business-card/edit, method는 .get")
    func getMyBusinessCardEdit() {
        let router = MyPageRouter.getMyBusinessCardEdit
        #expect(router.path == "/api/v1/member/me/business-card/edit")
        #expect(router.method == .get)
    }

    @Test("patchMyBusinessCard — path는 /api/v1/member/me/business-card, method는 .patch")
    func patchMyBusinessCard() {
        let router = MyPageRouter.patchMyBusinessCard(
            request: EditBusinessCardRequestDTO(settings: CardContactSettings())
        )
        #expect(router.path == "/api/v1/member/me/business-card")
        #expect(router.method == .patch)
    }

    @Test("deleteMember — path는 /api/v1/member, method는 .delete")
    func deleteMember() {
        let router = MyPageRouter.deleteMember(
            request: DeleteMemberRequestDTO(googleAccessToken: nil, kakaoAccessToken: nil)
        )
        #expect(router.path == "/api/v1/member")
        #expect(router.method == .delete)
    }

    @Test("patchMember와 deleteMember는 path가 같고 method로만 구분된다")
    func patchAndDeleteShareSamePath() {
        let patch = MyPageRouter.patchMember(
            request: UpdateMemberProfileImageRequestDTO(profileImageId: "x")
        )
        let delete = MyPageRouter.deleteMember(
            request: DeleteMemberRequestDTO(googleAccessToken: nil, kakaoAccessToken: nil)
        )
        #expect(patch.path == delete.path)      // 둘 다 /api/v1/member
        #expect(patch.method == .patch)
        #expect(delete.method == .delete)
    }
}

// MARK: - 이식 케이스: task 형태

@Suite("MyPageRouter — 이식 케이스 task 형태 계약")
struct MyPageRouterMigratedTaskTests {

    @Test("조회 계열(getMemberProfile/getChallengerProfile/getMyBusinessCardEdit) — task는 .requestPlain")
    func plainTasks() {
        #expect(isRequestPlain(MyPageRouter.getMemberProfile(memberId: 7).task))
        #expect(isRequestPlain(MyPageRouter.getChallengerProfile(challengerId: 3).task))
        #expect(isRequestPlain(MyPageRouter.getMyBusinessCardEdit.task))
    }

    @Test("본문 전송 계열(기록 추가·프로필 수정·명함 수정·탈퇴) — task는 .requestJSONEncodable")
    func jsonEncodableTasks() {
        #expect(isRequestJSONEncodable(MyPageRouter.addChallengerRecord(code: "ABC").task))
        #expect(isRequestJSONEncodable(
            MyPageRouter.patchMember(
                request: UpdateMemberProfileImageRequestDTO(profileImageId: "x")
            ).task
        ))
        #expect(isRequestJSONEncodable(
            MyPageRouter.patchMyBusinessCard(
                request: EditBusinessCardRequestDTO(settings: CardContactSettings())
            ).task
        ))
        #expect(isRequestJSONEncodable(
            MyPageRouter.deleteMember(
                request: DeleteMemberRequestDTO(googleAccessToken: nil, kakaoAccessToken: nil)
            ).task
        ))
    }

    @Test("deleteMember — task 바디에 Google·Kakao access token이 실린다")
    func deleteMemberTaskBodyCarriesTokens() throws {
        let router = MyPageRouter.deleteMember(
            request: DeleteMemberRequestDTO(
                googleAccessToken: "google-token",
                kakaoAccessToken: "kakao-token"
            )
        )
        guard case .requestJSONEncodable(let body) = router.task else {
            Issue.record("Expected .requestJSONEncodable, got \(router.task)")
            return
        }
        let json = try encodeToJSON(body)
        #expect(json["googleAccessToken"] as? String == "google-token")
        #expect(json["kakaoAccessToken"] as? String == "kakao-token")
        #expect(json.keys.count == 2)
    }
}

// MARK: - 요청 DTO / 쿼리 인코딩 계약

@Suite("MyPageRouter — 요청 DTO/쿼리 인코딩 계약")
struct MyPageRouterEncodingTests {

    @Test("AddChallengerRecordRequestDTO — { code } 단일 키로 인코딩")
    func addChallengerRecordDTOEncoding() throws {
        let json = try encodeToJSON(AddChallengerRecordRequestDTO(code: "INVITE-42"))
        #expect(json["code"] as? String == "INVITE-42")
        #expect(json.keys.count == 1)
    }

    @Test("UpdateMemberProfileImageRequestDTO — { profileImageId } 단일 키로 인코딩")
    func updateProfileImageDTOEncoding() throws {
        let json = try encodeToJSON(UpdateMemberProfileImageRequestDTO(profileImageId: "file-9"))
        #expect(json["profileImageId"] as? String == "file-9")
        #expect(json.keys.count == 1)
    }

    /// 서버는 링크를 전체 교체한다 — 목록에 없는 종류는 지우고, 빈 문자열은 빈 값으로 저장한다.
    @Test("EditBusinessCardRequestDTO — 링크 5종을 모두 싣고, 빈 값은 link 키를 빼며, 공백을 다듬는다")
    func editBusinessCardDTOEncoding() throws {
        let settings = CardContactSettings(
            isEmailPublic: false,
            links: [
                .github: CardContactItem(value: "https://github.com/umc ", isPublic: true),
                .blog: CardContactItem(value: "   ", isPublic: false)
            ]
        )
        let json = try encodeToJSON(EditBusinessCardRequestDTO(settings: settings))
        let contact = try #require(json["contact"] as? [String: Any])
        let links = try #require(json["links"] as? [[String: Any]])
        let byType = Dictionary(uniqueKeysWithValues: links.map { ($0["type"] as? String ?? "", $0) })

        #expect(json["profileImageId"] == nil)
        #expect(contact["email"] == nil)
        #expect(contact["isPublic"] as? Bool == false)
        #expect(links.map { $0["type"] as? String } == SocialLinkType.allCases.map(\.apiType))
        #expect(byType["GITHUB"]?["link"] as? String == "https://github.com/umc")
        #expect(byType["BLOG"]?["link"] == nil)
        #expect(byType["BLOG"]?["isPublic"] as? Bool == false)
        #expect(byType["LINKEDIN"]?["isPublic"] as? Bool == true)
    }

    /// 저장 API는 연락용 이메일 칸을 늘 함께 받는다. 비워 보내면 서버가 저장된 값을 지운다.
    @Test("EditBusinessCardRequestDTO — 연락용 이메일은 받은 그대로 다시 싣고, 없으면 email 키를 뺀다")
    func editBusinessCardDTOPassesContactEmailThrough() throws {
        let kept = try encodeToJSON(EditBusinessCardRequestDTO(
            settings: CardContactSettings(isEmailPublic: false, contactEmail: "contact@umc.dev")
        ))
        let empty = try encodeToJSON(EditBusinessCardRequestDTO(settings: CardContactSettings()))
        let keptContact = try #require(kept["contact"] as? [String: Any])
        let emptyContact = try #require(empty["contact"] as? [String: Any])

        #expect(keptContact["email"] as? String == "contact@umc.dev")
        #expect(keptContact["isPublic"] as? Bool == false)
        #expect(emptyContact["email"] == nil)
        #expect(emptyContact["isPublic"] as? Bool == true)
    }

    @Test("DeleteMemberRequestDTO — nil 토큰은 키째 빠진다 (서버는 해당 Provider revoke만 건너뜀)")
    func deleteMemberDTOOmitsNilTokens() throws {
        let kakaoOnly = try encodeToJSON(
            DeleteMemberRequestDTO(googleAccessToken: nil, kakaoAccessToken: "kakao-token")
        )
        #expect(kakaoOnly["kakaoAccessToken"] as? String == "kakao-token")
        #expect(kakaoOnly.keys.count == 1)

        let empty = try encodeToJSON(
            DeleteMemberRequestDTO(googleAccessToken: nil, kakaoAccessToken: nil)
        )
        #expect(empty.isEmpty)
    }
}

// MARK: - Test Helpers

private func isRequestPlain(_ task: Moya.Task) -> Bool {
    if case .requestPlain = task { return true }
    return false
}

private func isRequestJSONEncodable(_ task: Moya.Task) -> Bool {
    if case .requestJSONEncodable = task { return true }
    return false
}

private func encodeToJSON(_ value: some Encodable) throws -> [String: Any] {
    let data = try JSONEncoder().encode(value)
    let object = try JSONSerialization.jsonObject(with: data)
    return try #require(object as? [String: Any])
}
