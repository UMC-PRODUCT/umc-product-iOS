//
//  Project.swift
//  Project
//
//  Created by euijjang97 on 9/19/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = featureProject(
    name: "Project",
    presentationExtraDependencies: [
        .project(target: "CoreDI", path: .relativeToRoot("Core/DI")),
        // 기수 선택 메뉴가 (gen, gisuId) 매핑 저장소(ChallengerGenRepositoryProtocol)를 쓴다.
        .project(target: "CoreDomain", path: .relativeToRoot("Core/Domain")),
        // 썸네일·로고 업로드 전 JPEG 변환(`UIImage.jpegDataForUpload`) (#1477).
        .project(target: "CorePhoto", path: .relativeToRoot("Core/Photo")),
        // 팀원 추가(#1477)가 Activity 챌린저 검색 UI를 그대로 쓴다.
        // ActivityDomain 은 검색 UseCase 타입 해석에 필요하다.
        // Activity 는 Project 를 참조하지 않으므로 타겟 그래프에 순환이 없다.
        .project(target: "ActivityDomain", path: .relativeToRoot("Features/Activity")),
        .project(target: "ActivityPresentation", path: .relativeToRoot("Features/Activity")),
    ],
    includesDataTests: true,
    dataTestDependencies: [
        // Router 계약 테스트가 Moya.Task 케이스를 직접 검사한다 (BusinessCard 선례).
        .external(name: "Moya"),
        .target(name: "ProjectDomain"),
        .project(target: "CoreNetwork", path: .relativeToRoot("Core/Network")),
        .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
    ],
    includesPresentationTests: true,
    presentationTestDependencies: [
        .target(name: "ProjectDomain"),
        .target(name: "ProjectData"),
        .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
    ]
)
