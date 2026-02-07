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
    let id: UUID = .init()
    let serverID: String?
    let session: Session
    let attendanceRate: Double
    let attendedCount: Int
    let totalCount: Int
    let pendingMembers: [OperatorPendingMember]

    var pendingCount: Int {
        pendingMembers.count
    }

    /// 모든 출석이 승인 완료되었는지 여부
    var isAllApproved: Bool {
        pendingMembers.isEmpty
    }
}

// MARK: - copyWith

extension OperatorSessionAttendance {
    /// 특정 프로퍼티만 변경한 새 인스턴스 생성
    ///
    /// - Parameters:
    ///   - attendedCount: 출석 완료 인원 (nil이면 기존 값 유지)
    ///   - pendingMembers: 승인 대기 멤버 목록 (nil이면 기존 값 유지)
    /// - Returns: 변경된 프로퍼티가 적용된 새 인스턴스
    ///
    /// - Note: `attendedCount` 변경 시 `attendanceRate`가 자동 재계산됩니다.
    func copyWith(
        attendedCount: Int? = nil,
        pendingMembers: [OperatorPendingMember]? = nil
    ) -> OperatorSessionAttendance {
        let newAttendedCount = attendedCount ?? self.attendedCount
        let newAttendanceRate = totalCount > 0
            ? Double(newAttendedCount) / Double(totalCount)
            : 0.0

        return OperatorSessionAttendance(
            serverID: self.serverID,
            session: self.session,
            attendanceRate: newAttendanceRate,
            attendedCount: newAttendedCount,
            totalCount: self.totalCount,
            pendingMembers: pendingMembers ?? self.pendingMembers
        )
    }
}
