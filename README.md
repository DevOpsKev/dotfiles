# dotfiles

Personal configuration files, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Currently tracking:

- **`nvim`** — [AstroNvim](https://astronvim.com/) Neovim setup
- **`opencode`** — [OpenCode](https://github.com/opencode-ai/opencode) CLI AI coding agent
- **`ghostty`** — [Ghostty](https://ghostty.org/) terminal emulator
- **`zsh`** — Zsh shell config (`.zshrc`, `.zshenv`, `.zprofile`)

## Why this exists

Config files have a habit of drifting. You tweak your Neovim keymaps on one machine, forget what you changed, then spend twenty minutes on the next machine wondering why muscle memory doesn't work. This repo is the single source of truth for that config, version-controlled so every change is a deliberate, reversible checkpoint.

### Why not just `git init` in `$HOME`?

Tempting, but a footgun. Turning your home directory into a git repo means git is aware of *everything* under it — every cache, every secret, every stray token. One careless `git add -A` and your SSH keys, cloud credentials, or password-manager session files are in a commit. Managing the recursive ignores to prevent that is its own special misery.

### Why Stow?

Stow keeps the repo as an ordinary directory (`~/dotfiles`) that lives *outside* `$HOME`-as-a-repo territory, and uses **symlinks** to put each config file where its application expects to find it. That gives three things:

- **No copy step.** The deployed file and the repo file are the same file (same inode, two names). Edit either, and you've edited the one real file.
- **Explicit tracking.** Only what you deliberately put into a package and `stow` gets linked. Nothing is tracked by accident.
- **Zero dependencies beyond Stow itself.** No templating engine, no daemon, no runtime. It's just symlinks.

## How it works

Each top-level folder in this repo is a Stow **package**. The directory structure *inside* a package mirrors where its files should land relative to `$HOME`:

```
~/dotfiles/
├── nvim/
│   └── .config/
│       └── nvim/              → ~/.config/nvim/
│           ├── init.lua
│           └── lua/...
├── opencode/
│   └── .config/
│       └── opencode/          → ~/.config/opencode/
│           └── opencode.json
├── ghostty/
│   └── .config/
│       └── ghostty/           → ~/.config/ghostty/
│           └── config
└── zsh/
    ├── .zshrc                 → ~/.zshrc
    ├── .zshenv                → ~/.zshenv
    └── .zprofile              → ~/.zprofile
```

When you run `stow nvim` from inside `~/dotfiles`, Stow treats the `nvim/` package folder as transparent and replicates everything beneath it into your home directory as symlinks.

Note that Zsh's config files live directly in `$HOME` rather than `~/.config/`, so the `zsh` package has no `.config/` nesting — files at the package root land directly at `~/.zshrc` etc.

> **The one rule that matters:** the path *inside* each package must mirror the target path under `$HOME`. Get that nesting right and everything else just works. If files ever link to the wrong place, it's almost always a package's internal structure not matching the target layout.

## Fresh machine setup

### 1. Install prerequisites

On macOS with Homebrew:

```bash
brew install stow

# Terminal
brew install --cask ghostty

# Neovim (AstroNvim requires Nerd Font and a few dependencies)
brew install neovim node npm lazygit ripgrep fd
brew install --cask font-jetbrains-mono-nerd-font   # or your preferred Nerd Font

# OpenCode
npm install -g opencode
```

### 2. Clone this repo

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
```

### 3. Stow the packages

```bash
stow nvim opencode ghostty zsh
```

That's it. Stow's default target is the parent of wherever you run it, so cloning to `~/dotfiles` and running from inside it links everything into `$HOME` automatically.

### 4. Install AstroNvim plugins

Open Neovim — Lazy.nvim will detect the config and install all plugins on first launch:

```bash
nvim
```

Mason (LSP/linter/formatter installer) will also run on first open. Let it complete before doing anything else.

### 5. Authenticate OpenCode

```bash
opencode auth
```

Auth tokens are stored in `~/.local/share/opencode/` — outside the dotfiles repo and never tracked.

### Conflicts on a fresh machine

If an application already wrote a default config before you stowed (e.g. `~/.config/opencode/opencode.json` already exists as a real file), Stow refuses to clobber it and reports a conflict. Two ways out:

- Remove or back up the offending target file, then `stow` again, **or**
- `stow --adopt nvim` — but use this carefully. `--adopt` pulls the *existing target file's contents into the repo*, overwriting the repo's version. Commit first so you can diff and revert if it swallowed something you wanted to keep.

## Syncing — and what "both ways" actually means

There are two different syncs in play, and **neither is an automatic background daemon**. This isn't Dropbox.

### Local: edits ↔ repo (genuinely two-way)

Because Stow uses symlinks, the file at `~/.config/nvim/init.lua` *is* the file at `~/dotfiles/nvim/.config/nvim/init.lua` — one inode, two names. Edit it from either location and there's no copy and no drift. Your live config edits land in the repo's working tree **as you make them**.

This also means anything written *by* an application into its config directory is immediately in the repo too. Create an OpenCode agent through the TUI, save a Ghostty theme, update your Zsh aliases — all of it lands directly in `~/dotfiles/` without any sync step. You just need to commit when you want a checkpoint.

The only remaining local step is taking a git snapshot:

```bash
cd ~/dotfiles
git add -A
git commit -m "add opencode agent for JLR pipeline"
git push
```

### Cross-machine: repo ↔ other machines (manual, order matters)

This half is always deliberate git, regardless of tooling:

```bash
# machine A — after committing and pushing (above)

# machine B
cd ~/dotfiles
git pull
stow -R nvim opencode ghostty zsh   # restow: cleans up and re-links after a pull that added files
```

If you edit on two machines without pulling first, you get a normal git divergence to merge — nothing exotic, just regular git.

## Day-to-day Stow commands

| Command | What it does |
|---|---|
| `stow nvim` | Link the `nvim` package into `$HOME` |
| `stow -R nvim` | **Restow** — unlink then relink. Run after a `git pull` that added new files |
| `stow -D nvim` | **Unstow** — remove the package's symlinks (leaves the repo files untouched) |
| `stow nvim opencode ghostty zsh` | Operate on multiple packages at once |

Notes:

- You only need to re-run `stow` when the *set of files changes* (a new file or a new package). **Editing an already-linked file needs nothing** — the link already points at it.
- Re-running `stow` on an already-stowed package is safe and idempotent.
- `stow -D` must be run from the *same directory* you originally stowed from, since Stow resolves link targets relative to its current location.

## Adding a new config

1. Create the package structure mirroring the target path:
   ```bash
   mkdir -p ~/dotfiles/starship/.config
   ```
2. Move the existing config into it:
   ```bash
   mv ~/.config/starship.toml ~/dotfiles/starship/.config/starship.toml
   ```
3. Stow it:
   ```bash
   cd ~/dotfiles && stow starship
   ```
4. Commit.

## Secret hygiene

A dotfiles repo lives one careless commit away from leaking credentials, so the standing rules:

- **Never put API keys or tokens in config files.** Reference environment variables instead, and set those via your password manager CLI at shell startup — e.g. `export NEBIUS_API_KEY="$(op read 'op://vault/nebius/api_key')"` in `.zshrc`. The key is fetched at shell startup, never touches the repo.
- **Never blanket-add.** Always `git add -p` or add specific files. A `.gitignore` that excludes `*.token`, `*secret*`, `*key*`, `auth.json` patterns is cheap insurance.
- **Audit before pushing anywhere public.** Run [`gitleaks detect`](https://github.com/gitleaks/gitleaks) over the repo. Remember that *anything ever committed stays in history* even if you later delete it — scrub with `git filter-repo` and rotate the key if anything slips through.
- **OpenCode auth lives outside the repo.** Tokens are stored in `~/.local/share/opencode/` — not tracked. But check `opencode.json` for any inline API keys if you've manually edited it.
- **Zsh config is the highest-risk file.** It's easy to export a key inline in `.zshrc` and forget it's there. Audit it before the first commit.

## What is and isn't tracked

| Path | Tracked | Reason |
|---|---|---|
| `~/.config/nvim/` | ✅ | Your config and Lazy lockfile |
| `~/.local/share/nvim/` | ❌ | Plugin installs — regenerated by Lazy |
| `~/.config/opencode/` | ✅ | Config, agents, rules |
| `~/.local/share/opencode/` | ❌ | Auth tokens — never track |
| `~/.config/ghostty/` | ✅ | Terminal config |
| `~/.zshrc` / `.zshenv` / `.zprofile` | ✅ | Shell config |

## Platform notes

These configs assume macOS / Linux with the standard XDG layout (`~/.config`, `~/.local/share`, `~/.local/state`, `~/.cache`). If you've set a non-default `$XDG_CONFIG_HOME`, the target paths shift accordingly — check with `echo $XDG_CONFIG_HOME`.

## License

Personal config — take whatever's useful.

