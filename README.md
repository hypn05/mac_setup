# dev_setup

Modular developer environment setup for **macOS**, **Linux**, and **Windows (WSL2 / Ubuntu)**.
Each module is independent — install only what you need. The goal is the same
shell feel everywhere: Starship, oh-my-zsh, `sc` shortcuts, atuin, Helix, tmux,
and the same git/k8s CLIs.

> Formerly `mac_setup`. The folder/remote may still use that name until renamed;
> branding and scripts say `dev_setup`.

## Quick starts

### macOS

```sh
./install.sh all          # or: git docker k8s zsh editor iterm
./install.sh doctor
exec zsh
```

Packages install via Homebrew. `iterm` is available only on macOS.

### Linux (Ubuntu/Debian)

```sh
sudo apt update && sudo apt install -y build-essential curl file git
./install.sh all          # git docker k8s zsh editor  (no iterm)
./install.sh doctor
exec zsh
```

Uses **Homebrew on Linux** (Linuxbrew) so the same Brewfiles work as on macOS.
Docker installs Engine + Compose via Docker’s apt repo (not a Desktop cask).

### Windows (WSL2)

On the **Windows host** (PowerShell):

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\windows\bootstrap.ps1
```

Then inside **Ubuntu (WSL)**:

```sh
sudo apt update && sudo apt install -y build-essential curl file git
./install.sh all
./install.sh doctor
exec zsh
```

Prefer **Docker Desktop for Windows** with WSL integration enabled (closest to
macOS). If the daemon is missing, `./install.sh docker` prints those steps; set
`DOCKER_ENGINE_IN_WSL=1` only if you want Engine installed inside WSL instead.

## Usage

```sh
./install.sh <module> [module ...]
```

| Module   | Installs |
|----------|----------|
| `git`    | `git`, `gh` (+ curated `gh` aliases), `git-delta`, `lazygit`, and `~/.gitconfig` |
| `docker` | macOS: Docker Desktop · Linux: Engine + Compose · WSL: Desktop integration (or Engine fallback) |
| `k8s`    | `kubectl`, `kubectx`/`kubens`, `k9s`, `stern` |
| `zsh`    | oh-my-zsh + plugins, starship, atuin, **theme.sh** (400+ palettes, fzf preview), `sc` shortcuts, **pbcopy/pbpaste shims** on Linux/WSL |
| `editor` | Helix, glow, tmux (+ configs) and `tmux-copy` clipboard helper |
| `wezterm`| WezTerm + shared config — **Super+C/V = macOS Cmd+C/V** (recommended on Linux/WSL) |
| `iterm`  | iTerm2 + shell integration (**macOS only**; Nerd Font is opt-in) |
| `all`    | every installable module for the detected OS |
| `doctor` | read-only health check — installs nothing |

```sh
./install.sh zsh          # just the shell setup
./install.sh git zsh      # a couple of modules
./install.sh all          # everything for this OS
./install.sh doctor       # check what's actually in place
```

`install.sh` detects `macos` / `linux` / `wsl` and refuses modules that don’t
apply (e.g. `iterm` on Linux). No module depends on another; every step checks
what’s already installed — safe to re-run. Each module is also a standalone
script (`./modules/zsh.sh`) if you’d rather skip the dispatcher.

### Module availability

| Module | macOS | Linux | WSL |
|--------|:-----:|:-----:|:---:|
| git, k8s, zsh, editor, wezterm | ✓ | ✓ | ✓ |
| docker | Desktop cask | Engine (apt) | Desktop+WSL preferred |
| iterm | ✓ | — | — |

### Same shortcuts everywhere (copy / paste)

| Action | macOS (iTerm) | Linux / Windows (WezTerm) | Shell (all OSes) |
|--------|---------------|---------------------------|------------------|
| Copy selection | **Cmd+C** | **Super+C** (same key as Cmd on a Mac keyboard) or Ctrl+Shift+C | `pbcopy` / `clipcopy` / `scpath` |
| Paste | **Cmd+V** | **Super+V** or Ctrl+Shift+V | `pbpaste` / `clippaste` |
| tmux yank | `y` / mouse drag → clipboard | same | via `tmux-copy` → `pbcopy` |

On Linux/WSL the zsh module installs **`pbcopy` / `pbpaste` shims** in `~/.local/bin`, so every alias and OMZ helper that expects the macOS names keeps working. Run `./install.sh wezterm` so the GUI terminal uses the same chords as iTerm. Browse them anytime with `sc keys`.

## Layout

```
install.sh              dispatcher — OS detect, parses args, calls modules/<name>.sh
windows/bootstrap.ps1   Windows host: WSL2/Ubuntu + WezTerm/Docker hints
modules/
  lib.sh                 shared helpers (OS detect, brew, symlink, clone — idempotent)
  git.sh docker.sh k8s.sh zsh.sh editor.sh wezterm.sh iterm.sh
  doctor.sh              read-only health check, no installs
Brewfile.*               one per module (formulas reuse on Linuxbrew; docker cask is macOS)
bin/pbcopy pbpaste       macOS-named clipboard shims for Linux/WSL
bin/tmux-copy            tmux copy-pipe → pbcopy (native or shim)
bin/theme.sh             terminal theme switcher (400+ palettes, fzf preview)
wezterm/wezterm.lua      Super+C/V = Cmd+C/V; linked to ~/.wezterm.lua
git/gitconfig.template   copied to ~/.gitconfig once (yours to edit after)
zsh/
  zshrc                   symlinked to ~/.zshrc — edit it here, not the symlink
  shortcuts.zsh           symlinked to ~/.zsh/shortcuts.zsh — curated `sc` registry
  zshrc.secrets.template  copied to ~/.zshrc.secrets once, chmod 600, never committed
starship.toml             symlinked to ~/.config/starship.toml
helix/config.toml         symlinked to ~/.config/helix/config.toml (editor module)
tmux/tmux.conf            symlinked to ~/.tmux.conf (editor module)
.envrc.example            copy to .envrc per-project for direnv; .envrc is gitignored
```

Config files (`zshrc`, `shortcuts.zsh`, `starship.toml`, `helix/config.toml`,
`tmux/tmux.conf`) are **symlinked** so edits in the repo take effect
immediately — re-run the module to relink after a fresh clone. Personal files
(`.gitconfig`, `.zshrc.secrets`) are **copied once** and then left alone.

## The zsh setup

**Theme:** no OMZ theme (`ZSH_THEME=""`). **Starship** owns the prompt.

**Plugins:** git, sudo, colored-man-pages, colorize, dotenv, python, pip,
autojump, kubectl, fzf, docker, extract, copyfile, copypath, alias-finder,
**fzf-tab** (before autosuggestions), zsh-autosuggestions, you-should-use,
zsh-syntax-highlighting (**last**). **`brew`** is added only when `brew` is on
PATH; **`macos`** only on Darwin. Custom plugins are cloned into
`$ZSH_CUSTOM/plugins` by the zsh module.

**History:** **atuin** (SQLite-backed Ctrl+R / up-arrow) instead of an OMZ
history-substring plugin. Local-only until you opt into `atuin login`.

**Prompt:** calm left / right layout in `starship.toml` — directory + git on
the left; python venv, k8s context, docker context, direnv, and slow-command
duration on the right. No emoji icons by default. AWS/gcloud/package modules
are silenced.

**Venv-safe prompt:** `VIRTUAL_ENV_DISABLE_PROMPT=1` and
`unset _OLD_VIRTUAL_PS1` after Starship so `source .venv/bin/activate` cannot
wipe the prompt. Prefer project envs via **direnv** — copy `.envrc.example` to
`.envrc` per project (gitignored) and run `direnv allow`.

**`sc` / `shortcuts`:** curated registry with categories + descriptions
(git, k8s, docker/compose, files, search, util, keys, editor, tmux). Also:

```sh
sc                 # interactive browser (fzf)
sc git | sc docker # category filter
sc --live          # every currently loaded alias (OMZ + yours)
sc --list          # full curated table
```

**you-should-use** reminds you after you type a long form (`git status` → use
`gst`). Configured with `YSU_MESSAGE_POSITION=after`, `YSU_MODE=BESTMATCH`,
and `YSU_IGNORED_ALIASES=(g k)`.

**Modern CLI tools (Brewfile.zsh):** starship, zoxide, autojump, direnv, atuin,
fzf, fd, ripgrep, bat, eza, dust, duf, tlrc, yq.

**Terminal themes (`theme.sh`):** we ship [lemnos/theme.sh](https://github.com/lemnos/theme.sh)
instead of walh-shell — same instant OSC palette switching, but with an **fzf
preview pane** so you can browse before committing (walh’s gap). Also: live
browse mode, dark/light filters, 400+ themes, history restore on new shells.

```sh
th              # interactive picker with preview (fzf)
thd / thl       # dark-only / light-only picker
thlive          # apply each theme to the terminal as you arrow through
th gruvbox      # set a theme by name
thrand          # random theme
sc theme        # registry of theme shortcuts
# Ctrl+O        # previous theme
```

Works in iTerm2 and WezTerm (OSC 4/11). tmux has `allow-passthrough` enabled so
colors can update from inside a session.

**Doctor:** `sc doctor` (or `./install.sh doctor` from the repo) is a
read-only pass over every module — installed brew formulae (and OS-aware docker
checks), symlinks pointing where they should, `~/.zshrc.secrets` present and
`chmod 600`, gh aliases set. Installs nothing; safe to run anytime something
feels off.

**Also wired:**
- FZF defaults backed by `fd` (Ctrl+T / Alt+C)
- Word movement (Ctrl+←/→)
- Large shared history (50k, share + inc-append + dedupe)
- `DISABLE_UNTRACKED_FILES_DIRTY` for big repos
- Fuzzy helpers: `gcof` (git checkout), `dsh` / `dlof` (docker shell / logs)
- `~/.local/bin` on PATH (for `tmux-copy` and user tools)
- Linuxbrew / Homebrew shellenv fallback if `brew` isn’t on PATH yet

## The editor module (optional)

Not pulled in by `zsh` — `EDITOR`/`VISUAL`/`GIT_EDITOR`/`KUBE_EDITOR` and the
shortcuts below all auto-detect and fall back to `vim`/`vi` if you skip it.

**Helix** is the default `EDITOR` when installed. Config at
`helix/config.toml` → `~/.config/helix/config.toml`. Helpers: `e` (edit
path/cwd), `ef` (fuzzy file), `eg` (git-changed files), `ze` (zoxide + edit),
`hxconfig`, `mdv` (glow). Tutorial: `hx --tutor`.

**tmux** config at `tmux/tmux.conf` → `~/.tmux.conf` (prefix **Ctrl-a**,
mouse, vim-style panes). Copy-pipe uses `tmux-copy` (`~/.local/bin`), which
picks `pbcopy` / `wl-copy` / `xclip` / `clip.exe` (WSL). Shell helpers: `tn` /
`ta` / `ts` / `tls` / `tk` / `thelp`. Cheatsheet: `thelp` or `sc tmux`.

## Other module notes

**k8s:** `k9s`, `stern` (+ `k9` / `kstern` shortcuts when present, via the zsh module).

**git:** delta (side-by-side), lazygit, `gh` aliases
(`prc`, `prv`, `prl`, `prco`, `prw`), sensible defaults
(`pull.rebase`, `push.autoSetupRemote`, `init.defaultBranch=main`).

**docker:**
- **macOS** — Docker Desktop cask; open the app once.
- **Linux** — Docker Engine + Compose plugin; log out / `newgrp docker` after.
- **WSL** — use Docker Desktop on Windows + WSL integration when possible.

## Recommended terminals

| OS | Terminal |
|----|----------|
| macOS | iTerm2 (`./install.sh iterm`) and/or WezTerm (`./install.sh wezterm`) |
| Linux | **WezTerm** (`./install.sh wezterm`) — Super+C/V matches macOS Cmd+C/V |
| Windows | **WezTerm** on the host + WSL profile (`./install.sh wezterm` from Ubuntu links the config) |

Shared config: `wezterm/wezterm.lua` → `~/.wezterm.lua`. Starship ships **icon-free** by default, so a Nerd Font is optional.

## Manual follow-ups (can't be scripted)

1. **docker**: macOS — open Docker Desktop once; optional Kubernetes in Settings. Linux — re-login for the `docker` group. WSL — enable Desktop WSL integration.
2. **git**: edit `~/.gitconfig` (name/email) if just created; run `gh auth login`.
3. **iterm** (macOS): shell integration is automatic via the zsh module. Nerd Font is opt-in — only needed if you re-enable icon glyphs in `starship.toml`.
4. **zsh**: `exec zsh`; fill `~/.zshrc.secrets`; optional `atuin login` for multi-machine history sync. On Linux/WSL, ensure `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"` is in `~/.zprofile` if brew isn’t on PATH after install.
5. **editor**: run it if you want Helix/tmux; otherwise `EDITOR` falls back to vim/vi automatically.
