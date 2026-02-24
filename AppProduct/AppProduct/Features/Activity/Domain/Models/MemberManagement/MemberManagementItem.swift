//
//  MemberManagementItem.swift
//  AppProduct
//
//  Created by 이예지 on 1/8/26.
//

import Foundation
import SwiftUI

// MARK: - MemberManagementItem

/// 멤버 관리 리스트에서 사용되는 데이터 모델입니다.
///
/// - MemberManagementCard: 맴버 카드 뷰
/// - CoreMemberManagementList: 핵심 멤버 리스트 뷰
/// 위 두 뷰에서 공통으로 사용됩니다.
struct MemberManagementItem: Identifiable, Equatable {
    /// 고유 식별자
    let id: UUID

    /// 멤버 고유 식별자
    let memberID: Int?

    /// 챌린저 고유 식별자
    let challengerID: Int?
    
    /// 프로필 이미지 리소스
    let profile: String?
    
    /// 멤버 이름
    let name: String
    
    /// 멤버 닉네임
    let nickname: String
    
    /// 기수 정보 (예: "9기")
    let generation: String
    
    /// 소속 학교
    let school: String
    
    /// 포지션 정보 (Deprecated 가능성 있음, part와 중복?)
    let position: String
    
    /// 파트 정보 (iOS, Web 등)
    let part: UMCPartType
    
    /// 현재 누적 패널티 점수
    let penalty: Double
    
    /// 뱃지 표시 여부
    let badge: Bool
    
    // CoreManagementItem 관련
    
    /// 운영진 직책 정보 (회장, 부회장 등)
    let managementTeam: ManagementTeam
    
    // 상세 시트 사용
    
    /// 출석/활동 기록 목록
    let attendanceRecords: [MemberAttendanceRecord]
    
    /// 경고 히스토리
    let penaltyHistory: [OperatorMemberPenaltyHistory]

    init(
        id: UUID = .init(),
        memberID: Int? = nil,
        challengerID: Int? = nil,
        profile: String?,
        name: String,
        nickname: String,
        generation: String,
        school: String,
        position: String,
        part: UMCPartType,
        penalty: Double,
        badge: Bool,
        managementTeam: ManagementTeam,
        attendanceRecords: [MemberAttendanceRecord],
        penaltyHistory: [OperatorMemberPenaltyHistory]
    ) {
        self.id = id
        self.memberID = memberID
        self.challengerID = challengerID
        self.profile = profile
        self.name = name
        self.nickname = nickname
        self.generation = generation
        self.school = school
        self.position = position
        self.part = part
        self.penalty = penalty
        self.badge = badge
        self.managementTeam = managementTeam
        self.attendanceRecords = attendanceRecords
        self.penaltyHistory = penaltyHistory
    }
}
