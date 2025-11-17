# Game Engine Plugin Rapid Setup

A white-label template repository for cross-platform game engine plugin development. This folder contains all the rules, guidelines, and setup documentation needed to bootstrap new Unity and Unreal plugin projects consistently.

## Contents

### Rules Files (For AGENT/AI Reference)
- **AGENT Embedded Firmware Rules.md** - Guidelines for maintaining embedded firmware examples across cross-platform codebases
- **AGENT Unity Rules.md** - C# code style, automated compilation workflow, and Unity-specific development patterns
- **AGENT Unreal Rules.md** - C++ refactoring rules, build system guidelines, and Unreal Engine best practices

### Setup Documentation
- **CROSS-PLATFORM-GAME-ENGINE-PROJECT-SETUP-GUIDE.md** - Comprehensive guide for repository structure, Unity/Unreal project initialization, and automation recommendations

### Submodules
- **Unity_AutoCompilation/** - Git submodule containing the Unity automated compilation system (Unity-specific only; Unreal uses UBT out-of-the-box)

## Usage

1. **Clone this repository** (or copy the folder) to your new game engine plugin project root
2. **Initialize submodules:**
   ```bash
   git submodule update --init --recursive
   ```
3. **Replace `[PROJECT-NAME]`** placeholders throughout the documentation with your actual project name
4. **Follow the setup guide** to initialize Unity and Unreal repositories
5. **Reference the rules files** when developing to maintain consistency across projects
6. **For Unity projects:** Copy files from `Unity_AutoCompilation/` submodule to your Unity project (see AGENT Unity Rules.md for details)

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
└── [PROJECT-NAME]_Unreal/          ← Unreal project (template)
    └── Plugins/
        └── [PROJECT-NAME]/          ← Unreal plugin repository root
```

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

