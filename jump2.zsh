# jump2 — name a folder or a command, run it with one word.
# Source this file from ~/.zshrc:   source /path/to/jump2.zsh
# Requires zsh.

typeset -g JUMP2_VERSION="0.1.0"
typeset -ga _JUMP2_RESERVED=(ls list find rm remove migrate help version)
typeset -g _JUMP2_MTIME=""

zmodload -F zsh/stat b:zstat 2>/dev/null

_jump2_file() {
  print -r -- "${JUMP2_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/jump2/aliases}"
}

_jump2_err() { print -u2 -r -- "jump2: $*"; }

_jump2_usage() {
  cat <<EOF
jump2 $JUMP2_VERSION - name a folder or a command, run it with one word

Usage:
  jump2 <name>                  bookmark the current directory as <name>
  jump2 <folder> as <name>      bookmark a folder
  jump2 "<command>" as <name>   save a command
  jump2 ls                      list everything saved
  jump2 find <text>             search names and targets
  jump2 rm <name>...            remove entries
  jump2 migrate [file]          import aliases (default: ~/.zsh_aliases)
  jump2 -f ...                  allow overriding an existing command
  jump2 --help | --version

Data file: \$JUMP2_FILE (default ~/.config/jump2/aliases)
EOF
}

# Print saved names, one per line.
_jump2_names() {
  local file line
  file=$(_jump2_file)
  [[ -r $file ]] || return 0
  for line in "${(@f)$(<"$file")}"; do
    [[ $line == "alias "*=* ]] || continue
    line=${line#alias }
    print -r -- "${line%%=*}"
  done
}

_jump2_has() { _jump2_names | grep -qxF -- "$1"; }

_jump2_stamp() {
  local -a m
  zstat -A m +mtime -- "$(_jump2_file)" 2>/dev/null && _JUMP2_MTIME=${m[1]}
}

_jump2_ensure() {
  local file=$1 dir=${1:h}
  if [[ ! -d $dir ]]; then
    mkdir -p -- "$dir" || return 1
    chmod 700 -- "$dir" 2>/dev/null
  fi
  [[ -e $file ]] || ( umask 077; : >"$file" ) || return 1
}

# Rewrite file without the entry <name>.
_jump2_drop() {
  local file=$1 name=$2 tmp line
  [[ -f $file ]] || return 0
  tmp=$(mktemp "${file}.XXXXXX") || return 1
  for line in "${(@f)$(<"$file")}"; do
    [[ -z $line ]] && continue
    [[ $line == "alias ${name}="* ]] && continue
    print -r -- "$line" >>"$tmp"
  done
  mv -f -- "$tmp" "$file"
}

# Source the data file if it changed since last load.
_jump2_reload() {
  local file m
  local -a st
  file=$(_jump2_file)
  [[ -r $file ]] || return 0
  zstat -A st +mtime -- "$file" 2>/dev/null || return 0
  m=${st[1]}
  [[ $m == "$_JUMP2_MTIME" ]] && return 0
  source "$file" && _JUMP2_MTIME=$m
  return 0
}

_jump2_add() {
  local file=$1; shift
  local force=0 target name expanded abs cmd kind
  if [[ $1 == -f || $1 == --force ]]; then force=1; shift; fi

  if (( $# == 3 )) && [[ $2 == as ]]; then
    target=$1; name=$3
  elif (( $# == 1 )); then
    target=$PWD; name=$1
  else
    _jump2_err 'usage: jump2 <name>  |  jump2 <folder-or-command> as <name>'
    return 1
  fi

  if [[ ! $name =~ '^[A-Za-z0-9_][A-Za-z0-9_.-]*$' ]]; then
    _jump2_err "invalid name '$name' (use letters, digits, _ . -)"
    return 1
  fi
  if (( ${_JUMP2_RESERVED[(Ie)$name]} )); then
    _jump2_err "'$name' is a jump2 subcommand, pick another name"
    return 1
  fi
  if [[ -z $target ]]; then
    _jump2_err 'empty target'
    return 1
  fi

  expanded=${target/#\~/$HOME}
  if [[ -d $expanded ]]; then
    abs=${expanded:A}
    cmd="cd -- ${(q)abs}"
  elif [[ $target == [/~.]* && $target != *[[:space:]]* && ! -e $expanded ]]; then
    _jump2_err "no such folder: $target"
    return 1
  else
    cmd=$target
  fi

  if ! _jump2_has "$name" && (( ! force )); then
    kind=$(whence -w -- "$name" 2>/dev/null)
    if [[ -n $kind && $kind != *": none" ]]; then
      _jump2_err "'$name' already exists (${kind#*: }); use -f to override"
      return 1
    fi
  fi

  _jump2_ensure "$file" || { _jump2_err "cannot write $file"; return 1; }
  _jump2_drop "$file" "$name" || return 1
  print -r -- "alias ${name}=${(q)cmd}" >>"$file" || return 1
  alias -- "$name=$cmd"
  _jump2_stamp
  print -r -- "jump2: $name -> $cmd"
}

_jump2_list() {
  local name
  _jump2_reload
  for name in $(_jump2_names); do
    printf '%-16s %s\n' "$name" "${aliases[$name]}"
  done
}

_jump2_find() {
  [[ -n $1 ]] || { _jump2_err 'usage: jump2 find <text>'; return 1; }
  _jump2_list | grep -iF -- "$1"
}

_jump2_rm() {
  local file=$1 name rc=0; shift
  (( $# )) || { _jump2_err 'usage: jump2 rm <name>...'; return 1; }
  for name in "$@"; do
    if _jump2_has "$name"; then
      _jump2_drop "$file" "$name" && unalias -- "$name" 2>/dev/null
      print -r -- "jump2: removed $name"
    else
      _jump2_err "no such entry: $name"
      rc=1
    fi
  done
  _jump2_stamp
  return $rc
}

_jump2_migrate() {
  local file=$1 src=${2:-$HOME/.zsh_aliases} line name n=0
  [[ -r $src ]] || { _jump2_err "cannot read $src"; return 1; }
  _jump2_ensure "$file" || return 1
  for line in "${(@f)$(<"$src")}"; do
    [[ $line == "alias "*=* ]] || continue
    name=${${line#alias }%%=*}
    [[ $name =~ '^[A-Za-z0-9_][A-Za-z0-9_.-]*$' ]] || continue
    _jump2_has "$name" && continue
    print -r -- "$line" >>"$file"
    (( n++ ))
  done
  _JUMP2_MTIME=""
  _jump2_reload
  print -r -- "jump2: imported $n entries from $src"
}

jump2() {
  emulate -L zsh
  local file
  file=$(_jump2_file)
  (( $# )) || { _jump2_usage; return 0; }
  case $1 in
    -h|--help|help)      _jump2_usage ;;
    -V|--version|version) print -r -- "jump2 $JUMP2_VERSION" ;;
    ls|list)             _jump2_list ;;
    find)                _jump2_find "$2" ;;
    rm|remove)           shift; _jump2_rm "$file" "$@" ;;
    migrate)             _jump2_migrate "$file" "$2" ;;
    *)                   _jump2_add "$file" "$@" ;;
  esac
}

_jump2_complete() {
  local -a subs
  subs=(ls list find rm migrate help version)
  if (( CURRENT == 2 )); then
    _describe 'command' subs
  elif [[ $words[2] == rm ]]; then
    compadd -- ${(f)"$(_jump2_names)"}
  fi
}

_jump2_reload

if [[ -o interactive ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _jump2_reload
  (( $+functions[compdef] )) && compdef _jump2_complete jump2
fi
