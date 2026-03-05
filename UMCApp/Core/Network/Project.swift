import ProjectDescription

let project = Project(
    name: "CoreNetwork",
    targets: [
        .target(
            name: "CoreNetwork",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.core.network",
            deploymentTargets: .iOS("26.0"),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        )
    ]
)
