# one-time-install

Client-agnostic, one-shot toolkit installer for a fresh pentest box. It detects, or is told, the
OS and test type, then installs the matching declarative tool catalog.

**Status:** Windows + `webapp` is implemented. Linux / macOS and other test types are scaffolded
as stubs so future profiles can be added as data edits.

## Usage

Run the Windows install path in an **elevated** PowerShell.

```powershell
# defaults: auto-detect OS, webapp
iwr -useb https://raw.githubusercontent.com/kyleincyber/one-time-install/main/install.ps1 | iex

# pass flags over the one-liner
& ([scriptblock]::Create((iwr -useb https://raw.githubusercontent.com/kyleincyber/one-time-install/main/install.ps1))) -Type webapp -Os windows

# preview without installing
.\install.ps1 -Type webapp -DryRun

# list the catalog and exit
.\install.ps1 -Type webapp -List
```

## Parameters

| Flag | Values | Default | Notes |
|------|--------|---------|-------|
| `-Os` | `auto` `windows` `linux` `macos` | `auto` | `auto` works in Windows PowerShell 5.1 and PowerShell 7 by checking the available OS variables safely. |
| `-Type` | `webapp` | `webapp` | More test profiles can be added to the manifest later. |
| `-DryRun` | switch | off | Prints the catalog and planned actions without installing tools or changing PATH. |
| `-List` | switch | off | Prints the selected catalog and exits. |

## Behavior

- The tool catalog is declared in `install.ps1` by OS and test type.
- Each tool has an install method: `choco`, `go install`, `pipx`, `github-release`, or `git-clone`.
- The engine checks for already-present commands or clone destinations and skips them.
- Each install step is wrapped independently so one tool failure does not abort the whole run.
- A summary table is printed at the end with `installed`, `skipped`, `planned`, or `failed`.
- Before installing, the script checks HTTPS reachability for Chocolatey, GitHub, PyPI, and Go proxy endpoints and warns if egress looks restricted.
- On Windows, it persists these machine PATH entries: `C:\Tools`, `C:\Tools\bin`, `C:\Program Files\Go\bin`, `%USERPROFILE%\go\bin`, and `%USERPROFILE%\.local\bin`.

## What It Installs

Windows / `webapp`:

| Area | Tools |
|------|-------|
| Core apps | Firefox, Postman, Git, jq, Temurin JRE, 7-Zip, VS Code |
| Runtimes | Python 3, pipx, Go |
| Proxy/testing | Burp Suite Community, mitmproxy |
| Recon/discovery | ffuf, feroxbuster, gobuster, nuclei, nuclei-templates, httpx, katana, gau, waybackurls |
| Exploitation/auth | sqlmap, jwt_tool |
| Wordlists/payloads | SecLists, PayloadsAllTheThings |

Burp Suite Pro is not installed because it is licensed. Install it manually after signing in with
your own account. Burp extensions such as Autorize, Auth Analyzer, and JWT Editor are installed
manually inside Burp.

## Notes

- Requires outbound internet egress. If the box cannot reach Chocolatey, GitHub, PyPI, or Go
  module endpoints, transfer tools in by another route or rerun after egress is fixed.
- Some installs use "latest" upstream releases or module versions; reruns are designed to skip
  tools that are already present.
- The repository is public and intentionally contains no client names, engagement details,
  credentials, IPs, hostnames, or secrets.
- Chocolatey and machine PATH updates require an elevated Windows PowerShell session.
- Burp Community is included only as a stopgap. Use Burp Pro manually where a license is available.

## Roadmap

- Populate Linux and macOS catalogs.
- Add additional `-Type` profiles such as `api`, `network`, or `cloud`.
- Add optional profile switches for heavyweight tools such as hashcat, John the Ripper, or Node.
