//
//  CalendarSyncRepositoryTests.swift
//  HomeDataTests
//
//  Created by euijjang97 on 9/16/26.
//
//  fake `CalendarEventStoring` 으로 reconcile 규칙을 검증한다 — 신규 생성, 기존 갱신,
//  서버 삭제분 제거, 매핑 유실 시 재생성, 재동기화 멱등성, 그리고 UseCase 의 참여 일정 필터.
//  `UserDefaults.standard` 를 오염시키지 않도록 매 테스트마다 임시 suite 를 만들어 쓴다.
//

import Foundation
import HomeDomain
import Testing
import UMCFoundation
@testable import HomeData

@Suite("CalendarSyncRepository — 전용 캘린더 reconcile 검증")
struct CalendarSyncRepositoryTests {

    // MARK: - ① 신규 생성

    @Test("첫 동기화는 UMC 전용 캘린더를 만들고 일정마다 이벤트를 생성한다")
    func createsCalendarAndEventsOnFirstSync() async throws {
        try await withEphemeralUserDefaults { userDefaults in
            let store = FakeCalendarEventStore()
            let repository = CalendarSyncRepository(store: store, userDefaults: userDefaults)

            try await repository.reconcile(
                from: monthStart,
                to: monthEnd,
                schedules: [makeSchedule(id: "1"), makeSchedule(id: "2")]
            )

            #expect(store.createdCalendarTitles == ["UMC"])
            #expect(store.events.count == 2)
            #expect(store.savedEventCount == 2)
        }
    }

    @Test("장소가 있으면 이벤트에 그대로 싣고, 출석 정책이 있으면 체크인 시작 시각 알람을 단다")
    func mapsLocationAndAttendanceAlarm() async throws {
        try await withEphemeralUserDefaults { userDefaults in
            let store = FakeCalendarEventStore()
            let repository = CalendarSyncRepository(store: store, userDefaults: userDefaults)
            let checkInStartAt = monthStart.addingTimeInterval(3600)

            try await repository.reconcile(
                from: monthStart,
                to: monthEnd,
                schedules: [
                    makeSchedule(
                        id: "offline",
                        location: ScheduleLocation(
                            latitude: 37.5,
                            longitude: 127.0,
                            locationName: "UMC 라운지"
                        ),
                        attendancePolicy: ScheduleAttendancePolicy(
                            checkInStartAt: checkInStartAt,
                            onTimeEndAt: checkInStartAt.addingTimeInterval(600),
                            lateEndAt: checkInStartAt.addingTimeInterval(1200)
                        )
                    ),
                    makeSchedule(id: "online"),
                ]
            )

            let offline = try #require(store.draft(forTitle: "일정 offline"))
            #expect(offline.location?.locationName == "UMC 라운지")
            #expect(offline.alarmDate == checkInStartAt)

            let online = try #require(store.draft(forTitle: "일정 online"))
            #expect(online.location == nil)
            #expect(online.alarmDate == nil)
        }
    }

    // MARK: - ② 기존 갱신

    @Test("서버에서 제목이 바뀌면 같은 이벤트를 갱신한다 (새로 만들지 않는다)")
    func updatesExistingEventInPlace() async throws {
        try await withEphemeralUserDefaults { userDefaults in
            let store = FakeCalendarEventStore()
            let repository = CalendarSyncRepository(store: store, userDefaults: userDefaults)

            try await repository.reconcile(
                from: monthStart,
                to: monthEnd,
                schedules: [makeSchedule(id: "1", name: "스터디")]
            )
            let originalIdentifier = try #require(store.events.keys.first)

            try await repository.reconcile(
                from: monthStart,
                to: monthEnd,
                schedules: [makeSchedule(id: "1", name: "스터디(장소 변경)")]
            )

            #expect(store.events.count == 1)
            #expect(store.events.keys.first == originalIdentifier)
            #expect(store.events[originalIdentifier]?.draft.title == "스터디(장소 변경)")
        }
    }

    // MARK: - ③ 서버 삭제분 제거

    @Test("서버 결과에서 사라진 일정의 이벤트는 구간에서 삭제된다")
    func removesEventsMissingFromServerResult() async throws {
        try await withEphemeralUserDefaults { userDefaults in
            let store = FakeCalendarEventStore()
            let repository = CalendarSyncRepository(store: store, userDefaults: userDefaults)

            try await repository.reconcile(
                from: monthStart,
                to: monthEnd,
                schedules: [makeSchedule(id: "1"), makeSchedule(id: "2")]
            )
            #expect(store.events.count == 2)

            try await repository.reconcile(
                from: monthStart,
                to: monthEnd,
                schedules: [makeSchedule(id: "1")]
            )

            #expect(store.events.count == 1)
            #expect(store.draft(forTitle: "일정 1") != nil)
        }
    }

    // MARK: - ④ 매핑 유실 시 재생성

    @Test("사용자가 캘린더 앱에서 이벤트를 지우면 다음 동기화가 다시 만들고 매핑을 갱신한다")
    func recreatesEventWhenUserDeletedIt() async throws {
        try await withEphemeralUserDefaults { userDefaults in
            let store = FakeCalendarEventStore()
            let repository = CalendarSyncRepository(store: store, userDefaults: userDefaults)

            try await repository.reconcile(
                from: monthStart,
                to: monthEnd,
                schedules: [makeSchedule(id: "1")]
            )
            let deletedIdentifier = try #require(store.events.keys.first)
            store.simulateUserDeletion(identifier: deletedIdentifier)

            try await repository.reconcile(
                from: monthStart,
                to: monthEnd,
                schedules: [makeSchedule(id: "1")]
            )

            #expect(store.events.count == 1)
            let recreatedIdentifier = try #require(store.events.keys.first)
            #expect(recreatedIdentifier != deletedIdentifier)

            // 매핑이 새 식별자를 가리켜야 세 번째 동기화가 또 만들지 않는다.
            try await repository.reconcile(
                from: monthStart,
                to: monthEnd,
                schedules: [makeSchedule(id: "1")]
            )
            #expect(store.events.count == 1)
            #expect(store.events.keys.first == recreatedIdentifier)
        }
    }

    // MARK: - ⑤ 재동기화 멱등성

    @Test("같은 달을 세 번 동기화해도 이벤트 수와 캘린더 수가 변하지 않는다")
    func repeatedSyncIsIdempotent() async throws {
        try await withEphemeralUserDefaults { userDefaults in
            let store = FakeCalendarEventStore()
            let repository = CalendarSyncRepository(store: store, userDefaults: userDefaults)
            let schedules = [makeSchedule(id: "1"), makeSchedule(id: "2"), makeSchedule(id: "3")]

            for _ in 0..<3 {
                try await repository.reconcile(
                    from: monthStart,
                    to: monthEnd,
                    schedules: schedules
                )
            }

            #expect(store.events.count == 3)
            #expect(store.createdCalendarTitles == ["UMC"])
        }
    }

    // MARK: - ⑥ 참여 일정 필터

    @Test("UseCase는 isParticipant == false 인 일정을 내보내지 않는다")
    func excludesNonParticipantSchedules() async throws {
        try await withEphemeralUserDefaults { userDefaults in
            let store = FakeCalendarEventStore()
            let repository = CalendarSyncRepository(store: store, userDefaults: userDefaults)
            repository.enableSync()
            let useCase = SyncSchedulesToCalendarUseCase(repository: repository)

            try await useCase.execute(
                from: monthStart,
                to: monthEnd,
                schedules: [
                    makeSchedule(id: "참여", isParticipant: true),
                    makeSchedule(id: "미참여", isParticipant: false),
                ]
            )

            #expect(store.events.count == 1)
            #expect(store.draft(forTitle: "일정 참여") != nil)
            #expect(store.draft(forTitle: "일정 미참여") == nil)
        }
    }

    @Test("연동이 꺼져 있으면 UseCase가 저장소를 건드리지 않는다")
    func skipsSyncWhenDisabled() async throws {
        try await withEphemeralUserDefaults { userDefaults in
            let store = FakeCalendarEventStore()
            let repository = CalendarSyncRepository(store: store, userDefaults: userDefaults)
            let useCase = SyncSchedulesToCalendarUseCase(repository: repository)

            try await useCase.execute(
                from: monthStart,
                to: monthEnd,
                schedules: [makeSchedule(id: "1")]
            )

            #expect(store.createdCalendarTitles.isEmpty)
            #expect(store.events.isEmpty)
        }
    }

    // MARK: - 연동 해제

    @Test("연동을 끄면 UMC 캘린더와 매핑이 사라지고, 다시 켜면 캘린더를 새로 만든다")
    func disableSyncRemovesCalendarAndMapping() async throws {
        try await withEphemeralUserDefaults { userDefaults in
            let store = FakeCalendarEventStore()
            let repository = CalendarSyncRepository(store: store, userDefaults: userDefaults)
            repository.enableSync()

            try await repository.reconcile(
                from: monthStart,
                to: monthEnd,
                schedules: [makeSchedule(id: "1")]
            )
            try await repository.disableSync()

            #expect(repository.isSyncEnabled == false)
            #expect(store.events.isEmpty)
            #expect(store.liveCalendarIdentifiers.isEmpty)

            try await repository.reconcile(
                from: monthStart,
                to: monthEnd,
                schedules: [makeSchedule(id: "1")]
            )

            #expect(store.createdCalendarTitles == ["UMC", "UMC"])
            #expect(store.events.count == 1)
        }
    }
}

// MARK: - Fixture

/// 테스트가 쓰는 고정 구간 (2026년 9월, KST).
private let monthStart: Date = {
    Calendar.kstGregorian.date(from: DateComponents(year: 2026, month: 9, day: 1))!.kstStartOfDay
}()

private let monthEnd: Date = {
    Calendar.kstGregorian.date(from: DateComponents(year: 2026, month: 9, day: 30))!.kstEndOfDay
}()

private func makeSchedule(
    id: String,
    name: String? = nil,
    isParticipant: Bool = true,
    location: ScheduleLocation? = nil,
    attendancePolicy: ScheduleAttendancePolicy? = nil
) -> ScheduleDetailData {
    let startsAt = monthStart.addingTimeInterval(9 * 3600)
    return ScheduleDetailData(
        scheduleId: id,
        name: name ?? "일정 \(id)",
        description: "설명 \(id)",
        tags: [],
        startsAt: startsAt,
        endsAt: startsAt.addingTimeInterval(3600),
        isParticipant: isParticipant,
        location: location,
        attendancePolicy: attendancePolicy
    )
}

/// 임시 `UserDefaults` suite를 생성해 `body`에 전달하고, 종료 시 영구 도메인을 제거한다.
private func withEphemeralUserDefaults(
    _ body: (UserDefaults) async throws -> Void
) async rethrows {
    let suiteName = "CalendarSyncRepositoryTests.\(UUID().uuidString)"
    let userDefaults = UserDefaults(suiteName: suiteName)!
    defer { userDefaults.removePersistentDomain(forName: suiteName) }
    try await body(userDefaults)
}

// MARK: - Fake

/// 인메모리 ``CalendarEventStoring``. EventKit 없이 reconcile 규칙만 검증한다.
private final class FakeCalendarEventStore: CalendarEventStoring, @unchecked Sendable {

    // MARK: - Property

    var authorization: CalendarSyncAuthorization = .authorized
    var requestFullAccessResult = true

    private(set) var createdCalendarTitles: [String] = []
    private(set) var liveCalendarIdentifiers: Set<String> = []
    private(set) var events: [String: (draft: CalendarEventDraft, calendarIdentifier: String)] = [:]
    private(set) var savedEventCount = 0

    private var nextIdentifier = 0

    // MARK: - Function

    func requestFullAccess() async throws -> Bool {
        requestFullAccessResult
    }

    func createCalendar(titled title: String) throws -> String {
        createdCalendarTitles.append(title)
        let identifier = makeIdentifier(prefix: "calendar")
        liveCalendarIdentifiers.insert(identifier)
        return identifier
    }

    func calendarExists(identifier: String) -> Bool {
        liveCalendarIdentifiers.contains(identifier)
    }

    func removeCalendar(identifier: String) throws {
        guard liveCalendarIdentifiers.remove(identifier) != nil else {
            throw CalendarStoreError.calendarNotFound
        }
        events = events.filter { $0.value.calendarIdentifier != identifier }
    }

    func eventExists(identifier: String) -> Bool {
        events[identifier] != nil
    }

    func eventIdentifiers(
        inCalendar calendarIdentifier: String,
        from: Date,
        to: Date
    ) throws -> [String] {
        guard calendarExists(identifier: calendarIdentifier) else {
            throw CalendarStoreError.calendarNotFound
        }
        return events
            .filter { _, value in
                value.calendarIdentifier == calendarIdentifier
                    && value.draft.startDate <= to
                    && value.draft.endDate >= from
            }
            .map(\.key)
    }

    func saveEvent(
        _ draft: CalendarEventDraft,
        identifier: String?,
        inCalendar calendarIdentifier: String
    ) throws -> String {
        guard calendarExists(identifier: calendarIdentifier) else {
            throw CalendarStoreError.calendarNotFound
        }
        savedEventCount += 1

        // 실제 EventKit 어댑터와 같은 규칙 — 식별자가 있어도 이벤트가 사라졌으면 새로 만든다.
        let resolvedIdentifier = identifier.flatMap { events[$0] != nil ? $0 : nil }
            ?? makeIdentifier(prefix: "event")
        events[resolvedIdentifier] = (draft, calendarIdentifier)
        return resolvedIdentifier
    }

    func removeEvent(identifier: String) throws {
        guard events.removeValue(forKey: identifier) != nil else {
            throw CalendarStoreError.eventNotFound
        }
    }

    // MARK: - Test Helper

    /// 사용자가 캘린더 앱에서 이벤트를 직접 지운 상황.
    func simulateUserDeletion(identifier: String) {
        events.removeValue(forKey: identifier)
    }

    func draft(forTitle title: String) -> CalendarEventDraft? {
        events.values.first { $0.draft.title == title }?.draft
    }

    // MARK: - Private Function

    private func makeIdentifier(prefix: String) -> String {
        nextIdentifier += 1
        return "\(prefix)-\(nextIdentifier)"
    }
}
