local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local enabled = false
local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- INFINITE JUMP VARIABLE
local InfiniteJumpEnabled = false

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "KeekBooster"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 110)
frame.Position = UDim2.new(0.5, -110, 0.4, -55)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 32)

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(255, 0, 0)
frameStroke.Thickness = 2.0
frameStroke.Transparency = 0.2
frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
frameStroke.Parent = frame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 0, 24)
title.Position = UDim2.new(0, 16, 0, 10)
title.BackgroundTransparency = 1
title.Text = "Keek Booster"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

-- Speed
local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0, 90, 0, 32)
speedBox.Position = UDim2.new(0, 110, 0, 38)
speedBox.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
speedBox.Text = "28"
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 15
speedBox.ClearTextOnFocus = false
speedBox.Parent = frame
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 10)

-- Jump
local jumpBox = Instance.new("TextBox")
jumpBox.Size = UDim2.new(0, 90, 0, 32)
jumpBox.Position = UDim2.new(0, 110, 0, 70)
jumpBox.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
jumpBox.Text = "35"
jumpBox.TextColor3 = Color3.fromRGB(255, 255, 255)
jumpBox.Font = Enum.Font.Gotham
jumpBox.TextSize = 15
jumpBox.ClearTextOnFocus = false
jumpBox.Parent = frame
Instance.new("UICorner", jumpBox).CornerRadius = UDim.new(0, 10)

-- Toggle
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0, 52, 0, 24)
toggle.Position = UDim2.new(1, -68, 0, 12)
toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
toggle.Text = ""
toggle.AutoButtonColor = false
toggle.Parent = frame

local knob = Instance.new("Frame")
knob.Size = UDim2.new(0, 20, 0, 20)
knob.Position = UDim2.new(0, 2, 0.5, 0)
knob.AnchorPoint = Vector2.new(0, 0.5)
knob.BackgroundColor3 = Color3.new(1, 1, 1)
knob.Parent = toggle

Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 12)

toggle.MouseButton1Click:Connect(function()
    enabled = not enabled
    local targetPos = enabled and UDim2.new(0, 30, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
    local targetColor = enabled and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(60, 60, 70)
    TweenService:Create(knob, tweenInfo, {Position = targetPos}):Play()
    TweenService:Create(toggle, tweenInfo, {BackgroundColor3 = targetColor}):Play()
end)

UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState("Jumping")
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local root = hum.RootPart
    if not root then return end

    if enabled then
        hum.UseJumpPower = true
        local jump = tonumber(jumpBox.Text)
        if jump then hum.JumpPower = jump end

        local moveDir = hum.MoveDirection
        local speed = tonumber(speedBox.Text) or 28
        if moveDir.Magnitude > 0.01 then
            root.Velocity = Vector3.new(moveDir.X * speed, root.Velocity.Y, moveDir.Z * speed)
        end
    end

    InfiniteJumpEnabled = enabled
end)

print("Keek Booster + Infinite Jump loaded")
