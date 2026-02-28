//
//  FetchMembersUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/5/26.
//

import Foundation

/// 멤버 목록 조회 UseCase
protocol FetchMembersUseCaseProtocol {
    /// 멤버 목록 조회
    func execute() async throws -> [MemberManagementItem]

    /// 챌린저에게 아웃 포인트를 부여합니다.
    func grantOutPoint(
        challengerId: Int,
        description: String
    ) async throws

    /// 챌린저 아웃 포인트를 삭제합니다.
    func deleteOutPoint(
        challengerPointId: Int
    ) async throws

    /// 특정 챌린저의 출석/활동 기록을 조회합니다.
    func fetchAttendanceRecords(
        challengerId: Int
    ) async throws -> [MemberAttendanceRecord]
}
