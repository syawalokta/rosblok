-- WindUI
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"
))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")

local camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Config
local autoCatchEnabled = false
local inMinigame = false

local wasInsidePerfect = false
local lastClick = 0

local clickCooldown = 0.08
local hitMargin = 12

local clickX = 800
local clickY = 300

local autoRestart = true

local StatusText

-- Notification
local function kirimNotif(pesan)
    pcall(function()
        WindUI:Notify({
            Title = "Auto Catch",
            Content = pesan,
            Duration = 3
        })
    end)
end

-- Status
local function updateStatus(status)
    if StatusText then
        pcall(function()
            StatusText:Set({
                Content = status
            })
        end)
    end
end

-- Cari proximity prompt mancing terdekat
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

            local isFishPrompt =
                desc.Parent.Name == "Interact"
                or objectText:find("fish")
                or actionText:find("mancing")

            if isFishPrompt then

                local part = desc.Parent

                local partPos =
                    part:IsA("BasePart") and part.Position
                    or (part:IsA("Attachment") and part.WorldPosition)

                if partPos then
                    local dist = (hrp.Position - partPos).Magnitude

                    if dist < shortestDist then
                        shortestDist = dist
                        closestPrompt = desc
                    end
                end
            end
        end
    end

    return closestPrompt
end

-- Tap screen
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
        return
    end

    if firesignal then
        pcall(function()
            firesignal(btn.MouseButton1Click)
        end)

        pcall(function()
            firesignal(btn.Activated)
        end)
    end

    local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)

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
end

-- Proximity prompt
local function interactPrompt(prompt)
    if not prompt then
        return
    end

    if fireproximityprompt then
        pcall(function()
            fireproximityprompt(prompt)
        end)
    else
        pcall(function()
            prompt:InputHoldBegin()

            local duration = prompt.HoldDuration

            if duration and duration > 0 then
                task.wait(duration)
            else
                task.wait(0.05)
            end

            prompt:InputHoldEnd()
        end)
    end
end

-- Window
local Window = WindUI:CreateWindow({
    Title = "Topinz Hub",
    Icon = "door-open",
    Author = "by oktodev"
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

            kirimNotif("Auto Catch dimatikan.")

            return
        end

        local prompt = getNearestFishingPrompt()

        if not prompt then
            updateStatus("Tidak berada di spot mancing")

            kirimNotif(
                "Kamu tidak berada di spot mancing!"
            )

            return
        end

        autoCatchEnabled = true

        wasInsidePerfect = false
        lastClick = 0

        updateStatus("ON")

        kirimNotif("Auto Catch diaktifkan.")

        task.spawn(function()

            local fishGui =
                playerGui:FindFirstChild("FishGameTemplate")

            if not fishGui or not fishGui.Enabled then
                interactPrompt(prompt)
            end

        end)
    end
})

MainTab:Toggle({
    Title = "Auto Restart",
    Desc = "Mancing kembali setelah minigame selesai",
    Value = true,

    Callback = function(state)
        autoRestart = state
    end
})

MainTab:Slider({
    Title = "Click Cooldown",
    Desc = "Jeda antar klik",

    Step = 0.01,

    Value = {
        Min = 0.01,
        Max = 0.5,
        Default = clickCooldown
    },

    Callback = function(value)
        clickCooldown = tonumber(value) or clickCooldown
    end
})

MainTab:Slider({
    Title = "Hit Margin",
    Desc = "Toleransi tambahan pixel",

    Step = 1,

    Value = {
        Min = 0,
        Max = 50,
        Default = hitMargin
    },

    Callback = function(value)
        hitMargin = tonumber(value) or hitMargin
    end
})

-- Click Position
MainTab:Slider({
    Title = "Click X",
    Desc = "Posisi horizontal",

    Step = 1,

    Value = {
        Min = 0,
        Max = 2000,
        Default = clickX
    },

    Callback = function(value)
        clickX = tonumber(value) or clickX
    end
})

MainTab:Slider({
    Title = "Click Y",
    Desc = "Posisi vertical",

    Step = 1,

    Value = {
        Min = 0,
        Max = 1200,
        Default = clickY
    },

    Callback = function(value)
        clickY = tonumber(value) or clickY
    end
})

-- Test click
MainTab:Button({
    Title = "Test Click",
    Desc = "Tes posisi klik",

    Callback = function()

        tapScreen()

        kirimNotif(
            "Test Click: " ..
            tostring(clickX) ..
            ", " ..
            tostring(clickY)
        )
    end
})

-- Main auto catch loop
RunService.RenderStepped:Connect(function()

    if not autoCatchEnabled then
        return
    end

    local fishGui =
        playerGui:FindFirstChild("FishGameTemplate")

    local main =
        fishGui and fishGui:FindFirstChild("Main")

    local targetFrame =
        main and main:FindFirstChild("TargetFrame")

    local isMinigameActive =
        fishGui
        and fishGui.Enabled
        and targetFrame
        and targetFrame.Visible

    -- Minigame aktif
    if isMinigameActive then

        inMinigame = true

        local targetLine =
            targetFrame:FindFirstChild("TargetLine")

        local target =
            targetFrame:FindFirstChild("Target")

        local perfect =
            target and target:FindFirstChild("Perfect")

        if targetLine and perfect then

            local lineTop =
                targetLine.AbsolutePosition.Y

            local lineBottom =
                lineTop + targetLine.AbsoluteSize.Y

            local pTop =
                perfect.AbsolutePosition.Y

            local pBottom =
                pTop + perfect.AbsoluteSize.Y

            -- Deteksi overlap
            local isOverlap =
                lineBottom >= (pTop - hitMargin)
                and
                lineTop <= (pBottom + hitMargin)

            local now = tick()

            -- Baru masuk Perfect
            if isOverlap then

                if not wasInsidePerfect
                    and (now - lastClick >= clickCooldown)
                then

                    lastClick = now

                    tapScreen()
                end

                wasInsidePerfect = true

            else

                -- Keluar dari Perfect
                wasInsidePerfect = false
            end
        end

    -- Minigame selesai
    else

        if inMinigame then

            inMinigame = false
            wasInsidePerfect = false
            lastClick = 0

            updateStatus("Processing...")

            task.spawn(function()

                -- Tunggu state game berubah
                task.wait(0.12)

                -- Skip animasi ikan
                local stopGui =
                    playerGui:FindFirstChild("StopButton")

                local stopFrame =
                    stopGui and stopGui:FindFirstChild("Frame")

                local stopBtn =
                    stopFrame and stopFrame:FindFirstChild("Button")

                if stopBtn
                    and stopGui.Enabled
                    and stopFrame.Visible
                then

                    pressGuiButton(stopBtn)
                end

                -- Tunggu karakter ready
                task.wait(0.35)

                -- Mancing lagi
                if autoCatchEnabled
                    and autoRestart
                then

                    local prompt =
                        getNearestFishingPrompt()

                    if prompt then

                        updateStatus("Fishing...")

                        interactPrompt(prompt)

                    else

                        autoCatchEnabled = false

                        updateStatus(
                            "Tidak berada di spot mancing"
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

    if autoCatchEnabled then
        updateStatus("Character respawned")
    end
end)

-- Loaded
kirimNotif("Topinz Hub loaded.")