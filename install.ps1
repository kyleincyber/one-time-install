<#
    one-time-install / install.ps1
    Client-agnostic pentest toolkit installer.

    Detects (or is told) the OS and a test type, then installs the relevant toolkit.
    Currently implemented: Windows + webapp. Linux and other test types are stubbed.

    Usage (elevated PowerShell):
        # defaults: auto-detect OS, webapp
        iwr -useb https://raw.githubusercontent.com/kyleincyber/one-time-install/main/install.ps1 | iex

        # pass flags over the one-liner
        & ([scriptblock]::Create((iwr -useb https://raw.githubusercontent.com/kyleincyber/one-time-install/main/install.ps1))) -Type webapp -Os windows

        # or download then run
        .\install.ps1 -Type webapp

    Params:
        -Os    auto | windows | linux    (default: auto)
        -Type  webapp                     (default: webapp; more types to come)

    Note: Burp Suite PRO is licensed and is NOT installed here - install it signed in with your
    own account. Community edition is included only as a stopgap.
#>
param(
    [ValidateSet('auto','windows','linux')] [string]$Os   = 'auto',
    [ValidateSet('webapp')]                 [string]$Type = 'webapp'
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# OS resolution
# ---------------------------------------------------------------------------
if ($Os -eq 'auto') {
    $Os = if ($IsLinux) { 'linux' } elseif ($IsMacOS) { 'macos' } else { 'windows' }
}
Write-Host "[*] OS: $Os   Test type: $Type" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Windows
# ---------------------------------------------------------------------------
function Install-Windows {
    param([string]$Type)

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
               ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) { throw 'Run this in an elevated PowerShell (Administrator).' }

    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072

    # Chocolatey
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host '[*] Installing Chocolatey...' -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        $env:Path += ";$env:ProgramData\chocolatey\bin"
    } else {
        Write-Host '[*] Chocolatey already present.' -ForegroundColor Green
    }

    switch ($Type) {
        'webapp' { Install-Windows-WebApp }
        default  { Write-Host "[!] Windows / '$Type' not implemented yet." -ForegroundColor Yellow }
    }
}

function Install-Windows-WebApp {
    $Tools = 'C:\Tools'
    New-Item -ItemType Directory -Force -Path $Tools | Out-Null

    $packages = @(
        'firefox',                 # Multi-Account Containers for concurrent role sessions
        'postman',                 # API / Dataverse Web API requests
        'git',
        'jq',                      # JSON / OData response handling
        'temurin',                 # JRE for Java-based tools
        '7zip.install',
        'burp-suite-free-edition'  # stopgap only; bring Burp Pro separately (licensed)
    )
    Write-Host "[*] Installing: $($packages -join ', ')" -ForegroundColor Cyan
    choco install -y @packages

    # SecLists (wordlists)
    if (-not (Test-Path "$Tools\SecLists")) {
        Write-Host '[*] Cloning SecLists...' -ForegroundColor Cyan
        git clone --depth 1 https://github.com/danielmiessler/SecLists "$Tools\SecLists"
    } else {
        Write-Host '[*] SecLists already present.' -ForegroundColor Green
    }

    # ffuf (latest release, web content/param discovery)
    try {
        Write-Host '[*] Fetching latest ffuf...' -ForegroundColor Cyan
        $rel   = Invoke-RestMethod 'https://api.github.com/repos/ffuf/ffuf/releases/latest' -Headers @{ 'User-Agent' = 'one-time-install' }
        $asset = $rel.assets | Where-Object { $_.name -match 'windows_amd64\.zip$' } | Select-Object -First 1
        if ($asset) {
            $zip = "$env:TEMP\ffuf.zip"
            Invoke-WebRequest $asset.browser_download_url -OutFile $zip -UseBasicParsing
            Expand-Archive $zip -DestinationPath "$Tools\ffuf" -Force
            Remove-Item $zip -Force
        }
    } catch {
        Write-Host "[!] ffuf fetch skipped: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    Write-Host ''
    Write-Host '[+] Done (Windows / webapp).' -ForegroundColor Green
    Write-Host '    Apps via Choco: Firefox, Postman, git, jq, JRE (temurin), 7-Zip, Burp Community.'
    Write-Host '    C:\Tools: SecLists, ffuf.'
    Write-Host '    Burp PRO not installed here (licensed) - install it signed in with your own account.'
}

# ---------------------------------------------------------------------------
# Linux (stub - focus is Windows for now)
# ---------------------------------------------------------------------------
function Install-Linux {
    param([string]$Type)
    Write-Host '[!] Linux support is not implemented yet.' -ForegroundColor Yellow
    Write-Host "    Planned: apt/pipx-based '$Type' toolkit. For now use the Windows path."
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
switch ($Os) {
    'windows' { Install-Windows -Type $Type }
    'linux'   { Install-Linux   -Type $Type }
    'macos'   { Write-Host '[!] macOS not implemented yet.' -ForegroundColor Yellow }
    default   { throw "Unknown OS: $Os" }
}
