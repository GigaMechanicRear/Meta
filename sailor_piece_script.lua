--[[
    Sail Piece / AOPG Hub
    Auto Farm | Auto Collect | Auto Stats
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- ========================= STATE =========================
local Settings = {
    AutoFarm = false,
    AutoCollect = false,
    AutoStats = false,
    FarmRadius = 1500, -- studs
    StatToUpgrade = "Melee",
    Running = true,
}

-- Anti-AFK
pcall(function()
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ========================= HELPERS =========================
local function getCharacter()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").Health > 0 then
        return char, char.HumanoidRootPart, char:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function isAlive()
    return getCharacter() ~= nil
end

local function findMobFolder()
    for _, name in ipairs({"Enemies", "Mobs", "NPCs", "Monsters", "EnemySpawns", "Mob"}) do
        local f = workspace:FindFirstChild(name)
        if f then return f end
    end
    return workspace
end

local function isValidMob(model, rootPos)
    if not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    if model == LocalPlayer.Character then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if not hum or not hrp or hum.Health <= 0 then return false end
    if (hrp.Position - rootPos).Magnitude > Settings.FarmRadius then return false end
    return true, hum, hrp
end

local function getNearestMob()
    local _, root = getCharacter()
    if not root then return nil end
    local folder = findMobFolder()
    local best, bestHum, bestHrp, bestDist = nil, nil, nil, math.huge
    for _, model in ipairs(folder:GetDescendants()) do
        local ok, hum, hrp = isValidMob(model, root.Position)
        if ok then
            local d = (hrp.Position - root.Position).Magnitude
            if d < bestDist then
                best, bestHum, bestHrp, bestDist = model, hum, hrp, d
            end
        end
    end
    return best, bestHum, bestHrp
end

local function attack()
    -- Fire common remotes, fallback to click
    pcall(function()
        for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
            if r:IsA("RemoteEvent") and (r.Name:lower():find("combat") or r.Name:lower():find("attack") or r.Name:lower():find("damage")) then
                r:FireServer()
            end
        end
    end)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(0.05)
        VirtualUser:Button1Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end

local function equipTool()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        if char:FindFirstChildOfClass("Tool") then return end
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            local tool = backpack:FindFirstChildOfClass("Tool")
            if tool then
                char:FindFirstChildOfClass("Humanoid"):EquipTool(tool)
            end
        end
    end)
end

-- ========================= GUI =========================
local CoreGui = (gethui and gethui()) or game:GetService("CoreGui")
pcall(function()
    local old = CoreGui:FindFirstChild("SailPieceHub")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SailPieceHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local ACCENT = Color3.fromRGB(0, 255, 200)
local BG = Color3.fromRGB(13, 13, 26)
local BG2 = Color3.fromRGB(22, 22, 40)
local TEXT = Color3.fromRGB(235, 235, 245)
local MUTED = Color3.fromRGB(140, 140, 165)
local OFFCOL = Color3.fromRGB(60, 60, 85)

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 260, 0, 0) -- animated open
Main.Position = UDim2.new(0.5, -130, 0.35, 0)
Main.BackgroundColor3 = BG
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner", Main)
MainCorner.CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = ACCENT
MainStroke.Thickness = 1.2
MainStroke.Transparency = 0.4

local Gradient = Instance.new("UIGradient", Main)
Gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 34)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 20)),
}
Gradient.Rotation = 90

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = BG2
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚔️  SAIL PIECE HUB"
Title.TextColor3 = ACCENT
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -34, 0, 5)
MinBtn.BackgroundColor3 = BG
MinBtn.Text = "—"
MinBtn.TextColor3 = TEXT
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.AutoButtonColor = false
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

-- Content
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -20, 1, -48)
Content.Position = UDim2.new(0, 10, 0, 44)
Content.BackgroundTransparency = 1
Content.Parent = Main

local Layout = Instance.new("UIListLayout", Content)
Layout.Padding = UDim.new(0, 8)
Layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Notification toast
local function notify(text, dur)
    dur = dur or 2.5
    task.spawn(function()
        pcall(function()
            local toast = Instance.new("Frame")
            toast.Size = UDim2.new(0, 0, 0, 34)
            toast.AnchorPoint = Vector2.new(0.5, 1)
            toast.Position = UDim2.new(0.5, 0, 1, -30)
            toast.BackgroundColor3 = BG2
            toast.BorderSizePixel = 0
            toast.Parent = ScreenGui
            Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)
            local st = Instance.new("UIStroke", toast)
            st.Color = ACCENT
            st.Transparency = 0.3

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -16, 1, 0)
            lbl.Position = UDim2.new(0, 8, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = TEXT
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextTransparency = 1
            lbl.Parent = toast

            local w = math.max(140, lbl.TextBounds.X + 30)
            TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = UDim2.new(0, w, 0, 34)}):Play()
            TweenService:Create(lbl, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
            task.wait(dur)
            TweenService:Create(toast, TweenInfo.new(0.25), {Size = UDim2.new(0, 0, 0, 34)}):Play()
            TweenService:Create(lbl, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
            task.wait(0.3)
            toast:Destroy()
        end)
    end)
end

-- Toggle factory
local function makeToggle(name, key, order)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = BG2
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = order
    row.Parent = Content
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = TEXT
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 38, 0, 18)
    pill.Position = UDim2.new(1, -48, 0.5, -9)
    pill.BackgroundColor3 = OFFCOL
    pill.Parent = row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = TEXT
    knob.Parent = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function render()
        local on = Settings[key]
        TweenService:Create(pill, TweenInfo.new(0.2), {BackgroundColor3 = on and ACCENT or OFFCOL}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Position = on and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
    end

    row.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        render()
        notify(name .. (Settings[key] and "  ✅ ON" or "  ❌ OFF"))
    end)
    render()
end

makeToggle("Auto Farm Mobs", "AutoFarm", 1)
makeToggle("Auto Collect Drops", "AutoCollect", 2)
makeToggle("Auto Stats (" .. Settings.StatToUpgrade .. ")", "AutoStats", 3)

-- Radius slider row
local radiusRow = Instance.new("Frame")
radiusRow.Size = UDim2.new(1, 0, 0, 52)
radiusRow.BackgroundColor3 = BG2
radiusRow.LayoutOrder = 4
radiusRow.Parent = Content
Instance.new("UICorner", radiusRow).CornerRadius = UDim.new(0, 8)

local radiusLbl = Instance.new("TextLabel")
radiusLbl.Size = UDim2.new(1, -24, 0, 20)
radiusLbl.Position = UDim2.new(0, 12, 0, 4)
radiusLbl.BackgroundTransparency = 1
radiusLbl.Text = "Farm Radius: " .. Settings.FarmRadius
radiusLbl.TextColor3 = MUTED
radiusLbl.Font = Enum.Font.Gotham
radiusLbl.TextSize = 12
radiusLbl.TextXAlignment = Enum.TextXAlignment.Left
radiusLbl.Parent = radiusRow

local sliderBack = Instance.new("Frame")
sliderBack.Size = UDim2.new(1, -24, 0, 6)
sliderBack.Position = UDim2.new(0, 12, 0, 32)
sliderBack.BackgroundColor3 = OFFCOL
sliderBack.Parent = radiusRow
Instance.new("UICorner", sliderBack).CornerRadius = UDim.new(1, 0)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(Settings.FarmRadius / 5000, 0, 1, 0)
sliderFill.BackgroundColor3 = ACCENT
sliderFill.Parent = sliderBack
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

local draggingSlider = false
sliderBack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local rel = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        Settings.FarmRadius = math.floor(100 + rel * 4900)
        sliderFill.Size = UDim2.new(rel, 0, 1, 0)
        radiusLbl.Text = "Farm Radius: " .. Settings.FarmRadius
    end
end)

-- Dragging window
do
    local dragging, dragStart, startPos = false, nil, nil
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Minimize
local FULL_HEIGHT = 240
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local target = minimized and UDim2.new(0, 260, 0, 38) or UDim2.new(0, 260, 0, FULL_HEIGHT)
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = target}):Play()
    MinBtn.Text = minimized and "+" or "—"
end)

-- Open animation
TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 260, 0, FULL_HEIGHT)}):Play()
notify("Sail Piece Hub loaded ⚔️", 3)

-- ========================= LOOPS =========================
-- Auto Farm
task.spawn(function()
    while Settings.Running do
        if Settings.AutoFarm and isAlive() then
            local ok = pcall(function()
                local mob, hum, hrp = getNearestMob()
                if mob and hum and hrp then
                    equipTool()
                    local _, root = getCharacter()
                    if root then
                        root.CFrame = hrp.CFrame * CFrame.new(0, 8, 5) * CFrame.Angles(math.rad(-30), 0, 0)
                        root.Velocity = Vector3.zero
                        attack()
                    end
                end
            end)
            if not ok then task.wait(0.5) end
        end
        task.wait(0.15)
    end
end)

-- Auto Collect Drops
task.spawn(function()
    local dropNames = {"beli", "belli", "berry", "money", "cash", "drop", "orb", "coin", "chest"}
    while Settings.Running do
        if Settings.AutoCollect and isAlive() then
            pcall(function()
                local _, root = getCharacter()
                if not root then return end
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if (obj:IsA("BasePart") or obj:IsA("MeshPart")) and not obj.Anchored == false then
                        local lname = obj.Name:lower()
                        for _, dn in ipairs(dropNames) do
                            if lname:find(dn) and (obj.Position - root.Position).Magnitude <= Settings.FarmRadius then
                                obj.CFrame = root.CFrame
                                if firetouchinterest then
                                    firetouchinterest(root, obj, 0)
                                    firetouchinterest(root, obj, 1)
                                end
                                break
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- Auto Stats
task.spawn(function()
    while Settings.Running do
        if Settings.AutoStats and isAlive() then
            pcall(function()
                local names = {"melee", "strength", "stat", "level", "upgrade", "addpoint", "trainstat"}
                for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                    if r:IsA("RemoteEvent") then
                        local ln = r.Name:lower()
                        for _, n in ipairs(names) do
                            if ln:find(n) then
                                r:FireServer(Settings.StatToUpgrade)
                                r:FireServer("Strength")
                                break
                            end
                        end
                    end
                end
            end)
        end
        task.wait(2)
    end
end)

-- Cleanup on GUI destroy
ScreenGui.Destroying:Connect(function()
    Settings.Running = false
    Settings.AutoFarm = false
    Settings.AutoCollect = false
    Settings.AutoStats = false
end)
