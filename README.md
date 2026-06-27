# dotfiles

Personal configuration files, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Currently tracking:

- **`opencode`** — [OpenCode](https://github.com/opencode-ai/opencode) CLI agent config
- **`nvim`** — [AstroNvim](https://astronvim.com/) Neovim setup

More packages will land here over time.

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
│       └── nvim/            → links to ~/.config/nvim/
│           ├── init.lua
│           └── lua/...
└── opencode/
    └── .config/
        └── opencode/        → links to ~/.config/opencode/
            └── opencode.json
```

When you run `stow nvim` from inside `~/dotfiles`, Stow treats the `nvim/` package folder as transparent and replicates everything beneath it into your home directory as symlinks. So `nvim/.config/nvim/init.lua` becomes a link at `~/.config/nvim/init.lua` pointing back into the repo.

> **The one rule that matters:** the path *inside* each package must mirror the target path under `$HOME`. Get that nesting right and everything else just works. If files ever link to the wrong place, it's almost always a package's internal structure not matching the target layout.

## Installation

On a fresh machine:

```bash
# 1. Clone next to $HOME (the conventional spot)
git clone <repo-url> ~/dotfiles
cd ~/dotfiles

# 2. Lay down the symlinks for the packages you want
stow nvim opencode
```

Stow's default target is the parent of wherever you run it, so cloning to `~/dotfiles` and running from inside it links into `$HOME` automatically. If the repo ever lives somewhere else, pass the target explicitly: `stow -t ~ nvim`.

### Conflicts on a fresh machine

If an application already wrote a default config before you stowed (e.g. `~/.config/opencode/opencode.json` exists as a *real* file), Stow refuses to clobber it and reports a conflict. Two ways out:

- Remove or back up the offending target file, then `stow` again, **or**
- `stow --adopt nvim` — but use this carefully. `--adopt` pulls the *existing target file's contents into the repo*, overwriting the repo's version. Commit first so you can diff and revert if it swallowed something you wanted to keep.

## Syncing — and what "both ways" actually means

There are two different syncs in play, and **neither is an automatic background daemon**. This isn't Dropbox.

### Local: edits ↔ repo (genuinely two-way)

Because Stow uses symlinks, the file at `~/.config/nvim/init.lua` *is* the file at `~/dotfiles/nvim/.config/nvim/init.lua` — one inode, two names. Edit it from either location and there's no copy and no drift. Your live config edits land in the repo's working tree **as you make them**.

The only remaining local step is taking a git snapshot when you want a checkpoint:

```bash
cd ~/dotfiles
git add -A
git commit -m "tweak nvim keymaps"
git push
```

### Cross-machine: repo ↔ other machines (manual, order matters)

This half is always deliberate git, regardless of tooling:

```bash
# machine A — after committing and pushing (above)

# machine B
cd ~/dotfiles
git pull
stow -R nvim opencode   # restow: cleans up and re-links after a pull that added files
```

If you edit on two machines without pulling first, you get a normal git divergence to merge — nothing exotic, just regular git.

## Day-to-day Stow commands

| Command | What it does |
|---|---|
| `stow nvim` | Link the `nvim` package into `$HOME` |
| `stow -R nvim` | **Restow** — unlink then relink. Run after a `git pull` that added new files |
| `stow -D nvim` | **Unstow** — remove the package's symlinks (leaves the repo files untouched) |
| `stow nvim opencode` | Operate on multiple packages at once |

Notes:

- You only need to re-run `stow` when the *set of files changes* (a new file or a new package). **Editing an already-linked file needs nothing** — the link already points at it.
- Re-running `stow` on an already-stowed package is safe and idempotent.
- `stow -D` must be run from the *same directory* you originally stowed from, since Stow resolves link targets relative to its current location.

## Adding a new config

1. Create a package folder mirroring the target path:
   ```bash
   mkdir -p ~/dotfiles/zsh/.config/zsh
   ```
2. Move (or create) the config inside it:
   ```bash
   mv ~/.config/zsh/.zshrc ~/dotfiles/zsh/.config/zsh/
   ```
3. Stow it:
   ```bash
   cd ~/dotfiles && stow zsh
   ```
4. Commit.

## Secret hygiene

A dotfiles repo lives one careless commit away from leaking credentials, so the standing rules:

- **Never blanket-add credential material.** The `.gitignore` should exclude token/auth/key patterns by default.
- **Audit before pushing anywhere public.** Run [`gitleaks detect`](https://github.com/gitleaks/gitleaks) over the repo. Remember that *anything ever committed stays in history* even if you later delete it — a public repo needs the retroactive audit too.
- **Check `opencode.json` specifically.** OpenCode's auth state lives in `~/.local/share/opencode/` (outside the config dir, so not tracked here), but watch for any inline API keys in `opencode.json` itself — that's the most likely file in this set to carry a credential.

## Platform notes

These configs assume macOS / Linux with the standard XDG layout (`~/.config`, `~/.local/share`, `~/.local/state`, `~/.cache`). If you've set a non-default `$XDG_CONFIG_HOME`, the target paths shift accordingly — check with `echo $XDG_CONFIG_HOME`.

## License

Personal config — take whatever's useful.

