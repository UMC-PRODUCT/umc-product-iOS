//
//  CalendarSyncRepository.swift
//  HomeData
//
//  Created by euijjang97 on 9/16/26.
//

import Foundation
import HomeDomain

/// UMC 일정을 애플 캘린더의 "UMC" 전용 캘린더로 내보내는 Repository 구현체.
///
/// 전용 캘린더 하나만 쓰므로 사용자의 기본 캘린더를 건드리지 않고, 연동을 끄면 그 캘린더를
/// 통째로 지우는 것으로 정리가 끝난다.
///
/// 연동 플래그·캘린더 식별자·`[scheduleId: eventIdentifier]` 매핑은 전부 `UserDefaults` 에 둔다
/// (``ScheduleClassifierRepository`` 와 같은 정책). `eventIdentifier` 는 기기 로컬 값이라
/// CloudKit 으로 동기화되는 SwiftData 컨테이너에 넣으면 다른 기기가 엉뚱한 식별자를 참조한다.
public final class CalendarSyncRepository: CalendarSyncRepositoryProtocol, @unchecked Sendable {

    // MARK: - Property

    private let store: any CalendarEventStoring
    private let userDefaults: UserDefaults

    /// reconcile 이 겹쳐 들어와 전용 캘린더가 두 번 생기거나 매핑이 유실되는 것을 막는다.
    private let lock = NSLock()

    // MARK: - Constants

    private enum Constants {
        static let calendarTitle = "UMC"
        static let isEnabledKey = "CalendarSync.isEnabled"
        static let calendarIdentifierKey = "CalendarSync.calendarIdentifier"
        static let eventIdentifiersKey = "CalendarSync.eventIdentifiers"
    }

    // MARK: - Init

    /// 운영(DI)/테스트 공용 진입점.
    public init(
        store: any CalendarEventStoring = EventKitEventStore(),
        userDefaults: UserDefaults = .standard
    ) {
        self.store = store
        self.userDefaults = userDefaults
    }

    // MARK: - Function

    /// 기본값은 OFF — 등록되지 않은 키는 `false` 로 읽힌다.
    public var isSyncEnabled: Bool {
        userDefaults.bool(forKey: Constants.isEnabledKey)
    }

    public var authorization: CalendarSyncAuthorization {
        store.authorization
    }

    public func requestAccess() async throws -> Bool {
        try await store.requestFullAccess()
    }

    public func enableSync() {
        userDefaults.set(true, forKey: Constants.isEnabledKey)
    }

    public func disableSync() async throws {
        try lock.withLock {
            userDefaults.set(false, forKey: Constants.isEnabledKey)
            let identifier = userDefaults.string(forKey: Constants.calendarIdentifierKey)

            // 캘린더 삭제가 실패하더라도 로컬 상태는 반드시 비운다 — 남겨두면 다음 ON 에서
            // 존재하지 않을 수도 있는 식별자로 reconcile 을 시도한다.
            defer {
                userDefaults.removeObject(forKey: Constants.calendarIdentifierKey)
                saveMapping([:])
            }

            if let identifier, store.calendarExists(identifier: identifier) {
                try store.removeCalendar(identifier: identifier)
            }
        }
    }

    /// 구간 일정을 전용 캘린더에 반영한다.
    ///
    /// ① 매핑이 있고 이벤트가 살아 있으면 갱신한다.
    /// ② 매핑이 없거나 이벤트가 사라졌으면(사용자가 캘린더 앱에서 삭제) 새로 만들고 다시 매핑한다.
    /// ③ 구간 안 UMC 캘린더 이벤트 중 이번 결과에 없는 것은 삭제한다.
    ///
    /// EventKit 호출은 전부 동기라 락을 잡은 채로 끝난다. 이 메서드는 격리되어 있지 않으므로
    /// 호출자가 `@MainActor` 여도 본문은 메인 스레드 밖에서 돈다.
    public func reconcile(from: Date, to: Date, schedules: [ScheduleDetailData]) async throws {
        try lock.withLock {
            let calendarIdentifier = try ensureCalendar()
            var mapping = loadMapping()
            var writtenEventIdentifiers: Set<String> = []

            for schedule in schedules {
                let liveIdentifier = mapping[schedule.scheduleId].flatMap {
                    store.eventExists(identifier: $0) ? $0 : nil
                }
                let savedIdentifier = try store.saveEvent(
                    makeDraft(from: schedule),
                    identifier: liveIdentifier,
                    inCalendar: calendarIdentifier
                )
                mapping[schedule.scheduleId] = savedIdentifier
                writtenEventIdentifiers.insert(savedIdentifier)
            }

            let staleIdentifiers = try store.eventIdentifiers(
                inCalendar: calendarIdentifier,
                from: from,
                to: to
            ).filter { !writtenEventIdentifiers.contains($0) }

            for identifier in staleIdentifiers {
                try store.removeEvent(identifier: identifier)
            }

            let removed = Set(staleIdentifiers)
            saveMapping(mapping.filter { !removed.contains($0.value) })
        }
    }

    // MARK: - Private Function

    /// 전용 캘린더를 확보한다. 저장된 식별자가 없거나 사용자가 캘린더를 지웠으면 새로 만든다.
    private func ensureCalendar() throws -> String {
        if let identifier = userDefaults.string(forKey: Constants.calendarIdentifierKey),
           store.calendarExists(identifier: identifier) {
            return identifier
        }

        let created = try store.createCalendar(titled: Constants.calendarTitle)
        userDefaults.set(created, forKey: Constants.calendarIdentifierKey)
        // 캘린더가 새로 생겼으면 이전 캘린더를 가리키던 이벤트 매핑은 전부 무효다.
        saveMapping([:])
        return created
    }

    /// 출석 정책이 있는 일정에만 체크인 시작 시각 알람을 하나 건다. 정책이 없으면 알람 없이
    /// 캘린더 기본 알림 설정에 맡긴다.
    private func makeDraft(from schedule: ScheduleDetailData) -> CalendarEventDraft {
        CalendarEventDraft(
            title: schedule.name,
            notes: schedule.description,
            startDate: schedule.startsAt,
            endDate: schedule.endsAt,
            isAllDay: schedule.isAllDay,
            location: schedule.location,
            alarmDate: schedule.attendancePolicy?.checkInStartAt
        )
    }

    private func loadMapping() -> [String: String] {
        guard
            let data = userDefaults.data(forKey: Constants.eventIdentifiersKey),
            let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            return [:]
        }
        return decoded
    }

    private func saveMapping(_ mapping: [String: String]) {
        guard let data = try? JSONEncoder().encode(mapping) else { return }
        userDefaults.set(data, forKey: Constants.eventIdentifiersKey)
    }
}
