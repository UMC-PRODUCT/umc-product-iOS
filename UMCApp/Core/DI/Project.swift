import ProjectDescription

let project = Project(
    name: "CoreDI",
    targets: [
        .target(
            name: "CoreDI",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.umc.core.di",
            deploymentTargets: .iOS("26.0"),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "UMCFoundation", path: .relativeToRoot("Core/Foundation")),
            ]
        )
    ]
)
