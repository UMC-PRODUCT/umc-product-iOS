//
//  MemberAttendanceRecord.swift
//  AppProduct
//
//  Created by 김미주 on 2/6/26.
//

import Foundation

/// 멤버 출석/활동 기록
///
/// 멤버 상세 화면에서 출석 이력을 표시하기 위한 모델입니다.
/// SessionInfo의 title과 Attendance 정보를 포함합니다.
struct MemberAttendanceRecord: Identifiable, Equatable {
    let id: UUID = UUID()
    
    /// 세션 제목
    let sessionTitle: String
    
    /// 주차 (예: 1, 2, 3...)
    let week: Int
    
    /// 출석 정보
    let status: AttendanceStatus
}
