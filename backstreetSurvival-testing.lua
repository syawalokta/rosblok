-- backstreet survival
-- ui dimuat dari github, logic game tetap di file ini

local TpzUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/syawalokta/rosblok/refs/heads/master/ui/tpz-ui.lua"
))()

local ui = TpzUI.new({
    Title = "Tpz Hub",
    GameName = "Backstreet Survival",
    Icon = "rbxassetid://85074945377894",
})

local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local virtualUser = game:GetService("VirtualUser")
local PathfindingService = game:GetService("PathfindingService")

local states = {
    autoClick = false,
    antiAfk = true,
    autoFarm = false,
    autoSell = false
}

ui:CreateSection("Automation", "Main")

ui:CreateToggle(
    "Auto Click",
    "otomatis menggunakan tool saat aktif.",
    states.autoClick,
    function(enabled)
        states.autoClick = enabled
        ui:SetStatus(enabled and "Auto Click" or "READY")
        ui:AddLog("auto click: " .. (enabled and "on" or "off"))
    end,
    "Main"
)

ui:CreateToggle(
    "Anti AFK",
    "mencegah karakter menjadi idle.",
    states.antiAfk,
    function(enabled)
        states.antiAfk = enabled
        ui:SetStatus(enabled and "Anti AFK" or "READY")
        ui:AddLog("anti afk: " .. (enabled and "on" or "off"))
    end,
    "Main"
)

ui:CreateToggle(
    "Auto Farm",
    "prioritas target Mythic lalu Legendary.",
    states.autoFarm,
    function(enabled)
        states.autoFarm = enabled
        ui:SetStatus(enabled and "Farming" or "READY")
        ui:Notify(
            "Auto Farm",
            enabled and "auto farm aktif." or "auto farm dimatikan.",
            "rbxassetid://85074945377894"
        )
        ui:AddLog("auto farm: " .. (enabled and "on" or "off"))
    end,
    "Farming"
)

ui:CreateToggle(
    "Auto Sell",
    "jual otomatis saat inventory hampir penuh.",
    states.autoSell,
    function(enabled)
        states.autoSell = enabled
        ui:SetStatus(enabled and "Auto Sell" or "READY")
        ui:Notify(
            "Auto Sell",
            enabled and "auto sell aktif." or "auto sell dimatikan.",
            "rbxassetid://85074945377894"
        )
        ui:AddLog("auto sell: " .. (enabled and "on" or "off"))
    end,
    "Farming"
)

ui:CreateSection("Player", "Player")

ui:CreateButton(
    "Refresh Status",
    "perbarui status interface.",
    function()
        ui:SetStatus("READY")
        ui:AddLog("status diperbarui")
    end,
    "Player"
)

ui:CreateSection("Teleport", "Teleport")

ui:CreateButton(
    "Refresh Shop Target",
    "cek kembali lokasi Trash Master dan Deco1.",
    function()
        local npc = nil
        for _, prompt in ipairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt")
                and (prompt.ObjectText == "Trash Master" or prompt.ActionText == "Open shop") then
                npc = prompt.Parent
                break
            end
        end

        if npc then
            ui:SetStatus("Shop Ready")
            ui:AddLog("Trash Master ditemukan")
        else
            ui:SetStatus("Shop Missing")
            ui:AddLog("Trash Master tidak ditemukan")
        end
    end,
    "Teleport"
)

ui:CreateSection("Interface", "Settings")

ui:CreateButton(
    "Minimize",
    "sembunyikan panel dan gunakan floating button.",
    function()
        ui:Minimize()
    end,
    "Settings"
)

ui:CreateLogBox("Main")
ui:AddLog("Backstreet Survival loaded")
ui:AddLog("UI library loaded from GitHub")
ui:SetStatus("READY")


-- Anti Kick Roblox Default (20 Menit)
player.Idled:Connect(function()
    if states.antiAfk then
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new())
    end
end)

-- 5. KILLER AFKSCRIPT (NEW BYPASS)
task.spawn(function()
    while task.wait(2) do
        if states.antiAfk then
            -- Cari script pelaku dari player
            for _, obj in pairs(player:GetDescendants()) do
                if obj:IsA("LocalScript") and obj.Name == "AFKScript" then
                    if obj.Disabled == false then
                        obj.Disabled = true -- MATIKAN SCRIPTNYA!
                        ui:SetStatus("Anti AFK")
                        ui:AddLog("AFKScript berhasil dimatikan")
                        ui:SetStatus("Anti AFK", Color3.fromRGB(50, 255, 255))
                        task.wait(1)
                    end
                end
            end
            
            -- Cari script pelaku dari karakter (kalau dia spawn disana)
            local character = player.Character
            if character then
                for _, obj in pairs(character:GetDescendants()) do
                    if obj:IsA("LocalScript") and obj.Name == "AFKScript" then
                        if obj.Disabled == false then
                            obj.Disabled = true
                            ui:SetStatus("Anti AFK")
                        ui:AddLog("AFKScript berhasil dimatikan")
                            ui:SetStatus("Anti AFK", Color3.fromRGB(50, 255, 255))
                            task.wait(1)
                        end
                    end
                end
            end
            
            -- Bangunin karakter kalau sempat tertidur sebelum scriptnya mati
            local hum = character and character:FindFirstChild("Humanoid")
            if hum and hum:GetState() == Enum.HumanoidStateType.Physics then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end
end)

-- 6. FUNGSI RADAR & UTILITAS
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

-- 7. SMART PATHFINDING (Tetep Pakai Deco1)
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
                        ui:SetStatus("Nyangkut", Color3.fromRGB(255, 180, 80))
                        ui:AddLog("Nyangkut, mencari rute baru...")
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

-- 8. CORE LOOP (Dumpster Jump & Auto Equip)
local isSellingPhase = false
local sellFailCounter = 0

task.spawn(function()
    while task.wait(0.2) do
        if ui.Destroyed then break end 
        
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

        -- FASE 1: JUAL BARANG
        if isSellingPhase then
            local shopTargetPos = getShopTargetPosition()
            local npc = getTrashMasterNPC() 
            
            if shopTargetPos and npc then
                local dist = (rootPart.Position - shopTargetPos).Magnitude
                
                if dist > 4 then
                    ui:SetStatus("Otw Shop", Color3.fromRGB(255, 180, 80))
                    ui:SetStatus("Otw Shop", Color3.fromRGB(255, 150, 50))
                    
                    smoothWalk(shopTargetPos, nil, 3) 
                else
                    humanoid:MoveTo(rootPart.Position) 
                    ui:SetStatus("Membuka Shop", Color3.fromRGB(50, 255, 50))
                    ui:SetStatus("Membuka Shop", Color3.fromRGB(50, 255, 50))
                    
                    local prompt = npc:FindFirstChildOfClass("ProximityPrompt")
                    if prompt and fireproximityprompt then
                        fireproximityprompt(prompt)
                    end
                    
                    task.wait(1.5) 
                    
                    ui:SetStatus("Selling")
                    ui:AddLog("mencoba SELL ALL")
                    local isClicked = clickGuiButtonByText("SELL ALL")
                    
                    if isClicked then
                        task.wait(1) 
                        clickGuiButtonByText("X")
                        isSellingPhase = false
                        
                        -- AUTO EQUIP
                        local backpack = player:FindFirstChild("Backpack")
                        if backpack then
                            local tool = backpack:FindFirstChildOfClass("Tool")
                            if tool then
                                humanoid:EquipTool(tool)
                            end
                        end
                        task.wait(1)
                    else
                        sellFailCounter = sellFailCounter + 1
                        ui:SetStatus("Sell gagal", Color3.fromRGB(255, 120, 100))
                        ui:AddLog("gagal menekan SELL ALL")
                        task.wait(1)
                        if sellFailCounter > 3 then
                            isSellingPhase = false
                            clickGuiButtonByText("X")
                        end
                    end
                end
            else
                ui:SetStatus("Shop Missing", Color3.fromRGB(255, 80, 70))
                ui:AddLog("Deco1 / Trash Master tidak ditemukan")
                ui:SetStatus("Priority", Color3.fromRGB(255, 80, 70))
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
                        ui:SetStatus("Priority", Color3.fromRGB(255, 80, 70))
                    else
                        ui:SetStatus("Priority", Color3.fromRGB(255, 220, 100))
                    end
                    
                    ui:SetStatus("Otw " .. currentRarity, Color3.fromRGB(255, 180, 80))
                    ui:AddLog("menuju " .. currentRarity .. " - " .. targetPart.Name)
                    
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
                        ui:SetStatus("Priority", Color3.fromRGB(255, 80, 70))
                    else
                        ui:SetStatus("Priority", Color3.fromRGB(255, 220, 100))
                    end
                    
                    ui:SetStatus("Loot " .. currentRarity, Color3.fromRGB(255, 220, 120))
                    
                    -- SENSOR BAK SAMPAH TINGGI (Maksa Loncat)
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
                ui:SetStatus("Menunggu target", Color3.fromRGB(200, 200, 200))
                ui:SetStatus("Menunggu target", Color3.fromRGB(200, 200, 200))
                humanoid:MoveTo(rootPart.Position)
            end
        elseif not states.autoFarm and not states.autoClick then
            ui:SetStatus("READY")
            ui:SetStatus("Menunggu target", Color3.fromRGB(200, 200, 200))
        end
    end
end)
