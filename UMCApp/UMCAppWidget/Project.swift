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
    // 호스트 앱과 같은 iPhone 전용 (`UMCApp/Project.swift` 참조).
    destinations: [.iPhone],
    entitlements: .file(path: "UMCAppWidget.entitlements"),
    dependencies: [
        .project(target: "CoreWidgetShared", path: .relativeToRoot("Core/WidgetShared")),
    ]
)
