//
//  AppStorageKey.swift
//  AppProduct
//
//  Created by euijjang97 on 1/10/26.
//

import Foundation

/// @AppStorage 접근 키
///
/// UserDefaults 사용을 줄이고 `@AppStorage`로 관리합니다.
/// 홈 프로필 조회 시 `HomeViewModel.saveProfileToStorage()`에서 저장됩니다.
enum AppStorageKey {

    // MARK: - System

    /// FCM 푸시 토큰
    static let userFCMToken: String = "UserFCMToken"
    /// 서버에 마지막으로 등록한 FCM 토큰
    static let uploadedFCMToken: String = "UploadedFCMToken"
    /// 서버에 마지막으로 등록한 멤버 ID
    static let uploadedFCMMemberId: String = "UploadedFCMMemberId"
    /// 최근 검색 장소 목록
    static let recentSearchPlaces: String = "recentSearchPlaces"
    /// OAuth 연동된 소셜 provider 목록(JSON 문자열 배열)
    static let connectedSocialProviders: String = "connectedSocialProviders"
    /// 자동 로그인 허용 여부 (승인/등록 완료 사용자만 true)
    static let canAutoLogin: String = "canAutoLogin"

    // MARK: - Profile (최신 기수 기준)

    /// 서버 기수 식별 ID
    static let gisuId: String = "gisuId"
    /// 멤버 고유 ID
    static let memberId: String = "memberId"
    /// 챌린저 ID (패널티 API 파라미터)
    static let challengerId: String = "challengerId"
    /// 학교 ID
    static let schoolId: String = "schoolId"
    /// 학교 이름
    static let schoolName: String = "schoolName"
    /// 지부 ID
    static let chapterId: String = "chapterId"
    /// 지부 이름
    static let chapterName: String = "chapterName"
    /// 담당 파트 (`UMCPartType.apiValue` 문자열, 예: "IOS")
    static let responsiblePart: String = "responsiblePart"
    /// 멤버 역할 (`ManagementTeam.rawValue` 문자열)
    static let memberRole: String = "memberRole"
    /// 사용자가 보유한 전체 역할 목록 (`[ManagementTeam.rawValue]`)
    static let memberRoles: String = "memberRoles"
    /// 소속 조직 타입 (`OrganizationType.rawValue` 문자열)
    static let organizationType: String = "organizationType"
    /// 소속 조직 ID (`organizationType`에 따라 지부/학교 ID)
    static let organizationId: String = "organizationId"
    /// 공지 탭에서 현재 선택한 기수 ID (공지 작성 진입 시 사용)
    static let noticeSelectedGisuId: String = "noticeSelectedGisuId"
}
