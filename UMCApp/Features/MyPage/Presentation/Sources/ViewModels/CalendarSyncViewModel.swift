//
//  CalendarSyncViewModel.swift
//  MyPagePresentation
//
//  Created by euijjang97 on 9/16/26.
//

import CoreDI
import Foundation
import HomeDomain
import SwiftUI
import UMCFoundation
import os.log

private let logger = Logger(subsystem: "UMCApp", category: "CalendarSync")

/// 마이페이지 "애플 캘린더 연동" 토글 ViewModel.
///
/// 기본 OFF(opt-in)다 — 풀 액세스 팝업을 홈 진입 시 모든 사용자에게 띄우지 않는다.
/// ON 하면 권한을 요청하고, 허용되면 현재 달을 한 번 즉시 동기화한다. 이후 갱신은 홈이
/// 월별 일정을 조회할 때마다 따라온다.
@Observable
@MainActor
public final class CalendarSyncViewModel {

    // MARK: - Property

    /// 토글의 표시 상태. 권한 거부로 켜지지 못하면 OFF 로 남는다.
    public private(set) var isSyncEnabled: Bool

    /// 권한 거부/제한 안내 다이얼로그. 토글은 사용자 액션이라 조용히 넘기지 않는다.
    public var alertPrompt: AlertPrompt?

    /// 토글 처리 중. 권한 팝업과 첫 동기화가 끝나기 전의 중복 탭을 막는다.
    public private(set) var isBusy = false

    private let repository: CalendarSyncRepositoryProtocol
    private let fetchSchedulesUseCase: FetchSchedulesUseCaseProtocol
    private let syncSchedulesUseCase: SyncSchedulesToCalendarUseCaseProtocol

    // MARK: - Init

    public init(container: DIContainer) {
        repository = container.resolve(CalendarSyncRepositoryProtocol.self)
        fetchSchedulesUseCase = container.resolve(FetchSchedulesUseCaseProtocol.self)
        syncSchedulesUseCase = container.resolve(SyncSchedulesToCalendarUseCaseProtocol.self)
        isSyncEnabled = repository.isSyncEnabled
    }

    // MARK: - Function

    /// 토글 조작 진입점.
    public func setSyncEnabled(_ enabled: Bool) async {
        guard !isBusy, enabled != isSyncEnabled else { return }
        isBusy = true
        defer { isBusy = false }

        if enabled {
            await enableSync()
        } else {
            await disableSync()
        }
    }

    // MARK: - Private Function

    /// 권한을 확보한 뒤 연동을 켜고 현재 달을 한 번 동기화한다.
    private func enableSync() async {
        guard await ensureAuthorization() else {
            presentPermissionAlert()
            return
        }

        repository.enableSync()
        isSyncEnabled = true
        await syncCurrentMonth()
    }

    /// 연동을 끄고 UMC 캘린더와 매핑을 지운다. 삭제 실패는 사용자가 할 수 있는 일이 없으므로
    /// 로그만 남기고 토글은 OFF 로 내린다.
    private func disableSync() async {
        do {
            try await repository.disableSync()
        } catch {
            logger.error("애플 캘린더 연동 해제 실패: \(error.localizedDescription)")
        }
        isSyncEnabled = false
    }

    private func ensureAuthorization() async -> Bool {
        switch repository.authorization {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            do {
                return try await repository.requestAccess()
            } catch {
                logger.error("캘린더 권한 요청 실패: \(error.localizedDescription)")
                return false
            }
        }
    }

    /// 토글 ON 직후 현재 달만 즉시 반영한다. 홈이 보이는 달만 조회하므로 캘린더도 사용자가
    /// 열어 본 달까지만 채워진다.
    private func syncCurrentMonth() async {
        let calendar = Calendar.kstGregorian
        let now = Date()

        guard
            let startOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: now)
            ),
            let endOfMonth = calendar.date(
                byAdding: DateComponents(month: 1, day: -1),
                to: startOfMonth
            )
        else {
            return
        }

        let from = startOfMonth.kstStartOfDay
        let to = endOfMonth.kstEndOfDay

        do {
            let schedules = try await fetchSchedulesUseCase.execute(
                from: from,
                to: to,
                isAttendanceRequired: false
            )
            try await syncSchedulesUseCase.execute(
                from: from,
                to: to,
                schedules: schedules.values.flatMap { $0 }
            )
        } catch {
            logger.error("애플 캘린더 첫 동기화 실패: \(error.localizedDescription)")
        }
    }

    /// 권한이 막혀 있으면 앱에서 다시 물을 수 없으므로 설정 앱으로 보낸다.
    private func presentPermissionAlert() {
        alertPrompt = AlertPrompt(
            title: "캘린더 접근 권한이 필요합니다",
            message: "설정 앱에서 UMC의 캘린더 접근을 허용하면 일정을 내보낼 수 있습니다.",
            positiveBtnTitle: "설정 열기",
            positiveBtnAction: { openAppSettings() },
            negativeBtnTitle: "취소"
        )
    }
}

/// iOS 설정 앱의 UMC 설정 화면을 연다.
@MainActor
private func openAppSettings() {
    guard
        let url = URL(string: UIApplication.openSettingsURLString),
        UIApplication.shared.canOpenURL(url)
    else {
        return
    }
    UIApplication.shared.open(url)
}
