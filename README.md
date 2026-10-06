<h1 align="center">NspxMiguel/homebrew-tap</h1>

<p align="center">
  <b>A personal Homebrew tap. Every cask downloads the source and builds it on your machine.</b>
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue"></a>
  <img alt="Platform: macOS" src="https://img.shields.io/badge/platform-macOS-lightgrey?logo=apple&logoColor=white">
  <img alt="Homebrew casks" src="https://img.shields.io/badge/homebrew-casks-FBB040?logo=homebrew&logoColor=white">
</p>

<p align="center">
  <a href="#install">Install</a> ·
  <a href="#packages">Packages</a> ·
  <a href="#task-manager">Task Manager</a> ·
  <a href="#mactray">MacTray</a> ·
  <a href="#mailforai">MailForAI</a> ·
  <a href="#nanobridge">NanoBridge</a> ·
  <a href="docs/INDEX.md">Docs</a>
</p>

## Install

```bash
brew tap NspxMiguel/tap   # adds this repository as a Homebrew package source
```

Every cask here **downloads the source code and builds it on your machine** instead of pulling a prebuilt binary. A local build carries no download quarantine attribute, so Gatekeeper does not block it with an "unidentified developer" warning, and no paid developer account is needed.

The price is time: installing takes a few minutes and needs the Xcode Command Line Tools (free). If you do not have them, the installer runs `xcode-select --install` and waits for it to finish.

> First time using this tap? Homebrew asks you to trust it before installing (the standard guard for third-party taps):
> ```bash
> brew trust --cask NspxMiguel/tap/<cask-name>
> ```

## Packages

| Package | Install | What it is |
| --- | --- | --- |
| [Task Manager](https://github.com/NspxMiguel/mac-task-manager) | `brew install --cask task-manager` | Native macOS task manager. |
| [MacTray](https://github.com/NspxMiguel/MacTray) | `brew install --cask mactray` | Hides the icons that do not fit in the menu bar. |
| [MailForAI](https://github.com/NspxMiguel/MailForAI) | `brew install --cask mailforai` | Mailbox with an approval queue for AI agents. |
| [NanoBridge](https://github.com/NspxMiguel/NanoBridge) | `brew install --cask nanobridge` | Gemini image generation for the CLI and MCP. |
| [Ebb](https://github.com/NspxMiguel/Ebb) | `brew install --cask ebb` | Deletes old email over IMAP so the mailbox never fills up. |
| [ScrollBack](https://github.com/NspxMiguel/ScrollBack) | `brew install --cask scrollback` | Reverses mouse scroll (not trackpad) and revives side buttons macOS drops. |

All of them download the source and assemble the app or environment locally.

<details>
<summary><b>Task Manager</b></summary>

<a id="task-manager"></a>

A native macOS task manager in the style of Windows 11.

```bash
brew install --cask task-manager
```

1. Downloads the source of [mac-task-manager](https://github.com/NspxMiguel/mac-task-manager)
2. Checks for (or installs) the Command Line Tools
3. Builds with `swift build`
4. Assembles the `.app`, signs it locally and copies it to `/Applications`

Open it from Spotlight or `/Applications/TaskManager.app`. The default global shortcut is `⌘⇧⎋` (Cmd+Shift+Esc), configurable in the app under Settings. The menu bar icon toggles it with a left click and has `Quit` on right click.

Source: https://github.com/NspxMiguel/mac-task-manager

</details>

<details>
<summary><b>MacTray</b></summary>

<a id="mactray"></a>

Hides the icons that do not fit in the menu bar, keeping them reachable in a panel of their own.

```bash
brew install --cask mactray
```

On first launch, grant the Accessibility permission macOS asks for.

</details>

<details>
<summary><b>MailForAI</b></summary>

<a id="mailforai"></a>

A mailbox for AI agents, with reviews in the menu bar before any sensitive action.

```bash
brew install --cask mailforai
mailforai setup
```

</details>

<details>
<summary><b>NanoBridge</b></summary>

<a id="nanobridge"></a>

Exposes Gemini image generation as a CLI and an MCP server for agents.

```bash
brew install --cask nanobridge
nanobridge doctor
```

</details>

## Documentation

Full index in [`docs/INDEX.md`](docs/INDEX.md).
