//
//  ProfileData.swift
//  MyPageDomain
//
//  Created by euijjang97 on 5/10/26.
//

import Foundation
import UMCFoundation
import CoreDomain

/// 마이페이지에서 사용되는 프로필 전체 데이터를 나타내는 모델입니다.
public struct ProfileData: Identifiable, Equatable, Hashable {
    /// 프로필 데이터의 고유 식별자 (로컬 생성)
    public var id: UUID = .init()

    /// 챌린지 ID (서버 연동 등에서 사용)
    public var challengeId: Int

    /// 사용자 기본 정보 (이름, 학교, 기수 등)
    public var challengerInfo: ChallengerInfo

    /// 현재 연동된 소셜 계정 목록
    public var socialConnections: [SocialConnection]

    /// 활동 이력 목록 (기수별, 역할별)
    public var activityLogs: [ActivityLog]

    /// 홈과 동일한 프로덕트 계정 표시 여부(SUPER_ADMIN 포함).
    public var isUmcProduct: Bool

    /// 외부 프로필 링크 목록 (Github, Blog 등)
    public var profileLink: [ProfileLink]

    /// 명함 뒷면에 싣는 이메일 (#1678). 따로 입력받지 않고 계정에 있는 이메일을 쓴다 —
    /// 명함 쪽(`Profile+MyCard`)과 같은 규칙으로 최근 활동 기록의 이메일, 없으면 로그인 이메일.
    public var email: String

    /// 화면 표시용 연동 소셜 타입 목록
    public var socialConnected: [SocialType] {
        socialConnections.map(\.socialType)
    }

    public init(
        id: UUID = .init(),
        challengeId: Int,
        challengerInfo: ChallengerInfo,
        socialConnections: [SocialConnection],
        activityLogs: [ActivityLog],
        profileLink: [ProfileLink],
        email: String = "",
        isUmcProduct: Bool = false
    ) {
        self.id = id
        self.challengeId = challengeId
        self.challengerInfo = challengerInfo
        self.socialConnections = socialConnections
        self.activityLogs = activityLogs
        self.profileLink = profileLink
        self.email = email
        self.isUmcProduct = isUmcProduct
    }
}

/// 연동된 소셜 계정의 서버 식별자와 타입을 나타내는 모델입니다.
public struct SocialConnection: Identifiable, Equatable, Hashable {
    /// OAuth 연동 ID (서버 응답 String 기준)
    public let memberOAuthId: String

    /// 연동된 소셜 타입
    public let socialType: SocialType

    public var id: String { memberOAuthId }

    public init(memberOAuthId: String, socialType: SocialType) {
        self.memberOAuthId = memberOAuthId
        self.socialType = socialType
    }
}

/// 외부 소셜/포트폴리오 링크 정보를 나타내는 모델입니다.
public struct ProfileLink: Identifiable, Equatable, Hashable {
    /// 링크 항목의 고유 식별자
    public var id: UUID = .init()

    /// 링크 타입 (Github, LinkedIn, Blog 등)
    public var type: SocialLinkType

    /// 실제 URL 문자열
    public var url: String

    /// 화면에 표시용 URL 문자열입니다.
    /// 'http://', 'https://' 스키마를 제거하여 깔끔하게 표시합니다.
    public var displayURL: String {
        url.replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
    }

    public init(id: UUID = .init(), type: SocialLinkType, url: String) {
        self.id = id
        self.type = type
        self.url = url
    }
}
