local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local virtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("TpzHub_UI")
if oldGui then
    oldGui:Destroy()
end

-- ==========================================
-- 0. CONFIG & COLORS
-- ==========================================
local GAME_NAME = "Backstreet Auto-Farm"

local COLORS = {
    Background = Color3.fromRGB(17, 19, 22),
    Panel = Color3.fromRGB(24, 27, 31),
    Secondary = Color3.fromRGB(31, 34, 39),
    SecondaryHover = Color3.fromRGB(38, 42, 48),
    Border = Color3.fromRGB(49, 53, 59),
    Text = Color3.fromRGB(238, 240, 243),
    TextSoft = Color3.fromRGB(190, 194, 201),
    Muted = Color3.fromRGB(137, 142, 151),
    Accent = Color3.fromRGB(92, 124, 156),
    AccentSoft = Color3.fromRGB(76, 103, 130),
    SliderBackground = Color3.fromRGB(54, 58, 64),
    Notification = Color3.fromRGB(20, 22, 25),
}

local states = {
    autoClick = false,
    antiAfk = true,
    autoFarm = false,
    autoSell = false
}

-- ==========================================
-- 1. BASE UI SETUP
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name = "TpzHub_UI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local connections = {}
local minimized = false

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function addCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
    return corner
end

local function addStroke(object, color, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = transparency or 0
    stroke.Thickness = 1
    stroke.Parent = object
    return stroke
end

local function tween(object, duration, properties)
    return TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
end

-- ==========================================
-- 2. MAIN WINDOW & HEADER
-- ==========================================
local window = create("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0, 570, 0, 430),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, gui)

addCorner(window, 14)
addStroke(window, COLORS.Border, 0.18)

local header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 68),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
}, window)

create("Frame", { Name = "Divider", Position = UDim2.new(0, 16, 1, -1), Size = UDim2.new(1, -32, 0, 1), BackgroundColor3 = COLORS.Border, BorderSizePixel = 0 }, header)

create("ImageLabel", { Name = "Logo", Position = UDim2.new(0, 18, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 38, 0, 38), BackgroundTransparency = 1, Image = "rbxassetid://85074945377894", ScaleType = Enum.ScaleType.Fit }, header)

create("TextLabel", { Name = "Title", Position = UDim2.new(0, 67, 0, 12), Size = UDim2.new(0, 240, 0, 27), BackgroundTransparency = 1, Text = "Tpz Hub", Font = Enum.Font.GothamBold, TextSize = 19, TextColor3 = COLORS.Text, TextXAlignment = Enum.TextXAlignment.Left }, header)

create("TextLabel", { Name = "GameName", Position = UDim2.new(0, 68, 0, 38), Size = UDim2.new(0, 240, 0, 17), BackgroundTransparency = 1, Text = GAME_NAME, Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = COLORS.Muted, TextXAlignment = Enum.TextXAlignment.Left }, header)

local topStatus = create("TextLabel", { Name = "Status", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -95, 0.5, 0), Size = UDim2.new(0, 100, 0, 20), BackgroundTransparency = 1, Text = "IDLE", Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = COLORS.Accent, TextXAlignment = Enum.TextXAlignment.Right }, header)

-- Window Controls (Minimize & Close)
local minimizeButton = create("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -51, 0.5, 0), Size = UDim2.new(0, 32, 0, 32), BackgroundColor3 = COLORS.Secondary, Text = "—", Font = Enum.Font.GothamMedium, TextSize = 15, TextColor3 = COLORS.TextSoft, AutoButtonColor = false }, header)
addCorner(minimizeButton, 9)

local closeButton = create("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -13, 0.5, 0), Size = UDim2.new(0, 32, 0, 32), BackgroundColor3 = COLORS.Secondary, Text = "×", Font = Enum.Font.GothamMedium, TextSize = 17, TextColor3 = COLORS.TextSoft, AutoButtonColor = false }, header)
addCorner(closeButton, 9)

connect(closeButton.MouseButton1Click, function() gui:Destroy() end)
connect(minimizeButton.MouseButton1Click, function()
    minimized = not minimized
    tween(window, 0.3, { Size = minimized and UDim2.new(0, 570, 0, 68) or UDim2.new(0, 570, 0, 430) }):Play()
end)

-- Dragging Logic Fix
local dragging, dragInput, dragStart, startPosition
connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = window.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
connect(UserInputService.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
game:GetService("RunService").RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        window.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)

-- ==========================================
-- 3. CONTENT AREA
-- ==========================================
local body = create("Frame", { Name = "Body", Position = UDim2.new(0, 0, 0, 68), Size = UDim2.new(1, 0, 1, -68), BackgroundTransparency = 1 }, window)

local navigation = create("Frame", { Name = "Navigation", Position = UDim2.new(0, 12, 0, 12), Size = UDim2.new(0, 130, 1, -24), BackgroundColor3 = COLORS.Panel }, body)
addCorner(navigation, 12)
addStroke(navigation, COLORS.Border, 0.35)
create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10) }, navigation)
create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, navigation)

local navButton = create("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = COLORS.Secondary, Text = "Main", Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = COLORS.Text }, navigation)
addCorner(navButton, 6)

local content = create("Frame", { Name = "Content", Position = UDim2.new(0, 154, 0, 12), Size = UDim2.new(1, -166, 1, -24), BackgroundColor3 = COLORS.Panel }, body)
addCorner(content, 12)
addStroke(content, COLORS.Border, 0.35)

create("TextLabel", { Position = UDim2.new(0, 19, 0, 16), Size = UDim2.new(1, -38, 0, 24), BackgroundTransparency = 1, Text = "Auto Farming", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = COLORS.Text, TextXAlignment = Enum.TextXAlignment.Left }, content)
create("TextLabel", { Position = UDim2.new(0, 19, 0, 41), Size = UDim2.new(1, -38, 0, 18), BackgroundTransparency = 1, Text = "Deco1 Smart Pathing & Anti-AFK.", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = COLORS.Muted, TextXAlignment = Enum.TextXAlignment.Left }, content)

local scroll = create("ScrollingFrame", { Name = "Scroll", Position = UDim2.new(0, 14, 0, 72), Size = UDim2.new(1, -28, 1, -86), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = COLORS.Border }, content)
create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), PaddingBottom = UDim.new(0, 12) }, scroll)
create("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

local function createSection(text)
    create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = COLORS.Muted, TextXAlignment = Enum.TextXAlignment.Left }, scroll)
end

-- Modified Toggle to sync with `states` table
local function createToggle(text, description, stateName, default)
    states[stateName] = default or false
    local container = create("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = COLORS.Secondary }, scroll)
    addCorner(container, 11)
    
    create("TextLabel", { Position = UDim2.new(0, 13, 0, 8), Size = UDim2.new(1, -75, 0, 18), BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = COLORS.Text, TextXAlignment = Enum.TextXAlignment.Left }, container)
    create("TextLabel", { Position = UDim2.new(0, 13, 0, 28), Size = UDim2.new(1, -75, 0, 15), BackgroundTransparency = 1, Text = description, Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = COLORS.Muted, TextXAlignment = Enum.TextXAlignment.Left }, container)
    
    local toggle = create("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -13, 0.5, 0), Size = UDim2.new(0, 38, 0, 21), BackgroundColor3 = COLORS.SliderBackground, Text = "" }, container)
    addCorner(toggle, 12)
    
    local knob = create("Frame", { Position = UDim2.new(0, 3, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 15, 0, 15), BackgroundColor3 = COLORS.Text }, toggle)
    addCorner(knob, 9)

    local function update()
        if states[stateName] then
            tween(toggle, 0.15, { BackgroundColor3 = COLORS.Accent }):Play()
            tween(knob, 0.15, { Position = UDim2.new(1, -18, 0.5, 0) }):Play()
        else
            tween(toggle, 0.15, { BackgroundColor3 = COLORS.SliderBackground }):Play()
            tween(knob, 0.15, { Position = UDim2.new(0, 3, 0.5, 0) }):Play()
        end
    end

    connect(toggle.MouseButton1Click, function()
        states[stateName] = not states[stateName]
        update()
    end)
    update()
end

local function createTextArea(titleText, placeholder)
    local container = create("Frame", { Size = UDim2.new(1, 0, 0, 80), BackgroundColor3 = COLORS.Secondary }, scroll)
    addCorner(container, 11)
    create("TextLabel", { Position = UDim2.new(0, 13, 0, 8), Size = UDim2.new(1, -26, 0, 18), BackgroundTransparency = 1, Text = titleText, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = COLORS.Text, TextXAlignment = Enum.TextXAlignment.Left }, container)
    local textBox = create("TextBox", { Position = UDim2.new(0, 12, 0, 30), Size = UDim2.new(1, -24, 1, -40), BackgroundColor3 = COLORS.Panel, PlaceholderText = placeholder, TextColor3 = COLORS.TextSoft, Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ClearTextOnFocus = false, MultiLine = true }, container)
    addCorner(textBox, 8)
    return textBox
end

-- UI Building
createSection("General Controls")
createToggle("Auto Click", "Spam klik kiri otomatis pas equip tool.", "autoClick", false)
createToggle("Anti AFK (Kill Script)", "Membunuh script AFK bawaan game.", "antiAfk", true)
createToggle("Auto Farm (Stick)", "Prioritas Mythic > Legendary & Auto Dumpster Jump.", "autoFarm", false)
createToggle("Auto Sell (On Full)", "Smart Path ke NPC pakai jalan Deco1.", "autoSell", false)

createSection("Live Logs")
local logBox = createTextArea("Status Monitor", "Waiting for activity...")

local function setLogText(text)
    logBox.Text = tostring(text)
    topStatus.Text = states.autoFarm and "FARMING" or (states.autoSell and "SELLING" or "IDLE")
end

-- ==========================================
-- 4. UTILITIES & RADAR
-- ==========================================
player.Idled:Connect(function()
    if states.antiAfk then
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new())
    end
end)

-- Pembunuh AFKScript Bawaan Game
task.spawn(function()
    while task.wait(2) do
        if states.antiAfk then
            for _, obj in pairs(player:GetDescendants()) do
                if obj:IsA("LocalScript") and obj.Name == "AFKScript" and obj.Disabled == false then
                    obj.Disabled = true
                    setLogText("🛡️ AFKScript Player Killed!")
                end
            end
            local character = player.Character
            if character then
                for _, obj in pairs(character:GetDescendants()) do
                    if obj:IsA("LocalScript") and obj.Name == "AFKScript" and obj.Disabled == false then
                        obj.Disabled = true
                        setLogText("🛡️ AFKScript Character Killed!")
                    end
                end
                local hum = character:FindFirstChild("Humanoid")
                if hum and hum:GetState() == Enum.HumanoidStateType.Physics then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end
    end
end)

local function getBestTrashInStick()
    local trashTriggersFolder = workspace:FindFirstChild("TrashTriggers", true)
    if not trashTriggersFolder then return nil, nil end
    local stickFolder = trashTriggersFolder:FindFirstChild("Stick")
    if not stickFolder then return nil, nil end
    
    for _, trigger in ipairs(stickFolder:GetChildren()) do
        if trigger:IsA("BasePart") then
            local trashGui = trigger:FindFirstChild("TrashGui")
            if trashGui and trashGui:FindFirstChild("Mythic") and trashGui.Mythic.Visible then
                return trigger, "Mythic"
            end
        end
    end
    for _, trigger in ipairs(stickFolder:GetChildren()) do
        if trigger:IsA("BasePart") then
            local trashGui = trigger:FindFirstChild("TrashGui")
            if trashGui and trashGui:FindFirstChild("Legendary") and trashGui.Legendary.Visible then
                return trigger, "Legendary"
            end
        end
    end
    return nil, nil
end

local function getTrashMasterNPC()
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and (prompt.ObjectText == "Trash Master" or prompt.ActionText == "Open shop") then
            return prompt.Parent
        end
    end
    return nil
end

local function getShopTargetPosition()
    local deco1 = workspace:FindFirstChild("Deco1", true)
    if deco1 and deco1:IsA("BasePart") then return deco1.Position end
    local npc = getTrashMasterNPC()
    if npc then return npc.Position end
    return nil
end

local function isInventoryFull()
    for _, v in ipairs(playerGui:GetDescendants()) do
        if v:IsA("TextLabel") and v.Visible then
            local current, max = string.match(v.Text, "^(%d+)%s*/%s*(%d+)$")
            if current and max then
                local numMax = tonumber(max)
                if numMax > 100 and tonumber(current) >= (numMax - 10) then return true end
            end
        end
    end
    return false
end

local function clickGuiButtonByText(targetText)
    for _, v in ipairs(playerGui:GetDescendants()) do
        if v:IsA("TextLabel") and string.find(string.upper(v.Text), string.upper(targetText)) then
            local btn = v.Parent
            if btn and btn:IsA("GuiButton") and getconnections then
                for _, conn in pairs(getconnections(btn.MouseButton1Click)) do
                    conn:Function()
                end
                return true
            end
        end
    end
    return false
end

-- ==========================================
-- 5. SMART PATHFINDING
-- ==========================================
local function smoothWalk(targetPos, breakCondition, stopDistance)
    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    local path = PathfindingService:CreatePath({ AgentRadius = 1.5, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 3 })
    local success, _ = pcall(function() path:ComputeAsync(rootPart.Position, targetPos) end)

    if success and (path.Status == Enum.PathStatus.Success or path.Status == Enum.PathStatus.ClosestNoPath) then
        local waypoints = path:GetWaypoints()
        for i = 2, #waypoints do
            if not states.autoFarm and not states.autoSell then return end
            if (rootPart.Position - targetPos).Magnitude <= stopDistance then return end
            if breakCondition and breakCondition() then return end 
            
            local wp = waypoints[i]
            if wp.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
            
            humanoid:MoveTo(wp.Position)
            
            local timeout, stuckTimer = tick(), 0
            while tick() - timeout < 2 do
                task.wait(0.05)
                if (rootPart.Position - targetPos).Magnitude <= stopDistance then return end
                if breakCondition and breakCondition() then return end
                if (Vector2.new(rootPart.Position.X, rootPart.Position.Z) - Vector2.new(wp.Position.X, wp.Position.Z)).Magnitude < 1.5 then break end
                
                if rootPart.AssemblyLinearVelocity.Magnitude < 0.5 then
                    stuckTimer = stuckTimer + 0.05
                    humanoid.Jump = true
                    if stuckTimer > 1 then
                        setLogText("⚠️ Stuck! Auto unstuck...")
                        humanoid:MoveTo(rootPart.Position - rootPart.CFrame.LookVector * 5)
                        task.wait(0.5)
                        return 
                    end
                else
                    stuckTimer = 0 
                end
            end
        end
    else
        humanoid.Jump = true
        humanoid:MoveTo(rootPart.Position + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)))
        task.wait(0.5)
    end
end

-- ==========================================
-- 6. CORE LOOP (FARMING & SELLING)
-- ==========================================
local isSellingPhase = false
local sellFailCounter = 0

task.spawn(function()
    while task.wait(0.2) do
        if not ScreenGui.Parent then break end 
        
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart or humanoid.Health <= 0 then continue end

        if states.autoClick and not states.autoFarm then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end
        
        if states.autoSell and isInventoryFull() and not isSellingPhase then
            isSellingPhase = true
            sellFailCounter = 0
        end

        if isSellingPhase then
            local shopTargetPos = getShopTargetPosition()
            local npc = getTrashMasterNPC() 
            
            if shopTargetPos and npc then
                local dist = (rootPart.Position - shopTargetPos).Magnitude
                if dist > 4 then
                    setLogText("Tas Penuh! Otw Shop (Deco1 Path)...")
                    smoothWalk(shopTargetPos, nil, 3) 
                else
                    humanoid:MoveTo(rootPart.Position) 
                    setLogText("Membuka Shop...")
                    
                    local prompt = npc:FindFirstChildOfClass("ProximityPrompt")
                    if prompt and fireproximityprompt then fireproximityprompt(prompt) end
                    task.wait(1.5) 
                    
                    setLogText("Mencet tombol SELL ALL...")
                    if clickGuiButtonByText("SELL ALL") then
                        task.wait(1) 
                        clickGuiButtonByText("X")
                        isSellingPhase = false
                        
                        -- Auto Equip
                        local backpack = player:FindFirstChild("Backpack")
                        if backpack and backpack:FindFirstChildOfClass("Tool") then
                            humanoid:EquipTool(backpack:FindFirstChildOfClass("Tool"))
                        end
                        task.wait(1)
                    else
                        sellFailCounter = sellFailCounter + 1
                        setLogText("Gagal ngeklik tombol... ("..sellFailCounter.."/3)")
                        task.wait(1)
                        if sellFailCounter > 3 then
                            isSellingPhase = false
                            clickGuiButtonByText("X")
                        end
                    end
                end
            else
                setLogText("⚠️ Deco1 / Trash Master tidak ditemukan!")
                isSellingPhase = false
                task.wait(2)
            end
            
        elseif states.autoFarm then
            local targetPart, currentRarity = getBestTrashInStick()
            if targetPart then
                local dist = (rootPart.Position - targetPart.Position).Magnitude
                if dist > 5 then
                    setLogText("Otw Loot " .. currentRarity .. "!")
                    
                    local breakCheck = function()
                        if currentRarity == "Legendary" then
                            local _, newRarity = getBestTrashInStick()
                            if newRarity == "Mythic" then return true end
                        end
                        return false
                    end
                    smoothWalk(targetPart.Position, breakCheck, 4) 
                else
                    setLogText("Nge-loot " .. currentRarity .. "!")
                    
                    -- Jump over dumpsters
                    if targetPart.Position.Y > rootPart.Position.Y + 1 then
                        humanoid.Jump = true
                        humanoid:MoveTo(targetPart.Position) 
                    else
                        humanoid:MoveTo(rootPart.Position) 
                    end
                    
                    local equippedTool = character:FindFirstChildOfClass("Tool")
                    if not equippedTool then
                        local backpack = player:FindFirstChild("Backpack")
                        if backpack and backpack:FindFirstChildOfClass("Tool") then
                            humanoid:EquipTool(backpack:FindFirstChildOfClass("Tool"))
                            task.wait(0.1)
                            equippedTool = character:FindFirstChildOfClass("Tool")
                        end
                    end
                    if equippedTool then equippedTool:Activate() end
                end
            else
                setLogText("Menunggu Mythic / Legend spawn...")
                humanoid:MoveTo(rootPart.Position)
            end
        elseif not states.autoFarm and not states.autoSell then
            setLogText("Idle. Nyalakan toggle untuk memulai.")
        end
    end
end)

-- Opening Animation
local originalSize = window.Size
window.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 0)
tween(window, 0.3, { Size = originalSize }):Play()