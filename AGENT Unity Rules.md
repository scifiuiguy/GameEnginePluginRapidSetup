# AGENT Unity Rules

## Code Style

* Eliminate curly braces wherever possible.
* Eliminate extra newline spaces wherever possible.
* I like my C# concise, but don't place two or more statements (each finalized by a semicolon) on a single line.
* You can inline an if condition with its single-line statement if both in total are less than 100 characters, but otherwise place the condition on one line and its statement on the next with an indent.
* You can inline an 'else' under the same conditions as for 'if'.
* Any time a function is more than ~30 lines of code, you should chunk it into sensible code blocks and place each code block into a helper method in a region called Helper Methods.
* When refactoring code blocks into helper methods, use `ref` and `out` keywords appropriately to minimize total number of lines and prevent extra memory allocation.
* Write comments where appropriate, but note that many comments are unnecessary if code blocks are chunked well with helper methods accurately named.
* Use expression-bodied members liberally in favor of local vars any time it is more efficient or equivalent for memory management.
* For simple assignment passthrough methods (like getters that just return a field), always use expression-bodied members instead of full method bodies.
* Always use LINQ for filtering sizable data sets unless I specify otherwise.
* Ask my permission before using reflection for anything.
* If/else formatting: inline each branch if its condition+statement < 100 chars, but put else on its own line; never place both branches on the same line; one semicolon per line.

---

## Class and Method Size Limits

* **Target:** Controllers/Managers should be 500 lines or less. If a class exceeds this, it's a strong signal that refactoring is needed.
* **Target:** Methods should be ~30 lines or less. If a method exceeds this, consider breaking it into smaller, focused methods.
* Long methods are harder to understand, test, and maintain. Extract logical chunks into well-named helper methods.
* **Exception:** Complex initialization methods that set up multiple related objects may exceed this limit, but should still be reviewed for extraction opportunities.
* When a class grows too large, seek opportunities to extract functionality into focused service classes.

---

## Interface Naming Conventions

* Prefer verb-style interface names (e.g., `IBridgeEvents`, `IDMXTransport`) over adjective-style names (e.g., `IEventBridgeable`, `IDMXTransportable`).
* Verb-style names describe what the interface does, which is more idiomatic in C# and C++.
* This keeps interface names concise and action-oriented, consistent with common .NET and C++ patterns.

---

## Service Extraction Patterns

* If a controller has methods that are just thin wrappers calling subordinate class methods, remove the wrapper and call the subordinate directly.
* Gather like members and methods into their own classes to be referenced by the controller via interfaces and OOP.
* Services should own their dependencies. If a service is the only consumer of certain data structures, move ownership into the service.
* Controllers should compose services, not duplicate their functionality.
* Extract services as plain C# classes (not MonoBehaviours) when they don't need Unity lifecycle methods.

---

## State Machine Refactoring

* Switch-case or if-else chains handling basic state machine logic are great refactoring candidates.
* Use factory patterns to eliminate switch statements in construction logic.
* Use polymorphism (interfaces) to eliminate switch statements in runtime operations.
* If you have switch statements for construction, usage, AND setup, all three can likely be moved into a factory pattern.
* Consider using Unity's ScriptableObject-based factories for data-driven object creation.

---

## Polymorphism and Interfaces

* Prefer interfaces (`ITransport`, `IEventBridge`) over concrete types for abstraction.
* Use factory methods on interfaces to encapsulate construction logic.
* Controllers should use polymorphic references (`ITransport transport`) rather than mode-specific branches.
* When you see `"if (Mode == X) then use ClassX, else if (Mode == Y) then use ClassY"`, consider an interface with a factory.
* Use dependency injection to provide interface implementations to controllers.

---

## Service Architecture

* Services should be plain C# classes focused on specific domains (`NetworkService`, `DataService`, `EventService`).
* Services own their domain-specific data structures (`NetworkService` owns connection pools and message queues).
* Controllers orchestrate services and bridge events to Unity, but don't duplicate service logic.
* If functionality is shared across multiple contexts but contains the same logic, encapsulate it as a service.
* Services can be singletons or injected via dependency injection, depending on your architecture.

---

## Event Bridging Pattern

* **Prefer C# Action delegates** (`Action`, `Action<T>`, `Action<T1, T2>`, etc.) for event communication between services and controllers.
* Services expose Action properties or fields that controllers can subscribe to: `public Action<Data> OnDataReceived { get; set; }`
* Controllers subscribe to service Actions and handle the events directly in C# code.
* Only use `UnityEvent` or `UnityEvent<T>` when Inspector visibility is specifically required (e.g., for designer-friendly event configuration).
* Only use C# `event` keyword when you need the built-in thread safety and null-checking that events provide, or when multiple subscribers need individual unsubscribe capability.
* This keeps Unity/Inspector coupling minimal while allowing services to emit events freely.
* Use `[SerializeField]` on UnityEvent fields only when Inspector exposure is necessary.

---

## Factory Patterns

* When different modes require different construction parameters, use factory methods on interfaces.
* Factory methods can return setup results with callbacks for mode-specific initialization.
* This moves all mode-specific logic (construction, setup, configuration) into one place.
* Controllers should only call the factory and execute the setup callback - no mode checks needed.
* Consider ScriptableObject-based factories for data-driven object creation in Unity.

---

## Ownership and Memory Management

* Controllers own shared resources (buffers, pools used by both controller and services).
* Services own domain-specific resources (connection pools, caches owned by specific services).
* Service instances are owned by controllers but accessed polymorphically.
* Avoid circular references - use weak references or events for cross-service communication.
* In Unity, be mindful of MonoBehaviour lifecycle - services should not hold strong references to destroyed GameObjects.

---

## Best-Practice Notes

* Methods with `"InitializeX"` / `"ShutdownX"` pairs that just call `X.Initialize()` / `X.Shutdown()` - remove them.
* Methods that directly access registry/buffer that a service also uses - move to service.
* Switch statements that appear in multiple places (construction, usage, cleanup) - use factory pattern.
* Controller methods that are just "get service, call service method" - remove wrapper, expose service accessor.
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

* **Use struct-based data models** for stream data instead of classes when possible - structs avoid heap allocation and reduce GC pressure.
* Keep structs small and value-type focused - avoid reference types within structs when processing streams.
* Use `readonly struct` for immutable stream data to enable compiler optimizations.
* Consider `Span<T>` and `Memory<T>` for zero-copy operations on stream buffers.

### Serialization/Deserialization

* **Binary serialization** is fastest - prefer binary formats (FlatBuffers, MessagePack, Protobuf, custom binary) over text formats (JSON, XML) for high-frequency streams.
* **FlatBuffers is recommended as the default** for stream data processing - provides zero-copy deserialization, JSON compatibility for debugging, and 40x+ performance improvements over traditional JSON.
* **ZeroFormatter** ([GitHub](https://github.com/neuecc/ZeroFormatter)) - Unity-specific FlatBuffers variant using C# attributes and IL tricks. Provides "infinitely fast" deserialization by accessing serialized data without parsing. **Note:** Repository archived (May 2022) but still functional and faster than JsonUtility. Use when you need C#-native schema definitions without external IDL files.
* Use streaming deserializers (e.g., `Utf8JsonReader` for JSON) instead of loading entire documents into memory when JSON is required.
* Pool serialization buffers - reuse byte arrays/`ArrayPool<byte>` to avoid allocations per frame.
* For JSON fallback: Use `System.Text.Json` over `Newtonsoft.Json` for better performance in Unity.
* Avoid reflection-based serialization in hot paths - use code generation, FlatBuffers/ZeroFormatter, or manual serialization for stream data.

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

* **Avoid allocations in hot paths** - use object pooling for temporary objects created during stream processing.
* Use `unsafe` code blocks with pointers for zero-copy operations when performance is critical (profile first).
* Process streams in background threads - use `Task.Run` or `ThreadPool` to avoid blocking main thread.
* Use `System.Buffers.ArrayPool<T>` for temporary buffers instead of `new T[]`.
* Profile with Unity Profiler - measure actual performance before optimizing, focus on allocation spikes and GC pauses.

### Unity-Specific Considerations

* Use `NativeArray<T>` and `NativeSlice<T>` for interop with Unity's native code (e.g., texture data).
* Consider `JobSystem` for parallel stream processing when appropriate.
* Be mindful of Unity's main thread requirements - marshal results back to main thread when needed.
* Use `UnsafeUtility` for low-level memory operations when working with native data streams.

---

## AI Model Integration with NIM Containers

When integrating AI models via NVIDIA NIM (NVIDIA Inference Microservices) containers, use appropriate communication protocols based on deployment location:

### gRPC vs REST for NIM Containers

* **Local NIM containers: Use gRPC** - Lower latency, binary protocol (Protobuf), HTTP/2 multiplexing, and better performance for high-frequency inference requests.
* **Cloud NIM containers: Use REST** - Simpler firewall/proxy traversal, wider compatibility, easier debugging with standard HTTP tools, and better suited for occasional requests over public networks.
* **Hybrid approach:** Use gRPC for local inference pipelines and REST for cloud fallbacks or external API access.

### gRPC in Unity

* **Package:** Use `Grpc.Net.Client` NuGet package (requires .NET Standard 2.1+ or .NET 6+).
* **Unity Version:** Requires Unity 2021.2+ for .NET Standard 2.1 support, or Unity 2022.2+ for .NET 6+ support.
* **Best Practices:**
  * Use `GrpcChannel` with connection pooling - create channels once and reuse them (channels are thread-safe).
  * Use async/await for all gRPC calls - never block the main thread with synchronous calls.
  * Marshal results to main thread using `UnityMainThreadDispatcher` or `SynchronizationContext` when updating Unity objects.
  * Use cancellation tokens (`CancellationToken`) for timeout handling and request cancellation.
  * Configure channel options for your use case:
    ```csharp
    var channel = GrpcChannel.ForAddress("http://localhost:50051", new GrpcChannelOptions
    {
        MaxReceiveMessageSize = 4 * 1024 * 1024, // 4MB for large model outputs
        MaxSendMessageSize = 4 * 1024 * 1024,
        Credentials = ChannelCredentials.Insecure // Use Secure for production
    });
    ```
  * For streaming responses, use `AsyncServerStreamingCall<T>` and process results as they arrive.
  * Handle gRPC status codes (`RpcException`) appropriately - network errors, timeouts, and service errors.
* **Performance:** gRPC in Unity can achieve lower latency than REST, especially for binary data (images, tensors) using Protobuf serialization.

---

## Automated Compilation Workflow

> **Note:** Unreal Engine projects use UnrealBuildTool (UBT) which provides command-line compilation out-of-the-box. This automated compilation system is **Unity-specific only**.

AGENT uses a custom automated compilation system for Unity projects to enable AI-assisted error detection and debugging without requiring the Unity Editor to be open. This system mirrors the Unreal Engine's command-line build capabilities.

### Submodule Dependency

This compilation system is provided as a **git submodule** in this template repository:

- **Submodule Location:** `Unity_AutoCompilation/`
- **Repository:** [https://github.com/ajcampbell1333/Claude_Unity_Auto-Compilation](https://github.com/ajcampbell1333/Claude_Unity_Auto-Compilation)

**To add this submodule to your project:**

```bash
git submodule add https://github.com/ajcampbell1333/Claude_Unity_Auto-Compilation.git Unity_AutoCompilation
```

**To initialize submodules when cloning:**

```bash
git submodule update --init --recursive
```

### Architecture Overview

The system consists of three components:

1. **CompilationReporter.cs** - Editor script that monitors compilation events
2. **CompilationReporterCLI.cs** - Command-line interface for batch mode execution
3. **CompileProject_Silent.bat** (Windows) / **CompileProject.sh** (Linux) - Batch scripts that orchestrate the workflow

### How It Works

1. Batch script launches Unity in batch mode with `-executeMethod` flag
2. Unity loads the project and begins compilation
3. CompilationReporter hooks into Unity's CompilationPipeline events
4. Compilation results are written to `Temp/CompilationErrors.log`
5. Batch script detects report file creation (with 2-minute timeout)
6. Batch script terminates Unity process
7. Batch script returns exit code 0 (success) or 1 (failure)

### Key Design Decisions

- **DO NOT** use Unity's `-quit` flag - it exits before the report can be written
- Instead, launch Unity with `start /B` and manually kill it after report generation
- Use distinctive log markers (e.g., 🤖 `[PROJECT AUTO-COMPILE]`) for AI readability
- Write report to `Temp/CompilationErrors.log` (gitignored, ephemeral)
- Include Report ID (GUID) for tracking across multiple runs
- Support both event-driven compilation monitoring and CLI-triggered reports

### Usage for AGENT

When you need to check Unity compilation without user intervention:

1. Run: `.\CompileProject_Silent.bat` (Windows) or `./CompileProject.sh` (Linux)
2. Wait for exit code (0 = success, 1 = failure)
3. Read: `Temp/CompilationErrors.log` for structured error report
4. Parse errors in format: `[Type] file(line,column): message`

### File Locations

**Editor Scripts** (must be in `Assets/[ProjectName]/Editor/` or similar):

- `CompilationReporter.cs` - Auto-loads via `[InitializeOnLoad]`
- `CompilationReporterCLI.cs` - Provides static `CompileAndExit()` method

**Batch Scripts** (must be at Unity project root):

- `CompileProject_Silent.bat` (Windows)
- `CompileProject.sh` (Linux)

### Critical Implementation Notes

1. CompilationReporter **MUST** use `[InitializeOnLoad]` attribute
2. `CompilationReporterCLI.CompileAndExit()` **MUST NOT** call `EditorApplication.Exit()`
3. Batch script **MUST** wait for report file creation before killing Unity
4. Use `start /B` on Windows to launch Unity without blocking
5. Include timeout mechanism (default: 120 seconds) to prevent infinite hangs
6. `taskkill /IM Unity.exe /F` to forcefully terminate Unity on Windows

### Race Condition Prevention

The original implementation had a race condition where Unity would exit before writing the report. Solution:

- Remove `-quit` flag from Unity command line
- `CompileAndExit()` generates report but does **NOT** exit
- Batch script waits for `Temp/CompilationErrors.log` to exist
- Batch script adds 2-second grace period after detection
- Batch script explicitly kills Unity process

### Report Format

The report is structured for AI parsing:

```
===========================================
[PROJECT NAME] COMPILATION REPORT
🤖 AI-READABLE AUTOMATED COMPILATION CHECK
===========================================
Generated: YYYY-MM-DD HH:MM:SS
Report ID: PROJECT-XXXXXXXX

[Errors and warnings organized by assembly]

===========================================
Status: SUCCESS | FAILED
===========================================
```

### Installation and Setup

The automated compilation system is included as a git submodule in this template. To use it in your Unity project:

1. **Copy files from submodule:**
   - Copy Editor scripts from `Unity_AutoCompilation/` to `Assets/[YourProject]/Editor/`
   - Copy batch scripts (`CompileProject_Silent.bat` / `CompileProject_Silent.sh`) to your Unity project root

2. **Configure for your project:**
   - Update Unity executable paths in batch/shell scripts
   - (Optional) Update log markers from `"[YOURPROJECT AUTO-COMPILE]"` to your project name
   - (Optional) Update report header from `"YOURPROJECT COMPILATION REPORT"` to your project name

3. **Verify setup:**
   - Run `.\CompileProject_Silent.bat` (Windows) or `./CompileProject_Silent.sh` (Linux)
   - Check `Temp/CompilationErrors.log` for compilation report

> **No namespace customization needed** - Scripts use global namespace for simplicity.

### Integration with AI Workflow

This system enables AGENT to:

- Compile Unity projects without user intervention
- Detect compilation errors in real-time
- Fix errors iteratively without manual user feedback
- Verify fixes before committing changes
- Match the Unreal Engine workflow for consistency

**For detailed setup instructions, see:** `Unity_AutoCompilation/README.md` in the submodule.

---

## NOOP Marking

When generating new code, maintain awareness of all instances of **NOOP** parts of the implementation that are intended to be implemented later. Mark them clearly with NOOP comments and list all such instances in summaries of your work in chat when you're done.

---

## Git Workflow

* **Git initialization is automated** during project generation via `generate_unity_project.ps1`.
* **User handles all git operations** after initialization: `git add`, `git commit`, `git branch`, `git push`, etc. (both locally and remotely).
* **AGENT should NOT** perform git operations (add, commit, push, branch) unless explicitly requested by the user.
* **Exception:** Git initialization (`git init`) and related setup is handled automatically by the project generation script, which will prompt the user to choose between GitHub or local-only initialization.
* When the generation script runs, it will:
  1. Add a standard Unity `.gitignore` file
  2. Ask the user: "Would you like me to initialize the repository on GitHub or just locally?"
  3. If GitHub is selected, attempt to create the repository using GitHub CLI (`gh`), or prompt for a manual repository URL
  4. If local-only is selected, just run `git init`
  5. If skip is selected, the user will initialize manually later
* **CRITICAL:** If git initialization or any other automated git exception goes awry, **NEVER delete a git repository from the user's GitHub account**. Always prompt the user with the reason a repo should be deleted, and the user will delete it manually if approved.
* **Cloud Agent Exception:** When operating as a cloud agent in unsupervised VM environments, see `AGENT Cloud Agents Rules.md` for workflow exceptions that allow independent git commits to feature branches.

