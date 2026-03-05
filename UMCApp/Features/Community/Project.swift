import ProjectDescription

let project = Project(
    name: "Community",
    targets: [
        .target(
            name: "CommunityDomain",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.community.domain",
            deploymentTargets: .iOS("26.0"),
            sources: ["Domain/Sources/**"],
            dependencies: [
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
        .target(
            name: "CommunityData",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.community.data",
            deploymentTargets: .iOS("26.0"),
            sources: ["Data/Sources/**"],
            dependencies: [
                .target(name: "CommunityDomain"),
                .project(target: "CoreNetwork", path: .relativeToRoot("Core/Network")),
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
        .target(
            name: "CommunityPresentation",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.community.presentation",
            deploymentTargets: .iOS("26.0"),
            sources: ["Presentation/Sources/**"],
            dependencies: [
                .target(name: "CommunityDomain"),
                .project(target: "CoreDesignSystem", path: .relativeToRoot("Core/DesignSystem")),
                .project(target: "CoreUIComponents", path: .relativeToRoot("Core/UIComponents")),
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
    ]
)
