// Modified from Herdr App 0.1.16; see herdr-app/LICENSE in this repository.
import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { spaces, panes, machines, agents, theme, run, window, keys, layout, checking } from "herdr";

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

export default class WorkspaceStatus extends View {
  init(_props, cx) {
    cx.timer.every(1000, (cx) => cx.notify());
  }

  // The palette key as actually bound, not a hardcoded one; without a
  // binding the hint stays useful ("commands") instead of lying.
  hint(t) {
    const mac = window()?.platform === "macos";
    const mod = { cmd: mac ? "⌘" : "Ctrl+", ctrl: mac ? "⌃" : "Ctrl+", shift: mac ? "⇧" : "Shift+", alt: mac ? "⌥" : "Alt+", option: mac ? "⌥" : "Alt+" };
    const b = keys().find((k) => k.section === "global" && k.action === "app.palette");
    const parts = b && b.keys.endsWith("--") ? [...b.keys.slice(0, -2).split("-"), "-"] : b?.keys.split("-");
    const key = parts && parts.map((p) => mod[p.toLowerCase()] ?? p.toUpperCase()).join("");
    return key ? `${key}  commands` : "commands";
  }

  render() {
    const t = theme();
    const now = new Date();
    const space = spaces().find(s => s.active);
    const hosts = machines();
    const ready = hosts.find(m => m.name === (space?.machine ?? null))?.layout === "ready";
    if (panes().some(p => p.terminal) || !ready) {
      this.openingTerminal = false;
    } else if (!checking() && !this.openingTerminal && !hosts.some(m => m.layout === "loading")) {
      // run() queues the command; wait for its pane before requesting another.
      this.openingTerminal = true;
      // tab.new also creates a space when the last one has been closed.
      run("tab.new");
    }
    const tabBar = find(layout(), "tabs");
    if (!checking() && space && tabBar?.content?.mod === "tabs-no-padding") {
      const hide = space.tabs.length === 1;
      if (Boolean(tabBar.hidden) !== hide) run(hide ? "layout.hide" : "layout.show", { id: "tabs" });
    }
    const list = agents();
    const needs = list.filter(a => a.status === "blocked").length;
    const label = (icon, text) => h_flex().gap(6).items_center().child(svg(`mods/workspace-chrome/${icon}.svg`).size(13)).child(text);
    return h_flex().size_full().px(14).gap(16).items_center().bg(t.chrome).border_t(1).border_color(t.border).text_size(11.8).text_color(t.muted)
      .child(label(space?.machine ? "server" : "monitor", space?.machine ?? "This computer"))
      .when(Boolean(space?.branch), el => el.child(label("branch", space.branch)))
      .child(h_flex().gap(6).items_center().child(div().size(6).rounded(3).bg(t.dim)).child(`${list.length} agents`)
        .when(needs > 0, el => el.child(div().text_color(t.blocked).child(`· ${needs} needs you`))))
      .child(div().flex_1())
      .child(div().id("palette").text_color(t.dim).on_click(() => run("app.palette")).child(this.hint(t)))
      .child(div().flex_none().whitespace_nowrap().child(`${now.toDateString().slice(0, 10)} ${now.toTimeString().slice(0, 8)}`));
  }
}
