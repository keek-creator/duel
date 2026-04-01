-- UPDATED KEEK DUEL (CIRCLE BUTTONS VERSION)

-- Only the button section was modified

-- ========== FUNCTIONAL BUTTONS (CIRCLE STYLE) ==========
local buttonData = {
    {name = "Float", pos = UDim2.new(0.7, 0, 0.3, 0), func = "float"},
    {name = "Bat", pos = UDim2.new(0.82, 0, 0.3, 0), func = "Bat Aimbot"},
    {name = "Left", pos = UDim2.new(0.7, 0, 0.36, 0), func = "autoleft"},
    {name = "Right", pos = UDim2.new(0.82, 0, 0.36, 0), func = "autoright"},
    {name = "L", pos = UDim2.new(0.7, 0, 0.42, 0), func = "TP [Left]"},
    {name = "R", pos = UDim2.new(0.82, 0, 0.42, 0), func = "TP [Right]"}
}

local buttons = {}

for _, data in pairs(buttonData) do
    local b = Instance.new("TextButton", Lib)
    b.Name = data.name
    b.Size = UDim2.new(0, 45, 0, 45)
    b.Position = data.pos
    b.BackgroundTransparency = 0.15
    b.BackgroundColor3 = Color3.fromRGB(10, 10, 12)

    local Corner = Instance.new("UICorner", b)
    Corner.CornerRadius = UDim.new(1, 0)

    local Stroke = Instance.new("UIStroke", b)
    Stroke.Color = Color3.fromRGB(130, 80, 255)
    Stroke.Thickness = 2
    Stroke.Transparency = 0.3

    local lbl = Instance.new("TextLabel", b)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = data.name
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Center

    local dot = Instance.new("Frame", b)
    dot.Name = "StatusDot"
    dot.Size = UDim2.new(0, 6, 0, 6)
    dot.Position = UDim2.new(0.5, -3, 1, -10)
    dot.BackgroundColor3 = Color3.fromRGB(70, 70, 80)

    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    MakeDraggable(b)

    buttons[data.func] = b
end

-- ========== UPDATED BUTTON STATE ==========
local function updateButtonState(button, isActive)
    local dot = button:FindFirstChild("StatusDot")

    if isActive then
        button.BackgroundColor3 = Color3.fromRGB(130, 80, 255)
        button.BackgroundTransparency = 0.2
        if dot then
            dot.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        end
    else
        button.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        button.BackgroundTransparency = 0.15
        if dot then
            dot.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        end
    end
end
