//
//  CurriculumDTOTests.swift
//  ActivityDataTests
//
//  Created by jaewon Lee on 6/7/26.
//

import Foundation
import Testing
import ActivityDomain
import UMCFoundation
@testable import ActivityData

private enum FixedTime {

    static let week1StartISO = "2026-06-01T00:00:00Z"
    static let week1EndISO = "2026-06-07T00:00:00Z"
    static let week2StartISO = "2026-06-08T00:00:00Z"
    static let week2EndISO = "2026-06-14T00:00:00Z"
}

// MARK: - Helpers

private func decodeCurriculum(_ json: String) throws -> CurriculumDTO {
    try JSONDecoder().decode(CurriculumDTO.self, from: Data(json.utf8))
}

private func makeWeekJSON(
    startsAt: String,
    endsAt: String,
    weeklyCurriculumId: String = "\"5001\"",
    weekNo: String = "1",
    title: String = "\"1주차: Swift 기초\"",
    isExtra: String = "false"
) -> String {
    """
    {
        "weeklyCurriculumId": \(weeklyCurriculumId),
        "weekNo": \(weekNo),
        "title": \(title),
        "startsAt": "\(startsAt)",
        "endsAt": "\(endsAt)",
        "isExtra": \(isExtra)
    }
    """
}

private func makeCurriculumJSON(
    curriculumId: String = "\"900\"",
    title: String = "\"iOS 커리큘럼\"",
    weeks: [String]
) -> String {
    """
    {
        "curriculumId": \(curriculumId),
        "title": \(title),
        "weeks": [\(weeks.joined(separator: ","))]
    }
    """
}

@Suite("CurriculumDTO — 디코딩/매핑")
struct CurriculumDTOTests {

    // MARK: - Decoding (happy path)

    @Test("커리큘럼 전체 JSON 의 필드와 주차 목록을 디코딩한다")
    func decodesFullCurriculumJSON() throws {
        let json = makeCurriculumJSON(weeks: [
            makeWeekJSON(startsAt: FixedTime.week1StartISO, endsAt: FixedTime.week1EndISO),
            makeWeekJSON(
                startsAt: FixedTime.week2StartISO,
                endsAt: FixedTime.week2EndISO,
                weeklyCurriculumId: "\"5002\"",
                weekNo: "2"
            )
        ])
        let dto = try decodeCurriculum(json)

        #expect(dto.curriculumId == "900")
        #expect(dto.title == "iOS 커리큘럼")
        #expect(dto.weeks.count == 2)
        #expect(dto.weeks.first?.weeklyCurriculumId == "5001")
        #expect(dto.weeks.first?.weekNo == "1")
    }

    @Test("curriculumId 가 JSON 숫자로 와도 String 으로 디코딩한다")
    func decodesCurriculumIdAsNumber() throws {
        let json = makeCurriculumJSON(curriculumId: "900", weeks: [])
        #expect(try decodeCurriculum(json).curriculumId == "900")
    }

    @Test("weekNo 가 숫자 String 으로 와도 String 으로 디코딩한다")
    func decodesWeekNoAsString() throws {
        let json = makeCurriculumJSON(weeks: [
            makeWeekJSON(startsAt: FixedTime.week1StartISO, endsAt: FixedTime.week1EndISO, weekNo: "\"3\"")
        ])
        #expect(try decodeCurriculum(json).weeks.first?.weekNo == "3")
    }

    @Test("isExtra 가 String/Int 등 다양한 형태로 와도 Bool 로 디코딩한다")
    func decodesIsExtraFlexibly() throws {
        let json = makeCurriculumJSON(weeks: [
            makeWeekJSON(startsAt: FixedTime.week1StartISO, endsAt: FixedTime.week1EndISO, isExtra: "\"true\"")
        ])
        #expect(try decodeCurriculum(json).weeks.first?.isExtra == true)
    }

    @Test("필드가 없으면 기본값으로 디코딩한다")
    func decodesWithDefaults() throws {
        let dto = try decodeCurriculum("{}")
        #expect(dto.curriculumId == "")
        #expect(dto.title == "")
        #expect(dto.weeks.isEmpty)
    }

    @Test("주차 JSON 에 필드가 없으면 기본값으로 디코딩한다")
    func decodesWeekWithDefaults() throws {
        let json = makeCurriculumJSON(weeks: ["{}"])
        let week = try #require(try decodeCurriculum(json).weeks.first)

        #expect(week.weeklyCurriculumId == "")
        #expect(week.weekNo == "0")
        #expect(week.title == "")
        #expect(week.startsAt == "")
        #expect(week.endsAt == "")
        #expect(week.isExtra == false)
    }

    @Test("custom encode 후 다시 디코딩하면 동일한 DTO 가 복원된다")
    func encodeRoundTrip() throws {
        let json = makeCurriculumJSON(weeks: [
            makeWeekJSON(startsAt: FixedTime.week1StartISO, endsAt: FixedTime.week1EndISO)
        ])
        let original = try decodeCurriculum(json)
        let restored = try JSONDecoder().decode(
            CurriculumDTO.self,
            from: JSONEncoder().encode(original)
        )
        #expect(restored == original)
    }

    // MARK: - toCurriculumHeader

    @Test("toCurriculumHeader — partType/partName 은 part 인자로부터 매핑된다")
    func headerMapsPart() throws {
        let json = makeCurriculumJSON(weeks: [
            makeWeekJSON(startsAt: FixedTime.week1StartISO, endsAt: FixedTime.week1EndISO),
            makeWeekJSON(
                startsAt: FixedTime.week2StartISO,
                endsAt: FixedTime.week2EndISO,
                weekNo: "2"
            )
        ])
        let header = try decodeCurriculum(json)
            .toCurriculumHeader(part: "IOS")

        #expect(header.partType == .front(type: .ios))
        #expect(header.partName == "iOS PART CURRICULUM")
    }

    @Test("toCurriculumHeader — 알 수 없는 part 는 partType nil, partName 에 원본 문자열을 쓴다")
    func headerUnknownPartFallback() throws {
        let json = makeCurriculumJSON(weeks: [])
        let header = try decodeCurriculum(json)
            .toCurriculumHeader(part: "QUANTUM")

        #expect(header.partType == nil)
        #expect(header.partName == "QUANTUM PART CURRICULUM")
    }

    @Test("toCurriculumHeader — 주차 날짜와 제목 대신 서버 커리큘럼 제목을 보존한다")
    func headerPreservesCurriculumTitle() throws {
        let json = makeCurriculumJSON(weeks: [
            makeWeekJSON(
                startsAt: FixedTime.week1StartISO,
                endsAt: FixedTime.week1EndISO,
                title: "\"진행 중 주차\""
            )
        ])
        let header = try decodeCurriculum(json)
            .toCurriculumHeader(part: "IOS")
        #expect(header.curriculumTitle == "iOS 커리큘럼")
    }

    // MARK: - toMissionCards

    @Test("toMissionCards — 주차를 week 오름차순으로 정렬해 카드로 변환한다")
    func missionCardsSortedByWeek() throws {
        let json = makeCurriculumJSON(weeks: [
            makeWeekJSON(startsAt: "bad", endsAt: "bad", weekNo: "\"10\""),
            makeWeekJSON(
                startsAt: FixedTime.week2StartISO,
                endsAt: FixedTime.week2EndISO,
                weekNo: "2"
            ),
            makeWeekJSON(
                startsAt: FixedTime.week1StartISO,
                endsAt: FixedTime.week1EndISO,
                weekNo: "1"
            )
        ])
        let cards = try decodeCurriculum(json)
            .toMissionCards(platform: "iOS")

        #expect(cards.map(\.week) == ["1", "2", "10"])
    }

    @Test("toMissionCards — platform/missionTitle/isExtra 가 매핑된다")
    func missionCardsMapFields() throws {
        let json = makeCurriculumJSON(weeks: [
            makeWeekJSON(
                startsAt: FixedTime.week1StartISO,
                endsAt: FixedTime.week1EndISO,
                title: "\"1주차 미션\"",
                isExtra: "true"
            )
        ])
        let card = try #require(
            try decodeCurriculum(json)
                .toMissionCards(platform: "iOS").first
        )

        #expect(card.platform == "iOS")
        #expect(card.title == "1주차 미션")
        #expect(card.missionTitle == "1주차 미션")
        #expect(card.isExtra == true)
    }

    @Test("toMissionCards — 과거·미래·유효하지 않은 날짜의 주차도 모두 내용으로 매핑한다")
    func missionCardsKeepAllWeeksRegardlessOfDates() throws {
        let json = makeCurriculumJSON(weeks: [
            makeWeekJSON(startsAt: "2020-01-01T00:00:00Z", endsAt: "2020-01-07T00:00:00Z"),
            makeWeekJSON(
                startsAt: "2099-01-01T00:00:00Z",
                endsAt: "2099-01-07T00:00:00Z",
                weekNo: "2"
            ),
            makeWeekJSON(startsAt: "bad", endsAt: "bad", weekNo: "10")
        ])
        let cards = try decodeCurriculum(json).toMissionCards(platform: "iOS")

        #expect(cards.map(\.week) == ["1", "2", "10"])
        #expect(cards.allSatisfy { $0.missionTitle == "1주차: Swift 기초" })
    }

    @Test("toMissionCards — 빈 주차 목록이면 빈 카드 배열을 반환한다")
    func missionCardsEmptyWhenNoWeeks() throws {
        let json = makeCurriculumJSON(weeks: [])
        let cards = try decodeCurriculum(json)
            .toMissionCards(platform: "iOS")
        #expect(cards.isEmpty)
    }
}
