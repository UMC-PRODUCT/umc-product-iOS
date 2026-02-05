//
//  OperatorSessionAttendance.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/5/26.
//

import Foundation

/// 운영진 관점의 세션 출석 정보
///
/// 세션별 출석 현황과 승인 대기 멤버 목록을 관리합니다.
struct OperatorSessionAttendance: Identifiable, Equatable {
    let id: String
    let session: Session
    let attendanceRate: Double
    let attendedCount: Int
    let totalCount: Int
    let pendingMembers: [PendingMember]

    var pendingCount: Int {
        pendingMembers.count
    }

    /// 모든 출석이 승인 완료되었는지 여부
    var isAllApproved: Bool {
        pendingMembers.isEmpty
    }
}

// PendingMember는 이미 OperatorSessionCard.swift에 정의되어 있으므로 재사용
