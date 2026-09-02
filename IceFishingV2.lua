local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- CONFIG

local autoCatchEnabled = false
local inMinigame = false

-- Sistem multi-click
local wasInsidePerfect = false
local lastClick = 0

-- Jangan terlalu besar karena target bergerak cepat
local clickCooldown = 0.08

-- Toleransi tambahan pixel
local hitMargin = 12

-- NOTIFICATION
local function kirimNotif(pesan)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Auto Catch",
            Text = pesan,
            Duration = 3
        })
    end)
end

-- CARI PROXIMITY PROMPT MANCING TERDEKAT
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

-- TAP SCREEN
local function tapScreen()

    local clickX = 800
    local clickY = 300

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

-- GUI BUTTON
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

-- PROXIMITY PROMPT
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

-- GUI SETUP
local guiParent = (gethui and gethui()) or game:GetService("CoreGui")

pcall(function()
    local oldGui = guiParent:FindFirstChild("AutoCatchUI")

    if oldGui then
        oldGui:Destroy()
    end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoCatchUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 140, 0, 95)
mainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -35, 0, 30)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "Auto Catch"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.BackgroundTransparency = 1
title.Parent = mainFrame

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -28, 0, 3)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
minBtn.TextSize = 16
minBtn.Font = Enum.Font.GothamBold
minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
minBtn.BorderSizePixel = 0
minBtn.Parent = mainFrame

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minBtn

local bodyFrame = Instance.new("Frame")
bodyFrame.Size = UDim2.new(1, -16, 0, 50)
bodyFrame.Position = UDim2.new(0, 8, 0, 35)
bodyFrame.BackgroundTransparency = 1
bodyFrame.Parent = mainFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, 0, 0, 40)
toggleBtn.Position = UDim2.new(0, 0, 0, 5)
toggleBtn.Text = "AUTO: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 13
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = bodyFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleBtn

-- MINIMIZE
local isMinimized = false

minBtn.MouseButton1Click:Connect(function()

    isMinimized = not isMinimized

    if isMinimized then
        bodyFrame.Visible = false
        mainFrame.Size = UDim2.new(0, 140, 0, 30)
        minBtn.Text = "+"
    else
        bodyFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 140, 0, 95)
        minBtn.Text = "-"
    end

end)

-- TOGGLE
toggleBtn.MouseButton1Click:Connect(function()

    if not autoCatchEnabled then

        local prompt = getNearestFishingPrompt()

        if not prompt then
            kirimNotif("Kamu tidak berada di spot mancing!")
            return
        end

        autoCatchEnabled = true

        toggleBtn.Text = "AUTO: ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 180, 80)

        wasInsidePerfect = false
        lastClick = 0

        task.spawn(function()

            local fishGui =
                playerGui:FindFirstChild("FishGameTemplate")

            if not fishGui or not fishGui.Enabled then
                interactPrompt(prompt)
            end

        end)

    else

        autoCatchEnabled = false
        inMinigame = false

        wasInsidePerfect = false
        lastClick = 0

        toggleBtn.Text = "AUTO: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)

    end

end)

-- MAIN AUTO CATCH LOOP
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

    -- MINIGAME AKTIF
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

            -- DETEKSI OVERLAP
            local isOverlap =
                lineBottom >= (pTop - hitMargin)
                and
                lineTop <= (pBottom + hitMargin)

            local now = tick()

            -- BARU MASUK PERFECT
            if isOverlap then

                if not wasInsidePerfect
                    and (now - lastClick >= clickCooldown)
                then

                    lastClick = now

                    tapScreen()

                end

                wasInsidePerfect = true

            else

                -- Keluar dari Perfect.
                -- Artinya siap melakukan klik berikutnya.
                wasInsidePerfect = false

            end

        end

    -- MINIGAME SELESAI
    else

        if inMinigame then

            inMinigame = false
            wasInsidePerfect = false
            lastClick = 0

            task.spawn(function()

                -- Tunggu state game berubah
                task.wait(0.12)

                -- SKIP ANIMASI IKAN
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

                -- TUNGGU KARAKTER READY
                task.wait(0.35)

                -- MANCING LAGI
                if autoCatchEnabled then

                    local prompt =
                        getNearestFishingPrompt()

                    if prompt then

                        interactPrompt(prompt)

                    else

                        autoCatchEnabled = false

                        toggleBtn.Text = "AUTO: OFF"
                        toggleBtn.BackgroundColor3 =
                            Color3.fromRGB(200, 60, 60)

                        kirimNotif(
                            "Kamu tidak berada di spot mancing!"
                        )

                    end

                end

            end)

        end

    end

end)

-- CLEANUP SAAT CHARACTER RESPAWN
player.CharacterAdded:Connect(function()

    inMinigame = false
    wasInsidePerfect = false
    lastClick = 0

end)