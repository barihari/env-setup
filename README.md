# 🛠 Environment Setup for Product Designers

This repository provides a turnkey script to set up your full local development environment on macOS, plus a patch system to apply updates without re-running the full install.

---

## ✅ First-Time Setup (New Machine or Clean Environment)

If you already have GitHub and SSH configured on your machine, you can clone this repo directly:

```bash
git clone git@github.com:your-org/env-setup.git ~/env-setup
cd ~/env-setup
```

Then run the setup:

```bash
zsh turnkey.sh
```

What it does:

- Installs Homebrew, pnpm, yarn, and CLI tools
- Configures Oh My Zsh, `.zshrc`, and common plugins
- Adds your SSH key and GitHub config
- Installs Node tooling with optional `nvm`
- Clones the latest version of `my-starter` into `~/sites/my-starter`
- Adds the following terminal helpers:
  - `starter project-name` — clones a fresh copy of `my-starter` repo
  - `go` — pulls the latest updates to `~/sites/my-starter`
  - `sync-env` — applies any new patch updates to your environment

### 🩹 How Patches Work

The `patches/` folder contains small scripts that apply updates to your environment incrementally. These are used when you run:

```bash
sync-env
```

What patches do:

- Add or update shell aliases and functions (e.g. `go`, `sync-env`)
- Add supporting scripts into `~/env-setup`
- Modify your `.zshrc` or other local config files

Each patch logs a message when it's applied so you know what changed.

This lets the environment maintainer push new tooling or configuration safely, without forcing you to re-run the full setup.

- Other folders in `~/sites` are never touched

### 🔎 What is `my-starter` and why it matters

The `my-starter` folder is a shared starting point for new projects. It includes standardized configuration, starter files, and workspace rules to help:

- Align all designers on the same tooling (like Cursor settings, Tailwind setup, linters, and file structure)
- Minimize AI hallucination by giving tools like Cursor consistent, recognizable scaffolding
- Reduce the time spent reconfiguring or reinitializing every time you start a new idea or handoff

Keeping `my-starter` up to date ensures every new `starter project-name` has the latest fixes, enhancements, and conventions.

The `go` command lets you manually update the `~/sites/my-starter` source whenever you’re notified about improvements—such as updated Cursor instructions or file structure changes.

### 📁 Why `~/sites` is important

The `~/sites` folder is your centralized place for all local projects—whether they were created with `starter` or manually cloned from GitHub. Keeping all your work in this consistent location makes it easier to:

- Stay organized by separating environment setup from actual project work
- Standardize where projects live so everyone (including AI assistants) references consistent paths
- Debug issues more easily, since folder structure is predictable across teammates

Whether you're cloning a repo, creating a playground, or handing off to engineering, everything belongs in `~/sites/your-project-name`.

### 🛡 Safeguards if You Re-run `turnkey.sh`

If you accidentally run `zsh turnkey.sh` again on a machine that already has the environment set up, the script includes safeguards to prevent unwanted overwrites:

**✅ These will NOT be overwritten:**

- Any folders in `~/sites` **except** `my-starter`
- Your existing `.zshrc` entries (aliases/functions are added only if missing)
- Your `~/.env` file if already present

**♻️ These WILL be replaced or reinstalled:**

- `~/sites/my-starter` — deleted and re-cloned from GitHub to get the latest updates
- `starter` function, `go` function, and `sync-env` script — re-patched if missing or updated
- CLI tools (pnpm, yarn) re-verified via Homebrew

This lets you safely run the full script again without damaging your work, while ensuring your tooling and `my-starter` stay up to date.

## 📌 Summary

| Use Case               | Command                |
| ---------------------- | ---------------------- |
| First-time setup       | `zsh turnkey.sh`       |
| Pull updates (patches) | `sync-env`             |
| Scaffold a new project | `starter project-name` |
| Update starter folder  | `go`                   |

If you're unsure what to run, ask the environment maintainer (likely barihari).
