import ProjectDescription

let project = Project(
    name: "MyPage",
    targets: [
        .target(
            name: "MyPageDomain",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.mypage.domain",
            deploymentTargets: .iOS("26.0"),
            sources: ["Domain/Sources/**"],
            dependencies: [
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
        .target(
            name: "MyPageData",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.mypage.data",
            deploymentTargets: .iOS("26.0"),
            sources: ["Data/Sources/**"],
            dependencies: [
                .target(name: "MyPageDomain"),
                .project(target: "CoreNetwork", path: .relativeToRoot("Core/Network")),
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
        .target(
            name: "MyPagePresentation",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.feature.mypage.presentation",
            deploymentTargets: .iOS("26.0"),
            sources: ["Presentation/Sources/**"],
            dependencies: [
                .target(name: "MyPageDomain"),
                .project(target: "CoreDesignSystem", path: .relativeToRoot("Core/DesignSystem")),
                .project(target: "CoreUIComponents", path: .relativeToRoot("Core/UIComponents")),
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        ),
    ]
)
