# wamr-swift

Swift WebAssembly runtime powered by WAMR

## Adding wamr-swift as a Dependency

To use the wamr-swift library in a SwiftPM project, add the following line to the dependencies in your Package.swift file:

```swift
let package = Package(
    name: "Example",
    dependencies: [
        .package(name: "WAMR", url: "https://github.com/swiftwasm/wamr-swift", from: "0.1.1"),
    ],
    targets: [
        .target(name: "Example", dependencies: ["WAMR"]),
    ]
)

```


## Example

```swift
import WAMR
import Foundation

let inputFile = CommandLine.arguments[1]
let binary = try Array(Data(contentsOf: URL(fileURLWithPath: inputFile)))

WasmRuntime.initialize()
let module = try WasmModule(binary: binary)
module.setWasiOptions(dirs: [], mapDirs: [], envs: [], args: [])
let instance = try module.instantiate(stackSize: 64 * 1024)
try instance.executeMain(args: [])
```
