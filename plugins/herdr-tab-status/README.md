# Herdr tab directory + Agent status

This local Herdr plugin replaces the previous `dev-shimada.auto-tab-name` GitHub plugin.
It preserves directory-based names and adds a colored emoji marker for the most
urgent Agent in any pane of the tab.

| Agent status | Tab label example | Priority |
| --- | --- | --- |
| Blocked (input/approval needed) | 🔴 gh-settings | 1 |
| Done (unread completion) | 🟢 gh-settings | 2 |
| Idle or unknown | ⚪ gh-settings | 3 |
| Working | 🟡 gh-settings | 4 |
| No detected Agent | gh-settings | No marker |

Names use the focused pane's foreground working directory when available,
falling back to the focused pane's shell directory and then the first pane.
With multiple Agents, the highest-priority state across **all** panes wins.
When a tab is manually renamed, its text is preserved; only its marker changes.
A tab may also keep its user-specified name if the directory changes.

Herdr tab labels are plain text, so the plugin uses colored emoji rather than
theme-colored glyphs. The marker is part of the actual tab label. If the tab bar
is configured to hide when there is one tab, its marker is also hidden.

## Installation and updates

`bootstrap.sh` links this checked-in plugin from the dotfiles checkout,
then uninstalls the previous naming plugin if present. Herdr keeps the old
plugin's state and config files; this plugin adopts its previously owned labels
and defaults to its former `overwrite_manual` and `max_length` settings.
Bootstrap re-links this plugin on every run to refresh the registered command
manifest. It uses only macOS system Perl (including the core JSON::PP module),
and requires Herdr 0.7.0 or later.

Changes to the plugin code in the dotfiles checkout become available to the
next Herdr event; no plugin build is necessary. A server startup hook
synchronizes restored tabs. Run Bootstrap after upgrading to refresh the
registered runtime command before invoking the action.

Manually sync any existing tabs:

```sh
herdr plugin action invoke daiksud.tab-agent-status.sync
```

The plugin listens for tab/pane creation, focus, move, close, Agent detection
and Agent status transitions. Plain `cd` has no Herdr event, so directory
names catch up on the next relevant event. It intentionally does not install
the previous `chpwd` shell hook, which could rename a tab from an unfocused
pane.

## Configuration

Optional JSON config at `$(herdr plugin config-dir daiksud.tab-agent-status)/config.json`:

```json
{
  "overwrite_manual": false,
  "max_length": 0
}
```

The default `max_length = 0` disables name truncation. These settings affect
only the directory portion of the label, not the Agent marker.

## Tests

```sh
/usr/bin/perl plugins/herdr-tab-status/sync.t
```

The directory-labeling behavior is adapted from
[dev-shimada/herdr-auto-tab-name](https://github.com/dev-shimada/herdr-auto-tab-name)
(MIT; see [LICENSE](LICENSE)).
