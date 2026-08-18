# 0031: Remap `ctrl+e` to the End key in Ghostty

Translate `ctrl+e` into the End key (`CSI F`) at the terminal layer, and move
raw Ctrl+E to `ctrl+alt+e`, so `ctrl+e` keeps acting as end-of-line in the
Copilot CLI Plan review dialog.

## Status

Accepted

## Context

Emacs keybindings assign `ctrl+e` to `end-of-line`. This is also the expected
behavior in the Copilot CLI's text inputs, including the feedback field shown
when a plan is ready for review.

Copilot CLI 1.0.80's `Plan Ready for Review` dialog has a global input handler
that uses `ctrl+e` to toggle between the plan summary and the full plan. The
handler runs before the feedback field's text input handler and is not guarded
by the feedback field's focus state. As a result, pressing `ctrl+e` while
writing feedback moves the cursor to the end of the line and toggles the plan
display at the same time.

The upstream bug is tracked by
[github/copilot-cli#2308](https://github.com/github/copilot-cli/issues/2308),
which describes the same end-of-line conflict during a question prompt.
[github/copilot-cli#3017](https://github.com/github/copilot-cli/issues/3017)
also tracks the Plan review shortcut. Both issues remain open. The broader
request for configurable keybindings,
[github/copilot-cli#2259](https://github.com/github/copilot-cli/issues/2259),
is also unimplemented.

Copilot CLI exposes no keybinding setting, `keybindings.json` integration, or
plugin API. Its raw-mode TUI reads the pty directly while the shell is
suspended, so zsh's `bindkey` and `stty` cannot alter the input before the CLI
receives it. The terminal emulator is the available interception layer.

The installed Copilot CLI license also excludes modifying, adapting,
translating, or creating derivative works of the software in Section 3.
Patching the installed `app.js` is therefore not an acceptable solution.

This is the same constraint and interception strategy documented in
[ADR 0030](./0030-ghostty-ctrl-d-delete-key.md).

## Decision

In `dotfiles/ghostty/config`, translate `ctrl+e` to the End key and move the
raw control character to an alternate chord:

```ini
keybind = ctrl+e=csi:F
keybind = ctrl+alt+e=text:\x05
```

In `dotfiles/zshrc`, bind the resulting sequence to zsh's `end-of-line`
widget:

```zsh
bindkey '^[[F' end-of-line
```

The Plan review dialog checks for `code === "e"` with the control modifier,
but it does not intercept `code === "end"`. The shared text input handles the
End key as end-of-line, so the terminal translation bypasses the conflicting
dialog shortcut while preserving cursor movement. The `ctrl+alt+e` mapping
sends the original `0x05` byte, keeping Copilot CLI's other `ctrl+e` actions
available through an explicit alternate chord.

The zsh binding is required because plain zsh does not assign `CSI F` to
`end-of-line`; without it, `ctrl+e` would become inert at the shell prompt.

## Alternatives Considered

### Patch the Copilot CLI bundle

Changing the Plan dialog handler would solve the conflict at its source, but
the installed software license excludes modification and derivative works.
Updates would also overwrite the local patch. Rejected.

### `keybind = ctrl+e=ignore`

Suppressing the chord would stop the Plan display toggle, but it would also
remove end-of-line from zsh and Copilot CLI, and discard `ctrl+e` behavior in
other programs. Translating to the equivalent End key preserves the intended
editing action. Rejected.

### Use the physical End key

The physical End key already bypasses the Copilot CLI dialog shortcut, but
requiring a separate key for a high-frequency editing action does not protect
against reflexive `ctrl+e` use. Rejected.

### Use a Ghostty key table or foreground-process condition

Ghostty cannot activate a key table based on the foreground process, and the
available herdr binding layer does not provide a reliable process condition
for this translation. A manually toggled table would be easy to forget, while
a process-detection hook would add latency and race conditions to every
`ctrl+e` press. Rejected.

### Wait for an upstream fix

The upstream issues are worth tracking, but they have no implemented fix or
keybinding configuration to use today. Waiting alone leaves the destructive
conflict unresolved. Rejected as the local solution.

## Consequences

- In Copilot CLI Plan review feedback fields, `ctrl+e` moves the cursor to the
  end of the line without toggling the plan display.
- Copilot CLI's other `ctrl+e` actions, including showing the full plan,
  opening the configured editor, expanding history or tool details, and
  displaying the QR code, are available through `ctrl+alt+e`.
- The multiline composer loses its `ctrl+e` smart-end escalation from the
  current visual line to the next visual line and then the buffer end.
  `End` stops at the current visual line; single-line fields behave the same.
- Neovim's `<C-e>` scrolling/copy behavior and `less`'s `ctrl+e` one-line
  advance become End-key behavior in Ghostty. Neovim's `<End>` and `less`'
  other navigation commands remain available.
- The mapping is unconditional across programs. It is accepted because
  `CSI F` is the standard End-key sequence and preserves the primary
  end-of-line action rather than suppressing the chord.
- Ghostty can validate the `csi:F` mapping, but the `text:` escape is not
  semantically verified at load time. Live testing is required for the
  `ctrl+alt+e` escape hatch.
- If Copilot CLI gains configurable keybindings or fixes the conflicting
  handler, remove the two Ghostty mappings and the zsh binding to restore the
  original behavior.
