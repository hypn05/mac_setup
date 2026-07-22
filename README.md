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
| `zsh`    | oh-my-zsh + plugins, starship prompt, modern CLI tools, `~/.zsh/shortcut.zsh` |
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
Brewfile.git / .docker / .k8s / .zsh / .iterm   one per module, only pulled in by its own module
git/gitconfig.template   copied to ~/.gitconfig once (yours to edit after)
zsh/
  zshrc                   symlinked to ~/.zshrc — edit it here, not the symlink
  shortcut.zsh             symlinked to ~/.zsh/shortcut.zsh — the `sc` command
  zshrc.secrets.template   copied to ~/.zshrc.secrets once, chmod 600, never committed
starship.toml             symlinked to ~/.config/starship.toml
```

Config files (`zshrc`, `shortcut.zsh`, `starship.toml`) are **symlinked** so
edits in the repo take effect immediately — re-run the module to relink after
a fresh clone. Personal files (`.gitconfig`, `.zshrc.secrets`) are **copied
once** and then left alone, since they hold machine- or person-specific data
that shouldn't round-trip back into the template.

## The zsh setup

**Theme:** oh-my-zsh's `jonathan` theme, but starship (see below) overrides
the visible prompt whenever it's installed — the omz theme only matters as a
fallback if starship is ever missing.

**Plugins:** git, brew, macos, sudo, colored-man-pages, colorize, dotenv,
python, pip, autojump, zsh-autosuggestions, zsh-syntax-highlighting, kubectl,
fzf, docker, extract, copyfile, copypath, alias-finder, you-should-use,
fzf-tab. The last four aren't bundled with oh-my-zsh core; the `zsh` module
clones them into `$ZSH_CUSTOM/plugins`. `fzf-tab` (fuzzy, fzf-powered tab
completion) is deliberately last in the `plugins=(...)` list — it needs to
load after every other plugin that touches completion, and it replaces the
classic completion menu, which is why `zstyle ':completion:*' menu no` is
set instead of `menu select`.

History search is handled by **atuin** instead of an omz plugin — a
SQLite-backed Ctrl+R / up-arrow search with context (cwd, exit code,
duration). It's local-only until you opt into sync with `atuin login`.

**Prompt:** `~/.config/starship.toml` — directory, git branch/status,
kubernetes context, docker context, python venv, direnv status, and command
duration (only shown past 2s). AWS/gcloud/package modules are explicitly
silenced since they're not part of this toolchain and would otherwise add
noise. Needs a Nerd Font — the `iterm` module installs one, but you still
have to set it as the profile font by hand (see below).

**`sc` / `shortcut`:** `~/.zsh/shortcut.zsh` is a live cheatsheet over every
alias currently loaded (reads from `alias`, so it's always accurate — no
hand-maintained list to go stale):

```sh
sc                 # interactive fuzzy search (needs fzf), else prints help
sc git              # aliases whose name or expansion mentions "git"
sc kubectl          # same idea, e.g. all the kubectl-plugin shortcuts
sc query <term>     # explicit form of the above
sc --list           # everything, in one table
```

Multi-entry results always open through a full-screen pager (`less -M` by
default, or `$PAGER` if you've set one), the same alternate-screen behavior
`man` uses — no leftover scrollback clutter.

This is separate from the **you-should-use** plugin, which is the thing that
actually nudges you *after* you type something out longhand (e.g. type
`kubectl get pods`, get told you could've used `kgp`) — configured here with
`YSU_MESSAGE_POSITION=after` and `YSU_MODE=BESTMATCH` so it shows one
best-match suggestion after the command runs, not a wall of options before.

**Modern CLI tools wired into `.zshrc`:**
- `bat` → aliased to `cat`
- `eza` → aliased to `ls` / `ll` / `la` / `lt`, and to `fzf-tab`'s `cd` preview
- `lazygit` → aliased to `lg`
- `starship`, `zoxide`, `direnv`, `atuin` → hooked via `eval "$(... init zsh)"`
- `fzf` → file search backed by `fd` (via `FZF_DEFAULT_COMMAND`), tab completion via `fzf-tab`
- `git-delta` → wired in as git's pager in `gitconfig.template`, not `.zshrc`
- iTerm2 shell integration → sourced if the `iterm` module has installed it

Installed but intentionally alias-free: `ripgrep` (`rg`), `dust`, `duf`,
`yq`, `tlrc` (`tldr`), `kubectx`/`kubens`, `k9s`, `stern` — short enough
already, and aliasing over core utils like `du`/`df`/`grep` risks breaking
muscle memory or scripts that expect their exact output.

`gh` gets its own alias namespace (`gh <alias>`, separate from shell
aliases): `gh prc` (`pr create --fill`), `gh prv` (`pr view --web`), `gh prl`
(`pr list`), `gh prco` (`pr checkout`), `gh prw` (`pr checks --watch`). See
them anytime with `gh alias list`.

**Shell options:** `HYPHEN_INSENSITIVE`, `COMPLETION_WAITING_DOTS`, and a
beefed-up history setup (50k entries, shared live across sessions, deduped)
— that last one matters more than usual here since `ZSH_AUTOSUGGEST_STRATEGY`
and atuin are both driven directly off your history.

## Manual follow-ups (can't be scripted)

1. **docker**: open Docker Desktop once to finish onboarding; enable Kubernetes under Settings → Kubernetes if you want a local cluster from it instead of the `k8s` module.
2. **git**: edit `~/.gitconfig` (name/email) if it was just created; run `gh auth login`.
3. **iterm**: Preferences → Profiles → Text → Font → set to "Hack Nerd Font", so starship's icons render instead of showing as boxes.
4. **zsh**: restart your shell (`exec zsh`) to pick everything up; add real values to `~/.zshrc.secrets`; run `atuin login` if you want history synced across machines (it works local-only without this).
