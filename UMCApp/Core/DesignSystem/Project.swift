import ProjectDescription

let project = Project(
    name: "CoreDesignSystem",
    targets: [
        .target(
            name: "CoreDesignSystem",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.core.designsystem",
            deploymentTargets: .iOS("26.0"),
            sources: ["Sources/**"]
        )
    ]
)
