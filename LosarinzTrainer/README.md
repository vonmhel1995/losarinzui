# LOSARINZ TRAINER

> **Premium dark-violet UI framework for Roblox experiences** — single-file, drop-in, reusable.
> `v1.0.0` · Phase 1 — Core Framework · Developed by Losarinz

---

## About

**Losarinz** is a premium in-game UI framework built in Luau for experiences you own and develop.
Dark glassmorphism aesthetic, violet accent, sidebar + dashboard layout, fully animated, responsive
across **desktop, laptop, tablet and mobile**.

The entire framework ships as **one ModuleScript** — no folders, no Rojo, no external assets.

## Features (Phase 1)

- **Main window** — rounded glass surfaces, breathing violet glow border, animated open/close, mouse **and** touch dragging with screen-edge clamping, minimize/restore, close with floating restore orb
- **Sidebar navigation** — brand block, 5 tabs, animated active indicator, hover states, collapsible layout (manual + auto on mobile)
- **Dashboard** — gradient welcome header, player avatar + account info (User ID, account age, join date), live session card (timer + FPS + status), quick access controls, live recent-activity feed
- **Theme system** — one palette source of truth (`Losarinz.Theme`) with factory helpers
- **Responsive** — viewport-driven `UIScale`, window always fits ≤92% of screen, sidebar auto-collapses below 780px
- **Clean architecture** — pure-Lua signals, lazy page building, tween cancellation, full event cleanup (no memory leaks)

## Repository Structure

```text
LosarinzTrainer/
├── README.md
└── src/
    ├── Losarinz.lua        ← the entire framework (ModuleScript)
    └── Main.client.lua     ← 5-line bootstrap (LocalScript)
```

## Installation (2 objects)

1. **ReplicatedStorage** → create a **ModuleScript** named `Losarinz` → paste `src/Losarinz.lua`
2. **StarterPlayerScripts** (or StarterGui) → create a **LocalScript** named `Main` → paste `src/Main.client.lua`

Press **Play (F5)** — the window animates open.

## Quick Start

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Losarinz = require(ReplicatedStorage:WaitForChild("Losarinz"))

local UI = Losarinz.CreateWindow()

UI.RegisterActivity("Loaded my custom system")
UI.Navigation:SelectTab("Settings")
UI.Window:Minimize()
```

### Custom tabs

```lua
local UI = Losarinz.CreateWindow({
	Size = Vector2.new(900, 580),          -- optional
	Tabs = {                               -- optional (defaults to the 5 standard tabs)
		{ Name = "My Page", Icon = "⭐", Page = MyPageModule },
	},
})
```

**Page contract** — `Page` is a ModuleScript (or a plain table) exposing:

```lua
local MyPage = {}

function MyPage.Build(page: CanvasGroup, context): (() -> ())?
	-- context.Window          : the window instance (Show/Hide/Minimize/RegisterActivity...)
	-- context.RegisterActivity : fn(message) → feeds the dashboard activity feed
	-- build your UI inside `page` …
	return function()
		-- optional cleanup: disconnect connections here
	end
end

return MyPage
```

## API Reference

### `Losarinz.CreateWindow(options) → handle`

| Option | Type | Description |
|---|---|---|
| `Size` | `Vector2` | Window size (default `900 × 580`) |
| `Tabs` | `{TabConfig}` | Tab list; each `{ Name, Icon, Page?, Phase? }` |

### Handle

| Member | Description |
|---|---|
| `Window` | `:Show()` `:Hide()` `:Minimize()` `:Restore()` `:ToggleMinimize()` `:RegisterActivity(msg)` `:Destroy()` |
| `Navigation` | `:SelectTab(name)` `:SetCollapsed(bool)` `:ToggleCollapsed()` `:GetActiveTab()` `:Destroy()` |
| `RegisterActivity(msg)` | Push a message into the dashboard activity feed |
| `Config` / `Theme` | Framework tables — palette, metrics, tween presets, GUI factories |

### Notes

- Tabs **without** a `Page` render a styled empty state (used by the standard tabs until their phases land).
- If a page's `Build` errors, the tab shows a graceful *"Build error — check console (F9)"* state instead of breaking.

## Roadmap

| Phase | Scope | Status |
|---|---|---|
| 1 | Core framework — window, sidebar, dashboard, theme, navigation | ✅ Released |
| 2 | Premium visual upgrade — gradients, glow layers, icons, typography | ⏳ Next |
| 3 | Component library — toggles, sliders, dropdowns, keybinds, search, notifications | Planned |
| 4 | Settings & persistence — saved preferences, theme customization, reset | Planned |
| 5 | Optimization — testing, mobile polish, documentation | Planned |

> Phase updates ship as a **full replacement of `src/Losarinz.lua`** — re-paste one file to upgrade.

## License

© Losarinz — All rights reserved. (Swap in MIT/Apache-2.0 here if you want it open.)
