local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local virtualUser = game:GetService("VirtualUser")
local PathfindingService = game:GetService("PathfindingService")

if playerGui:FindFirstChild("TpzHub_UI") then
    playerGui.TpzHub_UI:Destroy()
end

-- ==========================================
-- 1. SETUP TAMPILAN UTAMA
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TpzHub_UI"
ScreenGui.Parent = playerGui

local HeaderFrame = Instance.new("Frame")
HeaderFrame.Size = UDim2.new(0, 220, 0, 35)
HeaderFrame.Position = UDim2.new(0.5, -110, 0.1, 0)
HeaderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
HeaderFrame.Active = true
HeaderFrame.Draggable = true
HeaderFrame.Parent = ScreenGui

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 6)
HeaderCorner.Parent = HeaderFrame

local HeaderBtn = Instance.new("TextButton")
HeaderBtn.Size = UDim2.new(1, 0, 1, 0)
HeaderBtn.BackgroundTransparency = 1
HeaderBtn.Text = "  tpzhub - backstreet"
HeaderBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HeaderBtn.Font = Enum.Font.GothamBold
HeaderBtn.TextSize = 14
HeaderBtn.TextXAlignment = Enum.TextXAlignment.Left
HeaderBtn.Parent = HeaderFrame

local ArrowLbl = Instance.new("TextLabel")
ArrowLbl.Size = UDim2.new(0, 30, 1, 0)
ArrowLbl.Position = UDim2.new(1, -30, 0, 0)
ArrowLbl.BackgroundTransparency = 1
ArrowLbl.Text = "↓"
ArrowLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
ArrowLbl.Font = Enum.Font.GothamBold
ArrowLbl.TextSize = 14
ArrowLbl.Parent = HeaderFrame

-- ==========================================
-- 2. SETUP DROPDOWN MENU
-- ==========================================
local DropdownFrame = Instance.new("Frame")
DropdownFrame.Size = UDim2.new(1, 0, 0, 140)
DropdownFrame.Position = UDim2.new(0, 0, 1, 2)
DropdownFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
DropdownFrame.Visible = false
DropdownFrame.Parent = HeaderFrame

local DropCorner = Instance.new("UICorner")
DropCorner.CornerRadius = UDim.new(0, 6)
DropCorner.Parent = DropdownFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = DropdownFrame

local function createToggle(name, defaultState)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 35)
    Btn.BackgroundTransparency = 1
    Btn.Text = "  " .. name
    Btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 13
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.Parent = DropdownFrame
    
    local CheckBoxLbl = Instance.new("TextLabel")
    CheckBoxLbl.Size = UDim2.new(0, 30, 1, 0)
    CheckBoxLbl.Position = UDim2.new(1, -30, 0, 0)
    CheckBoxLbl.BackgroundTransparency = 1
    CheckBoxLbl.Text = defaultState and "☑" or "☐"
    CheckBoxLbl.TextColor3 = defaultState and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 255, 255)
    CheckBoxLbl.Font = Enum.Font.GothamBold
    CheckBoxLbl.TextSize = 16
    CheckBoxLbl.Parent = Btn
    
    return Btn, CheckBoxLbl
end

local AutoClickBtn, AutoClickCheck = createToggle("auto click", false)
local AntiAfkBtn, AntiAfkCheck = createToggle("anti afk", true)
local AutoFarmBtn, AutoFarmCheck = createToggle("auto farm (stick)", false)
local AutoSellBtn, AutoSellCheck = createToggle("auto sell (on full)", false)

-- ==========================================
-- 3. SETUP UI INFO
-- ==========================================
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, 0, 0, 30)
InfoLabel.Position = UDim2.new(0, 0, 1, -40) 
InfoLabel.BackgroundTransparency = 0.5
InfoLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
InfoLabel.Text = "Status: Idle"
InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
InfoLabel.Font = Enum.Font.GothamBold
InfoLabel.TextSize = 14
InfoLabel.Parent = ScreenGui

-- ==========================================
-- 4. LOGIKA UI & STATE
-- ==========================================
local isExpanded = false
local states = {
    autoClick = false,
    antiAfk = true,
    autoFarm = false,
    autoSell = false
}

HeaderBtn.MouseButton1Click:Connect(function()
    isExpanded = not isExpanded
    DropdownFrame.Visible = isExpanded
    ArrowLbl.Text = isExpanded and "↑" or "↓"
end)

local function updateToggle(btnCheck, stateName)
    states[stateName] = not states[stateName]
    btnCheck.Text = states[stateName] and "☑" or "☐"
    btnCheck.TextColor3 = states[stateName] and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 255, 255)
end

AutoClickBtn.MouseButton1Click:Connect(function() updateToggle(AutoClickCheck, "autoClick") end)
AntiAfkBtn.MouseButton1Click:Connect(function() updateToggle(AntiAfkCheck, "antiAfk") end)
AutoFarmBtn.MouseButton1Click:Connect(function() updateToggle(AutoFarmCheck, "autoFarm") end)
AutoSellBtn.MouseButton1Click:Connect(function() updateToggle(AutoSellCheck, "autoSell") end)

-- Anti Kick Roblox Default
player.Idled:Connect(function()
    if states.antiAfk then
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new())
    end
end)

-- ==========================================
-- 5. KILLER AFKSCRIPT (BYPASS)
-- ==========================================
task.spawn(function()
    while task.wait(2) do
        if states.antiAfk then
            for _, obj in pairs(player:GetDescendants()) do
                if obj:IsA("LocalScript") and obj.Name == "AFKScript" then
                    if obj.Disabled == false then
                        obj.Disabled = true 
                        InfoLabel.Text = "🛡️ AFKScript Berhasil Dibunuh!"
                        InfoLabel.TextColor3 = Color3.fromRGB(50, 255, 255)
                        task.wait(1)
                    end
                end
            end
            
            local character = player.Character
            if character then
                for _, obj in pairs(character:GetDescendants()) do
                    if obj:IsA("LocalScript") and obj.Name == "AFKScript" then
                        if obj.Disabled == false then
                            obj.Disabled = true
                            InfoLabel.Text = "🛡️ AFKScript Berhasil Dibunuh!"
                            InfoLabel.TextColor3 = Color3.fromRGB(50, 255, 255)
                            task.wait(1)
                        end
                    end
                end
            end
            
            local hum = character and character:FindFirstChild("Humanoid")
            if hum and hum:GetState() == Enum.HumanoidStateType.Physics then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end
end)

-- ==========================================
-- 6. FUNGSI RADAR & UTILITAS
-- ==========================================
local function getBestTrashInStick()
    local trashTriggersFolder = workspace:FindFirstChild("TrashTriggers", true)
    if not trashTriggersFolder then return nil, nil end
    local stickFolder = trashTriggersFolder:FindFirstChild("Stick")
    if not stickFolder then return nil, nil end
    
    for _, trigger in ipairs(stickFolder:GetChildren()) do
        if trigger:IsA("BasePart") then
            local trashGui = trigger:FindFirstChild("TrashGui")
            if trashGui then
                local mythicLabel = trashGui:FindFirstChild("Mythic")
                if mythicLabel and mythicLabel.Visible == true then
                    return trigger, "Mythic"
                end
            end
        end
    end
    
    for _, trigger in ipairs(stickFolder:GetChildren()) do
        if trigger:IsA("BasePart") then
            local trashGui = trigger:FindFirstChild("TrashGui")
            if trashGui then
                local legendLabel = trashGui:FindFirstChild("Legendary")
                if legendLabel and legendLabel.Visible == true then
                    return trigger, "Legendary"
                end
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
    if deco1 and deco1:IsA("BasePart") then
        return deco1.Position
    end
    
    local npc = getTrashMasterNPC()
    if npc then
        return npc.Position
    end
    return nil
end

local function isInventoryFull()
    for _, v in ipairs(playerGui:GetDescendants()) do
        if v:IsA("TextLabel") and v.Visible then
            local current, max = string.match(v.Text, "^(%d+)%s*/%s*(%d+)$")
            if current and max then
                local numCurrent = tonumber(current)
                local numMax = tonumber(max)
                if numMax > 100 then
                    if numCurrent >= (numMax - 10) then
                        return true
                    end
                end
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
-- 7. SMART PATHFINDING
-- ==========================================
local function smoothWalk(targetPos, breakCondition, stopDistance)
    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end

    local path = PathfindingService:CreatePath({
        AgentRadius = 1.5,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 3 
    })

    local success, _ = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPos)
    end)

    if success and (path.Status == Enum.PathStatus.Success or path.Status == Enum.PathStatus.ClosestNoPath) then
        local waypoints = path:GetWaypoints()
        for i = 2, #waypoints do
            if not states.autoFarm and not states.autoSell then return end
            if (rootPart.Position - targetPos).Magnitude <= stopDistance then return end
            if breakCondition and breakCondition() then return end 
            
            local wp = waypoints[i]
            if wp.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
            
            humanoid:MoveTo(wp.Position)
            
            local timeout = tick()
            local stuckTimer = 0
            
            while tick() - timeout < 2 do
                task.wait(0.05)
                
                if (rootPart.Position - targetPos).Magnitude <= stopDistance then return end
                if breakCondition and breakCondition() then return end
                
                local distToWp = (Vector2.new(rootPart.Position.X, rootPart.Position.Z) - Vector2.new(wp.Position.X, wp.Position.Z)).Magnitude
                if distToWp < 1.5 then break end
                
                if rootPart.AssemblyLinearVelocity.Magnitude < 0.5 then
                    stuckTimer = stuckTimer + 0.05
                    humanoid.Jump = true
                    
                    if stuckTimer > 1 then
                        InfoLabel.Text = "⚠️ Nyangkut! Mencari rute baru..."
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
        local randomOffset = Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
        humanoid:MoveTo(rootPart.Position + randomOffset)
        task.wait(0.5)
    end
end

-- ==========================================
-- 8. CORE LOOP 
-- ==========================================
local isSellingPhase = false
local sellFailCounter = 0
local savedToolName = "" -- FITUR BARU: Tool Memory (Nginget alat lo)

task.spawn(function()
    while task.wait(0.2) do
        if not ScreenGui.Parent then break end 
        
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        
        if not humanoid or not rootPart or humanoid.Health <= 0 then continue end

        -- Nginget alat (Tool) yang lagi dipegang sebelum tas penuh
        local activeTool = character:FindFirstChildOfClass("Tool")
        if activeTool then
            savedToolName = activeTool.Name
        end

        if states.autoClick and not states.autoFarm then
            if activeTool then activeTool:Activate() end
        end
        
        if states.autoSell and isInventoryFull() and not isSellingPhase then
            isSellingPhase = true
            sellFailCounter = 0
        end

        -- FASE 1: JUAL BARANG
        if isSellingPhase then
            local shopTargetPos = getShopTargetPosition()
            local npc = getTrashMasterNPC() 
            
            if shopTargetPos and npc then
                local dist = (rootPart.Position - shopTargetPos).Magnitude
                
                if dist > 4 then
                    InfoLabel.Text = "🏃 Tas Penuh! Otw Shop..."
                    InfoLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
                    
                    smoothWalk(shopTargetPos, nil, 3) 
                else
                    humanoid:MoveTo(rootPart.Position) 
                    InfoLabel.Text = "💸 Membuka Shop..."
                    InfoLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
                    
                    local prompt = npc:FindFirstChildOfClass("ProximityPrompt")
                    if prompt and fireproximityprompt then
                        fireproximityprompt(prompt)
                    end
                    
                    task.wait(1.5) 
                    
                    InfoLabel.Text = "🤑 Mencet tombol SELL ALL..."
                    local isClicked = clickGuiButtonByText("SELL ALL")
                    
                    if isClicked then
                        task.wait(1) 
                        clickGuiButtonByText("X")
                        isSellingPhase = false
                        
                        -- FITUR BARU: AUTO EQUIP CERDAS (Sesuai Memory)
                        local backpack = player:FindFirstChild("Backpack")
                        if backpack then
                            local toolToEquip = nil
                            
                            -- Cari dulu alat dengan nama yang udah disave
                            if savedToolName ~= "" then
                                toolToEquip = backpack:FindFirstChild(savedToolName)
                            end
                            
                            -- Kalau gagal, baru cari Tool apapun secara random
                            if not toolToEquip then
                                toolToEquip = backpack:FindFirstChildOfClass("Tool")
                            end
                            
                            if toolToEquip then
                                humanoid:EquipTool(toolToEquip)
                            end
                        end
                        
                        task.wait(1)
                    else
                        sellFailCounter = sellFailCounter + 1
                        InfoLabel.Text = "⚠️ Gagal ngeklik tombol..."
                        task.wait(1)
                        if sellFailCounter > 3 then
                            isSellingPhase = false
                            clickGuiButtonByText("X")
                        end
                    end
                end
            else
                InfoLabel.Text = "⚠️ Deco1 / NPC Trash Master ngilang!"
                InfoLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                isSellingPhase = false
                task.wait(2)
            end
            
        -- FASE 2: FARMING (MYTHIC > LEGENDARY)
        elseif states.autoFarm then
            local targetPart, currentRarity = getBestTrashInStick()
            
            if targetPart then
                local dist = (rootPart.Position - targetPart.Position).Magnitude
                
                if dist > 5 then
                    if currentRarity == "Mythic" then
                        InfoLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                    else
                        InfoLabel.TextColor3 = Color3.fromRGB(255, 255, 50)
                    end
                    
                    InfoLabel.Text = "🏃 Otw ke " .. currentRarity .. " di " .. targetPart.Name
                    
                    local breakCheck = function()
                        if currentRarity == "Legendary" then
                            local _, newRarity = getBestTrashInStick()
                            if newRarity == "Mythic" then
                                return true 
                            end
                        end
                        return false
                    end
                    
                    smoothWalk(targetPart.Position, breakCheck, 4) 
                else
                    if currentRarity == "Mythic" then
                        InfoLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                    else
                        InfoLabel.TextColor3 = Color3.fromRGB(255, 255, 50)
                    end
                    
                    InfoLabel.Text = "⛏️ Nge-loot " .. currentRarity .. "!"
                    
                    -- FITUR BARU: LOGIKA BAK SAMPAH TINGGI (DIPERBAIKI)
                    -- Menghitung Jarak Horizontal Aja (Ngapus hitungan Tinggi biar botnya maksa maju)
                    local flatDist = (Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z) - Vector3.new(targetPart.Position.X, 0, targetPart.Position.Z)).Magnitude
                    local heightDiff = targetPart.Position.Y - rootPart.Position.Y
                    
                    if heightDiff > 1.5 or flatDist > 2 then
                        -- Terus jalan maju paksa masuk ke dalam bak sampah
                        humanoid:MoveTo(targetPart.Position)
                        
                        -- Kalau nempel (kecepatan lambat) ATAU targetnya ada di atas -> Spam Loncat
                        if rootPart.AssemblyLinearVelocity.Magnitude < 2 or heightDiff > 1.5 then
                            humanoid.Jump = true
                        end
                    else
                        -- Kalau bener-bener udah ada di titik (di dalem bak / tanah datar) baru ngerem
                        humanoid:MoveTo(rootPart.Position) 
                    end
                    
                    -- Sistem Equip Waktu Nge-loot (Juga pakai Memory Tool)
                    local equippedTool = character:FindFirstChildOfClass("Tool")
                    if not equippedTool then
                        local backpack = player:FindFirstChild("Backpack")
                        if backpack then
                            local toolToEquip = nil
                            if savedToolName ~= "" then
                                toolToEquip = backpack:FindFirstChild(savedToolName)
                            end
                            if not toolToEquip then
                                toolToEquip = backpack:FindFirstChildOfClass("Tool")
                            end
                            
                            if toolToEquip then
                                humanoid:EquipTool(toolToEquip)
                                task.wait(0.1)
                                equippedTool = character:FindFirstChildOfClass("Tool")
                            end
                        end
                    end
                    if equippedTool then equippedTool:Activate() end
                end
            else
                InfoLabel.Text = "🔍 Menunggu Mythic / Legend..."
                InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                humanoid:MoveTo(rootPart.Position)
            end
        elseif not states.autoFarm and not states.autoClick then
            InfoLabel.Text = "Status: Idle"
            InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
end)
