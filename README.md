# mac_setup

Modular new-Mac setup. Each module is independent — install only what you need.

## Usage

```sh
./install.sh <module> [module ...]
```

| Module   | Installs |
|----------|----------|
| `git`    | `git`, `gh` (+ curated `gh` aliases), `git-delta`, `lazygit`, and `~/.gitconfig` |
| `docker` | Docker Desktop (Engine, CLI, Compose v2) |
| `k8s`    | `kubectl`, `kubectx`/`kubens`, `k9s`, `stern` |
| `zsh`    | oh-my-zsh + plugins, starship prompt, modern CLI tools, `~/.zsh/shortcuts.zsh` |
| `iterm`  | iTerm2, a Nerd Font, and iTerm2 shell integration |
| `all`    | every module above |

```sh
./install.sh zsh          # just the shell setup
./install.sh git zsh      # a couple of modules
./install.sh all          # everything
```

No module depends on another, and every step checks what's already installed
before acting — safe to re-run, and safe to run in any combination. Each
module is also a standalone script (`./modules/zsh.sh`) if you'd rather skip
the dispatcher.

## Layout

```
install.sh              dispatcher — parses args, calls modules/<name>.sh
modules/
  lib.sh                 shared helpers (brew bundle, symlink, clone — all idempotent)
  git.sh docker.sh k8s.sh zsh.sh iterm.sh
Brewfile.git / .docker / .k8s / .zsh / .iterm   one per module
git/gitconfig.template   copied to ~/.gitconfig once (yours to edit after)
zsh/
  zshrc                   symlinked to ~/.zshrc — edit it here, not the symlink
  shortcuts.zsh           symlinked to ~/.zsh/shortcuts.zsh — curated `sc` registry
  shortcut.zsh            thin redirect for older name (also linked)
  zshrc.secrets.template  copied to ~/.zshrc.secrets once, chmod 600, never committed
starship.toml             symlinked to ~/.config/starship.toml
```

Config files (`zshrc`, `shortcuts.zsh`, `starship.toml`) are **symlinked** so
edits in the repo take effect immediately — re-run the module to relink after
a fresh clone. Personal files (`.gitconfig`, `.zshrc.secrets`) are **copied
once** and then left alone.

## The zsh setup

**Theme:** no OMZ theme (`ZSH_THEME=""`). **Starship** owns the prompt.

**Plugins:** git, brew, macos, sudo, colored-man-pages, colorize, dotenv,
python, pip, autojump, kubectl, fzf, docker, extract, copyfile, copypath,
alias-finder, **fzf-tab** (before autosuggestions), zsh-autosuggestions,
you-should-use, zsh-syntax-highlighting (**last**). Custom plugins are cloned
into `$ZSH_CUSTOM/plugins` by the zsh module.

**History:** **atuin** (SQLite-backed Ctrl+R / up-arrow) instead of an OMZ
history-substring plugin. Local-only until you opt into `atuin login`.

**Prompt:** calm left / right layout in `starship.toml` — directory + git on
the left; python venv, k8s context, docker context, direnv, and slow-command
duration on the right. No emoji icons by default. AWS/gcloud/package modules
are silenced.

**Venv-safe prompt:** `VIRTUAL_ENV_DISABLE_PROMPT=1` and
`unset _OLD_VIRTUAL_PS1` after Starship so `source .venv/bin/activate` cannot
wipe the prompt. Prefer project envs via **direnv**.

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
fzf, fd, ripgrep, bat, eza, dust, duf, tlrc, yq, **helix** (`hx`), **glow**.

**Editor:** Helix is the default `EDITOR` / `VISUAL` / `GIT_EDITOR` / `KUBE_EDITOR`.
Config at `helix/config.toml` → `~/.config/helix/config.toml`. Helpers:
`e` (edit path/cwd), `ef` (fuzzy file), `eg` (git-changed files), `ze` (zoxide + edit),
`hxconfig`, `mdv` (glow). Tutorial: `hx --tutor`.

**tmux:** config at `tmux/tmux.conf` → `~/.tmux.conf` (prefix **Ctrl-a**, mouse,
vim-style panes). Shell helpers: `tn` / `ta` / `ts` / `tls` / `tk` / `thelp`.
Cheatsheet: `thelp` or `sc tmux`.

**Also wired:**
- FZF defaults backed by `fd` (Ctrl+T / Alt+C)
- Word movement (Ctrl+←/→)
- Large shared history (50k, share + inc-append + dedupe)
- `DISABLE_UNTRACKED_FILES_DIRTY` for big repos
- Fuzzy helpers: `gcof` (git checkout), `dsh` / `dlof` (docker shell / logs)

**k8s module extras:** `k9s`, `stern` (+ `k9` / `kstern` shortcuts when present).

**git module:** delta (side-by-side), lazygit, `gh` aliases
(`prc`, `prv`, `prl`, `prco`, `prw`), sensible defaults
(`pull.rebase`, `push.autoSetupRemote`, `init.defaultBranch=main`).

## Manual follow-ups (can't be scripted)

1. **docker**: open Docker Desktop once; enable Kubernetes in Settings if you want a local cluster from it.
2. **git**: edit `~/.gitconfig` (name/email) if just created; run `gh auth login`.
3. **iterm**: Preferences → Profiles → Text → Font → "Hack Nerd Font" only if you re-enable icon glyphs.
4. **zsh**: `exec zsh`; fill `~/.zshrc.secrets`; optional `atuin login` for multi-machine history sync.
