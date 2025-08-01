// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "freewrite",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.10.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples", from: "1.15.2"),
        .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.0")
    ],
    targets: [
        .target(
            name: "freewrite",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXOptimizers", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-examples"),
                .product(name: "MLXLMCommon", package: "mlx-swift-examples"),
                .product(name: "Tokenizers", package: "mlx-swift-examples"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ]
        )
    ]
)