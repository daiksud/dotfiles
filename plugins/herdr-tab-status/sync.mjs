#!/usr/bin/env node
// Keep Herdr tab titles tied to the focused pane's directory and prefix them
// with the most urgent agent status across all panes in the tab.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const DEFAULT_LABEL = /^\d+$/;
const STATUS_MARKER = Object.freeze({
  blocked: '🔴',
  done: '🟢',
  working: '🟡',
  idle: '⚪',
  unknown: '⚪',
});
// Treat idle and unknown equally; both demand attention before a working Agent.
const STATUS_PRIORITY = Object.freeze({ working: 1, idle: 2, unknown: 2, done: 3, blocked: 4 });
const MARKER_PREFIX = /^(?:🔴|🟢|🟡|⚪) /u;

function readJson(file, fallback) {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
    return fallback;
  }
}

function writeJsonAtomic(file, data) {
  const temporary = `${file}.${process.pid}.tmp`;
  try {
    fs.writeFileSync(temporary, `${JSON.stringify(data, null, 2)}\n`);
    fs.renameSync(temporary, file);
  } finally {
    try { fs.unlinkSync(temporary); } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
  }
}

// Herdr can start multiple event hooks concurrently. Serialize read/rename/write
// cycles so a late hook cannot overwrite a newer tab label or state snapshot.
async function withLock(dir, action) {
  fs.mkdirSync(dir, { recursive: true });
  const lock = path.join(dir, '.sync-lock');
  let acquired = false;
  for (let attempt = 0; attempt < 60; attempt += 1) {
    try {
      fs.mkdirSync(lock);
      acquired = true;
      break;
    } catch (error) {
      if (error.code !== 'EEXIST') throw error;
      try {
        if (Date.now() - fs.statSync(lock).mtimeMs > 30_000) {
          fs.rmdirSync(lock);
        }
      } catch (statError) {
        if (!['ENOENT', 'ENOTEMPTY'].includes(statError.code)) throw statError;
      }
      if (attempt === 59) throw new Error('timed out waiting for tab status synchronization');
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
  }
  if (!acquired) throw new Error('cannot acquire tab status synchronization lock');
  try {
    return await action();
  } finally {
    fs.rmdirSync(lock);
  }
}

export function directoryLabel(cwd, home, maxLength = 0) {
  if (typeof cwd !== 'string' || cwd.length === 0) return null;
  let label = cwd === home ? '~' : (path.basename(cwd) || cwd);
  if (maxLength > 0 && Array.from(label).length > maxLength) {
    label = `${Array.from(label).slice(0, maxLength - 1).join('')}…`;
  }
  return label;
}

export function focusedCwd(tabPanes) {
  const pane = tabPanes.find((candidate) => candidate.focused) ?? tabPanes[0];
  return pane?.foreground_cwd || pane?.cwd || null;
}

function hasAgent(pane) {
  return [pane.agent, pane.display_agent].some((value) => typeof value === 'string' && value.trim().length > 0)
    || (pane.agent_session !== null && pane.agent_session !== undefined);
}

export function mostUrgentStatus(tabPanes) {
  let current = null;
  for (const pane of tabPanes) {
    if (!hasAgent(pane)) continue;
    const candidate = Object.hasOwn(STATUS_PRIORITY, pane.agent_status)
      ? pane.agent_status : 'unknown';
    if (current === null || STATUS_PRIORITY[candidate] > STATUS_PRIORITY[current]) {
      current = candidate;
    }
  }
  return current;
}

// lastLabel is the exact label this plugin most recently observed or emitted.
// A mismatch means someone manually renamed the tab: keep their new base name,
// but allow the status marker to update independently.
export function nextTabLabel(tab, tabPanes, previous, legacyOwnedLabel, config, home) {
  const currentLabel = tab.label;
  const cwd = directoryLabel(focusedCwd(tabPanes), home, config.max_length);
  const previousMatches = previous?.lastLabel === currentLabel;
  const base = previousMatches ? previous.base : currentLabel.replace(MARKER_PREFIX, '');
  const automatic = config.overwrite_manual || (previousMatches ? previous.automatic
    : DEFAULT_LABEL.test(currentLabel)
      || (previous === undefined && (legacyOwnedLabel === currentLabel || cwd === base)));
  const nextBase = automatic && cwd ? cwd : base;
  const status = mostUrgentStatus(tabPanes);
  const marker = status === null ? null : STATUS_MARKER[status];
  const nextLabel = marker === null ? nextBase : `${marker} ${nextBase}`;
  return { nextLabel, record: { lastLabel: nextLabel, base: nextBase, automatic } };
}

function invokeHerdr(args) {
  const binary = process.env.HERDR_BIN_PATH || 'herdr';
  const result = spawnSync(binary, args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`herdr ${args.join(' ')} failed: ${(result.stderr || result.stdout).trim()}`);
  }
  const response = JSON.parse(result.stdout);
  if (response.error) throw new Error(`herdr ${args.join(' ')}: ${response.error.message || JSON.stringify(response.error)}`);
  return response.result ?? response;
}

export async function synchronize({
  herdr = invokeHerdr,
  home = os.homedir(),
  stateDir = process.env.HERDR_PLUGIN_STATE_DIR,
  configDir = process.env.HERDR_PLUGIN_CONFIG_DIR,
} = {}) {
  if (!stateDir) throw new Error('HERDR_PLUGIN_STATE_DIR is required');
  return withLock(stateDir, async () => {
    const legacyConfigFile = configDir
      ? path.join(path.dirname(configDir), 'dev-shimada.auto-tab-name', 'config.json') : null;
    const legacyConfig = legacyConfigFile ? readJson(legacyConfigFile, {}) : {};
    const configData = configDir ? readJson(path.join(configDir, 'config.json'), legacyConfig) : legacyConfig;
    const config = {
      overwrite_manual: configData.overwrite_manual === true,
      max_length: Number.isInteger(configData.max_length) && configData.max_length >= 1
        ? configData.max_length : 0,
    };
    const stateFile = path.join(stateDir, 'labels.json');
    const previous = readJson(stateFile, {});
    // The former GitHub plugin retains its state after uninstall. Adopt titles
    // it owned, even if the shell has changed directory since its last event.
    const legacyFile = path.join(path.dirname(stateDir), 'dev-shimada.auto-tab-name', 'labels.json');
    const legacy = readJson(legacyFile, {});
    const next = {};
    const workspaces = herdr(['workspace', 'list']).workspaces;
    if (!Array.isArray(workspaces)) throw new Error('invalid Herdr workspace list');
    for (const workspace of workspaces) {
      const target = ['--workspace', workspace.workspace_id];
      const tabs = herdr(['tab', 'list', ...target]).tabs;
      const panes = herdr(['pane', 'list', ...target]).panes;
      if (!Array.isArray(tabs) || !Array.isArray(panes)) {
        throw new Error(`invalid Herdr tab/pane list for ${workspace.workspace_id}`);
      }
      for (const tab of tabs) {
        const tabPanes = panes.filter((pane) => pane.tab_id === tab.tab_id);
        const prior = Object.hasOwn(previous, tab.tab_id) ? previous[tab.tab_id] : undefined;
        const { nextLabel, record } = nextTabLabel(
          tab, tabPanes, prior, legacy[tab.tab_id], config, home,
        );
        if (tab.label !== nextLabel) herdr(['tab', 'rename', tab.tab_id, nextLabel]);
        next[tab.tab_id] = record;
      }
    }
    writeJsonAtomic(stateFile, next);
  });
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  synchronize().catch((error) => {
    console.error(`tab-agent-status: ${error.stack || error}`);
    process.exitCode = 1;
  });
}
