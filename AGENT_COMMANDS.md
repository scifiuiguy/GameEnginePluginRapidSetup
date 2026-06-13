# AGENT Commands Reference

This document defines standard commands that AGENT should recognize when working with the GameEnginePluginRapidSetup template.

## Project Generation Commands

### Command-to-Script Mapping

| Command Phrase | Script Workflow |
| --- | --- |
| "Generate this new plugin" | `.\generate_unity_project.ps1 -UnityLayout Package` then `.\generate_unreal_project.ps1` |
| "Generate this new unity plugin" | `.\generate_unity_project.ps1 -UnityLayout Package` |
| "Generate this new unity package" | `.\generate_unity_project.ps1 -UnityLayout Package` |
| "Generate Unity plugin/package" | `.\generate_unity_project.ps1 -UnityLayout Package` |
| "Create a new Unity plugin/package for me" | `.\generate_unity_project.ps1 -UnityLayout Package` |
| "Generate Unity project" | `.\generate_unity_project.ps1 -UnityLayout Project` |
| "Create a new Unity project for me" | `.\generate_unity_project.ps1 -UnityLayout Project` |
| "Generate this new unreal plugin" | `.\generate_unreal_project.ps1` |
| "Generate Unreal project" | `.\generate_unreal_project.ps1` |

### Command Variations

- **"Generate this new plugin"** → Generate both Unity AND Unreal projects
- **"Generate this new unity plugin"** → Generate Unity package/plugin workflow only
- **"Generate this new unity package"** → Generate Unity package/plugin workflow only
- **"Generate Unity plugin/package"** → Generate Unity package/plugin workflow only
- **"Create a new Unity plugin/package for me"** → Generate Unity package/plugin workflow only
- **"Generate this new unreal plugin"** → Generate Unreal project only
- **"Generate Unity project"** → Generate Unity project workflow only
- **"Create a new Unity project for me"** → Generate Unity project workflow only
- **"Generate Unreal project"** → Generate Unreal project only

### Unity Workflow Mapping (Project vs Package)

For Unity requests, AGENT must map phrasing to `-UnityLayout` explicitly:

- **Project phrasing** (`"Generate Unity project"`, `"Create a new Unity project for me"`)  
  → run `generate_unity_project.ps1 -UnityLayout Project`
- **Package/plugin phrasing** (`"Generate this new unity plugin"`, `"Generate this new unity package"`, `"Generate Unity plugin/package"`, `"Create a new Unity plugin/package for me"`)  
  → run `generate_unity_project.ps1 -UnityLayout Package`

### "Generate this new plugin" / Unity-specific commands

When the user requests to generate a Unity project (any of the above Unity-specific commands), AGENT should:

1. **Verify the context:**
   - Confirm the script is being run from `[Project-Name]/GameEnginePluginRapidSetup/` directory
   - Verify the parent directory exists and is the project root

2. **Execute Unity project generation:**
   ```powershell
   # Project mode
   .\generate_unity_project.ps1 -UnityLayout Project
   ```
   For package/plugin workflow:
   ```powershell
   .\generate_unity_project.ps1 -UnityLayout Package
   ```
   Or with Unity version:
   ```powershell
   .\generate_unity_project.ps1 -UnityLayout [Project|Package] -UnityVersion [VERSION]
   ```

3. **Handle existing directories:**
   - **If target directory is empty:** Automatically delete and recreate (no user confirmation needed)
   - **If target directory contains files:** Cancel workflow, inform user that AGENT has been instructed not to destroy existing files, and ask how to proceed (remove manually, use different name, or continue with existing)

4. **Project creation method:**
   - **Preferred (fully automated):** Uses Unity Editor directly with `-batchmode -createProject` flags
     - No user interaction required
     - Suitable for CI/CD, containers, and automated testing
     - Creates project silently and exits
   - **Fallback (requires user interaction):** Uses Unity Hub if Unity Editor not found
     - Launches Unity Hub with project name and path pre-filled
     - **User action required:** User must click "CREATE PROJECT" button
     - Script polls for project directory creation (waits up to 5 minutes, checks every 2 seconds)
   - Checks for Unity project structure (ProjectSettings/ or Assets/ folders)
   - Reports success once project is detected

5. **Git initialization (project/plugin creation):**
   - During project or plugin **creation**, AGENT may run `git init` and add the standard `.gitignore` **without asking** (see **AGENT Git Permissions** below).
   - **Remote setup** (GitHub repo creation, `git push`, initial commit that affects remote) **requires user permission**.
   - The generation script may still prompt for GitHub vs local vs skip when run interactively; AGENT manual setup follows **AGENT Git Permissions**.
   - After initialization, user handles ongoing git operations unless explicitly requested.

6. **Next steps (inform user):**
   - **Project mode:** open `[PROJECT-NAME]_Unity` in Unity Hub
   - **Package mode:** open `[PROJECT-NAME]_Unity_Plugin_Test` in Unity Hub and iterate against local package repo `[PROJECT-NAME]_Unity`
   - Copy files from `Unity_AutoCompilation/` submodule (see AGENT Unity Rules.md)
   - Follow the setup guide for package structure configuration

### "Generate Unreal project" / "Generate this new unreal plugin"

When the user requests to generate an Unreal project (any of the above Unreal-specific commands), AGENT should:

1. **Verify the context:**
   - Confirm the script is being run from `[Project-Name]/GameEnginePluginRapidSetup/` directory
   - Verify the parent directory exists and is the project root

2. **Execute Unreal project generation:**
   ```powershell
   .\generate_unreal_project.ps1
   ```
   Or with parameters:
   ```powershell
   .\generate_unreal_project.ps1 -UnrealVersion 5.3 -Template Blank
   ```

3. **Handle existing directories:**
   - **If target directory is empty:** Automatically delete and recreate (no user confirmation needed)
   - **If target directory contains files:** Cancel workflow, inform user that AGENT has been instructed not to destroy existing files, and ask how to proceed

4. **Project creation method:**
   - Creates minimal Unreal project structure (.uproject file, Source module, Content folder)
   - Uses UnrealBuildTool (UBT) to generate Visual Studio project files
   - Fully automated - no user interaction required
   - Creates C++ project structure by default

5. **Verify project creation:**
   - Checks for .uproject file
   - Verifies Source module structure
   - Confirms UBT project file generation

6. **Git initialization (project/plugin creation):**
   - During project or plugin **creation**, AGENT may run `git init` and add the standard `.gitignore` **without asking** (see **AGENT Git Permissions** below).
   - **Note:** For Unreal projects, the git repository is initialized in `Plugins/[Project-Name]/`, not the project root.
   - **Remote setup** (GitHub repo creation, `git push`, initial commit that affects remote) **requires user permission**.
   - The generation script may still prompt for GitHub vs local vs skip when run interactively; AGENT manual setup follows **AGENT Git Permissions**.
   - After initialization, user handles ongoing git operations unless explicitly requested.

7. **Next steps (inform user):**
   - Open the .uproject file in Unreal Editor
   - Create plugin structure in `Plugins/[Project-Name]/` (see setup guide)

## Command Patterns

### Standard Phrases to Recognize

- **"Generate this new plugin"** → Run both `generate_unity_project.ps1` AND `generate_unreal_project.ps1`
- **"Generate this new unity plugin"** → Run `generate_unity_project.ps1 -UnityLayout Package`
- **"Generate this new unity package"** → Run `generate_unity_project.ps1 -UnityLayout Package`
- **"Generate Unity plugin/package"** → Run `generate_unity_project.ps1 -UnityLayout Package`
- **"Create a new Unity plugin/package for me"** → Run `generate_unity_project.ps1 -UnityLayout Package`
- **"Generate this new unreal plugin"** → Run `generate_unreal_project.ps1` only
- **"Generate Unity project"** → Run `generate_unity_project.ps1 -UnityLayout Project`
- **"Create a new Unity project for me"** → Run `generate_unity_project.ps1 -UnityLayout Project`
- **"Generate Unreal project"** → Run `generate_unreal_project.ps1` only
- **"Set up [Project-Name]"** → Full project setup workflow
- **"Initialize [Project-Name]"** → Full project initialization

## Workflow Context

When AGENT sees these commands, it should understand:

1. **Current State:** User has cloned GameEnginePluginRapidSetup into a new project directory
2. **Goal:** Generate the Unity (and eventually Unreal) project structure
3. **Location:** Scripts are in `GameEnginePluginRapidSetup/` subdirectory
4. **Output:** Projects should be created in parent directory as `[Project-Name]_Unity/` and `[Project-Name]_Unreal/`
   - In Unity **Package** mode, output is split into `[Project-Name]_Unity/` (package repo) and `[Project-Name]_Unity_Plugin_Test/` (test project)

## Script Location

All generation scripts are located in:
```
[Project-Name]/
└── GameEnginePluginRapidSetup/
    ├── generate_unity_project.ps1
    ├── generate_unity_project.bat
    ├── generate_unreal_project.ps1
    └── generate_unreal_project.bat
```

## Error Handling

### Existing Directory with Files

If the target directory exists and contains files, AGENT must:
1. **Cancel the workflow immediately** - Do not delete or modify existing files
2. **Inform the user** that AGENT has been instructed not to destroy existing files
3. **Present options:**
   - Remove the existing directory manually and run the script again
   - Use a different project name
   - Continue with the existing directory (manual setup required)

### Other Errors

If generation fails for other reasons, AGENT should:
1. Report the specific error from the script
2. Provide fallback instructions (manual Unity Hub creation)
3. Reference the CROSS-PLATFORM-GAME-ENGINE-PROJECT-SETUP-GUIDE.md for manual setup steps

## Example Interactions

### Example 1: Generate Both Projects

**User:** "Generate this new plugin"

**AGENT should:**
1. Confirm current directory structure
2. Run `.\generate_unity_project.ps1` and wait for completion (script exits with code 0)
3. Report Unity project success/failure
4. Run `.\generate_unreal_project.ps1` and wait for completion (script exits with code 0)
5. Report Unreal project success/failure
6. Continue with next pipeline tasks (e.g., copy submodule files, initialize git repos, etc.)
7. Provide next steps for both projects

### Example 2: Generate Unity Only

**User:** "Generate this new unity plugin"

**AGENT should:**
1. Confirm current directory structure
2. Run `.\generate_unity_project.ps1 -UnityLayout Package`
3. Report success/failure
4. Provide next steps for Unity package + test project setup

### Example 2b: Generate Unity Project Only

**User:** "Create a new Unity project for me"

**AGENT should:**
1. Confirm current directory structure
2. Run `.\generate_unity_project.ps1 -UnityLayout Project`
3. Report success/failure
4. Provide next steps for Unity project setup

### Example 3: Generate Unreal Only

**User:** "Generate this new unreal plugin"

**AGENT should:**
1. Confirm current directory structure
2. Run `.\generate_unreal_project.ps1`
3. Report success/failure
4. Provide next steps for Unreal project setup

## AGENT Git Permissions

Git rules distinguish **local repo bootstrap** (allowed on creation) from **commits and remote operations** (require permission).

### Allowed Without Asking (Project/Plugin Creation Only)

During **initial project or plugin creation**, AGENT may:

- Run `git init` in the appropriate repo root
- Add the standard `.gitignore` (`unity.gitignore` or `unreal.gitignore`)
- Copy README/license templates into the new repo

This applies when AGENT is executing a create/generate workflow (e.g. `generate_unity_project.ps1`, `generate_unreal_project.ps1`, or equivalent manual setup immediately after generation).

### Requires User Permission

AGENT must **not** perform these unless the user explicitly requests them:

- `git commit` (local or otherwise)
- `git push`
- Creating a GitHub remote repository
- Any operation that affects the **remote** repository
- Branch operations intended for sharing (push, merge to shared branches, force push, etc.)

**Clarification:** The restriction is **commits and pushes** — not `git init` or `.gitignore` setup during creation. Local commits are not automatic; ask first unless the user has explicitly requested a commit.

### Safety Rules (Always)

- **NEVER** delete a git repository from the user's GitHub account without explicit approval.
- If git initialization fails, report the error and let the user decide next steps.

### Cloud Agent Exception

When operating as a cloud agent in unsupervised VM environments, see `AGENT Cloud Agents Rules.md` for feature-branch commit exceptions.

---

## Python Script Bulk-Edit Policy

AGENT must **not** silently substitute a Python (or other shell) transformation script for direct editing of a text-based file when a large sequence of changes is requested.

### Why This Matters

Agents sometimes generate Python scripts to transform large files instead of editing them directly — often as a token-efficiency technique. In practice:

- The failure rate for such scripts is **very high** (often >50%).
- Recovery is poor because the agent deliberately avoided loading the full file into context.
- Reverting damaged files is difficult without a known-good checkpoint.

### Required Workflow Before Python Bulk Edits

If AGENT is considering a Python script (or similar) to process **any text-based file** (source, shaders, markdown, config, JSON, YAML, etc.):

1. **Prefer direct edit** when the file is reasonably sized or changes are localized.
2. If a script still seems necessary, **ask the user for permission to create a local git commit** of the target file(s) first — so reversion is one command away if the script corrupts content.
3. Do **not** run the script until the user approves that commit (or explicitly waives the safety commit).
4. After running the script, verify the result (diff, spot-check, compile) before proceeding.

### When Scripts Are Acceptable Without This Ask

- The user **explicitly requested** a Python/script-based transformation.
- The file is **generated output** not yet committed, with no risk to irreplaceable work.
- The script only **reads** the file and does not write back to it.

---
