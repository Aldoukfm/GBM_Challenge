// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GBMChallengeiOS",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GBMChallengeiOS",
            targets: ["GBMChallengeiOS"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        
        .package(url: "https://github.com/danielgindi/Charts.git", .upToNextMajor(from: "4.0.1")),
        .package(name: "GBMChallengeKit", path: "../GBMChallengeKit"),
        .package(name: "CombineHelpers", path: "../CombineHelpers"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .binaryTarget(name: "ConstraintHelpers", path: "./Sources/ConstraintHelpers.xcframework"),
        .target(
            name: "GBMChallengeiOS",
            dependencies: ["GBMChallengeKit", "ConstraintHelpers", "Charts", "CombineHelpers"],
            resources: [.process("Resources/TestIPCValues.json")]
        ),
        .testTarget(
            name: "GBMChallengeiOSTests",
            dependencies: ["GBMChallengeiOS"]),
    ]
)
