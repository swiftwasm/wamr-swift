// swift-tools-version:5.3

import PackageDescription
import Foundation

let wamrSource = "third-party/wasm-micro-runtime"

var wamrTargets: [Target] = []

let wamrPlatforms = ["linux", "darwin"]

let macroDefinitions = [
    "BH_MALLOC": "wasm_runtime_malloc",
    "BH_FREE": "wasm_runtime_free",
    "WASM_ENABLE_FAST_INTERP": "1",
    "WASM_ENABLE_INTERP": "1",
    "WASM_ENABLE_LIBC_WASI": "1",
    "WASM_ENABLE_LIBC_BUILTIN": "1",
]
.map { CSetting.define($0.key, to: $0.value) } + [
    .define("BH_PLATFORM_DARWIN", to: "1", .when(platforms: [.macOS, .iOS, .tvOS, .watchOS])),
    .define("BH_PLATFORM_LINUX", to: "1", .when(platforms: [.linux])),
]

let iwasmCommonArchSpecificAsms = {
    try! FileManager.default.contentsOfDirectory(atPath: "\(wamrSource)/core/iwasm/common/arch").filter {
        $0.hasSuffix(".s") || $0.hasSuffix(".asm")
    }
    .map { "wamr/core/iwasm/common/arch/\($0.split(separator: "/").last!)" }
}()

func wamrCorePlatforms(except: String) -> [String] {
    try! FileManager.default.contentsOfDirectory(atPath: "\(wamrSource)/core/shared/platform/").filter {
        $0 != except && $0 != "common"
    }
    .map { "wamr/core/shared/platform/\($0.split(separator: "/").last!)" }
}

func wamrCoreTarget(platform: String) -> Target {
    .target(
        name: "wamr-core-\(platform)",
        dependencies: [
        ],
        exclude: iwasmCommonArchSpecificAsms + wamrCorePlatforms(except: platform) + [
            "wamr/test-tools",
            "wamr/product-mini",
            "wamr/samples",
            "wamr/assembly-script",
            "wamr/doc",
            "wamr/CONTRIBUTING.md",
            "wamr/SECURITY.md",
            "wamr/LICENSE",
            "wamr/CODE_OF_CONDUCT.md",
            "wamr/ATTRIBUTIONS.md",
            "wamr/README.md",
            "wamr/ORG_CODE_OF_CONDUCT.md",
            "wamr/Dockerfile",
            "wamr/wamr-compiler",
            "wamr/build-scripts",
            "wamr/wamr-sdk",
            "wamr/core/app-framework",
            "wamr/core/app-mgr",
            "wamr/core/deps",
            "wamr/core/iwasm/README.md",
            "wamr/core/iwasm/aot",
            "wamr/core/iwasm/common/iwasm_common.cmake",
            "wamr/core/iwasm/compilation",
            "wamr/core/iwasm/interpreter/iwasm_interp.cmake",
            "wamr/core/iwasm/interpreter/wasm_interp_classic.c",
            "wamr/core/iwasm/interpreter/wasm_mini_loader.c",
            "wamr/core/iwasm/libraries/lib-pthread",
            "wamr/core/iwasm/libraries/libc-builtin/libc_builtin.cmake",
            "wamr/core/iwasm/libraries/libc-emcc",
            "wamr/core/iwasm/libraries/libc-wasi/libc_wasi.cmake",
            "wamr/core/iwasm/libraries/libc-wasi/sandboxed-system-primitives/LICENSE",
            "wamr/core/iwasm/libraries/libc-wasi/sandboxed-system-primitives/include/LICENSE",
            "wamr/core/iwasm/libraries/libc-wasi/sandboxed-system-primitives/src/LICENSE",
            "wamr/core/iwasm/libraries/libc-wasi/sandboxed-system-primitives/src/README.md",
            "wamr/core/iwasm/libraries/thread-mgr",
            "wamr/core/shared/coap",
            "wamr/core/shared/mem-alloc/mem_alloc.cmake",
            "wamr/core/shared/platform/\(platform)/shared_platform.cmake",
            "wamr/core/shared/platform/common/freertos",
            "wamr/core/shared/platform/common/math",
            "wamr/core/shared/platform/common/posix/platform_api_posix.cmake",
            "wamr/core/shared/utils/shared_utils.cmake",
            "wamr/core/shared/utils/uncommon/shared_uncommon.cmake",
        ],
        sources: [
            "wamr/core/iwasm/common",
            "wamr/core/iwasm/common/arch/invokeNative_general.c",
            "wamr/core/iwasm/interpreter",
            "wamr/core/iwasm/libraries/libc-builtin",
            "wamr/core/iwasm/libraries/libc-wasi",
            "wamr/core/shared/mem-alloc",
            "wamr/core/shared/platform/\(platform)",
            "wamr/core/shared/platform/common/posix",
            "wamr/core/shared/utils",
        ],
        cSettings: macroDefinitions + [
            .headerSearchPath("wamr/core/iwasm/common"),
            .headerSearchPath("wamr/core/iwasm/include"),
            .headerSearchPath("wamr/core/iwasm/interpreter"),
            .headerSearchPath("wamr/core/iwasm/libraries/libc-wasi/sandboxed-system-primitives/include"),
            .headerSearchPath("wamr/core/iwasm/libraries/libc-wasi/sandboxed-system-primitives/src"),
            .headerSearchPath("wamr/core/shared/mem-alloc"),
            .headerSearchPath("wamr/core/shared/platform/\(platform)"),
            .headerSearchPath("wamr/core/shared/platform/include"),
            .headerSearchPath("wamr/core/shared/utils"),
        ]
    )
}

wamrTargets += [
    wamrCoreTarget(platform: "linux"),
    wamrCoreTarget(platform: "darwin"),
]

let package = Package(
    name: "WAMR",
    products: [
    ],
    targets: wamrTargets + [
        .target(name: "WAMR", dependencies: [.target(name: "wamr-core")]),
        .target(name: "wamr-demo", dependencies: [
            .target(name: "wamr-core"),
            .target(name: "wamr-core-darwin", condition: .when(platforms: [.macOS, .iOS, .tvOS, .watchOS])),
            .target(name: "wamr-core-linux", condition: .when(platforms: [.linux])),
        ]),
        .target(name: "wamr-core", dependencies: [
            .target(name: "wamr-core-darwin", condition: .when(platforms: [.macOS, .iOS, .tvOS, .watchOS])),
            .target(name: "wamr-core-linux", condition: .when(platforms: [.linux])),
        ]),
//        .testTarget(name: "WAMRTests", dependencies: ["WAMR"]),
    ]
)
