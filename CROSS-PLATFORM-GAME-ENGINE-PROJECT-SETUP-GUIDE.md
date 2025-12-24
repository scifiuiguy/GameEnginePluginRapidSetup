# [PROJECT-NAME] Project Setup Guide

## Overview

This guide addresses repository structure, Unity/Unreal project initialization, and automation possibilities for the [PROJECT-NAME] SDK project.

---

## Repository Root Location Recommendations

### Unity Repository
**Recommended:** `[PROJECT-NAME]_Unity/` should be the **Git repository root**

**Structure:**
```
[PROJECT-NAME]_Unity/          ← Git repo root
├── .git/
├── .gitignore
├── README.md
├── LICENSE
├── Assets/
│   └── [PROJECT-NAME]/        ← Your package code here
│       ├── Runtime/
│       ├── Editor/
│       └── package.json  ← Unity Package Manager manifest
├── Packages/
├── ProjectSettings/
└── ...
```

**Rationale:**
- Unity projects are self-contained ecosystems
- Package management works best when the repo root = Unity project root
- Standard Unity `.gitignore` works out-of-the-box
- Developers clone and open directly in Unity Hub
- CI/CD can build/test the project directly

### Unreal Repository
**Recommended:** `Plugins/[PROJECT-NAME]/` should be the **Git repository root** (within an Unreal project)

**Important:** The Unreal project (`[PROJECT-NAME]_Unreal/`) must be created at the **top-level directory** (same level as `GameEnginePluginRapidSetup/`), not inside any subdirectories.

**Structure:**
```
[PROJECT-NAME]/                    ← Project root
├── GameEnginePluginRapidSetup/    ← Setup folder (template files)
└── [PROJECT-NAME]_Unreal/         ← Unreal project (created at top level)
    ├── Plugins/
    │   └── [PROJECT-NAME]/        ← Git repo root
    │       ├── .git/
    │       ├── .gitignore
    │       ├── README.md
    │       ├── LICENSE
    │       ├── [PROJECT-NAME].uplugin
    │       ├── Source/
    │       │   └── [PROJECT-NAME]/
    │       ├── Content/
    │       └── Resources/
    ├── Source/
    ├── Content/
    └── [PROJECT-NAME].uproject
```

**Rationale:**
- Unreal plugins are designed to live in `Plugins/` directory
- Plugin can be version-controlled independently
- Template project can be regenerated or shared separately
- Matches Unreal's plugin management conventions
- **Top-level placement ensures consistent project structure and avoids path confusion**

---

## Unity CLI Project Creation

### Current State
Unity's CLI supports **fully automated project creation**:

1. **Unity Editor Batch Mode:** `Unity.exe -batchmode -createProject <path>` - Fully automated, no user interaction required
2. **Unity Hub CLI:** Requires user interaction (opens GUI dialog)
3. **Template Repository:** Alternative approach for CI/CD (store pre-created template project)

### Recommended Approach

**Option 1: Unity Editor Batch Mode (Fully Automated - Recommended)**
```powershell
# Unity Editor supports -createProject flag in batch mode
& "C:\Program Files\Unity\Hub\Editor\[VERSION]\Editor\Unity.exe" -batchmode -quit -createProject "F:\[PROJECT-NAME]\[PROJECT-NAME]_Unity"
```
- **Pros:** Fully automated, suitable for CI/CD, containers, and automated testing
- **Cons:** Requires Unity Editor installation (not just Unity Hub)
- **Use case:** Automated pipelines, unit testing, containerized builds

**Option 2: Unity Hub CLI (Requires User Interaction)**
```powershell
# Unity Hub opens GUI dialog (user must click "CREATE PROJECT")
& "C:\Program Files\Unity Hub\Unity Hub.exe" --create-project "F:\[PROJECT-NAME]\[PROJECT-NAME]_Unity" --name "[PROJECT-NAME]" --version "[VERSION]"
```
- **Pros:** Pre-fills project name and path
- **Cons:** Requires user to click button in GUI
- **Use case:** Manual project setup when Unity Editor not available

**Option 3: Template Repository (For CI/CD)**
- Store a pre-created Unity project template in a repository
- Clone and customize for new projects
- **Pros:** Fast, consistent, works in any environment
- **Cons:** Requires maintaining template, version updates need template rollup
- **Use case:** High-frequency project creation in CI/CD pipelines

### Unity Package Management Structure

For a Unity package that conforms to Unity Package Manager:

```
[PROJECT-NAME]_Unity/
├── Assets/
│   └── [PROJECT-NAME]/
│       ├── package.json          ← Package manifest
│       ├── Runtime/
│       │   ├── Scripts/
│       │   └── [PROJECT-NAME].asmdef  ← Assembly definition
│       ├── Editor/
│       │   ├── Scripts/
│       │   └── [PROJECT-NAME].Editor.asmdef
│       ├── Samples~/
│       │   └── DemoScene/
│       └── Documentation~/
│           └── [PROJECT-NAME].md
├── Packages/
│   └── manifest.json             ← Project dependencies
└── ProjectSettings/
```

**Key Files:**
- `Assets/[PROJECT-NAME]/package.json` - Defines package metadata, dependencies
- `Assets/[PROJECT-NAME]/Runtime/[PROJECT-NAME].asmdef` - Assembly definition for runtime code
- `Packages/manifest.json` - Project-level package dependencies

---

## Unreal Plugin Structure

### Plugin Creation

Unreal plugins require:
1. `.uplugin` file (JSON manifest)
2. `Source/` directory with module structure
3. `Content/` directory for assets (optional)
4. `Resources/` for icons (optional)

**Standard Plugin Structure:**
```
Plugins/[PROJECT-NAME]/
├── [PROJECT-NAME].uplugin            ← Plugin manifest
├── Source/
│   ├── [PROJECT-NAME]/
│   │   ├── [PROJECT-NAME].Build.cs   ← Build configuration
│   │   ├── [PROJECT-NAME].h
│   │   ├── [PROJECT-NAME].cpp
│   │   └── Public/
│   └── [PROJECT-NAME]Editor/         ← Editor module (optional)
│       ├── [PROJECT-NAME]Editor.Build.cs
│       └── ...
├── Content/
└── Resources/
    └── Icon128.png
```

### Unreal Project Template

You'll need to:
1. Create a template Unreal project (via Unreal Editor)
2. Place the plugin in `Plugins/[PROJECT-NAME]/`
3. Initialize git repo in `Plugins/[PROJECT-NAME]/` (not the project root)

---

## Automation Pipeline Recommendations

### What Can Be Automated

✅ **Can Automate:**
- Folder structure creation
- Basic Unity project files (`ProjectVersion.txt`, minimal `ProjectSettings.asset`)
- Unity package structure (`package.json`, `.asmdef` files)
- Unreal plugin structure (`.uplugin`, `.Build.cs` templates)
- `.gitignore` files (Unity/Unreal standard templates)
- Initial README/LICENSE files
- Git repository initialization

❌ **Cannot Fully Automate:**
- Unity Editor initialization (requires opening project)
- Unreal project creation (requires Unreal Editor)
- Engine-specific metadata generation (Unity/Unreal generate these)

### Proposed Automation Script

Create a PowerShell script `Setup-[PROJECT-NAME]Projects.ps1` that:

1. **Unity Setup:**
   - Creates `[PROJECT-NAME]_Unity/` structure
   - Generates minimal Unity project files
   - Creates package structure with `package.json`
   - Adds Unity `.gitignore`
   - Initializes git repo
   - **Note:** User must open in Unity Editor to complete initialization

2. **Unreal Setup:**
   - Creates template plugin structure in `Plugins/[PROJECT-NAME]/`
   - Generates `.uplugin` file
   - Creates module structure with `.Build.cs`
   - Adds Unreal `.gitignore`
   - Initializes git repo in plugin directory
   - **Note:** User must create Unreal project manually, then copy plugin

### Alternative: Template Repositories

Consider creating:
- `unity-package-template` - Clone and rename for new Unity packages
- `unreal-plugin-template` - Clone and rename for new Unreal plugins

This avoids fighting with engine metadata generation.

---

## Next Steps

1. **Decide on automation level:**
   - Full script-based setup (requires manual Unity/Unreal Editor steps)
   - Template repositories (clone and customize)
   - Hybrid approach (script + templates)

2. **Unity Setup:**
   - Create project structure manually or via script
   - Open in Unity Editor to initialize
   - Configure package structure
   - Initialize git repo

3. **Unreal Setup:**
   - Create Unreal project template
   - Create plugin structure in `Plugins/[PROJECT-NAME]/`
   - Initialize git repo in plugin directory

4. **Documentation:**
   - Add setup instructions to main README
   - Document any automation scripts
   - Include troubleshooting for common issues

---

## Questions to Resolve

1. **Unity Package vs. Project:**
   - Are you building a Unity **package** (distributed via UPM) or a Unity **project** (standalone application)?
   - If package: repo structure should match UPM conventions
   - If project: standard Unity project structure is fine

2. **Unreal Project Template:**
   - Should the template project be version-controlled?
   - Or just the plugin, with project as a separate artifact?

3. **Automation Script Location:**
   - Should automation scripts live in the root `[PROJECT-NAME]/` directory?
   - Or in a separate `scripts/` or `tools/` directory?

---

## Unity CLI Answer

**Short Answer:** Unity Editor **supports fully automated project creation** via `-batchmode -createProject` flags. Unity Hub CLI requires user interaction.

**Best Practice:** 
- **For automation/CI/CD:** Use Unity Editor directly: `Unity.exe -batchmode -quit -createProject <path>`
- **For manual setup:** Use Unity Hub (pre-fills fields but requires button click)
- **For high-frequency CI/CD:** Consider template repository approach (clone pre-created project)

