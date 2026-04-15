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

5. **Git initialization (automated):**
   - Script automatically adds a standard Unity `.gitignore` file
   - Script prompts user: "Would you like me to initialize the repository on GitHub or just locally?"
   - **Option 1 (GitHub):** Attempts to create GitHub repository using GitHub CLI (`gh`), or prompts for manual repository URL
   - **Option 2 (Local only):** Runs `git init` in the project directory
   - **Option 3 (Skip):** User will initialize manually later
   - **Note:** After initialization, user handles all git operations (add, commit, push, branch). AGENT should NOT perform git operations unless explicitly requested.

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

6. **Git initialization (automated):**
   - Script automatically adds a standard Unreal `.gitignore` file to the project root
   - **Note:** For Unreal projects, the git repository is initialized in `Plugins/[Project-Name]/`, not the project root
   - Script prompts user: "Would you like me to initialize the repository on GitHub or just locally?"
   - **Option 1 (GitHub):** Attempts to create GitHub repository using GitHub CLI (`gh`), or prompts for manual repository URL
   - **Option 2 (Local only):** Runs `git init` in `Plugins/[Project-Name]/`
   - **Option 3 (Skip):** User will initialize manually later
   - **Note:** After initialization, user handles all git operations (add, commit, push, branch). AGENT should NOT perform git operations unless explicitly requested.

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

