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

## Code Smells to Watch For

* Methods with `"InitializeX"` / `"ShutdownX"` pairs that just call `X->Initialize()` / `X->Shutdown()` - remove them.
* Methods that directly access registry/buffer that a service also uses - move to service.
* Switch statements that appear in multiple places (construction, usage, cleanup) - use factory pattern.
* Controller methods that are just "get service, call service method" - remove wrapper, expose service accessor.
* Friend declarations that are only needed because wrapper methods exist - remove friend and wrapper.

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

* Controllers are orchestrators, not implementers.
* Services are domain experts, not general-purpose utilities.
* Interfaces enable polymorphism, factories enable clean construction.
* The goal is a thin controller that composes services, not a fat controller that does everything.

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

