// swift-tools-version:5.3

import PackageDescription
import Foundation

let wamrSource = "third-party/wasm-micro-runtime"

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

func wamrCorePlatforms(except: String) -> [String] {
    let platforms = ["riot", "vxworks", "linux-sgx", "alios", "linux", "android", "windows", "zephyr", "nuttx", "esp-idf", "darwin"]
    return platforms.filter { $0 != except }.map { "wamr/core/shared/platform/\($0.split(separator: "/").last!)" }
}

func invokeNative(_ platform: String) -> String {
    switch platform {
    case "darwin": return "invokeNative.s"
    case "linux": return "invokeNative.c"
    default: fatalError("unsupported platform \(platform)")
    }
}

func wamrCoreTarget(platform: String) -> Target {
    .target(
        name: "wamr-core-\(platform)",
        dependencies: [
        ],
        exclude: wamrCorePlatforms(except: platform) + [
            "wamr/ATTRIBUTIONS.md",
            "wamr/CODE_OF_CONDUCT.md",
            "wamr/CONTRIBUTING.md",
            "wamr/Dockerfile",
            "wamr/LICENSE",
            "wamr/ORG_CODE_OF_CONDUCT.md",
            "wamr/README.md",
            "wamr/SECURITY.md",
            "wamr/assembly-script",
            "wamr/build-scripts",
            "wamr/core/app-framework",
            "wamr/core/app-mgr",
            "wamr/core/deps",
            "wamr/core/iwasm/README.md",
            "wamr/core/iwasm/aot",
            "wamr/core/iwasm/common/arch",
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
            "wamr/core/shared/platform/README.md",
            "wamr/core/shared/platform/\(platform)/shared_platform.cmake",
            "wamr/core/shared/platform/common/freertos",
            "wamr/core/shared/platform/common/math",
            "wamr/core/shared/platform/common/posix/platform_api_posix.cmake",
            "wamr/core/shared/platform/include",
            "wamr/core/shared/utils/shared_utils.cmake",
            "wamr/core/shared/utils/uncommon/shared_uncommon.cmake",
            "wamr/doc",
            "wamr/product-mini",
            "wamr/samples",
            "wamr/test-tools",
            "wamr/wamr-compiler",
            "wamr/wamr-sdk",
        ],
        sources: [
            "wamr/core/iwasm/common",
            "wamr/core/iwasm/interpreter",
            "wamr/core/iwasm/libraries/libc-builtin",
            "wamr/core/iwasm/libraries/libc-wasi",
            "wamr/core/shared/mem-alloc",
            "wamr/core/shared/platform/\(platform)",
            "wamr/core/shared/platform/common/posix",
            "wamr/core/shared/utils",
            invokeNative(platform),
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

var wamrTargets: [Target] = []
let wamrCoreDependencies: [Target.Dependency]
if getenv("WAMR_SWIFT_LINUX_ONLY") != nil {
    wamrTargets += [
        wamrCoreTarget(platform: "linux"),
    ]
    wamrCoreDependencies = [
        .target(name: "wamr-core-linux", condition: .when(platforms: [.linux])),
    ]
} else {
    wamrTargets += [
        wamrCoreTarget(platform: "linux"),
        wamrCoreTarget(platform: "darwin"),
    ]

    wamrCoreDependencies = [
        .target(name: "wamr-core-linux", condition: .when(platforms: [.linux])),
        .target(name: "wamr-core-darwin", condition: .when(platforms: [.macOS, .iOS, .tvOS, .watchOS])),
    ]
}

let package = Package(
    name: "WAMR",
    products: [
        .library(name: "WAMR", targets: ["WAMR"])
    ],
    targets: wamrTargets + [
        .target(name: "wamr-demo", dependencies: [.target(name: "WAMR")]),
        .target(name: "WAMR", dependencies: [.target(name: "wamr-core")]),
        .target(name: "wamr-core", dependencies: wamrCoreDependencies),
        .testTarget(name: "WAMRTests", dependencies: ["WAMR"]),
    ]
)
