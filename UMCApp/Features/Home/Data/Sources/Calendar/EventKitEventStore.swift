//
//  EventKitEventStore.swift
//  HomeData
//
//  Created by euijjang97 on 9/16/26.
//
//  EventKit 어댑터. `import EventKit` 은 이 파일 밖으로 나가지 않는다 — reconcile 규칙은
//  ``CalendarEventStoring`` 뒤에 있으므로 fake 저장소로 테스트한다.
//

import CoreLocation
import EventKit
import Foundation
import HomeDomain
import UMCFoundation

/// ``CalendarEventStoring`` 의 EventKit 구현체.
///
/// 이벤트 생성만 필요하면 write-only 로 충분하지만, 서버에서 수정·삭제된 일정을 따라가려면
/// 기존 이벤트 조회(`event(withIdentifier:)`)·갱신·삭제와 전용 캘린더 생성이 필요하고
/// 이는 전부 풀 액세스에서만 된다. 그래서 `requestFullAccessToEvents()` 만 쓴다.
public final class EventKitEventStore: CalendarEventStoring, @unchecked Sendable {

    // MARK: - Property

    private let store: EKEventStore

    // MARK: - Init

    public init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    // MARK: - Function

    public var authorization: CalendarSyncAuthorization {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .fullAccess:
            return .authorized
        // write-only 는 이벤트 조회가 막혀 reconcile 이 불가능하므로 거부와 같게 본다.
        case .denied, .writeOnly:
            return .denied
        @unknown default:
            return .denied
        }
    }

    public func requestFullAccess() async throws -> Bool {
        try await store.requestFullAccessToEvents()
    }

    public func createCalendar(titled title: String) throws -> String {
        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = title

        guard let source = preferredSource() else { throw CalendarStoreError.noAvailableSource }
        calendar.source = source

        try store.saveCalendar(calendar, commit: true)
        return calendar.calendarIdentifier
    }

    public func calendarExists(identifier: String) -> Bool {
        store.calendar(withIdentifier: identifier) != nil
    }

    public func removeCalendar(identifier: String) throws {
        guard let calendar = store.calendar(withIdentifier: identifier) else {
            throw CalendarStoreError.calendarNotFound
        }
        try store.removeCalendar(calendar, commit: true)
    }

    public func eventExists(identifier: String) -> Bool {
        store.event(withIdentifier: identifier) != nil
    }

    public func eventIdentifiers(
        inCalendar calendarIdentifier: String,
        from: Date,
        to: Date
    ) throws -> [String] {
        guard let calendar = store.calendar(withIdentifier: calendarIdentifier) else {
            throw CalendarStoreError.calendarNotFound
        }

        let predicate = store.predicateForEvents(withStart: from, end: to, calendars: [calendar])
        return store.events(matching: predicate).compactMap(\.eventIdentifier)
    }

    public func saveEvent(
        _ draft: CalendarEventDraft,
        identifier: String?,
        inCalendar calendarIdentifier: String
    ) throws -> String {
        guard let calendar = store.calendar(withIdentifier: calendarIdentifier) else {
            throw CalendarStoreError.calendarNotFound
        }

        // 식별자가 있어도 사용자가 그 사이 캘린더 앱에서 지웠을 수 있다. 그때는 새로 만든다.
        let event = identifier.flatMap { store.event(withIdentifier: $0) }
            ?? EKEvent(eventStore: store)
        event.calendar = calendar
        apply(draft, to: event)

        try store.save(event, span: .thisEvent, commit: true)
        guard let savedIdentifier = event.eventIdentifier else {
            throw CalendarStoreError.eventNotFound
        }
        return savedIdentifier
    }

    public func removeEvent(identifier: String) throws {
        guard let event = store.event(withIdentifier: identifier) else {
            throw CalendarStoreError.eventNotFound
        }
        try store.remove(event, span: .thisEvent, commit: true)
    }

    // MARK: - Private Function

    /// 전용 캘린더를 만들 소스. iCloud(CalDAV)가 있으면 기기 간 동기화가 되므로 우선하고,
    /// 없으면 로컬 소스로 떨어진다.
    private func preferredSource() -> EKSource? {
        let sources = store.sources
        return sources.first { $0.sourceType == .calDAV && $0.title == "iCloud" }
            ?? sources.first { $0.sourceType == .calDAV }
            ?? sources.first { $0.sourceType == .local }
            ?? store.defaultCalendarForNewEvents?.source
    }

    /// 서버 일정 값을 이벤트에 덮어쓴다. 사용자가 캘린더 앱에서 고친 값은 여기서 되돌아간다
    /// (전용 캘린더라 예상 가능한 동작).
    private func apply(_ draft: CalendarEventDraft, to event: EKEvent) {
        event.title = draft.title
        event.notes = draft.notes
        event.startDate = draft.startDate
        event.endDate = draft.endDate
        event.isAllDay = draft.isAllDay
        event.timeZone = .kst

        if let location = draft.location {
            let structuredLocation = EKStructuredLocation(title: location.locationName)
            structuredLocation.geoLocation = CLLocation(
                latitude: location.latitude,
                longitude: location.longitude
            )
            event.structuredLocation = structuredLocation
        } else {
            event.structuredLocation = nil
        }

        // 기존 알람을 먼저 비워야 재동기화마다 알람이 쌓이지 않는다.
        event.alarms?.forEach(event.removeAlarm)
        if let alarmDate = draft.alarmDate {
            event.addAlarm(EKAlarm(absoluteDate: alarmDate))
        }
    }
}
