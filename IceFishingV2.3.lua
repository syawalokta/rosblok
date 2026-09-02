-- WindUI
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"
))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Config
local autoCatchEnabled = false
local autoSellEnabled = false
local autoRestart = true

local inMinigame = false
local wasInsidePerfect = false
local lastClick = 0

local clickCooldown = 0.08
local hitMargin = 12

local clickX = 800
local clickY = 300

local sellProcessing = false
local returnPosition = nil

local sellDistance = 7
local coolerDistance = 7

local StatusText

-- Notification
local function kirimNotif(pesan)
    pcall(function()
        WindUI:Notify({
            Title = "Topinz Hub",
            Content = pesan,
            Duration = 3
        })
    end)
end

-- Status
local function updateStatus(text)
    if StatusText then
        pcall(function()
            StatusText:Set({
                Content = text
            })
        end)
    end
end

-- Find nearest fishing prompt
local function getNearestFishingPrompt()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        return nil
    end

    local closestPrompt = nil
    local shortestDist = 12

    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then

            local objectText = string.lower(desc.ObjectText or "")
            local actionText = string.lower(desc.ActionText or "")

            local parent = desc.Parent

            if parent then

                local isFishPrompt =
                    parent.Name == "Interact"
                    or objectText:find("fish")
                    or actionText:find("mancing")

                if isFishPrompt then

                    local partPos

                    if parent:IsA("BasePart") then
                        partPos = parent.Position
                    elseif parent:IsA("Attachment") then
                        partPos = parent.WorldPosition
                    end

                    if partPos then

                        local dist =
                            (hrp.Position - partPos).Magnitude

                        if dist < shortestDist then
                            shortestDist = dist
                            closestPrompt = desc
                        end
                    end
                end
            end
        end
    end

    return closestPrompt
end

-- Fixed screen click
local function tapScreen()
    pcall(function()

        VirtualInputManager:SendMouseButtonEvent(
            clickX,
            clickY,
            0,
            true,
            game,
            1
        )

        task.wait(0.01)

        VirtualInputManager:SendMouseButtonEvent(
            clickX,
            clickY,
            0,
            false,
            game,
            1
        )

    end)
end

-- GUI button
local function pressGuiButton(btn)
    if not btn then
        return false
    end

    if firesignal then

        pcall(function()
            firesignal(btn.MouseButton1Click)
        end)

        pcall(function()
            firesignal(btn.Activated)
        end)

        return true
    end

    local pos =
        btn.AbsolutePosition
        + (btn.AbsoluteSize / 2)

    pcall(function()

        VirtualInputManager:SendMouseButtonEvent(
            pos.X,
            pos.Y,
            0,
            true,
            game,
            1
        )

        task.wait()

        VirtualInputManager:SendMouseButtonEvent(
            pos.X,
            pos.Y,
            0,
            false,
            game,
            1
        )

    end)

    return true
end

-- Proximity prompt
local function interactPrompt(prompt)
    if not prompt then
        return false
    end

    if fireproximityprompt then

        local success = pcall(function()
            fireproximityprompt(prompt)
        end)

        return success
    end

    local success = pcall(function()

        prompt:InputHoldBegin()

        local duration = prompt.HoldDuration

        if duration and duration > 0 then
            task.wait(duration)
        else
            task.wait(0.05)
        end

        prompt:InputHoldEnd()

    end)

    return success
end

-- Get prompt position
local function getPromptPosition(prompt)
    if not prompt then
        return nil
    end

    local parent = prompt.Parent

    if not parent then
        return nil
    end

    if parent:IsA("Attachment") then
        return parent.WorldPosition
    end

    if parent:IsA("BasePart") then
        return parent.Position
    end

    local model = parent:FindFirstAncestorOfClass("Model")

    if model then
        local part =
            model.PrimaryPart
            or model:FindFirstChildWhichIsA("BasePart", true)

        if part then
            return part.Position
        end
    end

    return nil
end

-- Find nearest Reti Cooler
local function getNearestRetiCooler()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        return nil, nil, nil
    end

    local nearestCooler = nil
    local nearestPickup = nil
    local nearestPosition = nil

    local shortestDist = math.huge
    local checked = {}

    for _, obj in ipairs(workspace:GetDescendants()) do

        if obj.Name == "Reti Cooler"
            and obj:IsA("Model")
            and not checked[obj]
        then

            checked[obj] = true

            local main =
                obj:FindFirstChild("Main", true)

            local pickup

            if main then
                pickup =
                    main:FindFirstChild("PickUp", true)
            end

            if not pickup then
                pickup =
                    obj:FindFirstChild("PickUp", true)
            end

            if pickup
                and pickup:IsA("ProximityPrompt")
            then

                local position =
                    getPromptPosition(pickup)

                if position then

                    local distance =
                        (hrp.Position - position).Magnitude

                    if distance < shortestDist then

                        shortestDist = distance
                        nearestCooler = obj
                        nearestPickup = pickup
                        nearestPosition = position

                    end
                end
            end
        end
    end

    return nearestCooler, nearestPickup, nearestPosition
end

-- Pathfinding
local function walkTo(targetPosition, maxDistance)
    if not targetPosition then
        return false
    end

    local char = player.Character
    local humanoid =
        char and char:FindFirstChildOfClass("Humanoid")

    local hrp =
        char and char:FindFirstChild("HumanoidRootPart")

    if not humanoid or not hrp then
        return false
    end

    if (hrp.Position - targetPosition).Magnitude <= (maxDistance or 5) then
        return true
    end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4
    })

    local success = pcall(function()
        path:ComputeAsync(
            hrp.Position,
            targetPosition
        )
    end)

    if not success then
        return false
    end

    if path.Status ~= Enum.PathStatus.Success then
        return false
    end

    local waypoints = path:GetWaypoints()

    for _, waypoint in ipairs(waypoints) do

        if not autoSellEnabled
            or not autoCatchEnabled
        then
            return false
        end

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end

        humanoid:MoveTo(waypoint.Position)

        local reached = humanoid.MoveToFinished:Wait()

        if not reached then
            return false
        end

        if (hrp.Position - targetPosition).Magnitude
            <= (maxDistance or 5)
        then
            return true
        end
    end

    return (
        hrp.Position - targetPosition
    ).Magnitude <= (maxDistance or 5)
end

-- Detect Pendingin Penuh
local function isCoolerFull()
    for _, obj in ipairs(playerGui:GetDescendants()) do

        if obj:IsA("TextLabel")
            or obj:IsA("TextButton")
            or obj:IsA("TextBox")
        then

            local text = string.lower(obj.Text or "")

            if text:find(
                "pendingin penuh",
                1,
                true
            ) then
                return true
            end
        end
    end

    return false
end

-- Find Sell Everything
local function getSellEverythingButton()
    local dialogue =
        playerGui:FindFirstChild(
            "DialogueBillboard"
        )

    if not dialogue then
        return nil
    end

    local main =
        dialogue:FindFirstChild(
            "Main",
            true
        )

    if not main then
        return nil
    end

    local mainCol =
        main:FindFirstChild(
            "MainCol",
            true
        )

    if not mainCol then
        return nil
    end

    local options =
        mainCol:FindFirstChild(
            "Options",
            true
        )

    if not options then
        return nil
    end

    local button =
        options:FindFirstChild(
            "Sell Everything"
        )

    if button then
        return button
    end

    for _, obj in ipairs(options:GetDescendants()) do

        if obj:IsA("TextButton")
            or obj:IsA("ImageButton")
        then

            if obj.Name == "Sell Everything"
                or obj.Text == "Sell Everything"
            then
                return obj
            end
        end
    end

    return nil
end

-- Get SellPart
local function getSellPart()
    local fishMarket =
        workspace:FindFirstChild("FishMarket")

    if not fishMarket then
        return nil
    end

    return fishMarket:FindFirstChild(
        "SellPart",
        true
    )
end

-- Sell everything
local function sellEverything()
    local timeout = os.clock() + 5

    while os.clock() < timeout do

        local button =
            getSellEverythingButton()

        if button then

            local success =
                pressGuiButton(button)

            if success then
                return true
            end
        end

        task.wait(0.1)
    end

    return false
end

-- Check if cooler is being carried
local function isCoolerCarried()
    local char = player.Character

    if not char then
        return false
    end

    for _, obj in ipairs(char:GetDescendants()) do

        if obj.Name == "Reti Cooler" then
            return true
        end
    end

    return false
end

-- Reset minigame
local function resetMinigameState()
    inMinigame = false
    wasInsidePerfect = false
    lastClick = 0
end

-- Start fishing
local function startFishing()
    if not autoCatchEnabled then
        return
    end

    local prompt =
        getNearestFishingPrompt()

    if prompt then

        updateStatus("Fishing...")

        interactPrompt(prompt)

    else

        updateStatus(
            "Spot mancing tidak ditemukan"
        )

        kirimNotif(
            "Kamu tidak berada di spot mancing!"
        )
    end
end

-- Auto sell
local function performAutoSell()
    if sellProcessing then
        return
    end

    if not autoSellEnabled
        or not autoCatchEnabled
    then
        return
    end

    sellProcessing = true

    local char = player.Character
    local hrp =
        char and char:FindFirstChild("HumanoidRootPart")

    if not hrp then
        sellProcessing = false
        return
    end

    returnPosition = hrp.Position

    updateStatus("Mencari Reti Cooler...")

    local cooler, pickup, coolerPosition =
        getNearestRetiCooler()

    if not cooler
        or not pickup
        or not coolerPosition
    then

        updateStatus(
            "Reti Cooler tidak ditemukan"
        )

        kirimNotif(
            "Reti Cooler tidak ditemukan."
        )

        sellProcessing = false
        return
    end

    updateStatus("Menuju Reti Cooler...")

    local reachedCooler =
        walkTo(
            coolerPosition,
            coolerDistance
        )

    if not reachedCooler then

        updateStatus(
            "Gagal menuju Reti Cooler"
        )

        sellProcessing = false
        return
    end

    if not autoSellEnabled
        or not autoCatchEnabled
    then
        sellProcessing = false
        return
    end

    updateStatus("Mengambil Reti Cooler...")

    interactPrompt(pickup)

    task.wait(0.25)

    if not isCoolerCarried() then
        task.wait(0.5)
    end

    local sellPart = getSellPart()

    if not sellPart then

        updateStatus(
            "SellPart tidak ditemukan"
        )

        kirimNotif(
            "Workspace.FishMarket.SellPart tidak ditemukan."
        )

        sellProcessing = false
        return
    end

    updateStatus("Menuju tempat jual...")

    local sellPosition =
        sellPart.Position

    local reachedSell =
        walkTo(
            sellPosition,
            sellDistance
        )

    if not reachedSell then

        updateStatus(
            "Gagal menuju tempat jual"
        )

        sellProcessing = false
        return
    end

    updateStatus("Menjual ikan...")

    task.wait(0.2)

    local sold =
        sellEverything()

    if sold then

        updateStatus("Berhasil menjual")

        task.wait(0.5)

    else

        updateStatus(
            "Tombol Sell Everything tidak ditemukan"
        )

        kirimNotif(
            "Sell Everything tidak ditemukan."
        )

        sellProcessing = false
        return
    end

    if not autoSellEnabled
        or not autoCatchEnabled
    then
        sellProcessing = false
        return
    end

    task.wait(0.5)

    if returnPosition then

        updateStatus(
            "Kembali ke spot mancing..."
        )

        walkTo(
            returnPosition,
            7
        )
    end

    task.wait(0.35)

    sellProcessing = false

    if autoCatchEnabled then
        updateStatus("Fishing...")

        local prompt =
            getNearestFishingPrompt()

        if prompt then
            interactPrompt(prompt)
        else
            updateStatus(
                "Spot mancing tidak ditemukan"
            )
        end
    end
end

-- Window
local Window = WindUI:CreateWindow({
    Title = "Topinz Hub",
    Icon = "door-open",
    Author = "by oktodev"
})

-- settings
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

SettingsTab:Keybind({
    Title = "GUI Keybind",
    Desc = "Tombol untuk menampilkan / menyembunyikan UI",
    Value = "RightControl",

    Callback = function(value)
        local keyCode = Enum.KeyCode[value]

        if keyCode then
            Window:SetToggleKey(keyCode)
        end
    end
})

-- Main tab
local MainTab = Window:Tab({
    Title = "Auto Catch",
    Icon = "fish"
})

-- Auto Catch
MainTab:Toggle({
    Title = "Auto Catch",
    Desc = "Otomatis menangkap ikan",
    Value = false,

    Callback = function(state)

        if not state then

            autoCatchEnabled = false
            inMinigame = false
            wasInsidePerfect = false
            lastClick = 0

            updateStatus("OFF")

            kirimNotif(
                "Auto Catch dimatikan."
            )

            return
        end

        local prompt =
            getNearestFishingPrompt()

        if not prompt then

            updateStatus(
                "Tidak berada di spot mancing"
            )

            kirimNotif(
                "Kamu tidak berada di spot mancing!"
            )

            return
        end

        autoCatchEnabled = true

        wasInsidePerfect = false
        lastClick = 0

        updateStatus("ON")

        kirimNotif(
            "Auto Catch diaktifkan."
        )

        task.spawn(function()

            local fishGui =
                playerGui:FindFirstChild(
                    "FishGameTemplate"
                )

            if not fishGui
                or not fishGui.Enabled
            then
                interactPrompt(prompt)
            end

        end)
    end
})

-- Auto Sell
MainTab:Toggle({
    Title = "Auto Sell",
    Desc = "Ambil Reti Cooler saat penuh lalu jual ikan",
    Value = false,

    Callback = function(state)

        autoSellEnabled = state

        if state then

            kirimNotif(
                "Auto Sell diaktifkan."
            )

            if isCoolerFull()
                and autoCatchEnabled
            then

                task.spawn(
                    performAutoSell
                )
            end

        else

            kirimNotif(
                "Auto Sell dimatikan."
            )
        end
    end
})

-- Status
StatusText = MainTab:Paragraph({
    Title = "Status",
    Content = "OFF"
})

-- Auto Restart
MainTab:Toggle({
    Title = "Auto Restart",
    Desc = "Mancing kembali setelah proses selesai",
    Value = true,

    Callback = function(state)
        autoRestart = state
    end
})

-- Click Cooldown
MainTab:Slider({
    Title = "Click Cooldown",
    Desc = "Jeda antar klik",

    Value = {
        Min = 0.01,
        Max = 0.5,
        Default = clickCooldown
    },

    Step = 0.01,

    Callback = function(value)
        clickCooldown =
            tonumber(value)
            or clickCooldown
    end
})

-- Hit Margin
MainTab:Slider({
    Title = "Hit Margin",
    Desc = "Toleransi area Perfect",

    Value = {
        Min = 0,
        Max = 50,
        Default = hitMargin
    },

    Step = 1,

    Callback = function(value)
        hitMargin =
            tonumber(value)
            or hitMargin
    end
})

-- Click X
MainTab:Slider({
    Title = "Click X",
    Desc = "Posisi horizontal klik",

    Value = {
        Min = 0,
        Max = 2000,
        Default = clickX
    },

    Step = 1,

    Callback = function(value)
        clickX =
            tonumber(value)
            or clickX
    end
})

-- Click Y
MainTab:Slider({
    Title = "Click Y",
    Desc = "Posisi vertical klik",

    Value = {
        Min = 0,
        Max = 1200,
        Default = clickY
    },

    Step = 1,

    Callback = function(value)
        clickY =
            tonumber(value)
            or clickY
    end
})

-- Test click
MainTab:Button({
    Title = "Test Click",
    Desc = "Tes posisi klik",

    Callback = function()

        tapScreen()

        kirimNotif(
            "Click: "
            .. tostring(clickX)
            .. ", "
            .. tostring(clickY)
        )
    end
})

-- Main Auto Catch Loop
RunService.RenderStepped:Connect(function()

    if not autoCatchEnabled then
        return
    end

    -- Auto Sell trigger
    if autoSellEnabled
        and not sellProcessing
        and isCoolerFull()
    then

        task.spawn(
            performAutoSell
        )

        return
    end

    if sellProcessing then
        return
    end

    local fishGui =
        playerGui:FindFirstChild(
            "FishGameTemplate"
        )

    local main =
        fishGui
        and fishGui:FindFirstChild("Main")

    local targetFrame =
        main
        and main:FindFirstChild(
            "TargetFrame"
        )

    local isMinigameActive =
        fishGui
        and fishGui.Enabled
        and targetFrame
        and targetFrame.Visible

    -- Minigame aktif
    if isMinigameActive then

        inMinigame = true

        local targetLine =
            targetFrame:FindFirstChild(
                "TargetLine"
            )

        local target =
            targetFrame:FindFirstChild(
                "Target"
            )

        local perfect =
            target
            and target:FindFirstChild(
                "Perfect"
            )

        if targetLine and perfect then

            local lineTop =
                targetLine.AbsolutePosition.Y

            local lineBottom =
                lineTop
                + targetLine.AbsoluteSize.Y

            local pTop =
                perfect.AbsolutePosition.Y

            local pBottom =
                pTop
                + perfect.AbsoluteSize.Y

            local isOverlap =
                lineBottom >=
                    (pTop - hitMargin)
                and
                lineTop <=
                    (pBottom + hitMargin)

            local now = tick()

            -- Baru masuk Perfect
            if isOverlap then

                if not wasInsidePerfect
                    and (
                        now - lastClick
                    ) >= clickCooldown
                then

                    lastClick = now

                    tapScreen()
                end

                wasInsidePerfect = true

            else

                wasInsidePerfect = false
            end
        end

    -- Minigame selesai
    else

        if inMinigame then

            inMinigame = false
            wasInsidePerfect = false
            lastClick = 0

            task.spawn(function()

                task.wait(0.12)

                -- Stop button
                local stopGui =
                    playerGui:FindFirstChild(
                        "StopButton"
                    )

                local stopFrame =
                    stopGui
                    and stopGui:FindFirstChild(
                        "Frame"
                    )

                local stopBtn =
                    stopFrame
                    and stopFrame:FindFirstChild(
                        "Button"
                    )

                if stopBtn
                    and stopGui.Enabled
                    and stopFrame.Visible
                then

                    pressGuiButton(
                        stopBtn
                    )
                end

                task.wait(0.35)

                -- Kalau Auto Sell aktif dan
                -- pendingin sudah penuh,
                -- biarkan Auto Sell menangani.
                if autoSellEnabled
                    and isCoolerFull()
                then

                    updateStatus(
                        "Pendingin penuh"
                    )

                    return
                end

                -- Mancing lagi
                if autoCatchEnabled
                    and autoRestart
                then

                    local prompt =
                        getNearestFishingPrompt()

                    if prompt then

                        updateStatus(
                            "Fishing..."
                        )

                        interactPrompt(
                            prompt
                        )

                    else

                        autoCatchEnabled =
                            false

                        updateStatus(
                            "Spot mancing tidak ditemukan"
                        )

                        kirimNotif(
                            "Kamu tidak berada di spot mancing!"
                        )
                    end
                end

            end)
        end
    end
end)

-- Character respawn
player.CharacterAdded:Connect(function()

    inMinigame = false
    wasInsidePerfect = false
    lastClick = 0
    sellProcessing = false

end)

-- Loaded
kirimNotif(
    "Topinz Hub loaded."
)