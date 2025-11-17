# Unreal Engine Project Generation Script
# Generates an Unreal Engine project using Unreal Editor or template approach
# Assumes this script is in: [Project-Name]/GameEnginePluginRapidSetup/
# Creates project at: [Project-Name]/[Project-Name]_Unreal/

param(
    [string]$UnrealVersion = "",
    [string]$ProjectName = "",
    [string]$Template = "Blank",
    [ValidateSet("GitHub", "Local", "Skip", "")]
    [string]$GitInit = ""
)

# Get the project name from parent directory if not provided
if ([string]::IsNullOrEmpty($ProjectName)) {
    $CurrentDir = Get-Location
    $ParentDir = Split-Path -Path $CurrentDir -Parent
    $ProjectName = Split-Path -Path $ParentDir -Leaf
    Write-Host "Detected project name: $ProjectName" -ForegroundColor Cyan
} else {
    $CurrentDir = Get-Location
    $ParentDir = Split-Path -Path $CurrentDir -Parent
}

# Construct project path
$ProjectPath = Join-Path $ParentDir "${ProjectName}_Unreal"
$UProjectFile = Join-Path $ProjectPath "${ProjectName}.uproject"

# Check if project already exists
if (Test-Path $ProjectPath) {
    $ExistingFiles = Get-ChildItem -Path $ProjectPath -Force -ErrorAction SilentlyContinue
    
    if ($ExistingFiles.Count -eq 0) {
        # Directory is empty - safe to delete and recreate
        Write-Host "Found empty directory at $ProjectPath" -ForegroundColor Yellow
        Write-Host "Removing empty directory and proceeding with project creation..." -ForegroundColor Cyan
        Remove-Item -Path $ProjectPath -Force -ErrorAction Stop
    } else {
        # Directory contains files - must ask user
        Write-Host "ERROR: Project directory already exists and contains files: $ProjectPath" -ForegroundColor Red
        Write-Host "File count: $($ExistingFiles.Count)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "AGENT has been instructed not to destroy existing files." -ForegroundColor Yellow
        Write-Host "Please choose how to proceed:" -ForegroundColor Cyan
        Write-Host "  1. Remove the existing directory manually and run this script again" -ForegroundColor White
        Write-Host "  2. Use a different project name" -ForegroundColor White
        Write-Host "  3. Continue with the existing directory (manual setup required)" -ForegroundColor White
        exit 1
    }
}

# Find Unreal Editor executable
$UnrealEditorExe = $null
$UnrealBasePaths = @(
    "${env:ProgramFiles}\Epic Games",
    "${env:ProgramFiles(x86)}\Epic Games"
)

# Search for Unreal Engine installations
$UnrealVersions = @()
foreach ($BasePath in $UnrealBasePaths) {
    if (Test-Path $BasePath) {
        $UEDirs = Get-ChildItem -Path $BasePath -Directory -Filter "UE_*" -ErrorAction SilentlyContinue | Sort-Object Name -Descending
        foreach ($UEDir in $UEDirs) {
            $EditorPath = Join-Path $UEDir.FullName "Engine\Binaries\Win64\UnrealEditor.exe"
            if (Test-Path $EditorPath) {
                $Version = $UEDir.Name
                $UnrealVersions += @{
                    Version = $Version
                    EditorPath = $EditorPath
                }
            }
        }
    }
}

# Select Unreal version
if ($UnrealVersions.Count -eq 0) {
    Write-Host "ERROR: Unreal Engine Editor not found in standard locations." -ForegroundColor Red
    Write-Host "Searched locations:" -ForegroundColor Yellow
    foreach ($BasePath in $UnrealBasePaths) {
        Write-Host "  - $BasePath\UE_*" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Please install Unreal Engine or specify the path manually." -ForegroundColor Yellow
    exit 1
}

# Use specified version or latest
if (-not [string]::IsNullOrEmpty($UnrealVersion)) {
    $SelectedVersion = $UnrealVersions | Where-Object { $_.Version -eq "UE_$UnrealVersion" -or $_.Version -like "*$UnrealVersion*" } | Select-Object -First 1
    if ($null -eq $SelectedVersion) {
        Write-Host "WARNING: Specified Unreal version not found. Using latest version." -ForegroundColor Yellow
        $SelectedVersion = $UnrealVersions[0]
    }
} else {
    $SelectedVersion = $UnrealVersions[0]
}

$UnrealEditorExe = $SelectedVersion.EditorPath
$DetectedVersion = $SelectedVersion.Version

Write-Host "Found Unreal Editor: $UnrealEditorExe" -ForegroundColor Green
Write-Host "Unreal Version: $DetectedVersion" -ForegroundColor Cyan

Write-Host ""
Write-Host "Creating Unreal Engine project..." -ForegroundColor Cyan
Write-Host "  Project Name: $ProjectName" -ForegroundColor White
Write-Host "  Project Path: $ProjectPath" -ForegroundColor White
Write-Host "  Template: $Template" -ForegroundColor White
Write-Host "  Unreal Version: $DetectedVersion" -ForegroundColor White
Write-Host ""

# Create project directory
New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null

# Create minimal .uproject file
# Unreal projects require a .uproject file with specific structure
$UProjectContent = @{
    FileVersion = 3
    EngineAssociation = $DetectedVersion
    Category = ""
    Description = ""
    Modules = @(
        @{
            Name = $ProjectName
            Type = "Runtime"
            LoadingPhase = "Default"
        }
    )
    Plugins = @()
    TargetPlatforms = @()
} | ConvertTo-Json -Depth 10

# Write .uproject file
$UProjectContent | Out-File -FilePath $UProjectFile -Encoding UTF8

Write-Host "Created .uproject file: $UProjectFile" -ForegroundColor Green

# Create basic project structure
$Directories = @(
    "Content",
    "Source\$ProjectName",
    "Config",
    "Plugins"
)

foreach ($Dir in $Directories) {
    $FullPath = Join-Path $ProjectPath $Dir
    New-Item -ItemType Directory -Path $FullPath -Force | Out-Null
}

# Create minimal Source module files
$SourceDir = Join-Path $ProjectPath "Source\$ProjectName"
$BuildCsFile = Join-Path $SourceDir "$ProjectName.Build.cs"
$MainHeaderFile = Join-Path $SourceDir "$ProjectName.h"
$MainCppFile = Join-Path $SourceDir "$ProjectName.cpp"

# Create Build.cs file
$BuildCsContent = @"
using UnrealBuildTool;

public class $ProjectName : ModuleRules
{
    public $ProjectName(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;
        
        PublicDependencyModuleNames.AddRange(new string[] { "Core", "CoreUObject", "Engine" });
        
        PrivateDependencyModuleNames.AddRange(new string[] { });
    }
}
"@
$BuildCsContent | Out-File -FilePath $BuildCsFile -Encoding UTF8

# Create main header file
$HeaderContent = @"
#pragma once

#include "CoreMinimal.h"
"@
$HeaderContent | Out-File -FilePath $MainHeaderFile -Encoding UTF8

# Create main cpp file
$CppContent = @"
#include "$ProjectName.h"
#include "Modules/ModuleManager.h"

IMPLEMENT_PRIMARY_GAME_MODULE( FDefaultGameModuleImpl, $ProjectName, "$ProjectName" );
"@
$CppContent | Out-File -FilePath $MainCppFile -Encoding UTF8

Write-Host "Created basic project structure and source files." -ForegroundColor Green

# Generate project files using UBT
Write-Host ""
Write-Host "Generating Visual Studio project files..." -ForegroundColor Cyan

# Construct UBT path from Unreal Editor path
# UnrealEditor.exe is at: Engine\Binaries\Win64\UnrealEditor.exe
# UBT is at: Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe
$EngineBinariesDir = Split-Path -Path $UnrealEditorExe -Parent
$EngineDir = Split-Path -Path $EngineBinariesDir -Parent
$UBTPath = Join-Path $EngineDir "Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"

# Also try direct path based on detected version
$DirectUBTPath = Join-Path "${env:ProgramFiles}\Epic Games\$DetectedVersion\Engine\Binaries\DotNET\UnrealBuildTool" "UnrealBuildTool.exe"

if (Test-Path $UBTPath) {
    $FinalUBTPath = $UBTPath
} elseif (Test-Path $DirectUBTPath) {
    $FinalUBTPath = $DirectUBTPath
} else {
    $FinalUBTPath = $null
}

if ($null -ne $FinalUBTPath -and (Test-Path $FinalUBTPath)) {
    try {
        $UBTArgs = @(
            "-projectfiles",
            "-project=`"$UProjectFile`"",
            "-game",
            "-rocket",
            "-progress"
        )
        
        Write-Host "Running UnrealBuildTool..." -ForegroundColor Cyan
        $UBTProcess = Start-Process -FilePath $FinalUBTPath -ArgumentList $UBTArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\UBT_Output.log" -RedirectStandardError "$env:TEMP\UBT_Error.log"
        
        # Ensure process has fully terminated
        if (-not $UBTProcess.HasExited) {
            Write-Host "Waiting for UBT to complete..." -ForegroundColor Yellow
            $UBTProcess.WaitForExit(60000) # Wait up to 60 seconds
            if (-not $UBTProcess.HasExited) {
                Write-Host "WARNING: UBT process did not exit within timeout. Terminating..." -ForegroundColor Yellow
                $UBTProcess.Kill()
                Start-Sleep -Seconds 1
            }
        }
        
        if ($UBTProcess.ExitCode -eq 0) {
            Write-Host "SUCCESS: Visual Studio project files generated." -ForegroundColor Green
        } else {
            Write-Host "WARNING: UBT exited with code $($UBTProcess.ExitCode). Project files may not be generated." -ForegroundColor Yellow
            Write-Host "Check logs: $env:TEMP\UBT_Output.log and $env:TEMP\UBT_Error.log" -ForegroundColor Gray
        }
    } catch {
        Write-Host "WARNING: Failed to generate project files with UBT: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "You can generate them manually by right-clicking the .uproject file and selecting 'Generate Visual Studio project files'." -ForegroundColor Gray
    }
} else {
    Write-Host "WARNING: UnrealBuildTool not found. Project files not generated." -ForegroundColor Yellow
    Write-Host "You can generate them manually by right-clicking the .uproject file and selecting 'Generate Visual Studio project files'." -ForegroundColor Gray
}

Write-Host ""
Write-Host "SUCCESS: Unreal Engine project created at $ProjectPath" -ForegroundColor Green

# Ask user about git initialization (if not provided as parameter)
# Note: For Unreal, git repo should be in Plugins/$ProjectName/, not project root
$PluginDir = Join-Path $ProjectPath "Plugins\$ProjectName"

# Add .gitignore file to plugin directory (where git repo will be)
$GitIgnoreSource = Join-Path $PSScriptRoot "unreal.gitignore"
$GitIgnoreDest = Join-Path $PluginDir ".gitignore"

if (Test-Path $GitIgnoreSource) {
    # Ensure plugin directory exists
    if (-not (Test-Path $PluginDir)) {
        New-Item -ItemType Directory -Path $PluginDir -Force | Out-Null
    }
    Copy-Item -Path $GitIgnoreSource -Destination $GitIgnoreDest -Force
    Write-Host "Added .gitignore file to plugin directory." -ForegroundColor Green
} else {
    Write-Host "WARNING: unreal.gitignore template not found at $GitIgnoreSource" -ForegroundColor Yellow
}

# Add README template to plugin directory and replace placeholders
$ReadmeSource = Join-Path $PSScriptRoot "Unreal_README_template.md"
$ReadmeDest = Join-Path $PluginDir "README.md"

if (Test-Path $ReadmeSource) {
    # Ensure plugin directory exists
    if (-not (Test-Path $PluginDir)) {
        New-Item -ItemType Directory -Path $PluginDir -Force | Out-Null
    }
    
    # Read template content
    $ReadmeContent = Get-Content $ReadmeSource -Raw
    
    # Try to get GitHub username if available
    $GitHubUsername = ""
    $GitHubCLI = Get-Command "gh" -ErrorAction SilentlyContinue
    if ($null -ne $GitHubCLI) {
        try {
            $AuthStatus = gh auth status 2>&1
            if ($LASTEXITCODE -eq 0) {
                $GitHubUsername = gh api user --jq .login 2>$null
            }
        } catch {
            # GitHub CLI not authenticated or not available
        }
    }
    
    # Replace placeholders
    $ReadmeContent = $ReadmeContent -replace '\[PROJECT-NAME\]', $ProjectName
    $ReadmeContent = $ReadmeContent -replace '\[PROJECT-NAME\]_Unity', "${ProjectName}_Unity"
    $ReadmeContent = $ReadmeContent -replace '\[PROJECT-NAME\]_Unreal', "${ProjectName}_Unreal"
    
    # Replace username if we have it, otherwise leave placeholder
    if (-not [string]::IsNullOrEmpty($GitHubUsername)) {
        $ReadmeContent = $ReadmeContent -replace '\[USERNAME\]', $GitHubUsername
    }
    
    # Try to get author name from git config, otherwise leave placeholder
    try {
        $AuthorName = git config user.name 2>$null
        if (-not [string]::IsNullOrEmpty($AuthorName)) {
            $ReadmeContent = $ReadmeContent -replace '\[AUTHOR-NAME\]', $AuthorName
        }
    } catch {
        # Git not available or no user.name configured
    }
    
    # Write the updated README
    $ReadmeContent | Set-Content $ReadmeDest -NoNewline
    Write-Host "Added README.md template to plugin directory with project name replaced." -ForegroundColor Green
    Write-Host "NOTE: Please update README.md with project tagline, description, and features." -ForegroundColor Yellow
} else {
    Write-Host "WARNING: Unreal_README_template.md not found at $ReadmeSource" -ForegroundColor Yellow
}

if ([string]::IsNullOrEmpty($GitInit)) {
    Write-Host ""
    Write-Host "Git Repository Setup" -ForegroundColor Cyan
    Write-Host "Note: For Unreal projects, the git repository should be initialized in Plugins/$ProjectName/" -ForegroundColor Yellow
    Write-Host "Would you like me to initialize the repository on GitHub or just locally?" -ForegroundColor Yellow
    Write-Host "  [1] GitHub (create remote repo and initialize)" -ForegroundColor White
    Write-Host "  [2] Local only (just git init)" -ForegroundColor White
    Write-Host "  [3] Skip (initialize manually later)" -ForegroundColor White
    Write-Host ""
    
    $GitChoiceInput = Read-Host "Enter choice (1, 2, or 3)"
    switch ($GitChoiceInput) {
        "1" { $GitInit = "GitHub" }
        "2" { $GitInit = "Local" }
        "3" { $GitInit = "Skip" }
        default { $GitInit = "Skip" }
    }
} else {
    Write-Host ""
    Write-Host "Git Repository Setup: $GitInit" -ForegroundColor Cyan
    Write-Host "Note: For Unreal projects, the git repository should be initialized in Plugins/$ProjectName/" -ForegroundColor Yellow
}

$GitChoice = switch ($GitInit) {
    "GitHub" { "1" }
    "Local" { "2" }
    "Skip" { "3" }
    default { "3" }
}

if ($GitChoice -eq "1" -or $GitChoice -eq "2") {
    # Create plugin directory if it doesn't exist
    if (-not (Test-Path $PluginDir)) {
        New-Item -ItemType Directory -Path $PluginDir -Force | Out-Null
        Write-Host "Created plugin directory: $PluginDir" -ForegroundColor Green
    }
    
    # Initialize git repository in plugin directory
    Push-Location $PluginDir
    try {
        if (Test-Path ".git") {
            Write-Host "Git repository already exists. Skipping git init." -ForegroundColor Yellow
        } else {
            git init | Out-Null
            Write-Host "Initialized local git repository in $PluginDir" -ForegroundColor Green
        }
        
        if ($GitChoice -eq "1") {
            # Try to create GitHub repository
            Write-Host ""
            Write-Host "Attempting to create GitHub repository..." -ForegroundColor Cyan
            
            # Check if GitHub CLI is available
            $GitHubCLI = Get-Command "gh" -ErrorAction SilentlyContinue
            
            if ($null -ne $GitHubCLI) {
                # Check if user is authenticated
                $AuthStatus = gh auth status 2>&1
                if ($LASTEXITCODE -eq 0) {
                    # Get GitHub username
                    $GitHubUsername = gh api user --jq .login 2>$null
                    
                    # User is authenticated, try to create repo
                    $RepoName = $ProjectName
                    
                    # Check if repo already exists
                    $RepoExists = gh repo view $RepoName 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "GitHub repository already exists: $RepoName" -ForegroundColor Yellow
                        Write-Host "Adding remote origin..." -ForegroundColor Cyan
                        git remote add origin "https://github.com/$GitHubUsername/$RepoName.git" 2>&1 | Out-Null
                        if ($LASTEXITCODE -ne 0) {
                            # Remote might already exist, try to set URL
                            git remote set-url origin "https://github.com/$GitHubUsername/$RepoName.git" 2>&1 | Out-Null
                        }
                        Write-Host "SUCCESS: Remote configured for existing repository." -ForegroundColor Green
                        $CreateRepo = $null
                        $LASTEXITCODE = 0
                    } else {
                        Write-Host "Creating GitHub repository: $RepoName" -ForegroundColor Cyan
                        
                        # Create repo without push first (since we have no commits yet)
                        $CreateRepo = gh repo create $RepoName --private --source=. --remote=origin 2>&1
                    }
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "SUCCESS: GitHub repository created and configured." -ForegroundColor Green
                        
                        # Make initial commit and push
                        Write-Host "Making initial commit..." -ForegroundColor Cyan
                        git add .
                        git commit -m "Initial commit" 2>&1 | Out-Null
                            if ($LASTEXITCODE -eq 0) {
                                # Rename branch from master to main
                                git branch -M main 2>&1 | Out-Null
                                Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
                                git push -u origin main 2>&1 | Out-Null
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "SUCCESS: Initial commit pushed to GitHub." -ForegroundColor Green
                            } else {
                                Write-Host "WARNING: Failed to push initial commit. You can push manually later." -ForegroundColor Yellow
                            }
                        } else {
                            Write-Host "WARNING: Failed to create initial commit. You can commit and push manually later." -ForegroundColor Yellow
                        }
                        
                        # Update README crosslink to Unity package if it exists (use already-fetched username)
                        if (-not [string]::IsNullOrEmpty($GitHubUsername)) {
                            $UnityProjectPath = Join-Path (Split-Path $ProjectPath -Parent) "${ProjectName}_Unity"
                            if (Test-Path (Join-Path $UnityProjectPath "README.md")) {
                                $ReadmePath = Join-Path $PluginDir "README.md"
                                if (Test-Path $ReadmePath) {
                                    $ReadmeContent = Get-Content $ReadmePath -Raw
                                    $UnityRepoUrl = "https://github.com/$GitHubUsername/${ProjectName}_Unity"
                                    $ReadmeContent = $ReadmeContent -replace '\[Unity Package\]\(\.\.\/\[PROJECT-NAME\]_Unity/README\.md\)', "[Unity Package]($UnityRepoUrl)"
                                    $ReadmeContent | Set-Content $ReadmePath -NoNewline
                                    Write-Host "Updated README crosslink to Unity package." -ForegroundColor Green
                                }
                            }
                        }
                    } else {
                        Write-Host "WARNING: Failed to create GitHub repository automatically." -ForegroundColor Yellow
                        Write-Host "Error: $CreateRepo" -ForegroundColor Gray
                        Write-Host ""
                        Write-Host "Please create the repository manually on GitHub and provide the remote URL:" -ForegroundColor Yellow
                        $RemoteUrl = Read-Host "GitHub repository URL (e.g., git@github.com:username/repo.git)"
                        if (-not [string]::IsNullOrEmpty($RemoteUrl)) {
                            git remote add origin $RemoteUrl
                            Write-Host "Added remote origin: $RemoteUrl" -ForegroundColor Green
                        }
                    }
                } else {
                    Write-Host "GitHub CLI is installed but you are not authenticated." -ForegroundColor Yellow
                    Write-Host "Please run 'gh auth login' first, or create the repository manually." -ForegroundColor Yellow
                    Write-Host "You can add the remote later with: git remote add origin <URL>" -ForegroundColor Gray
                }
            } else {
                Write-Host "GitHub CLI (gh) not found. Please create the repository manually on GitHub." -ForegroundColor Yellow
                Write-Host "After creating the repository, add the remote with: git remote add origin <URL>" -ForegroundColor Gray
                Write-Host "Example: git remote add origin git@github.com:username/Proptical.git" -ForegroundColor Gray
            }
        }
    } catch {
        Write-Host "WARNING: Git initialization failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "You can initialize git manually by running 'git init' in $PluginDir" -ForegroundColor Gray
    } finally {
        Pop-Location
    }
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open the project: Double-click $UProjectFile" -ForegroundColor White
Write-Host "  2. Create plugin structure in Plugins/$ProjectName/ (see CROSS-PLATFORM-GAME-ENGINE-PROJECT-SETUP-GUIDE.md)" -ForegroundColor White
Write-Host "  3. Configure plugin structure (see AGENT Unreal Rules.md)" -ForegroundColor White
if ($GitChoice -eq "3") {
    Write-Host "  4. Initialize git repository manually: cd $PluginDir && git init" -ForegroundColor White
}

# Explicitly exit to ensure script terminates cleanly
exit 0

