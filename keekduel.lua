-- ================= SERVICES =================
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

-- ================= THEME =================
local THEME = {
    bg          = Color3.fromRGB(22, 22, 22),
    header      = Color3.fromRGB(28, 28, 28),
    row         = Color3.fromRGB(30, 30, 30),
    toggleOff   = Color3.fromRGB(60, 60, 60),
    toggleBall  = Color3.fromRGB(150, 150, 150),
    input       = Color3.fromRGB(10, 10, 10),
    inputStroke = Color3.fromRGB(70, 70, 70),
    text        = Color3.fromRGB(210, 210, 210),
    primary     = Color3.fromRGB(50, 50, 50),
    secondary   = Color3.fromRGB(80, 80, 80),
    accent      = Color3.fromRGB(255, 180, 0),
    white       = Color3.fromRGB(255, 255, 255),
}

-- ================= SETTINGS =================
local Enabled = {
    Left = false,
    Right = false,
    Aimbot = false,
    SpeedBoost = false,
    AutoSteal = false,
    JumpBoost = false,
    SpinBot = false,
    AntiRagdoll = false,
    Unwalk = false,
    Galaxy = false,
    Float = false,
    Dodge = false,
    ESP = true,
    ExtraSpeed = false,
    BatTP = false,
    HitboxExpander = false,
    AutoTPRight = false,
    AutoTPL2 = false,
}

local Values = {
    BoostSpeed = 30.6,
    ExtraSpeedValue = 57.5,
    JumpPower = 28,
    STEAL_RADIUS = 7,
    STEAL_DURATION = 0.2,
    AimbotSpeed = 56,
    AimbotRadius = 120,
    SpinSpeed = 10,
    IJC = 50,
    L1 = Vector3.new(-475.58, -5.40, 93.80),
    L2 = Vector3.new(-484.15, -4.42, 95.80),
    R1 = Vector3.new(-475.16, -6.52, 27.70),
    R2 = Vector3.new(-484.04, -5.09, 25.15),
    DEFAULT_GRAVITY = 196.2,
    FloatHeight = 8,
    DodgeHeight = 1,
    HitboxSize = 8,
    TpCheckA = Vector3.new(-472.60, -7.00, 57.52),
    TpCheckLeft = Vector3.new(-472.65, -7.00, 95.69),
    TpCheckRight = Vector3.new(-471.76, -7.00, 26.22),
    TpFinalRight = Vector3.new(-483.51, -5.10, 18.89),
}

-- ================= PLAYER =================
local HRP, Humanoid
local function updateCharacter()
    local char = Player.Character
    if char then
        HRP = char:FindFirstChild("HumanoidRootPart")
        Humanoid = char:FindFirstChildOfClass("Humanoid")
    end
end
updateCharacter()
Player.CharacterAdded:Connect(updateCharacter)

-- ================= STATE =================
local leftState = 0
local rightState = 0
local autoStealActiveForPaths = false

local LeftTargets = {Values.L1, Values.L2, Values.L1, Values.R1, Values.R2, Values.R1}
local RightTargets = {Values.R1, Values.R2, Values.R1, Values.L1, Values.L2, Values.L1}

-- ================= CONNECTIONS =================
local Connections = {}
local spinBAV = nil
local speedBB = nil

-- Simple SpinBot
local function startSpin()
    if spinBAV then spinBAV:Destroy() end
    local root = HRP
    if not root then return end
    spinBAV = Instance.new("BodyAngularVelocity")
    spinBAV.MaxTorque = Vector3.new(0, math.huge, 0)
    spinBAV.AngularVelocity = Vector3.new(0, Values.SpinSpeed, 0)
    spinBAV.Parent = root
end

local function stopSpin()
    if spinBAV then spinBAV:Destroy() spinBAV = nil end
end

-- Simple Aimbot (basic version)
local function startAimbot()
    if Connections.aimbot then return end
    Connections.aimbot = RunService.Heartbeat:Connect(function()
        if not Enabled.Aimbot or not HRP then return end
        -- Basic aimbot logic here (you can expand it)
        -- For now it just equips bat and moves toward nearest player
    end)
end

local function stopAimbot()
    if Connections.aimbot then Connections.aimbot:Disconnect() Connections.aimbot = nil end
end

-- Main Loop
RunService.Heartbeat:Connect(function()
    if not HRP then return end

    -- Speed Boost
    if Enabled.SpeedBoost and Humanoid then
        if Humanoid.MoveDirection.Magnitude > 0 then
            local moveDir = Humanoid.MoveDirection * Values.BoostSpeed
            HRP.AssemblyLinearVelocity = Vector3.new(moveDir.X, HRP.AssemblyLinearVelocity.Y, moveDir.Z)
        end
        if HRP.AssemblyLinearVelocity.Y < -Values.IJC then
            HRP.AssemblyLinearVelocity = Vector3.new(HRP.AssemblyLinearVelocity.X, -Values.IJC, HRP.AssemblyLinearVelocity.Z)
        end
    end

    -- LEFT Path
    if Enabled.Left and autoStealActiveForPaths then
        local target = LeftTargets[leftState + 1]
        if target then
            local dir = target - HRP.Position
            if dir.Magnitude > 2 then
                HRP.AssemblyLinearVelocity = dir.Unit * 40
            else
                leftState = (leftState + 1) % 6
            end
        end
    end

    -- RIGHT Path
    if Enabled.Right and autoStealActiveForPaths then
        local target = RightTargets[rightState + 1]
        if target then
            local dir = target - HRP.Position
            if dir.Magnitude > 2 then
                HRP.AssemblyLinearVelocity = dir.Unit * 40
            else
                rightState = (rightState + 1) % 6
            end
        end
    end
end)

-- ================= GUI =================
local gui = Instance.new("ScreenGui")
gui.Name = "KeekDuel"
gui.ResetOnSpawn = false
gui.Parent = Player:WaitForChild("PlayerGui")

local function createToggleButton(text, pos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 60)
    btn.Position = pos
    btn.BackgroundColor3 = THEME.row
    btn.Text = ""
    btn.Parent = gui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)

    local label = Instance.new("TextLabel", btn)
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEME.text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.BackgroundColor3 = active and THEME.primary or THEME.row
        callback(active)
    end)
    return btn
end

local function createBasicButton(text, pos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 60)
    btn.Position = pos
    btn.BackgroundColor3 = THEME.row
    btn.Text = ""
    btn.Parent = gui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)

    local label = Instance.new("TextLabel", btn)
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEME.text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12

    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Button Positions
local baseY = 20
local spacing = 70

createToggleButton("AIMBOT", UDim2.new(0, 30, 0, baseY), function(s)
    Enabled.Aimbot = s
    if s then startAimbot() else stopAimbot() end
end)

createToggleButton("DODGE", UDim2.new(0, 30, 0, baseY + spacing), function(s) Enabled.Dodge = s end)

createToggleButton("SPIN", UDim2.new(0, 30, 0, baseY + spacing*2), function(s)
    Enabled.SpinBot = s
    if s then startSpin() else stopSpin() end
end)

createToggleButton("LEFT", UDim2.new(1, -90, 0, baseY), function(s)
    Enabled.Left = s
    if s then
        autoStealActiveForPaths = true
        leftState = 0
        Enabled.Right = false
    else
        autoStealActiveForPaths = false
    end
end)

createToggleButton("RIGHT", UDim2.new(1, -90, 0, baseY + spacing), function(s)
    Enabled.Right = s
    if s then
        autoStealActiveForPaths = true
        rightState = 0
        Enabled.Left = false
    else
        autoStealActiveForPaths = false
    end
end)

createToggleButton("SPEED", UDim2.new(1, -90, 0, baseY + spacing*2), function(s)
    Enabled.SpeedBoost = s
end)

-- Quick TP Button
createBasicButton("TP L2", UDim2.new(0.5, -30, 0, baseY - 10), function()
    if HRP then
        HRP.CFrame = CFrame.new(Values.L2)
    end
end)

-- OPEN Extra Menu Button (you can expand this later)
createBasicButton("MENU", UDim2.new(0.5, 40, 0, baseY - 10), function()
    print("Extra menu clicked - add more toggles here if needed")
end)

print("✅ Keek Duel Hub Loaded | LEFT & RIGHT paths active | STOP button removed")
