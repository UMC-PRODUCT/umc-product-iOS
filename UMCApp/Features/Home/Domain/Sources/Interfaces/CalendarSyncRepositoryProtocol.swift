//
//  CalendarSyncRepositoryProtocol.swift
//  HomeDomain
//
//  Created by euijjang97 on 9/16/26.
//

import Foundation

/// UMC 일정을 애플 캘린더로 내보내는 저장소 프로토콜.
///
/// 앱 → 애플 캘린더 단방향이다. 구현체는 "UMC" 전용 캘린더 하나를 확보해 그 안에만 쓰고,
/// 사용자의 다른 캘린더는 건드리지 않는다. 연동 ON/OFF 플래그도 이 저장소가 소유한다
/// (기기 로컬 값이므로 `UserDefaults` 에 둔다).
public protocol CalendarSyncRepositoryProtocol {

    /// 연동이 켜져 있는지 여부. 기본값은 OFF(opt-in)다.
    var isSyncEnabled: Bool { get }

    /// 현재 캘린더 접근 권한 상태.
    var authorization: CalendarSyncAuthorization { get }

    /// 풀 액세스 권한을 요청하고 허용 여부를 반환한다.
    func requestAccess() async throws -> Bool

    /// 연동을 켠다. 권한이 확보된 뒤에만 호출한다.
    func enableSync()

    /// 연동을 끄고 "UMC" 캘린더와 이벤트 매핑을 모두 지운다.
    ///
    /// 캘린더를 통째로 지우므로 사용자 캘린더 앱에서도 UMC 일정이 한 번에 사라진다.
    func disableSync() async throws

    /// 주어진 구간의 일정을 전용 캘린더에 반영한다.
    ///
    /// 같은 구간을 몇 번 호출해도 이벤트가 중복 생성되지 않는다 — 매핑에 남은 이벤트는 갱신하고,
    /// 구간 안의 UMC 캘린더 이벤트 중 `schedules` 에 없는 것은 삭제한다.
    ///
    /// - Parameters:
    ///   - from: 반영할 구간 시작 시각
    ///   - to: 반영할 구간 종료 시각
    ///   - schedules: 그 구간의 서버 일정 (호출자가 이미 필터링한 결과)
    func reconcile(from: Date, to: Date, schedules: [ScheduleDetailData]) async throws
}
