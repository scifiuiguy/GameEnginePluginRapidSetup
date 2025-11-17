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

**Structure:**
```
[UnrealProject]/          ← Template project (not in git)
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
└── ...
```

**Rationale:**
- Unreal plugins are designed to live in `Plugins/` directory
- Plugin can be version-controlled independently
- Template project can be regenerated or shared separately
- Matches Unreal's plugin management conventions

---

## Unity CLI Project Creation

### Current State
Unity's CLI has **limited project creation capabilities**:

1. **Deprecated Method:** `Unity -createProject <path>` (removed in Unity 2019.3+)
2. **Unity Hub CLI:** Limited availability, not officially documented
3. **Manual Creation:** Most reliable method

### Recommended Approach

**Option 1: Manual Creation (Most Reliable)**
1. Create folder structure manually
2. Add minimal Unity project files
3. Open in Unity Editor (auto-initializes)

**Option 2: Unity Hub CLI (If Available)**
```powershell
# Check if Unity Hub CLI is available
& "C:\Program Files\Unity Hub\Unity Hub.exe" --help

# Create project (if supported)
& "C:\Program Files\Unity Hub\Unity Hub.exe" --createProject "F:\[PROJECT-NAME]\[PROJECT-NAME]_Unity"
```

**Option 3: Template-Based Script**
Create a PowerShell script that:
- Creates folder structure
- Generates `ProjectSettings/ProjectVersion.txt`
- Generates `ProjectSettings/ProjectSettings.asset` (minimal)
- Creates `Assets/` directory
- Initializes package structure

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

**Short Answer:** Unity CLI **cannot reliably create projects** in modern Unity versions. The `-createProject` flag was deprecated.

**Best Practice:** Create folder structure + minimal files via script, then open in Unity Editor to complete initialization. This is the most reliable cross-platform approach.

