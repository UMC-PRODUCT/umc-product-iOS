//
//  MyPageRouter.swift
//  MyPageData
//
//  Created by One on 5/6/26.
//

import Foundation
import Moya
import CoreNetwork

/// 마이페이지 Feature API 라우터
///
/// `BaseTargetType`을 통해 baseURL/headers/validation 기본 동작을 상속받습니다.
/// 각 case의 path/method/task는 본 extension에서 정의합니다.
public enum MyPageRouter {
    /// 특정 멤버 프로필 조회 (`GET /api/v1/member/profile/{memberId}`)
    case getMemberProfile(memberId: Int)
    /// 특정 챌린저 프로필 조회
    case getChallengerProfile(challengerId: Int)
    /// 기존 챌린저 기록 추가
    case addChallengerRecord(code: String)
    /// 회원 정보 수정(프로필 이미지 ID 반영)
    case patchMember(request: UpdateMemberProfileImageRequestDTO)
    /// 명함 수정 화면 조회 — 연락처·링크와 공개 여부 (`GET /api/v1/member/me/business-card/edit`)
    case getMyBusinessCardEdit
    /// 명함 수정 — 연락처·링크와 공개 여부 (`PATCH /api/v1/member/me/business-card`)
    case patchMyBusinessCard(request: EditBusinessCardRequestDTO)
    /// 회원 탈퇴 (소셜 연동 해제용 access token 동봉)
    case deleteMember(request: DeleteMemberRequestDTO)
    /// 약관 조회 (`GET /api/v1/terms/type/{termsType}`)
    case getTerms(termsType: String)
}

// MARK: - BaseTargetType

extension MyPageRouter: BaseTargetType {
    public var path: String {
        switch self {
        case .getMemberProfile(let memberId):
            return "/api/v1/member/profile/\(memberId)"
        case .getChallengerProfile(let challengerId):
            return "/api/v1/challenger/\(challengerId)"
        case .addChallengerRecord:
            return "/api/v1/challenger-record/member"
        case .patchMember:
            return "/api/v1/member"
        case .getMyBusinessCardEdit:
            return "/api/v1/member/me/business-card/edit"
        case .patchMyBusinessCard:
            return "/api/v1/member/me/business-card"
        case .deleteMember:
            return "/api/v1/member"
        case .getTerms(let termsType):
            return "/api/v1/terms/type/\(termsType)"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getMemberProfile:
            return .get
        case .getChallengerProfile:
            return .get
        case .addChallengerRecord:
            return .post
        case .patchMember:
            return .patch
        case .getMyBusinessCardEdit:
            return .get
        case .patchMyBusinessCard:
            return .patch
        case .deleteMember:
            return .delete
        case .getTerms:
            return .get
        }
    }

    public var task: Moya.Task {
        switch self {
        case .getMemberProfile, .getChallengerProfile, .getMyBusinessCardEdit:
            return .requestPlain
        case .addChallengerRecord(let code):
            return .requestJSONEncodable(
                AddChallengerRecordRequestDTO(code: code)
            )
        case .patchMember(let request):
            return .requestJSONEncodable(request)
        case .patchMyBusinessCard(let request):
            return .requestJSONEncodable(request)
        case .deleteMember(let request):
            return .requestJSONEncodable(request)
        case .getTerms:
            return .requestPlain
        }
    }
}
