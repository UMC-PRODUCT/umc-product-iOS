//
//  MyPageRouter.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation
internal import Alamofire
import Moya

/// 마이페이지 Feature API 라우터
///
/// 프로필 조회/수정 및 활동 로그/약관 API를 정의합니다.
enum MyPageRouter {
    /// 내 프로필 조회
    case getMyProfile
    /// 회원 정보 수정 (프로필 이미지 ID 반영)
    case patchMember(request: UpdateMemberProfileImageRequestDTO)
    /// 회원 탈퇴
    case deleteMember
    /// 내가 쓴 글 목록
    case getMyPosts(query: MyPagePostListQuery)
    /// 댓글 단 글 목록
    case getCommentedPosts(query: MyPagePostListQuery)
    /// 스크랩한 글 목록
    case getScrappedPosts(query: MyPagePostListQuery)
    /// 약관 조회
    case getTerms(termsType: String)
}

// MARK: - BaseTargetType

extension MyPageRouter: BaseTargetType {

    var path: String {
        switch self {
        case .getMyProfile:
            return "/api/v1/member/me"
        case .patchMember:
            return "/api/v1/member"
        case .deleteMember:
            return "/api/v1/member"
        case .getMyPosts:
            return "/api/v1/posts/my"
        case .getCommentedPosts:
            return "/api/v1/posts/commented"
        case .getScrappedPosts:
            return "/api/v1/posts/scrapped"
        case .getTerms(let termsType):
            return "/api/v1/terms/type/\(termsType)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getMyProfile:
            return .get
        case .patchMember:
            return .patch
        case .deleteMember:
            return .delete
        case .getMyPosts, .getCommentedPosts, .getScrappedPosts:
            return .get
        case .getTerms:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .getMyProfile, .deleteMember:
            return .requestPlain
        case .patchMember(let request):
            return .requestJSONEncodable(request)
        case .getMyPosts(let query),
             .getCommentedPosts(let query),
             .getScrappedPosts(let query):
            return .requestParameters(
                parameters: query.queryItems,
                encoding: URLEncoding.queryString
            )
        case .getTerms:
            return .requestPlain
        }
    }
}
