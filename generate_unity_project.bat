@echo off
REM Unity Project Generation Script (Batch wrapper)
REM Calls the PowerShell script with proper execution policy

powershell.exe -ExecutionPolicy Bypass -File "%~dp0generate_unity_project.ps1" %*

