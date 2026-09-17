//
//  Project.swift
//  Maintenance
//
//  Created by euijjang97 on 7/10/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = featureProject(
    name: "Maintenance",
    presentationExtraDependencies: [
        // `MaintenanceViewModel`이 다른 Presentation ViewModel과 동일하게
        // `container: DIContainer`를 주입받는다.
        .project(target: "CoreDI", path: .relativeToRoot("Core/DI")),
    ],
    includesDomainTests: true,
    includesDataTests: true,
    includesPresentationTests: true,
    presentationTestDependencies: [
        .project(target: "CoreDI", path: .relativeToRoot("Core/DI")),
    ]
)
