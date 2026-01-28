//
//  ModifyProfileData.swift
//  AppProduct
//
//  Created by euijjang97 on 1/26/26.
//

import Foundation

/// 마이페이지에서 사용되는 프로필 전체 데이터를 나타내는 모델입니다.
struct ProfileData: Identifiable, Equatable, Hashable {
    /// 프로필 데이터의 고유 식별자 (로컬 생성)
    var id: UUID = .init()
    
    /// 챌린지 ID (서버 연동 등에서 사용)
    var challengeId: Int
    
    /// 사용자 기본 정보 (이름, 학교, 기수 등)
    var challangerInfo: ChallengerInfo
    
    /// 현재 연동된 소셜 계정 목록
    var socialConnected: [SocialType]
    
    /// 활동 이력 목록 (기수별, 역할별)
    var activityLogs: [ActivityLog]
    
    /// 외부 프로필 링크 목록 (Github, Blog 등)
    var profileLink: [ProfileLink]
}

/// 특정 기수/파트에서의 활동 기록을 나타내는 모델입니다.
struct ActivityLog: Identifiable, Equatable, Hashable {
    /// 활동 기록의 고유 식별자
    var id: UUID = .init()
    
    /// 활동 당시의 파트 (기획, 디자인, 서버 등)
    var part: UMCPartType
    
    /// 활동 기수 (예: 11기, 12기)
    var generation: Int
    
    /// 맡았던 역할 (회장, 팀원 등)
    var role: ManagementTeam
}

/// 외부 소셜/포트폴리오 링크 정보를 나타내는 모델입니다.
struct ProfileLink: Identifiable, Equatable, Hashable {
    /// 링크 항목의 고유 식별자
    var id: UUID = .init()

    /// 링크 타입 (Github, LinkedIn, Blog 등)
    var type: SocialLinkType

    /// 실제 URL 문자열
    var url: String

    /// 화면에 표시용 URL 문자열입니다.
    /// 'http://', 'https://' 스키마를 제거하여 깔끔하게 표시합니다.
    var displayURL: String {
        url.replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
    }
}





