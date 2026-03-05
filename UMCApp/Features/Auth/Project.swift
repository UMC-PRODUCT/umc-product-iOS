import ProjectDescription

let project = Project(
    name: "Auth",
    targets: [
        .target(
            name: "AuthDomain",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.auth.domain",
            deploymentTargets: .iOS("26.0"),
            sources: ["Domain/Sources/**"],
            dependencies: [
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
        .target(
            name: "AuthData",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.auth.data",
            deploymentTargets: .iOS("26.0"),
            sources: ["Data/Sources/**"],
            dependencies: [
                .target(name: "AuthDomain"),
                .project(target: "CoreNetwork", path: .relativeToRoot("Core/Network")),
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
        .target(
            name: "AuthPresentation",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.auth.presentation",
            deploymentTargets: .iOS("26.0"),
            sources: ["Presentation/Sources/**"],
            dependencies: [
                .target(name: "AuthDomain"),
                .project(target: "CoreDesignSystem", path: .relativeToRoot("Core/DesignSystem")),
                .project(target: "CoreUIComponents", path: .relativeToRoot("Core/UIComponents")),
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
    ]
)
