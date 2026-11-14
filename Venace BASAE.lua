--==============================================================
--   VENACE HUB  •  Pickaxe Edition  (UNIVERSAL)
--   Toggle UI : LEFT ALT (rebindable in Settings)
--   Works in every game: uses Tool:Activate() + common
--   swing remote names. No game-specific dependencies.
--==============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

--==============================================================
-- CONFIG
--==============================================================
local DEFAULTS = {
    FastSwing      = false,
    SwingDelay     = 0.03,              -- seconds between swings
    Keybind        = Enum.KeyCode.LeftAlt,
    UITransparency = 0,                 -- 0 = solid
}
local Config = table.clone(DEFAULTS)

local Theme = {
    BG      = Color3.fromRGB(14, 14, 19),
    Panel   = Color3.fromRGB(22, 22, 30),
    Panel2  = Color3.fromRGB(32, 32, 44),
    Stroke  = Color3.fromRGB(48, 48, 66),
    Accent  = Color3.fromRGB(139, 92, 246),
    Accent2 = Color3.fromRGB(56, 189, 248),
    Text    = Color3.fromRGB(236, 236, 245),
    Sub     = Color3.fromRGB(148, 148, 168),
    Good    = Color3.fromRGB(74, 222, 128),
}

--==============================================================
-- UNIVERSAL SWING ENGINE
-- Tries every common way to swing a tool so the script works
-- across unrelated games without any game-specific setup.
--==============================================================
local CommonSwingRemotes = {
    -- original (Mastery / pickaxe games)
    "MasteryPickaxeSwing",
    "PickaxeSwing",
    "SwingPickaxe",
    "PickaxeActivate",
    "ActivatePickaxe",
    "UsePickaxe",
    "MinePickaxe",
    -- generic
    "Swing",
    "Mine",
    "Mining",
    "Hit",
    "UseTool",
    "ToolActivate",
}

local cachedRemotes = {}
local function refreshRemoteCache()
    cachedRemotes = {}
    for _, name in ipairs(CommonSwingRemotes) do
        local found = ReplicatedStorage:FindFirstChild(name, true)
        if found and found:IsA("RemoteEvent") then
            table.insert(cachedRemotes, found)
        end
    end
end
refreshRemoteCache()

local function getEquippedTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

local function swingOnce()
    local tool = getEquippedTool()
    if tool then
        -- Primary universal path: native tool activation
        -- (fires Tool.Activated, which all standard tools listen to)
        pcall(function() tool:Activate() end)

        -- If the tool has its own swing remote, fire it too
        for _, d in ipairs(tool:GetDescendants()) do
            if d:IsA("RemoteEvent") then
                pcall(function() d:FireServer() end)
            end
        end
    end

    -- Known common swing remotes found anywhere in ReplicatedStorage
    for _, remote in ipairs(cachedRemotes) do
        if remote and remote.Parent then
            pcall(function() remote:FireServer() end)
        end
    end
end

--==============================================================
-- HELPERS
--==============================================================
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

--==============================================================
-- ROOT
--==============================================================
local old = PlayerGui:FindFirstChild("VenaceHub")
if old then old:Destroy() end

local gui = new("ScreenGui", {
    Name = "VenaceHub",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
}, PlayerGui)

local main = new("CanvasGroup", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(560, 360),
    BackgroundColor3 = Theme.BG,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    GroupTransparency = Config.UITransparency,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 12) }, main)
new("UIStroke", { Color = Theme.Stroke, Thickness = 1 }, main)

--==============================================================
-- TITLE BAR
--==============================================================
local titleBar = new("Frame", {
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
}, main)
new("UIGradient", {
    Color = ColorSequence.new(Theme.Panel2, Theme.Panel),
    Rotation = 90,
}, titleBar)

local title = new("TextLabel", {
    Position = UDim2.new(0, 16, 0, 0),
    Size = UDim2.new(1, -120, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "VENACE HUB",
    TextSize = 16,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)
new("UIGradient", {
    Color = ColorSequence.new(Theme.Accent, Theme.Accent2),
}, title)

new("TextLabel", {
    Position = UDim2.new(0, 16, 0, 26),
    Size = UDim2.new(1, -120, 0, 12),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "pickaxe edition  •  universal",
    TextSize = 10,
    TextColor3 = Theme.Sub,
    TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)

new("Frame", {
    Position = UDim2.new(0, 0, 1, -1),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = Theme.Accent,
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
}, titleBar)

local closeBtn = new("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -14, 0.5, 0),
    Size = UDim2.fromOffset(24, 24),
    BackgroundColor3 = Theme.Panel2,
    AutoButtonColor = false,
    Text = "×",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Theme.Sub,
    BorderSizePixel = 0,
}, titleBar)
new("UICorner", { CornerRadius = UDim.new(0, 6) }, closeBtn)

--==============================================================
-- SIDEBAR
--==============================================================
local sidebar = new("Frame", {
    Position = UDim2.new(0, 0, 0, 46),
    Size = UDim2.fromOffset(150, 314),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel = 0,
}, main)
new("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, sidebar)
new("UIPadding", { PaddingTop = UDim.new(0, 10) }, sidebar)

--==============================================================
-- CONTENT
--==============================================================
local content = new("Frame", {
    Position = UDim2.new(0, 158, 0, 46),
    Size = UDim2.new(1, -158, 1, -46),
    BackgroundTransparency = 1,
}, main)

local function createPage(order)
    local page = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        LayoutOrder = order,
    }, content)
    new("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, page)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
    }, page)
    return page
end

local mainPage    = createPage(1)
local settingsPage = createPage(2)
local pages = { mainPage, settingsPage }

--==============================================================
-- WIDGETS
--==============================================================
local function createToggle(parent, text, default, order, onChanged)
    local state = default
    local row = new("TextButton", {
        Size = UDim2.new(1, -24, 0, 44),
        BackgroundColor3 = Theme.Panel,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        LayoutOrder = order,
    }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, row)
    new("UIStroke", { Color = Theme.Stroke, Thickness = 1 }, row)

    new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local pill = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(42, 22),
        BackgroundColor3 = Theme.Panel2,
        BorderSizePixel = 0,
    }, row)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Theme.Sub,
        BorderSizePixel = 0,
    }, pill)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local function render()
        TweenService:Create(pill, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Theme.Accent or Theme.Panel2,
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
            BackgroundColor3 = state and Color3.new(1, 1, 1) or Theme.Sub,
        }):Play()
    end

    local function set(v, fire)
        state = v
        render()
        if fire and onChanged then onChanged(state) end
    end

    row.MouseButton1Click:Connect(function() set(not state, true) end)
    set(default, false)

    return { Set = function(v) set(v, false) end, Get = function() return state end }
end

local function createSlider(parent, labelText, minV, maxV, defaultV, order, fmt, onChanged)
    local holder = new("Frame", {
        Size = UDim2.new(1, -24, 0, 58),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        LayoutOrder = order,
    }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, holder)
    new("UIStroke", { Color = Theme.Stroke, Thickness = 1 }, holder)

    new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 8),
        Size = UDim2.new(1, -100, 0, 16),
        Font = Enum.Font.GothamMedium,
        Text = labelText,
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)

    local valueLabel = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -14, 0, 8),
        Size = UDim2.new(0, 80, 0, 16),
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 12,
        TextColor3 = Theme.Accent2,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, holder)

    local bar = new("Frame", {
        Position = UDim2.new(0, 14, 0, 30),
        Size = UDim2.new(1, -28, 0, 18),
        BackgroundTransparency = 1,
    }, holder)

    local track = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 6),
        BackgroundColor3 = Theme.Panel2,
        BorderSizePixel = 0,
    }, bar)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, track)

    local fill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, track)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, track)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local value = defaultV

    local function render()
        local a = (value - minV) / (maxV - minV)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        valueLabel.Text = fmt(value)
    end

    local dragging = false
    local function updateFromX(x)
        local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        value = minV + (maxV - minV) * a
        render()
        if onChanged then onChanged(value) end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    render()
    return {
        Get = function() return value end,
        Set = function(v) value = v; render() end,
    }
end

--==============================================================
-- MAIN PAGE
--==============================================================
new("TextLabel", {
    Size = UDim2.new(1, -24, 0, 20),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "Pickaxe Mastery",
    TextSize = 15,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 0,
}, mainPage)

new("TextLabel", {
    Size = UDim2.new(1, -24, 0, 16),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Universal tool swing. Auto-detects swing remotes.",
    TextSize = 11,
    TextColor3 = Theme.Sub,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 1,
}, mainPage)

local statusLabel = new("TextLabel", {
    Size = UDim2.new(1, -24, 0, 16),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Status: idle",
    TextSize = 11,
    TextColor3 = Theme.Sub,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 3,
}, mainPage)

local function updateStatus()
    if Config.FastSwing then
        statusLabel.Text = string.format("Status: swinging every %d ms", math.floor(Config.SwingDelay * 1000 + 0.5))
        statusLabel.TextColor3 = Theme.Good
    else
        statusLabel.Text = "Status: idle"
        statusLabel.TextColor3 = Theme.Sub
    end
end

local swingToggle = createToggle(mainPage, "Fast Pickaxe Swing", Config.FastSwing, 2, function(v)
    Config.FastSwing = v
    if v then refreshRemoteCache() end
    updateStatus()
end)

local delaySlider = createSlider(mainPage, "Swing Delay", 0.01, 0.30, Config.SwingDelay, 4,
    function(v) return string.format("%d ms", math.floor(v * 1000 + 0.5)) end,
    function(v)
        Config.SwingDelay = v
        updateStatus()
    end
)

--==============================================================
-- SETTINGS PAGE
--==============================================================
new("TextLabel", {
    Size = UDim2.new(1, -24, 0, 20),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "Settings",
    TextSize = 15,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 0,
}, settingsPage)

local rebinding = false
local keyLabel

local function setKeybind(key)
    Config.Keybind = key
    if keyLabel then
        keyLabel.Text = key.Name
        keyLabel.TextColor3 = Theme.Accent2
    end
end

local keyRow = new("TextButton", {
    Size = UDim2.new(1, -24, 0, 44),
    BackgroundColor3 = Theme.Panel,
    AutoButtonColor = false,
    Text = "",
    BorderSizePixel = 0,
    LayoutOrder = 1,
}, settingsPage)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, keyRow)
new("UIStroke", { Color = Theme.Stroke, Thickness = 1 }, keyRow)

new("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 14, 0, 0),
    Size = UDim2.new(1, -120, 1, 0),
    Font = Enum.Font.GothamMedium,
    Text = "Toggle Keybind",
    TextSize = 13,
    TextColor3 = Theme.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, keyRow)

keyLabel = new("TextLabel", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -14, 0.5, 0),
    Size = UDim2.new(0, 90, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = Config.Keybind.Name,
    TextSize = 12,
    TextColor3 = Theme.Accent2,
    TextXAlignment = Enum.TextXAlignment.Right,
}, keyRow)

keyRow.MouseButton1Click:Connect(function()
    rebinding = true
    keyLabel.Text = "press a key..."
    keyLabel.TextColor3 = Theme.Sub
end)

local transparencySlider = createSlider(settingsPage, "UI Transparency", 0, 0.8, Config.UITransparency, 2,
    function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end,
    function(v)
        Config.UITransparency = v
        main.GroupTransparency = v
    end
)

local resetBtn = new("TextButton", {
    Size = UDim2.new(1, -24, 0, 40),
    BackgroundColor3 = Theme.Panel,
    AutoButtonColor = false,
    Text = "Reset to Defaults",
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextColor3 = Theme.Text,
    BorderSizePixel = 0,
    LayoutOrder = 3,
}, settingsPage)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, resetBtn)
new("UIStroke", { Color = Theme.Stroke, Thickness = 1 }, resetBtn)

resetBtn.MouseButton1Click:Connect(function()
    Config = table.clone(DEFAULTS)
    swingToggle.Set(Config.FastSwing)
    delaySlider.Set(Config.SwingDelay)
    transparencySlider.Set(Config.UITransparency)
    main.GroupTransparency = Config.UITransparency
    setKeybind(Config.Keybind)
    updateStatus()
end)

--==============================================================
-- TABS
--==============================================================
local tabButtons = {}
local function createTab(text, page, order)
    local btn = new("TextButton", {
        Size = UDim2.new(1, -16, 0, 36),
        BackgroundColor3 = Theme.Panel,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        LayoutOrder = order,
    }, sidebar)
    new("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)

    local indicator = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(3, 16),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
    }, btn)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, indicator)

    local label = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -14, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextSize = 12,
        TextColor3 = Theme.Sub,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, btn)

    local entry = { Button = btn, Indicator = indicator, Label = label, Page = page }
    table.insert(tabButtons, entry)

    btn.MouseButton1Click:Connect(function()
        for _, t in ipairs(tabButtons) do
            local active = (t == entry)
            t.Page.Visible = active
            t.Indicator.Visible = active
            t.Label.TextColor3 = active and Theme.Accent or Theme.Sub
            TweenService:Create(t.Button, TweenInfo.new(0.15), {
                BackgroundColor3 = active and Theme.Panel2 or Theme.Panel,
            }):Play()
        end
    end)

    return entry
end

local mainTab = createTab("Main", mainPage, 1)
createTab("Settings", settingsPage, 2)

-- Activate Main tab by default
mainTab.Page.Visible = true
mainTab.Indicator.Visible = true
mainTab.Label.TextColor3 = Theme.Accent
mainTab.Button.BackgroundColor3 = Theme.Panel2

--==============================================================
-- CLOSE BUTTON
--==============================================================
local function toggleUI()
    main.Visible = not main.Visible
end
closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
end)

--==============================================================
-- KEYBIND LISTENER (Left Alt to toggle, rebindable)
--==============================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- rebinding mode
    if rebinding then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            setKeybind(input.KeyCode)
            rebinding = false
        end
        return
    end

    if input.KeyCode == Config.Keybind then
        toggleUI()
    end
end)

--==============================================================
-- SWING LOOP (single loop, checks Config each tick)
--==============================================================
task.spawn(function()
    local lastCacheRefresh = 0
    while true do
        local now = os.clock()

        if Config.FastSwing then
            -- Re-scan for remotes every 3s in case the game loaded them late
            if now - lastCacheRefresh > 3 then
                refreshRemoteCache()
                lastCacheRefresh = now
            end
            swingOnce()
            task.wait(Config.SwingDelay)
        else
            task.wait(0.1)
        end
    end
end)

updateStatus()
print("[Venace] Universal Pickaxe Hub loaded. Press LEFT ALT to toggle.")
