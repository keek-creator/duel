-- // [1] SERVICES //

local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local Stats            = game:GetService("Stats")
local StarterGui       = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- // [2] CONFIGURATION //

-- [[ CONFIG - EDIT EVERYTHING HERE ]] --

local CONFIG = {

    Names = {
        MainGui    = "KeekDuel",
        HudGui     = "KeekHUD",
        DuelGui    = "KeekDuelUI",
        MainFrame  = "MainFrame",
        HudFrame   = "HudFrame",
        DuelFrame  = "DuelFrame",
        OpenButton = "OpenButton",
        TabBar     = "TabBar",
        Content    = "ContentFrame",
    },

    Colors = {
        Gold          = Color3.fromRGB(255,0,0),
        GoldDim       = Color3.fromRGB(255,80,80),
        Background    = Color3.new(0, 0, 0),
        FrameDark     = Color3.new(0.0392157, 0.0392157, 0.0392157),
        FrameMid      = Color3.new(0.0588235, 0.0588235, 0.0784314),
        FrameLight    = Color3.new(0.117647, 0.117647, 0.117647),
        ButtonDark    = Color3.new(0.0980392, 0.0980392, 0.0980392),
        ButtonOff     = Color3.new(0.0980392, 0.0980392, 0.0980392),
        ButtonOn      = Color3.fromRGB(255,0,0),
        ButtonOnText  = Color3.new(0, 0, 0),
        ButtonOffText = Color3.new(0.470588, 0.431373, 0.235294),
        White         = Color3.new(1, 1, 1),
        Divider       = Color3.new(1, 1, 1),
        SliderTrack   = Color3.new(0.117647, 0.117647, 0.117647),
        SliderFill    = Color3.fromRGB(255,0,0),
        PlotZone      = Color3.new(0, 0, 0),
    },

    Sizes = {
        MainFrame  = UDim2.new(0, 260, 0, 330),
        HudFrame   = UDim2.new(0, 180, 0, 52),
        DuelFrame  = UDim2.new(0, 200, 0, 135),
        OpenButton = UDim2.new(0, 48, 0, 48),
    },

    Positions = {
        MainFrame  = UDim2.new(0.5, -130, 0.5, -165),
        HudFrame   = UDim2.new(0.5, -90, 0, 5),
        DuelFrame  = UDim2.new(0.5, -100, 0.28, 0),
        OpenButton = UDim2.new(0.01, 0, 0.18, 0),
    },

    Fonts = {
        Title  = Enum.Font.GothamBlack,
        Body   = Enum.Font.Gotham,
        Bold   = Enum.Font.GothamBold,
    },

    Keys = {
        ToggleGui  = Enum.KeyCode.U,
        BatLock    = Enum.KeyCode.X,
        Speed      = Enum.KeyCode.V,
        InfJump    = Enum.KeyCode.J,
        Fling      = Enum.KeyCode.F,
        AutoDuel   = Enum.KeyCode.G,
    },

    Defaults = {
        HeliSpeed   = 10,
        BatLockSpeed= 55,
        GrabRadius  = 7,
        FOV         = 70,
    },

    Tabs = {"Combat", "Protect", "Visual", "Settings"},

    -- Combat tab toggles (label = display name, default = starting state)
    CombatToggles = {
        { label = "Bat Lock UI",          default = false },
        { label = "Fling",                default = false },
        { label = "Float",                default = false },
        { label = "Speed Custom",         default = false },
        { label = "Inf Jump",             default = false },
        { label = "Auto Duel",            default = false },
        { label = "Auto R / L",           default = false },
        { label = "Auto Grab",            default = false },
        { label = "Auto Correct Lag",     default = false },
        { label = "Anti-Ragdoll",         default = false },
        { label = "Visual Player",        default = true  },
        { label = "Auto disable on plot", default = false },
    },

    -- Protect tab toggles
    ProtectToggles = {
        { label = "Anti Effect",  default = false },
        { label = "Xray Base",   default = false },
        { label = "Unwalk",       default = false },
        { label = "Player ESP",   default = false },
    },

    -- Visual tab toggles
    VisualToggles = {
        { label = "Helicopter", default = false, hasSlider = true },
    },

}

-- // [3] OBJECT REFERENCES //

local MainGui    = nil
local HudGui     = nil
local DuelGui    = nil

-- Main window
local MainFrame  = nil
local OpenButton = nil
local TitleBar   = nil
local CloseBtn   = nil
local TabBar     = nil
local ContentFrame = nil

-- HUD elements
local HudFrame      = nil
local HudTitle      = nil
local HudDivider    = nil
local HudStatsLabel = nil
local HudPlatLabel  = nil
local HudProgressOuter = nil
local HudProgressFill  = nil
local HudProgressThumb = nil
local HudSpeedBox   = nil

-- Duel window
local DuelFrame     = nil
local DuelTitleBar  = nil
local DuelContent   = nil
local DuelAutoRBtn  = nil
local DuelAutoLBtn  = nil
local DuelStopBtn   = nil
local DuelStatusLbl = nil

-- Stroke gradient on HUD (rotates each frame)
local HudStrokeGradient = nil

-- Runtime state
local CurrentTab      = "Combat"
local TabButtons      = {}
local ScrollFrames    = {}
local ToggleStates    = {}
local BoundKeys       = {}
local HeliSpeed       = CONFIG.Defaults.HeliSpeed
local BatLockSpeed    = CONFIG.Defaults.BatLockSpeed
local GrabRadius      = CONFIG.Defaults.GrabRadius
local CurrentFOV      = CONFIG.Defaults.FOV
local GradientAngle   = 0
local PlotZonePart    = nil
local PlotZoneBox     = nil

-- // [4] UTILITY FUNCTIONS //

local function getHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("UpperTorso")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function getCamera()
    return workspace.CurrentCamera
end

-- Smooth tween helper
local function tween(obj, props, duration, style, direction)
    style     = style     or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration or 0.3, style, direction)
    return TweenService:Create(obj, info, props)
end

-- Creates a rounded stroke with a spinning gold gradient
local function applyGoldStroke(parent, thickness)
    thickness = thickness or 2.5
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness
    stroke.Color     = CONFIG.Colors.Gold

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.15, Color3.new(0, 0, 0)),
        ColorSequenceKeypoint.new(0.3,  Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.45, Color3.new(0, 0, 0)),
        ColorSequenceKeypoint.new(0.6,  Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.75, Color3.new(0, 0, 0)),
        ColorSequenceKeypoint.new(1,    Color3.new(1, 1, 1)),
    })
    grad.Parent = stroke
    stroke.Parent = parent
    return stroke, grad
end

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or UDim.new(0, 8)
    c.Parent = parent
    return c
end

-- Creates a standard toggle row inside a ScrollingFrame
local function createToggleRow(parent, labelText, isOn)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 0.3
    row.BackgroundColor3       = CONFIG.Colors.FrameDark
    row.Size                   = UDim2.new(0.96, 0, 0, 28)
    row.BorderSizePixel         = 0
    addCorner(row, UDim.new(0, 7))

    local stroke = Instance.new("UIStroke")
    stroke.Transparency = 0.7
    stroke.Thickness    = 0.4
    stroke.Parent       = row

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = CONFIG.Colors.White
    lbl.Font                   = CONFIG.Fonts.Body
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextSize               = 9
    lbl.Text                   = labelText
    lbl.Position               = UDim2.new(0.03, 0, 0, 0)
    lbl.Size                   = UDim2.new(0.58, 0, 1, 0)
    lbl.Parent                 = row

    local btn = Instance.new("TextButton")
    btn.Font                   = CONFIG.Fonts.Bold
    btn.TextSize               = 8
    btn.Size                   = UDim2.new(0, 40, 0, 18)
    btn.Position               = UDim2.new(1, -44, 0.5, -9)
    btn.Text                   = isOn and "ON" or "OFF"
    btn.BackgroundColor3       = isOn and CONFIG.Colors.ButtonOn or CONFIG.Colors.ButtonOff
    btn.TextColor3             = isOn and CONFIG.Colors.ButtonOnText or CONFIG.Colors.Gold
    addCorner(btn, UDim.new(0, 5))

    local bstroke = Instance.new("UIStroke")
    bstroke.Transparency = 0.5
    bstroke.Thickness    = 0.7
    bstroke.Parent       = btn

    btn.Parent = row
    row.Parent = parent

    return row, btn
end

-- Creates a slider row (track + fill + draggable thumb + textbox)
local function createSliderRow(parent, labelText, defaultVal, minVal, maxVal, onChanged)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 0.3
    row.BackgroundColor3       = CONFIG.Colors.FrameDark
    row.Size                   = UDim2.new(0.96, 0, 0, 40)
    row.BorderSizePixel         = 0
    addCorner(row, UDim.new(0, 7))

    local stroke = Instance.new("UIStroke")
    stroke.Transparency = 0.7
    stroke.Thickness    = 0.4
    stroke.Parent       = row

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = CONFIG.Colors.White
    lbl.Font                   = CONFIG.Fonts.Body
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextSize               = 8
    lbl.Text                   = labelText .. ": " .. tostring(defaultVal)
    lbl.Position               = UDim2.new(0.03, 0, 0, 2)
    lbl.Size                   = UDim2.new(0.6, 0, 0, 14)
    lbl.Parent                 = row

    local box = Instance.new("TextBox")
    box.BackgroundColor3  = CONFIG.Colors.ButtonDark
    box.TextColor3        = CONFIG.Colors.Gold
    box.Font              = CONFIG.Fonts.Bold
    box.TextSize          = 8
    box.ClearTextOnFocus  = false
    box.Text              = tostring(defaultVal)
    box.Size              = UDim2.new(0, 34, 0, 14)
    box.Position          = UDim2.new(1, -38, 0, 1)
    box.ZIndex            = 2
    addCorner(box, UDim.new(0, 4))
    box.Parent = row

    local track = Instance.new("Frame")
    track.BackgroundColor3 = CONFIG.Colors.SliderTrack
    track.BorderSizePixel  = 0
    track.Size             = UDim2.new(0.9, 0, 0, 6)
    track.Position         = UDim2.new(0.05, 0, 0, 24)
    addCorner(track, UDim.new(1, 0))
    track.Parent = row

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = CONFIG.Colors.SliderFill
    fill.BorderSizePixel  = 0
    local initRatio = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
    fill.Size             = UDim2.new(initRatio, 0, 1, 0)
    addCorner(fill, UDim.new(1, 0))
    fill.Parent = track

    local thumb = Instance.new("Frame")
    thumb.BackgroundColor3 = CONFIG.Colors.SliderFill
    thumb.BorderSizePixel  = 0
    thumb.ZIndex           = 3
    thumb.Size             = UDim2.new(0, 11, 0, 11)
    thumb.Position         = UDim2.new(initRatio, -5, 0.5, -5)
    addCorner(thumb, UDim.new(1, 0))
    local thumbStroke = Instance.new("UIStroke")
    thumbStroke.Color  = Color3.new(0, 0, 0)
    thumbStroke.Parent = thumb
    thumb.Parent = track

    -- Invisible drag button spanning full track height
    local dragBtn = Instance.new("TextButton")
    dragBtn.BackgroundTransparency = 1
    dragBtn.Text     = ""
    dragBtn.ZIndex   = 3
    dragBtn.Size     = UDim2.new(1, 0, 3, 0)
    dragBtn.Position = UDim2.new(0, 0, -1, 0)
    dragBtn.Parent   = track

    local function applyValue(ratio)
        ratio = math.clamp(ratio, 0, 1)
        local val = math.floor(minVal + ratio * (maxVal - minVal))
        fill.Size      = UDim2.new(ratio, 0, 1, 0)
        thumb.Position = UDim2.new(ratio, -5, 0.5, -5)
        box.Text       = tostring(val)
        lbl.Text       = labelText .. ": " .. tostring(val)
        if onChanged then onChanged(val) end
    end

    local dragging = false
    dragBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    dragBtn.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local absPos  = track.AbsolutePosition
        local absSize = track.AbsoluteSize
        local ratio   = (inp.Position.X - absPos.X) / absSize.X
        applyValue(ratio)
    end)

    box.FocusLost:Connect(function()
        local v = tonumber(box.Text)
        if v then
            applyValue((v - minVal) / (maxVal - minVal))
        end
    end)

    row.Parent = parent
    return row
end

-- Creates a keybind button row
local function createKeybindRow(parent, labelText, defaultKey, onBound)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 0.3
    row.BackgroundColor3       = CONFIG.Colors.FrameDark
    row.Size                   = UDim2.new(0.96, 0, 0, 28)
    row.BorderSizePixel         = 0
    addCorner(row, UDim.new(0, 7))

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = CONFIG.Colors.White
    lbl.Font                   = CONFIG.Fonts.Body
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextSize               = 9
    lbl.Text                   = labelText
    lbl.Position               = UDim2.new(0.03, 0, 0, 0)
    lbl.Size                   = UDim2.new(0.55, 0, 1, 0)
    lbl.Parent                 = row

    local keyName = defaultKey and defaultKey.Name or "?"
    local btn = Instance.new("TextButton")
    btn.Font              = CONFIG.Fonts.Bold
    btn.TextSize          = 8
    btn.BackgroundColor3  = CONFIG.Colors.ButtonDark
    btn.TextColor3        = CONFIG.Colors.Gold
    btn.Text              = keyName
    btn.Size              = UDim2.new(0, 40, 0, 16)
    btn.Position          = UDim2.new(1, -44, 0.5, -8)
    addCorner(btn, UDim.new(0, 5))
    btn.Parent = row

    local waiting = false
    btn.MouseButton1Click:Connect(function()
        if waiting then return end
        waiting   = true
        btn.Text  = "..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(inp, gp)
            if gp then return end
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                local newKey = inp.KeyCode
                BoundKeys[labelText] = newKey
                btn.Text = newKey.Name
                if onBound then onBound(newKey) end
                waiting = false
                conn:Disconnect()
            end
        end)
    end)

    row.Parent = parent
    return row, btn
end

-- // [5] GUI CREATION //

local function buildToggleSection(scrollFrame, toggleList, sectionKey)
    for i, info in ipairs(toggleList) do
        local stateKey = sectionKey .. "_" .. i
        ToggleStates[stateKey] = info.default or false

        local row, btn = createToggleRow(scrollFrame, info.label, info.default)

        btn.MouseButton1Click:Connect(function()
            ToggleStates[stateKey] = not ToggleStates[stateKey]
            local on = ToggleStates[stateKey]
            btn.Text             = on and "ON"  or "OFF"
            btn.BackgroundColor3 = on and CONFIG.Colors.ButtonOn  or CONFIG.Colors.ButtonOff
            btn.TextColor3       = on and CONFIG.Colors.ButtonOnText or CONFIG.Colors.Gold
        end)

        if info.hasSlider then
            createSliderRow(scrollFrame, "Heli Speed", CONFIG.Defaults.HeliSpeed, 1, 100, function(v)
                HeliSpeed = v
            end)
        end
    end
end

local function createHUD()
    -- Cleanup old
    pcall(function() CoreGui:FindFirstChild(CONFIG.Names.HudGui):Destroy() end)

    HudGui = Instance.new("ScreenGui")
    HudGui.Name         = CONFIG.Names.HudGui
    HudGui.ResetOnSpawn = false
    HudGui.Parent       = CoreGui

    HudFrame = Instance.new("Frame")
    HudFrame.Name                = CONFIG.Names.HudFrame
    HudFrame.BackgroundTransparency = 0.06
    HudFrame.BackgroundColor3    = CONFIG.Colors.Background
    HudFrame.Size                = CONFIG.Sizes.HudFrame
    HudFrame.Position            = CONFIG.Positions.HudFrame
    HudFrame.Parent              = HudGui
    addCorner(HudFrame, UDim.new(0, 10))

    local _, hudGrad = applyGoldStroke(HudFrame, 2.5)
    HudStrokeGradient = hudGrad

    HudTitle = Instance.new("TextLabel")
    HudTitle.BackgroundTransparency = 1
    HudTitle.TextColor3  = CONFIG.Colors.Gold
    HudTitle.Font        = CONFIG.Fonts.Title
    HudTitle.TextSize    = 10
    HudTitle.Text        = "KEEK DUEL"
    HudTitle.Position    = UDim2.new(0, 0, 0, 2)
    HudTitle.Size        = UDim2.new(1, 0, 0, 12)
    HudTitle.Parent      = HudFrame

    HudDivider = Instance.new("Frame")
    HudDivider.BackgroundTransparency = 0.6
    HudDivider.BackgroundColor3       = CONFIG.Colors.Divider
    HudDivider.BorderSizePixel        = 0
    HudDivider.Size                   = UDim2.new(0.85, 0, 0, 1)
    HudDivider.Position               = UDim2.new(0.075, 0, 0, 15)
    HudDivider.Parent                 = HudFrame

    HudStatsLabel = Instance.new("TextLabel")
    HudStatsLabel.BackgroundTransparency = 1
    HudStatsLabel.TextColor3  = CONFIG.Colors.GoldDim
    HudStatsLabel.Font        = CONFIG.Fonts.Body
    HudStatsLabel.TextSize    = 7
    HudStatsLabel.Text        = "FPS: -- | Ping: --ms"
    HudStatsLabel.Position    = UDim2.new(0, 0, 0, 17)
    HudStatsLabel.Size        = UDim2.new(1, 0, 0, 10)
    HudStatsLabel.Parent      = HudFrame

    HudPlatLabel = Instance.new("TextLabel")
    HudPlatLabel.BackgroundTransparency = 1
    HudPlatLabel.TextColor3  = CONFIG.Colors.GoldDim
    HudPlatLabel.Font        = CONFIG.Fonts.Body
    HudPlatLabel.TextSize    = 6
    HudPlatLabel.Text        = UserInputService.TouchEnabled and "📱 Mobile" or "🖥 PC"
    HudPlatLabel.Position    = UDim2.new(0, 0, 0, 28)
    HudPlatLabel.Size        = UDim2.new(1, 0, 0, 8)
    HudPlatLabel.Parent      = HudFrame

    -- Progress bar (hidden by default; shown during bat lock or other active features)
    local progressOuter = Instance.new("Frame")
    progressOuter.Visible             = false
    progressOuter.BackgroundColor3    = CONFIG.Colors.FrameMid
    progressOuter.BorderSizePixel     = 0
    progressOuter.Size                = UDim2.new(0.7, 0, 0, 8)
    progressOuter.Position            = UDim2.new(0.04, 0, 0, 38)
    addCorner(progressOuter, UDim.new(1, 0))
    applyGoldStroke(progressOuter, 1.5)
    progressOuter.Parent = HudFrame
    HudProgressOuter = progressOuter

    HudProgressFill = Instance.new("Frame")
    HudProgressFill.BackgroundColor3 = CONFIG.Colors.Gold
    HudProgressFill.BorderSizePixel  = 0
    HudProgressFill.Size             = UDim2.new(0, 0, 1, 0)
    addCorner(HudProgressFill, UDim.new(1, 0))
    HudProgressFill.Parent = progressOuter

    -- Speed override textbox
    HudSpeedBox = Instance.new("TextBox")
    HudSpeedBox.Visible           = false
    HudSpeedBox.TextColor3        = CONFIG.Colors.Gold
    HudSpeedBox.Font              = CONFIG.Fonts.Bold
    HudSpeedBox.TextSize          = 7
    HudSpeedBox.Text              = tostring(CONFIG.Defaults.BatLockSpeed)
    HudSpeedBox.BackgroundColor3  = CONFIG.Colors.ButtonDark
    HudSpeedBox.ClearTextOnFocus  = false
    HudSpeedBox.Size              = UDim2.new(0, 30, 0, 12)
    HudSpeedBox.Position          = UDim2.new(0.78, 0, 0, 36)
    addCorner(HudSpeedBox, UDim.new(0, 4))
    applyGoldStroke(HudSpeedBox, 1)
    HudSpeedBox.Parent = HudFrame

    HudSpeedBox.FocusLost:Connect(function()
        local v = tonumber(HudSpeedBox.Text)
        if v then BatLockSpeed = v end
    end)

    -- HUD drag
    local hudDragging = false
    local hudDragStart, hudStartPos
    HudFrame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            hudDragging  = true
            hudDragStart = inp.Position
            hudStartPos  = HudFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not hudDragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = inp.Position - hudDragStart
        HudFrame.Position = UDim2.new(
            hudStartPos.X.Scale, hudStartPos.X.Offset + delta.X,
            hudStartPos.Y.Scale, hudStartPos.Y.Offset + delta.Y
        )
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            hudDragging = false
        end
    end)
end

local function createMainGUI()
    -- Cleanup old
    pcall(function() CoreGui:FindFirstChild(CONFIG.Names.MainGui):Destroy() end)

    MainGui = Instance.new("ScreenGui")
    MainGui.Name         = CONFIG.Names.MainGui
    MainGui.ResetOnSpawn = false
    MainGui.Parent       = CoreGui

    -- Floating open button (shown when main window is closed)
    OpenButton = Instance.new("TextButton")
    OpenButton.Name             = CONFIG.Names.OpenButton
    OpenButton.Text             = "Open"
    OpenButton.Font             = CONFIG.Fonts.Bold
    OpenButton.TextSize         = 11
    OpenButton.TextColor3       = CONFIG.Colors.Gold
    OpenButton.BackgroundColor3 = CONFIG.Colors.Background
    OpenButton.Size             = CONFIG.Sizes.OpenButton
    OpenButton.Position         = CONFIG.Positions.OpenButton
    addCorner(OpenButton, UDim.new(0, 8))
    applyGoldStroke(OpenButton, 1.5)
    OpenButton.Parent = MainGui

    -- Main window frame
    MainFrame = Instance.new("Frame")
    MainFrame.Name                = CONFIG.Names.MainFrame
    MainFrame.BackgroundColor3    = CONFIG.Colors.Background
    MainFrame.Size                = CONFIG.Sizes.MainFrame
    MainFrame.Position            = CONFIG.Positions.MainFrame
    MainFrame.ClipsDescendants    = true
    MainFrame.Visible             = false
    addCorner(MainFrame, UDim.new(0, 8))
    applyGoldStroke(MainFrame, 2)
    MainFrame.Parent = MainGui

    -- Title bar (draggable)
    TitleBar = Instance.new("Frame")
    TitleBar.BackgroundTransparency = 1
    TitleBar.Active  = true
    TitleBar.ZIndex  = 2
    TitleBar.Size    = UDim2.new(1, 0, 0, 32)
    TitleBar.Position= UDim2.new(0, 0, 0, 0)
    TitleBar.Parent  = MainFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3    = CONFIG.Colors.Gold
    titleLabel.Font          = CONFIG.Fonts.Bold
    titleLabel.TextXAlignment= Enum.TextXAlignment.Left
    titleLabel.TextSize      = 13
    titleLabel.Text          = "Keek Duel"
    titleLabel.Position      = UDim2.new(0.04, 0, 0, 0)
    titleLabel.Size          = UDim2.new(0.7, 0, 0, 32)
    titleLabel.ZIndex        = 2
    titleLabel.Parent        = MainFrame

    CloseBtn = Instance.new("TextButton")
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text      = "×"
    CloseBtn.Font      = CONFIG.Fonts.Title
    CloseBtn.TextSize  = 18
    CloseBtn.TextColor3= CONFIG.Colors.Gold
    CloseBtn.Size      = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position  = UDim2.new(1, -32, 0, 2)
    CloseBtn.ZIndex    = 2
    CloseBtn.Parent    = MainFrame

    -- Thin divider below title
    local divider = Instance.new("Frame")
    divider.BackgroundTransparency = 0.5
    divider.BackgroundColor3       = CONFIG.Colors.Divider
    divider.BorderSizePixel        = 0
    divider.Size                   = UDim2.new(0.9, 0, 0, 1)
    divider.Position               = UDim2.new(0.05, 0, 0, 32)
    divider.Parent = MainFrame

    -- Tab bar
    TabBar = Instance.new("Frame")
    TabBar.Name                = CONFIG.Names.TabBar
    TabBar.BackgroundColor3    = CONFIG.Colors.FrameMid
    TabBar.BorderSizePixel     = 0
    TabBar.Size                = UDim2.new(0.94, 0, 0, 24)
    TabBar.Position            = UDim2.new(0.03, 0, 0, 36)
    addCorner(TabBar, UDim.new(0, 6))
    TabBar.Parent = MainFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection       = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.Parent = TabBar

    -- Content area
    ContentFrame = Instance.new("Frame")
    ContentFrame.Name             = CONFIG.Names.Content
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Size             = UDim2.new(0.96, 0, 0, 262)
    ContentFrame.Position         = UDim2.new(0.02, 0, 0, 64)
    ContentFrame.Parent           = MainFrame

    -- Build tabs
    for _, tabName in ipairs(CONFIG.Tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Font              = CONFIG.Fonts.Bold
        tabBtn.Text              = tabName
        tabBtn.TextSize          = 9
        tabBtn.Size              = UDim2.new(0.24, 0, 1, 0)
        tabBtn.BackgroundColor3  = CONFIG.Colors.FrameMid
        tabBtn.TextColor3        = CONFIG.Colors.ButtonOffText
        tabBtn.BorderSizePixel   = 0
        tabBtn.Parent            = TabBar
        TabButtons[tabName]      = tabBtn

        -- ScrollingFrame for each tab's content
        local sf = Instance.new("ScrollingFrame")
        sf.Visible               = false
        sf.BackgroundTransparency= 1
        sf.ZIndex                = 2
        sf.AutomaticCanvasSize   = Enum.AutomaticSize.Y
        sf.ScrollBarThickness    = 2
        sf.ScrollBarImageColor3  = CONFIG.Colors.Gold
        sf.Size                  = UDim2.new(1, 0, 1, 0)
        sf.Parent                = ContentFrame
        ScrollFrames[tabName]    = sf

        local sfLayout = Instance.new("UIListLayout")
        sfLayout.Padding         = UDim.new(0, 3)
        sfLayout.Parent          = sf

        local sfPad = Instance.new("UIPadding")
        sfPad.PaddingTop = UDim.new(0, 2)
        sfPad.Parent     = sf
    end

    -- Populate Combat
    buildToggleSection(ScrollFrames["Combat"],  CONFIG.CombatToggles,  "Combat")
    buildToggleSection(ScrollFrames["Protect"], CONFIG.ProtectToggles, "Protect")
    buildToggleSection(ScrollFrames["Visual"],  CONFIG.VisualToggles,  "Visual")

    -- Settings tab content
    local settingsSF = ScrollFrames["Settings"]
    createSliderRow(settingsSF, "FOV", CONFIG.Defaults.FOV, 30, 120, function(v)
        CurrentFOV = v
        local cam = getCamera()
        if cam then cam.FieldOfView = v end
    end)
    createKeybindRow(settingsSF, "Bat Lock Key",  CONFIG.Keys.BatLock)
    createKeybindRow(settingsSF, "Speed Key",     CONFIG.Keys.Speed)
    createKeybindRow(settingsSF, "Inf Jump Key",  CONFIG.Keys.InfJump)
    createKeybindRow(settingsSF, "Fling Key",     CONFIG.Keys.Fling)
    createKeybindRow(settingsSF, "Auto Duel Key", CONFIG.Keys.AutoDuel)
    createSliderRow(settingsSF, "BatLock Speed", CONFIG.Defaults.BatLockSpeed, 10, 200, function(v)
        BatLockSpeed = v
    end)
    createSliderRow(settingsSF, "Grab Radius", CONFIG.Defaults.GrabRadius, 1, 50, function(v)
        GrabRadius = v
    end)

    -- Mobile mode label
    local mobLabel = Instance.new("TextLabel")
    mobLabel.BackgroundTransparency = 1
    mobLabel.TextColor3  = CONFIG.Colors.White
    mobLabel.Font        = CONFIG.Fonts.Body
    mobLabel.TextSize    = 8
    mobLabel.Text        = "📱 Mobile Mode"
    mobLabel.Size        = UDim2.new(0.96, 0, 0, 16)
    mobLabel.Parent      = settingsSF

    local saveBtn = Instance.new("TextButton")
    saveBtn.Font             = CONFIG.Fonts.Title
    saveBtn.Text             = "SAVE CONFIG"
    saveBtn.TextSize         = 10
    saveBtn.TextColor3       = CONFIG.Colors.Gold
    saveBtn.BackgroundColor3 = CONFIG.Colors.Background
    saveBtn.Size             = UDim2.new(0.96, 0, 0, 28)
    addCorner(saveBtn, UDim.new(0, 6))
    applyGoldStroke(saveBtn, 1)
    saveBtn.Parent = settingsSF

    saveBtn.MouseButton1Click:Connect(function()
        -- Config save stub — extend with DataStore or writefile if available
        print("[IllusionDev] Config saved!")
    end)

    local hintLabel = Instance.new("TextLabel")
    hintLabel.BackgroundTransparency = 1
    hintLabel.TextColor3  = CONFIG.Colors.GoldDim
    hintLabel.Font        = CONFIG.Fonts.Body
    hintLabel.TextSize    = 7
    hintLabel.Text        = "Press U to toggle GUI | Auto saves every 10s"
    hintLabel.Size        = UDim2.new(0.96, 0, 0, 14)
    hintLabel.Parent      = settingsSF

    local versionLabel = Instance.new("TextLabel")
    versionLabel.BackgroundTransparency = 1
    versionLabel.TextColor3  = CONFIG.Colors.GoldDim
    versionLabel.Font        = CONFIG.Fonts.Body
    versionLabel.TextSize    = 7
    versionLabel.Text        = "Keek Duel v5.4"
    versionLabel.Size        = UDim2.new(0.96, 0, 0, 12)
    versionLabel.Parent      = settingsSF

    -- Title bar drag logic
    local mainDragging = false
    local mainDragStart, mainStartPos
    TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            mainDragging  = true
            mainDragStart = inp.Position
            mainStartPos  = MainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not mainDragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = inp.Position - mainDragStart
        MainFrame.Position = UDim2.new(
            mainStartPos.X.Scale, mainStartPos.X.Offset + delta.X,
            mainStartPos.Y.Scale, mainStartPos.Y.Offset + delta.Y
        )
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            mainDragging = false
        end
    end)
end

local function createDuelUI()
    pcall(function() CoreGui:FindFirstChild(CONFIG.Names.DuelGui):Destroy() end)

    DuelGui = Instance.new("ScreenGui")
    DuelGui.Name         = CONFIG.Names.DuelGui
    DuelGui.ResetOnSpawn = false
    DuelGui.Enabled      = true
    DuelGui.Parent       = CoreGui

    DuelFrame = Instance.new("Frame")
    DuelFrame.Name             = CONFIG.Names.DuelFrame
    DuelFrame.BackgroundColor3 = CONFIG.Colors.Background
    DuelFrame.Size             = CONFIG.Sizes.DuelFrame
    DuelFrame.Position         = CONFIG.Positions.DuelFrame
    addCorner(DuelFrame, UDim.new(0, 8))
    applyGoldStroke(DuelFrame, 1.5)
    DuelFrame.Parent = DuelGui

    DuelTitleBar = Instance.new("Frame")
    DuelTitleBar.BackgroundTransparency = 1
    DuelTitleBar.Size     = UDim2.new(1, 0, 0, 28)
    DuelTitleBar.Position = UDim2.new(0, 0, 0, 0)
    DuelTitleBar.Parent   = DuelFrame

    local duelTitle = Instance.new("TextLabel")
    duelTitle.BackgroundTransparency = 1
    duelTitle.TextColor3   = CONFIG.Colors.Gold
    duelTitle.Font         = CONFIG.Fonts.Bold
    duelTitle.TextSize     = 11
    duelTitle.Text         = "AUTO DUEL"
    duelTitle.Size         = UDim2.new(0.5, 0, 1, 0)
    duelTitle.Parent       = DuelTitleBar

    local duelMinimize = Instance.new("TextButton")
    duelMinimize.BackgroundTransparency = 1
    duelMinimize.Text       = "▼"
    duelMinimize.TextSize   = 10
    duelMinimize.TextColor3 = CONFIG.Colors.Gold
    duelMinimize.Size       = UDim2.new(0, 20, 0, 20)
    duelMinimize.Position   = UDim2.new(1, -24, 0, 4)
    duelMinimize.Parent     = DuelTitleBar

    DuelContent = Instance.new("Frame")
    DuelContent.BackgroundTransparency = 1
    DuelContent.Size     = UDim2.new(1, 0, 1, -28)
    DuelContent.Position = UDim2.new(0, 0, 0, 28)
    DuelContent.Parent   = DuelFrame

    DuelAutoRBtn = Instance.new("TextButton")
    DuelAutoRBtn.Font             = CONFIG.Fonts.Bold
    DuelAutoRBtn.TextSize         = 9
    DuelAutoRBtn.Text             = "AutoR"
    DuelAutoRBtn.TextColor3       = CONFIG.Colors.Gold
    DuelAutoRBtn.BackgroundColor3 = CONFIG.Colors.ButtonDark
    DuelAutoRBtn.Size             = UDim2.new(0.44, 0, 0, 30)
    DuelAutoRBtn.Position         = UDim2.new(0.04, 0, 0, 6)
    addCorner(DuelAutoRBtn, UDim.new(0, 6))
    applyGoldStroke(DuelAutoRBtn, 0.8)
    DuelAutoRBtn.Parent = DuelContent

    DuelAutoLBtn = Instance.new("TextButton")
    DuelAutoLBtn.Font             = CONFIG.Fonts.Bold
    DuelAutoLBtn.TextSize         = 9
    DuelAutoLBtn.Text             = "AutoL"
    DuelAutoLBtn.TextColor3       = CONFIG.Colors.Gold
    DuelAutoLBtn.BackgroundColor3 = CONFIG.Colors.ButtonDark
    DuelAutoLBtn.Size             = UDim2.new(0.44, 0, 0, 30)
    DuelAutoLBtn.Position         = UDim2.new(0.52, 0, 0, 6)
    addCorner(DuelAutoLBtn, UDim.new(0, 6))
    applyGoldStroke(DuelAutoLBtn, 0.8)
    DuelAutoLBtn.Parent = DuelContent

    DuelStopBtn = Instance.new("TextButton")
    DuelStopBtn.Font             = CONFIG.Fonts.Bold
    DuelStopBtn.TextSize         = 9
    DuelStopBtn.Text             = "■ Stop All"
    DuelStopBtn.TextColor3       = CONFIG.Colors.Gold
    DuelStopBtn.BackgroundColor3 = CONFIG.Colors.ButtonDark
    DuelStopBtn.Size             = UDim2.new(0.9, 0, 0, 24)
    DuelStopBtn.Position         = UDim2.new(0.05, 0, 0, 42)
    addCorner(DuelStopBtn, UDim.new(0, 6))
    DuelStopBtn.Parent = DuelContent

    DuelStatusLbl = Instance.new("TextLabel")
    DuelStatusLbl.BackgroundTransparency = 1
    DuelStatusLbl.TextColor3  = CONFIG.Colors.GoldDim
    DuelStatusLbl.Font        = CONFIG.Fonts.Body
    DuelStatusLbl.TextSize    = 9
    DuelStatusLbl.Text        = "Idle"
    DuelStatusLbl.Size        = UDim2.new(0.9, 0, 0, 14)
    DuelStatusLbl.Position    = UDim2.new(0.05, 0, 0, 70)
    DuelStatusLbl.Parent      = DuelContent

    -- Duel window drag
    local duelDragging = false
    local duelDragStart, duelStartPos
    DuelTitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            duelDragging  = true
            duelDragStart = inp.Position
            duelStartPos  = DuelFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not duelDragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = inp.Position - duelDragStart
        DuelFrame.Position = UDim2.new(
            duelStartPos.X.Scale, duelStartPos.X.Offset + delta.X,
            duelStartPos.Y.Scale, duelStartPos.Y.Offset + delta.Y
        )
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            duelDragging = false
        end
    end)

    duelMinimize.MouseButton1Click:Connect(function()
        DuelContent.Visible = not DuelContent.Visible
        duelMinimize.Text   = DuelContent.Visible and "▼" or "▶"
    end)
end

-- // [6] FUNCTIONALITY //

local function switchTab(tabName)
    CurrentTab = tabName
    for name, sf in pairs(ScrollFrames) do
        sf.Visible = (name == tabName)
    end
    for name, btn in pairs(TabButtons) do
        if name == tabName then
            btn.TextColor3      = CONFIG.Colors.Gold
            btn.BackgroundColor3= Color3.new(0.1, 0.1, 0.1)
        else
            btn.TextColor3      = CONFIG.Colors.ButtonOffText
            btn.BackgroundColor3= CONFIG.Colors.FrameMid
        end
    end
end

local function toggleMainWindow(forceState)
    local visible = forceState ~= nil and forceState or (not MainFrame.Visible)
    MainFrame.Visible  = visible
    OpenButton.Visible = not visible
    if visible then
        tween(MainFrame, {Size = CONFIG.Sizes.MainFrame}, 0.25):Play()
    end
end

-- Spin the HUD stroke gradient each frame
local function startHUDGradientSpin()
    RunService.RenderStepped:Connect(function()
        if HudStrokeGradient then
            GradientAngle = (GradientAngle + 2) % 360
            HudStrokeGradient.Rotation = GradientAngle
        end
    end)
end

-- Update FPS and ping display every half-second
local lastStatUpdate = 0
local function startHUDStats()
    RunService.Heartbeat:Connect(function(dt)
        local now = tick()
        if now - lastStatUpdate < 0.5 then return end
        lastStatUpdate = now

        local fps  = math.floor(1 / dt)
        local ping = 0
        pcall(function()
            ping = math.floor(
                Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            )
        end)

        if HudStatsLabel then
            HudStatsLabel.Text = string.format("FPS: %d | Ping: %dms", fps, ping)
        end
    end)
end

-- Inf Jump
local function startInfJump()
    UserInputService.JumpRequest:Connect(function()
        if not ToggleStates["Combat_5"] then return end
        local hrp = getHRP()
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.new(
                hrp.AssemblyLinearVelocity.X,
                50,
                hrp.AssemblyLinearVelocity.Z
            )
        end
    end)
end

-- Godmode (max health on heartbeat when toggle is on)
local function startGodmode()
    RunService.Heartbeat:Connect(function()
        local hum = getHumanoid()
        if hum and hum.MaxHealth > 0 then
            hum.MaxHealth = math.huge
            hum.Health    = math.huge
        end
    end)
end

-- Character re-added — reapply god/etc
local function onCharacterAdded(char)
    char:WaitForChild("Humanoid")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.MaxHealth = math.huge
        hum.Health    = math.huge
    end
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
end

-- Plot zone visualizer
local function createPlotZone(cframe, size)
    pcall(function()
        if PlotZonePart then PlotZonePart:Destroy() end
    end)

    PlotZonePart              = Instance.new("Part")
    PlotZonePart.Name         = "IllusionPlotZone"
    PlotZonePart.Size         = size or Vector3.new(19, 0.05, 16)
    PlotZonePart.CFrame       = cframe or CFrame.new(-484.5, -6.95, 20)
    PlotZonePart.Color        = CONFIG.Colors.PlotZone
    PlotZonePart.Transparency = 0.85
    PlotZonePart.Anchored     = true
    PlotZonePart.CanCollide   = false
    PlotZonePart.Material     = Enum.Material.Neon
    PlotZonePart.Parent       = workspace

    PlotZoneBox               = Instance.new("SelectionBox")
    PlotZoneBox.Adornee       = PlotZonePart
    PlotZoneBox.Color3        = CONFIG.Colors.Gold
    PlotZoneBox.LineThickness = 0.04
    PlotZoneBox.SurfaceTransparency = 1
    PlotZoneBox.Parent        = PlotZonePart
end

-- Duel auto-swing state
local autoDuelRunning = false
local autoDuelSide    = nil

local function stopAutoDuel()
    autoDuelRunning = false
    autoDuelSide    = nil
    if DuelStatusLbl then DuelStatusLbl.Text = "Idle" end
    if DuelAutoRBtn  then
        DuelAutoRBtn.Text             = "AutoR"
        DuelAutoRBtn.BackgroundColor3 = CONFIG.Colors.ButtonDark
    end
    if DuelAutoLBtn  then
        DuelAutoLBtn.Text             = "AutoL"
        DuelAutoLBtn.BackgroundColor3 = CONFIG.Colors.ButtonDark
    end
end

local function startAutoDuel(side)
    stopAutoDuel()
    autoDuelRunning = true
    autoDuelSide    = side
    if DuelStatusLbl then DuelStatusLbl.Text = side == "R" and "Right..." or "Left..." end

    local activeBtn  = side == "R" and DuelAutoRBtn  or DuelAutoLBtn
    local activeStop = side == "R" and DuelAutoLBtn  or DuelAutoRBtn
    if activeBtn then
        activeBtn.Text             = "STOP " .. side
        activeBtn.BackgroundColor3 = Color3.fromRGB(40, 38, 10)
    end
    if activeStop then
        activeStop.Text             = side == "R" and "AutoL" or "AutoR"
        activeStop.BackgroundColor3 = CONFIG.Colors.ButtonDark
    end
end

local function connectDuelButtons()
    if not DuelAutoRBtn then return end
    DuelAutoRBtn.MouseButton1Click:Connect(function()
        if autoDuelRunning and autoDuelSide == "R" then
            stopAutoDuel()
        else
            startAutoDuel("R")
        end
    end)
    DuelAutoLBtn.MouseButton1Click:Connect(function()
        if autoDuelRunning and autoDuelSide == "L" then
            stopAutoDuel()
        else
            startAutoDuel("L")
        end
    end)
    DuelStopBtn.MouseButton1Click:Connect(stopAutoDuel)
end

local function connectMainButtons()
    CloseBtn.MouseButton1Click:Connect(function()
        toggleMainWindow(false)
    end)
    OpenButton.MouseButton1Click:Connect(function()
        toggleMainWindow(true)
    end)
    for _, tabName in ipairs(CONFIG.Tabs) do
        TabButtons[tabName].MouseButton1Click:Connect(function()
            switchTab(tabName)
        end)
    end
end

-- Global keybinds
local function connectKeybinds()
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end

        if inp.KeyCode == CONFIG.Keys.ToggleGui then
            toggleMainWindow()
        end
    end)
end

-- Cleanup on ScreenGui destroy (executor re-run safety)
local function connectDestroyCleanup()
    MainGui.Destroying:Connect(function()
        pcall(function() HudGui:Destroy()  end)
        pcall(function() DuelGui:Destroy() end)
        if PlotZonePart then
            pcall(function() PlotZonePart:Destroy() end)
        end
    end)
end

-- // [7] INITIALIZATION //

local function init()
    -- Remove any leftover GUI from previous run
    for _, name in ipairs({
        CONFIG.Names.MainGui,
        CONFIG.Names.HudGui,
        CONFIG.Names.DuelGui,
    }) do
        pcall(function()
            local existing = CoreGui:FindFirstChild(name)
            if existing then existing:Destroy() end
        end)
    end

    -- Apply FOV
    local cam = getCamera()
    if cam then cam.FieldOfView = CONFIG.Defaults.FOV end

    -- Suppress default CoreGui leaking into workspace
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
    end)

    -- Build GUIs
    createHUD()
    createMainGUI()
    createDuelUI()
    createPlotZone()

    -- Wire up events
    connectMainButtons()
    connectDuelButtons()
    connectKeybinds()
    connectDestroyCleanup()

    -- Start runtime loops
    startHUDGradientSpin()
    startHUDStats()
    startInfJump()
    startGodmode()

    -- Default to Combat tab visible
    switchTab("Combat")

    -- Connect character respawn handler
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end

    print("Keek Duel v5.4 Loaded!")
    print("[IllusionDev] Config applied!")
end

init()
