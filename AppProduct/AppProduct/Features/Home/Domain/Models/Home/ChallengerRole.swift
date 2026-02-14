//
//  ChallengerRole.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation

/// 챌린저 역할 정보 (프로필 → 패널티/공지 API 호출 시 필요)
struct ChallengerRole: Equatable {
    /// 챌린저 ID (패널티 API 파라미터)
    let challengerId: Int
    /// 기수 번호 (예: 9, 10)
    let gisu: Int
    /// 서버 기수 식별 ID (패널티 저장, 공지 조회 파라미터)
    let gisuId: Int
    /// 멤버 역할 타입
    let roleType: ManagementTeam
    /// 담당 파트 (파트장만 해당, 없으면 nil)
    let responsiblePart: UMCPartType?
    /// 소속 조직 타입 (CENTRAL / CHAPTER / SCHOOL)
    let organizationType: OrganizationType
    /// 소속 조직 ID (organizationType에 따라 지부/학교 ID)
    let organizationId: Int
}

/// 홈 프로필 조회 결과
///
/// 프로필 API 한 번 호출로 기수 카드용 데이터와 역할 정보를 함께 반환합니다.
struct HomeProfileResult: Equatable {
    /// 멤버 ID
    let memberId: Int
    /// 학교 ID
    let schoolId: Int
    /// 홈 화면 상단 기수 카드용 데이터 (누적 활동일, 참여 기수)
    let seasonTypes: [SeasonType]
    /// 역할별 상세 정보 매핑
    let roles: [ChallengerRole]
    /// 프로필 응답에서 파생한 기수별 패널티 데이터
    let generations: [GenerationData]
}
