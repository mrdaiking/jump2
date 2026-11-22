#!/bin/sh
# jump2 installer.
#   curl -fsSL https://raw.githubusercontent.com/mrdaiking/jump2/main/install.sh | sh
#   ./install.sh --uninstall
set -eu

REPO_RAW="${JUMP2_RAW_URL:-https://raw.githubusercontent.com/mrdaiking/jump2/main}"
DEST="${JUMP2_HOME:-$HOME/.jump2}"
RC="${ZDOTDIR:-$HOME}/.zshrc"
BEGIN="# >>> jump2 >>>"
END="# <<< jump2 <<<"

say() { printf 'jump2: %s\n' "$*"; }

remove_block() {
  [ -f "$RC" ] || return 0
  grep -qF "$BEGIN" "$RC" || return 0
  tmp=$(mktemp)
  awk -v b="$BEGIN" -v e="$END" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip
  ' "$RC" >"$tmp"
  cat "$tmp" >"$RC"
  rm -f "$tmp"
}

if [ "${1:-}" = "--uninstall" ]; then
  remove_block
  rm -rf "$DEST"
  say "removed. Your saved entries in ~/.config/jump2 were kept."
  exit 0
fi

command -v zsh >/dev/null 2>&1 || { say "zsh not found"; exit 1; }

mkdir -p "$DEST"
here=$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)
if [ -n "$here" ] && [ -f "$here/jump2.zsh" ]; then
  cp "$here/jump2.zsh" "$DEST/jump2.zsh"
else
  curl -fsSL "$REPO_RAW/jump2.zsh" -o "$DEST/jump2.zsh"
fi

touch "$RC"
if grep -qF "$BEGIN" "$RC"; then
  say "already hooked into $RC"
else
  cp "$RC" "$RC.jump2.bak"
  {
    printf '\n%s\n' "$BEGIN"
    printf 'source "%s/jump2.zsh"\n' "$DEST"
    printf '%s\n' "$END"
  } >>"$RC"
  say "added source line to $RC (backup: $RC.jump2.bak)"
fi

say "installed. Run: exec zsh   then: jump2 --help"
