// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "projext-airpods-control",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "GestureCore", targets: ["GestureCore"]),
        .executable(name: "projext-diagnostic", targets: ["ProjextDiagnostic"])
    ],
    targets: [
        .target(name: "GestureCore"),
        .executableTarget(name: "ProjextDiagnostic", dependencies: ["GestureCore"]),
        .testTarget(name: "GestureCoreTests", dependencies: ["GestureCore"])
    ]
)
