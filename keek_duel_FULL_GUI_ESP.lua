repeat task.wait() until game:IsLoaded()

--// SERVICES //
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
-- // [2] ANTI-LAG CONFIGURATION //
local CONFIG = {
	AntiLag = {
		GlobalShadows = false,
		FogEnd = 9000000000,
		Brightness = 1,
		EnvironmentDiffuseScale = 0,
		EnvironmentSpecularScale = 0,
	},
}


--// DESYNC VARIABLES //
local desyncEnabled = false
local desyncConnection = nil

--// VARIABLES & STATE //
local player = Players.LocalPlayer
local LocalPlayer = player
local FILE_NAME = "keekduelConfig.json"

--// ANTI RAGDOLL //
local anti = {}
local antiMode = nil
local ragConns = {}
local charCache = {}
local antiRagdollEnabled = true -- toggle

local function cacheChar()
    local c = player.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    if not h or not r then return false end
    charCache = {
        char = c,
        hum = h,
        root = r
    }
    return true
end

local function killConns()
    for _, c in pairs(ragConns) do
        pcall(function() c:Disconnect() end)
    end
    ragConns = {}
end

local function isRagdoll()
    if not charCache.hum then return false end
    local s = charCache.hum:GetState()
    if s == Enum.HumanoidStateType.Physics 
    or s == Enum.HumanoidStateType.Ragdoll 
    or s == Enum.HumanoidStateType.FallingDown then
        return true
    end

    local et = player:GetAttribute("RagdollEndTime")
    if et then
        local n = workspace:GetServerTimeNow()
        if (et - n) > 0 then
            return true
        end
    end

    return false
end

local function removeCons()
    if not charCache.char then return end
    for _, d in pairs(charCache.char:GetDescendants()) do
        if d:IsA("BallSocketConstraint") 
        or (d:IsA("Attachment") and string.find(d.Name, "RagdollAttachment")) then
            pcall(function() d:Destroy() end)
        end
    end
end

local function forceExit()
    if not charCache.hum or not charCache.root then return end

    pcall(function()
        player:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow())
    end)

    if charCache.hum.Health > 0 then
        charCache.hum:ChangeState(Enum.HumanoidStateType.Running)
    end

    charCache.root.Anchored = false
    charCache.root.AssemblyLinearVelocity = Vector3.zero
end

local function antiLoop()
    while antiMode == "v1" and charCache.hum do
        task.wait()
        if isRagdoll() then
            removeCons()
            forceExit()
        end
    end
end

local function setupCam()
    if not charCache.hum then return end
    table.insert(ragConns, RunService.RenderStepped:Connect(function()
        if antiMode ~= "v1" then return end
        local cam = workspace.CurrentCamera
        if cam and charCache.hum and cam.CameraSubject ~= charCache.hum then
            cam.CameraSubject = charCache.hum
        end
    end))
end

local function onChar()
    task.wait(0.5)
    if not antiMode then return end
    if cacheChar() then
        setupCam()
        task.spawn(antiLoop)
    end
end

function anti.Enable()
    if antiMode == "v1" then return end
    if not cacheChar() then return end

    antiMode = "v1"
    table.insert(ragConns, player.CharacterAdded:Connect(onChar))

    setupCam()
    task.spawn(antiLoop)

    print("anti ragdoll on")
end

function anti.Disable()
    antiMode = nil
    killConns()
    charCache = {}
    print("anti ragdoll off")
end

-- Galaxy Mover Variables
local dropEnabled = false
local _wfConns = {}
Config = {
    AutoPlaySpeed = 58,
    CarrySpeed = 29.4
}
local rightWaypoints = {
    Vector3.new(-473.04, -6.99, 29.71),
    Vector3.new(-486.04, -4.64, 19.04),
    Vector3.new(-474.18, -6.85, 28.20),
    Vector3.new(-474.67, -6.94, 105.48),
}

local leftWaypoints = {
    Vector3.new(-472.49, -7.00, 90.62),
    Vector3.new(-485.59, -4.74, 100.73),
    Vector3.new(-474.49, -6.85, 92.60),
    Vector3.new(-474.22, -6.96, 16.18),
}

-- Auto-Play variables
local AutoLeftEnabled = false
local AutoRightEnabled = false
local autoLeftKey = Enum.KeyCode.Z
local autoRightKey = Enum.KeyCode.C
local autoLeftConnection = nil
local autoRightConnection = nil
local autoLeftPhase = 1
local autoRightPhase = 1


local FloatHeight = 10
local floatConn = nil
local isFloating = false

local animalCache = {}
local promptCache = {}
local stealCache = {}
local IsStealing = false
local STEAL_R = 7
local AnimalsData = {}
local instaGrabEnabled = false

local tpDownActive = false
local AutoPlayEnabled = false
local AutoPlayDirection = "Right"

local SETTINGS = {
    LOCK_ENABLED = false,
    LOCK_SPEED = 57,
}

-- keek duel Logic Variables
local fovOn, galaxyOn, antiBatOn = false, false, false
local detectDistance = 15
local defBrightness, defClock, defAmbient = Lighting.Brightness, Lighting.ClockTime, Lighting.OutdoorAmbient
local menuOpen = false
local infinityJumpEnabled = false
local jumpForce = 50
local clampFallSpeed = 80
local noAnimToggled = false
local animationConnection = nil

--// ANTI-LAG UTILITY FUNCTIONS //
local function destroyAllAccessories()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Accessory") or descendant:IsA("MeshPartAccessory") then
			pcall(function()
				descendant:Destroy()
			end)
		end
	end
end

local function applyLowQualityToPart(part)
	if part:IsA("BasePart") or part:IsA("MeshPart") then
		part.Material = Enum.Material.Plastic
		part.Reflectance = 0
		part.CastShadow = false
		if part.Transparency == 0 then
			part.Transparency = 0 
		end
	end
end

local function applyAntiLagSettings(enabled)
	if enabled then
		Lighting.GlobalShadows = CONFIG.AntiLag.GlobalShadows
		Lighting.FogEnd = CONFIG.AntiLag.FogEnd
		Lighting.Brightness = CONFIG.AntiLag.Brightness
		Lighting.EnvironmentDiffuseScale = CONFIG.AntiLag.EnvironmentDiffuseScale
		Lighting.EnvironmentSpecularScale = CONFIG.AntiLag.EnvironmentSpecularScale
		for _, descendant in ipairs(Workspace:GetDescendants()) do
			applyLowQualityToPart(descendant)
		end
		if not _G.MGAntiLagDescendantConnection then
			_G.MGAntiLagDescendantConnection = Workspace.DescendantAdded:Connect(function(descendant)
				if descendant:IsA("Accessory") or descendant:IsA("MeshPartAccessory") then
					pcall(function() descendant:Destroy() end)
				else
					applyLowQualityToPart(descendant)
				end
			end)
		end
	else
		if _G.MGAntiLagDescendantConnection then
			_G.MGAntiLagDescendantConnection:Disconnect()
			_G.MGAntiLagDescendantConnection = nil
		end
	end
end


--// ==================== DESYNC CORE ====================
local function getDesyncHumanoid()
	local char = player.Character or player.CharacterAdded:Wait()
	return char:WaitForChild("Humanoid")
end

local function stopDesyncAnimations(hum)
	for _, track in pairs(hum:GetPlayingAnimationTracks()) do
		track:Stop()
	end
end

local function enableDesync()
	local humanoid = getDesyncHumanoid()
	stopDesyncAnimations(humanoid)

	desyncConnection = humanoid.AnimationPlayed:Connect(function(track)
		track:Stop()
	end)

	if raknet and raknet.desync then
		raknet.desync(true)
	end
end

local function disableDesync()
	if desyncConnection then
		desyncConnection:Disconnect()
		desyncConnection = nil
	end

	if raknet and raknet.desync then
		raknet.desync(false)
	end
end

local function toggleDesync()
	desyncEnabled = not desyncEnabled
	if desyncEnabled then enableDesync() else disableDesync() end
end

--// CORE FUNCTIONS //
local function getHRP()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function toggleDrop(state)
    dropEnabled = state
    if dropEnabled then
        local colConn = RunService.Stepped:Connect(function()
            if not dropEnabled then return end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    for _, part in ipairs(p.Character:GetChildren()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end
        end)
        table.insert(_wfConns, colConn)
        task.spawn(function()
            while dropEnabled do
                RunService.Heartbeat:Wait()
                local c = player.Character
                local root = c and c:FindFirstChild("HumanoidRootPart")
                if not root then continue end
                local vel = root.Velocity
                root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
                RunService.RenderStepped:Wait()
                if root and root.Parent then root.Velocity = vel end
                RunService.Stepped:Wait()
                if root and root.Parent then root.Velocity = vel + Vector3.new(0, 0.1, 0) end
            end
        end)
    else
        for _, c in ipairs(_wfConns) do if typeof(c) == "RBXScriptConnection" then c:Disconnect() end end
        _wfConns = {}
    end
end

local function doTPDown()
    local h = getHRP()
    if h then
        h.CFrame = h.CFrame * CFrame.new(0, -20, 0)
        h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
end

local function startFloat()
    if floatConn then return end
    local c = player.Character; if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local floatOriginY = hrp.Position.Y + FloatHeight
    local floatStartTime = tick()
    local floatDescending = false
    floatConn = RunService.Heartbeat:Connect(function()
        local c2 = player.Character; if not c2 then return end
        local h = c2:FindFirstChild("HumanoidRootPart"); if not h then return end
        local hum2 = c2:FindFirstChildOfClass("Humanoid")
        local moveDir = hum2 and hum2.MoveDirection or Vector3.zero
        if tick() - floatStartTime >= 4 then floatDescending = true end
        local currentY = h.Position.Y
        local vertVel
        if floatDescending then
            vertVel = -20
            if currentY <= floatOriginY - FloatHeight + 0.5 then
                h.AssemblyLinearVelocity = Vector3.zero
                if floatConn then floatConn:Disconnect(); floatConn = nil end
                return
            end
        else
            local diff = floatOriginY - currentY
            if diff > 0.3 then vertVel = math.clamp(diff * 8, 5, 50)
            elseif diff < -0.3 then vertVel = math.clamp(diff * 8, -50, -5)
            else vertVel = 0 end
        end
        local spd = 28
        local horizX = moveDir.Magnitude > 0.1 and moveDir.X * spd or 0
        local horizZ = moveDir.Magnitude > 0.1 and moveDir.Z * spd or 0
        h.AssemblyLinearVelocity = Vector3.new(horizX, vertVel, horizZ)
    end)
end

local function stopFloat()
    if floatConn then floatConn:Disconnect(); floatConn = nil end
    local c = player.Character
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
    end
end

--// AUTO PLAY (4 WAYPOINT SYSTEM) //

local autoRightConn
local autoLeftConn

local autoRightIndex = 1
local autoLeftIndex = 1

-- RIGHT SIDE
local function startAutoRight()
    if autoRightConn then autoRightConn:Disconnect() end
    autoRightIndex = 1

    autoRightConn = RunService.Heartbeat:Connect(function()
        if not AutoRightEnabled then return end

        local h, hum = getHRP(), getHum()
        if not h or not hum then return end

        local target = rightWaypoints[autoRightIndex]
        local direction = target - h.Position

        if direction.Magnitude < 2 then
            autoRightIndex += 1
            if autoRightIndex > #rightWaypoints then
                autoRightIndex = 1
            end
            return
        end

        local moveDir = direction.Unit
        hum:Move(moveDir, false)

        local speed = Config.AutoPlaySpeed

        if autoRightIndex >= 3 then
            speed = Config.CarrySpeed
        end

h.AssemblyLinearVelocity = Vector3.new(
    moveDir.X * speed,
    h.AssemblyLinearVelocity.Y,
    moveDir.Z * speed
)
    end)
end

local function stopAutoRight()
    if autoRightConn then
        autoRightConn:Disconnect()
        autoRightConn = nil
    end
end

-- LEFT SIDE
local function startAutoLeft()
    if autoLeftConn then autoLeftConn:Disconnect() end
    autoLeftIndex = 1

    autoLeftConn = RunService.Heartbeat:Connect(function()
        if not AutoLeftEnabled then return end

        local h, hum = getHRP(), getHum()
        if not h or not hum then return end

        local target = leftWaypoints[autoLeftIndex]
        local direction = target - h.Position

        if direction.Magnitude < 2 then
            autoLeftIndex += 1
            if autoLeftIndex > #leftWaypoints then
                autoLeftIndex = 1
            end
            return
        end

        local moveDir = direction.Unit
        hum:Move(moveDir, false)

        local speed = Config.AutoPlaySpeed

        if autoLeftIndex >= 3 then
            speed = Config.CarrySpeed
        end

h.AssemblyLinearVelocity = Vector3.new(
    moveDir.X * speed,
    h.AssemblyLinearVelocity.Y,
    moveDir.Z * speed
)
    end)
end

local function stopAutoLeft()
    if autoLeftConn then
        autoLeftConn:Disconnect()
        autoLeftConn = nil
    end
end

--// NO ANIMATION LOGIC //
local function stopAllAnimations(humanoid)
    if not humanoid then return end
    local activeTracks = humanoid:GetPlayingAnimationTracks()
    for _, track in ipairs(activeTracks) do
        track:Stop(0)
    end
end

local function startNoAnim()
    noAnimToggled = true
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then stopAllAnimations(hum) end
    end
    animationConnection = RunService.Stepped:Connect(function()
        if not noAnimToggled then return end
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then stopAllAnimations(humanoid) end
        end
    end)
end

local function stopNoAnim()
    noAnimToggled = false
    if animationConnection then
        animationConnection:Disconnect()
        animationConnection = nil
    end
end


--// AUTO GRAB LOGIC //
pcall(function()
    local rep = game:GetService("ReplicatedStorage")
    local datas = rep:FindFirstChild("Datas")
    if datas then
        local animals = datas:FindFirstChild("Animals")
        if animals then AnimalsData = require(animals) end
    end
end)

local function isMyBase(plotName)
    local plot = workspace.Plots and workspace.Plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if not sign then return false end
    local yb = sign:FindFirstChild("YourBase")
    return yb and yb:IsA("BillboardGui") and yb.Enabled == true
end

local function scanPlot(plot)
    if not plot or not plot:IsA("Model") then return end
    if isMyBase(plot.Name) then return end
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return end
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
                worldPosition = pod:GetPivot().Position, uid = plot.Name .. "*" .. pod.Name,
            })
        end
    end
end

local function findPrompt(ad)
    if not ad then return nil end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local plot = plots:FindFirstChild(ad.plot)
    if not plot then return nil end
    local pods = plot:FindFirstChild("AnimalPodiums")
    if not pods then return nil end
    local pod = pods:FindFirstChild(ad.slot)
    if not pod then return nil end
    local base = pod:FindFirstChild("Base")
    if not base then return nil end
    local sp = base:FindFirstChild("Spawn")
    if not sp then return nil end
    local att = sp:FindFirstChild("PromptAttachment")
    if not att then return nil end
    for _, p in ipairs(att:GetChildren()) do
        if p:IsA("ProximityPrompt") then promptCache[ad.uid] = p; return p end
    end
end

local function execSteal(prompt)
    IsStealing = true
    task.spawn(function()
        task.wait(0.2)
        fireproximityprompt(prompt)
        task.wait(0.01)
        IsStealing = false
    end)
    return true
end



--// SILENT SWING & LOCK //
local function equipAnyTool()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or char:FindFirstChildWhichIsA("Tool") then return end
    local bp = player:FindFirstChild("Backpack")
    local bat = bp and bp:FindFirstChild("Bat")
    if bat then hum:EquipTool(bat) end
end

local function silentSwing()
    local char = player.Character
    local tool = char and char:FindFirstChildWhichIsA("Tool")
    if not tool then return end
    local handle = tool:FindFirstChild("Handle")
    if not handle or not char:FindFirstChild("HumanoidRootPart") then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local eh = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if eh and hum and hum.Health > 0 and (eh.Position - char.HumanoidRootPart.Position).Magnitude <= 10 then
                for _, part in ipairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        pcall(function() firetouchinterest(handle, part, 0); firetouchinterest(handle, part, 1) end)
                    end
                end
                break
            end
        end
    end
end

local autoSwingActive = false
local function startAutoSwing()
    if autoSwingActive then return end
    autoSwingActive = true
    task.spawn(function()
        while autoSwingActive and SETTINGS.LOCK_ENABLED do
            equipAnyTool(); silentSwing(); task.wait(math.random(30, 50) / 100)
        end
        autoSwingActive = false
    end)
end

--// keek duel UI SETUP //
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "keek duel"
screenGui.ResetOnSpawn = false
local success, err = pcall(function() screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui") end)
if not success then screenGui.Parent = player:WaitForChild("PlayerGui") end
print("GUI LOADED")

-- // DARK THEME OVERRIDE //
local GALAXY_BLACK  = Color3.fromRGB(0, 0, 0)
local GALAXY_DARK   = Color3.fromRGB(5, 5, 5)     -- Deeper charcoal/black 
local GALAXY_ACCENT = Color3.fromRGB(100, 100, 100) -- Muted grey instead of bright purple 
local GALAXY_PURPLE = Color3.fromRGB(40, 40, 40)   -- Darker border stroke [cite: 49, 78]

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 55, 0, 55)
openBtn.Position = UDim2.new(0, 20, 0.5, -27)
openBtn.BackgroundColor3 = GALAXY_DARK
openBtn.Text = "K"
openBtn.TextColor3 = GALAXY_ACCENT
openBtn.TextSize = 28
openBtn.Font = Enum.Font.LuckiestGuy
openBtn.Parent = screenGui
openBtn.Draggable = true 
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)
local openStroke = Instance.new("UIStroke", openBtn)
openStroke.Color = GALAXY_PURPLE
openStroke.Thickness = 2

local sideMenu = Instance.new("Frame")
sideMenu.Size = UDim2.new(0, 200, 0, 360)
sideMenu.Position = UDim2.new(0, 85, 0.5, -180)
sideMenu.BackgroundColor3 = GALAXY_DARK
sideMenu.Parent = screenGui
sideMenu.Visible = true
Instance.new("UICorner", sideMenu).CornerRadius = UDim.new(0, 15)
local menuStroke = Instance.new("UIStroke", sideMenu)
menuStroke.Color = GALAXY_PURPLE
menuStroke.Thickness = 2

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 45)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "keek duel"
titleLabel.TextColor3 = GALAXY_ACCENT
titleLabel.TextSize = 22
titleLabel.Font = Enum.Font.LuckiestGuy
titleLabel.Parent = sideMenu


local layout = Instance.new("UIListLayout", container)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 12); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local padding = Instance.new("UIPadding", container)
padding.PaddingTop = UDim.new(0, 5)
padding.PaddingBottom = UDim.new(0, 5)

local container = Instance.new("ScrollingFrame")
container.Size = UDim2.new(0.9, 0, 0.82, 0)
container.Position = UDim2.new(0.05, 0, 0.14, 0)
container.BackgroundTransparency = 1
container.Parent = sideMenu

container.ScrollBarThickness = 6
container.AutomaticCanvasSize = Enum.AutomaticSize.Y

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 10)

local function createToggle(text)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 40)
    holder.BackgroundTransparency = 1
    holder.Parent = container

    -- label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220,220,220)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    -- toggle background
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(0, 45, 0, 22)
    toggle.Position = UDim2.new(1, -50, 0.5, -11)
    toggle.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    toggle.Parent = holder
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1,0)

    -- circle
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 18, 0, 18)
    circle.Position = UDim2.new(0, 2, 0.5, -9)
    circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    circle.Parent = toggle
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1,0)

    -- invisible button (click area)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1,0,1,0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = holder

    return button, circle, toggle
end

local fovToggle, fovInd, fovBase = createToggle("FOV (100)")
local galaxyToggle, galInd, galBase = createToggle("GALAXY MODE")
local antiBatToggle, batInd, batBase = createToggle("ANTI BAT")

local infJumpToggle, jumpInd, jumpBase = createToggle("INFINITE JUMP")
local noAnimToggle, noAnimInd, noAnimBase = createToggle("NO ANIMATION")
local antiRagdollToggle, ragInd, ragBase = createToggle("ANTI RAGDOLL")
local desyncToggle, desyncInd, desyncBase = createToggle("DESYNC")

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(0.9, 0, 0, 32); saveBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 0); saveBtn.Text = "SAVE CONFIG"; saveBtn.TextColor3 = Color3.new(1, 1, 1); saveBtn.Font = Enum.Font.LuckiestGuy; saveBtn.TextSize = 14; saveBtn.Parent = container
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0.9, 0, 0, 32)
resetBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
resetBtn.Text = "RESET CONFIG"
resetBtn.TextColor3 = Color3.new(1,1,1)
resetBtn.Font = Enum.Font.LuckiestGuy
resetBtn.TextSize = 14
resetBtn.Parent = container
Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0,6)

--// FLOATING BARS UI (Galaxy Mover) //
local function createFloatingBar(name, defaultText, startPos)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = UDim2.new(0, 160, 0, 40)
    frame.Position = startPos
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = screenGui

    local uiGradient = Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 10))
    }
    uiGradient.Rotation = 90
    uiGradient.Parent = frame

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = frame

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(60, 60, 60)
    uiStroke.Thickness = 1.5
    uiStroke.Transparency = 0.3
    uiStroke.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = defaultText
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = frame

    local dragging, dragInput, dragStart, startPosFrame, hasDragged = false

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            hasDragged = false
            dragStart = input.Position
            startPosFrame = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    btn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
            if dragging then
                if (input.Position - dragStart).Magnitude > 5 then
                    hasDragged = true
                end
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPosFrame.X.Scale,
                startPosFrame.X.Offset + delta.X,
                startPosFrame.Y.Scale,
                startPosFrame.Y.Offset + delta.Y
            )
        end
    end)

    local function isRealClick()
        return not hasDragged
    end

    return frame, btn, uiStroke, uiGradient, isRealClick
end

local frameAuto, btnAuto, strokeAuto, gradAuto, checkAuto = createFloatingBar("AutoBar", "AUTO PLAY: OFF", UDim2.new(0.3, 0, 0.3, 0))
local frameGrab, btnGrab, strokeGrab, gradGrab, checkGrab = createFloatingBar("GrabBar", "AUTO GRAB: OFF", UDim2.new(0.6, 0, 0.3, 0))
local frameDrop, btnDrop, strokeDrop, gradDrop, checkDrop = createFloatingBar("DropBar", "DROP", UDim2.new(0.3, 0, 0.45, 0))
local frameFloat, btnFloat, strokeFloat, gradFloat, checkFloat = createFloatingBar("FloatBar", "FLOAT: OFF", UDim2.new(0.45, 0, 0.45, 0))
local frameTP, btnTP, strokeTP, gradTP, checkTP = createFloatingBar("TPBar", "TP DOWN", UDim2.new(0.6, 0, 0.45, 0))
local frameLock, btnLock, strokeLock, gradLock, checkLock = createFloatingBar("LockBar", "LOCK: OFF", UDim2.new(0.3, 0, 0.60, 0))

local function addGear(parentFrame)
    local g = Instance.new("TextButton")
    g.Size = UDim2.new(0, 25, 0, 25); g.Position = UDim2.new(1, -30, 0.5, -12.5); g.BackgroundColor3 = Color3.fromRGB(40, 20, 70); g.Text = "⚙️"; g.TextColor3 = Color3.fromRGB(255, 255, 255); g.Font = Enum.Font.GothamBold; g.TextSize = 14; g.Parent = parentFrame
    Instance.new("UICorner", g).CornerRadius = UDim.new(0, 6)
    return g
end

local btnAutoSet = addGear(frameAuto)
local autoPanel = Instance.new("Frame")
autoPanel.Size = UDim2.new(0, 160, 0, 50); autoPanel.Position = UDim2.new(0, 0, 1, 10); autoPanel.BackgroundColor3 = Color3.fromRGB(10, 20, 40); autoPanel.Visible = false; autoPanel.Parent = frameAuto
Instance.new("UICorner", autoPanel).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", autoPanel).Color = Color3.fromRGB(138, 43, 226)

local btnDirLeft = Instance.new("TextButton")
btnDirLeft.Size = UDim2.new(0.4, 0, 0, 25); btnDirLeft.Position = UDim2.new(0.06, 0, 0.5, -12.5); btnDirLeft.BackgroundColor3 = Color3.fromRGB(30, 40, 60); btnDirLeft.Text = "LEFT"; btnDirLeft.TextColor3 = Color3.fromRGB(255, 255, 255); btnDirLeft.Font = Enum.Font.GothamBold; btnDirLeft.TextSize = 11; btnDirLeft.Parent = autoPanel
Instance.new("UICorner", btnDirLeft).CornerRadius = UDim.new(0, 6)

local btnDirRight = Instance.new("TextButton")
btnDirRight.Size = UDim2.new(0.4, 0, 0, 25); btnDirRight.Position = UDim2.new(0.54, 0, 0.5, -12.5); btnDirRight.BackgroundColor3 = Color3.fromRGB(138, 43, 226); btnDirRight.Text = "RIGHT"; btnDirRight.TextColor3 = Color3.fromRGB(255, 255, 255); btnDirRight.Font = Enum.Font.GothamBold; btnDirRight.TextSize = 11; btnDirRight.Parent = autoPanel
Instance.new("UICorner", btnDirRight).CornerRadius = UDim.new(0, 6)

btnAutoSet.MouseButton1Click:Connect(function() autoPanel.Visible = not autoPanel.Visible end)
btnDirLeft.MouseButton1Click:Connect(function() AutoPlayDirection = "Left"; btnDirLeft.BackgroundColor3 = Color3.fromRGB(138, 43, 226); btnDirRight.BackgroundColor3 = Color3.fromRGB(30, 40, 60); if AutoPlayEnabled then stopAutoRight(); AutoRightEnabled = false; AutoLeftEnabled = true; startAutoLeft() end end)

-- SPEED INPUTS
local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0.9, 0, 0, 20)
speedBox.Position = UDim2.new(0.05, 0, 1, 5)
speedBox.PlaceholderText = "Auto Speed"
speedBox.Text = tostring(Config.AutoPlaySpeed)
speedBox.Parent = autoPanel

speedBox.FocusLost:Connect(function()
    local val = tonumber(speedBox.Text)
    if val then Config.AutoPlaySpeed = val end
end)

local carryBox = Instance.new("TextBox")
carryBox.Size = UDim2.new(0.9, 0, 0, 20)
carryBox.Position = UDim2.new(0.05, 0, 1, 30)
carryBox.PlaceholderText = "Carry Speed"
carryBox.Text = tostring(Config.CarrySpeed)
carryBox.Parent = autoPanel

carryBox.FocusLost:Connect(function()
    local val = tonumber(carryBox.Text)
    if val then Config.CarrySpeed = val end
end)

btnDirRight.MouseButton1Click:Connect(function() AutoPlayDirection = "Right"; btnDirRight.BackgroundColor3 = Color3.fromRGB(138, 43, 226); btnDirLeft.BackgroundColor3 = Color3.fromRGB(30, 40, 60); if AutoPlayEnabled then stopAutoLeft(); AutoLeftEnabled = false; AutoRightEnabled = true; startAutoRight() end end)

--// UI CONNECTIONS & PERSISTENCE //
local function updateVisual(on, circle, bg)
    TweenService:Create(circle, TweenInfo.new(0.25), {
        Position = on and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    }):Play()

    TweenService:Create(bg, TweenInfo.new(0.25), {
        BackgroundColor3 = on and Color3.fromRGB(80, 120, 255) or Color3.fromRGB(40, 40, 60)
    }):Play()
end

openBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    if menuOpen then
        sideMenu.Visible = true
        sideMenu:TweenPosition(UDim2.new(0, 85, 0.5, -180), "Out", "Quad", 0.35, true)
    else
        sideMenu:TweenPosition(UDim2.new(0, -250, 0.5, -180), "In", "Quad", 0.35, true, function() if not menuOpen then sideMenu.Visible = false end end)
    end
end)

fovToggle.MouseButton1Click:Connect(function() fovOn = not fovOn; camera.FieldOfView = fovOn and 100 or 70; updateVisual(fovOn, fovInd, fovBase) end)
galaxyToggle.MouseButton1Click:Connect(function()
    galaxyOn = not galaxyOn
    if galaxyOn then
        local sky = Lighting:FindFirstChild("GalaxySky") or Instance.new("Sky")
        sky.Name = "GalaxySky"; sky.SkyboxBk, sky.SkyboxDn, sky.SkyboxFt, sky.SkyboxLf, sky.SkyboxRt, sky.SkyboxUp = "rbxassetid://159454299", "rbxassetid://159454296", "rbxassetid://159454293", "rbxassetid://159454286", "rbxassetid://159454289", "rbxassetid://159454291"; sky.Parent = Lighting
        Lighting.Brightness, Lighting.ClockTime, Lighting.ExposureCompensation = 0, 0, -2; Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
    else
        if Lighting:FindFirstChild("GalaxySky") then Lighting.GalaxySky:Destroy() end
        Lighting.Brightness, Lighting.ClockTime, Lighting.ExposureCompensation = defBrightness, defClock, 0; Lighting.OutdoorAmbient = defAmbient
    end
    updateVisual(galaxyOn, galInd, galBase)
end)
antiBatToggle.MouseButton1Click:Connect(function() antiBatOn = not antiBatOn; updateVisual(antiBatOn, batInd, batBase) end)

infJumpToggle.MouseButton1Click:Connect(function() infinityJumpEnabled = not infinityJumpEnabled; updateVisual(infinityJumpEnabled, jumpInd, jumpBase) end)
noAnimToggle.MouseButton1Click:Connect(function() if not noAnimToggled then startNoAnim() else stopNoAnim() end; updateVisual(noAnimToggled, noAnimInd, noAnimBase) end)
desyncToggle.MouseButton1Click:Connect(function()
	toggleDesync()
	updateVisual(desyncEnabled, desyncInd, desyncBase)
end)

antiRagdollToggle.MouseButton1Click:Connect(function()
    antiRagdollEnabled = not antiRagdollEnabled

    if antiRagdollEnabled then
        anti.Enable()
    else
        anti.Disable()
    end

    updateVisual(antiRagdollEnabled, ragInd, ragBase)
end)

local function setVisual(btn, grad, stroke, state, onTxt, offTxt)
    btn.Text = state and onTxt or offTxt
    btn.TextColor3 = state and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,180)

    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, state and Color3.fromRGB(40,40,40) or Color3.fromRGB(25,25,25)),
        ColorSequenceKeypoint.new(1, state and Color3.fromRGB(20,20,20) or Color3.fromRGB(10,10,10))
    }

    stroke.Color = state and Color3.fromRGB(120,120,120) or Color3.fromRGB(60,60,60)
end

btnAuto.MouseButton1Click:Connect(function() if not checkAuto() then return end; AutoPlayEnabled = not AutoPlayEnabled; setVisual(btnAuto, gradAuto, strokeAuto, AutoPlayEnabled, "AUTO PLAY: ON", "AUTO PLAY: OFF"); if AutoPlayEnabled then if AutoPlayDirection == "Right" then AutoRightEnabled = true; startAutoRight() else AutoLeftEnabled = true; startAutoLeft() end else AutoRightEnabled = false; AutoLeftEnabled = false; stopAutoRight(); stopAutoLeft() end end)
btnGrab.MouseButton1Click:Connect(function() if not checkGrab() then return end; instaGrabEnabled = not instaGrabEnabled; setVisual(btnGrab, gradGrab, strokeGrab, instaGrabEnabled, "AUTO GRAB: ON", "AUTO GRAB: OFF") end)
btnFloat.MouseButton1Click:Connect(function() if not checkFloat() then return end; isFloating = not isFloating; setVisual(btnFloat, gradFloat, strokeFloat, isFloating, "FLOAT: ON", "FLOAT: OFF"); if isFloating then startFloat() else stopFloat() end end)
btnDrop.MouseButton1Click:Connect(function() if not checkDrop() then return end; toggleDrop(not dropEnabled); setVisual(btnDrop, gradDrop, strokeDrop, dropEnabled, "DROP: ON", "DROP: OFF") end)
btnLock.MouseButton1Click:Connect(function() if not checkLock() then return end; SETTINGS.LOCK_ENABLED = not SETTINGS.LOCK_ENABLED; setVisual(btnLock, gradLock, strokeLock, SETTINGS.LOCK_ENABLED, "LOCK: ON", "LOCK: OFF"); if SETTINGS.LOCK_ENABLED then equipAnyTool(); startAutoSwing() end end)
btnTP.MouseButton1Click:Connect(function() if not checkTP() then return end; tpDownActive = true; setVisual(btnTP, gradTP, strokeTP, true, "TP DOWN: ON", "TP DOWN: OFF"); task.spawn(doTPDown); task.delay(0.2, function() tpDownActive = false; setVisual(btnTP, gradTP, strokeTP, false, "TP DOWN: ON", "TP DOWN: OFF") end) end)

--// LOOPS & CONNECTIONS //
LocalPlayer.CharacterAdded:Connect(function() if noAnimToggled then task.wait(0.5); startNoAnim() end end)

RunService.Heartbeat:Connect(function()
    local char = player.Character; local root = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid")
    if root and hum then
        local currentTool = char:FindFirstChildOfClass("Tool")
        local holdingBat = currentTool and currentTool.Name:lower():find("bat")
        if not antiBatOn or holdingBat then 
            local spin = root:FindFirstChild("CryzsnForce"); if spin then spin:Destroy(); hum.AutoRotate = true end
        else
            local threat = false
            for _, other in pairs(Players:GetPlayers()) do
                if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
                    if (root.Position - other.Character.HumanoidRootPart.Position).Magnitude <= detectDistance then threat = true break end
                end
            end
            local spin = root:FindFirstChild("CryzsnForce")
            if threat then
                if not spin then
                    local bv = Instance.new("BodyAngularVelocity"); bv.Name = "CryzsnForce"; bv.MaxTorque = Vector3.new(0, math.huge, 0); bv.AngularVelocity = Vector3.new(0, 50, 0); bv.Parent = root; hum.AutoRotate = false
                end
            elseif spin then spin:Destroy(); hum.AutoRotate = true end
        end
    end
    if infinityJumpEnabled and player.Character then local hrp = player.Character:FindFirstChild("HumanoidRootPart"); if hrp and hrp.Velocity.Y < -clampFallSpeed then hrp.Velocity = Vector3.new(hrp.Velocity.X, -clampFallSpeed, hrp.Velocity.Z) end end
    if instaGrabEnabled and not IsStealing then
        local hrp = getHRP(); if hrp then local t, bd = nil, math.huge; for _, ad in ipairs(animalCache) do local d = (hrp.Position - ad.worldPosition).Magnitude; if d < bd then bd = d; t = ad end end; if t and bd <= STEAL_R then local p = promptCache[t.uid] or findPrompt(t); if p then execSteal(p) end end end
    end
    if SETTINGS.LOCK_ENABLED then
        local hrp = getHRP(); if hrp then equipAnyTool(); local n, dist, t = nil, math.huge, nil; for _, p in ipairs(Players:GetPlayers()) do if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid").Health > 0 then local d = (p.Character.HumanoidRootPart.Position - hrp.Position).Magnitude; if d < dist then dist = d; n = p.Character.HumanoidRootPart; t = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso") or n end end end; if n and t then local fd = t.Position - hrp.Position; if fd.Magnitude > 1.5 then hrp.Velocity = Vector3.new(fd.Unit.X * SETTINGS.LOCK_SPEED, fd.Unit.Y * SETTINGS.LOCK_SPEED, fd.Unit.Z * SETTINGS.LOCK_SPEED) else hrp.Velocity = n.Velocity end end end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == Enum.KeyCode.E then
		toggleDesync()
		updateVisual(desyncEnabled, desyncInd, desyncBase)
	end
end)

UserInputService.JumpRequest:Connect(function() if infinityJumpEnabled and player.Character then local hrp = player.Character:FindFirstChild("HumanoidRootPart"); if hrp then hrp.Velocity = Vector3.new(hrp.Velocity.X, jumpForce, hrp.Velocity.Z) end end end)

saveBtn.MouseButton1Click:Connect(function()
    if writefile then
        local data = {
            -- toggles
            FOV = fovOn,
            Galaxy = galaxyOn,
            AntiBat = antiBatOn,
            
            InfJump = infinityJumpEnabled,
            NoAnim = noAnimToggled,

            -- open button
            OpenBtn = {
                X = openBtn.Position.X.Scale,
                Xo = openBtn.Position.X.Offset,
                Y = openBtn.Position.Y.Scale,
                Yo = openBtn.Position.Y.Offset
            },

            -- floating buttons
            Floating = {
                Auto = {frameAuto.Position.X.Scale, frameAuto.Position.X.Offset, frameAuto.Position.Y.Scale, frameAuto.Position.Y.Offset},
                Grab = {frameGrab.Position.X.Scale, frameGrab.Position.X.Offset, frameGrab.Position.Y.Scale, frameGrab.Position.Y.Offset},
                Drop = {frameDrop.Position.X.Scale, frameDrop.Position.X.Offset, frameDrop.Position.Y.Scale, frameDrop.Position.Y.Offset},
                Float = {frameFloat.Position.X.Scale, frameFloat.Position.X.Offset, frameFloat.Position.Y.Scale, frameFloat.Position.Y.Offset},
                TP = {frameTP.Position.X.Scale, frameTP.Position.X.Offset, frameTP.Position.Y.Scale, frameTP.Position.Y.Offset},
                Lock = {frameLock.Position.X.Scale, frameLock.Position.X.Offset, frameLock.Position.Y.Scale, frameLock.Position.Y.Offset},
            }
        }

        writefile(FILE_NAME, HttpService:JSONEncode(data))
        saveBtn.Text = "SAVED!"
        task.wait(0.5)
        saveBtn.Text = "SAVE CONFIG"
    end
end)

if isfile and isfile(FILE_NAME) then
    local s, d = pcall(function()
        return HttpService:JSONDecode(readfile(FILE_NAME))
    end)

    if s and d then
        -- open button
        if d.OpenBtn then
            openBtn.Position = UDim2.new(d.OpenBtn.X, d.OpenBtn.Xo, d.OpenBtn.Y, d.OpenBtn.Yo)
        end

        -- floating buttons
        if d.Floating then
            local function setPos(frame, t)
                if t then
                    frame.Position = UDim2.new(t[1], t[2], t[3], t[4])
                end
            end

            setPos(frameAuto, d.Floating.Auto)
            setPos(frameGrab, d.Floating.Grab)
            setPos(frameDrop, d.Floating.Drop)
            setPos(frameFloat, d.Floating.Float)
            setPos(frameTP, d.Floating.TP)
            setPos(frameLock, d.Floating.Lock)
        end

        -- toggles
        fovOn = d.FOV or false
        galaxyOn = d.Galaxy or false
        antiBatOn = d.AntiBat or false
        
        infinityJumpEnabled = d.InfJump or false
        noAnimToggled = d.NoAnim or false

        camera.FieldOfView = fovOn and 100 or 70

        if noAnimToggled then startNoAnim() end

        updateVisual(fovOn, fovInd, fovBase)
        updateVisual(galaxyOn, galInd, galBase)
        updateVisual(antiBatOn, batInd, batBase)
        
        updateVisual(infinityJumpEnabled, jumpInd, jumpBase)
        updateVisual(noAnimToggled, noAnimInd, noAnimBase)
    end
end

--// AUTO-EXECUTION //
applyAntiLagSettings(true)
destroyAllAccessories()
task.spawn(function()
    task.wait(2); local plots = workspace:WaitForChild("Plots", 10); if plots then for _, plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then scanPlot(plot) end end; plots.ChildAdded:Connect(function(plot) if plot:IsA("Model") then task.wait(0.5); scanPlot(plot) end end) end
end)

resetBtn.MouseButton1Click:Connect(function()
    if delfile and isfile(FILE_NAME) then
        delfile(FILE_NAME)
    end

    openBtn.Position = UDim2.new(0, 20, 0.5, -27)

    frameAuto.Position = UDim2.new(0.3, 0, 0.3, 0)
    frameGrab.Position = UDim2.new(0.6, 0, 0.3, 0)
    frameDrop.Position = UDim2.new(0.3, 0, 0.45, 0)
    frameFloat.Position = UDim2.new(0.45, 0, 0.45, 0)
    frameTP.Position = UDim2.new(0.6, 0, 0.45, 0)
    frameLock.Position = UDim2.new(0.3, 0, 0.60, 0)

    resetBtn.Text = "RESET DONE"
    task.wait(0.5)
    resetBtn.Text = "RESET CONFIG"
end)

print("[MG Anti Lag] Auto-Executed: All optimizations active.")



--// ==================== ESP SYSTEM ====================
local espOn = false
local espConnections = {}
local espBillboards = {}

local function clearESP()
    for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
        if plr ~= game.Players.LocalPlayer and plr.Character then
            local h = plr.Character:FindFirstChild("ESPHighlight")
            if h then h:Destroy() end
            if espBillboards[plr] then
                espBillboards[plr]:Destroy()
                espBillboards[plr] = nil
            end
        end
    end
end

local function addESP(plr)
    if not espOn then return end
    if plr == game.Players.LocalPlayer then return end
    if not plr.Character then return end

    local char = plr.Character
    local head = char:FindFirstChild("Head")
    if not head then return end

    local hl = Instance.new("Highlight")
    hl.Name = "ESPHighlight"
    hl.FillColor = Color3.fromRGB(120,120,255)
    hl.OutlineColor = Color3.fromRGB(120,120,255)
    hl.FillTransparency = 0.3
    hl.Parent = char

    local bill = Instance.new("BillboardGui")
    bill.Name = "ESPName"
    bill.Adornee = head
    bill.Size = UDim2.new(0,100,0,40)
    bill.StudsOffset = Vector3.new(0,2,0)
    bill.AlwaysOnTop = true
    bill.Parent = char

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1,0,1,0)
    txt.BackgroundTransparency = 1
    txt.Text = plr.Name
    txt.TextScaled = true
    txt.TextColor3 = Color3.new(1,1,1)
    txt.Font = Enum.Font.GothamBold
    txt.Parent = bill

    espBillboards[plr] = bill
end

local function enableESP()
    clearESP()
    for _, plr in pairs(game:GetService("Players"):GetPlayers()) do
        addESP(plr)
    end
end

local function disableESP()
    clearESP()
end
