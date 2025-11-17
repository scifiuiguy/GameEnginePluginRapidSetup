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

## Interface Naming Conventions

* Prefer verb-style interface names (e.g., `IBridgeEvents`, `IDMXTransport`) over adjective-style names (e.g., `IEventBridgeable`, `IDMXTransportable`).
* Verb-style names describe what the interface does, which is more idiomatic in C# and C++.
* This keeps interface names concise and action-oriented, consistent with common .NET and C++ patterns.

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

