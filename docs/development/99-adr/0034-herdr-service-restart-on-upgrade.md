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
- Leave a compatible server alone when it is already managed by a healthy
  Homebrew service.
- When the server is stale, incompatible, or not backed by a healthy service,
  stop the existing Homebrew job, stop the Herdr server, start the current
  Homebrew service, and verify that the resulting server is compatible.
- Keep the Linux path as a no-op.
- Propagate status, stop, start, and verification errors instead of masking
  them.

## Alternatives Considered

### Require manual recovery

The installer could report the mismatch and leave the old server running.
Rejected because every Homebrew upgrade would require a separate recovery
step and the installation would remain failed even though the correct binary
is installed.

### Restart on every installation

The installer could always stop and start Herdr. Rejected because it would
terminate active panes on every idempotent `install.sh` run, even when the
running server is already compatible.

### Remove the Homebrew service

The installer could rely on a client-launched server instead of a resident
LaunchAgent. Rejected because the service is what keeps panes and agents alive
after terminal clients close and across reboots.

## Consequences

- Re-running `install.sh` is non-disruptive when the Herdr service is healthy
  and compatible.
- A stale or incompatible server is automatically handed off to the current
  Homebrew service, but stopping it terminates all processes in its panes.
- The service setup now depends on the JSON status interfaces of the installed
  Homebrew and Herdr versions.
- Hermetic Bats tests cover the lifecycle decisions without invoking launchd
  or stopping a real Herdr session.
