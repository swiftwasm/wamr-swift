// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Tools",
    products: [
        .executable(name: "synthesize-invoke-native", targets: ["SynthesizeInvokeNative"]),
    ],
    targets: [
        .target(name: "SynthesizeInvokeNative", dependencies: []),
    ]
)
