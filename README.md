# Game Engine Plugin Rapid Setup

A white-label template repository for cross-platform game engine plugin development. This folder contains all the rules, guidelines, and setup documentation needed to bootstrap new Unity and Unreal plugin projects consistently.

## Contents

### Rules Files (For AGENT/AI Reference)
- **AGENT Embedded Firmware Rules.md** - Guidelines for maintaining embedded firmware examples across cross-platform codebases
- **AGENT Unity Rules.md** - C# code style, automated compilation workflow, and Unity-specific development patterns
- **AGENT Unreal Rules.md** - C++ refactoring rules, build system guidelines, and Unreal Engine best practices
- **AGENT Cloud Agents Rules.md** - Workflow exceptions for cloud agent operations in unsupervised VM environments

### Setup Documentation
- **CROSS-PLATFORM-GAME-ENGINE-PROJECT-SETUP-GUIDE.md** - Comprehensive guide for repository structure, Unity/Unreal project initialization, and automation recommendations
- **AGENT_COMMANDS.md** - Standard commands for AI agents to understand project generation workflows

### Submodules
- **Unity_AutoCompilation/** - Git submodule containing the Unity automated compilation system (Unity-specific only; Unreal uses UBT out-of-the-box)
- **TurboLink/** - Git submodule containing TurboLink gRPC plugin for Unreal Engine (Unreal-specific only; Unity uses Grpc.Net.Client)

## Usage

### Quick Start (AI-Assisted)

When starting a new project, you can tell your AI assistant:
- **"Generate this new plugin"** - Automatically runs both Unity AND Unreal project generation scripts
- **"Generate this new unity plugin"** - Runs Unity project generation only (`generate_unity_project.ps1`)
- **"Generate this new unreal plugin"** - Runs Unreal project generation only (`generate_unreal_project.ps1`)
- **"Generate Unity project"** - Alternative phrase for Unity-only generation
- **"Generate Unreal project"** - Alternative phrase for Unreal-only generation
- The AI will execute the appropriate script(s) and guide you through next steps

### Manual Setup

1. **Clone this repository** (or copy the folder) to your new game engine plugin project root
2. **Initialize submodules:**
   ```bash
   git submodule update --init --recursive
   ```
3. **Generate projects:**
   ```powershell
   # Unity project (fully automated)
   .\GameEnginePluginRapidSetup\generate_unity_project.ps1
   
   # Unreal project (creates minimal structure)
   .\GameEnginePluginRapidSetup\generate_unreal_project.ps1
   ```
4. **Replace `[PROJECT-NAME]`** placeholders throughout the documentation with your actual project name
5. **Follow the setup guide** to initialize Unity and Unreal repositories
6. **Reference the rules files** when developing to maintain consistency across projects
7. **For Unity projects:** Copy files from `Unity_AutoCompilation/` submodule to your Unity project (see AGENT Unity Rules.md for details)

## Purpose

This template enables:
- **Consistent project structure** across all game engine plugins
- **Standardized development workflows** for Unity and Unreal
- **Reusable automation scripts** (to be added)
- **Cross-platform firmware example management** (when applicable)
- **AI-assisted development** with clear coding standards

## Repository Structure

When using this template, your project structure should follow:

```
[PROJECT-NAME]/
├── GameEnginePluginRapidSetup/     ← This folder (template files)
├── [PROJECT-NAME]_Unity/            ← Unity repository root
└── [PROJECT-NAME]_Unreal/          ← Unreal project (created at top level)
    └── Plugins/
        └── [PROJECT-NAME]/          ← Unreal plugin repository root
```

**Important:** The Unreal project must be created at the **top-level directory** (same level as `GameEnginePluginRapidSetup/`), not inside any subdirectories. The generation script will automatically place it at the correct location.

### Nested Directory Structures

**Note:** The `GameEnginePluginRapidSetup` repository may be nested inside one or more subdirectories under the project root. For example:

```
[PROJECT-NAME]/                          ← IDE workspace root
├── Setup/
│   └── GameEnginePluginRapidSetup/      ← Nested one level
│       └── ...
├── [PROJECT-NAME]_Unity/
└── [PROJECT-NAME]_Unreal/
```

Or even deeper nesting:

```
[PROJECT-NAME]/                          ← IDE workspace root
├── Tools/
│   └── Setup/
│       └── GameEnginePluginRapidSetup/ ← Nested two levels
│           └── ...
├── [PROJECT-NAME]_Unity/
└── [PROJECT-NAME]_Unreal/
```

**Project Name Detection:** The project name used for creating Unity and Unreal projects should always be derived from the **top-most root directory selected by the IDE** (the workspace root), not from the immediate parent of `GameEnginePluginRapidSetup`. 

The generation scripts automatically detect the workspace root using the following methods (in order of priority):
1. **IDE Environment Variables:** If available, uses `CURSOR_WORKSPACE_ROOT` or `VSCODE_WORKSPACE_ROOT` environment variables set by the IDE
2. **Directory Navigation:** Walks up the directory tree, handling common nested structures (e.g., `Setup/GameEnginePluginRapidSetup/`)
3. **Fallback:** Uses the immediate parent directory if no workspace root can be determined

This ensures that projects are always created with the correct name and at the correct location, regardless of how deeply `GameEnginePluginRapidSetup` is nested.

## White-Labeling

All files in this folder use `[PROJECT-NAME]` as a placeholder. When setting up a new project:

1. Search and replace `[PROJECT-NAME]` with your actual project name
2. Update any path examples to match your directory structure
3. Customize rules files if your project has specific requirements

## Contributing to This Template

This template is designed to evolve. As you develop new game engine plugins:

- **Document new patterns** that work well across projects
- **Add automation scripts** that can be reused
- **Improve the setup guide** based on real-world experience
- **Update rules files** with lessons learned

The goal is to make each new plugin project faster to bootstrap than the last.

---

**Note:** This folder should be version-controlled in its own repository, separate from individual plugin projects. Clone it when starting a new plugin, then customize for that specific project.

