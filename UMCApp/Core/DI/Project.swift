//
//  Project.swift
//  CoreDI
//
//  Created by euijjang97 on 3/6/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = coreProject(
    name: "CoreDI",
    bundleIdSuffix: "di",
    dependencies: [
        .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
        .project(target: "CoreNetwork", path:
            .relativeToRoot("Core/Network")),
    ],
    includesTests: true
)
