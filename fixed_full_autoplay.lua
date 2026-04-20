
-- CLEAN FULL AUTO PLAY SYSTEM (FIXED)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer

local function getChar()
    return lp.Character
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- PATHS
local LeftPoints = {L1=nil,L2=nil,L3=nil,L4=nil}
local RightPoints = {R1=nil,R2=nil,R3=nil,R4=nil}

local leftOrder = {"L1","L2","L3","L4"}
local rightOrder = {"R1","R2","R3","R4"}

local AutoPlayDirection = "Right"
local CustomAutoEnabled = false
local currentPointIndex = 1
local conn

function saveLeft(name)
    local hrp = getHRP()
    if hrp then LeftPoints[name] = hrp.Position end
end

function saveRight(name)
    local hrp = getHRP()
    if hrp then RightPoints[name] = hrp.Position end
end

function startCustomAuto()
    if conn then conn:Disconnect() end
    currentPointIndex = 1

    conn = RunService.Heartbeat:Connect(function()
        if not CustomAutoEnabled then return end

        local hrp = getHRP()
        local hum = getHum()
        if not hrp or not hum then return end

        local target = (AutoPlayDirection=="Right")
            and RightPoints[rightOrder[currentPointIndex]]
            or LeftPoints[leftOrder[currentPointIndex]]

        if not target then
            warn("Missing:", currentPointIndex)
            return
        end

        local dir = target - hrp.Position

        if dir.Magnitude < 3 then
            currentPointIndex += 1
            local max = (AutoPlayDirection=="Right") and #rightOrder or #leftOrder
            if currentPointIndex > max then currentPointIndex = 1 end
            return
        end

        local moveDir = dir.Unit
        hum:Move(moveDir, false)

        hrp.AssemblyLinearVelocity = Vector3.new(
            moveDir.X * 50,
            hrp.AssemblyLinearVelocity.Y,
            moveDir.Z * 50
        )
    end)
end

function stopCustomAuto()
    if conn then conn:Disconnect() conn=nil end
end

-- GUI
task.spawn(function()
    task.wait(1)

    local gui = Instance.new("ScreenGui", game.CoreGui)
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0,220,0,320)
    frame.Position = UDim2.new(0,20,0,100)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,25)

    local layout = Instance.new("UIListLayout", frame)
    layout.Padding = UDim.new(0,5)

    local function btn(txt, cb)
        local b = Instance.new("TextButton", frame)
        b.Size = UDim2.new(1,0,0,28)
        b.Text = txt
        b.BackgroundColor3 = Color3.fromRGB(40,40,40)
        b.TextColor3 = Color3.new(1,1,1)
        b.MouseButton1Click:Connect(cb)
        return b
    end

    for i=1,4 do
        btn("L"..i,function() saveLeft("L"..i) end)
    end

    for i=1,4 do
        btn("R"..i,function() saveRight("R"..i) end)
    end

    btn("SWITCH SIDE",function()
        AutoPlayDirection = (AutoPlayDirection=="Right") and "Left" or "Right"
        print("Side:",AutoPlayDirection)
    end)

    btn("AUTO PLAY",function()
        CustomAutoEnabled = not CustomAutoEnabled
        if CustomAutoEnabled then startCustomAuto() else stopCustomAuto() end
    end)
end)
