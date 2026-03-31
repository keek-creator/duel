local Lib = Instance.new("ScreenGui")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

Lib.Name = "KeekDuel"
Lib.Parent = game:GetService("CoreGui")
Lib.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ========== AUTO DUEL VARIABLES ==========
local rightWaypoints = {
    Vector3.new(-473.04, -6.99, 29.71),
    Vector3.new(-483.57, -5.10, 18.74),
    Vector3.new(-475.00, -6.99, 26.43),
    Vector3.new(-474.67, -6.94, 105.48),
}

local leftWaypoints = {
    Vector3.new(-472.49, -7.00, 90.62),
    Vector3.new(-484.62, -5.10, 100.37),
    Vector3.new(-475.08, -7.00, 93.29),
    Vector3.new(-474.22, -6.96, 16.18),
}

local patrolMode = "none"
local floating = false
local currentWaypoint = 1
local heartbeatConn
local waitingForCountdownLeft = false
local waitingForCountdownRight = false
local AUTO_START_DELAY = 0.7

-- Bat Aimbot Variables
local batAimbotActive = false
local batAimbotConn = nil
local AimbotRadius = 100
local BatAimbotSpeed = 55

local SlapList = {
    {1, "Bat"}, {2, "Slap"}, {3, "Iron Slap"}, {4, "Gold Slap"},
    {5, "Diamond Slap"}, {6, "Emerald Slap"}, {7, "Ruby Slap"},
    {8, "Dark Matter Slap"}, {9, "Flame Slap"}, {10, "Nuclear Slap"},
    {11, "Galaxy Slap"}, {12, "Glitched Slap"}
}

-- ========== SPIN BOT VARIABLES ==========
local spinActive = false
local spinAngle = 0
local spinSpeed = 20
local spinAlign = nil
local spinAttachment = nil
local spinConn = nil

local function setupSpinBot()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if spinAlign then spinAlign:Destroy() end
    if spinAttachment then spinAttachment:Destroy() end

    spinAttachment = Instance.new("Attachment")
    spinAttachment.Parent = hrp

    spinAlign = Instance.new("AlignOrientation")
    spinAlign.Attachment0 = spinAttachment
    spinAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment
    spinAlign.Responsiveness = 30
    spinAlign.MaxTorque = math.huge
    spinAlign.RigidityEnabled = false
    spinAlign.Enabled = false
    spinAlign.Parent = hrp
end

local function startSpinBot()
    setupSpinBot()
    if spinAlign then spinAlign.Enabled = true end
    if spinConn then spinConn:Disconnect() end
    spinConn = RunService.Heartbeat:Connect(function(dt)
        if not spinActive then return end
        if not spinAlign or not spinAlign.Parent then
            setupSpinBot()
            if spinAlign then spinAlign.Enabled = true end
            return
        end
        spinAngle = spinAngle + spinSpeed * dt
        spinAlign.CFrame = CFrame.Angles(0, spinAngle, 0)
    end)
end

local function stopSpinBot()
    spinActive = false
    if spinConn then spinConn:Disconnect(); spinConn = nil end
    if spinAlign then spinAlign.Enabled = false end
end

-- ========== STEAL SPEED VARIABLES ==========
local stealSpeedActive = false
local stealSpeedConn = nil
local STEAL_SPEED_VALUE = 29

local function startStealSpeed()
    if stealSpeedConn then stealSpeedConn:Disconnect() end
    stealSpeedConn = RunService.Heartbeat:Connect(function()
        if not stealSpeedActive then return end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end
        if hum.MoveDirection.Magnitude > 0.1 then
            local moveDir = hum.MoveDirection.Unit
            root.AssemblyLinearVelocity = Vector3.new(
                moveDir.X * STEAL_SPEED_VALUE,
                root.AssemblyLinearVelocity.Y,
                moveDir.Z * STEAL_SPEED_VALUE
            )
        end
    end)
end

local function stopStealSpeed()
    if stealSpeedConn then
        stealSpeedConn:Disconnect()
        stealSpeedConn = nil
    end
end

-- ========== TP VARIABLES ==========
local tpFinalLeft  = Vector3.new(-483.59, -5.04, 104.24)
local tpFinalRight = Vector3.new(-483.51, -5.10, 18.89)
local tpCheckA     = Vector3.new(-472.60, -7.00, 57.52)
local tpCheckLeft  = Vector3.new(-472.65, -7.00, 95.69)
local tpCheckRight = Vector3.new(-471.76, -7.00, 26.22)

local lastTpSide = "none"
local ragdollDetectorConn = nil
local ragdollAutoActive = false

local function tpMove(pos)
    local char = player.Character
    if not char then return end
    char:PivotTo(CFrame.new(pos))
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) end
end

local function doTPLeft()
    tpMove(tpCheckA)
    task.wait(0.1)
    tpMove(tpCheckLeft)
    task.wait(0.1)
    tpMove(tpFinalLeft)
    lastTpSide = "left"
    print("TP Left done")
end

local function doTPRight()
    tpMove(tpCheckA)
    task.wait(0.1)
    tpMove(tpCheckRight)
    task.wait(0.1)
    tpMove(tpFinalRight)
    lastTpSide = "right"
    print("TP Right done")
end

local function isRagdolled(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum:GetState() == Enum.HumanoidStateType.Ragdoll then return true end
    local ragVal = char:FindFirstChild("Ragdoll") or char:FindFirstChild("IsRagdoll")
    if ragVal and ragVal:IsA("BoolValue") and ragVal.Value then return true end
    return false
end

local ragdollWasActive = false

-- ========== ANTI RAGDOLL ==========
local antiRagdollActive = false
local antiRagdollConn = nil

local function startAntiRagdoll()
    if antiRagdollConn then antiRagdollConn:Disconnect() end
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        if not antiRagdollActive then return end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then
            local state = hum:GetState()
            if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown then
                if not ragdollWasActive then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                    if workspace.CurrentCamera then
                        workspace.CurrentCamera.CameraSubject = hum
                    end
                    if root then
                        root.Velocity = Vector3.new(0, 0, 0)
                        root.RotVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and obj.Enabled == false then
                obj.Enabled = true
            end
        end
    end)
end

local function stopAntiRagdoll()
    if antiRagdollConn then
        antiRagdollConn:Disconnect()
        antiRagdollConn = nil
    end
end

-- ========== UNWALK ==========
local unwalkActive = false
local unwalkConn = nil

local function startUnwalk()
    if unwalkConn then unwalkConn:Disconnect() end
    unwalkConn = RunService.Heartbeat:Connect(function()
        if not unwalkActive then return end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then return end
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end)
end

local function stopUnwalk()
    if unwalkConn then
        unwalkConn:Disconnect()
        unwalkConn = nil
    end
end

local function startRagdollDetector()
    if ragdollDetectorConn then ragdollDetectorConn:Disconnect() end
    ragdollDetectorConn = RunService.Heartbeat:Connect(function()
        if not ragdollAutoActive then return end
        local char = player.Character
        if not char then return end
        local nowRagdolled = isRagdolled(char)
        if nowRagdolled and not ragdollWasActive then
            ragdollWasActive = true
            print("Ragdoll detected! Auto-TP + patrol on side:", lastTpSide)
            task.spawn(function()
                task.wait(0.15)
                if lastTpSide == "left" then
                    doTPLeft()
                    task.wait(0.2)
                    if patrolMode ~= "left" then
                        startMovement("left", buttons["autoleft"])
                    end
                elseif lastTpSide == "right" then
                    doTPRight()
                    task.wait(0.2)
                    if patrolMode ~= "right" then
                        startMovement("right", buttons["autoright"])
                    end
                end
            end)
        elseif not nowRagdolled then
            ragdollWasActive = false
        end
    end)
end

local function stopRagdollDetector()
    if ragdollDetectorConn then
        ragdollDetectorConn:Disconnect()
        ragdollDetectorConn = nil
    end
    ragdollWasActive = false
end

-- ========== AUTO STEAL VARIABLES ==========
local stealActive = false
local stealConn = nil
local animalCache = {}
local promptCache = {}
local stealCache = {}
local isStealing = false
local STEAL_R = 7

local AnimalsData = {}
pcall(function()
    local rep = game:GetService("ReplicatedStorage")
    local datas = rep:FindFirstChild("Datas")
    if datas then
        local animals = datas:FindFirstChild("Animals")
        if animals then AnimalsData = require(animals) end
    end
end)

local function stealHRP()
    local c = player.Character; if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso")
end

local function isMyBase(plotName)
    local plot = workspace.Plots and workspace.Plots:FindFirstChild(plotName); if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign"); if not sign then return false end
    local yb = sign:FindFirstChild("YourBase")
    return yb and yb:IsA("BillboardGui") and yb.Enabled == true
end

local function scanPlot(plot)
    if not plot or not plot:IsA("Model") then return end
    if isMyBase(plot.Name) then return end
    local podiums = plot:FindFirstChild("AnimalPodiums"); if not podiums then return end
    for _, pod in ipairs(podiums:GetChildren()) do
        if pod:IsA("Model") and pod:FindFirstChild("Base") then
            local name = "Unknown"
            local spawn = pod.Base:FindFirstChild("Spawn")
            if spawn then
                for _, child in ipairs(spawn:GetChildren()) do
                    if child:IsA("Model") and child.Name ~= "PromptAttachment" then
                        name = child.Name
                        local info = AnimalsData[name]
                        if info and info.DisplayName then name = info.DisplayName end
                        break
                    end
                end
            end
            table.insert(animalCache, {
                name = name, plot = plot.Name, slot = pod.Name,
                worldPosition = pod:GetPivot().Position,
                uid = plot.Name .. "_" .. pod.Name,
            })
        end
    end
end

local function findPrompt(ad)
    if not ad then return nil end
    local cp = promptCache[ad.uid]
    if cp and cp.Parent then return cp end
    local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end
    local plot = plots:FindFirstChild(ad.plot); if not plot then return nil end
    local pods = plot:FindFirstChild("AnimalPodiums"); if not pods then return nil end
    local pod = pods:FindFirstChild(ad.slot); if not pod then return nil end
    local base = pod:FindFirstChild("Base"); if not base then return nil end
    local sp = base:FindFirstChild("Spawn"); if not sp then return nil end
    local att = sp:FindFirstChild("PromptAttachment"); if not att then return nil end
    for _, p in ipairs(att:GetChildren()) do
        if p:IsA("ProximityPrompt") then 
            promptCache[ad.uid] = p
            return p 
        end
    end
end

local function buildCallbacks(prompt)
    if stealCache[prompt] then return end
    local data = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
    local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(c1) == "table" then
        for _, conn in ipairs(c1) do
            if type(conn.Function) == "function" then table.insert(data.holdCallbacks, conn.Function) end
        end
    end
    local ok2, c2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(c2) == "table" then
        for _, conn in ipairs(c2) do
            if type(conn.Function) == "function" then table.insert(data.triggerCallbacks, conn.Function) end
        end
    end
    if #data.holdCallbacks > 0 or #data.triggerCallbacks > 0 then stealCache[prompt] = data end
end

local function execSteal(prompt)
    local data = stealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false; isStealing = true
    task.spawn(function()
        for _, fn in ipairs(data.holdCallbacks) do task.spawn(fn) end
        task.wait(0.2)
        for _, fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end
        task.wait(0.01); data.ready = true; task.wait(0.01); isStealing = false
    end)
    return true
end

local function nearestAnimal()
    local hrp = stealHRP(); if not hrp then return nil end
    local best, bestD = nil, math.huge
    for _, ad in ipairs(animalCache) do
        if not isMyBase(ad.plot) and ad.worldPosition then
            local d = (hrp.Position - ad.worldPosition).Magnitude
            if d < bestD then bestD = d; best = ad end
        end
    end
    return best
end

local function startStealLoop()
    if stealConn then stealConn:Disconnect() end
    stealConn = RunService.Heartbeat:Connect(function()
        if not stealActive or isStealing then return end
        local target = nearestAnimal(); if not target then return end
        local hrp = stealHRP(); if not hrp then return end
        if (hrp.Position - target.worldPosition).Magnitude > STEAL_R then return end
        local prompt = promptCache[target.uid]
        if not prompt or not prompt.Parent then prompt = findPrompt(target) end
        if prompt then buildCallbacks(prompt); execSteal(prompt) end
    end)
end

local function stopStealLoop()
    if stealConn then stealConn:Disconnect(); stealConn = nil end
end

local stealInitialized = false
local function initSteal()
    if stealInitialized then return end
    stealInitialized = true
    task.spawn(function()
        task.wait(2)
        local plots = workspace:WaitForChild("Plots", 10); if not plots then return end
        for _, plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then scanPlot(plot) end end
        plots.ChildAdded:Connect(function(plot)
            if plot:IsA("Model") then task.wait(0.5); scanPlot(plot) end
        end)
        task.spawn(function()
            while task.wait(5) do
                animalCache = {}
                for _, plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then scanPlot(plot) end end
            end
        end)
    end)
    startStealLoop()
    print("Auto Steal initialized")
end

-- ========== AUTO DUEL HELPER FUNCTIONS ==========
local function isCountdownNumber(text)
    local num = tonumber(text)
    if num and num >= 1 and num <= 5 then
        return true, num
    end
    return false
end

local function isTimerInCountdown(label)
    if not label then return false end
    local ok, num = isCountdownNumber(label.Text)
    return ok and num >= 1 and num <= 5
end

local function getCurrentSpeed()
    if patrolMode == "right" or patrolMode == "left" then
        if currentWaypoint >= 3 then
            return 29.4
        else
            return 60
        end
    end
    return 0
end

local function getCurrentWaypoints()
    if patrolMode == "right" then
        return rightWaypoints
    elseif patrolMode == "left" then
        return leftWaypoints
    end
    return {}
end

local function updateButtonState(button, isActive, activeText, inactiveText)
    if isActive then
        button.BackgroundColor3 = Color3.fromRGB(130, 80, 255)
        button.BackgroundTransparency = 0.7
        button:FindFirstChild("StatusDot").BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        button:FindFirstChild("Label").Text = activeText
    else
        button.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        button.BackgroundTransparency = 0.15
        button:FindFirstChild("StatusDot").BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        button:FindFirstChild("Label").Text = inactiveText
    end
end

local function startMovement(mode, button)
    patrolMode = mode
    currentWaypoint = 1
    if mode == "right" then
        updateButtonState(button, true, "Auto Right [ON]", "Auto Right")
    else
        updateButtonState(button, true, "Auto Left [ON]", "Auto Left")
    end
end

local function stopMovement(rightButton, leftButton)
    patrolMode = "none"
    currentWaypoint = 1
    waitingForCountdownLeft = false
    waitingForCountdownRight = false
    
    updateButtonState(rightButton, false, "", "Auto Right")
    updateButtonState(leftButton, false, "", "Auto Left")
    
    local char = player.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
        end
    end
end

-- ========== BAT AIMBOT FUNCTIONS ==========
local function findBat()
    local c = player.Character
    if not c then return nil end
    local bp = player:FindFirstChildOfClass("Backpack")
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
    end
    for _, i in ipairs(SlapList) do
        local t = c:FindFirstChild(i[2]) or (bp and bp:FindFirstChild(i[2]))
        if t then return t end
    end
    return nil
end

local function findNearestEnemy(myHRP)
    local nearest = nil
    local nearestDist = math.huge
    local nearestTorso = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            local torso = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local d = (eh.Position - myHRP.Position).Magnitude
                if d < nearestDist and d <= AimbotRadius then
                    nearestDist = d
                    nearest = eh
                    nearestTorso = torso or eh
                end
            end
        end
    end
    return nearest, nearestDist, nearestTorso
end

local function startBatAimbot()
    if batAimbotConn then return end
    batAimbotConn = RunService.Heartbeat:Connect(function()
        local c = player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        
        local bat = findBat()
        if bat and bat.Parent ~= c then
            hum:EquipTool(bat)
        end
        
        local target, _, torso = findNearestEnemy(h)
        if target and torso then
            local Prediction = 0.13
            local PredictedPos = torso.Position + (torso.AssemblyLinearVelocity * Prediction)
            
            local dir = (P-- leaked by https://discord.gg/WfTDsBPR9n join for more sources cheap

local Lib = Instance.new("ScreenGui")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

Lib.Name = "KeekDuel"
Lib.Parent = game:GetService("CoreGui")
Lib.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ========== AUTO DUEL VARIABLES ==========
local rightWaypoints = {
    Vector3.new(-473.04, -6.99, 29.71),
    Vector3.new(-483.57, -5.10, 18.74),
    Vector3.new(-475.00, -6.99, 26.43),
    Vector3.new(-474.67, -6.94, 105.48),
}

local leftWaypoints = {
    Vector3.new(-472.49, -7.00, 90.62),
    Vector3.new(-484.62, -5.10, 100.37),
    Vector3.new(-475.08, -7.00, 93.29),
    Vector3.new(-474.22, -6.96, 16.18),
}

local patrolMode = "none"
local floating = false
local currentWaypoint = 1
local heartbeatConn
local waitingForCountdownLeft = false
local waitingForCountdownRight = false
local AUTO_START_DELAY = 0.7

-- Bat Aimbot Variables
local batAimbotActive = false
local batAimbotConn = nil
local AimbotRadius = 100
local BatAimbotSpeed = 55

local SlapList = {
    {1, "Bat"}, {2, "Slap"}, {3, "Iron Slap"}, {4, "Gold Slap"},
    {5, "Diamond Slap"}, {6, "Emerald Slap"}, {7, "Ruby Slap"},
    {8, "Dark Matter Slap"}, {9, "Flame Slap"}, {10, "Nuclear Slap"},
    {11, "Galaxy Slap"}, {12, "Glitched Slap"}
}

-- ========== SPIN BOT VARIABLES ==========
local spinActive = false
local spinAngle = 0
local spinSpeed = 20
local spinAlign = nil
local spinAttachment = nil
local spinConn = nil

local function setupSpinBot()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if spinAlign then spinAlign:Destroy() end
    if spinAttachment then spinAttachment:Destroy() end

    spinAttachment = Instance.new("Attachment")
    spinAttachment.Parent = hrp

    spinAlign = Instance.new("AlignOrientation")
    spinAlign.Attachment0 = spinAttachment
    spinAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment
    spinAlign.Responsiveness = 30
    spinAlign.MaxTorque = math.huge
    spinAlign.RigidityEnabled = false
    spinAlign.Enabled = false
    spinAlign.Parent = hrp
end

local function startSpinBot()
    setupSpinBot()
    if spinAlign then spinAlign.Enabled = true end
    if spinConn then spinConn:Disconnect() end
    spinConn = RunService.Heartbeat:Connect(function(dt)
        if not spinActive then return end
        if not spinAlign or not spinAlign.Parent then
            setupSpinBot()
            if spinAlign then spinAlign.Enabled = true end
            return
        end
        spinAngle = spinAngle + spinSpeed * dt
        spinAlign.CFrame = CFrame.Angles(0, spinAngle, 0)
    end)
end

local function stopSpinBot()
    spinActive = false
    if spinConn then spinConn:Disconnect(); spinConn = nil end
    if spinAlign then spinAlign.Enabled = false end
end

-- ========== STEAL SPEED VARIABLES ==========
local stealSpeedActive = false
local stealSpeedConn = nil
local STEAL_SPEED_VALUE = 29

local function startStealSpeed()
    if stealSpeedConn then stealSpeedConn:Disconnect() end
    stealSpeedConn = RunService.Heartbeat:Connect(function()
        if not stealSpeedActive then return end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end
        if hum.MoveDirection.Magnitude > 0.1 then
            local moveDir = hum.MoveDirection.Unit
            root.AssemblyLinearVelocity = Vector3.new(
                moveDir.X * STEAL_SPEED_VALUE,
                root.AssemblyLinearVelocity.Y,
                moveDir.Z * STEAL_SPEED_VALUE
            )
        end
    end)
end

local function stopStealSpeed()
    if stealSpeedConn then
        stealSpeedConn:Disconnect()
        stealSpeedConn = nil
    end
end

-- ========== TP VARIABLES ==========
local tpFinalLeft  = Vector3.new(-483.59, -5.04, 104.24)
local tpFinalRight = Vector3.new(-483.51, -5.10, 18.89)
local tpCheckA     = Vector3.new(-472.60, -7.00, 57.52)
local tpCheckLeft  = Vector3.new(-472.65, -7.00, 95.69)
local tpCheckRight = Vector3.new(-471.76, -7.00, 26.22)

local lastTpSide = "none"
local ragdollDetectorConn = nil
local ragdollAutoActive = false

local function tpMove(pos)
    local char = player.Character
    if not char then return end
    char:PivotTo(CFrame.new(pos))
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) end
end

local function doTPLeft()
    tpMove(tpCheckA)
    task.wait(0.1)
    tpMove(tpCheckLeft)
    task.wait(0.1)
    tpMove(tpFinalLeft)
    lastTpSide = "left"
    print("TP Left done")
end

local function doTPRight()
    tpMove(tpCheckA)
    task.wait(0.1)
    tpMove(tpCheckRight)
    task.wait(0.1)
    tpMove(tpFinalRight)
    lastTpSide = "right"
    print("TP Right done")
end

local function isRagdolled(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum:GetState() == Enum.HumanoidStateType.Ragdoll then return true end
    local ragVal = char:FindFirstChild("Ragdoll") or char:FindFirstChild("IsRagdoll")
    if ragVal and ragVal:IsA("BoolValue") and ragVal.Value then return true end
    return false
end

local ragdollWasActive = false

-- ========== ANTI RAGDOLL ==========
local antiRagdollActive = false
local antiRagdollConn = nil

local function startAntiRagdoll()
    if antiRagdollConn then antiRagdollConn:Disconnect() end
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        if not antiRagdollActive then return end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum then
            local state = hum:GetState()
            if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown then
                if not ragdollWasActive then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                    if workspace.CurrentCamera then
                        workspace.CurrentCamera.CameraSubject = hum
                    end
                    if root then
                        root.Velocity = Vector3.new(0, 0, 0)
                        root.RotVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and obj.Enabled == false then
                obj.Enabled = true
            end
        end
    end)
end

local function stopAntiRagdoll()
    if antiRagdollConn then
        antiRagdollConn:Disconnect()
        antiRagdollConn = nil
    end
end

-- ========== UNWALK ==========
local unwalkActive = false
local unwalkConn = nil

local function startUnwalk()
    if unwalkConn then unwalkConn:Disconnect() end
    unwalkConn = RunService.Heartbeat:Connect(function()
        if not unwalkActive then return end
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then return end
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end)
end

local function stopUnwalk()
    if unwalkConn then
        unwalkConn:Disconnect()
        unwalkConn = nil
    end
end

local function startRagdollDetector()
    if ragdollDetectorConn then ragdollDetectorConn:Disconnect() end
    ragdollDetectorConn = RunService.Heartbeat:Connect(function()
        if not ragdollAutoActive then return end
        local char = player.Character
        if not char then return end
        local nowRagdolled = isRagdolled(char)
        if nowRagdolled and not ragdollWasActive then
            ragdollWasActive = true
            print("Ragdoll detected! Auto-TP + patrol on side:", lastTpSide)
            task.spawn(function()
                task.wait(0.15)
                if lastTpSide == "left" then
                    doTPLeft()
                    task.wait(0.2)
                    if patrolMode ~= "left" then
                        startMovement("left", buttons["autoleft"])
                    end
                elseif lastTpSide == "right" then
                    doTPRight()
                    task.wait(0.2)
                    if patrolMode ~= "right" then
                        startMovement("right", buttons["autoright"])
                    end
                end
            end)
        elseif not nowRagdolled then
            ragdollWasActive = false
        end
    end)
end

local function stopRagdollDetector()
    if ragdollDetectorConn then
        ragdollDetectorConn:Disconnect()
        ragdollDetectorConn = nil
    end
    ragdollWasActive = false
end

-- ========== AUTO STEAL VARIABLES ==========
local stealActive = false
local stealConn = nil
local animalCache = {}
local promptCache = {}
local stealCache = {}
local isStealing = false
local STEAL_R = 7

local AnimalsData = {}
pcall(function()
    local rep = game:GetService("ReplicatedStorage")
    local datas = rep:FindFirstChild("Datas")
    if datas then
        local animals = datas:FindFirstChild("Animals")
        if animals then AnimalsData = require(animals) end
    end
end)

local function stealHRP()
    local c = player.Character; if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso")
end

local function isMyBase(plotName)
    local plot = workspace.Plots and workspace.Plots:FindFirstChild(plotName); if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign"); if not sign then return false end
    local yb = sign:FindFirstChild("YourBase")
    return yb and yb:IsA("BillboardGui") and yb.Enabled == true
end

local function scanPlot(plot)
    if not plot or not plot:IsA("Model") then return end
    if isMyBase(plot.Name) then return end
    local podiums = plot:FindFirstChild("AnimalPodiums"); if not podiums then return end
    for _, pod in ipairs(podiums:GetChildren()) do
        if pod:IsA("Model") and pod:FindFirstChild("Base") then
            local name = "Unknown"
            local spawn = pod.Base:FindFirstChild("Spawn")
            if spawn then
                for _, child in ipairs(spawn:GetChildren()) do
                    if child:IsA("Model") and child.Name ~= "PromptAttachment" then
                        name = child.Name
                        local info = AnimalsData[name]
                        if info and info.DisplayName then name = info.DisplayName end
                        break
                    end
                end
            end
            table.insert(animalCache, {
                name = name, plot = plot.Name, slot = pod.Name,
                worldPosition = pod:GetPivot().Position,
                uid = plot.Name .. "_" .. pod.Name,
            })
        end
    end
end

local function findPrompt(ad)
    if not ad then return nil end
    local cp = promptCache[ad.uid]
    if cp and cp.Parent then return cp end
    local plots = workspace:FindFirstChild("Plots"); if not plots then return nil end
    local plot = plots:FindFirstChild(ad.plot); if not plot then return nil end
    local pods = plot:FindFirstChild("AnimalPodiums"); if not pods then return nil end
    local pod = pods:FindFirstChild(ad.slot); if not pod then return nil end
    local base = pod:FindFirstChild("Base"); if not base then return nil end
    local sp = base:FindFirstChild("Spawn"); if not sp then return nil end
    local att = sp:FindFirstChild("PromptAttachment"); if not att then return nil end
    for _, p in ipairs(att:GetChildren()) do
        if p:IsA("ProximityPrompt") then 
            promptCache[ad.uid] = p
            return p 
        end
    end
end

local function buildCallbacks(prompt)
    if stealCache[prompt] then return end
    local data = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
    local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(c1) == "table" then
        for _, conn in ipairs(c1) do
            if type(conn.Function) == "function" then table.insert(data.holdCallbacks, conn.Function) end
        end
    end
    local ok2, c2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(c2) == "table" then
        for _, conn in ipairs(c2) do
            if type(conn.Function) == "function" then table.insert(data.triggerCallbacks, conn.Function) end
        end
    end
    if #data.holdCallbacks > 0 or #data.triggerCallbacks > 0 then stealCache[prompt] = data end
end

local function execSteal(prompt)
    local data = stealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false; isStealing = true
    task.spawn(function()
        for _, fn in ipairs(data.holdCallbacks) do task.spawn(fn) end
        task.wait(0.2)
        for _, fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end
        task.wait(0.01); data.ready = true; task.wait(0.01); isStealing = false
    end)
    return true
end

local function nearestAnimal()
    local hrp = stealHRP(); if not hrp then return nil end
    local best, bestD = nil, math.huge
    for _, ad in ipairs(animalCache) do
        if not isMyBase(ad.plot) and ad.worldPosition then
            local d = (hrp.Position - ad.worldPosition).Magnitude
            if d < bestD then bestD = d; best = ad end
        end
    end
    return best
end

local function startStealLoop()
    if stealConn then stealConn:Disconnect() end
    stealConn = RunService.Heartbeat:Connect(function()
        if not stealActive or isStealing then return end
        local target = nearestAnimal(); if not target then return end
        local hrp = stealHRP(); if not hrp then return end
        if (hrp.Position - target.worldPosition).Magnitude > STEAL_R then return end
        local prompt = promptCache[target.uid]
        if not prompt or not prompt.Parent then prompt = findPrompt(target) end
        if prompt then buildCallbacks(prompt); execSteal(prompt) end
    end)
end

local function stopStealLoop()
    if stealConn then stealConn:Disconnect(); stealConn = nil end
end

local stealInitialized = false
local function initSteal()
    if stealInitialized then return end
    stealInitialized = true
    task.spawn(function()
        task.wait(2)
        local plots = workspace:WaitForChild("Plots", 10); if not plots then return end
        for _, plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then scanPlot(plot) end end
        plots.ChildAdded:Connect(function(plot)
            if plot:IsA("Model") then task.wait(0.5); scanPlot(plot) end
        end)
        task.spawn(function()
            while task.wait(5) do
                animalCache = {}
                for _, plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then scanPlot(plot) end end
            end
        end)
    end)
    startStealLoop()
    print("Auto Steal initialized")
end

-- ========== AUTO DUEL HELPER FUNCTIONS ==========
local function isCountdownNumber(text)
    local num = tonumber(text)
    if num and num >= 1 and num <= 5 then
        return true, num
    end
    return false
end

local function isTimerInCountdown(label)
    if not label then return false end
    local ok, num = isCountdownNumber(label.Text)
    return ok and num >= 1 and num <= 5
end

local function getCurrentSpeed()
    if patrolMode == "right" or patrolMode == "left" then
        if currentWaypoint >= 3 then
            return 29.4
        else
            return 60
        end
    end
    return 0
end

local function getCurrentWaypoints()
    if patrolMode == "right" then
        return rightWaypoints
    elseif patrolMode == "left" then
        return leftWaypoints
    end
    return {}
end

local function updateButtonState(button, isActive, activeText, inactiveText)
    if isActive then
        button.BackgroundColor3 = Color3.fromRGB(130, 80, 255)
        button.BackgroundTransparency = 0.7
        button:FindFirstChild("StatusDot").BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        button:FindFirstChild("Label").Text = activeText
    else
        button.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        button.BackgroundTransparency = 0.15
        button:FindFirstChild("StatusDot").BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        button:FindFirstChild("Label").Text = inactiveText
    end
end

local function startMovement(mode, button)
    patrolMode = mode
    currentWaypoint = 1
    if mode == "right" then
        updateButtonState(button, true, "Auto Right [ON]", "Auto Right")
    else
        updateButtonState(button, true, "Auto Left [ON]", "Auto Left")
    end
end

local function stopMovement(rightButton, leftButton)
    patrolMode = "none"
    currentWaypoint = 1
    waitingForCountdownLeft = false
    waitingForCountdownRight = false
    
    updateButtonState(rightButton, false, "", "Auto Right")
    updateButtonState(leftButton, false, "", "Auto Left")
    
    local char = player.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
        end
    end
end

-- ========== BAT AIMBOT FUNCTIONS ==========
local function findBat()
    local c = player.Character
    if not c then return nil end
    local bp = player:FindFirstChildOfClass("Backpack")
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
    end
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end
        end
    end
    for _, i in ipairs(SlapList) do
        local t = c:FindFirstChild(i[2]) or (bp and bp:FindFirstChild(i[2]))
        if t then return t end
    end
    return nil
end

local function findNearestEnemy(myHRP)
    local nearest = nil
    local nearestDist = math.huge
    local nearestTorso = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            local torso = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 then
                local d = (eh.Position - myHRP.Position).Magnitude
                if d < nearestDist and d <= AimbotRadius then
                    nearestDist = d
                    nearest = eh
                    nearestTorso = torso or eh
                end
            end
        end
    end
    return nearest, nearestDist, nearestTorso
end

local function startBatAimbot()
    if batAimbotConn then return end
    
    batAimbotConn = RunService.Heartbeat:Connect(function()
        local c = player.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        
        local bat = findBat()
        if bat and bat.Parent ~= c then
            hum:EquipTool(bat)
        end
        
        local target, dist, torso = findNearestEnemy(h)
        
        if target and torso then
            -- Prediction
            local Prediction = 0.13
            local PredictedPos = torso.Position + (torso.AssemblyLinearVelocity * Prediction)
            
            -- Move toward target
            local myPos = h.Position
            local dir = (PredictedPos - myPos)
            
            if dir.Magnitude > 1.5 then
                local moveDir = dir.Unit
                local targetVel = moveDir * BatAimbotSpeed
                h.AssemblyLinearVelocity = targetVel
            else
                h.AssemblyLinearVelocity = target.AssemblyLinearVelocity
            end
        end
    end)
end

local function stopBatAimbot()
    if batAimbotConn then
        batAimbotConn:Disconnect()
        batAimbotConn = nil
    end
end

-- Bat Aimbot Button
buttons["Bat Aimbot"].MouseButton1Click:Connect(function()
    batAimbotActive = not batAimbotActive
    if batAimbotActive then
        updateButtonState(buttons["Bat Aimbot"], true, "Bat Aimbot [ON]", "Bat Aimbot")
        startBatAimbot()
        print("Bat Aimbot ON")
    else
        updateButtonState(buttons["Bat Aimbot"], false, "", "Bat Aimbot")
        stopBatAimbot()
        print("Bat Aimbot OFF")
    end
end)

-- ========== UPDATE WALKING ==========
local function updateWalking()
    local char = player.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end

    local currentVel = root.AssemblyLinearVelocity

    if floating then
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {char}

        local raycastResult = workspace:Raycast(root.Position, Vector3.new(0, -50, 0), raycastParams)

        if raycastResult then
            local groundY = raycastResult.Position.Y
            local targetY = groundY + 8
            local currentY = root.Position.Y
            local yDifference = targetY - currentY

            if math.abs(yDifference) > 0.3 then
                root.AssemblyLinearVelocity = Vector3.new(
                    currentVel.X,
                    yDifference * 15,
                    currentVel.Z
                )
            else
                root.AssemblyLinearVelocity = Vector3.new(
                    currentVel.X,
                    0,
                    currentVel.Z
                )
            end
        end
    end

    if patrolMode ~= "none" then
        local waypoints = getCurrentWaypoints()
        local targetPos = waypoints[currentWaypoint]
        local currentPos = root.Position

        local targetXZ = Vector3.new(targetPos.X, 0, targetPos.Z)
        local currentXZ = Vector3.new(currentPos.X, 0, currentPos.Z)
        local distanceXZ = (targetXZ - currentXZ).Magnitude

        if distanceXZ > 3 then
            local moveDirection = (targetXZ - currentXZ).Unit
            local currentSpeed = getCurrentSpeed()

            root.AssemblyLinearVelocity = Vector3.new(
                moveDirection.X * currentSpeed,
                root.AssemblyLinearVelocity.Y,
                moveDirection.Z * currentSpeed
            )
        else
            if currentWaypoint == #waypoints then
                patrolMode = "none"
                currentWaypoint = 1
                waitingForCountdownLeft = false
                waitingForCountdownRight = false

                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                print("Path completed")

                if lastTpSide == "left" then
                    print("Restarting Auto Left (TP side)")
                    task.spawn(function() startMovement("left", buttons["autoleft"]) end)
                elseif lastTpSide == "right" then
                    print("Restarting Auto Right (TP side)")
                    task.spawn(function() startMovement("right", buttons["autoright"]) end)
                else
                    print("No TP side set - stopped")
                end
            else
                currentWaypoint = currentWaypoint + 1
                local speed = getCurrentSpeed()
                local modeText = (patrolMode == "right") and "AutoRight" or "AutoLeft"
                local speedText = (speed == 60) and "60" or "30"
                print("heading to " .. modeText .. " spot " .. currentWaypoint .. " @ " .. speedText)
            end
        end
    end
end

-- ========== START HEARTBEAT ==========
heartbeatConn = RunService.Heartbeat:Connect(updateWalking)

-- ========== CHARACTER RESPAWN HANDLER ==========
player.CharacterAdded:Connect(function()
    task.wait(1)
    patrolMode = "none"
    currentWaypoint = 1
    waitingForCountdownLeft = false
    waitingForCountdownRight = false
    floating = false
    batAimbotActive = false

    updateButtonState(buttons["autoright"], false, "", "Auto Right")
    updateButtonState(buttons["autoleft"], false, "", "Auto Left")
    updateButtonState(buttons["float"], false, "", "Float")
    updateButtonState(buttons["Bat Aimbot"], false, "", "Bat Aimbot")
    
    -- Stop bat aimbot on respawn
    stopBatAimbot()
    -- Reset TP state on respawn
    ragdollAutoActive = false
    ragdollWasActive = false
    updateButtonState(buttons["TP [Left]"], false, "", "TP [Left]")
    updateButtonState(buttons["TP [Right]"], false, "", "TP [Right]")
    -- Restart persistent features if they were active
    if antiRagdollActive then startAntiRagdoll() end
    if unwalkActive then startUnwalk() end
    if stealSpeedActive then startStealSpeed() end
    if spinActive then startSpinBot() end
end)

-- ========== COUNTDOWN DETECTION ==========
local function onTextChanged(label)
    local text = label.Text
    local ok, number = isCountdownNumber(text)

    if ok then
        print("Countdown detected:", number)

        if number == 1 then
            if waitingForCountdownLeft then
                print("Countdown finished! Starting auto left in", AUTO_START_DELAY, "seconds")
                task.wait(AUTO_START_DELAY)
                waitingForCountdownLeft = false
                startMovement("left", buttons["autoleft"])
            end

            if waitingForCountdownRight then
                print("Countdown finished! Starting auto right in", AUTO_START_DELAY, "seconds")
                task.wait(AUTO_START_DELAY)
                waitingForCountdownRight = false
                startMovement("right", buttons["autoright"])
            end
        end
    end
end

spawn(function()
    local success, label = pcall(function()
        return player.PlayerGui
            :FindFirstChild("DuelsMachineTopFrame")
            and player.PlayerGui.DuelsMachineTopFrame
            :FindFirstChild("DuelsMachineTopFrame")
            and player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame
            :FindFirstChild("Timer")
            and player.PlayerGui.DuelsMachineTopFrame.DuelsMachineTopFrame.Timer
            :FindFirstChild("Label")
    end)

    if success and label then
        print("Timer label found! Countdown detection enabled.")
        onTextChanged(label)
        label:GetPropertyChangedSignal("Text"):Connect(function()
            onTextChanged(label)
        end)
    else
        print("Timer label not found. Auto movements will start immediately.")
    end
end)

-- ========== CLEANUP ==========
Lib.Destroying:Connect(function()
    if heartbeatConn then
        heartbeatConn:Disconnect()
    end
end)

print("Keek Duel loaded successfully!")
