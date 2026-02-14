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
/// 프로필 조회/수정 및 프로필 이미지 업로드 준비 API를 정의합니다.
enum MyPageRouter {
    /// 내 프로필 조회
    case getMyProfile
    /// 회원 정보 수정 (프로필 이미지 ID 반영)
    case patchMember(request: UpdateMemberProfileImageRequestDTO)
    /// 파일 업로드 준비 (Signed URL 발급)
    case prepareUpload(request: PrepareUploadRequestDTO)
    /// 파일 업로드 완료 확정
    case confirmUpload(fileId: String)
}

extension MyPageRouter: BaseTargetType {

    var path: String {
        switch self {
        case .getMyProfile:
            return "/api/v1/member/me"
        case .patchMember:
            return "/api/v1/member"
        case .prepareUpload:
            return "/api/v1/∫storage/prepare-upload"
        case .confirmUpload(let fileId):
            return "/api/v1/storage/\(fileId)/confirm"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getMyProfile:
            return .get
        case .patchMember:
            return .patch
        case .prepareUpload, .confirmUpload:
            return .post
        }
    }

    var task: Task {
        switch self {
        case .getMyProfile, .confirmUpload:
            return .requestPlain
        case .patchMember(let request):
            return .requestJSONEncodable(request)
        case .prepareUpload(let request):
            return .requestJSONEncodable(request)
        }
    }
}
