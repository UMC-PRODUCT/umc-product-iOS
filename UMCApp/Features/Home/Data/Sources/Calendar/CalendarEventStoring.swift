//
//  CalendarEventStoring.swift
//  HomeData
//
//  Created by euijjang97 on 9/16/26.
//

import Foundation
import HomeDomain

/// 캘린더에 쓸 이벤트 한 건의 값. EventKit 타입을 쓰지 않아 fake 저장소로 대체할 수 있다.
public struct CalendarEventDraft: Equatable, Sendable {

    // MARK: - Property

    public let title: String
    public let notes: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool

    /// 일정 장소 (`nil` = 비대면 — 이벤트의 장소를 비운다)
    public let location: ScheduleLocation?

    /// 절대시각 알람 (`nil` = 알람 없음 — 캘린더 기본 알림 설정에 맡긴다)
    public let alarmDate: Date?

    // MARK: - Init

    public init(
        title: String,
        notes: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        location: ScheduleLocation?,
        alarmDate: Date?
    ) {
        self.title = title
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.location = location
        self.alarmDate = alarmDate
    }
}

/// 캘린더 저장소 추상화.
///
/// `EKEventStore` 를 이 프로토콜 뒤에 숨겨 `import EventKit` 이 어댑터
/// (``EventKitEventStore``) 한 파일 밖으로 새지 않게 한다. reconcile 규칙은 이 프로토콜의
/// fake 구현으로 유닛 테스트한다.
public protocol CalendarEventStoring: AnyObject {

    /// 현재 캘린더 접근 권한 상태.
    var authorization: CalendarSyncAuthorization { get }

    /// 풀 액세스 권한을 요청하고 허용 여부를 반환한다.
    func requestFullAccess() async throws -> Bool

    /// 전용 캘린더를 만들고 식별자를 반환한다.
    func createCalendar(titled title: String) throws -> String

    /// 해당 식별자의 캘린더가 아직 존재하는지 여부 (사용자가 캘린더 앱에서 지웠을 수 있다).
    func calendarExists(identifier: String) -> Bool

    /// 캘린더를 이벤트째 삭제한다.
    func removeCalendar(identifier: String) throws

    /// 해당 식별자의 이벤트가 아직 존재하는지 여부.
    func eventExists(identifier: String) -> Bool

    /// 구간에 걸친 해당 캘린더의 이벤트 식별자 목록.
    func eventIdentifiers(inCalendar calendarIdentifier: String, from: Date, to: Date) throws
        -> [String]

    /// 이벤트를 저장하고 그 식별자를 반환한다.
    ///
    /// - Parameter identifier: 갱신할 기존 이벤트 식별자. `nil` 이면 새로 만든다.
    func saveEvent(
        _ draft: CalendarEventDraft,
        identifier: String?,
        inCalendar calendarIdentifier: String
    ) throws -> String

    /// 이벤트를 삭제한다.
    func removeEvent(identifier: String) throws
}

/// 캘린더 저장소가 던지는 오류.
///
/// 동기화는 부수효과라 화면 흐름을 막지 않는다 — 호출자(``CalendarSyncRepository`` 소비자)는
/// 이 오류를 로그로만 남긴다.
public enum CalendarStoreError: Error, Equatable {

    /// 전용 캘린더를 만들 수 있는 소스(iCloud/로컬)가 없다.
    case noAvailableSource

    /// 식별자에 해당하는 캘린더를 찾지 못했다 (사용자가 캘린더 앱에서 삭제).
    case calendarNotFound

    /// 식별자에 해당하는 이벤트를 찾지 못했다.
    case eventNotFound
}
