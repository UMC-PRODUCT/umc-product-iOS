import ProjectDescription

let project = Project(
    name: "Notice",
    targets: [
        .target(
            name: "NoticeDomain",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.notice.domain",
            deploymentTargets: .iOS("26.0"),
            sources: ["Domain/Sources/**"],
            dependencies: [
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
        .target(
            name: "NoticeData",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.notice.data",
            deploymentTargets: .iOS("26.0"),
            sources: ["Data/Sources/**"],
            dependencies: [
                .target(name: "NoticeDomain"),
                .project(target: "CoreNetwork", path: .relativeToRoot("Core/Network")),
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
        .target(
            name: "NoticePresentation",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.notice.presentation",
            deploymentTargets: .iOS("26.0"),
            sources: ["Presentation/Sources/**"],
            dependencies: [
                .target(name: "NoticeDomain"),
                .project(target: "CoreDesignSystem", path: .relativeToRoot("Core/DesignSystem")),
                .project(target: "CoreUIComponents", path: .relativeToRoot("Core/UIComponents")),
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
    ]
)
