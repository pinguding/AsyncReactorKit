// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncReactor",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .macCatalyst(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AsyncReactor",
            targets: ["AsyncReactor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pinguding/DynamicTypeDictionary.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AsyncReactor",
            dependencies: [
                .product(name: "DynamicTypeDictionary", package: "dynamictypedictionary")
            ]
        ),

        .testTarget(
            name: "AsyncReactorTests",
            dependencies: ["AsyncReactor"]
        ),
    ]
)
