# Unity Project Generation Script
# Generates a Unity project using Unity Hub CLI
# Assumes this script is in: [Project-Name]/GameEnginePluginRapidSetup/
# Creates project at: [Project-Name]/[Project-Name]_Unity/

param(
    [string]$UnityVersion = "",
    [string]$ProjectName = "",
    [ValidateSet("GitHub", "Local", "Skip", "")]
    [string]$GitInit = ""
)

# Get the project name from parent directory if not provided
# The Unity project should be created at the top-level directory (IDE workspace root)
# Handle nested directory structures by detecting the workspace root
if ([string]::IsNullOrEmpty($ProjectName)) {
    $CurrentDir = Get-Location
    $ParentDir = Split-Path -Path $CurrentDir -Parent
    
    # Walk up the directory tree to find the workspace root
    # Check if we're inside a "Setup" folder or other nested structure
    $ProjectRoot = $ParentDir
    $ParentDirName = Split-Path -Path $ProjectRoot -Leaf
    
    # If parent is "Setup" or we want to detect workspace root more intelligently,
    # we can walk up further. For now, handle common case of Setup folder.
    if ($ParentDirName -eq "Setup") {
        $ProjectRoot = Split-Path -Path $ProjectRoot -Parent
        Write-Host "Detected Setup folder, navigating to project root: $ProjectRoot" -ForegroundColor Cyan
    }
    
    # Try to detect IDE workspace root from environment variable (if available)
    # Cursor/VS Code typically sets workspace-related environment variables
    if ($env:CURSOR_WORKSPACE_ROOT) {
        $ProjectRoot = $env:CURSOR_WORKSPACE_ROOT
        Write-Host "Detected IDE workspace root from environment: $ProjectRoot" -ForegroundColor Cyan
    } elseif ($env:VSCODE_WORKSPACE_ROOT) {
        $ProjectRoot = $env:VSCODE_WORKSPACE_ROOT
        Write-Host "Detected IDE workspace root from environment: $ProjectRoot" -ForegroundColor Cyan
    }
    
    $ProjectName = Split-Path -Path $ProjectRoot -Leaf
    Write-Host "Detected project name: $ProjectName" -ForegroundColor Cyan
} else {
    $CurrentDir = Get-Location
    $ParentDir = Split-Path -Path $CurrentDir -Parent
    
    # Determine project root for path construction
    $ProjectRoot = $ParentDir
    $ParentDirName = Split-Path -Path $ProjectRoot -Leaf
    if ($ParentDirName -eq "Setup") {
        $ProjectRoot = Split-Path -Path $ProjectRoot -Parent
    }
    
    # Check for IDE workspace root environment variable
    if ($env:CURSOR_WORKSPACE_ROOT) {
        $ProjectRoot = $env:CURSOR_WORKSPACE_ROOT
    } elseif ($env:VSCODE_WORKSPACE_ROOT) {
        $ProjectRoot = $env:VSCODE_WORKSPACE_ROOT
    }
}

# Construct project path at the top-level directory
$ProjectPath = Join-Path $ProjectRoot "${ProjectName}_Unity"

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

# Find Unity Editor executable (preferred for full automation)
# Unity Editor supports -createProject flag in batch mode for fully automated creation
# Search for Unity Editor by scanning Unity Hub Editor directories
$UnityEditorExe = $null
$UnityHubExe = $null

# Search for Unity Editor installations
$UnityEditorBasePaths = @(
    "${env:ProgramFiles}\Unity\Hub\Editor",
    "${env:ProgramFiles(x86)}\Unity\Hub\Editor"
)

# Try to find Unity Editor by scanning version directories
foreach ($BasePath in $UnityEditorBasePaths) {
    if (Test-Path $BasePath) {
        # Get all Unity version directories
        $VersionDirs = Get-ChildItem -Path $BasePath -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
        
        foreach ($VersionDir in $VersionDirs) {
            $EditorPath = Join-Path $VersionDir.FullName "Editor\Unity.exe"
            if (Test-Path $EditorPath) {
                $UnityEditorExe = $EditorPath
                # Extract version from directory name if not already set
                if ([string]::IsNullOrEmpty($UnityVersion)) {
                    $UnityVersion = $VersionDir.Name
                }
                Write-Host "Found Unity Editor: $UnityEditorExe" -ForegroundColor Green
                Write-Host "Unity Version: $UnityVersion" -ForegroundColor Cyan
                break
            }
        }
        
        if ($null -ne $UnityEditorExe) {
            break
        }
    }
}

# Also search common Unity installation paths for Unity Hub (fallback)
$UnityHubPaths = @(
    "${env:ProgramFiles}\Unity Hub\Unity Hub.exe",
    "${env:ProgramFiles(x86)}\Unity Hub\Unity Hub.exe",
    "$env:LOCALAPPDATA\Programs\Unity Hub\Unity Hub.exe"
)

# Fallback to Unity Hub if Editor not found
if ($null -eq $UnityEditorExe) {
    foreach ($Path in $UnityHubPaths) {
        if (Test-Path $Path) {
            $UnityHubExe = $Path
            Write-Host "Found Unity Hub: $UnityHubExe" -ForegroundColor Yellow
            Write-Host "Note: Unity Hub requires user interaction. Consider installing Unity Editor for full automation." -ForegroundColor Yellow
            break
        }
    }
    
    if ($null -eq $UnityHubExe) {
        Write-Host "ERROR: Unity Editor or Unity Hub not found in standard locations." -ForegroundColor Red
        Write-Host "Searched Unity Editor locations:" -ForegroundColor Yellow
        foreach ($Path in $UnityEditorPaths) {
            Write-Host "  - $Path" -ForegroundColor Gray
        }
        Write-Host "Searched Unity Hub locations:" -ForegroundColor Yellow
        foreach ($Path in $UnityHubPaths) {
            Write-Host "  - $Path" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "Please install Unity Editor or Unity Hub." -ForegroundColor Yellow
        exit 1
    }
}

# If Unity version not provided and Unity Editor not found, try to detect from Unity Hub Editor directories
if ([string]::IsNullOrEmpty($UnityVersion) -and $null -eq $UnityEditorExe) {
    Write-Host "Unity version not specified. Attempting to detect installed versions..." -ForegroundColor Yellow
    
    $UnityInstallPaths = @(
        "${env:ProgramFiles}\Unity\Hub\Editor",
        "${env:ProgramFiles(x86)}\Unity\Hub\Editor"
    )
    
    $LatestVersion = $null
    foreach ($InstallPath in $UnityInstallPaths) {
        if (Test-Path $InstallPath) {
            $Versions = Get-ChildItem -Path $InstallPath -Directory | Sort-Object Name -Descending
            if ($Versions.Count -gt 0) {
                $LatestVersion = $Versions[0].Name
                Write-Host "Found Unity version: $LatestVersion" -ForegroundColor Cyan
                break
            }
        }
    }
    
    if ($null -eq $LatestVersion) {
        Write-Host "WARNING: Could not auto-detect Unity version." -ForegroundColor Yellow
        Write-Host "Please specify Unity version using -UnityVersion parameter." -ForegroundColor Yellow
        Write-Host "Example: .\generate_unity_project.ps1 -UnityVersion 2022.3.0f1" -ForegroundColor Gray
        exit 1
    }
    
    $UnityVersion = $LatestVersion
}

Write-Host ""
Write-Host "Creating Unity project..." -ForegroundColor Cyan
Write-Host "  Project Name: $ProjectName" -ForegroundColor White
Write-Host "  Project Path: $ProjectPath" -ForegroundColor White
Write-Host "  Unity Version: $UnityVersion" -ForegroundColor White
Write-Host ""

# Create Unity project using Unity Editor (fully automated) or Unity Hub (requires user interaction)
if ($null -ne $UnityEditorExe) {
    # Use Unity Editor directly for fully automated project creation
    Write-Host "Creating Unity project using Unity Editor (fully automated)..." -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $Arguments = @(
            "-batchmode",
            "-quit",
            "-createProject",
            "`"$ProjectPath`"",
            "-logFile",
            "`"$env:TEMP\UnityProjectCreation.log`""
        )
        
        Write-Host "Executing Unity Editor in batch mode..." -ForegroundColor Cyan
        $Process = Start-Process -FilePath $UnityEditorExe -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
        
        # Check for project creation
        Start-Sleep -Seconds 2 # Brief pause for file system
        
        if (Test-Path $ProjectPath) {
            $HasProjectSettings = Test-Path (Join-Path $ProjectPath "ProjectSettings")
            $HasAssets = Test-Path (Join-Path $ProjectPath "Assets")
            
            if ($HasProjectSettings -or $HasAssets) {
                $ProjectCreated = $true
                Write-Host ""
                Write-Host "SUCCESS: Unity project created at $ProjectPath" -ForegroundColor Green
            } else {
                Write-Host "WARNING: Project directory created but Unity project structure not detected." -ForegroundColor Yellow
                Write-Host "Check log file: $env:TEMP\UnityProjectCreation.log" -ForegroundColor Gray
            }
        } else {
            Write-Host "ERROR: Project directory was not created." -ForegroundColor Red
            Write-Host "Check log file: $env:TEMP\UnityProjectCreation.log" -ForegroundColor Gray
            if ($Process.ExitCode -ne 0) {
                Write-Host "Unity Editor exit code: $($Process.ExitCode)" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "ERROR: Failed to execute Unity Editor" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
} else {
    # Fallback to Unity Hub (requires user interaction)
    Write-Host "Unity Editor not found. Using Unity Hub (requires user interaction)..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ACTION REQUIRED: Unity Hub dialog will open with project name and path pre-filled." -ForegroundColor Yellow
    Write-Host "Please click 'CREATE PROJECT' button in Unity Hub." -ForegroundColor Yellow
    Write-Host ""
    
    try {
        $Arguments = @(
            "--create-project",
            "`"$ProjectPath`"",
            "--name",
            "`"$ProjectName`"",
            "--version",
            $UnityVersion
        )
        
        Write-Host "Opening Unity Hub..." -ForegroundColor Cyan
        Start-Process -FilePath $UnityHubExe -ArgumentList $Arguments
        
        Write-Host ""
        Write-Host "Waiting for project creation..." -ForegroundColor Cyan
        Write-Host "Please click 'CREATE PROJECT' in the Unity Hub dialog that just opened." -ForegroundColor Yellow
        Write-Host ""
        
        # Poll for project directory creation (wait up to 5 minutes)
        $MaxWaitTime = 300 # 5 minutes
        $CheckInterval = 2 # Check every 2 seconds
        $ElapsedTime = 0
        $ProjectCreated = $false
        
        while ($ElapsedTime -lt $MaxWaitTime -and -not $ProjectCreated) {
            Start-Sleep -Seconds $CheckInterval
            $ElapsedTime += $CheckInterval
            
            if (Test-Path $ProjectPath) {
                $ProjectFiles = Get-ChildItem -Path $ProjectPath -Force -ErrorAction SilentlyContinue
                if ($ProjectFiles.Count -gt 0) {
                    $HasProjectSettings = Test-Path (Join-Path $ProjectPath "ProjectSettings")
                    $HasAssets = Test-Path (Join-Path $ProjectPath "Assets")
                    
                    if ($HasProjectSettings -or $HasAssets) {
                        $ProjectCreated = $true
                        Write-Host ""
                        Write-Host "SUCCESS: Unity project created at $ProjectPath" -ForegroundColor Green
                        break
                    }
                }
            }
            
            if ($ElapsedTime % 30 -eq 0) {
                Write-Host "Still waiting... ($($ElapsedTime)s elapsed)" -ForegroundColor Gray
            }
        }
        
        if (-not $ProjectCreated) {
            Write-Host ""
            Write-Host "WARNING: Project directory not detected after $MaxWaitTime seconds." -ForegroundColor Yellow
            Write-Host "Please verify you clicked 'CREATE PROJECT' in Unity Hub." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "ERROR: Failed to launch Unity Hub" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}

# Final verification and git setup
if ($ProjectCreated) {
    Write-Host ""
    Write-Host "Project structure verified." -ForegroundColor Green
    
    # Add .gitignore file
    $GitIgnoreSource = Join-Path $PSScriptRoot "unity.gitignore"
    $GitIgnoreDest = Join-Path $ProjectPath ".gitignore"
    
    if (Test-Path $GitIgnoreSource) {
        Copy-Item -Path $GitIgnoreSource -Destination $GitIgnoreDest -Force
        Write-Host "Added .gitignore file." -ForegroundColor Green
    } else {
        Write-Host "WARNING: unity.gitignore template not found at $GitIgnoreSource" -ForegroundColor Yellow
    }
    
    # Add README template and replace placeholders
    $ReadmeSource = Join-Path $PSScriptRoot "Unity_README_template.md"
    $ReadmeDest = Join-Path $ProjectPath "README.md"
    
    if (Test-Path $ReadmeSource) {
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
        Write-Host "Added README.md template with project name replaced." -ForegroundColor Green
        Write-Host "NOTE: Please update README.md with project tagline, description, and features." -ForegroundColor Yellow
    } else {
        Write-Host "WARNING: Unity_README_template.md not found at $ReadmeSource" -ForegroundColor Yellow
    }
    
    # Ask user about git initialization (if not provided as parameter)
    if ([string]::IsNullOrEmpty($GitInit)) {
        Write-Host ""
        Write-Host "Git Repository Setup" -ForegroundColor Cyan
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
    }
    
    $GitChoice = switch ($GitInit) {
        "GitHub" { "1" }
        "Local" { "2" }
        "Skip" { "3" }
        default { "3" }
    }
    
    if ($GitChoice -eq "1" -or $GitChoice -eq "2") {
        # Initialize local git repository
        Push-Location $ProjectPath
        try {
            if (Test-Path ".git") {
                Write-Host "Git repository already exists. Skipping git init." -ForegroundColor Yellow
            } else {
                git init | Out-Null
                Write-Host "Initialized local git repository." -ForegroundColor Green
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
                        # User is authenticated, try to create repo
                        $RepoName = "${ProjectName}_Unity"
                        
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
                            
                            # Update README crosslink to Unreal plugin if it exists (use already-fetched username)
                            if (-not [string]::IsNullOrEmpty($GitHubUsername)) {
                                $UnrealPluginPath = Join-Path (Split-Path $ProjectPath -Parent) "${ProjectName}_Unreal\Plugins\$ProjectName"
                                if (Test-Path (Join-Path $UnrealPluginPath "README.md")) {
                                    $ReadmePath = Join-Path $ProjectPath "README.md"
                                    if (Test-Path $ReadmePath) {
                                        $ReadmeContent = Get-Content $ReadmePath -Raw
                                        $UnrealRepoUrl = "https://github.com/$GitHubUsername/$ProjectName"
                                        $ReadmeContent = $ReadmeContent -replace '\[Unreal Engine Plugin\]\(\.\.\/\[PROJECT-NAME\]_Unreal/Plugins/\[PROJECT-NAME\]/README\.md\)', "[Unreal Engine Plugin]($UnrealRepoUrl)"
                                        $ReadmeContent | Set-Content $ReadmePath -NoNewline
                                        Write-Host "Updated README crosslink to Unreal plugin." -ForegroundColor Green
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
                    Write-Host "Example: git remote add origin git@github.com:username/Proptical_Unity.git" -ForegroundColor Gray
                }
            }
        } catch {
            Write-Host "WARNING: Git initialization failed: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "You can initialize git manually by running 'git init' in the project directory." -ForegroundColor Gray
        } finally {
            Pop-Location
        }
    }
    
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Copy files from Unity_AutoCompilation/ submodule (see AGENT Unity Rules.md)" -ForegroundColor White
    Write-Host "  2. Configure package structure (see CROSS-PLATFORM-GAME-ENGINE-PROJECT-SETUP-GUIDE.md)" -ForegroundColor White
    if ($GitChoice -eq "3") {
        Write-Host "  3. Initialize git repository manually: cd $ProjectPath && git init" -ForegroundColor White
    }
}

# Explicitly exit to ensure script terminates cleanly
exit 0

