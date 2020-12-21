import WAMRCore

struct WasmRuntimeError: Error {
    let message: String
}

public enum WasmRuntime {
    public static func defaultRuntimeInitArgs() -> RuntimeInitArgs {
        var initArgs = RuntimeInitArgs()
        initArgs.mem_alloc_type = Alloc_With_System_Allocator
        return initArgs
    }
    public static func initialize(initArgs: RuntimeInitArgs = defaultRuntimeInitArgs()) {
        var initArgs = initArgs
        wasm_runtime_full_init(&initArgs)
    }
}

public class WasmModule {
    let pointer: wasm_module_t
    init(pointer: wasm_module_t) {
        self.pointer = pointer
    }
    public init(binary: [UInt8]) throws {
        do {
            let module = try wasmThrowsfy { (errorBuffer, errorBufferSize) in
                binary.withUnsafeBufferPointer { binary in
                    wasm_runtime_load(
                        binary.baseAddress!, UInt32(binary.count),
                        errorBuffer, errorBufferSize
                    )
                }
            }
            self.pointer = module
        } catch {
            wasm_runtime_destroy()
            throw error
        }
    }

    public func setWasiOptions(dirs: [String], mapDirs: [String],
                               envs: [String], args: [String]) {
        var unsafeDirs = dirs.map { dir -> UnsafePointer<Int8>? in dir.unsafeUTF8Copy() }
        var unsafeMapDirs = mapDirs.map { dir -> UnsafePointer<Int8>? in dir.unsafeUTF8Copy() }
        var unsafeEnvs = envs.map { env -> UnsafePointer<Int8>? in env.unsafeUTF8Copy() }
        var unsafeArgs = args.map { arg -> UnsafeMutablePointer<Int8>? in
            UnsafeMutablePointer(mutating: arg.unsafeUTF8Copy())
        }
        defer {
            unsafeDirs.forEach { $0?.deallocate() }
            unsafeMapDirs.forEach { $0?.deallocate() }
            unsafeEnvs.forEach { $0?.deallocate() }
            unsafeArgs.forEach { $0?.deallocate() }
        }

        wasm_runtime_set_wasi_args(
            pointer, &unsafeDirs, UInt32(unsafeDirs.count),
            &unsafeMapDirs, UInt32(unsafeMapDirs.count),
            &unsafeEnvs, UInt32(unsafeEnvs.count),
            &unsafeArgs, Int32(unsafeArgs.count)
        )
    }

    public func instantiate(
        stackSize: Int = 16 * 1024,
        heapSize: Int = 16 * 1024
    ) throws -> WasmInstance {
        let instance = try wasmThrowsfy { (errorBuffer, errorBufferSize) in
            wasm_runtime_instantiate(
                pointer, UInt32(stackSize), UInt32(heapSize),
                errorBuffer, errorBufferSize
            )
        }
        return WasmInstance(pointer: instance)
    }

    deinit {
        wasm_runtime_unload(pointer)
    }
}

public class WasmInstance {
    let pointer: wasm_module_inst_t
    init(pointer: wasm_module_inst_t) {
        self.pointer = pointer
    }
    
    
    public func executeMain(
        args: [String]
    ) throws {
        var unsafeArgs = args.map { arg -> UnsafeMutablePointer<Int8>? in
            UnsafeMutablePointer(mutating: arg.unsafeUTF8Copy())
        }
        defer { unsafeArgs.forEach { $0?.deallocate() } }
        guard wasm_application_execute_main(
            pointer, Int32(unsafeArgs.count), &unsafeArgs
        ) else {
            let errorBuffer = wasm_runtime_get_exception(pointer)!
            throw WasmRuntimeError(message: String(cString: errorBuffer))
        }
    }

    public func executeFunc(
        funcName: String, args: [String]
    ) throws {
        var unsafeArgs = args.map { arg -> UnsafeMutablePointer<Int8>? in
            UnsafeMutablePointer(mutating: arg.unsafeUTF8Copy())
        }
        defer { unsafeArgs.forEach { $0?.deallocate() } }
        guard wasm_application_execute_func(
            pointer, funcName,
            Int32(args.count), &unsafeArgs
        ) else {
            let errorBuffer = wasm_runtime_get_exception(pointer)!
            throw WasmRuntimeError(message: String(cString: errorBuffer))
        }
    }

    deinit {
        wasm_runtime_deinstantiate(pointer)
    }
}


internal func wasmThrowsfy<T>(
    _ fn: (_ errorBuffer: UnsafeMutablePointer<Int8>,
           _ errorBufferSize: UInt32) -> T?
) throws -> T {
    var errorBuffer = [CChar](repeating: 0, count: 128)
    let result = errorBuffer.withUnsafeMutableBufferPointer { buffer in
        fn(buffer.baseAddress!, UInt32(buffer.count))
    }
    guard let value = result else {
        throw WasmRuntimeError(
            message: String(cString: errorBuffer)
        )
    }
    return value
}

extension String {
    internal func unsafeUTF8Copy() -> UnsafePointer<CChar> {
        let cString = utf8CString
        let cStringCopy = UnsafeMutableBufferPointer<CChar>
            .allocate(capacity: cString.count)
        _ = cStringCopy.initialize(from: cString)
        return UnsafePointer(cStringCopy.baseAddress!)
    }
}
