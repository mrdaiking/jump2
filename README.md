# jump2

Name a **folder** or a **command**, run it with one word. zsh only.

Run something you always type? Save it once:

```sh
npm install && npm run dev        # you just ran this
jump2 last as setup               # save it
setup                             # run it again, anywhere
```

Folders work the same way:

```sh
cd ~/Documents/project/shadow-it
jump2 shait                       # bookmark current folder
jump2 ~/Downloads as dl           # bookmark any folder

shait                             # jumps there
dl
```

Or type a command yourself (**quotes required** when it has spaces, `&&` or `|`):

```sh
jump2 "npm install && npm run dev" as setup
jump2 "cat ~/.ssh/config" as sc
```

Unlike `z`/`autojump` (fuzzy, folders only), jump2 gives you explicit names and also stores commands.

## Install

Homebrew (once the tap exists):

```sh
brew install mrdaiking/tap/jump2
echo 'source "$(brew --prefix)/share/jump2/jump2.zsh"' >> ~/.zshrc
```

Or curl:

```sh
curl -fsSL https://raw.githubusercontent.com/mrdaiking/jump2/main/install.sh | sh
exec zsh
```

Uninstall: `./install.sh --uninstall` (saved entries are kept).

## Commands

| Command | Does |
|---|---|
| `jump2 <name>` | bookmark current directory |
| `jump2 <folder> as <name>` | bookmark a folder |
| `jump2 last as <name>` | save the command you just ran |
| `jump2 "<cmd>" as <name>` | save a command (quotes required) |
| `jump2 ls` | list entries |
| `jump2 find <text>` | search names and targets |
| `jump2 rm <name>...` | remove entries |
| `jump2 migrate [file]` | import `alias` lines (default `~/.zsh_aliases`) |
| `jump2 -f ...` | allow overriding an existing command name |

Want a shorter command? `alias sa=jump2` in your `~/.zshrc`.

## Safety

- Names must match `[A-Za-z0-9_][A-Za-z0-9_.-]*`; subcommand names are reserved.
- Refuses to shadow an existing command (`ls`, `git`, ...) unless `-f`.
- Values are shell-quoted before being written, so quotes, spaces and `$` are stored literally.
- Data file is mode `600` in a `700` directory. It is **sourced** by your shell, so treat it like `.zshrc`.

## Config

`JUMP2_FILE` overrides the data file. Default: `${XDG_CONFIG_HOME:-~/.config}/jump2/aliases`.

## Develop

```sh
zsh -f tests/run.zsh
```

## License

MIT
