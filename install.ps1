<#
    one-time-install / install.ps1
    Client-agnostic pentest toolkit installer.

    Detects (or is told) the OS and a test type, then installs the relevant toolkit
    from a declarative catalog. Windows + webapp is implemented; Linux/macOS and
    additional test types are scaffolded as clean stubs.

    Usage (elevated PowerShell):
        # defaults: auto-detect OS, webapp
        iwr -useb https://raw.githubusercontent.com/kyleincyber/one-time-install/main/install.ps1 | iex

        # pass flags over the one-liner
        & ([scriptblock]::Create((iwr -useb https://raw.githubusercontent.com/kyleincyber/one-time-install/main/install.ps1))) -Type webapp -Os windows

        # preview only
        .\install.ps1 -Type webapp -DryRun
        .\install.ps1 -Type webapp -List

    Params:
        -Os      auto | windows | linux | macos    (default: auto)
        -Type    webapp                            (default: webapp; more types to come)
        -DryRun  preview actions without installing
        -List    print the catalog for the selected OS/type and exit

    Note: Burp Suite Pro is licensed and is NOT installed here - install it signed in with your
    own account. Community edition is included only as a stopgap.
#>
param(
    [ValidateSet('auto','windows','linux','macos')] [string]$Os = 'auto',
    [ValidateSet('webapp')]                         [string]$Type = 'webapp',
    [switch]$DryRun,
    [switch]$List
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Catalog
# ---------------------------------------------------------------------------
function New-Tool {
    param(
        [Parameter(Mandatory=$true)] [string]$Name,
        [Parameter(Mandatory=$true)] [string]$Method,
        [string]$Package,
        [string]$Command,
        [string]$Repository,
        [string]$Destination,
        [string]$Url,
        [string]$ReleaseRepo,
        [string]$AssetPattern,
        [string]$BinaryName,
        [string]$Notes
    )

    [pscustomobject]@{
        Name         = $Name
        Method       = $Method
        Package      = $Package
        Command      = $Command
        Repository   = $Repository
        Destination  = $Destination
        Url          = $Url
        ReleaseRepo  = $ReleaseRepo
        AssetPattern = $AssetPattern
        BinaryName   = $BinaryName
        Notes        = $Notes
    }
}

$ToolCatalog = @{
    windows = @{
        webapp = @(
            (New-Tool -Name 'Firefox' -Method 'choco' -Package 'firefox' -Command 'firefox' -Notes 'Browser for multi-role testing workflows')
            (New-Tool -Name 'Postman' -Method 'choco' -Package 'postman' -Command 'postman' -Notes 'API request client')
            (New-Tool -Name 'Git' -Method 'choco' -Package 'git' -Command 'git' -Notes 'Source and clone support')
            (New-Tool -Name 'jq' -Method 'choco' -Package 'jq' -Command 'jq' -Notes 'JSON response handling')
            (New-Tool -Name 'Temurin JRE' -Method 'choco' -Package 'temurin' -Command 'java' -Notes 'Java runtime for Java-based tooling')
            (New-Tool -Name '7-Zip' -Method 'choco' -Package '7zip.install' -Command '7z' -Notes 'Archive extraction')
            (New-Tool -Name 'Python 3' -Method 'choco' -Package 'python' -Command 'python' -Notes 'Python runtime')
            (New-Tool -Name 'pipx' -Method 'choco' -Package 'pipx' -Command 'pipx' -Notes 'Isolated Python CLI installer')
            (New-Tool -Name 'Go' -Method 'choco' -Package 'golang' -Command 'go' -Notes 'Go runtime and go install support')
            (New-Tool -Name 'VS Code' -Method 'choco' -Package 'vscode' -Command 'code' -Notes 'Optional editor')
            (New-Tool -Name 'Burp Suite Community' -Method 'choco' -Package 'burp-suite-free-edition' -Command 'burpsuitecommunity' -Notes 'Stopgap only; install Burp Pro manually if licensed')
            (New-Tool -Name 'feroxbuster' -Method 'github-release' -Command 'feroxbuster' -ReleaseRepo 'epi052/feroxbuster' -AssetPattern 'x86_64-windows.*\.zip$' -BinaryName 'feroxbuster.exe' -Notes 'Recursive content discovery')
            (New-Tool -Name 'ffuf' -Method 'github-release' -Command 'ffuf' -ReleaseRepo 'ffuf/ffuf' -AssetPattern 'windows_amd64.*\.zip$' -BinaryName 'ffuf.exe' -Notes 'Fast web fuzzing')
            (New-Tool -Name 'nuclei' -Method 'go install' -Package 'github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest' -Command 'nuclei' -Notes 'Template-based scanning')
            (New-Tool -Name 'gobuster' -Method 'go install' -Package 'github.com/OJ/gobuster/v3@latest' -Command 'gobuster' -Notes 'Content and DNS discovery')
            (New-Tool -Name 'httpx' -Method 'go install' -Package 'github.com/projectdiscovery/httpx/cmd/httpx@latest' -Command 'httpx' -Notes 'HTTP probing')
            (New-Tool -Name 'katana' -Method 'go install' -Package 'github.com/projectdiscovery/katana/cmd/katana@latest' -Command 'katana' -Notes 'Crawling and spidering')
            (New-Tool -Name 'gau' -Method 'go install' -Package 'github.com/lc/gau/v2/cmd/gau@latest' -Command 'gau' -Notes 'Known URL collection')
            (New-Tool -Name 'waybackurls' -Method 'go install' -Package 'github.com/tomnomnom/waybackurls@latest' -Command 'waybackurls' -Notes 'Wayback URL collection')
            (New-Tool -Name 'sqlmap' -Method 'pipx' -Package 'sqlmap' -Command 'sqlmap' -Notes 'SQL injection testing')
            (New-Tool -Name 'jwt_tool' -Method 'pipx' -Package 'git+https://github.com/ticarpi/jwt_tool.git' -Command 'jwt_tool' -Notes 'JWT inspection and testing')
            (New-Tool -Name 'mitmproxy' -Method 'pipx' -Package 'mitmproxy' -Command 'mitmproxy' -Notes 'Optional intercepting proxy')
            (New-Tool -Name 'SecLists' -Method 'git-clone' -Repository 'https://github.com/danielmiessler/SecLists' -Destination 'C:\Tools\SecLists' -Notes 'Wordlists')
            (New-Tool -Name 'nuclei-templates' -Method 'git-clone' -Repository 'https://github.com/projectdiscovery/nuclei-templates' -Destination 'C:\Tools\nuclei-templates' -Notes 'Nuclei templates')
            (New-Tool -Name 'PayloadsAllTheThings' -Method 'git-clone' -Repository 'https://github.com/swisskyrepo/PayloadsAllTheThings' -Destination 'C:\Tools\PayloadsAllTheThings' -Notes 'Payload references')
            (New-Tool -Name 'Jython standalone' -Method 'download-file' -Url 'https://repo1.maven.org/maven2/org/python/jython-standalone/2.7.3/jython-standalone-2.7.3.jar' -Destination 'C:\Tools\jython-standalone-2.7.3.jar' -Notes 'Burp Python extension runtime: Burp > Extensions > settings > Python environment')
            (New-Tool -Name 'JRuby complete' -Method 'download-file' -Url 'https://repo1.maven.org/maven2/org/jruby/jruby-complete/9.4.8.0/jruby-complete-9.4.8.0.jar' -Destination 'C:\Tools\jruby-complete-9.4.8.0.jar' -Notes 'Burp Ruby extension runtime: Burp > Extensions > settings > Ruby environment')
        )
    }
    linux = @{
        webapp = @()
    }
    macos = @{
        webapp = @()
    }
}

$EgressTargets = @(
    'community.chocolatey.org',
    'github.com',
    'api.github.com',
    'objects.githubusercontent.com',
    'raw.githubusercontent.com',
    'pypi.org',
    'proxy.golang.org',
    'repo1.maven.org'
)

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------
function Resolve-Os {
    param([string]$RequestedOs)

    if ($RequestedOs -ne 'auto') {
        return $RequestedOs
    }

    $isLinuxVar = Get-Variable -Name IsLinux -ErrorAction SilentlyContinue
    $isMacVar = Get-Variable -Name IsMacOS -ErrorAction SilentlyContinue

    if ($isLinuxVar -and $isLinuxVar.Value) {
        return 'linux'
    }
    if ($isMacVar -and $isMacVar.Value) {
        return 'macos'
    }

    return 'windows'
}

function Get-ToolsForProfile {
    param(
        [string]$OsName,
        [string]$ProfileType
    )

    if (-not $ToolCatalog.ContainsKey($OsName)) {
        return @()
    }
    if (-not $ToolCatalog[$OsName].ContainsKey($ProfileType)) {
        return @()
    }

    return @($ToolCatalog[$OsName][$ProfileType])
}

function Test-CommandPresent {
    param([string]$CommandName)

    if ([string]::IsNullOrWhiteSpace($CommandName)) {
        return $false
    }

    return [bool](Get-Command $CommandName -ErrorAction SilentlyContinue)
}

function Add-Summary {
    param(
        [System.Collections.ArrayList]$Summary,
        [string]$Name,
        [string]$Method,
        [string]$Status,
        [string]$Detail
    )

    [void]$Summary.Add([pscustomobject]@{
        Tool   = $Name
        Method = $Method
        Status = $Status
        Detail = $Detail
    })
}

function Show-Catalog {
    param(
        [object[]]$Tools,
        [string]$OsName,
        [string]$ProfileType
    )

    Write-Host "[*] Catalog: $OsName / $ProfileType" -ForegroundColor Cyan
    if ($Tools.Count -eq 0) {
        Write-Host '    No tools are implemented for this profile yet.' -ForegroundColor Yellow
        return
    }

    $Tools | Select-Object Name, Method, Package, Repository, Destination, Notes | Format-Table -AutoSize
}

function Show-Summary {
    param([System.Collections.ArrayList]$Summary)

    Write-Host ''
    Write-Host '[*] Summary' -ForegroundColor Cyan
    if ($Summary.Count -eq 0) {
        Write-Host '    No actions were attempted.'
        return
    }

    $Summary | Sort-Object Tool | Format-Table -AutoSize
}

function Test-Tcp443 {
    param([string]$HostName)

    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect($HostName, 443, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne(3000, $false)) {
            return $false
        }
        $client.EndConnect($async)
        return $true
    } catch {
        return $false
    } finally {
        $client.Close()
    }
}

function Enable-Tls12 {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
}

function Test-Egress {
    param([string[]]$Hosts)

    Write-Host '[*] Checking outbound HTTPS reachability...' -ForegroundColor Cyan
    $failed = @()
    foreach ($hostName in $Hosts) {
        if (-not (Test-Tcp443 -HostName $hostName)) {
            $failed += $hostName
        }
    }

    if ($failed.Count -gt 0) {
        Write-Host '[!] Some required download endpoints were not reachable on TCP/443:' -ForegroundColor Yellow
        foreach ($hostName in $failed) {
            Write-Host "    - $hostName" -ForegroundColor Yellow
        }
        Write-Host '    The installer will continue, but affected tools may fail. Check proxy/VPN/egress policy before retrying.' -ForegroundColor Yellow
    } else {
        Write-Host '[+] Required download endpoints are reachable.' -ForegroundColor Green
    }
}

function Assert-WindowsAdmin {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
               ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        throw 'Run this in an elevated PowerShell (Administrator).'
    }
}

function Update-CurrentProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $paths = @()
    if ($machinePath) { $paths += $machinePath }
    if ($userPath) { $paths += $userPath }
    $env:Path = ($paths -join ';')
}

function Ensure-MachinePathEntries {
    param([string[]]$Paths)

    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    if (-not $machinePath) {
        $machinePath = ''
    }

    $existing = @()
    foreach ($entry in ($machinePath -split ';')) {
        if (-not [string]::IsNullOrWhiteSpace($entry)) {
            $existing += $entry.Trim()
        }
    }

    $changed = $false
    foreach ($path in $Paths) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        $matched = $false
        foreach ($entry in $existing) {
            if ($entry.TrimEnd('\') -ieq $path.TrimEnd('\')) {
                $matched = $true
                break
            }
        }

        if (-not $matched) {
            $existing += $path
            $changed = $true
            Write-Host "[*] Adding to machine PATH: $path" -ForegroundColor Cyan
        }
    }

    if ($changed) {
        [Environment]::SetEnvironmentVariable('Path', ($existing -join ';'), 'Machine')
    }

    Update-CurrentProcessPath
}

function Test-ChocoPackageInstalled {
    param([string]$PackageName)

    if ([string]::IsNullOrWhiteSpace($PackageName)) {
        return $false
    }
    if (-not (Test-CommandPresent -CommandName 'choco')) {
        return $false
    }

    try {
        $output = & choco list --local-only --exact $PackageName 2>$null
        if ($LASTEXITCODE -ne 0) {
            return $false
        }
        foreach ($line in $output) {
            if ($line -match ("^" + [regex]::Escape($PackageName) + "\s")) {
                return $true
            }
        }
    } catch {
        return $false
    }

    return $false
}

function Ensure-Chocolatey {
    param(
        [System.Collections.ArrayList]$Summary,
        [switch]$PreviewOnly
    )

    if (Test-CommandPresent -CommandName 'choco') {
        Add-Summary -Summary $Summary -Name 'Chocolatey' -Method 'bootstrap' -Status 'skipped' -Detail 'already present'
        return
    }

    if ($PreviewOnly) {
        Add-Summary -Summary $Summary -Name 'Chocolatey' -Method 'bootstrap' -Status 'planned' -Detail 'would install Chocolatey'
        return
    }

    try {
        Write-Host '[*] Installing Chocolatey...' -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Enable-Tls12
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        $env:Path += ";$env:ProgramData\chocolatey\bin"
        Add-Summary -Summary $Summary -Name 'Chocolatey' -Method 'bootstrap' -Status 'installed' -Detail 'installed'
    } catch {
        Add-Summary -Summary $Summary -Name 'Chocolatey' -Method 'bootstrap' -Status 'failed' -Detail $_.Exception.Message
    }
}

function Install-ChocoTool {
    param(
        [object]$Tool,
        [System.Collections.ArrayList]$Summary,
        [switch]$PreviewOnly
    )

    if ($Tool.Command -and (Test-CommandPresent -CommandName $Tool.Command)) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'skipped' -Detail 'command already present'
        return
    }
    if (Test-ChocoPackageInstalled -PackageName $Tool.Package) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'skipped' -Detail 'Chocolatey package already installed'
        return
    }

    if ($PreviewOnly) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'planned' -Detail "would install package $($Tool.Package)"
        return
    }

    if (-not (Test-CommandPresent -CommandName 'choco')) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'failed' -Detail 'Chocolatey is not available'
        return
    }

    try {
        Write-Host "[*] Installing $($Tool.Name) via Chocolatey..." -ForegroundColor Cyan
        & choco install -y $Tool.Package
        if ($LASTEXITCODE -ne 0) {
            throw "choco exited with code $LASTEXITCODE"
        }
        Update-CurrentProcessPath
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'installed' -Detail $Tool.Package
    } catch {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'failed' -Detail $_.Exception.Message
    }
}

function Install-GoTool {
    param(
        [object]$Tool,
        [System.Collections.ArrayList]$Summary,
        [switch]$PreviewOnly
    )

    if ($Tool.Command -and (Test-CommandPresent -CommandName $Tool.Command)) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'skipped' -Detail 'command already present'
        return
    }

    if ($PreviewOnly) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'planned' -Detail "would run go install $($Tool.Package)"
        return
    }

    if (-not (Test-CommandPresent -CommandName 'go')) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'failed' -Detail 'Go is not available'
        return
    }

    try {
        Write-Host "[*] Installing $($Tool.Name) via go install..." -ForegroundColor Cyan
        & go install $Tool.Package
        if ($LASTEXITCODE -ne 0) {
            throw "go install exited with code $LASTEXITCODE"
        }
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'installed' -Detail $Tool.Package
    } catch {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'failed' -Detail $_.Exception.Message
    }
}

function Install-PipxTool {
    param(
        [object]$Tool,
        [System.Collections.ArrayList]$Summary,
        [switch]$PreviewOnly
    )

    if ($Tool.Command -and (Test-CommandPresent -CommandName $Tool.Command)) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'skipped' -Detail 'command already present'
        return
    }

    if ($PreviewOnly) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'planned' -Detail "would run pipx install $($Tool.Package)"
        return
    }

    if (-not (Test-CommandPresent -CommandName 'pipx')) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'failed' -Detail 'pipx is not available'
        return
    }

    try {
        Write-Host "[*] Installing $($Tool.Name) via pipx..." -ForegroundColor Cyan
        & pipx install $Tool.Package
        if ($LASTEXITCODE -ne 0) {
            throw "pipx exited with code $LASTEXITCODE"
        }
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'installed' -Detail $Tool.Package
    } catch {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'failed' -Detail $_.Exception.Message
    }
}

function Install-GitCloneTool {
    param(
        [object]$Tool,
        [System.Collections.ArrayList]$Summary,
        [switch]$PreviewOnly
    )

    if ($Tool.Destination -and (Test-Path $Tool.Destination)) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'skipped' -Detail 'destination already exists'
        return
    }

    if ($PreviewOnly) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'planned' -Detail "would clone $($Tool.Repository)"
        return
    }

    if (-not (Test-CommandPresent -CommandName 'git')) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'failed' -Detail 'git is not available'
        return
    }

    try {
        Write-Host "[*] Cloning $($Tool.Name)..." -ForegroundColor Cyan
        & git clone --depth 1 $Tool.Repository $Tool.Destination
        if ($LASTEXITCODE -ne 0) {
            throw "git clone exited with code $LASTEXITCODE"
        }
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'installed' -Detail $Tool.Destination
    } catch {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'failed' -Detail $_.Exception.Message
    }
}

function Install-GitHubReleaseTool {
    param(
        [object]$Tool,
        [System.Collections.ArrayList]$Summary,
        [switch]$PreviewOnly
    )

    if ($Tool.Command -and (Test-CommandPresent -CommandName $Tool.Command)) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'skipped' -Detail 'command already present'
        return
    }

    if ($PreviewOnly) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'planned' -Detail "would fetch latest release from $($Tool.ReleaseRepo)"
        return
    }

    try {
        $binRoot = 'C:\Tools\bin'
        New-Item -ItemType Directory -Force -Path $binRoot | Out-Null

        Write-Host "[*] Fetching latest $($Tool.Name) release..." -ForegroundColor Cyan
        $releaseUri = "https://api.github.com/repos/$($Tool.ReleaseRepo)/releases/latest"
        $release = Invoke-RestMethod -Uri $releaseUri -Headers @{ 'User-Agent' = 'one-time-install' }
        $asset = $release.assets | Where-Object { $_.name -match $Tool.AssetPattern } | Select-Object -First 1
        if (-not $asset) {
            throw "no release asset matched $($Tool.AssetPattern)"
        }

        $workDir = Join-Path $env:TEMP ("one-time-install-" + [guid]::NewGuid().ToString())
        $archive = Join-Path $workDir $asset.name
        New-Item -ItemType Directory -Force -Path $workDir | Out-Null
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archive -UseBasicParsing
        Expand-Archive -Path $archive -DestinationPath $workDir -Force

        $binary = Get-ChildItem -Path $workDir -Recurse -Filter $Tool.BinaryName | Select-Object -First 1
        if (-not $binary) {
            throw "release did not contain $($Tool.BinaryName)"
        }

        Copy-Item -Path $binary.FullName -Destination (Join-Path $binRoot $Tool.BinaryName) -Force
        Remove-Item -Path $workDir -Recurse -Force
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'installed' -Detail (Join-Path $binRoot $Tool.BinaryName)
    } catch {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'failed' -Detail $_.Exception.Message
    }
}

function Install-DownloadFileTool {
    param(
        [object]$Tool,
        [System.Collections.ArrayList]$Summary,
        [switch]$PreviewOnly
    )

    if ($Tool.Destination -and (Test-Path $Tool.Destination)) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'skipped' -Detail 'destination already exists'
        return
    }

    if ($PreviewOnly) {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'planned' -Detail "would download $($Tool.Url)"
        return
    }

    try {
        $dir = Split-Path -Parent $Tool.Destination
        if ($dir) {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
        }
        Write-Host "[*] Downloading $($Tool.Name)..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $Tool.Url -OutFile $Tool.Destination -UseBasicParsing
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'installed' -Detail $Tool.Destination
    } catch {
        Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'failed' -Detail $_.Exception.Message
    }
}

function Install-Tool {
    param(
        [object]$Tool,
        [System.Collections.ArrayList]$Summary,
        [switch]$PreviewOnly
    )

    switch ($Tool.Method) {
        'choco'          { Install-ChocoTool -Tool $Tool -Summary $Summary -PreviewOnly:$PreviewOnly }
        'go install'     { Install-GoTool -Tool $Tool -Summary $Summary -PreviewOnly:$PreviewOnly }
        'pipx'           { Install-PipxTool -Tool $Tool -Summary $Summary -PreviewOnly:$PreviewOnly }
        'github-release' { Install-GitHubReleaseTool -Tool $Tool -Summary $Summary -PreviewOnly:$PreviewOnly }
        'git-clone'      { Install-GitCloneTool -Tool $Tool -Summary $Summary -PreviewOnly:$PreviewOnly }
        'download-file'  { Install-DownloadFileTool -Tool $Tool -Summary $Summary -PreviewOnly:$PreviewOnly }
        default          { Add-Summary -Summary $Summary -Name $Tool.Name -Method $Tool.Method -Status 'failed' -Detail 'unknown install method' }
    }
}

# ---------------------------------------------------------------------------
# OS implementations
# ---------------------------------------------------------------------------
function Install-WindowsProfile {
    param(
        [string]$ProfileType,
        [object[]]$Tools,
        [switch]$PreviewOnly
    )

    $summary = New-Object System.Collections.ArrayList

    if ($Tools.Count -eq 0) {
        Write-Host "[!] Windows / '$ProfileType' is not implemented yet." -ForegroundColor Yellow
        return
    }

    if (-not $PreviewOnly) {
        Assert-WindowsAdmin
        Enable-Tls12
        Test-Egress -Hosts $EgressTargets
    }

    $pathEntries = @(
        'C:\Tools',
        'C:\Tools\bin',
        'C:\Program Files\Go\bin',
        "$env:USERPROFILE\go\bin",
        "$env:USERPROFILE\.local\bin"
    )

    if ($PreviewOnly) {
        Add-Summary -Summary $summary -Name 'PATH entries' -Method 'machine-path' -Status 'planned' -Detail ($pathEntries -join '; ')
    } else {
        New-Item -ItemType Directory -Force -Path 'C:\Tools','C:\Tools\bin' | Out-Null
        Ensure-MachinePathEntries -Paths $pathEntries
    }

    Ensure-Chocolatey -Summary $summary -PreviewOnly:$PreviewOnly

    foreach ($tool in $Tools) {
        Install-Tool -Tool $tool -Summary $summary -PreviewOnly:$PreviewOnly
    }

    Show-Summary -Summary $summary
    Write-Host ''
    Write-Host 'Burp Suite Pro is licensed and is not installed here. Install it manually if you have a license.' -ForegroundColor Yellow
}

function Install-LinuxProfile {
    param([string]$ProfileType)

    Write-Host '[!] Linux support is not implemented yet.' -ForegroundColor Yellow
    Write-Host "    The manifest is scaffolded for '$ProfileType'; add tools under `$ToolCatalog.linux.$ProfileType when ready."
}

function Install-MacOSProfile {
    param([string]$ProfileType)

    Write-Host '[!] macOS support is not implemented yet.' -ForegroundColor Yellow
    Write-Host "    The manifest is scaffolded for '$ProfileType'; add tools under `$ToolCatalog.macos.$ProfileType when ready."
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
$resolvedOs = Resolve-Os -RequestedOs $Os
$toolsForProfile = Get-ToolsForProfile -OsName $resolvedOs -ProfileType $Type

Write-Host "[*] OS: $resolvedOs   Test type: $Type" -ForegroundColor Cyan

if ($List) {
    Show-Catalog -Tools $toolsForProfile -OsName $resolvedOs -ProfileType $Type
    return
}

if ($DryRun) {
    Show-Catalog -Tools $toolsForProfile -OsName $resolvedOs -ProfileType $Type
}

switch ($resolvedOs) {
    'windows' { Install-WindowsProfile -ProfileType $Type -Tools $toolsForProfile -PreviewOnly:$DryRun }
    'linux'   { Install-LinuxProfile -ProfileType $Type }
    'macos'   { Install-MacOSProfile -ProfileType $Type }
    default   { throw "Unknown OS: $resolvedOs" }
}
