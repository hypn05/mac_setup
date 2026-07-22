# =============================================================================
# Shortcuts registry + discovery
#
# Usage:
#   sc / shortcuts         Interactive browser (fzf) or full table
#   sc <query>             Filter by name, category, or description
#   sc git | sc k8s | sc docker | sc keys
#   sc --list              Full curated table (no fzf)
#   sc --live [term]       All currently loaded aliases (OMZ + curated)
#   type <alias>           Show expansion
#
# you-should-use reminds you when a shorter alias exists for a command you type.
# =============================================================================

typeset -gA _SC_DESC _SC_CAT

# Register: _sc_add <alias> <category> <description> <command string>
_sc_add() {
  local name="$1" cat="$2" desc="$3" cmd="$4"
  _SC_DESC[$name]="$desc"
  _SC_CAT[$name]="$cat"
  alias -- "$name=$cmd"
}

# -------------------------- Git ---------------------------------------------
# For you-should-use: expansion should be a prefix of what you type.
_sc_add gst    git "Git status"                    'git status'
_sc_add gsb    git "Short git status (branch)"     'git status -sb'
_sc_add gss    git "Short git status"              'git status --short'
_sc_add gco    git "Checkout branch/commit"        'git checkout'
_sc_add gcb    git "Create and checkout branch"    'git checkout -b'
_sc_add gaa    git "Stage all changes"             'git add --all'
_sc_add gcmsg  git "Commit with message"           'git commit -m'
_sc_add gp     git "Push to remote"                'git push'
_sc_add gl     git "Pull from remote"              'git pull'
_sc_add gd     git "Diff unstaged (delta pager)"   'git diff'
_sc_add gds    git "Diff staged (delta pager)"     'git diff --staged'
_sc_add glog   git "Pretty one-line graph log"     'git log --oneline --graph --decorate -20'
_sc_add gloga  git "Graph log (all branches)"      'git log --oneline --graph --decorate --all -30'
_sc_add gundo  git "Undo last commit (keep files)" 'git reset --soft HEAD~1'

if (( $+commands[lazygit] )); then
  _sc_add lg   git "Lazygit TUI"                   'lazygit'
fi

if (( $+commands[delta] )); then
  _SC_DESC[delta]="Git diff pager (configured as core.pager)"
  _SC_CAT[delta]="git"
fi

# Fuzzy checkout branch (local + remote)
gcof() {
  local b
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print -u2 "Not a git repository"
    return 1
  fi
  if ! (( $+commands[fzf] )); then
    print -u2 "fzf required for gcof"
    return 1
  fi
  b=$(git branch -a --format='%(refname:short)' 2>/dev/null \
    | sed 's|^origin/||' | sort -u \
    | fzf --height=40% --reverse --border --prompt='branch> ') || return
  [[ -n "$b" ]] && git checkout "$b"
}
_SC_DESC[gcof]="Fuzzy checkout branch (fzf)"
_SC_CAT[gcof]="git"

# -------------------------- Kubernetes --------------------------------------
_sc_add k      k8s "kubectl shorthand"             'kubectl'
_sc_add kgp    k8s "Get pods"                      'kubectl get pods'
_sc_add kgpa   k8s "Get pods (all namespaces)"     'kubectl get pods -A'
_sc_add kgs    k8s "Get services"                  'kubectl get svc'
_sc_add kgd    k8s "Get deployments"               'kubectl get deploy'
_sc_add kgn    k8s "Get nodes"                     'kubectl get nodes'
_sc_add kdp    k8s "Describe pod"                  'kubectl describe pod'
_sc_add kl     k8s "Logs from pod"                 'kubectl logs'
_sc_add klf    k8s "Follow logs"                   'kubectl logs -f'
_sc_add kex    k8s "Exec shell into pod"           'kubectl exec -it'
_sc_add kctx   k8s "Switch kube context"           'kubectl config use-context'
_sc_add kns    k8s "Set current namespace"         'kubectl config set-context --current --namespace'
_sc_add kctxs  k8s "List contexts"                 'kubectl config get-contexts'
_sc_add kga    k8s "Get all in namespace"          'kubectl get all'

if (( $+commands[kubectx] )); then
  _sc_add kx   k8s "Switch context (kubectx/fzf)"  'kubectx'
  _sc_add kxc  k8s "Current context"               'kubectx -c'
fi
if (( $+commands[kubens] )); then
  _sc_add kn   k8s "Switch namespace (kubens/fzf)" 'kubens'
  _sc_add knc  k8s "Current namespace"             'kubens -c'
fi
if (( $+commands[k9s] )); then
  _sc_add k9   k8s "Kubernetes TUI (k9s)"          'k9s'
fi
if (( $+commands[stern] )); then
  _sc_add kstern k8s "Multi-pod log tail (stern)"  'stern'
fi

# -------------------------- Docker / Compose --------------------------------
if (( $+commands[docker] )); then
  _sc_add dps    docker "List running containers"       'docker ps'
  _sc_add dpsa   docker "List all containers"           'docker ps -a'
  _sc_add dpu    docker "Pull image"                    'docker pull'
  _sc_add dbl    docker "Build image"                   'docker build'
  _sc_add dils   docker "List images"                   'docker image ls'
  _sc_add dirm   docker "Remove image"                  'docker image rm'
  _sc_add dr     docker "Run container"                 'docker container run'
  _sc_add drit   docker "Run container interactive"     'docker container run -it'
  _sc_add dst    docker "Start container"               'docker container start'
  _sc_add dstp   docker "Stop container"                'docker container stop'
  _sc_add drs    docker "Restart container"             'docker container restart'
  _sc_add drm    docker "Remove container"              'docker container rm'
  _sc_add 'drm!' docker "Force remove container"        'docker container rm -f'
  _sc_add dlo    docker "Container logs"                'docker container logs'
  _sc_add dxc    docker "Exec in container"             'docker container exec'
  _sc_add dxcit  docker "Exec interactive shell"        'docker container exec -it'
  _sc_add dsta   docker "Stop all running containers"   'docker stop $(docker ps -q)'
  _sc_add dsprune docker "Prune unused docker data"     'docker system prune'
  _sc_add dsts   docker "Live container stats"          'docker stats'
  _sc_add dvls   docker "List volumes"                  'docker volume ls'
  _sc_add dnls   docker "List networks"                 'docker network ls'

  if docker compose version >/dev/null 2>&1; then
    _dccmd='docker compose'
  elif (( $+commands[docker-compose] )); then
    _dccmd='docker-compose'
  else
    _dccmd=''
  fi
  if [[ -n "$_dccmd" ]]; then
    _sc_add dco    docker "Docker Compose shorthand"    "$_dccmd"
    _sc_add dcup   docker "Compose up"                  "$_dccmd up"
    _sc_add dcupd  docker "Compose up detached"         "$_dccmd up -d"
    _sc_add dcupb  docker "Compose up --build"          "$_dccmd up --build"
    _sc_add dcdn   docker "Compose down"                "$_dccmd down"
    _sc_add dcps   docker "Compose ps"                  "$_dccmd ps"
    _sc_add dcl    docker "Compose logs"                "$_dccmd logs"
    _sc_add dclf   docker "Compose logs follow"         "$_dccmd logs -f"
    _sc_add dcb    docker "Compose build"               "$_dccmd build"
    _sc_add dce    docker "Compose exec"                "$_dccmd exec"
    _sc_add dcr    docker "Compose run"                 "$_dccmd run"
    _sc_add dcstop docker "Compose stop"                "$_dccmd stop"
    _sc_add dcrestart docker "Compose restart"          "$_dccmd restart"
    _sc_add dcpull docker "Compose pull images"         "$_dccmd pull"
  fi
  unset _dccmd

  dsh() {
    local c
    if ! (( $+commands[fzf] )); then
      print -u2 "fzf required for dsh"
      return 1
    fi
    c=$(docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null \
      | fzf --height=40% --reverse --border --prompt='container> ' \
          --with-nth=1,2,3 | awk '{print $1}') || return
    [[ -z "$c" ]] && return 1
    docker exec -it "$c" sh -c 'command -v bash >/dev/null && exec bash || exec sh'
  }
  _SC_DESC[dsh]="Fuzzy shell into running container (fzf)"
  _SC_CAT[dsh]="docker"

  dlof() {
    local c
    if ! (( $+commands[fzf] )); then
      print -u2 "fzf required for dlof"
      return 1
    fi
    c=$(docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null \
      | fzf --height=40% --reverse --border --prompt='logs> ' \
          --with-nth=1,2,3 | awk '{print $1}') || return
    [[ -n "$c" ]] && docker logs -f --tail 100 "$c"
  }
  _SC_DESC[dlof]="Fuzzy pick container + follow logs"
  _SC_CAT[dlof]="docker"
fi

# -------------------------- Navigation / files ------------------------------
if (( $+commands[eza] )); then
  _sc_add ll   files "Long list with git (eza)"    'eza -lah --git --group-directories-first'
  _sc_add la   files "All files (eza)"             'eza -lah --git'
  _sc_add lt   files "Tree view depth 2 (eza)"     'eza -lah --tree --level=2 --git'
  _sc_add l    files "Simple list (eza)"           'eza -lh --git'
else
  _sc_add ll   files "Long list"                   'ls -lah'
  _sc_add la   files "All files"                   'ls -lah'
  _sc_add l    files "Simple list"                 'ls -lh'
fi

alias -- '..'='cd ..'
alias -- '...'='cd ../..'
alias -- '....'='cd ../../..'
_sc_dot1='..' _sc_dot2='...' _sc_dot3='....'
_SC_DESC[$_sc_dot1]="Up one directory";      _SC_CAT[$_sc_dot1]="files"
_SC_DESC[$_sc_dot2]="Up two directories";    _SC_CAT[$_sc_dot2]="files"
_SC_DESC[$_sc_dot3]="Up three directories";  _SC_CAT[$_sc_dot3]="files"
unset _sc_dot1 _sc_dot2 _sc_dot3

if (( $+commands[bat] )); then
  _sc_add cat  files "Syntax-highlighted cat"      'bat --paging=never'
  _sc_add preview files "Page a file with bat"     'bat'
fi

if (( $+commands[dust] )); then
  _SC_DESC[dust]="Disk usage by directory (better du)"
  _SC_CAT[dust]="files"
fi
if (( $+commands[duf] )); then
  _SC_DESC[duf]="Disk free overview (better df)"
  _SC_CAT[duf]="files"
fi

alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'
_SC_DESC[rm]="Remove (interactive confirm)"
_SC_CAT[rm]="files"
_SC_DESC[mv]="Move (interactive confirm)"
_SC_CAT[mv]="files"
_SC_DESC[cp]="Copy (interactive confirm)"
_SC_CAT[cp]="files"

if (( $+commands[zoxide] )) || (( $+commands[z] )); then
  _SC_DESC[z]="Jump to frecent directory (zoxide)"
  _SC_CAT[z]="files"
  _SC_DESC[zi]="Interactive directory picker (zoxide)"
  _SC_CAT[zi]="files"
fi
if (( $+commands[autojump] )) || (( $+functions[j] )) || (( $+aliases[j] )); then
  _SC_DESC[j]="Autojump to frequent directory"
  _SC_CAT[j]="files"
fi

# -------------------------- Search / data -----------------------------------
if (( $+commands[fd] )); then
  _SC_DESC[fd]="Find files by name (use instead of find)"
  _SC_CAT[fd]="search"
fi
if (( $+commands[rg] )); then
  _SC_DESC[rg]="Fast search in files (use instead of grep)"
  _SC_CAT[rg]="search"
fi
if (( $+commands[yq] )); then
  _SC_DESC[yq]="YAML processor (jq for YAML)"
  _SC_CAT[yq]="search"
fi
if (( $+commands[tldr] )); then
  _SC_DESC[tldr]="Practical command examples (man alternative)"
  _SC_CAT[tldr]="util"
fi

# -------------------------- Editor (Helix) ----------------------------------
# Helpers honor $EDITOR (set to hx in .zshrc when Helix is installed).
e() {
  if (( $# )); then
    ${EDITOR:-hx} "$@"
  else
    ${EDITOR:-hx} .
  fi
}
_SC_DESC[e]="Edit path or open editor in cwd (Helix)"
_SC_CAT[e]="editor"

ef() {
  local f
  if ! (( $+commands[fzf] )); then
    print -u2 "fzf required for ef"
    return 1
  fi
  if (( $+commands[fd] )); then
    f=$(fd --type f --hidden --follow --exclude .git 2>/dev/null \
      | fzf --height=60% --reverse --border --prompt='edit> ' \
          --preview 'bat --color=always --style=numbers --line-range=:80 {} 2>/dev/null || head -80 {}') || return
  else
    f=$(find . -type f -not -path '*/.git/*' 2>/dev/null \
      | fzf --height=60% --reverse --border --prompt='edit> ') || return
  fi
  [[ -n "$f" ]] && ${EDITOR:-hx} "$f"
}
_SC_DESC[ef]="Fuzzy-find file and open in editor"
_SC_CAT[ef]="editor"

eg() {
  local -a files
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print -u2 "Not a git repository"
    return 1
  fi
  if ! (( $+commands[fzf] )); then
    print -u2 "fzf required for eg"
    return 1
  fi
  files=(${(f)"$(git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null)"})
  (( ${#files} )) || files=(${(f)"$(git show --pretty='' --name-only HEAD 2>/dev/null)"})
  if (( ${#files} == 0 )); then
    print -u2 "No changed files"
    return 1
  fi
  local picked
  picked=$(printf '%s\n' "${files[@]}" | sort -u \
    | fzf --height=60% --reverse --border --multi --prompt='git edit> ' \
        --preview 'bat --color=always --style=numbers --line-range=:80 {} 2>/dev/null || head -80 {}') || return
  [[ -n "$picked" ]] && ${EDITOR:-hx} ${=picked}
}
_SC_DESC[eg]="Fuzzy-edit git-changed files"
_SC_CAT[eg]="editor"

ze() {
  if (( $+commands[zoxide] )) && (( $# )); then
    z "$@" && ${EDITOR:-hx} .
  else
    ${EDITOR:-hx} "${1:-.}"
  fi
}
_SC_DESC[ze]="zoxide jump then open editor in directory"
_SC_CAT[ze]="editor"

hxconfig() { ${EDITOR:-hx} "${XDG_CONFIG_HOME:-$HOME/.config}/helix/config.toml" }
_SC_DESC[hxconfig]="Edit Helix config"
_SC_CAT[hxconfig]="editor"

if (( $+commands[glow] )); then
  # `md` is taken by OMZ (mkdir -p); use mdv for "markdown view"
  mdv() {
    if (( $# )); then
      glow "$@"
    else
      local f
      f=$(fd --type f -e md -e markdown 2>/dev/null | fzf --height=40% --reverse --prompt='mdv> ') || return
      [[ -n "$f" ]] && glow "$f"
    fi
  }
  _SC_DESC[mdv]="Render markdown with glow (or fuzzy-pick)"
  _SC_CAT[mdv]="editor"
  _SC_DESC[glow]="Markdown viewer in the terminal"
  _SC_CAT[glow]="editor"
fi

if (( $+commands[hx] )); then
  _SC_DESC[hx]="Helix terminal editor (default EDITOR)"
  _SC_CAT[hx]="editor"
fi

# -------------------------- Everyday productivity ---------------------------
if (( $+functions[web_search] )) || (( $+aliases[web_search] )); then
  _sc_add ws util "Web search (Google)" 'web_search google'
fi
_sc_add zshreload util "Reload shell (fresh zsh)"  'exec zsh'

zshconfig() { ${EDITOR:-hx} ~/.zshrc }
_SC_DESC[zshconfig]="Edit ~/.zshrc"
_SC_CAT[zshconfig]="util"

starconfig() { ${EDITOR:-hx} ~/.config/starship.toml }
_SC_DESC[starconfig]="Edit starship prompt config"
_SC_CAT[starconfig]="util"

scpath() {
  if (( $+commands[pbcopy] )); then
    pwd | pbcopy && print "path copied: $(pwd)"
  else
    pwd
  fi
}
_SC_DESC[scpath]="Copy current path to clipboard"
_SC_CAT[scpath]="util"

please() { sudo $(fc -ln -1) }
_SC_DESC[please]="Re-run last command with sudo"
_SC_CAT[please]="util"

h() {
  if (( $+commands[rg] )); then
    fc -l 1 | rg --color=always "$@" | tail -80
  else
    fc -l 1 | grep -i -- "$@" | tail -80
  fi
}
_SC_DESC[h]="Search shell history"
_SC_CAT[h]="util"

if (( $+commands[direnv] )); then
  _SC_DESC[direnv]="Per-directory env (use: direnv allow)"
  _SC_CAT[direnv]="util"
fi
if (( $+commands[atuin] )); then
  _SC_DESC[atuin]="SQLite-backed history search (Ctrl+R / up-arrow)"
  _SC_CAT[atuin]="util"
fi

# gh CLI aliases are under `gh <alias>` — document common ones from the git module
if (( $+commands[gh] )); then
  _SC_DESC[gh]="GitHub CLI (also: gh prc/prv/prl/prco/prw if installed)"
  _SC_CAT[gh]="git"
fi

# -------------------------- tmux --------------------------------------------
if (( $+commands[tmux] )); then
  _sc_add tls  tmux "List tmux sessions"              'tmux ls'
  _sc_add tnew tmux "New session (optional name)"     'tmux new -s'
  _sc_add tks  tmux "Kill named session"              'tmux kill-session -t'
  _sc_add tkw  tmux "Kill current window"             'tmux kill-window'
  _sc_add tkp  tmux "Kill current pane"               'tmux kill-pane'
  _sc_add tdet tmux "Detach from session"             'tmux detach'

  # Attach: named session, or last if none given
  ta() {
    if (( $# )); then
      tmux attach -t "$@"
    else
      tmux attach || tmux new -s main
    fi
  }
  _SC_DESC[ta]="Attach to session (or create main)"
  _SC_CAT[ta]="tmux"

  # New session named after cwd (or arg)
  tn() {
    local name="${1:-${PWD:t}}"
    name="${name//./-}"
    tmux has-session -t "$name" 2>/dev/null && tmux attach -t "$name" && return
    tmux new -s "$name"
  }
  _SC_DESC[tn]="New/attach session named after cwd or arg"
  _SC_CAT[tn]="tmux"

  # Fuzzy pick a session (or create)
  ts() {
    local s
    if ! (( $+commands[fzf] )); then
      tmux ls 2>/dev/null || print -u2 "No sessions"
      return 1
    fi
    if ! tmux ls >/dev/null 2>&1; then
      print "No sessions — starting 'main'"
      tmux new -s main
      return
    fi
    s=$(tmux ls -F '#{session_name}: #{session_windows} windows#{?session_attached, (attached),}' 2>/dev/null \
      | fzf --height=40% --reverse --border --prompt='session> ' \
      | cut -d: -f1) || return
    [[ -n "$s" ]] && tmux attach -t "$s"
  }
  _SC_DESC[ts]="Fuzzy attach to a tmux session"
  _SC_CAT[ts]="tmux"

  tk() {
    local s
    if (( $# )); then
      tmux kill-session -t "$@"
      return
    fi
    if ! (( $+commands[fzf] )); then
      print -u2 "usage: tk <session>"
      return 1
    fi
    s=$(tmux ls -F '#{session_name}' 2>/dev/null \
      | fzf --height=40% --reverse --border --prompt='kill> ') || return
    [[ -n "$s" ]] && tmux kill-session -t "$s" && print "killed $s"
  }
  _SC_DESC[tk]="Kill session (arg or fzf pick)"
  _SC_CAT[tk]="tmux"

  tmuxconfig() {
    ${EDITOR:-hx} "${HOME}/.tmux.conf"
  }
  _SC_DESC[tmuxconfig]="Edit ~/.tmux.conf"
  _SC_CAT[tmuxconfig]="tmux"

  # Full cheatsheet (keys + shell helpers)
  thelp() {
    cat <<'EOF'
tmux help — prefix is Ctrl-a  (configured in ~/.tmux.conf)

SESSIONS (shell)
  tn [name]     New session (default: cwd name) or attach if exists
  ta [name]     Attach (no name → last / create main)
  ts            Fuzzy pick session → attach
  tls           List sessions
  tk [name]     Kill session (fzf if no name)
  tdet          Detach current client
  thelp         This help
  sc tmux       Registry of shortcuts

PREFIX KEYS  (press Ctrl-a, then key)
  r             Reload ~/.tmux.conf
  c             New window (same directory)
  |  /  -       Split horizontal / vertical
  h j k l       Move between panes (vim keys)
  H J K L       Resize pane
  n / p         Next / previous window
  Tab           Last window
  0-9           Jump to window number
  d             Detach
  x             Kill pane (confirm)
  &             Kill window (confirm)
  z             Zoom pane (toggle fullscreen)
  [             Copy mode (vi: v select, y yank → clipboard)
  s             Session picker (tree)
  w             Window picker
  f             Find window by name
  Ctrl-p        Popup floating shell
  ?             List all key bindings
  :             Command prompt

MOUSE
  Click to select pane/window; drag borders to resize;
  scroll history; drag to select + copy (pbcopy)

TYPICAL FLOW
  tn securescope     # one session per project
  Ctrl-a |           # side-by-side panes
  Ctrl-a c           # extra window for logs/k9s
  Ctrl-a d           # detach; later: ta or ts
EOF
  }
  _SC_DESC[thelp]="Print tmux cheatsheet (prefix Ctrl-a)"
  _SC_CAT[thelp]="tmux"

  _SC_DESC[tmux]="Terminal multiplexer (prefix Ctrl-a)"
  _SC_CAT[tmux]="tmux"
fi

# -------------------------- Key bindings (documented) -----------------------
typeset -ga _SC_KEYS
_SC_KEYS=(
  "keys|Ctrl+R|History search (atuin if installed, else fzf)"
  "keys|Ctrl+T|Fuzzy insert file path (fzf + fd)"
  "keys|Alt+C|Fuzzy cd into directory (fzf + fd)"
  "keys|Up/Down|History search by current prefix (atuin)"
  "keys|Tab|Fuzzy completion (fzf-tab) or classic complete"
  "keys|Right/End|Accept autosuggestion"
  "keys|Ctrl+Right|Forward one word / partial accept"
  "keys|Ctrl+Left|Backward one word"
  "keys|Esc Esc|Prefix line with sudo (OMZ sudo plugin)"
  "keys|Ctrl+a|tmux prefix (then c/|/-/hjkl/d/r/? …)"
  "keys|Ctrl+a then ?|List all tmux key bindings"
  "keys|Ctrl+a then r|Reload ~/.tmux.conf"
)

# -------------------------- Discovery ---------------------------------------
_sc_print_table() {
  local query="${1:-}"
  local name cat desc body line rest kcat kkey kdesc
  local -a lines
  lines=()

  local exact_cat=0
  local -a known_cats
  known_cats=(git k8s docker files search util keys atuin editor tmux)
  [[ -n "$query" && ${known_cats[(Ie)$query]} -ne 0 ]] && exact_cat=1

  for name in ${(ok)_SC_DESC}; do
    cat="${_SC_CAT[$name]}"
    desc="${_SC_DESC[$name]}"
    if (( $+aliases[$name] )); then
      body="${aliases[$name]//$'\n'/ }"
      (( ${#body} > 60 )) && body="${body[1,57]}..."
    elif (( $+functions[$name] )); then
      body="(function)"
    else
      body="(command)"
    fi
    line=$(printf '%-14s | %-10s | %-42s | %s' "$name" "$cat" "$desc" "$body")
    if [[ -z "$query" ]]; then
      lines+="$line"
    elif (( exact_cat )); then
      [[ "$cat" == "$query" ]] && lines+="$line"
    elif [[ "$name" == *${query}* || "$cat" == *${query}* || "$desc" == *${query}* || "$body" == *${query}* ]]; then
      lines+="$line"
    fi
  done

  local entry
  for entry in $_SC_KEYS; do
    kcat="${entry%%|*}"
    rest="${entry#*|}"
    kkey="${rest%%|*}"
    kdesc="${rest#*|}"
    line=$(printf '%-14s | %-10s | %-42s | %s' "$kkey" "$kcat" "$kdesc" "(key binding)")
    if [[ -z "$query" ]]; then
      lines+="$line"
    elif (( exact_cat )); then
      [[ "$kcat" == "$query" ]] && lines+="$line"
    elif [[ "$query" == keys || "$kcat" == *${query}* || "$kkey" == *${query}* || "$kdesc" == *${query}* ]]; then
      lines+="$line"
    fi
  done

  if (( ${#lines} == 0 )); then
    print -u2 "No shortcuts matched: $query"
    print -u2 "Try:  sc   |  sc git  |  sc k8s  |  sc docker  |  sc keys  |  sc --live  |  sc --help"
    return 1
  fi

  printf '%-14s | %-10s | %-42s | %s\n' "SHORTCUT" "CATEGORY" "DESCRIPTION" "EXPANDS TO"
  printf '%s\n' "---------------+------------+--------------------------------------------+------------------"
  printf '%s\n' "${lines[@]}"
}

# Live dump of every alias currently loaded (OMZ plugins + curated)
_sc_live_rows() {
  local name value
  for name in "${(k)aliases[@]}"; do
    value="${aliases[$name]//$'\n'/ }"
    (( ${#value} > 80 )) && value="${value[1,77]}..."
    printf '%s\t%s\n' "$name" "$value"
  done
}

_sc_live() {
  local term="${1:-}" matches
  if [[ -n "$term" ]]; then
    matches="$(_sc_live_rows | grep -i -- "$term" || true)"
    if [[ -z "$matches" ]]; then
      print -u2 "No loaded aliases matching '$term'."
      return 1
    fi
  else
    matches="$(_sc_live_rows)"
  fi
  if [[ -n "${PAGER:-}" ]]; then
    print -r -- "$matches" | sort | column -t -s $'\t' | ${=PAGER}
  elif (( $+commands[fzf] )) && [[ -t 1 ]] && [[ -z "$term" ]]; then
    print -r -- "$matches" | sort | fzf --prompt='live alias> ' --delimiter=$'\t' --with-nth=1,2
  else
    print -r -- "$matches" | sort | column -t -s $'\t' | less -M
  fi
}

_sc_help() {
  cat <<'EOF'
shortcuts / sc — discover shell shortcuts

  sc                     Interactive browser of curated shortcuts (fzf)
  sc --list              Full curated table (no fzf)
  sc <query>             Filter curated by name / category / description
  sc git | sc k8s | sc docker | sc keys | sc editor | sc tmux
  sc --live [term]       All currently loaded aliases (OMZ + yours)
  sc --help              This help

Categories: git  k8s  docker  files  search  util  keys  editor  tmux

Helpers:
  e / ef / eg / ze       Edit cwd, fuzzy file, git-changed, z+edit
  hxconfig               Edit Helix config   |  hx --tutor
  mdv                    Render markdown (glow)
  tn / ta / ts / thelp   tmux new, attach, fuzzy session, cheatsheet
  gcof                   Fuzzy git checkout
  dsh / dlof             Fuzzy docker shell / follow logs
  k9 / kstern            k9s / stern (if installed)
  h <pattern>            Search shell history
  z / zi                 zoxide jump
  direnv allow           Load project .envrc
  gh prc|prv|prl|prco|prw  GitHub PR helpers (git module)

Automatic reminder:
  Type a full command that has an alias (e.g. git status) and
  you-should-use prints:  You should use: "gst"
EOF
}

shortcuts() {
  local mode="auto"
  local query=""

  while (( $# )); do
    case "$1" in
      -h|--help) _sc_help; return 0 ;;
      -l|--list|--all) mode="list"; shift ;;
      --live) shift; _sc_live "$@"; return $? ;;
      *) query="$1"; shift; break ;;
    esac
  done
  (( $# )) && query="${query:+$query }$^*"

  if [[ "$mode" == "list" || ! -t 1 ]] || ! (( $+commands[fzf] )); then
    _sc_print_table "$query"
    return $?
  fi

  local selected sc
  selected=$(_sc_print_table "$query" | fzf \
    --header="Enter copies name · Esc closes · sc git|k8s|docker|keys · sc --live for all OMZ aliases" \
    --height=80% \
    --reverse \
    --border \
    --header-lines=2) || return 0

  [[ -z "$selected" ]] && return 0
  sc=$(print -r -- "$selected" | awk -F'|' '{gsub(/^ +| +$/,"",$1); print $1}')
  if (( $+commands[pbcopy] )); then
    print -n -- "$sc" | pbcopy 2>/dev/null
    print "→ $sc  (copied to clipboard)"
  else
    print "→ $sc"
  fi
  if (( $+aliases[$sc] )); then
    print "  expands to: ${aliases[$sc]}"
  fi
  if [[ -n "${_SC_DESC[$sc]:-}" ]]; then
    print "  ${_SC_DESC[$sc]}"
  fi
}

alias sc=shortcuts
alias shortcut=shortcuts
