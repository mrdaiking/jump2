#!/usr/bin/env zsh
# Run: zsh -f tests/run.zsh
ROOT=${0:A:h:h}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export HOME=$TMP/home
mkdir -p "$HOME"
export JUMP2_FILE=$TMP/cfg/aliases
source "$ROOT/jump2.zsh"

pass=0 fail=0
ok()   { (( pass++ )); print "  ok   $1"; }
bad()  { (( fail++ )); print "  FAIL $1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi }

mkdir -p "$TMP/work/my project" "$TMP/work/it's"

print "add / run"
( cd "$TMP/work" && jump2 wk >/dev/null )
_JUMP2_MTIME=""; _jump2_reload   # subshell alias is lost; load from file
check "bookmark cwd" '[[ $aliases[wk] == "cd -- ${TMP:A}/work" ]]'
check "alias jumps" '( eval wk; [[ $PWD == ${TMP:A}/work ]] )'

jump2 "$TMP/work/my project" as sp >/dev/null
check "folder with space" '( eval sp; [[ $PWD == "${TMP:A}/work/my project" ]] )'
jump2 "$TMP/work/it's" as apos >/dev/null
check "folder with apostrophe" '( eval apos; [[ $PWD == "${TMP:A}/work/it'"'"'s" ]] )'

jump2 "echo 'hi there'" as hi >/dev/null
check "command with quotes" '[[ $(eval hi) == "hi there" ]]'

# persisted file must survive a fresh shell
check "persisted in new shell" \
  '[[ $(zsh -f -c "export HOME=$HOME JUMP2_FILE=$JUMP2_FILE; source $ROOT/jump2.zsh; eval hi") == "hi there" ]]'

print "validation"
check "reject ; in name"      '! jump2 x as "a;touch $TMP/pwn" 2>/dev/null; [[ ! -e $TMP/pwn ]]'
check "reject spaces in name" '! jump2 x as "a b" 2>/dev/null'
check "reject leading dash"   '! jump2 x as -rf 2>/dev/null'
check "reject reserved name"  '! jump2 x as ls 2>/dev/null'
check "reject shadowing cmd"  '! jump2 x as cat 2>/dev/null'
check "-f allows shadowing"   'jump2 -f "echo x" as cat >/dev/null 2>&1; jump2 rm cat >/dev/null'
check "missing folder errors" '! jump2 ./nope-dir-xyz as nd 2>/dev/null'
check "empty target errors"   '! jump2 "" as e 2>/dev/null'
check "bad arity errors"      '! jump2 a b 2>/dev/null'

print "overwrite / list / find / rm"
jump2 "echo one" as dup >/dev/null
jump2 "echo two" as dup >/dev/null
check "overwrite keeps one line" '[[ $(grep -c "^alias dup=" $JUMP2_FILE) == 1 ]]'
check "overwrite updates value"  '[[ $(eval dup) == two ]]'
check "ls lists names"           'jump2 ls | grep -q "^dup "'
check "find matches target"      'jump2 find "echo two" | grep -q "^dup "'

jump2 "echo a" as a.b >/dev/null
jump2 "echo x" as axb >/dev/null
jump2 rm a.b >/dev/null
check "rm is literal, not regex" 'grep -qF "alias axb=" $JUMP2_FILE && ! grep -qF "alias a.b=" $JUMP2_FILE'
check "rm unsets live alias"     '(( ! $+aliases[a.b] ))'
check "rm unknown fails"         '! jump2 rm nothere 2>/dev/null'

print "file safety"
check "data file mode 600" '[[ $(stat -f %Lp $JUMP2_FILE 2>/dev/null || stat -c %a $JUMP2_FILE) == 600 ]]'

print "migrate"
cat >$HOME/.zsh_aliases <<'EOF'
alias old1='cd "/tmp"'
alias dup='echo SHOULD-NOT-OVERRIDE'
not an alias line
alias bad;name='x'
EOF
jump2 migrate >/dev/null
check "migrate imports new"        '[[ $aliases[old1] == "cd \"/tmp\"" ]]'
check "migrate skips existing"     '[[ $(eval dup) == two ]]'
check "migrate skips bad names"    '! grep -q "bad;name" $JUMP2_FILE'

print "meta"
check "--version" '[[ $(jump2 --version) == "jump2 $JUMP2_VERSION" ]]'
check "--help"    'jump2 --help | grep -q "^Usage:"'

print
print "passed: $pass  failed: $fail"
(( fail == 0 ))
