import ProjectDescription

let project = Project(
    name: "Home",
    targets: [
        .target(
            name: "HomeDomain",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.home.domain",
            deploymentTargets: .iOS("26.0"),
            sources: ["Domain/Sources/**"],
            dependencies: [
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
        .target(
            name: "HomeData",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.home.data",
            deploymentTargets: .iOS("26.0"),
            sources: ["Data/Sources/**"],
            dependencies: [
                .target(name: "HomeDomain"),
                .project(target: "CoreNetwork", path: .relativeToRoot("Core/Network")),
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
        .target(
            name: "HomePresentation",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.home.presentation",
            deploymentTargets: .iOS("26.0"),
            sources: ["Presentation/Sources/**"],
            dependencies: [
                .target(name: "HomeDomain"),
                .project(target: "CoreDesignSystem", path: .relativeToRoot("Core/DesignSystem")),
                .project(target: "CoreUIComponents", path: .relativeToRoot("Core/UIComponents")),
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
    ]
)
