-- WindUI
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"
))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Config
local autoCatchEnabled = false
local autoRestart = true

local inMinigame = false
local wasInsidePerfect = false
local lastClick = 0

local clickCooldown = 0.08
local hitMargin = 12

local clickX = 800
local clickY = 300

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

            local objectText =
                string.lower(desc.ObjectText or "")

            local actionText =
                string.lower(desc.ActionText or "")

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

        task.wait(0.01)

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

-- Reset minigame
local function resetMinigameState()
    inMinigame = false
    wasInsidePerfect = false
    lastClick = 0
end

-- Window
local Window = WindUI:CreateWindow({
    Title = "Topinz Hub",
    Icon = "door-open",
    Author = "by oktodev"
})

-- Settings
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

-- Auto Catch
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

            resetMinigameState()

            updateStatus("OFF")

            kirimNotif(
                "Auto Catch dimatikan."
            )

            return
        end

        local prompt =
            getNearestFishingPrompt()

        if not prompt then

            autoCatchEnabled = false

            updateStatus(
                "Tidak berada di spot mancing"
            )

            kirimNotif(
                "Kamu tidak berada di spot mancing!"
            )

            return
        end

        autoCatchEnabled = true

        resetMinigameState()

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

    local fishGui =
        playerGui:FindFirstChild(
            "FishGameTemplate"
        )

    local main =
        fishGui
        and fishGui:FindFirstChild(
            "Main"
        )

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

                if not autoRestart then

                    updateStatus(
                        "Selesai"
                    )

                    return
                end

                task.wait(0.35)

                if not autoCatchEnabled then
                    return
                end

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

                    autoCatchEnabled = false

                    updateStatus(
                        "Spot mancing tidak ditemukan"
                    )

                    kirimNotif(
                        "Kamu tidak berada di spot mancing!"
                    )
                end

            end)
        end
    end
end)

-- Character respawn
player.CharacterAdded:Connect(function()

    resetMinigameState()

    if autoCatchEnabled then
        updateStatus(
            "Menunggu karakter..."
        )
    else
        updateStatus("OFF")
    end

end)

-- Loaded
kirimNotif(
    "Topinz Hub loaded."
)