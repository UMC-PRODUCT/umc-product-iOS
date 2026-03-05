import ProjectDescription

let project = Project(
    name: "CoreUIComponents",
    targets: [
        .target(
            name: "CoreUIComponents",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.core.uicomponents",
            deploymentTargets: .iOS("26.0"),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "CoreDesignSystem", path: .relativeToRoot("Core/DesignSystem")),
            ]
        )
    ]
)
