import ProjectDescription

let project = Project(
    name: "Activity",
    targets: [
        .target(
            name: "ActivityDomain",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.activity.domain",
            deploymentTargets: .iOS("26.0"),
            sources: ["Domain/Sources/**"],
            dependencies: [
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
        .target(
            name: "ActivityData",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.activity.data",
            deploymentTargets: .iOS("26.0"),
            sources: ["Data/Sources/**"],
            dependencies: [
                .target(name: "ActivityDomain"),
                .project(target: "CoreNetwork", path: .relativeToRoot("Core/Network")),
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
        .target(
            name: "ActivityPresentation",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.activity.presentation",
            deploymentTargets: .iOS("26.0"),
            sources: ["Presentation/Sources/**"],
            dependencies: [
                .target(name: "ActivityDomain"),
                .project(target: "CoreDesignSystem", path: .relativeToRoot("Core/DesignSystem")),
                .project(target: "CoreUIComponents", path: .relativeToRoot("Core/UIComponents")),
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
    ]
)
