//
//  Project.swift
//  CoreWidgetShared
//
//  Created by euijjang97 on 4/23/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = coreProject(
    name: "CoreWidgetShared",
    bundleIdSuffix: "widgetshared",
    dependencies: [
        .sdk(name: "WidgetKit", type: .framework, status: .required),
    ]
)
