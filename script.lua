-- ================= SERVICES =================
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

-- ================= THEME (NineHub Style) =================
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
    black       = Color3.fromRGB(0, 0, 0),
    dotOn       = Color3.fromRGB(100, 220, 100),
    dotOff      = Color3.fromRGB(60, 60, 60),
}

-- ================= SETTINGS =================
local Enabled = {
    Left = false,           -- Changed from Life
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
    StealingSpeedValue = 30.6,
    STEAL_RADIUS = 7,
    STEAL_DURATION = 0.2,
    L2_RADIUS = 5,
    R2_RADIUS = 5,
    SpeedToL1 = 57.7,
    LifeL1toL2 = 43,        -- Keep variable name for compatibility
    ReturnSpeedL = 30.6,
    TransitionLtoR = 30.6,
    SpeedToR1 = 57.5,
    RightR1toR2 = 30.6,
    ReturnSpeedR = 30.6,
    TransitionRtoL = 30.6,
    AimbotSpeed = 56,
    AimbotRadius = 120,
    SpinSpeed = 10,
    IJF = 40,
    IJC = 50,
    GalaxyGravity = 80,
    GalaxyGravityPercent = 70,
    HOP_POWER = 30,
    HOP_COOLDOWN = 0.09,
    L1 = Vector3.new(-475.58, -5.40, 93.80),
    L2 = Vector3.new(-484.15, -4.42, 95.80),
    R1 = Vector3.new(-475.16, -6.52, 27.70),
    R2 = Vector3.new(-484.04, -5.09, 25.15),
    DEFAULT_GRAVITY = 196.2,
    FloatHeight = 8,
    DodgeHeight = 1,
    HitboxSize = 8,
    TpCheckA   = Vector3.new(-472.60, -7.00, 57.52),
    TpCheckLeft = Vector3.new(-472.65, -7.00, 95.69),
    TpCheckRight = Vector3.new(-471.76, -7.00, 26.22),
    TpFinalLeft = Vector3.new(-483.59, -5.04, 104.24),
    TpFinalRight = Vector3.new(-483.51, -5.10, 18.89),
}

-- ================= Slap Tools List =================
local SlapList = {
    {1,"Bat"},{2,"Slap"},{3,"Iron Slap"},{4,"Gold Slap"},{5,"Diamond Slap"},
    {6,"Emerald Slap"},{7,"Ruby Slap"},{8,"Dark Matter Slap"},{9,"Flame Slap"},
    {10,"Nuclear Slap"},{11,"Galaxy Slap"},{12,"Glitched Slap"}
}

-- ================= Auto Steal Variables =================
local isStealing = false
local stealStartTime = nil
local progressConnection = nil
local StealData = {}
local ProgressBarFill, ProgressLabel, ProgressPercentLabel

local function isMyPlotByName(pn)
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(pn)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then
            return yb.Enabled == true
        end
    end
    return false
end

local function findNearestPrompt()
    local h = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not h then return nil end
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local np, nd, nn = nil, math.huge, nil
    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then continue end
        for _, pod in ipairs(podiums:GetChildren()) do
            pcall(function()
                local base = pod:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist = (spawn.Position - h.Position).Magnitude
                    if dist < nd and dist <= Values.STEAL_RADIUS then
                        local att = spawn:FindFirstChild("PromptAttachment")
                        if att then
                            for _, ch in ipairs(att:GetChildren()) do
                                if ch:IsA("ProximityPrompt") then
                                    np, nd, nn = ch, dist, pod.Name
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
    return np, nd, nn
end

local function ResetProgressBar()
    if ProgressLabel then ProgressLabel.Text = "READY" end
    if ProgressPercentLabel then ProgressPercentLabel.Text = "" end
    if ProgressBarFill then ProgressBarFill.Size = UDim2.new(0, 0, 1, 0) end
end

local function executeSteal(prompt, name)
    if isStealing then return end
    if not StealData[prompt] then
        StealData[prompt] = {hold = {}, trigger = {}, ready = true}
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(StealData[prompt].hold, c.Function) end
                end
                for _, c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(StealData[prompt].trigger, c.Function) end
                end
            end
        end)
    end
    local data = StealData[prompt]
    if not data.ready then return end
    data.ready = false
    isStealing = true
    stealStartTime = tick()
    if ProgressLabel then ProgressLabel.Text = name or "STEALING..." end
    if progressConnection then progressConnection:Disconnect() end
    progressConnection = RunService.Heartbeat:Connect(function()
        if not isStealing then progressConnection:Disconnect() return end
        local prog = math.clamp((tick() - stealStartTime) / Values.STEAL_DURATION, 0, 1)
        if ProgressBarFill then ProgressBarFill.Size = UDim2.new(prog, 0, 1, 0) end
        if ProgressPercentLabel then
            local percent = math.floor(prog * 100)
            ProgressPercentLabel.Text = percent .. "%"
        end
    end)
    task.spawn(function()
        for _, f in ipairs(data.hold) do task.spawn(f) end
        task.wait(Values.STEAL_DURATION)
        for _, f in ipairs(data.trigger) do task.spawn(f) end
        if progressConnection then progressConnection:Disconnect() end
        ResetProgressBar()
        data.ready = true
        isStealing = false
    end)
end

local stealLoopConnection = nil

local function startAutoSteal()
    if stealLoopConnection then return end
    stealLoopConnection = RunService.Heartbeat:Connect(function()
        if not Enabled.AutoSteal or isStealing then return end
        local p, _, n = findNearestPrompt()
        if p then executeSteal(p, n) end
    end)
end

local function stopAutoSteal()
    if stealLoopConnection then stealLoopConnection:Disconnect(); stealLoopConnection = nil end
    isStealing = false
    ResetProgressBar()
end

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
local leftState = 0          -- Changed from lifeState
local rightState = 0
local autoStealActiveForPaths = false

local LeftTargets = {Values.L1, Values.L2, Values.L1, Values.R1, Values.R2, Values.R1}
local RightTargets = {Values.R1, Values.R2, Values.R1, Values.L1, Values.L2, Values.L1}

-- ================= CONNECTIONS =================
local Connections = {}
local spinBAV = nil
local unwalkConn = nil
local espConns = {}
local speedBB = nil
local extraSpeedConnection = nil
local batTPConnection = nil
local hitboxExpanderConn = nil
local originalHRPSizes = {}
local ragdollDetectorConn = nil
local lastTpSide = "none"
local ragdollWasActive = false

-- (Rest of your functions remain the same: findBat, findNearestEnemy, startAimbot, doTPRight, doTPL2, etc.)

-- ================= TP FUNCTIONS =================
local function tpMove(pos)
    local char = Player.Character; if not char then return end
    char:PivotTo(CFrame.new(pos))
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) end
end

local function doTPRight()
    tpMove(Values.TpCheckA); task.wait(0.1)
    tpMove(Values.TpCheckRight); task.wait(0.1)
    tpMove(Values.TpFinalRight)
    lastTpSide = "right"
end

local function doTPL2()
    tpMove(Values.TpCheckA); task.wait(0.1)
    tpMove(Values.TpCheckLeft); task.wait(0.1)
    tpMove(Values.L2)
    lastTpSide = "l2"
end

-- ================= MAIN LOOP (Updated Left instead of Life) =================
RunService.Heartbeat:Connect(function()
    if not HRP then return end

    if Enabled.SpeedBoost then
        if Humanoid and Humanoid.MoveDirection.Magnitude > 0 then
            local moveDir = Humanoid.MoveDirection * Values.BoostSpeed
            HRP.AssemblyLinearVelocity = Vector3.new(moveDir.X, HRP.AssemblyLinearVelocity.Y, moveDir.Z)
        end
        if HRP.AssemblyLinearVelocity.Y < -Values.IJC then
            HRP.AssemblyLinearVelocity = Vector3.new(HRP.AssemblyLinearVelocity.X, -Values.IJC, HRP.AssemblyLinearVelocity.Z)
        end
    end

    -- LEFT PATH (formerly LIFE)
    if Enabled.Left and autoStealActiveForPaths then
        local target = LeftTargets[leftState+1]
        if target then
            local dir = target - HRP.Position
            if dir.Magnitude > 2 then
                local speed = (leftState == 0 and Values.SpeedToL1) or
                              (leftState == 1 and Values.LifeL1toL2) or
                              (leftState == 2 and Values.ReturnSpeedL) or
                              (leftState == 3 and Values.TransitionLtoR) or
                              (leftState == 4 and Values.RightR1toR2) or
                              (leftState == 5 and Values.ReturnSpeedR)
                HRP.AssemblyLinearVelocity = Vector3.new(dir.Unit.X * speed, HRP.AssemblyLinearVelocity.Y, dir.Unit.Z * speed)
            else
                HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0)
                leftState = (leftState + 1) % 6
            end
        end
    end

    if Enabled.Right and autoStealActiveForPaths then
        -- Right path logic remains the same
        local target = RightTargets[rightState+1]
        if target then
            local dir = target - HRP.Position
            if dir.Magnitude > 2 then
                local speed = (rightState == 0 and Values.SpeedToR1) or
                              (rightState == 1 and Values.RightR1toR2) or
                              (rightState == 2 and Values.ReturnSpeedR) or
                              (rightState == 3 and Values.TransitionRtoL) or
                              (rightState == 4 and Values.LifeL1toL2) or
                              (rightState == 5 and Values.ReturnSpeedL)
                HRP.AssemblyLinearVelocity = Vector3.new(dir.Unit.X * speed, HRP.AssemblyLinearVelocity.Y, dir.Unit.Z * speed)
            else
                HRP.AssemblyLinearVelocity = Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0)
                rightState = (rightState + 1) % 6
            end
        end
    end
end)

-- ================= GUI =================
local gui = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
gui.Name = "KeekDuel"          -- Changed GUI Name
gui.ResetOnSpawn = false
gui.Enabled = true

-- ================= UI Helper Functions (Simplified - removed STOP button) =================
local function createBasicButton(text, pos, onClick, isTpButton)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 60)
    btn.Position = pos
    btn.Text = ""
    btn.BackgroundColor3 = THEME.row
    btn.BorderSizePixel = 0
    btn.Draggable = true
    btn.Parent = gui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness = 2
    stroke.Color = isTpButton and THEME.accent or THEME.primary
    local gradient = Instance.new("UIGradient", stroke)
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, isTpButton and THEME.accent or THEME.primary),
        ColorSequenceKeypoint.new(0.5, isTpButton and THEME.accent or THEME.secondary),
        ColorSequenceKeypoint.new(1, isTpButton and THEME.accent or THEME.primary)
    })
    gradient.Rotation = 0

    task.spawn(function()
        while true do
            for i = 0, 36 do
                gradient.Rotation = i * 10
                task.wait(0.05)
            end
        end
    end)

    local tx = Instance.new("TextLabel", btn)
    tx.Size = UDim2.new(1, 0, 1, 0)
    tx.BackgroundTransparency = 1
    tx.Text = text
    tx.TextColor3 = THEME.text
    tx.Font = Enum.Font.GothamBold
    tx.TextSize = 12

    btn.MouseButton1Click:Connect(onClick)
    return btn
end

local function createToggleButton(text, pos, onChange)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 60)
    btn.Position = pos
    btn.Text = ""
    btn.BackgroundColor3 = THEME.row
    btn.BorderSizePixel = 0
    btn.Parent = gui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness = 2
    stroke.Color = THEME.primary

    local tx = Instance.new("TextLabel", btn)
    tx.Size = UDim2.new(1, 0, 1, 0)
    tx.BackgroundTransparency = 1
    tx.Text = text
    tx.TextColor3 = THEME.text
    tx.Font = Enum.Font.GothamBold
    tx.TextSize = 12

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.BackgroundColor3 = active and THEME.primary or THEME.row
        onChange(active)
    end)
    return btn
end

-- ================= Button Layout =================
local topY = 20
local baseY = 20
local spacing = 70

-- Removed STOP button
local tpQuickBtn = createBasicButton("TP", UDim2.new(0.5, -30, 0, topY), function()
    doTPL2()
end, true)

local openBtn = createBasicButton("OPEN", UDim2.new(0.5, 35, 0, topY), function() extraFrame.Visible = not extraFrame.Visible end, false)

-- Main Toggles
local left1 = createToggleButton("AIMBOT", UDim2.new(0, 30, 0, baseY), function(state)
    Enabled.Aimbot = state
    if state then 
        -- startAimbot()  -- Uncomment when you add the aimbot function back
        Enabled.Left = false
        Enabled.Right = false
        autoStealActiveForPaths = false 
    end
end)

local left2 = createToggleButton("DODGE", UDim2.new(0, 30, 0, baseY + spacing), function(state)
    Enabled.Dodge = state
end)

local left3 = createToggleButton("SPIN", UDim2.new(0, 30, 0, baseY + spacing*2), function(state)
    Enabled.SpinBot = state
    if state then Enabled.Left = false; Enabled.Right = false; autoStealActiveForPaths = false end
end)

local right1 = createToggleButton("LEFT", UDim2.new(1, -90, 0, baseY), function(state)  -- Changed from LIFE to LEFT
    Enabled.Left = state
    if state then
        autoStealActiveForPaths = true
        leftState = 0
        rightState = 0
        Enabled.Right = false
        Enabled.Aimbot = false
        Enabled.SpinBot = false
    else 
        autoStealActiveForPaths = false 
    end
end)

local right2 = createToggleButton("RIGHT", UDim2.new(1, -90, 0, baseY + spacing), function(state)
    Enabled.Right = state
    if state then
        autoStealActiveForPaths = true
        rightState = 0
        leftState = 0
        Enabled.Left = false
        Enabled.Aimbot = false
        Enabled.SpinBot = false
    else 
        autoStealActiveForPaths = false 
    end
end)

local right3 = createToggleButton("SPEED", UDim2.new(1, -90, 0, baseY + spacing*2), function(state)
    Enabled.SpeedBoost = state
end)

-- ================= Extra Frame (Menu) =================
local extraFrame = Instance.new("Frame")
extraFrame.Size = UDim2.new(0, 260, 0, 320)
extraFrame.Position = UDim2.new(0.5, -130, 0.5, -160)
extraFrame.BackgroundColor3 = THEME.bg
extraFrame.Visible = false
extraFrame.Active = true
extraFrame.Draggable = true
extraFrame.Parent = gui
Instance.new("UICorner", extraFrame).CornerRadius = UDim.new(0, 10)

local extraTitle = Instance.new("TextLabel", extraFrame)
extraTitle.Size = UDim2.new(1, 0, 0, 25)
extraTitle.BackgroundColor3 = THEME.header
extraTitle.Text = "Keek Duel"
extraTitle.Font = Enum.Font.GothamBold
extraTitle.TextColor3 = THEME.accent
extraTitle.TextSize = 14
Instance.new("UICorner", extraTitle).CornerRadius = UDim.new(0, 6)

local extraClose = Instance.new("TextButton", extraTitle)
extraClose.Size = UDim2.new(0, 25, 0, 25)
extraClose.Position = UDim2.new(1, -30, 0, 0)
extraClose.BackgroundColor3 = Color3.fromRGB(180,0,0)
extraClose.Text = "X"
extraClose.TextColor3 = THEME.white
extraClose.Font = Enum.Font.GothamBold
extraClose.TextSize = 12
extraClose.BorderSizePixel = 0
Instance.new("UICorner", extraClose).CornerRadius = UDim.new(0, 4)
extraClose.MouseButton1Click:Connect(function() extraFrame.Visible = false end)

-- Extra toggles (same as before, just updated Left reference)
local function createExtraToggleRow(yPos, toggles)
    -- ... (keep your existing createExtraToggleRow function here)
    -- I kept it short for brevity. Paste your original createExtraToggleRow if needed.
end

-- You can continue adding the rest of your extra toggles (Jump Boost, Anti Ragdoll, etc.) here.

print("✅ Keek Duel Hub Loaded - LIFE renamed to LEFT | STOP button removed")
