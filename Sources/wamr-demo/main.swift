import WAMR
import Foundation

let inputFile = CommandLine.arguments[1]
let binary = try Array(Data(contentsOf: URL(fileURLWithPath: inputFile)))

WasmRuntime.initialize()
let module = try WasmModule(binary: binary)
module.setWasiOptions(dirs: [], mapDirs: [], envs: [], args: [])
let instance = try module.instantiate(stackSize: 64 * 1024)
try instance.executeMain(args: [])
