--[[
	LOSARINZ TRAINER • Main (LocalScript)
	Studio setup: place this as a LocalScript named "Main" in
	StarterPlayerScripts (or StarterGui), and the Losarinz ModuleScript
	in ReplicatedStorage. That's the entire install — 2 objects.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Losarinz = require(ReplicatedStorage:WaitForChild("Losarinz"))

-- Opens the window, selects Dashboard, starts the session log.
local UI = Losarinz.CreateWindow()

-- ── Examples for your future scripts ────────────────────────────────────────
-- UI.RegisterActivity("Loaded my custom system")
-- UI.Navigation:SelectTab("Settings")
-- UI.Window:Minimize()
-- UI.Window:Hide()   -- reopens via the floating "L" orb
--
-- Custom tabs: pass them through CreateWindow({ Tabs = { ... } }) —
-- see the header of src/Losarinz.lua for the page contract.
