//
//  DeleteScheduleUseCaseProtocol.swift
//  AppProduct
//
//  Created by Codex on 2/13/26.
//

import Foundation

/// 일정 + 출석부 통합 삭제 UseCase Protocol
protocol DeleteScheduleUseCaseProtocol {
    // MARK: - Function

    /// 일정과 연결된 출석부를 함께 삭제합니다.
    /// - Parameter scheduleId: 삭제할 일정 ID
    /// - Throws: 서버 에러 또는 네트워크 에러
    func execute(scheduleId: Int) async throws
}
