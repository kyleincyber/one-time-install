# one-time-install

Client-agnostic, one-shot toolkit installer for a fresh pentest box. Detects (or is told) the
OS and a test type, then installs the relevant tooling.

**Status:** Windows + `webapp` implemented. Linux / macOS and other test types are stubbed.

## Usage (Windows)

Run in an **elevated** PowerShell.

```powershell
# defaults: auto-detect OS, webapp
iwr -useb https://raw.githubusercontent.com/kyleincyber/one-time-install/main/install.ps1 | iex

# pass flags over the one-liner
& ([scriptblock]::Create((iwr -useb https://raw.githubusercontent.com/kyleincyber/one-time-install/main/install.ps1))) -Type webapp -Os windows

# or download then run
.\install.ps1 -Type webapp
```

## Parameters

| Flag    | Values                    | Default | Notes |
|---------|---------------------------|---------|-------|
| `-Os`   | `auto` `windows` `linux`  | `auto`  | `auto` picks Windows/Linux/macOS from the running shell |
| `-Type` | `webapp`                  | `webapp`| More test types to be added |

## What it installs (Windows / webapp)

Via Chocolatey: **Firefox** (Multi-Account Containers for concurrent sessions), **Postman**,
**git**, **jq**, a **JRE** (Temurin), **7-Zip**, **Burp Suite Community**.

Into `C:\Tools`: **SecLists**, **ffuf** (latest release).

## Notes

- Requires outbound internet egress. If the box can't reach the Chocolatey/GitHub CDNs, transfer
  the tools in by another route.
- **Burp Suite Pro is licensed and is not installed** by this script - install it signed in with
  your own account. Community is included only as a stopgap.
- Contains no client, engagement, or credential data by design - this repo is public.

## Roadmap

- Linux (`apt`/`pipx`) toolkit
- Additional `-Type` profiles (api, network, ...)
