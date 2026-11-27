# omarchy-workspaces

[Omarchy](https://omarchy.org) bar widget (`pjf.workspaces`): a clone of the stock `omarchy.workspaces`
widget that always shows workspaces 1–0.

## Install

```sh
omarchy plugin add https://github.com/pjfitzgerald/omarchy-workspaces.git --enable
```

## Special workspaces

- **Scratchpad** (`special:scratchpad`): an inbox icon after the numbers while it holds windows (count when
  more than one); highlighted while it's open. Click toggles it.
- **Orchestrator popout** (`special:agent-orch`, see `agent-orch` in dotfiles): its sitemap icon while the
  orchestrator's terminal exists (dimmed); highlighted while it's open. Click toggles it.

While a special workspace is open on the bar's monitor, the regular workspace under it loses its focused
marker. Hyprland keeps the regular workspace focused, so the widget follows `activespecial` events instead.
