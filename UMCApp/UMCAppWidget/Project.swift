//
//  Project.swift
//  UMCAppWidget
//
//  Created by euijjang97 on 4/23/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = widgetExtensionProject(
    name: "UMCAppWidget",
    bundleId: "com.umc.product.widget",
    entitlements: .file(path: "UMCAppWidget.entitlements"),
    dependencies: [
        .project(target: "CoreWidgetShared", path: .relativeToRoot("Core/WidgetShared")),
    ]
)
