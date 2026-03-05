//
//  NoticeRequestFactoryTests.swift
//  AppProductTests
//
//  Created by euijjang97 on 3/6/26.
//

import XCTest
@testable import AppProduct

final class NoticeRequestFactoryTests: XCTestCase {

    func test_iOS01_UMC공지_요청은_gisuId만_포함한다() {
        let request = NoticeRequestFactory.make(
            gisuId: 9,
            page: 0,
            selectedMainFilter: .central,
            chapterId: 11,
            schoolId: 22,
            pageSize: 20,
            sort: ["createdAt,DESC"]
        )

        let query = request.queryItems
        XCTAssertEqual(query["gisuId"] as? Int, 9)
        XCTAssertNil(query["chapterId"])
        XCTAssertNil(query["schoolId"])
        XCTAssertNil(query["part"])
    }

    func test_iOS02_학교필터_요청은_schoolId를_포함한다() {
        let request = NoticeRequestFactory.make(
            gisuId: 9,
            page: 0,
            selectedMainFilter: .school("중앙대학교"),
            chapterId: 11,
            schoolId: 22,
            pageSize: 20,
            sort: ["createdAt,DESC"]
        )

        let query = request.queryItems
        XCTAssertEqual(query["gisuId"] as? Int, 9)
        XCTAssertNil(query["chapterId"])
        XCTAssertEqual(query["schoolId"] as? Int, 22)
        XCTAssertNil(query["part"])
    }

    func test_iOS03_지부필터_요청은_chapterId를_포함한다() {
        let request = NoticeRequestFactory.make(
            gisuId: 9,
            page: 0,
            selectedMainFilter: .branch("Product"),
            chapterId: 11,
            schoolId: 22,
            pageSize: 20,
            sort: ["createdAt,DESC"]
        )

        let query = request.queryItems
        XCTAssertEqual(query["gisuId"] as? Int, 9)
        XCTAssertEqual(query["chapterId"] as? Int, 11)
        XCTAssertNil(query["schoolId"])
        XCTAssertNil(query["part"])
    }

    func test_iOS04_파트필터_요청은_part만_포함한다() {
        let request = NoticeRequestFactory.make(
            gisuId: 9,
            page: 0,
            selectedMainFilter: .part(.ios),
            chapterId: 11,
            schoolId: 22,
            pageSize: 20,
            sort: ["createdAt,DESC"]
        )

        let query = request.queryItems
        XCTAssertEqual(query["gisuId"] as? Int, 9)
        XCTAssertNil(query["chapterId"])
        XCTAssertNil(query["schoolId"])
        XCTAssertEqual(query["part"] as? String, UMCPartType.front(type: .ios).apiValue)
    }
}
