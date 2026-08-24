# ADR 0034: Restart Herdr after an incompatible Homebrew upgrade

Make the Herdr Homebrew service self-healing when its running server is older
than the installed client.

## Status

Accepted

## Context

Homebrew can replace the `herdr` executable while a previously started server
continues running. The new client may then report an incompatible protocol,
while `brew services start herdr` attempts to launch a second server against
the same socket. Herdr rejects that second process with `server is already
running`; launchd reports the failed keep-alive job as a bootstrap error.

The existing `scripts/100-herdr.sh` blindly starts the service and therefore
turns an otherwise successful `install.sh` run into a failure. Herdr's
documented recovery for package-manager upgrades is to stop the old server and
start it again with the updated binary.

## Decision

Make `scripts/100-herdr.sh` version- and health-aware on macOS.

- Read Herdr server status and Homebrew service status through their JSON
  interfaces.
- Clear inherited session and socket selectors when querying or stopping Herdr
  so the lifecycle operation always targets the default session managed by the
  Homebrew LaunchAgent.
- Leave a compatible server alone when it is already managed by a healthy
  Homebrew service, even when its version string differs from the installed
  client and Herdr recommends a restart.
- Serialize the complete status, handoff, and verification sequence with a
  per-user advisory lock. A later installer waits and then evaluates the state
  produced by the first installer.
- When the server is incompatible or not backed by a healthy service, stop the
  existing Homebrew job, stop the Herdr server, start the current Homebrew
  service, and verify that the resulting server is compatible.
- After stopping the old Homebrew job, re-read both service and server status.
  Preserve a healthy compatible service if launchd or another service actor
  has already recovered it instead of continuing the destructive handoff.
- If a status query fails after the Homebrew job was stopped, attempt to reload
  the job before reporting the original failure.
- Refuse that destructive handoff before changing the service when
  `HERDR_ENV=1`. The user must save pane work and rerun `install.sh` from a
  plain shell so stopping the server cannot terminate its own installer.
- Keep the Linux path as a no-op.
- Propagate status, stop, start, and verification errors instead of masking
  them.

## Alternatives Considered

### Always require manual recovery

The installer could report the mismatch and leave the old server running.
Rejected because every Homebrew upgrade would require a separate recovery
step and the installation would remain failed even though the correct binary
is installed. Requiring a plain-shell rerun only when the installer itself is
owned by a Herdr pane retains automatic recovery where it is safe.

### Restart on every installation

The installer could always stop and start Herdr. Rejected because it would
terminate active panes on every idempotent `install.sh` run, even when the
running server is already compatible.

### Rely on status rechecks without serialization

The installer could re-read both states immediately before stopping the
server. Rejected because another installer can still replace the server after
the read and before the stop. Serializing the complete decision and mutation
sequence closes that installer-to-installer race.

### Remove the Homebrew service

The installer could rely on a client-launched server instead of a resident
LaunchAgent. Rejected because the service is what keeps panes and agents alive
after terminal clients close and across reboots.

## Consequences

- Re-running `install.sh` is non-disruptive when the Herdr service is healthy
  and protocol-compatible, including across version-only upgrades.
- A stale or incompatible server is automatically handed off to the current
  Homebrew service from a plain shell, but stopping it terminates all processes
  in its panes.
- An installer running inside Herdr reports the required plain-shell rerun
  before it unloads the Homebrew job or stops the default server.
- Named and custom sessions are not inspected or stopped during Homebrew
  service recovery.
- Concurrent installers wait for the active lifecycle operation, then converge
  on its healthy service instead of stopping and restarting it again.
- A failed post-stop status query still fails the setup, but the installer
  attempts to reload the Homebrew job first.
- The service setup now depends on the JSON status interfaces of the installed
  Homebrew and Herdr versions.
- Hermetic Bats tests cover the lifecycle decisions without invoking launchd
  or stopping a real Herdr session.
