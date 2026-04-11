# toolshed

**The command archaeologist** — automatically catalog, browse, and discover your personal CLI tools.

If you have dozens of scripts, aliases, and functions scattered across your system and sometimes forget what you've built, toolshed finds them all, indexes them, and gives you a fast fuzzy picker to search and launch them.

## What makes it different

Unlike snippet managers (navi, pet) that require manual curation, toolshed **scans your system automatically**:

- **Auto-scans** your bin dirs, bashrc aliases, shell functions, MCP servers
- **Fuzzy picker** (fzf) with syntax-highlighted preview, editor jumping, clipboard yank
- **Semantic search** — find tools by meaning, not just name (`toolshed --ask "connect to remote machine"` finds SSH aliases)
- **Discover mode** — finds commands you *use* but haven't *cataloged* (scans bash history)
- **"Not mine" detection** — automatically skips system packages, ELF binaries, pip/npm-installed tools
- **MCP-aware** — indexes Model Context Protocol servers and tools (for Claude Code / AI-assisted workflows)

## Quick start

```bash
git clone https://github.com/gruncode/toolshed.git
cd toolshed
./install.sh

# Build the catalog
toolshed-index

# Browse your tools
toolshed
```

## Usage

```
toolshed                      # interactive fuzzy picker
toolshed <query>              # filter, auto-pick if unique
toolshed --ask "description"  # semantic search (requires setup)
toolshed --list               # plain table
toolshed --list <category>    # filter by category
toolshed --cats               # show categories with counts
toolshed --refresh            # rebuild catalog
```

### Inside the picker

| Key     | Action                              |
|---------|-------------------------------------|
| Enter   | Select (scripts prompt run/edit)    |
| F3      | Full-screen pager with syntax color |
| Ctrl-E  | Open in $EDITOR (jumps to line)     |
| Ctrl-Y  | Yank source to clipboard            |
| Ctrl-O  | Yank path to clipboard              |
| Esc     | Cancel                              |

### Discover uncataloged commands

```bash
toolshed-discover          # what am I using but haven't cataloged?
toolshed-discover 90       # look back 90 days
toolshed-discover --ignore cmd  # permanently dismiss false positives
```

## How it works

### Indexing (`toolshed-index`)

Scans these locations (configurable):

| Source | What it finds |
|--------|---------------|
| `/usr/local/bin`, `~/bin`, `~/.local/bin`, `~/scripts` | Your scripts |
| `/etc/bash.bashrc`, `~/.bashrc` | Functions and aliases |
| `~/.local/share/mcp/*/` | MCP servers and `@mcp.tool` functions |
| `~/.mcp.json`, `~/.claude/mcp.json` | Additional MCP server paths |
| Claude Code session logs (opt-in) | Cloud/plugin MCP tools seen in use |
| `~/.claude/commands/*.md` (opt-in) | Claude Code slash commands |

Outputs:
- `~/.local/share/toolshed/index.tsv` — structured catalog (TSV)
- `~/.local/share/toolshed/CMDLIST.md` — human-readable grouped list
- `~/.local/share/toolshed/embeddings.npz` — vector cache (if semantic search enabled)

### "Not mine" detection

toolshed-index automatically filters out things you didn't write:
- ELF binaries (compiled C/C++/Rust programs)
- dpkg/rpm-owned packages (system tools)
- pip console_scripts (installed Python packages)
- npm/node_modules binaries
- snap/flatpak applications

Only your hand-written scripts, functions, and aliases make it into the catalog.

### Discover mode (`toolshed-discover`)

Compares what you actually *run* (from bash history) against what's in the catalog.
Surfaces commands that are:
- Used 2+ times (not one-off typos)
- Resolvable on PATH
- Not system-owned (passes "not mine" detection)
- Not already cataloged or ignored

This is the "command archaeologist" — it digs up tools you've forgotten about.

## Semantic search (optional)

`toolshed --ask` uses vector embeddings for meaning-based search, not just keyword matching.

### How it works

1. **Indexing:** `toolshed-index` sends each tool's name + description to [Cohere's Embed API](https://cohere.com/embed)
2. **Vectorization:** Each entry becomes a 1024-dimensional vector capturing its semantic meaning
3. **Caching:** Vectors are saved locally in `~/.local/share/toolshed/embeddings.npz` (a compressed NumPy file)
4. **Searching:** When you run `--ask "your query"`, the query is embedded into the same vector space
5. **Ranking:** Results are ranked by cosine similarity (dot product of normalized vectors) — the closer two vectors are, the more semantically similar

### Why this matters

Regular fuzzy search matches characters: `ssh` finds things named "ssh". Semantic search matches *meaning*: `"connect to remote machine"` finds SSH aliases, autossh tunnels, and sshfs mount commands — even if "remote" or "connect" don't appear in their names.

### Setup

```bash
# 1. Get a free API key (1000 calls/month free tier — plenty for personal use)
#    https://dashboard.cohere.com/api-keys

# 2. Install Python dependencies
pip install cohere numpy

# 3. Set your key (add to ~/.bashrc for persistence)
export COHERE_API_KEY="your-key-here"

# 4. Rebuild catalog with embeddings
toolshed-index

# 5. Search by meaning
toolshed --ask "find files on remote machine"
toolshed --ask "monitor system resources"
toolshed --ask "clipboard operations"
```

**Your API key never leaves your machine** except to call Cohere's API directly. It's read from the `COHERE_API_KEY` environment variable — never stored in any toolshed file.

Semantic search is **fully optional**. Without it, everything else works perfectly — fuzzy search, categories, preview, discover, all of it.

## Configuration

Edit `~/.config/toolshed/config`:

```bash
# Directories to scan (space-separated)
TOOLSHED_SCAN_DIRS="/usr/local/bin $HOME/bin $HOME/.local/bin"

# Python with cohere+numpy for embeddings (optional)
TOOLSHED_EMBED_PYTHON="/path/to/venv/bin/python3"

# Claude Code integration (optional, disabled by default)
TOOLSHED_CLAUDE_SESSIONS="$HOME/.claude/projects/-home-username"
TOOLSHED_CLAUDE_COMMANDS="$HOME/.claude/commands"

# Extra third-party exclusions (pipe-separated regex)
TOOLSHED_EXTRA_EXCLUDE="^(terraform|kubectl|helm)$"

# Custom categories (path to file with category_override function)
TOOLSHED_CATEGORIES_FILE="$HOME/.config/toolshed/categories.sh"

# Extra history files for discover mode
TOOLSHED_EXTRA_HISTORY="$HOME/.zsh_history"
```

See `config.example` for all options with documentation.

## Dependencies

| Dependency | Required | Purpose |
|------------|----------|---------|
| bash 4+    | yes      | Associative arrays, `mapfile` |
| fzf        | yes      | Interactive fuzzy picker |
| python3    | yes      | MCP scanning, discover mode |
| bat/batcat | recommended | Syntax-highlighted preview |
| xclip / wl-copy / pbcopy | recommended | Clipboard (Ctrl-Y, Ctrl-O) |
| cohere + numpy (pip) | optional | Semantic search (`--ask`) |

## File structure

```
~/.local/share/toolshed/     # Data (auto-generated)
  index.tsv                   # Catalog: type, name, path, category, description, mtime
  CMDLIST.md                  # Grouped markdown view
  embeddings.npz              # Cohere vectors (if enabled)
  CHANGELOG.md                # Index run log
  discover-ignore.txt         # Commands to skip in discover

~/.config/toolshed/           # Configuration
  config                      # User settings
```

## Comparison with similar tools

| Feature | toolshed | navi | pet | Atuin |
|---------|----------|------|-----|-------|
| Auto-scan bin/aliases/functions | **yes** | no | no | no |
| Fuzzy picker with preview | **yes** | yes | yes | partial |
| Semantic/NL search | **yes** | no | no | no |
| Discover uncataloged commands | **yes** | no | no | no |
| "Not mine" detection | **yes** | no | no | no |
| MCP server awareness | **yes** | no | no | no |
| Manual curation needed | **no** | yes | yes | n/a |

## License

MIT
