--[[
	LOSARINZ TRAINER — Premium Roblox UI Framework
	Version : 1.0.0 (Phase 1 — Core Framework)
	Author  : Developed by Losarinz
	Style   : Premium Futuristic / Dark Glassmorphism · Violet

	SINGLE-FILE BUILD
	=================
	Drop this ModuleScript into ReplicatedStorage named "Losarinz", then:

		local Losarinz = require(game:GetService("ReplicatedStorage").Losarinz)
		local UI = Losarinz.CreateWindow()

	Custom tabs (Page accepts a ModuleScript or a table with Build(page, ctx)):

		local UI = Losarinz.CreateWindow({
			Tabs = {
				{ Name = "My Page", Icon = "⭐", Page = MyPageModule },
			},
		})

	Page contract: Build(pageFrame: CanvasGroup, context) -> optional cleanup function.
	context = { Window, RegisterActivity(message) }
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. CONFIG — branding, layout metrics, animation presets
-- ═══════════════════════════════════════════════════════════════════════════

local Config = {}

Config.Brand = {
	Name = "LOSARINZ",
	Subtitle = "TRAINER",
	WindowTitle = "LOSARINZ TRAINER",
	Greeting = "Welcome to Losarinz",
	Footer = "Developed by Losarinz",
	Version = "1.0.0",
}

Config.Window = {
	DefaultSize = Vector2.new(900, 580),
	TitleBarHeight = 56,
	MaxViewportFraction = 0.92, -- window never exceeds this fraction of the screen
	ScaleReferenceWidth = 1280, -- viewport width that maps to scale 1.0
	ScaleMin = 0.55,
	ScaleMax = 1.05,
	DisplayOrder = 50,
}

Config.Navigation = {
	ExpandedWidth = 220,
	CollapsedWidth = 64,
	MobileBreakpoint = 780, -- viewports narrower than this auto-collapse the sidebar
}

Config.Animation = {
	Open = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Close = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	Page = TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	Hover = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	WindowMove = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
	Collapse = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
	Fade = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. THEME — palette, typography and GUI factory helpers
-- ═══════════════════════════════════════════════════════════════════════════

local Theme = {}

Theme.Colors = {
	Background = Color3.fromHex("#090812"),
	Sidebar = Color3.fromHex("#0F0D1B"),
	MainPanel = Color3.fromHex("#141122"),
	Card = Color3.fromHex("#1D1830"),
	CardHover = Color3.fromHex("#262043"),
	Primary = Color3.fromHex("#8B5CF6"),
	Secondary = Color3.fromHex("#A855F7"),
	Glow = Color3.fromHex("#C084FC"),
	TextPrimary = Color3.fromHex("#F5F3FF"),
	TextSecondary = Color3.fromHex("#9690AA"),
	Success = Color3.fromHex("#4ADE80"),
	Warning = Color3.fromHex("#FACC15"),
	Error = Color3.fromHex("#F87171"),
	Outline = Color3.fromHex("#2A2440"),
}

local function font(weight)
	return Font.new("rbxasset://fonts/families/GothamSSm.json", weight, Enum.FontStyle.Normal)
end

Theme.Fonts = {
	Bold = font(Enum.FontWeight.Bold),
	Medium = font(Enum.FontWeight.Medium),
	Regular = font(Enum.FontWeight.Regular),
}

Theme.Radius = {
	Window = UDim.new(0, 14),
	Card = UDim.new(0, 10),
	Control = UDim.new(0, 8),
	Pill = UDim.new(1, 0),
}

-- Creates an instance, applies properties, parents children, then parents itself.
function Theme.instance(className, props, children, parent)
	local inst = Instance.new(className)
	if props then
		for key, value in props do
			inst[key] = value
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function Theme.corner(radius)
	return Theme.instance("UICorner", { CornerRadius = radius or Theme.Radius.Card })
end

function Theme.stroke(color, thickness, transparency)
	return Theme.instance("UIStroke", {
		Color = color or Theme.Colors.Outline,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Theme.padding(left, top, right, bottom)
	return Theme.instance("UIPadding", {
		PaddingLeft = UDim.new(0, left),
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
	})
end

function Theme.list(direction, gap, horizontalAlign, verticalAlign)
	return Theme.instance("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, gap or 0),
		HorizontalAlignment = horizontalAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = verticalAlign or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

function Theme.violetGradient(rotation)
	return Theme.instance("UIGradient", {
		Color = ColorSequence.new(Theme.Colors.Primary, Theme.Colors.Glow),
		Rotation = rotation or 45,
	})
end

-- Standard text label. opts: { Color, Font, Align, Size, Truncate }
function Theme.text(text, size, opts)
	opts = opts or {}
	return Theme.instance("TextLabel", {
		Text = text,
		TextSize = size,
		Font = opts.Font or Theme.Fonts.Medium,
		TextColor3 = opts.Color or Theme.Colors.TextPrimary,
		TextXAlignment = opts.Align or Enum.TextXAlignment.Left,
		Size = opts.Size or UDim2.new(1, 0, 1, 0),
		TextTruncate = opts.Truncate == false and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})
end

-- Plays a tween and returns it so callers can await or cancel it.
function Theme.play(inst, info, props)
	local tween = TweenService:Create(inst, info, props)
	tween:Play()
	return tween
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. SIGNAL — minimal pure-Lua signal (no Instance overhead)
-- ═══════════════════════════════════════════════════════════════════════════

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(handler)
	local handlers = self._handlers
	table.insert(handlers, handler)
	local connection = {}
	function connection.Disconnect()
		local index = table.find(handlers, handler)
		if index then
			table.remove(handlers, index)
		end
	end
	return connection
end

function Signal:Fire(...)
	for _, handler in self._handlers do
		task.spawn(handler, ...)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. WINDOW CONTROLLER — chrome, drag, minimize/close, responsive scaling
-- ═══════════════════════════════════════════════════════════════════════════

-- Window control icons, drawn from Frames (deterministic — no external assets)
local function iconBar(width, yOffset, rotation)
	return Theme.instance("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, yOffset or 0.5),
		Size = UDim2.fromOffset(width, 2),
		BackgroundColor3 = Theme.Colors.TextSecondary,
		BorderSizePixel = 0,
		Rotation = rotation or 0,
	})
end

local function controlButton(hoverColor)
	local button = Theme.instance("TextButton", {
		Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = Theme.Colors.Card,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
	}, { Theme.corner(Theme.Radius.Control) })
	button.MouseEnter:Connect(function()
		if hoverColor then
			Theme.play(button, Config.Animation.Hover, { BackgroundTransparency = 0.82, BackgroundColor3 = hoverColor })
		end
	end)
	button.MouseLeave:Connect(function()
		Theme.play(button, Config.Animation.Hover, { BackgroundTransparency = 1 })
	end)
	return button
end

local WindowController = {}
local Window = {}
Window.__index = Window

function WindowController.new(config)
	local self = setmetatable({}, Window)

	config = config or {}
	self._size = config.Size or Config.Window.DefaultSize
	self._minimized = false
	self._visible = false
	self._scale = 1
	self._connections = {}
	self.Viewport = Vector2.new(1280, 720)

	self.Activity = Signal.new() -- (timeText, message)
	self.OnToggleSidebar = Signal.new()
	self.ViewportChanged = Signal.new() -- (viewport, scale)

	local player = Players.LocalPlayer
	if not player then
		error("[Losarinz] WindowController must run in a client context (LocalPlayer missing).")
	end

	-- ScreenGui
	local gui = Theme.instance("ScreenGui", {
		Name = "LosarinzTrainer",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = Config.Window.DisplayOrder,
	})
	gui.Parent = player.PlayerGui
	self._gui = gui

	-- Root: CanvasGroup gives rounded clipping + whole-window group fades
	local glowStroke = Theme.stroke(Theme.Colors.Glow, 1.6, 0.3)
	Theme.violetGradient(90).Parent = glowStroke

	local scaleObj = Theme.instance("UIScale", { Name = "ResponsiveScale" })
	local openScale = Theme.instance("UIScale", { Name = "OpenScale", Scale = 0.92 })

	local root = Theme.instance("CanvasGroup", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(self._size.X, self._size.Y),
		BackgroundColor3 = Theme.Colors.Background,
		GroupTransparency = 1,
		Visible = false,
		BorderSizePixel = 0,
	}, {
		Theme.corner(Theme.Radius.Window),
		glowStroke,
		scaleObj,
		openScale,
	})
	root.Parent = gui

	self._root = root
	self._scaleObj = scaleObj
	self._openScale = openScale

	-- Breathing glow (lifetime tween, cancelled on Destroy)
	self._glowPulse = TweenService:Create(glowStroke,
		TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.55 })
	self._glowPulse:Play()

	-- Layout skeleton: TitleBar over Body(Sidebar | Separator | MainPanel)
	Theme.list(Enum.FillDirection.Vertical, 0).Parent = root

	local titleBar = Theme.instance("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, Config.Window.TitleBarHeight),
		BackgroundColor3 = Theme.Colors.Sidebar,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		LayoutOrder = 1,
	})
	titleBar.Parent = root

	local body = Theme.instance("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 1, -Config.Window.TitleBarHeight),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 2,
	})
	body.Parent = root

	Theme.list(Enum.FillDirection.Horizontal, 0).Parent = body

	local sidebar = Theme.instance("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, Config.Navigation.ExpandedWidth, 1, 0),
		BackgroundColor3 = Theme.Colors.Sidebar,
		BorderSizePixel = 0,
		LayoutOrder = 1,
	})
	sidebar.Parent = body
	self.Sidebar = sidebar

	Theme.instance("Frame", {
		Name = "Separator",
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Theme.Colors.Outline,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		LayoutOrder = 2,
	}).Parent = body

	local mainPanel = Theme.instance("Frame", {
		Name = "MainPanel",
		Size = UDim2.fromScale(0, 0), -- UIFlexItem.Fill takes all remaining width
		BackgroundColor3 = Theme.Colors.MainPanel,
		BorderSizePixel = 0,
		LayoutOrder = 3,
	}, { Theme.instance("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }) })
	mainPanel.Parent = body
	self.MainPanel = mainPanel

	-- Title bar content
	Theme.padding(18, 0, 0, 0).Parent = titleBar

	Theme.instance("TextLabel", {
		Name = "Brand",
		Size = UDim2.new(0, 320, 1, 0),
		BackgroundTransparency = 1,
		RichText = true,
		Text = ("%s  <font color=\"#A855F7\" size=\"11\">%s</font>"):format(Config.Brand.Name, Config.Brand.Subtitle),
		TextSize = 15,
		Font = Theme.Fonts.Bold,
		TextColor3 = Theme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
	}).Parent = titleBar

	local controls = Theme.instance("Frame", {
		Name = "Controls",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(126, 34),
		BackgroundTransparency = 1,
	}, { Theme.list(Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right) })
	controls.Parent = titleBar

	-- Hamburger (sidebar toggle)
	local menuButton = controlButton()
	for _, y in { 0.22, 0.5, 0.78 } do
		iconBar(14, y).Parent = menuButton
	end
	menuButton.Parent = controls

	-- Minimize / restore (icon morphs between bar and square)
	local minimizeButton = controlButton()
	local minBar = iconBar(12)
	minBar.Parent = minimizeButton
	local restoreSquare = Theme.instance("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(10, 10),
		BackgroundTransparency = 1,
		Visible = false,
	}, {
		Theme.corner(UDim.new(0, 3)),
		Theme.stroke(Theme.Colors.TextSecondary, 1.5),
	})
	restoreSquare.Parent = minimizeButton
	minimizeButton.Parent = controls
	self._minimizeIcon = { bar = minBar, square = restoreSquare }

	-- Close (red hover tint)
	local closeButton = controlButton(Theme.Colors.Error)
	iconBar(12, 0.5, 45).Parent = closeButton
	iconBar(12, 0.5, -45).Parent = closeButton
	closeButton.Parent = controls

	-- Violet hairline fading out to the right, under the title bar
	Theme.instance("Frame", {
		Name = "Hairline",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(1, -36, 0, 1),
		BackgroundColor3 = Theme.Colors.Primary,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
	}, {
		Theme.instance("UIGradient", {
			Color = ColorSequence.new(Theme.Colors.Primary, Theme.Colors.Background),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.6, 0.4),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	}).Parent = titleBar

	-- Restore orb (appears when the window is closed)
	local orb = Theme.instance("TextButton", {
		Name = "RestoreOrb",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -22, 1, -22),
		Size = UDim2.fromOffset(46, 46),
		BackgroundColor3 = Theme.Colors.Card,
		Text = "L",
		TextSize = 18,
		Font = Theme.Fonts.Bold,
		TextColor3 = Theme.Colors.Glow,
		AutoButtonColor = false,
		Visible = false,
		BorderSizePixel = 0,
	}, {
		Theme.corner(Theme.Radius.Pill),
		Theme.stroke(Theme.Colors.Primary, 1.5, 0.25),
	})
	orb.Parent = gui
	self._orb = orb

	-- Behaviour wiring
	closeButton.Activated:Connect(function()
		self:Hide()
	end)
	minimizeButton.Activated:Connect(function()
		self:ToggleMinimize()
	end)
	menuButton.Activated:Connect(function()
		self.OnToggleSidebar:Fire()
	end)
	orb.Activated:Connect(function()
		self:Show()
	end)

	self:_setupDragging(titleBar)
	self:_updateScale()

	table.insert(self._connections, Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		self:_bindCamera()
		self:_updateScale()
	end))
	self:_bindCamera()

	return self
end

function Window:_bindCamera()
	local camera = Workspace.CurrentCamera
	if camera then
		table.insert(self._connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			self:_updateScale()
		end))
	end
end

-- Base scale from viewport width; "fit" caps the window to the screen.
function Window:_updateScale()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	local cfg = Config.Window
	local base = math.clamp(viewport.X / cfg.ScaleReferenceWidth, cfg.ScaleMin, cfg.ScaleMax)
	local fit = math.min(
		viewport.X * cfg.MaxViewportFraction / self._size.X,
		viewport.Y * 0.88 / self._size.Y
	)
	local scale = math.min(base, fit)
	self._scale = scale
	self._scaleObj.Scale = scale
	self.Viewport = viewport
	self.ViewportChanged:Fire(viewport, scale)
	self:_clampToScreen()
end

-- Keeps the title bar grabbable: at least 90px/60px of window stays on screen.
function Window:_clampToScreen()
	local camera = Workspace.CurrentCamera
	local root = self._root
	if not camera or not root.Visible then
		return
	end
	local viewport = camera.ViewportSize
	local absolute = root.AbsoluteSize
	local scale = absolute.X / math.max(root.Size.X.Offset, 1)
	local centerX = viewport.X / 2 + root.Position.X.Offset * scale
	local centerY = viewport.Y / 2 + root.Position.Y.Offset * scale

	local halfW, halfH = absolute.X / 2, absolute.Y / 2
	local minX, maxX = halfW - 90, viewport.X - halfW + 90
	local minY, maxY = halfH - 60, viewport.Y - halfH + 60
	centerX = if minX > maxX then viewport.X / 2 else math.clamp(centerX, minX, maxX)
	centerY = if minY > maxY then viewport.Y / 2 else math.clamp(centerY, minY, maxY)

	root.Position = UDim2.new(
		0.5, (centerX - viewport.X / 2) / scale,
		0.5, (centerY - viewport.Y / 2) / scale
	)
end

-- Custom dragging (Draggable is deprecated). Mouse + touch; deltas are
-- divided by the UI scale so tracking stays 1:1 with the cursor.
function Window:_setupDragging(handle)
	local dragging = false
	local startInputPos = nil
	local startPosition = nil

	table.insert(self._connections, handle.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startInputPos = input.Position
			startPosition = self._root.Position
		end
	end))

	table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging or not startInputPos or not startPosition then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local scale = self._scale
		self._root.Position = UDim2.new(
			startPosition.X.Scale, startPosition.X.Offset + (input.Position.X - startInputPos.X) / scale,
			startPosition.Y.Scale, startPosition.Y.Offset + (input.Position.Y - startInputPos.Y) / scale
		)
		self:_clampToScreen()
	end))
end

function Window:Show()
	if self._visible then
		return
	end
	self._visible = true
	self._orb.Visible = false
	self._root.Visible = true
	self._openScale.Scale = 0.92
	self._root.GroupTransparency = 1
	Theme.play(self._root, Config.Animation.Open, { GroupTransparency = 0 })
	Theme.play(self._openScale, Config.Animation.Open, { Scale = 1 })
	self:_clampToScreen()
end

function Window:Hide()
	if not self._visible then
		return
	end
	self._visible = false
	local fade = Theme.play(self._root, Config.Animation.Close, { GroupTransparency = 1 })
	Theme.play(self._openScale, Config.Animation.Close, { Scale = 0.94 })
	fade.Completed:Once(function()
		if not self._visible then
			self._root.Visible = false
			self._orb.Visible = true
		end
	end)
end

function Window:ToggleMinimize()
	if self._minimized then
		self:Restore()
	else
		self:Minimize()
	end
end

function Window:Minimize()
	if self._minimized then
		return
	end
	self._minimized = true
	self._minimizeIcon.bar.Visible = false
	self._minimizeIcon.square.Visible = true
	Theme.play(self._root, Config.Animation.WindowMove, {
		Size = UDim2.fromOffset(self._size.X, Config.Window.TitleBarHeight),
	})
end

function Window:Restore()
	if not self._minimized then
		return
	end
	self._minimized = false
	self._minimizeIcon.bar.Visible = true
	self._minimizeIcon.square.Visible = false
	Theme.play(self._root, Config.Animation.WindowMove, {
		Size = UDim2.fromOffset(self._size.X, self._size.Y),
	})
end

function Window:RegisterActivity(message)
	self.Activity:Fire(os.date("%H:%M:%S"), message)
end

function Window:Destroy()
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
	if self._glowPulse then
		self._glowPulse:Cancel()
	end
	self._gui:Destroy()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. NAVIGATION CONTROLLER — sidebar, nav buttons, routed pages
-- ═══════════════════════════════════════════════════════════════════════════

local NavigationController = {}
local Nav = {}
Nav.__index = Nav

local function makeNavButton(name, icon, order)
	local button = Theme.instance("TextButton", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = Theme.Colors.Card,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		LayoutOrder = order,
	}, { Theme.corner(Theme.Radius.Control) })

	local indicator = Theme.instance("Frame", {
		Name = "Indicator",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(3, 22),
		BackgroundColor3 = Theme.Colors.Glow,
		Transparency = 1,
		BorderSizePixel = 0,
	}, { Theme.corner(Theme.Radius.Pill) })
	indicator.Parent = button

	local iconLabel = Theme.instance("TextLabel", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 1,
		Text = icon or "•",
		TextSize = 17,
		Font = Theme.Fonts.Medium,
		TextColor3 = Theme.Colors.TextSecondary,
	})
	iconLabel.Parent = button

	local nameLabel = Theme.instance("TextLabel", {
		Name = "Label",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 48, 0.5, 0),
		Size = UDim2.new(1, -56, 1, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextSize = 13,
		Font = Theme.Fonts.Medium,
		TextColor3 = Theme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	nameLabel.Parent = button

	return button, indicator, iconLabel, nameLabel
end

-- Empty state for tabs whose content arrives in a later phase (or on error).
local function buildEmptyState(page, tabName, message)
	local container = Theme.instance("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Theme.list(Enum.FillDirection.Vertical, 10, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center),
	})
	container.Parent = page

	Theme.instance("TextLabel", {
		Size = UDim2.fromOffset(280, 30),
		BackgroundTransparency = 1,
		Text = tabName,
		TextSize = 22,
		Font = Theme.Fonts.Bold,
		TextColor3 = Theme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Center,
	}).Parent = container

	Theme.instance("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 0, 24),
		BackgroundColor3 = Theme.Colors.Card,
		BorderSizePixel = 0,
		Text = ("  %s  "):format(message),
		TextSize = 11,
		Font = Theme.Fonts.Medium,
		TextColor3 = Theme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Center,
	}, {
		Theme.corner(Theme.Radius.Pill),
		Theme.stroke(Theme.Colors.Outline, 1, 0.4),
		Theme.padding(10, 0, 10, 0),
	}).Parent = container

	Theme.instance("Frame", {
		Size = UDim2.fromOffset(120, 1),
		BackgroundColor3 = Theme.Colors.Outline,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
	}).Parent = container
end

function NavigationController.new(window, tabs)
	local self = setmetatable({}, Nav)
	self._window = window
	self._tabs = tabs
	self._byName = {}
	self._active = nil
	self._collapsed = false
	self._connections = {}

	self:_buildSidebar()

	-- Responsive: auto-collapse on narrow viewports
	table.insert(self._connections, window.ViewportChanged:Connect(function()
		self:_setCollapsed(window.Viewport.X < Config.Navigation.MobileBreakpoint, true)
	end))
	self:_setCollapsed(window.Viewport.X < Config.Navigation.MobileBreakpoint, true)

	-- Hamburger + dashboard quick access both route through this signal
	table.insert(self._connections, window.OnToggleSidebar:Connect(function()
		self:ToggleCollapsed()
	end))

	return self
end

function Nav:_buildSidebar()
	local sidebar = self._window.Sidebar

	Theme.padding(12, 16, 12, 14).Parent = sidebar
	Theme.list(Enum.FillDirection.Vertical, 8).Parent = sidebar

	-- Brand block
	local brand = Theme.instance("Frame", {
		Name = "Brand",
		Size = UDim2.new(1, 0, 0, 78),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, { Theme.list(Enum.FillDirection.Vertical, 3) })
	brand.Parent = sidebar

	self._brandLogo = Theme.instance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Text = Config.Brand.Name,
		TextSize = 19,
		Font = Theme.Fonts.Bold,
		TextColor3 = Theme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, {
		Theme.instance("UIGradient", {
			Color = ColorSequence.new(Theme.Colors.TextPrimary, Theme.Colors.Glow),
			Rotation = 90,
		}),
	})
	self._brandLogo.Parent = brand

	self._brandTag = Theme.instance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Text = Config.Brand.Subtitle,
		TextSize = 10,
		Font = Theme.Fonts.Medium,
		TextColor3 = Theme.Colors.Secondary,
	})
	self._brandTag.Parent = brand

	self._versionPill = Theme.instance("TextLabel", {
		Size = UDim2.fromOffset(64, 20),
		BackgroundColor3 = Theme.Colors.Card,
		BorderSizePixel = 0,
		Text = ("v%s"):format(Config.Brand.Version),
		TextSize = 10,
		Font = Theme.Fonts.Medium,
		TextColor3 = Theme.Colors.TextSecondary,
		LayoutOrder = 3,
	}, { Theme.corner(Theme.Radius.Pill), Theme.stroke(Theme.Colors.Outline, 1, 0.5) })
	self._versionPill.Parent = brand

	-- Nav buttons
	local navList = Theme.instance("Frame", {
		Name = "NavList",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
	}, { Theme.list(Enum.FillDirection.Vertical, 4) })
	navList.Parent = sidebar

	for index, tab in self._tabs do
		local button, indicator, iconLabel, nameLabel = makeNavButton(tab.Name, tab.Icon or "", index)
		button.Parent = navList

		local entry = {
			Tab = tab,
			Button = button,
			Indicator = indicator,
			Icon = iconLabel,
			Label = nameLabel,
			Page = nil,
			CleanUp = nil,
			Tween = nil,
		}
		self._byName[tab.Name] = entry

		button.MouseEnter:Connect(function()
			if self._active ~= entry then
				Theme.play(button, Config.Animation.Hover, { BackgroundTransparency = 0.55 })
			end
		end)
		button.MouseLeave:Connect(function()
			if self._active ~= entry then
				Theme.play(button, Config.Animation.Hover, { BackgroundTransparency = 1 })
			end
		end)
		button.Activated:Connect(function()
			self:SelectTab(tab.Name)
		end)
	end

	-- Spacer pushes the footer to the bottom
	Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
	}, { Theme.instance("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }) }).Parent = sidebar

	-- Footer: credit + online status
	local footer = Theme.instance("Frame", {
		Name = "Footer",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
	}, { Theme.list(Enum.FillDirection.Vertical, 4) })
	footer.Parent = sidebar

	self._footerCredit = Theme.instance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundTransparency = 1,
		Text = Config.Brand.Footer,
		TextSize = 10,
		Font = Theme.Fonts.Regular,
		TextColor3 = Theme.Colors.TextSecondary,
	})
	self._footerCredit.Parent = footer

	local statusRow = Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
	}, { Theme.list(Enum.FillDirection.Horizontal, 6) })
	statusRow.Parent = footer

	self._statusDot = Theme.instance("Frame", {
		Size = UDim2.fromOffset(7, 7),
		BackgroundColor3 = Theme.Colors.Success,
		BorderSizePixel = 0,
	}, { Theme.corner(Theme.Radius.Pill) })
	self._statusDot.Parent = statusRow

	self._statusLabel = Theme.instance("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "Online",
		TextSize = 11,
		Font = Theme.Fonts.Medium,
		TextColor3 = Theme.Colors.Success,
	})
	self._statusLabel.Parent = statusRow
end

-- ── Collapse ────────────────────────────────────────────────────────────────

function Nav:SetCollapsed(collapsed)
	self:_setCollapsed(collapsed, true)
end

function Nav:ToggleCollapsed()
	self:_setCollapsed(not self._collapsed, true)
end

function Nav:_setCollapsed(collapsed, animate)
	if collapsed == self._collapsed then
		return
	end
	self._collapsed = collapsed

	local sidebar = self._window.Sidebar
	local width = if collapsed then Config.Navigation.CollapsedWidth else Config.Navigation.ExpandedWidth
	local info = if animate then Config.Animation.Collapse else TweenInfo.new(0)
	local hidden = if collapsed then 1 else 0

	Theme.play(sidebar, info, { Size = UDim2.new(0, width, 1, 0) })

	for _, label in { self._brandLogo, self._brandTag, self._footerCredit, self._statusLabel } do
		Theme.play(label, info, { TextTransparency = hidden })
	end
	Theme.play(self._versionPill, info, { TextTransparency = hidden, BackgroundTransparency = hidden })
	Theme.play(self._statusDot, info, { BackgroundTransparency = hidden })

	for _, entry in self._byName do
		Theme.play(entry.Icon, info, {
			Position = if collapsed then UDim2.fromScale(0.5, 0.5) else UDim2.new(0, 14, 0.5, 0),
			AnchorPoint = if collapsed then Vector2.new(0.5, 0.5) else Vector2.new(0, 0.5),
		})
		Theme.play(entry.Label, info, { TextTransparency = hidden })
	end
end

-- ── Pages ───────────────────────────────────────────────────────────────────

function Nav:_applyButtonState(entry, isActive)
	local info = Config.Animation.Hover
	Theme.play(entry.Button, info, { BackgroundTransparency = if isActive then 0 else 1 })
	Theme.play(entry.Indicator, info, { Transparency = if isActive then 0 else 1 })
	Theme.play(entry.Label, info, {
		TextColor3 = if isActive then Theme.Colors.TextPrimary else Theme.Colors.TextSecondary,
	})
end

function Nav:_buildPage(entry)
	local tab = entry.Tab
	local page = Theme.instance("CanvasGroup", {
		Name = tab.Name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		BorderSizePixel = 0,
	})
	page.Parent = self._window.MainPanel

	if tab.Page then
		local ok, result = pcall(function()
			-- Page may be a ModuleScript or an already-required table
			local source = tab.Page
			if typeof(source) == "Instance" and source:IsA("ModuleScript") then
				source = require(source)
			end
			local build = if typeof(source) == "table" and typeof(source.Build) == "function"
				then source.Build
				else source
			return build(page, {
				Window = self._window,
				RegisterActivity = function(message)
					self._window:RegisterActivity(message)
				end,
			})
		end)
		if not ok then
			warn(("[Losarinz] Page '%s' failed to build: %s"):format(tab.Name, tostring(result)))
			buildEmptyState(page, tab.Name, "Build error — check console (F9)")
		elseif typeof(result) == "function" then
			entry.CleanUp = result
		end
	else
		buildEmptyState(page, tab.Name,
			if tab.Phase then ("Unlocks in Phase %d"):format(tab.Phase) else "Coming soon")
	end

	return page
end

function Nav:_showPage(entry)
	local page = entry.Page
	self:_cancelPageTween(entry)
	page.Visible = true
	page.GroupTransparency = 1
	page.Position = UDim2.fromOffset(0, 16)
	entry.Tween = Theme.play(page, Config.Animation.Page, {
		GroupTransparency = 0,
		Position = UDim2.fromOffset(0, 0),
	})
end

function Nav:_hidePage(entry)
	local page = entry.Page
	if not page then
		return
	end
	self:_cancelPageTween(entry)
	entry.Tween = Theme.play(page, Config.Animation.Close, { GroupTransparency = 1 })
	entry.Tween.Completed:Once(function()
		-- Only hide if nothing re-selected this page while we were fading out
		if self._active ~= entry and page.GroupTransparency >= 0.99 then
			page.Visible = false
		end
	end)
end

function Nav:_cancelPageTween(entry)
	if entry.Tween then
		entry.Tween:Cancel()
		entry.Tween = nil
	end
end

-- ── Public API ──────────────────────────────────────────────────────────────

function Nav:SelectTab(name)
	local entry = self._byName[name]
	if not entry then
		warn(("[Losarinz] Unknown tab: %s"):format(name))
		return
	end
	if self._active == entry then
		return
	end

	local previous = self._active
	self._active = entry

	for _, other in self._byName do
		self:_applyButtonState(other, other == entry)
	end

	if previous and previous.Page then
		self:_hidePage(previous)
	end

	if not entry.Page then
		entry.Page = self:_buildPage(entry)
	end
	self:_showPage(entry)

	self._window:RegisterActivity(("Navigated to %s"):format(name))
end

function Nav:GetActiveTab()
	return self._active and self._active.Tab.Name or nil
end

function Nav:Destroy()
	for _, entry in self._byName do
		if entry.Tween then
			entry.Tween:Cancel()
		end
		if entry.CleanUp then
			pcall(entry.CleanUp)
		end
	end
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
	table.clear(self._byName)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. DASHBOARD PAGE — welcome header, account + session cards, quick access,
--    recent activity feed, version footer
-- ═══════════════════════════════════════════════════════════════════════════

local DashboardPage = {}

local function formatClock(totalSeconds)
	return ("%02d:%02d:%02d"):format(
		math.floor(totalSeconds / 3600),
		math.floor((totalSeconds % 3600) / 60),
		math.floor(totalSeconds % 60)
	)
end

local function sectionLabel(text, order)
	return Theme.instance("TextLabel", {
		Text = text,
		TextSize = 11,
		Font = Theme.Fonts.Bold,
		TextColor3 = Theme.Colors.TextSecondary,
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = order,
	})
end

local function infoRow(labelText, valueText, order)
	local row = Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = order,
	})
	Theme.text(labelText, 11, { Color = Theme.Colors.TextSecondary, Font = Theme.Fonts.Regular, Size = UDim2.fromOffset(104, 16) }).Parent = row
	local value = Theme.text(valueText, 11, { Size = UDim2.new(1, -104, 1, 0) })
	value.Parent = row
	return row, value
end

function DashboardPage.Build(page, context)
	local window = context.Window
	local player = Players.LocalPlayer

	local connections = {}
	local alive = true

	-- Scrollable page body (content exceeds the panel on small screens)
	local scroll = Theme.instance("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Colors.Primary,
		ScrollBarImageTransparency = 0.3,
	}, { Theme.padding(24, 20, 24, 20) })
	scroll.Parent = page

	local orderCounter = 0
	local function takeOrder()
		orderCounter += 1
		return orderCounter
	end

	Theme.list(Enum.FillDirection.Vertical, 12).Parent = scroll

	-- ── Header ──────────────────────────────────────────────────────────────
	local header = Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = takeOrder(),
	}, { Theme.list(Enum.FillDirection.Vertical, 4) })
	header.Parent = scroll

	Theme.instance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = Config.Brand.Greeting,
		TextSize = 24,
		Font = Theme.Fonts.Bold,
		TextColor3 = Theme.Colors.TextPrimary,
	}, { Theme.violetGradient(0) }).Parent = header

	Theme.text(("Hey, %s — your session is active."):format(player.DisplayName), 13,
		{ Color = Theme.Colors.TextSecondary, Font = Theme.Fonts.Regular, Size = UDim2.new(1, 0, 0, 18) }).Parent = header

	-- ── Account + Session cards ─────────────────────────────────────────────
	local cardRow = Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 158),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = takeOrder(),
	}, { Theme.list(Enum.FillDirection.Horizontal, 12) })
	cardRow.Parent = scroll

	local function halfCard(name)
		return Theme.instance("Frame", {
			Name = name,
			Size = UDim2.new(0.5, -6, 1, 0),
			BackgroundColor3 = Theme.Colors.Card,
			BorderSizePixel = 0,
		}, { Theme.corner(), Theme.stroke(Theme.Colors.Outline, 1, 0.45) })
	end

	-- Account card
	local accountCard = halfCard("AccountCard")
	accountCard.Parent = cardRow
	Theme.padding(14, 12, 14, 12).Parent = accountCard
	Theme.list(Enum.FillDirection.Vertical, 8).Parent = accountCard

	local identityRow = Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 1,
	}, { Theme.list(Enum.FillDirection.Horizontal, 10) })
	identityRow.Parent = accountCard

	local avatarWrap = Theme.instance("Frame", {
		Size = UDim2.fromOffset(46, 46),
		BackgroundColor3 = Theme.Colors.Outline,
		BorderSizePixel = 0,
	}, { Theme.corner(Theme.Radius.Pill), Theme.stroke(Theme.Colors.Primary, 1.2, 0.4) })
	avatarWrap.Parent = identityRow

	local avatar = Theme.instance("ImageLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = "",
		ScaleType = Enum.ScaleType.Crop,
		BorderSizePixel = 0,
	}, { Theme.corner(Theme.Radius.Pill) })
	avatar.Parent = avatarWrap

	local nameColumn = Theme.instance("Frame", {
		Size = UDim2.new(1, -56, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, { Theme.list(Enum.FillDirection.Vertical, 2, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center) })
	nameColumn.Parent = identityRow

	Theme.text(player.DisplayName, 14, { Font = Theme.Fonts.Bold, Size = UDim2.new(1, 0, 0, 18) }).Parent = nameColumn
	Theme.text("@" .. player.Name, 11, { Color = Theme.Colors.TextSecondary, Font = Theme.Fonts.Regular, Size = UDim2.new(1, 0, 0, 14) }).Parent = nameColumn

	Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Colors.Outline,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		LayoutOrder = 2,
	}).Parent = accountCard

	local accountInfo = Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 3,
	}, { Theme.list(Enum.FillDirection.Vertical, 5) })
	accountInfo.Parent = accountCard

	local joinDate = os.date("%b %d, %Y", os.time() - player.AccountAge * 86400)
	infoRow("User ID", tostring(player.UserId), 1).Parent = accountInfo
	infoRow("Account Age", ("%d days"):format(player.AccountAge), 2).Parent = accountInfo
	infoRow("Joined", joinDate, 3).Parent = accountInfo

	-- Session card
	local sessionCard = halfCard("SessionCard")
	sessionCard.Parent = cardRow
	Theme.padding(14, 12, 14, 12).Parent = sessionCard
	Theme.list(Enum.FillDirection.Vertical, 8).Parent = sessionCard

	sectionLabel("SESSION", 1).Parent = sessionCard

	local timerLabel = Theme.instance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = "00:00:00",
		TextSize = 24,
		Font = Theme.Fonts.Bold,
		TextColor3 = Theme.Colors.TextPrimary,
		LayoutOrder = 2,
	}, { Theme.violetGradient(0) })
	timerLabel.Parent = sessionCard

	local sessionInfo = Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 3,
	}, { Theme.list(Enum.FillDirection.Vertical, 5) })
	sessionInfo.Parent = sessionCard

	local fpsRow, fpsValue = infoRow("FPS", "—", 1)
	fpsRow.Parent = sessionInfo

	local statusRow = Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 2,
	})
	statusRow.Parent = sessionInfo
	Theme.text("Status", 11, { Color = Theme.Colors.TextSecondary, Font = Theme.Fonts.Regular, Size = UDim2.fromOffset(104, 16) }).Parent = statusRow
	Theme.instance("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 104, 0.5, 0),
		Size = UDim2.fromOffset(7, 7),
		BackgroundColor3 = Theme.Colors.Success,
		BorderSizePixel = 0,
	}, { Theme.corner(Theme.Radius.Pill) }).Parent = statusRow
	local statusValue = Theme.text("Online", 11, { Color = Theme.Colors.Success, Size = UDim2.new(1, -116, 0, 14) })
	statusValue.AnchorPoint = Vector2.new(0, 0.5)
	statusValue.Position = UDim2.new(0, 116, 0.5, 0)
	statusValue.Parent = statusRow

	-- ── Quick access ────────────────────────────────────────────────────────
	local quickCard = Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.Card,
		BorderSizePixel = 0,
		LayoutOrder = takeOrder(),
	}, {
		Theme.corner(),
		Theme.stroke(Theme.Colors.Outline, 1, 0.45),
		Theme.padding(14, 12, 14, 12),
		Theme.list(Enum.FillDirection.Vertical, 10),
	})
	quickCard.Parent = scroll

	sectionLabel("QUICK ACCESS", 1).Parent = quickCard

	local buttonRow = Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 2,
	}, { Theme.list(Enum.FillDirection.Horizontal, 8) })
	buttonRow.Parent = quickCard

	local function quickButton(text, onClick)
		local button = Theme.instance("TextButton", {
			Size = UDim2.new(0, 0, 1, 0), -- UIFlexItem.Fill provides the width
			BackgroundColor3 = Theme.Colors.Outline,
			BackgroundTransparency = 0.35,
			AutoButtonColor = false,
			Text = text,
			TextSize = 12,
			Font = Theme.Fonts.Medium,
			TextColor3 = Theme.Colors.TextPrimary,
			BorderSizePixel = 0,
		}, { Theme.corner(Theme.Radius.Control), Theme.instance("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }) })
		button.Parent = buttonRow
		button.MouseEnter:Connect(function()
			Theme.play(button, Config.Animation.Hover, { BackgroundTransparency = 0.1, BackgroundColor3 = Theme.Colors.CardHover })
		end)
		button.MouseLeave:Connect(function()
			Theme.play(button, Config.Animation.Hover, { BackgroundTransparency = 0.35, BackgroundColor3 = Theme.Colors.Outline })
		end)
		button.Activated:Connect(onClick)
	end

	quickButton("Hide Interface", function()
		window:Hide()
	end)
	quickButton("Minimize", function()
		window:Minimize()
	end)
	quickButton("Toggle Sidebar", function()
		window.OnToggleSidebar:Fire()
	end)

	-- ── Recent activity ─────────────────────────────────────────────────────
	local activityCard = Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.Card,
		BorderSizePixel = 0,
		LayoutOrder = takeOrder(),
	}, {
		Theme.corner(),
		Theme.stroke(Theme.Colors.Outline, 1, 0.45),
		Theme.padding(14, 12, 14, 12),
		Theme.list(Enum.FillDirection.Vertical, 10),
	})
	activityCard.Parent = scroll

	sectionLabel("RECENT ACTIVITY", 1).Parent = activityCard

	local activityList = Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 108),
		ClipsDescendants = true,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 2,
	}, { Theme.list(Enum.FillDirection.Vertical, 3) })
	activityList.Parent = activityCard

	local rows = {}
	local rowOrder = 0

	local function addActivityRow(timeText, message)
		rowOrder -= 1 -- decreasing LayoutOrder keeps the newest row on top
		local row = Theme.instance("TextLabel", {
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			RichText = true,
			Text = ("<font color=\"#9690AA\">%s</font>  %s"):format(timeText, message),
			TextSize = 11,
			Font = Theme.Fonts.Regular,
			TextColor3 = Theme.Colors.TextPrimary,
			LayoutOrder = rowOrder,
			TextTransparency = 1,
		})
		row.Parent = activityList
		table.insert(rows, row)
		Theme.play(row, Config.Animation.Fade, { TextTransparency = 0 })
		if #rows > 7 then
			table.remove(rows, 1):Destroy()
		end
	end

	table.insert(connections, window.Activity:Connect(function(timeText, message)
		addActivityRow(timeText, message)
	end))
	addActivityRow(os.date("%H:%M:%S"), "Session started")

	-- ── Footer ──────────────────────────────────────────────────────────────
	Theme.instance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		RichText = true,
		Text = ("<font color=\"#9690AA\">%s v%s  •  %s</font>"):format(
			Config.Brand.WindowTitle, Config.Brand.Version, Config.Brand.Footer),
		TextSize = 11,
		Font = Theme.Fonts.Regular,
		TextColor3 = Theme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = takeOrder(),
	}).Parent = scroll

	-- ── Avatar (async, with graceful failure) ───────────────────────────────
	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if alive and ok and typeof(content) == "string" then
			avatar.Image = content
		end
	end)

	-- ── Live session clock + FPS ────────────────────────────────────────────
	local sessionSeconds = 0
	local clockAccumulator = 0
	local fpsFrames = 0
	local fpsAccumulator = 0

	table.insert(connections, RunService.Heartbeat:Connect(function(deltaTime)
		sessionSeconds += deltaTime
		clockAccumulator += deltaTime
		fpsFrames += 1
		fpsAccumulator += deltaTime

		if clockAccumulator >= 1 then
			clockAccumulator -= 1
			timerLabel.Text = formatClock(sessionSeconds)
		end
		if fpsAccumulator >= 0.5 then
			fpsValue.Text = tostring(math.round(fpsFrames / fpsAccumulator))
			fpsFrames = 0
			fpsAccumulator = 0
		end
	end))

	return function()
		alive = false
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 6b. COMPONENTS — toggle / slider / dropdown / input / button / section /
--     paragraph. Not part of the original Phase 1 release; added so existing
--     Rayfield-style scripts can be adapted onto Losarinz (see section 8).
-- ═══════════════════════════════════════════════════════════════════════════

local Components = {}

local function newContainer(parent, order)
	local container = Theme.instance("Frame", {
		Name = "Control",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = order,
	}, { Theme.list(Enum.FillDirection.Vertical, 6) })
	container.Parent = parent
	return container
end

local function newRow(container, height)
	local r = Theme.instance("Frame", {
		Name = "Row",
		Size = UDim2.new(1, 0, 0, height or 44),
		BackgroundColor3 = Theme.Colors.Card,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
	}, { Theme.corner(Theme.Radius.Card), Theme.stroke(Theme.Colors.Outline, 1, 0.5), Theme.padding(14, 0, 14, 0) })
	r.Parent = container
	return r
end

function Components.Section(_parent, _order, proxy)
	local container = newContainer(_parent, _order)
	container.AutomaticSize = Enum.AutomaticSize.None
	container.Size = UDim2.new(1, 0, 0, 26)
	local label = Theme.text(string.upper(tostring(proxy.Name or "")), 11, {
		Font = Theme.Fonts.Bold,
		Color = Theme.Colors.Secondary,
	})
	label.Position = UDim2.new(0, 0, 1, -14)
	label.Size = UDim2.new(1, 0, 0, 14)
	label.Parent = container
	return container, nil
end

function Components.Toggle(parent, order, proxy)
	local container = newContainer(parent, order)
	local r = newRow(container, 44)

	Theme.text(proxy.Name, 13, { Size = UDim2.new(1, -60, 1, 0) }).Parent = r

	local track = Theme.instance("TextButton", {
		Name = "Switch",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(40, 22),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = if proxy.CurrentValue then Theme.Colors.Primary else Theme.Colors.Outline,
		BorderSizePixel = 0,
	}, { Theme.corner(Theme.Radius.Pill) })
	track.Parent = r

	local knob = Theme.instance("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, if proxy.CurrentValue then 20 else 2, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = Theme.Colors.TextPrimary,
		BorderSizePixel = 0,
	}, { Theme.corner(Theme.Radius.Pill) })
	knob.Parent = track

	local function paint(value)
		Theme.play(track, Config.Animation.Hover, { BackgroundColor3 = if value then Theme.Colors.Primary else Theme.Colors.Outline })
		Theme.play(knob, Config.Animation.Hover, { Position = UDim2.new(0, if value then 20 else 2, 0.5, 0) })
	end

	track.Activated:Connect(function()
		proxy:_fire(not proxy.CurrentValue)
	end)

	proxy._visual = paint
	return container, nil
end

function Components.Slider(parent, order, proxy)
	local container = newContainer(parent, order)
	local r = newRow(container, 54)

	local min, max = proxy.Range[1], proxy.Range[2]
	local increment = proxy.Increment or 1

	local label = Theme.text(proxy.Name, 13, { Size = UDim2.new(1, -70, 0, 20) })
	label.Position = UDim2.new(0, 0, 0, 2)
	label.Parent = r

	local valueLabel = Theme.text("", 12, {
		Color = Theme.Colors.Secondary,
		Font = Theme.Fonts.Bold,
		Align = Enum.TextXAlignment.Right,
		Size = UDim2.fromOffset(60, 20),
	})
	valueLabel.AnchorPoint = Vector2.new(1, 0)
	valueLabel.Position = UDim2.new(1, 0, 0, 2)
	valueLabel.Parent = r

	local track = Theme.instance("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -8),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = Theme.Colors.Outline,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
	}, { Theme.corner(Theme.Radius.Pill) })
	track.Parent = r

	local fill = Theme.instance("Frame", {
		Name = "Fill",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.Colors.Primary,
		BorderSizePixel = 0,
	}, { Theme.corner(Theme.Radius.Pill) })
	fill.Parent = track

	local knob = Theme.instance("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Theme.Colors.TextPrimary,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, { Theme.corner(Theme.Radius.Pill), Theme.stroke(Theme.Colors.Primary, 2) })
	knob.Parent = track

	local function alphaFor(value)
		if max <= min then
			return 0
		end
		return math.clamp((value - min) / (max - min), 0, 1)
	end

	local function paint(value)
		local alpha = alphaFor(value)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		local decimals = if increment % 1 == 0 then 0 else 2
		valueLabel.Text = ("%." .. decimals .. "f%s"):format(value, proxy.Suffix or "")
	end

	local dragging = false
	local function setFromX(x)
		local absPos = track.AbsolutePosition.X
		local absSize = math.max(track.AbsoluteSize.X, 1)
		local alpha = math.clamp((x - absPos) / absSize, 0, 1)
		local raw = min + (max - min) * alpha
		local stepped = math.floor((raw - min) / increment + 0.5) * increment + min
		stepped = math.clamp(stepped, min, max)
		paint(stepped)
		proxy:_fire(stepped)
	end

	local connections = {}
	table.insert(connections, track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end))
	table.insert(connections, track.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	proxy._visual = paint
	paint(proxy.CurrentValue or min)

	return container, function()
		for _, c in connections do
			c:Disconnect()
		end
	end
end

function Components.Dropdown(parent, order, proxy)
	local container = newContainer(parent, order)
	local r = newRow(container, 44)

	Theme.text(proxy.Name, 13, { Size = UDim2.new(1, -90, 1, 0) }).Parent = r

	local summary = Theme.text("", 12, {
		Color = Theme.Colors.Secondary,
		Align = Enum.TextXAlignment.Right,
		Size = UDim2.new(0, 110, 1, 0),
	})
	summary.AnchorPoint = Vector2.new(1, 0)
	summary.Position = UDim2.new(1, -26, 0, 0)
	summary.Parent = r

	local caret = Theme.text("v", 12, {
		Color = Theme.Colors.TextSecondary,
		Align = Enum.TextXAlignment.Right,
		Size = UDim2.fromOffset(16, 44),
	})
	caret.AnchorPoint = Vector2.new(1, 0)
	caret.Position = UDim2.new(1, 0, 0, 0)
	caret.Parent = r

	local hitButton = Theme.instance("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 2,
	})
	hitButton.Parent = r

	local list = Theme.instance("Frame", {
		Name = "Options",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.MainPanel,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Visible = false,
		ClipsDescendants = true,
	}, {
		Theme.corner(Theme.Radius.Card),
		Theme.stroke(Theme.Colors.Outline, 1, 0.5),
		Theme.padding(8, 8, 8, 8),
		Theme.list(Enum.FillDirection.Vertical, 4),
	})
	list.Parent = container

	local optionEntries = {}
	local open = false

	local function isSelected(name)
		for _, v in proxy.CurrentOption do
			if v == name then
				return true
			end
		end
		return false
	end

	local function summarize()
		local sel = proxy.CurrentOption
		if #sel == 0 then
			summary.Text = "None"
		elseif #sel == 1 then
			summary.Text = tostring(sel[1])
		else
			summary.Text = ("%d selected"):format(#sel)
		end
	end

	local function paintOption(entry)
		local sel = isSelected(entry.Name)
		entry.Button.BackgroundColor3 = if sel then Theme.Colors.Primary else Theme.Colors.Card
		entry.Button.BackgroundTransparency = if sel then 0.1 else 0.3
		entry.Button.TextColor3 = if sel then Theme.Colors.TextPrimary else Theme.Colors.TextSecondary
	end

	local function refreshVisual()
		summarize()
		for _, entry in optionEntries do
			paintOption(entry)
		end
	end

	local function selectOption(name)
		local current = proxy.CurrentOption
		if proxy.MultipleOptions then
			local idx
			for i, v in current do
				if v == name then
					idx = i
					break
				end
			end
			if idx then
				table.remove(current, idx)
			else
				table.insert(current, name)
			end
		else
			current = { name }
			open = false
			list.Visible = false
			caret.Text = "v"
		end
		proxy:_fire(current)
		refreshVisual()
	end

	local function rebuildOptions(options)
		for _, entry in optionEntries do
			entry.Button:Destroy()
		end
		table.clear(optionEntries)
		for i, name in options do
			local btn = Theme.instance("TextButton", {
				Name = "Option",
				Size = UDim2.new(1, 0, 0, 28),
				AutoButtonColor = false,
				Text = "  " .. tostring(name),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextSize = 12,
				Font = Theme.Fonts.Medium,
				BorderSizePixel = 0,
				LayoutOrder = i,
			}, { Theme.corner(Theme.Radius.Control) })
			btn.Parent = list
			local entry = { Button = btn, Name = name }
			btn.Activated:Connect(function()
				selectOption(name)
			end)
			table.insert(optionEntries, entry)
		end
	end

	hitButton.Activated:Connect(function()
		open = not open
		list.Visible = open
		caret.Text = if open then "^" else "v"
	end)

	rebuildOptions(proxy.Options)
	refreshVisual()

	proxy._visual = function(_value)
		refreshVisual()
	end
	proxy._refresh = function(options)
		rebuildOptions(options)
		refreshVisual()
	end

	return container, nil
end

function Components.Input(parent, order, proxy)
	local container = newContainer(parent, order)
	local r = newRow(container, 44)

	Theme.text(proxy.Name, 13, { Size = UDim2.new(0.42, -8, 1, 0) }).Parent = r

	local box = Theme.instance("TextBox", {
		Name = "Input",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0.55, 0, 0, 30),
		BackgroundColor3 = Theme.Colors.MainPanel,
		BorderSizePixel = 0,
		Text = tostring(proxy.CurrentValue or ""),
		PlaceholderText = proxy.PlaceholderText or "",
		PlaceholderColor3 = Theme.Colors.TextSecondary,
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		Font = Theme.Fonts.Regular,
		ClearTextOnFocus = false,
	}, { Theme.corner(Theme.Radius.Control), Theme.stroke(Theme.Colors.Outline, 1, 0.4), Theme.padding(10, 0, 10, 0) })
	box.Parent = r

	box.FocusLost:Connect(function()
		proxy:_fire(box.Text)
		if proxy.RemoveTextAfterFocusLost then
			box.Text = ""
		end
	end)

	proxy._visual = function(value)
		box.Text = tostring(value or "")
	end

	return container, nil
end

function Components.Button(parent, order, proxy)
	local container = newContainer(parent, order)
	container.AutomaticSize = Enum.AutomaticSize.None
	container.Size = UDim2.new(1, 0, 0, 40)

	local btn = Theme.instance("TextButton", {
		Name = "Button",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.Colors.Primary,
		BackgroundTransparency = 0.12,
		AutoButtonColor = false,
		Text = proxy.Name,
		TextColor3 = Theme.Colors.TextPrimary,
		TextSize = 13,
		Font = Theme.Fonts.Bold,
		BorderSizePixel = 0,
	}, { Theme.corner(Theme.Radius.Card), Theme.stroke(Theme.Colors.Primary, 1, 0.3) })
	btn.Parent = container

	btn.MouseEnter:Connect(function()
		Theme.play(btn, Config.Animation.Hover, { BackgroundTransparency = 0 })
	end)
	btn.MouseLeave:Connect(function()
		Theme.play(btn, Config.Animation.Hover, { BackgroundTransparency = 0.12 })
	end)
	btn.Activated:Connect(function()
		local ok, err = pcall(proxy.Callback)
		if not ok then
			warn(("[Losarinz] Button '%s' callback error: %s"):format(tostring(proxy.Name), tostring(err)))
		end
	end)

	proxy._visual = function(text)
		if typeof(text) == "string" then
			btn.Text = text
		end
	end

	return container, nil
end

function Components.Paragraph(parent, order, proxy)
	local container = newContainer(parent, order)

	local box = Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.Card,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
	}, {
		Theme.corner(Theme.Radius.Card),
		Theme.stroke(Theme.Colors.Outline, 1, 0.5),
		Theme.padding(14, 10, 14, 10),
		Theme.list(Enum.FillDirection.Vertical, 4),
	})
	box.Parent = container

	local title = Theme.instance("TextLabel", {
		Text = tostring(proxy.Title or ""),
		TextSize = 14,
		Font = Theme.Fonts.Bold,
		TextColor3 = Theme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
	})
	title.Parent = box

	local content = Theme.instance("TextLabel", {
		Text = tostring(proxy.Content or ""),
		TextSize = 12,
		Font = Theme.Fonts.Regular,
		TextColor3 = Theme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
	})
	content.Parent = box

	proxy._visual = function(value)
		if typeof(value) == "table" then
			if value.Title ~= nil then
				title.Text = tostring(value.Title)
			end
			if value.Content ~= nil then
				content.Text = tostring(value.Content)
			end
		end
	end

	return container, nil
end

local Builders = {
	Toggle = Components.Toggle,
	Slider = Components.Slider,
	Dropdown = Components.Dropdown,
	Input = Components.Input,
	Button = Components.Button,
	Section = Components.Section,
	Paragraph = Components.Paragraph,
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 7. CONTROL PROXY — the value/flag object every component above wires into.
--    Lives before section 8 because the compat layer below constructs these.
-- ═══════════════════════════════════════════════════════════════════════════

local ControlProxy = {}
ControlProxy.__index = ControlProxy

local function newControlProxy(ctype, cfg)
	cfg = cfg or {}
	local self = setmetatable({}, ControlProxy)
	self.Type = ctype
	self.Name = cfg.Name
	self.Flag = cfg.Flag
	self.Callback = cfg.Callback or function() end
	self._visual = nil
	self._refresh = nil
	self._onChanged = nil

	if ctype == "Dropdown" then
		self.Options = cfg.Options or {}
		self.CurrentOption = cfg.CurrentOption or {}
		self.MultipleOptions = cfg.MultipleOptions and true or false
	elseif ctype == "Slider" then
		self.CurrentValue = cfg.CurrentValue or 0
		self.Range = cfg.Range or { 0, 100 }
		self.Increment = cfg.Increment or 1
		self.Suffix = cfg.Suffix or ""
	elseif ctype == "Input" then
		self.CurrentValue = cfg.CurrentValue or ""
		self.PlaceholderText = cfg.PlaceholderText or ""
		self.RemoveTextAfterFocusLost = cfg.RemoveTextAfterFocusLost
	elseif ctype == "Toggle" then
		self.CurrentValue = cfg.CurrentValue and true or false
	elseif ctype == "Paragraph" then
		self.Title = cfg.Title
		self.Content = cfg.Content
	end
	-- Section / Button only need Name (+ Callback for Button)

	return self
end

function ControlProxy:_fire(value)
	if self.Type == "Dropdown" then
		self.CurrentOption = value
	else
		self.CurrentValue = value
	end
	local ok, err = pcall(self.Callback, value)
	if not ok then
		warn(("[Losarinz] '%s' callback error: %s"):format(tostring(self.Name), tostring(err)))
	end
	if self._onChanged then
		self._onChanged()
	end
end

function ControlProxy:Set(value, silent)
	if self.Type == "Dropdown" then
		self.CurrentOption = value
	elseif self.Type == "Paragraph" then
		if typeof(value) == "table" then
			if value.Title ~= nil then
				self.Title = value.Title
			end
			if value.Content ~= nil then
				self.Content = value.Content
			end
		end
	elseif self.Type == "Button" then
		if typeof(value) == "string" then
			self.Name = value
		end
	else
		self.CurrentValue = value
	end

	if self._visual then
		self._visual(value)
	end

	if not silent and self.Type ~= "Paragraph" and self.Type ~= "Section" then
		local target = if self.Type == "Dropdown" then self.CurrentOption else self.CurrentValue
		local ok, err = pcall(self.Callback, target)
		if not ok then
			warn(("[Losarinz] '%s' callback error: %s"):format(tostring(self.Name), tostring(err)))
		end
		if self._onChanged then
			self._onChanged()
		end
	end
end

function ControlProxy:Refresh(options)
	self.Options = options or {}
	if self._refresh then
		self._refresh(self.Options)
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 8. RAYFIELD-COMPATIBLE SHIM — lets an existing `rayfield:CreateWindow(...)`
--    script run unmodified on top of Losarinz. Only the loader line needs to
--    change (require this instead of loadstring-ing Rayfield); every
--    CreateTab/CreateToggle/CreateSlider/.../Notify/LoadConfiguration call
--    the script already makes keeps working as-is.
--
--    Why this has to buffer things: Losarinz builds each tab's page lazily,
--    the first time it is selected, and it needs the *full* tab list up
--    front (NavigationController.new(window, tabs)). A Rayfield-style
--    script, though, creates tabs and controls one at a time, interleaved,
--    and only calls rayfield:LoadConfiguration() once at the very end. So
--    this shim just records everything the script declares (tabs, controls,
--    their initial values) into plain queues, and only actually builds the
--    real Losarinz window at that final LoadConfiguration() call — at which
--    point the whole tab/control list is known. Every CreateX call returns
--    a live ControlProxy immediately (so `local x = tab:CreateToggle(...)`
--    and `rayfield.Flags.X:Set(...)` both work right away); the proxy just
--    has nothing to paint on screen until the real control is built.
-- ═══════════════════════════════════════════════════════════════════════════

local TabProxy = {}
TabProxy.__index = TabProxy

local function newTabProxy(name, icon)
	return setmetatable({ Name = name, Icon = icon, Queue = {} }, TabProxy)
end

local function queueControl(tab, ctype, cfg)
	local proxy = newControlProxy(ctype, cfg)
	table.insert(tab.Queue, proxy)
	return proxy
end

function TabProxy:CreateToggle(cfg)
	return queueControl(self, "Toggle", cfg)
end
function TabProxy:CreateSlider(cfg)
	return queueControl(self, "Slider", cfg)
end
function TabProxy:CreateDropdown(cfg)
	return queueControl(self, "Dropdown", cfg)
end
function TabProxy:CreateInput(cfg)
	return queueControl(self, "Input", cfg)
end
function TabProxy:CreateButton(cfg)
	return queueControl(self, "Button", cfg)
end
function TabProxy:CreateParagraph(cfg)
	return queueControl(self, "Paragraph", cfg)
end
function TabProxy:CreateSection(name)
	return queueControl(self, "Section", { Name = name })
end

local Compat = {}
Compat.__index = Compat

local function newCompat()
	return setmetatable({
		Flags = {},
		_tabs = {},
		_options = {},
		_built = false,
		_autosave = false,
		_window = nil,
		_nav = nil,
		_toastLayer = nil,
	}, Compat)
end

-- Rayfield scripts do `local window = rayfield:CreateWindow(opts)` and then
-- call CreateTab on `window`, but Notify/LoadConfiguration on `rayfield`
-- itself — returning `self` here means window and rayfield are the same
-- object, so every one of those calls lands on the same table.
function Compat:CreateWindow(opts)
	self._options = opts or {}
	if typeof(self._options.ConfigurationSaving) == "table" then
		self._configSaving = self._options.ConfigurationSaving
	end
	return self
end

function Compat:CreateTab(name, icon)
	local tab = newTabProxy(name, icon)
	table.insert(self._tabs, tab)
	return tab
end

function Compat:_configFile()
	local saving = self._configSaving
	if not (saving and saving.Enabled) then
		return nil, nil
	end
	local folder = saving.FolderName or "LosarinzTrainer"
	local file = saving.FileName or "settings"
	return folder, (folder .. "/" .. file .. ".json")
end

function Compat:_save()
	local folder, path = self:_configFile()
	if not path or typeof(writefile) ~= "function" then
		return
	end
	local data = {}
	for flagName, proxy in self.Flags do
		if proxy.Type == "Dropdown" then
			data[flagName] = proxy.CurrentOption
		elseif proxy.Type ~= "Section" and proxy.Type ~= "Paragraph" and proxy.Type ~= "Button" then
			data[flagName] = proxy.CurrentValue
		end
	end
	pcall(function()
		if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(folder) then
			makefolder(folder)
		end
		writefile(path, game:GetService("HttpService"):JSONEncode(data))
	end)
end

function Compat:_ensureToastLayer()
	if self._toastLayer then
		return self._toastLayer
	end
	local layer = Theme.instance("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.fromOffset(300, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, { Theme.list(Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom) })
	layer.Parent = self._window._gui
	self._toastLayer = layer
	return layer
end

function Compat:Notify(opts)
	opts = opts or {}
	if not self._built then
		warn("[Losarinz] Notify called before the window was built: " .. tostring(opts.Title))
		return
	end
	local layer = self:_ensureToastLayer()
	local card = Theme.instance("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.Card,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		Theme.corner(Theme.Radius.Card),
		Theme.stroke(Theme.Colors.Primary, 1, 1),
		Theme.padding(14, 10, 14, 10),
		Theme.list(Enum.FillDirection.Vertical, 2),
	})
	card.Parent = layer

	Theme.instance("TextLabel", {
		Text = tostring(opts.Title or "Notice"),
		TextSize = 13,
		Font = Theme.Fonts.Bold,
		TextColor3 = Theme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
	}).Parent = card

	if opts.Content and opts.Content ~= "" then
		Theme.instance("TextLabel", {
			Text = tostring(opts.Content),
			TextSize = 12,
			Font = Theme.Fonts.Regular,
			TextColor3 = Theme.Colors.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
		}).Parent = card
	end

	Theme.play(card, Config.Animation.Fade, { BackgroundTransparency = 0.1 })
	for _, child in card:GetChildren() do
		if child:IsA("UIStroke") then
			Theme.play(child, Config.Animation.Fade, { Transparency = 0.3 })
		end
	end

	task.delay(math.max(opts.Duration or 5, 1), function()
		if card and card.Parent then
			Theme.play(card, Config.Animation.Fade, { BackgroundTransparency = 1 })
			for _, child in card:GetChildren() do
				if child:IsA("UIStroke") then
					Theme.play(child, Config.Animation.Fade, { Transparency = 1 })
				end
			end
			task.wait(0.25)
			card:Destroy()
		end
	end)
end

function Compat:_build()
	if self._built then
		return
	end
	self._built = true

	local tabConfigs = {}
	for _, tab in self._tabs do
		table.insert(tabConfigs, {
			Name = tab.Name,
			Icon = tab.Icon,
			Page = {
				Build = function(page, _context)
					local scroller = Theme.instance("ScrollingFrame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ScrollBarThickness = 4,
						ScrollBarImageColor3 = Theme.Colors.Primary,
						CanvasSize = UDim2.new(0, 0, 0, 0),
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
					}, { Theme.padding(18, 16, 18, 16), Theme.list(Enum.FillDirection.Vertical, 10) })
					scroller.Parent = page

					local cleanups = {}
					for i, proxy in tab.Queue do
						local builder = Builders[proxy.Type]
						if builder then
							local _container, cleanup = builder(scroller, i, proxy)
							if cleanup then
								table.insert(cleanups, cleanup)
							end
							if proxy.Flag then
								self.Flags[proxy.Flag] = proxy
							end
							proxy._onChanged = function()
								if self._autosave then
									self:_save()
								end
							end
						end
					end

					return function()
						for _, c in cleanups do
							pcall(c)
						end
					end
				end,
			},
		})
	end

	self._window = WindowController.new({ Size = Config.Window.DefaultSize })
	self._nav = NavigationController.new(self._window, tabConfigs)
	self._window:Show()

	-- Force every tab to build right away: automation toggles on tabs the
	-- person never opens still need to exist and hold their Flag values.
	for _, tab in tabConfigs do
		self._nav:SelectTab(tab.Name)
	end
	if tabConfigs[1] then
		self._nav:SelectTab(tabConfigs[1].Name)
	end

	self._window:RegisterActivity("Loaded " .. tostring(self._options.Name or Config.Brand.WindowTitle))
end

function Compat:LoadConfiguration()
	self:_build()

	local _, path = self:_configFile()
	local saved
	if path and typeof(isfile) == "function" and typeof(readfile) == "function" and isfile(path) then
		local ok, result = pcall(function()
			return game:GetService("HttpService"):JSONDecode(readfile(path))
		end)
		if ok then
			saved = result
		end
	end

	if saved then
		for flagName, proxy in self.Flags do
			local value = saved[flagName]
			if value ~= nil then
				proxy:Set(value, false)
			end
		end
	end

	-- Only autosave from here on — the restore above already wrote every
	-- flag's starting value, no need to re-save the file for that.
	self._autosave = true
end

function Compat:SaveConfiguration()
	self:_save()
end

function Compat:Destroy()
	if self._nav then
		self._nav:Destroy()
	end
	if self._window then
		self._window:Destroy()
	end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 9. PUBLIC API — the Losarinz namespace
-- ═══════════════════════════════════════════════════════════════════════════

local Losarinz = {}

Losarinz.Version = Config.Brand.Version
Losarinz.Config = Config
Losarinz.Theme = Theme

--[[
	Losarinz.CreateWindow(options) -> handle
	options: { Size = Vector2?, Tabs = { { Name, Icon, Page, Phase } }? }

	handle: {
		Window            — :Show() :Hide() :Minimize() :Restore() :ToggleMinimize()
		                    :RegisterActivity(msg) :Destroy()
		Navigation        — :SelectTab(name) :SetCollapsed(bool) :ToggleCollapsed()
		                    :GetActiveTab() :Destroy()
		RegisterActivity  — fn(message)
		Config / Theme    — framework tables for extending in future phases
	}
]]
function Losarinz.CreateWindow(options)
	options = options or {}

	local window = WindowController.new({
		Size = options.Size or Config.Window.DefaultSize,
	})

	local tabs = options.Tabs or {
		{ Name = "Dashboard",     Icon = "🏠", Page = DashboardPage, Phase = 1 },
		{ Name = "Main Features", Icon = "🧩", Phase = 3 },
		{ Name = "Player",        Icon = "👤", Phase = 3 },
		{ Name = "Visuals",       Icon = "🎨", Phase = 4 },
		{ Name = "Settings",      Icon = "⚙️", Phase = 4 },
	}

	local nav = NavigationController.new(window, tabs)

	window:Show()
	nav:SelectTab("Dashboard")
	window:RegisterActivity("Welcome to Losarinz — interface ready")

	return {
		Window = window,
		Navigation = nav,
		RegisterActivity = function(message)
			window:RegisterActivity(message)
		end,
		Config = Config,
		Theme = Theme,
	}
end

--[[
	Losarinz.CreateRayfieldCompat() -> rayfield-shaped table

	Drop-in replacement for `loadstring(game:HttpGet(RAYFIELD_URL))()`. The
	object it returns supports :CreateWindow(opts) / :CreateTab(name, icon) /
	:CreateToggle / :CreateSlider / :CreateDropdown / :CreateInput /
	:CreateButton / :CreateSection / :CreateParagraph / :Notify(opts) /
	:LoadConfiguration() / :SaveConfiguration() / :Destroy(), and a .Flags
	table keyed by each control's Flag — the same shape an existing
	Rayfield script already expects, so only its loader line changes:

		local rayfield = Losarinz.CreateRayfieldCompat()
		local window = rayfield:CreateWindow({ ConfigurationSaving = {...} })
		-- every CreateTab / CreateToggle / ... / Notify / LoadConfiguration
		-- call below this line is unchanged from the Rayfield version.
]]
function Losarinz.CreateRayfieldCompat()
	return newCompat()
end

return Losarinz
