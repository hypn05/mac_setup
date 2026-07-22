# Brewfile.zsh — run via: ./install.sh zsh

# Prompt / shell UX
brew "starship"   # cross-shell prompt, configured via ~/.config/starship.toml
brew "zoxide"      # smarter `cd`, learns your most-used directories
brew "autojump"    # directory jumping (used by the omz autojump plugin)
brew "direnv"      # per-directory env vars
brew "atuin"        # SQLite-backed history search (Ctrl+R / up-arrow), replaces zsh-history-substring-search

# Search / navigation
brew "fzf"          # fuzzy finder, used by the omz fzf plugin and `sc`
brew "fd"            # fast, friendly `find` replacement
brew "ripgrep"       # fast `grep` replacement (rg)

# Modern replacements for everyday CLI tools
brew "bat"     # `cat` with syntax highlighting (aliased to cat)
brew "eza"      # modern `ls` replacement (aliased to ls/ll/la/lt)
brew "dust"      # more intuitive `du`
brew "duf"        # more intuitive `df`
brew "tlrc"        # tldr client (simplified man pages)

# Data munging
brew "yq"   # YAML/JSON/XML processor (the jq of YAML)
