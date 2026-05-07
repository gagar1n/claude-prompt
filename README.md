# claude-prompt

Custom Claude Code status line that shows, all in one line:

- **Model** in use (e.g. `Opus 4.7`)
- **Thinking effort** level (`low` / `medium` / `high` / `xhigh` / `max`)
- **5-hour rate limit** — % used and ETA to reset
- **7-day rate limit** — % used and ETA to reset
- **Context window** usage — % of the model's context window consumed

Example:

```
Opus 4.7 · effort:high · 5h:23% (4h12m) · 7d:41% (3d5h) · ctx:12%
```

The 5h / 7d entries are omitted when Claude Code does not provide them
(e.g. on plans that don't surface those limits, or before the first API
response of the session).

Output is coloured:

- **Model** — bold cyan
- **Effort** — green (low) · yellow (medium) · magenta (high / xhigh / max)
- **Limits & context %** — green (<50%) · yellow (50–79%) · red (≥80%)
- **Labels & ETAs** — dim
- **Separators** — dim grey

Set `NO_COLOR=1` (per [no-color.org](https://no-color.org/)) to disable.

## Install

On a new host:

```sh
git clone https://github.com/gagar1n/claude-prompt.git
cd claude-prompt && ./install.sh
```

The installer:

1. Installs `jq` if it isn't already (apt / dnf / pacman / brew — auto-detected).
2. Copies `statusline.sh` to `~/.claude/statusline.sh` (mode `0755`).
3. Merges the `statusLine` entry into `~/.claude/settings.json`, preserving
   any existing keys (`theme`, `permissions`, hooks, etc.). If
   `settings.json` exists but is not valid JSON, the installer aborts
   without modifying it.

It is idempotent — re-running it just refreshes the script and
re-applies the settings entry.

Restart Claude Code after install to pick up the new status line.

## How it works

Claude Code passes a JSON blob to the status-line command via stdin on
every redraw. The script reads that JSON with `jq`, picks out the
fields it needs, and prints a one-line summary. It does **no** network
or filesystem I/O on every redraw, so it stays cheap.

Relevant input fields (from current Claude Code):

| Field                                       | Used for                |
| ------------------------------------------- | ----------------------- |
| `.model.display_name`                       | Model label             |
| `.effort.level`                             | Thinking effort         |
| `.context_window.used_percentage`           | Context bar             |
| `.rate_limits.five_hour.{used_percentage,resets_at}` | 5h limit + ETA |
| `.rate_limits.seven_day.{used_percentage,resets_at}` | 7d limit + ETA |

`resets_at` is a Unix epoch second; the script formats the remaining
time as `Xd Yh`, `Xh Ym`, or `Xm`.

## Files

- `statusline.sh` — the status-line script. Single source of truth.
- `install.sh` — installer (jq install + copy + settings merge).
- `README.md` — this file.

## Customising

Edit `statusline.sh` to change the format. The simplest tweaks:

- Reorder or drop entries by editing the `parts=(...)` array and the
  conditional appends.
- Change the separator by editing the `sep=" · "` line.
- Add ANSI colour codes around segments — Claude Code renders them.

After editing, re-run `install.sh` to copy the new version into
`~/.claude/`.

## Uninstall

```sh
rm -f ~/.claude/statusline.sh
jq 'del(.statusLine)' ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
```
