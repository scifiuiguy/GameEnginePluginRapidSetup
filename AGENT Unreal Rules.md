# AGENT Unreal Engine Refactoring Rules

These rules guide refactoring efforts to keep controllers thin, maintainable, and focused on orchestration rather than implementation details.

---

## Controller Size Limits

* **Target:** Controllers should be 500 lines or less. If a controller exceeds this, it's a strong signal that refactoring is needed.
* When a controller grows too large, seek opportunities to extract functionality into focused service classes.

---

## Method Size Limits

* **Target:** Methods should be ~30 lines or less. If a method exceeds this, consider breaking it into smaller, focused methods.
* Long methods are harder to understand, test, and maintain. Extract logical chunks into well-named helper methods.
* **Exception:** Complex initialization methods that set up multiple related objects may exceed this limit, but should still be reviewed for extraction opportunities.

---

## Interface Naming Conventions

* Prefer verb-style interface names (e.g., `IBridgeEvents`, `IDMXTransport`) over adjective-style names (e.g., `IEventBridgeable`, `IDMXTransportable`).
* Verb-style names describe what the interface does, which is more idiomatic in C++ and aligns with Microsoft's naming conventions.
* This keeps interface names concise and action-oriented, consistent with Unreal Engine's existing patterns.

---

## Service Extraction Patterns

* If a controller has methods that are just thin wrappers calling subordinate class methods, remove the wrapper and call the subordinate directly.
* Gather like members and methods into their own classes to be referenced by the controller via interfaces and OOP.
* Services should own their dependencies. If a service is the only consumer of certain data structures, move ownership into the service.
* Controllers should compose services, not duplicate their functionality.
* When refactoring code blocks into helper methods, extract logical chunks into well-named helper methods to improve readability and maintainability.

---

## State Machine Refactoring

* Switch-case or if-else chains handling basic state machine logic are great refactoring candidates.
* Use factory patterns to eliminate switch statements in construction logic.
* Use polymorphism (interfaces) to eliminate switch statements in runtime operations.
* If you have switch statements for construction, usage, AND setup, all three can likely be moved into a factory pattern.

---

## Polymorphism and Interfaces

* Prefer interfaces (`IDMXTransport`) over concrete types for abstraction.
* Use factory methods on interfaces to encapsulate construction logic.
* Controllers should use polymorphic pointers (`IDMXTransport*`) rather than mode-specific branches.
* When you see `"if (Mode == X) then use ClassX, else if (Mode == Y) then use ClassY"`, consider an interface with a factory.

---

## Service Architecture

* Services should be non-UObject classes focused on specific domains (`FixtureService`, `RDMService`, `ArtNetManager`).
* Services own their domain-specific data structures (`FixtureService` owns `FixtureRegistry` and `FadeEngine`).
* Controllers orchestrate services and bridge events to Blueprint, but don't duplicate service logic.
* If functionality is shared across multiple contexts but contains the same logic, encapsulate it as a service.

---

## Event Bridging Pattern

* Services emit native events (`DECLARE_MULTICAST_DELEGATE`).
* Controllers forward native events to Blueprint delegates (`DECLARE_DYNAMIC_MULTICAST_DELEGATE`).
* This keeps UI/Blueprint coupling minimal while allowing services to emit events freely.

---

## Factory Patterns

* When different modes require different construction parameters, use factory methods on interfaces.
* Factory methods can return setup results with callbacks for mode-specific initialization.
* This moves all mode-specific logic (construction, setup, configuration) into one place.
* Controllers should only call the factory and execute the setup callback - no mode checks needed.

---

## Ownership Principles

* Controllers own shared resources (`UniverseBuffer` used by both controller and services).
* Services own domain-specific resources (`FixtureRegistry`, `FadeEngine` owned by `FixtureService`).
* Transport instances are owned by controllers but accessed polymorphically.
* Avoid double ownership - use raw pointers or custom deleters when one object points to another it doesn't own.

---

## Best-Practice Notes

* Methods with `"InitializeX"` / `"ShutdownX"` pairs that just call `X->Initialize()` / `X->Shutdown()` - remove them.
* Methods that directly access registry/buffer that a service also uses - move to service.
* Switch statements that appear in multiple places (construction, usage, cleanup) - use factory pattern.
* Controller methods that are just "get service, call service method" - remove wrapper, expose service accessor.
* Friend declarations that are only needed because wrapper methods exist - remove friend and wrapper.
* Avoid unnecessary inheritance - prefer composition and interfaces over deep inheritance hierarchies.

---

## Refactoring Workflow

1. **Identify the bloat:** What's making the controller too large?
2. **Find the patterns:** Are there switch statements? Wrapper methods? Direct access to shared resources?
3. **Extract services:** Group related functionality into focused service classes.
4. **Use interfaces:** Create polymorphic interfaces for similar but different implementations.
5. **Factory patterns:** Move construction and setup logic into factories.
6. **Verify:** Controller should be thin orchestrator, services handle implementation.

---

## Building and Compilation

* Use UnrealBuildTool (UBT) to compile Unreal Engine projects from the command line.
* Typical UBT location: `C:\Program Files\Epic Games\UE_<VERSION>\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe`
* Common build command format:
  ```powershell
  UnrealBuildTool.exe <TargetName> <Platform> <Configuration> -Project="<PathToUProject>" -WaitMutex -FromMsBuild
  ```
* Example for Editor target:
  ```powershell
  UnrealBuildTool.exe [PROJECT-NAME]_UnrealPluginEditor Win64 Development -Project="$PWD\[PROJECT-NAME]_UnrealPlugin.uproject" -WaitMutex -FromMsBuild
  ```
* Check for Unreal Engine installation at standard path:
  ```powershell
  Test-Path 'C:\Program Files\Epic Games\UE_5.5\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe'
  ```
* Build output: Exit code 0 = success, Exit code 1 = failure

### Module Renaming

When renaming a module (folder name, Build.cs class name, or module name in IMPLEMENT_MODULE), always perform a full clean build:

1. Delete `Intermediate/` folder: `Remove-Item -Path "Intermediate" -Recurse -Force`
2. Delete `Binaries/` folder (optional but recommended): `Remove-Item -Path "Binaries" -Recurse -Force`
3. Regenerate project files: `UnrealBuildTool.exe -projectfiles -project="<PathToUProject>" -game -rocket -progress`
4. Rebuild: `UnrealBuildTool.exe <TargetName> <Platform> <Configuration> -Project="<PathToUProject>" -WaitMutex -FromMsBuild`

> **Why:** Unreal's build system caches module names and file lists. Renaming a module without cleaning can cause the build system to look for files in the old location, resulting in "file not found" errors even though the code is correct.

* Common issues: Circular dependencies (move types to shared headers), incomplete type deletions (use raw pointers or forward-declared deleters), missing includes

---

## Debugging Compilation Errors

### Error Migration Pattern

If you comment out a line that has a compilation error, and the same error appears on a different line (usually earlier in the file), this is a strong indicator of a syntax error somewhere higher up in the same file. The compiler is misinterpreting later code due to the earlier syntax issue.

* **Example:** Error on line 516 → comment it out → error moves to line 338 → comment that out → error moves to line 291. This pattern suggests checking lines 33-34 (DOREPLIFETIME macros with wrong class name) or other syntax issues near the top of the file.
* **Solution:** Read the entire file from the top, looking for:
  - Incorrect class names in macros (`DOREPLIFETIME`, `GENERATED_BODY`, etc.)
  - Missing semicolons or braces
  - Mismatched template brackets
  - Incorrect include paths
  - Forward declaration issues

---

## Remember

* **NEVER use backtick marks (`) in responses to the user** - they cause formatting issues in Cursor chat.
* Controllers are orchestrators, not implementers.
* Services are domain experts, not general-purpose utilities.
* Interfaces enable polymorphism, factories enable clean construction.
* The goal is a thin controller that composes services, not a fat controller that does everything.

---

## Stream Data Processing Performance

When building transport layers for API data streams (media: image/video/audio, metadata, or any continuous data stream), prioritize lowest-latency and high-performance patterns:

### Data Models

* **Use struct-based data models** for stream data instead of classes when possible - structs avoid heap allocation and reduce memory fragmentation.
* Keep structs small and value-type focused - avoid `UObject` references or other heavy types within stream processing structs.
* Use `const` and `constexpr` where possible to enable compiler optimizations.
* Consider `TArrayView<T>` for zero-copy operations on stream buffers without ownership transfer.

### Serialization/Deserialization

* **Binary serialization** is fastest - prefer binary formats (FlatBuffers, MessagePack, Protobuf, custom binary) over text formats (JSON, XML) for high-frequency streams.
* **FlatBuffers is recommended as the default** for stream data processing - provides zero-copy deserialization, JSON compatibility for debugging, and significant performance improvements. FlatBuffers works in Unreal but requires plugin integration due to Unreal's build system.
* **Unreal's native `USTRUCT` system** - Excellent for Unreal-specific data with built-in reflection, Blueprint support, and network replication. However, for pure stream processing, FlatBuffers may offer better performance due to zero-copy access patterns.
* Use streaming deserializers instead of loading entire documents into memory when JSON is required.
* Pool serialization buffers - reuse `TArray<uint8>` or `FMemory::Malloc` allocations to avoid per-frame allocations.
* For JSON fallback: Use rapidjson or similar high-performance libraries over slower alternatives.
* Avoid reflection-based serialization in hot paths - use code generation, FlatBuffers, manual serialization, or Unreal's `USTRUCT` system (when Blueprint/network features are needed) for stream data.

### Encryption

* Use hardware-accelerated encryption when available (AES-NI, etc.).
* Prefer symmetric encryption (AES) over asymmetric (RSA) for stream data - symmetric is orders of magnitude faster.
* Process encryption in chunks rather than per-packet to reduce overhead.
* Consider encrypting only metadata headers, leaving media payloads unencrypted if security requirements allow.

### ORM and Database Access

* **Avoid ORMs in stream processing paths** - use raw SQL or lightweight data access for high-frequency operations.
* Use connection pooling and prepared statements for database streams.
* Batch database operations when possible - group multiple inserts/updates into transactions.
* Consider in-memory databases or caches (Redis, Memcached) for stream metadata that needs persistence.

### General Stream Processing

* **Avoid allocations in hot paths** - use object pooling (`FObjectPool`) for temporary objects created during stream processing.
* Use raw pointers and `FMemory::Malloc`/`Free` for zero-copy operations when performance is critical (profile first).
* Process streams in background threads - use `AsyncTask` or `FRunnable` to avoid blocking game thread.
* Use `TArray<uint8>` with pre-allocated capacity or `FMemory::Malloc` for temporary buffers instead of frequent reallocations.
* Profile with Unreal Insights - measure actual performance before optimizing, focus on allocation spikes and frame time.

### Unreal-Specific Considerations

* Use `TArray<uint8>` or `TArrayView<uint8>` for binary stream data instead of `FString` or `TCHAR*`.
* Consider `FAsyncTask` or `FRunnableThread` for parallel stream processing.
* Be mindful of Unreal's game thread requirements - marshal results back to game thread when needed using `AsyncTask(ENamedThreads::GameThread, ...)`.
* Use `FMemory::Memcpy` for low-level memory operations when working with native data streams.
* Leverage Unreal's `USTRUCT` system with `UPROPERTY` for serialization when you need reflection, but prefer manual binary serialization for hot paths.

---

## AI Model Integration with NIM Containers

When integrating AI models via NVIDIA NIM (NVIDIA Inference Microservices) containers, use appropriate communication protocols based on deployment location:

### gRPC vs REST for NIM Containers

* **Local NIM containers: Use gRPC** - Lower latency, binary protocol (Protobuf), HTTP/2 multiplexing, and better performance for high-frequency inference requests.
* **Cloud NIM containers: Use REST** - Simpler firewall/proxy traversal, wider compatibility, easier debugging with standard HTTP tools, and better suited for occasional requests over public networks.
* **Hybrid approach:** Use gRPC for local inference pipelines and REST for cloud fallbacks or external API access.

### gRPC in Unreal with TurboLink

* **Plugin:** TurboLink ([GitHub](https://github.com/thejinchao/turbolink)) - Unreal Engine plugin for Google gRPC integration.
* **Compatibility:** Supports Unreal Engine 4.27+ and 5.x (C++ and Blueprint).
* **Installation:** 
  * Add as git submodule to your Unreal project's `Plugins/` directory.
  * **Important:** TurboLink has several open-source dependencies that must be installed separately. See the [TurboLink repository documentation](https://github.com/thejinchao/turbolink) for complete installation instructions and dependency requirements.
* **Best Practices:**
  * Use TurboLink's async gRPC function calls - never block the game thread.
  * TurboLink automatically handles game thread marshaling for Blueprint callbacks.
  * For C++ implementations, use `AsyncTask(ENamedThreads::GameThread, ...)` to marshal results back to game thread when updating UObject properties.
  * Configure gRPC channels with appropriate timeouts and message size limits for your model outputs.
  * Use TurboLink's streaming gRPC methods for real-time inference pipelines (e.g., video processing).
  * Handle gRPC errors appropriately - TurboLink provides error callbacks in both C++ and Blueprint.
  * For TLS connections, configure TurboLink's SSL credentials for secure local or cloud connections.
* **Performance:** TurboLink provides efficient C++ bindings to gRPC, enabling low-latency communication with NIM containers while maintaining Unreal's threading model.

---

## NOOP Marking

When generating new code, maintain awareness of all instances of **NOOP** parts of the implementation that are intended to be implemented later. Mark them clearly with NOOP comments:

```cpp
// NOOP: This functionality will be implemented in a future update
void SomeMethod()
{
    // TODO: Implement actual logic
    return;
}
```

List all such instances in summaries of your work in chat when you're done. This helps track incomplete implementations and prevents confusion about missing functionality.

---

## References

* References (`T&`) must be initialized at declaration - `T& x;` does not compile.
* `T&` = C# `ref` - modifies caller's variable.
* No `out` keyword in C++ - just declare the variable before the call and pass by `T&`.
* `const T&` = pass big data without copy - use for all input params > 8 bytes (`FVector`, `FName`, `FMyStruct`).
* Never return `T&` to a local - dangling reference → crash. Return by value instead (RVO).

---

## Lambda Capture (Async Safety)

* Never capture `this` or raw `UObject*` in `Async()` - actor may be destroyed.
* Use `TWeakObjectPtr<T>` for all UObject captures:
  ```cpp
  TWeakObjectPtr<AActor> Weak = this;
  Async(..., [Weak]() { if (Weak.Get()) ... });
  ```
* Copy primitives with `[var]` or `[=]` - safe and simple.
* Never use `[&]` unless same-stack, immediate execution - dangling risk.

---

## TArray & Dynamic Data

* `TArray` is 24 bytes - contains pointer to heap, Num, and Max.
* Array data lives on the heap - the containing object never grows or moves.
* `Add()` may reallocate the heap buffer - object stays in place.
* `TArray` copy is shallow - both arrays point to same heap data.
* Use `Duplicate(Original)` for deep copy when needed.
* Use `MoveTemp(Local)` when adding to `TArray` - avoids heap allocation and copy.

---

## Move Semantics (T&&)

* `T&&` = rvalue reference - binds to temporaries or `MoveTemp(var)`.
* Move = steal heap data, leave source empty - zero-cost transfer.
* Return big objects by value - move is automatic (RVO or move constructor).
* `MoveTemp(var)` forces move - treat lvalue as rvalue.
* Write move constructors for custom types with heap data - use `MoveTemp` on members.

---

## Function Best Practices

* **Input > 8 bytes** → `const T&`
  ```cpp
  void SetLocation(const FVector& Loc);
  ```
* **Input ≤ 8 bytes** → `T`
  ```cpp
  void SetHealth(int32 Health);
  ```
* **Return big data** → `T` (let RVO/move handle it)
  ```cpp
  FMyConfig LoadConfig() { ... return Config; }
  ```
* **Modify caller** → `T&`
  ```cpp
  void AddScore(int32& Score);
  ```
* **Take ownership** → `T&&`
  ```cpp
  void Store(FMyData&& Data);
  ```

---

## Unreal Golden Rules

* Always null-check pointers: `if (Actor) ...`
* Never copy UObjects - use pointers or `TWeakObjectPtr`.
* Use `AsyncTask(ENamedThreads::GameThread, ...)` to return to GameThread.
* `TArray::Add(MoveTemp(...))` = zero-cost insert.
* `const T&` = zero-cost read-only access.
* `TWeakObjectPtr` = the only safe way to reference UObjects in async or long-lived contexts.

---

## Git Workflow

* **Git initialization is automated** during project generation via `generate_unreal_project.ps1`.
* **Note:** For Unreal projects, the git repository is initialized in `Plugins/[Project-Name]/`, not the project root.
* **User handles all git operations** after initialization: `git add`, `git commit`, `git branch`, `git push`, etc. (both locally and remotely).
* **AGENT should NOT** perform git operations (add, commit, push, branch) unless explicitly requested by the user.
* **Exception:** Git initialization (`git init`) and related setup is handled automatically by the project generation script, which will prompt the user to choose between GitHub or local-only initialization.
* When the generation script runs, it will:
  1. Add a standard Unreal `.gitignore` file to the project root
  2. Ask the user: "Would you like me to initialize the repository on GitHub or just locally?"
  3. If GitHub is selected, attempt to create the repository using GitHub CLI (`gh`), or prompt for a manual repository URL
  4. If local-only is selected, just run `git init` in `Plugins/[Project-Name]/`
  5. If skip is selected, the user will initialize manually later
* **CRITICAL:** If git initialization or any other automated git exception goes awry, **NEVER delete a git repository from the user's GitHub account**. Always prompt the user with the reason a repo should be deleted, and the user will delete it manually if approved.
* **Cloud Agent Exception:** When operating as a cloud agent in unsupervised VM environments, see `AGENT Cloud Agents Rules.md` for workflow exceptions that allow independent git commits to feature branches.

