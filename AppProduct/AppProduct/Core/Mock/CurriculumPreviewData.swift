//
//  CurriculumPreviewData.swift
//  AppProduct
//
//  Created by jaewon Lee on 02/01/26.
//

import Foundation

#if DEBUG
struct CurriculumPreviewData {

    // MARK: - Single Curriculum

    static let singleCurriculum = CurriculumProgressModel(
        partName: "WEB PART CURRICULUM",
        curriculumTitle: "웹 프론트엔드 기초",
        completedCount: 2,
        totalCount: 8
    )

    // MARK: - Platform-specific Curriculums

    static let iosCurriculum = CurriculumProgressModel(
        partName: "iOS PART CURRICULUM",
        curriculumTitle: "Swift 기초 문법",
        completedCount: 5,
        totalCount: 10
    )

    static let androidCurriculum = CurriculumProgressModel(
        partName: "ANDROID PART CURRICULUM",
        curriculumTitle: "Kotlin 입문",
        completedCount: 3,
        totalCount: 8
    )

    static let webCurriculum = CurriculumProgressModel(
        partName: "WEB PART CURRICULUM",
        curriculumTitle: "웹 프론트엔드 기초",
        completedCount: 2,
        totalCount: 8
    )

    static let serverCurriculum = CurriculumProgressModel(
        partName: "SERVER PART CURRICULUM",
        curriculumTitle: "Spring Boot 입문",
        completedCount: 7,
        totalCount: 10
    )

    static let designCurriculum = CurriculumProgressModel(
        partName: "DESIGN PART CURRICULUM",
        curriculumTitle: "UI/UX 디자인 기초",
        completedCount: 4,
        totalCount: 6
    )

    static let pmCurriculum = CurriculumProgressModel(
        partName: "PM PART CURRICULUM",
        curriculumTitle: "프로덕트 매니지먼트 입문",
        completedCount: 1,
        totalCount: 5
    )

    // MARK: - Progress Variations

    /// 다양한 진행률 상태
    static let allProgressStates: [CurriculumProgressModel] = [
        .init(
            partName: "iOS PART CURRICULUM",
            curriculumTitle: "Swift 기초 문법",
            completedCount: 10,
            totalCount: 10
        ),
        .init(
            partName: "ANDROID PART CURRICULUM",
            curriculumTitle: "Kotlin 입문",
            completedCount: 5,
            totalCount: 8
        ),
        .init(
            partName: "WEB PART CURRICULUM",
            curriculumTitle: "웹 프론트엔드 기초",
            completedCount: 2,
            totalCount: 8
        ),
        .init(
            partName: "SERVER PART CURRICULUM",
            curriculumTitle: "Spring Boot 입문",
            completedCount: 0,
            totalCount: 10
        )
    ]

    // MARK: - All Platforms

    static let allPlatforms: [CurriculumProgressModel] = [
        iosCurriculum,
        androidCurriculum,
        webCurriculum,
        serverCurriculum,
        designCurriculum,
        pmCurriculum
    ]
}
#endif
