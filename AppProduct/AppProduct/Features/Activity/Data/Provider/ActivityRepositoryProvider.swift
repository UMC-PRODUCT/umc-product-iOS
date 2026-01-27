//
//  ActivityRepositoryProvider.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/27/26.
//

import Foundation

/// Activity Feature에서 사용하는 Repository들을 제공하는 Provider Protocol
protocol ActivityRepositoryProviding {
    /// 출석 데이터 접근 Repository
    var attendanceRepository: AttendanceRepositoryProtocol { get }
    /// 세션 목록 데이터 접근 Repository
    var sessionRepository: SessionRepositoryProtocol { get }
    /// Activity 통합 데이터 접근 Repository
    var activityRepository: ActivityRepositoryProtocol { get }
}

/// Activity Repository Provider 구현
///
/// Activity Feature 전용 Repository들을 중앙에서 관리합니다.
/// Mock/Real 구현체 교체 시 이 Provider만 수정하면 됩니다.
final class ActivityRepositoryProvider: ActivityRepositoryProviding {

    // MARK: - Property

    let attendanceRepository: AttendanceRepositoryProtocol
    let sessionRepository: SessionRepositoryProtocol
    let activityRepository: ActivityRepositoryProtocol

    // MARK: - Init

    init(
        attendanceRepository: AttendanceRepositoryProtocol,
        sessionRepository: SessionRepositoryProtocol,
        activityRepository: ActivityRepositoryProtocol
    ) {
        self.attendanceRepository = attendanceRepository
        self.sessionRepository = sessionRepository
        self.activityRepository = activityRepository
    }
}

// MARK: - Factory

extension ActivityRepositoryProvider {
    /// Mock Repository들로 구성된 Provider 생성
    static func mock() -> ActivityRepositoryProvider {
        ActivityRepositoryProvider(
            attendanceRepository: MockAttendanceRepository(),
            sessionRepository: MockSessionRepository(),
            activityRepository: MockActivityRepository()
        )
    }

    // TODO: 서버 연결 시 실제 구현체로 변경 예정 - [25.1.27] 이재원
    // static func real() -> ActivityRepositoryProvider {
    //     ActivityRepositoryProvider(
    //         attendanceRepository: AttendanceRepository(),
    //         sessionRepository: SessionRepository(),
    //         activityRepository: ActivityRepository()
    //     )
    // }
}
