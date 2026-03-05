import ProjectDescription

let project = Project(
    name: "UMCFoundation",
    targets: [
        .target(
            name: "UMCFoundation",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.core.foundation",
            deploymentTargets: .iOS("26.0"),
            sources: ["Sources/**"]
        )
    ]
)
