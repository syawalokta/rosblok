local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- PENGATURAN LOADER & WEBHOOK
local LogoAssetID = "rbxassetid://85074945377894" 
local WebhookURL = "https://discord.com/api/webhooks/1411957681891311718/FWmL3lPgEI3fMfZzeG45sim4l7dK6dGDyCVkmkSi7cZfgRwdTxsLHbh2hjc3YGAGc8gu" 

-- Daftar game yang disupport
local SupportedGames = {
    [123456789] = {
        Name = "Ice Fishing",
        Script = "https://raw.githubusercontent.com/username/repo/main/bloxfruits.lua"
    },
    [123379620921451] = {
        Name = "Backstreet Survival: Enhanced",
        Script = "https://raw.githubusercontent.com/syawalokta/rosblok/refs/heads/master/esceh/backstreet"
    }
}

local CurrentGame = SupportedGames[PlaceId]

-- Status Valid/Invalid
local ValidScript = CurrentGame and "Valid" or "Invalid"

-- SISTEM WEBHOOK DISCORD
local function SendWebhook()
    -- Mengambil nama game asli jika tidak ada di daftar
    local GameName = "Unknown Game"
    if CurrentGame then
        GameName = CurrentGame.Name
    else
        pcall(function()
            GameName = MarketplaceService:GetProductInfo(PlaceId).Name
        end)
    end

    -- FIX AVATAR: Menggunakan Roblox API untuk mendapat link gambar CDN langsung
    local AvatarUrl = ""
    pcall(function()
        local response = game:HttpGet("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. tostring(LocalPlayer.UserId) .. "&size=420x420&format=Png&isCircular=false")
        local data = HttpService:JSONDecode(response)
        if data and data.data and data.data[1] then
            AvatarUrl = data.data[1].imageUrl
        end
    end)

    -- Format Waktu Real-time (Bulan/Hari/Tahun Jam:Menit AM/PM)
    local CurrentTime = os.date("%m/%d/%Y %I:%M %p")

    -- Format pesan Discord yang baru
    local WebhookData = {
        ["content"] = "",
        ["embeds"] = {
            {
                ["title"] = "SCRIPT EXECUTED",
                ["description"] = "User:\n`" .. LocalPlayer.DisplayName .. "`\n\n" ..
                                  "Username:\n`" .. LocalPlayer.Name .. "`\n\n" ..
                                  "Place id:\n`" .. tostring(PlaceId) .. "`\n\n" ..
                                  "Game name:\n`" .. GameName .. "`\n\n" ..
                                  "Valid script:\n`" .. ValidScript .. "`",
                ["color"] = tonumber(0x3498DB), -- Warna biru
                ["thumbnail"] = {
                    ["url"] = AvatarUrl
                },
                ["footer"] = {
                    ["text"] = "topinzhub | " .. CurrentTime
                }
            }
        }
    }

    local JSONData = HttpService:JSONEncode(WebhookData)
    local HTTPRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    
    if HTTPRequest and WebhookURL ~= "" then
        pcall(function()
            HTTPRequest({
                Url = WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = JSONData
            })
        end)
    end
end

-- Kirim webhook saat loader dieksekusi
SendWebhook()

-- SISTEM EKSEKUSI SCRIPT / NOTIFIKASI
if CurrentGame then
    local success, err = pcall(function()
        loadstring(game:HttpGet(CurrentGame.Script))()
    end)
    
    if success then
        StarterGui:SetCore("SendNotification", {
            Title = "Script Loaded",
            Text = "Berhasil memuat script untuk:\n" .. CurrentGame.Name,
            Icon = LogoAssetID,
            Duration = 5
        })
    else
        warn("Gagal memuat script untuk " .. CurrentGame.Name .. ": " .. tostring(err))
    end
else
    StarterGui:SetCore("SendNotification", {
        Title = "Unsupported Game",
        Text = "PlaceId: " .. tostring(PlaceId) .. "\nnot supported.",
        Icon = LogoAssetID,
        Duration = 8
    })
end
