-- KEEK HUB - Mobile Buttons (Separated, Draggable, Save/Load)
repeat task.wait() until game.Players.LocalPlayer
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KEEK_MOBILE"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local CFG_PATH = "KeekHubConfig.json"
local cfg = { buttonSize = 70, mobilePositions = {} }

local function loadConfig()
	if readfile then
		local ok, data = pcall(function()
			return HttpService:JSONDecode(readfile(CFG_PATH))
		end)
		if ok and type(data) == "table" then
			cfg.buttonSize = tonumber(data.buttonSize) or cfg.buttonSize
			cfg.mobilePositions = type(data.mobilePositions) == "table" and data.mobilePositions or {}
		end
	end
end

local MobileButtons = {}
local function saveConfig()
	if writefile then
		local data = { buttonSize = cfg.buttonSize, mobilePositions = {} }
		for id, btn in pairs(MobileButtons) do
			data.mobilePositions[id] = {
				x = btn.Position.X.Offset,
				y = btn.Position.Y.Offset
			}
		end
		writefile(CFG_PATH, HttpService:JSONEncode(data))
	end
end

loadConfig()

local defaultPositions = {
	["DROPBR"]={20,200},["AUTOLEFT"]={20,280},["AUTOBAT"]={20,360},
	["AUTORIGHT"]={120,200},["TPDOWN"]={120,280},["CARRYSPEED"]={120,360},
	["BATCOUNTER"]={120,440},["LAGGERMODE"]={120,520}
}

local mobileLocked=false

local function styleButton(btn)
	btn.BackgroundColor3=Color3.fromRGB(18,18,22)
	btn.TextColor3=Color3.fromRGB(240,240,255)
	btn.Font=Enum.Font.GothamBold
	btn.TextScaled=true
	btn.BorderSizePixel=0
	Instance.new("UICorner",btn).CornerRadius=UDim.new(0,12)
end

local function makeDraggable(btn,id)
	local dragging=false
	local dragStart,startPos

	btn.InputBegan:Connect(function(input)
		if mobileLocked then return end
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true
			dragStart=input.Position
			startPos=btn.Position
			input.Changed:Connect(function()
				if input.UserInputState==Enum.UserInputState.End then
					dragging=false
					saveConfig()
				end
			end)
		end
	end)

	btn.InputChanged:Connect(function(input)
		if dragging and not mobileLocked then
			local delta=input.Position-dragStart
			btn.Position=UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset+delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset+delta.Y
			)
		end
	end)
end

local function makeMobileBtn(text,callback)
	local id=text:gsub("%s",""):gsub("\n",""):upper()
	local size=cfg.buttonSize
	local pos=cfg.mobilePositions[id] or defaultPositions[id] or {20,200}

	local btn=Instance.new("TextButton")
	btn.Size=UDim2.new(0,size,0,size)
	btn.Position=UDim2.new(0,pos[1],0,pos[2])
	btn.Text=text
	btn.Parent=ScreenGui

	styleButton(btn)
	makeDraggable(btn,id)

	btn.MouseButton1Click:Connect(function()
		if callback then callback() end
	end)

	MobileButtons[id]=btn
	return btn
end

-- Lock button
local lockBtn=Instance.new("TextButton")
lockBtn.Size=UDim2.new(0,50,0,50)
lockBtn.Position=UDim2.new(0,20,1,-80)
lockBtn.Text="🔓"
lockBtn.Parent=ScreenGui
styleButton(lockBtn)

lockBtn.MouseButton1Click:Connect(function()
	mobileLocked=not mobileLocked
	lockBtn.Text=mobileLocked and "🔒" or "🔓"
end)

-- Buttons
makeMobileBtn("DROP\nBR",function() if runDrop then task.spawn(runDrop) end end)
makeMobileBtn("AUTO\nLEFT",function() if startAutoLeft then startAutoLeft() end end)
makeMobileBtn("AUTO\nBAT",function() if startBatAimbot then startBatAimbot() end end)
makeMobileBtn("AUTO\nRIGHT",function() if startAutoRight then startAutoRight() end end)
makeMobileBtn("TP\nDOWN",function() if runTPDown then task.spawn(runTPDown) end end)
makeMobileBtn("CARRY\nSPEED",function() speedMode=not speedMode end)
makeMobileBtn("BAT\nCOUNTER",function() if startBatCounter then startBatCounter() end end)
makeMobileBtn("LAGGER\nMODE",function() if startLaggerMode then startLaggerMode() end end)

print("KEEK MOBILE SEPARATED LOADED")
