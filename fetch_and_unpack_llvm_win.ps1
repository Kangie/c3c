#!/usr/bin/env pwsh

# PWSH (>=7.0) script to fetch and unpack the prebuilt c3c LLVM for Windows builds
# Positional arguments '-BuildType' '("debug", "release") and -Version' are supported.
# If no arguments are provided, the script will fetch the latest (hardcoded...) release build.
# It probably also works on older PowerShell but is untested.

# Example usage:
# ./fetch_and_unpack_llvm_win.ps1 -BuildType 'release' -Version '19.1.5'

# Parse command-line arguments
param (
    [string]$BuildType = "release",
    [string]$Version = "19.1.5"
)

function Get-LLVMUrl {
    param (
        [string]$BuildType,
        [string]$Version
    )

    $underscoreVersion = $Version -replace '\.', '_'

    switch ($BuildType) {
        'release' { return "https://github.com/c3lang/win-llvm/releases/download/llvm_$underscoreVersion/llvm-$Version-windows-amd64-msvc17-libcmt.7z" }
        'debug' { return "https://github.com/c3lang/win-llvm/releases/download/llvm_$underscoreVersion/llvm-$Version-windows-amd64-msvc17-libcmt-dbg.7z" }
        default { throw "Invalid build type specified. Use 'release' or 'debug'." }
    }
}

function Fetch-AndUnpack-LLVM {
    param (
        [string]$BuildType,
        [string]$Version
    )

    $url = Get-LLVMUrl -BuildType $BuildType -Version $Version
    # If we don't use Join-Path here it can get confusing if you want to test changes on POSIX.
    $outputPath = Join-Path -Path $PSScriptRoot -ChildPath "llvm-$Version.7z"
    $extractPath = Join-Path -Path $PSScriptRoot -ChildPath "llvm"

    Write-host "Fetching LLVM $Version ($BuildType) from $url"

    if (-not (Test-Path $outputPath)) {
        Invoke-WebRequest -Uri $url -OutFile $outputPath
    } else {
        Write-Host "File $outputPath already exists. Skipping download."
    }
    if (-not (Test-Path $extractPath)) {
        New-Item -ItemType Directory -Path $extractPath
    }

    Write-host "Extracting LLVM to $extractPath"
    & 7z x $outputPath "-o$extractPath"
}

# $PSScriptRoot only works when invoked as a script, guard against
# sourcing it instead.
if ($MyInvocation.InvocationName -eq $PSCommandPath) {
    Fetch-AndUnpack-LLVM -BuildType $BuildType -Version $Version
}
