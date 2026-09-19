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
    includesDataTests: true,
    dataTestDependencies: [
        // Router 계약 테스트가 Moya.Task 케이스를 직접 검사한다 (BusinessCard 선례).
        .external(name: "Moya"),
        .target(name: "ProjectDomain"),
        .project(target: "CoreNetwork", path: .relativeToRoot("Core/Network")),
        .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
    ]
)
