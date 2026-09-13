# keep-awake ⚡

> Minimal, zero-bloat CLI to keep your laptop awake (even with lid closed) on macOS and Linux.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-blue.svg)](#how-it-works)

`keep-awake` (or simply `awake`) is a transparent, lightweight command-line tool that prevents system sleep, screen sleep, and clamshell/lid-closed sleep.

---

## Why keep-awake?

Many existing tools (like Capsomnia or Amphetamine) require:
* ⚠️ Accessibility permissions (granting global keyboard event taps)
* ⚠️ Modifying `/etc/sudoers` with dangerous `NOPASSWD` rules
* ⚠️ Background daemons (`LaunchAgents`) running 24/7 in memory
* ⚠️ Heavy UI frameworks or third-party auto-update daemons

`keep-awake` takes the native, zero-bloat approach:
* ✅ **Zero daemons:** runs only when you need it and exits cleanly.
* ✅ **Zero sudoers tampering:** uses standard temporary `sudo` on macOS and unprivileged `systemd-inhibit` on Linux.
* ✅ **Zero accessibility hooks:** no keyboard monitoring, no keylogging risk.
* ✅ **Guaranteed cleanup:** uses POSIX `trap` to re-enable normal sleep as soon as the timer expires or `Ctrl+C` is pressed.
* ✅ **Battery warning:** alerts you if running on battery below 15%.

---

## Installation

### One-liner (Remote)

```bash
curl -fsSL https://raw.githubusercontent.com/r1cc4rd0m4zz4/keep-awake/main/install.sh | bash
```

### From Local Clone

```bash
git clone https://github.com/r1cc4rd0m4zz4/keep-awake.git
cd keep-awake
./install.sh
```

The installer places `keep-awake` and an `awake` shorthand symlink into `~/.local/bin/`.

Ensure `~/.local/bin` is in your `$PATH`:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## Usage

```bash
# Keep awake for the default duration (60 minutes)
awake

# Specify custom duration (supports h, m, s)
awake 45m
awake 2h
awake 3600s

# Keep awake only for the duration of a command or script
awake -c "npm run build"
awake -c "python train_model.py"

# Stop anytime
Press Ctrl + C
```

---

## How It Works

### macOS
* Invokes the native Apple `/usr/bin/pmset -a disablesleep 1` command to prevent all sleep modes (including closed-lid clamshell without an external display).
* Registers a `trap` for `INT`, `TERM`, and `EXIT` signals to immediately restore `/usr/bin/pmset -a disablesleep 0`.

### Linux
* Uses `systemd-inhibit --what="idle:sleep:handle-lid-switch"`.
* Requires no root privileges on modern systemd/logind distributions (Ubuntu, Debian, Fedora, Arch, etc.).
* Releases the inhibitor lock automatically upon exit.

---

## Hardware & Thermal Notice

⚠️ **Do NOT place your laptop inside a backpack or enclosed bag while `keep-awake` is active with the lid closed.** Laptops require adequate ventilation to dissipate heat; running intensive workloads in an enclosed space can cause thermal throttling or battery degradation.

---

## Uninstallation

```bash
# Using the installer
./install.sh --uninstall

# Or manually
rm -f ~/.local/bin/keep-awake ~/.local/bin/awake
```

---

## License

MIT License © 2025 r1cc4rd0m4zz4
