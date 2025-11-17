@echo off
REM Unreal Engine Project Generation Script (Batch wrapper)
REM Calls the PowerShell script with proper execution policy

powershell.exe -ExecutionPolicy Bypass -File "%~dp0generate_unreal_project.ps1" %*

