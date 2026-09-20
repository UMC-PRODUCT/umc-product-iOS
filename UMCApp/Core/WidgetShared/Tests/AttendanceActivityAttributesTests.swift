//
//  AttendanceActivityAttributesTests.swift
//  CoreWidgetSharedTests
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import Testing
@testable import CoreWidgetShared

@Suite("AttendanceActivityAttributes")
struct AttendanceActivityAttributesTests {

    // MARK: - Property

    private let start = Date(timeIntervalSince1970: 1_000)
    private var attributes: AttendanceActivityAttributes {
        AttendanceActivityAttributes(
            scheduleId: "42",
            title: "정기 세션",
            checkInStartAt: start,
            onTimeEndAt: start.addingTimeInterval(600),
            lateEndAt: start.addingTimeInterval(1_200)
        )
    }

    // MARK: - Phase

    @Test("경계 시각은 출석 화면 판정과 같이 앞 단계에 포함된다")
    func phaseBoundaries() {
        #expect(attributes.phase(at: start.addingTimeInterval(-1)) == .beforeCheckIn)
        #expect(attributes.phase(at: start) == .onTime)
        #expect(attributes.phase(at: start.addingTimeInterval(600)) == .onTime)
        #expect(attributes.phase(at: start.addingTimeInterval(601)) == .late)
        #expect(attributes.phase(at: start.addingTimeInterval(1_200)) == .late)
        #expect(attributes.phase(at: start.addingTimeInterval(1_201)) == .closed)
    }

    @Test("단계 종료 시각이 staleDate 로 쓰이고, 다음 단계가 이어진다")
    func endDateAndNextPhase() {
        #expect(attributes.endDate(of: .onTime) == start.addingTimeInterval(600))
        #expect(attributes.endDate(of: .late) == start.addingTimeInterval(1_200))
        #expect(attributes.endDate(of: .closed) == nil)
        #expect(AttendanceActivityPhase.onTime.next == .late)
        #expect(AttendanceActivityPhase.late.next == .closed)
        #expect(AttendanceActivityPhase.closed.next == .closed)
    }

    @Test("ContentState 는 JSON 객체로 인코딩된다 (APNs content-state 호환)")
    func contentStateEncodesAsObject() throws {
        let state = AttendanceActivityAttributes.ContentState(phase: .late)
        let data = try JSONEncoder().encode(state)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: String]
        #expect(object == ["phase": "late"])
    }
}
