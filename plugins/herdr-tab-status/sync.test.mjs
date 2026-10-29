import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import {
  directoryLabel, focusedCwd, mostUrgentStatus, nextTabLabel, synchronize,
} from './sync.mjs';

function createFixture(t, { tabs = [{ tab_id: 'w1:t1', label: '1' }], panes = [] } = {}) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'herdr-tab-status-'));
  t.after(() => fs.rmSync(root, { force: true, recursive: true }));
  const stateDir = path.join(root, 'plugins', 'daiksud.tab-agent-status');
  const configDir = path.join(root, 'config', 'daiksud.tab-agent-status');
  fs.mkdirSync(stateDir, { recursive: true });
  fs.mkdirSync(configDir, { recursive: true });
  const state = { tabs, panes, commands: [] };
  function herdr(args) {
    state.commands.push(args);
    const command = args.slice(0, 2).join(' ');
    if (command === 'workspace list') return { workspaces: [{ workspace_id: 'w1' }] };
    if (command === 'tab list') return { tabs: state.tabs };
    if (command === 'pane list') return { panes: state.panes };
    if (command === 'tab rename') {
      const [, , tabId, nextLabel] = args;
      const target = state.tabs.find((tab) => tab.tab_id === tabId);
      if (!target) throw new Error(`unknown tab ${tabId}`);
      target.label = nextLabel;
      return {};
    }
    throw new Error(`unexpected herdr invocation: ${args.join(' ')}`);
  }
  const sync = () => synchronize({ herdr, home: '/home/tester', stateDir, configDir });
  const labels = () => state.tabs.map((tab) => tab.label);
  const saved = () => JSON.parse(fs.readFileSync(path.join(stateDir, 'labels.json'), 'utf8'));
  const renames = () => state.commands.filter((command) => command[0] === 'tab' && command[1] === 'rename');
  return { root, state, stateDir, configDir, sync, labels, saved, renames };
}

function pane(fields = {}) {
  return { tab_id: 'w1:t1', cwd: '/home/tester/code', agent_status: 'idle', ...fields };
}

test('uses the focused pane directory and leaves plain terminal tabs unmarked', async (t) => {
  const fx = createFixture(t, { panes: [
    pane({ cwd: '/home/tester/unused', agent_status: 'idle' }),
    pane({ focused: true, foreground_cwd: '/projects/gh-settings' }),
  ] });
  await fx.sync();
  assert.deepEqual(fx.labels(), ['gh-settings']);
  assert.equal(fx.saved()['w1:t1'].automatic, true);
  await fx.sync();
  assert.equal(fx.renames().length, 1, 'unchanged tabs must not be renamed again');
});

test('aggregates all agents in the tab, not just the focused pane', async (t) => {
  const fx = createFixture(t, { panes: [
    pane({ agent: 'codex', focused: true, agent_status: 'working', cwd: '/repo/gh-settings' }),
    pane({ agent: 'claude', agent_status: 'blocked' }),
    pane({ agent: 'codex', agent_status: 'done' }),
  ] });
  await fx.sync();
  assert.deepEqual(fx.labels(), ['🔴 gh-settings']);
  fx.state.panes[1].agent_status = 'idle';
  await fx.sync();
  assert.deepEqual(fx.labels(), ['🟢 gh-settings'], 'done outranks working and idle');
  fx.state.panes[2].agent_status = 'working';
  await fx.sync();
  assert.deepEqual(fx.labels(), ['🟡 gh-settings']);
  fx.state.panes[2].agent_status = 'idle';
  fx.state.panes[0].agent_status = 'idle';
  await fx.sync();
  assert.deepEqual(fx.labels(), ['⚪ gh-settings']);
  fx.state.panes = [pane({ cwd: '/repo/gh-settings' })];
  await fx.sync();
  assert.deepEqual(fx.labels(), ['gh-settings'], 'agent removed clears status');
});

test('preserves manual names while updating agent status and directory', async (t) => {
  const fx = createFixture(t, { tabs: [{ tab_id: 'w1:t1', label: 'customer-work' }], panes: [
    pane({ agent: 'codex', agent_status: 'working', cwd: '/repo/first' }),
  ] });
  await fx.sync();
  assert.deepEqual(fx.labels(), ['🟡 customer-work']);
  fx.state.panes[0].cwd = '/repo/second';
  fx.state.panes[0].agent_status = 'blocked';
  await fx.sync();
  assert.deepEqual(fx.labels(), ['🔴 customer-work']);
  fx.state.tabs[0].label = 'manually renamed';
  fx.state.panes[0].agent_status = 'done';
  await fx.sync();
  assert.deepEqual(fx.labels(), ['🟢 manually renamed']);
  fx.state.panes[0].agent = null;
  await fx.sync();
  assert.deepEqual(fx.labels(), ['manually renamed']);
});

test('honors overwrite_manual after a manual tab was already synchronized', async (t) => {
  const fx = createFixture(t, { tabs: [{ tab_id: 'w1:t1', label: 'manually chosen' }], panes: [
    pane({ cwd: '/repo/selected-directory' }),
  ] });
  await fx.sync();
  assert.deepEqual(fx.labels(), ['manually chosen']);
  fs.writeFileSync(path.join(fx.configDir, 'config.json'), '{"overwrite_manual":true}');
  await fx.sync();
  assert.deepEqual(fx.labels(), ['selected-directory']);
});

test('adopts the former auto-tab-name plugin ownership during migration', async (t) => {
  const fx = createFixture(t, { tabs: [{ tab_id: 'w1:t1', label: 'old-project' }], panes: [
    pane({ agent: 'codex', agent_status: 'blocked', foreground_cwd: '/repo/new-project' }),
  ] });
  const legacyDir = path.join(fx.root, 'plugins', 'dev-shimada.auto-tab-name');
  fs.mkdirSync(legacyDir);
  fs.writeFileSync(path.join(legacyDir, 'labels.json'), '{"w1:t1":"old-project"}\n');
  await fx.sync();
  assert.deepEqual(fx.labels(), ['🔴 new-project']);
  assert.equal(fx.saved()['w1:t1'].automatic, true);
});

test('respects latest cwd, user config and unknown agent status', async (t) => {
  const fx = createFixture(t, { tabs: [{ tab_id: 'w1:t1', label: '1' }], panes: [
    pane({ agent: 'codex', agent_status: 'future', cwd: '/repo/language-tools' }),
  ] });
  fs.writeFileSync(path.join(fx.configDir, 'config.json'), '{"max_length":8}');
  await fx.sync();
  assert.deepEqual(fx.labels(), ['⚪ languag…']);
});

test('inherits the previous naming plugin configuration if not overridden', async (t) => {
  const fx = createFixture(t, { panes: [pane({ cwd: '/repo/abcdefghij' })] });
  const legacyDir = path.join(fx.root, 'config', 'dev-shimada.auto-tab-name');
  fs.mkdirSync(legacyDir);
  fs.writeFileSync(path.join(legacyDir, 'config.json'), '{"max_length":4}');
  await fx.sync();
  assert.deepEqual(fx.labels(), ['abc…']);
});

test('concurrent hooks do not duplicate labels or write operations', async (t) => {
  const fx = createFixture(t, { panes: [pane({ agent: 'codex', agent_status: 'done', cwd: '/repo/dotfiles' })] });
  await Promise.all([fx.sync(), fx.sync(), fx.sync()]);
  assert.deepEqual(fx.labels(), ['🟢 dotfiles']);
  assert.equal(fx.renames().length, 1);
});

test('retains auto-directory tracking after agent status disappears and cwd changes', async (t) => {
  const fx = createFixture(t, { panes: [pane({ agent: 'codex', agent_status: 'blocked', cwd: '/repo/a' })] });
  await fx.sync();
  fx.state.panes[0].agent = undefined;
  fx.state.panes[0].cwd = '/repo/b';
  await fx.sync();
  assert.deepEqual(fx.labels(), ['b']);
  fx.state.panes[0].cwd = '/repo/c';
  await fx.sync();
  assert.deepEqual(fx.labels(), ['c']);
});

test('home directory and simple status priority helpers', () => {
  assert.equal(directoryLabel('/home/tester', '/home/tester'), '~');
  assert.equal(directoryLabel('/', '/home/tester'), '/');
  assert.equal(directoryLabel(null, '/home/tester'), null);
  assert.equal(directoryLabel('/repo/hello', '/home/tester', 1), '…');
  assert.equal(focusedCwd([pane({ cwd: '/repo/one' }), pane({ focused: true, cwd: '/repo/two' })]), '/repo/two');
  assert.equal(mostUrgentStatus([pane({ agent_status: 'blocked' })]), null);
  assert.equal(mostUrgentStatus([pane({ agent: 'codex', agent_status: 'idle' })]), 'idle');
  assert.equal(nextTabLabel({ tab_id: 'w1:t1', label: '1' }, [], undefined, null,
    { overwrite_manual: false, max_length: 0 }, '/home/tester').nextLabel, '1');
});
