# ~/.zsh/shortcut.zsh — symlinked here by modules/zsh.sh.
#
# `sc` / `shortcut`: an on-demand cheatsheet over every alias currently loaded
# (oh-my-zsh plugins + our own). It reads live from zsh's own $aliases
# associative array, so it's always accurate and needs no maintenance as
# plugins/omz versions change.
#
# This complements the you-should-use plugin, which nudges you *after* you type
# something a shorter alias already covers (e.g. `kubectl get pods` -> "you can
# use kgp"). `sc` is for looking things up *before* you type them.

_shortcut_rows() {
  # "alias<TAB>expansion" for every currently defined alias, one per line.
  # Reading $aliases directly (rather than parsing `alias`'s text output)
  # sidesteps quoting edge cases — e.g. the omz git plugin's `current_branch`
  # alias embeds a literal newline in its expansion, which broke a regex-based
  # parser and threw off column alignment for every row.
  local name value
  for name in "${(k)aliases[@]}"; do
    value="${aliases[$name]//$'\n'/ }"
    (( ${#value} > 80 )) && value="${value[1,77]}..."
    printf '%s\t%s\n' "$name" "$value"
  done
}

_shortcut_table() {
  # Reads "alias<TAB>expansion" rows on stdin, prints as an aligned table,
  # always through a full-screen pager (man-page style: alternate screen,
  # clears on quit, no scrollback clutter). `-F` and `-X` are deliberately
  # NOT used — `-F` skips the pager for short output and `-X` disables the
  # alternate screen, and together they were dumping raw redraws straight
  # into the terminal's scrollback instead of a clean full-screen view.
  if [[ -n "${PAGER:-}" ]]; then
    # Intentionally unquoted: $PAGER commonly carries flags (e.g. "less -R").
    sort | column -t -s $'\t' | ${=PAGER}
  else
    sort | column -t -s $'\t' | less -M
  fi
}

_shortcut_query() {
  local term="$1" matches
  if [[ -z "$term" ]]; then
    _shortcut_help
    return 1
  fi
  matches="$(_shortcut_rows | grep -i -- "$term")"
  if [[ -z "$matches" ]]; then
    echo "No aliases matching '$term'."
    return 1
  fi
  printf '%s\n' "$matches" | _shortcut_table
}

_shortcut_help() {
  cat <<'EOF'
sc / shortcut — cheatsheet for currently loaded shell aliases

  sc                  interactive fuzzy search (needs fzf), else this help
  sc <term>           shorthand for `sc query <term>`
  sc query <term>     list aliases whose name or expansion contains <term>
  sc git|docker|kubectl|...   same idea, e.g. `sc git`, `sc kubectl`
  sc --list           full table of every alias currently defined

Tip: the you-should-use plugin also reminds you inline whenever you type
out something a defined alias already shortens.
EOF
}

shortcut() {
  local sub="${1:-}"
  case "$sub" in
    -h|--help)
      _shortcut_help
      ;;
    -l|--list)
      _shortcut_rows | _shortcut_table
      ;;
    query|-q)
      shift
      _shortcut_query "$@"
      ;;
    "")
      if command -v fzf >/dev/null 2>&1; then
        _shortcut_rows | sort | fzf --prompt="shortcut> " --delimiter=$'\t' --with-nth=1,2
      else
        _shortcut_help
      fi
      ;;
    *)
      _shortcut_query "$sub"
      ;;
  esac
}
alias sc=shortcut
