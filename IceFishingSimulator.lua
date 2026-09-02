local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Status & Config
local autoCatchEnabled = false
local inMinigame = false
local hasClicked = false
local lastClick = 0
local clickCooldown = 0.4
local hitMargin = 8 -- Toleransi pixel biar gak lolos pas garis gerak cepet

-- Notifikasi System
local function kirimNotif(pesan)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Auto Catch",
            Text = pesan,
            Duration = 3
        })
    end)
end

-- Deteksi ProximityPrompt Spot Mancing Terdekat
local function getNearestFishingPrompt()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local closestPrompt = nil
    local shortestDist = 12 -- Jarak maksimal (studs)

    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local isFishPrompt = desc.Parent.Name == "Interact" 
                or desc.ObjectText:lower():find("fish") 
                or desc.ActionText:lower():find("mancing")

            if isFishPrompt then
                local part = desc.Parent
                local partPos = part:IsA("BasePart") and part.Position 
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

-- Input Tap Layar
local function tapScreen()
    local center = camera.ViewportSize / 2
    if mouse1click then
        mouse1click()
    else
        VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
    end
end

-- Pencet Tombol GUI (Tombol Berhenti)
local function pressGuiButton(btn)
    if not btn then return end
    if firesignal then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() firesignal(btn.Activated) end)
    end
    local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
end

-- Trigger Interaksi ProximityPrompt
local function interactPrompt(prompt)
    if not prompt then return end
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration > 0 and prompt.HoldDuration or 0.05)
        prompt:InputHoldEnd()
    end
end

-- GUI Setup
local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
pcall(function()
    if guiParent:FindFirstChild("AutoCatchUI") then
        guiParent.AutoCatchUI:Destroy()
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

-- Minimize Handler
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

-- Toggle Handler + Cek Jarak Spot
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
        
        -- Kalau belum mulai mancing, langsung trigger prompt-nya
        task.spawn(function()
            local fishGui = playerGui:FindFirstChild("FishGameTemplate")
            if not fishGui or not fishGui.Enabled then
                interactPrompt(prompt)
            end
        end)
    else
        autoCatchEnabled = false
        toggleBtn.Text = "AUTO: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        inMinigame = false
        hasClicked = false
    end
end)

-- Main Loop (Hit Timing + Auto Skip Animasi + Auto Mancing Ulang)
RunService.RenderStepped:Connect(function()
    if not autoCatchEnabled then return end

    local fishGui = playerGui:FindFirstChild("FishGameTemplate")
    local main = fishGui and fishGui:FindFirstChild("Main")
    local targetFrame = main and main:FindFirstChild("TargetFrame")
    local isMinigameActive = fishGui and fishGui.Enabled and targetFrame and targetFrame.Visible

    if isMinigameActive then
        inMinigame = true

        local targetLine = targetFrame:FindFirstChild("TargetLine")
        local target = targetFrame:FindFirstChild("Target")
        local perfect = target and target:FindFirstChild("Perfect")

        if targetLine and perfect then
            local lineTop = targetLine.AbsolutePosition.Y
            local lineBottom = lineTop + targetLine.AbsoluteSize.Y
            local pTop = perfect.AbsolutePosition.Y
            local pBottom = pTop + perfect.AbsoluteSize.Y

            -- Sistem cek tabrakan area (AABB) + margin toleransi biar gak kelewat frame
            local isOverlap = (lineBottom >= (pTop - hitMargin)) and (lineTop <= (pBottom + hitMargin))

            if isOverlap then
                local now = tick()
                if not hasClicked and (now - lastClick > clickCooldown) then
                    hasClicked = true
                    lastClick = now
                    tapScreen()
                end
            end
        end
    else
        -- Minigame selesai / ikan dapet
        if inMinigame then
            inMinigame = false
            hasClicked = false

            task.spawn(function()
                task.wait(0.12) -- Jeda kecil biar state catch kedaftar game

                -- 1. Pencet tombol Berhenti buat skip animasi pamer ikan
                local stopGui = playerGui:FindFirstChild("StopButton")
                local stopFrame = stopGui and stopGui:FindFirstChild("Frame")
                local stopBtn = stopFrame and stopFrame:FindFirstChild("Button")

                if stopBtn and stopGui.Enabled and stopFrame.Visible then
                    pressGuiButton(stopBtn)
                end

                task.wait(0.35) -- Tunggu karakter idle kembali

                -- 2. Pencet ProximityPrompt otomatis buat lempar pancing lagi
                if autoCatchEnabled then
                    local prompt = getNearestFishingPrompt()
                    if prompt then
                        interactPrompt(prompt)
                    else
                        autoCatchEnabled = false
                        toggleBtn.Text = "AUTO: OFF"
                        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
                        kirimNotif("Kamu tidak berada di spot mancing!")
                    end
                end
            end)
        end
    end
end)
