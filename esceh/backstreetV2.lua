-- services

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualUser = game:GetService("VirtualUser")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- cleanup

local oldGui = playerGui:FindFirstChild("TpzHub_UI")

if oldGui then
    oldGui:Destroy()
end

-- game info

local GAME_NAME = "Roblox"

pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    if info and info.Name then
        GAME_NAME = info.Name
    end
end)

-- colors

local COLORS = {
    Background = Color3.fromRGB(17, 19, 22),
    Panel = Color3.fromRGB(24, 27, 31),
    Secondary = Color3.fromRGB(31, 34, 39),
    Hover = Color3.fromRGB(38, 42, 48),

    Border = Color3.fromRGB(49, 53, 59),

    Text = Color3.fromRGB(238, 240, 243),
    TextSoft = Color3.fromRGB(190, 194, 201),
    Muted = Color3.fromRGB(137, 142, 151),

    Accent = Color3.fromRGB(92, 124, 156),
    AccentSoft = Color3.fromRGB(76, 103, 130),

    SliderBackground = Color3.fromRGB(54, 58, 64),

    Success = Color3.fromRGB(102, 145, 110),
    Warning = Color3.fromRGB(170, 132, 76),
    Danger = Color3.fromRGB(155, 83, 83),
}

-- state

local states = {
    autoClick = false,
    antiAfk = true,
    autoFarm = false,
    autoSell = false
}

local connections = {}
local minimized = false
local currentTab = "Main"

-- utility

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
    return TweenService:Create(
        object,
        TweenInfo.new(
            duration,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        ),
        properties
    )
end

-- main gui

local ScreenGui = create("ScreenGui", {
    Name = "TpzHub_UI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

-- main window

local Window = create("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0, 570, 0, 430),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, ScreenGui)

addCorner(Window, 14)
addStroke(Window, COLORS.Border, 0.18)

-- responsive

local function updateWindowSize()
    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport = camera.ViewportSize

    if viewport.X <= 700 then
        Window.Size = UDim2.new(
            0.93,
            0,
            0,
            math.clamp(viewport.Y * 0.76, 350, 520)
        )
    else
        Window.Size = UDim2.new(0, 570, 0, 430)
    end
end

updateWindowSize()

connect(
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),
    updateWindowSize
)

-- header

local HeaderFrame = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 68),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
}, Window)

create("Frame", {
    Position = UDim2.new(0, 16, 1, -1),
    Size = UDim2.new(1, -32, 0, 1),
    BackgroundColor3 = COLORS.Border,
    BorderSizePixel = 0,
}, HeaderFrame)

-- logo

create("ImageLabel", {
    Name = "Logo",
    Position = UDim2.new(0, 18, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    Size = UDim2.new(0, 38, 0, 38),
    BackgroundTransparency = 1,
    Image = "rbxassetid://85074945377894",
    ScaleType = Enum.ScaleType.Fit,
}, HeaderFrame)

-- title

create("TextLabel", {
    Name = "Title",
    Position = UDim2.new(0, 67, 0, 12),
    Size = UDim2.new(0, 250, 0, 27),
    BackgroundTransparency = 1,
    Text = "Tpz Hub",
    Font = Enum.Font.GothamBold,
    TextSize = 19,
    TextColor3 = COLORS.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, HeaderFrame)

create("TextLabel", {
    Name = "GameName",
    Position = UDim2.new(0, 68, 0, 38),
    Size = UDim2.new(0, 250, 0, 17),
    BackgroundTransparency = 1,
    Text = GAME_NAME,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = COLORS.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
}, HeaderFrame)

-- status

local InfoLabel = create("TextLabel", {
    Name = "Status",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -95, 0.5, 0),
    Size = UDim2.new(0, 170, 0, 20),
    BackgroundTransparency = 1,
    Text = "Status: Idle",
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextColor3 = COLORS.Muted,
    TextXAlignment = Enum.TextXAlignment.Right,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, HeaderFrame)

-- minimize

local MinimizeButton = create("TextButton", {
    Name = "Minimize",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -51, 0.5, 0),
    Size = UDim2.new(0, 32, 0, 32),
    BackgroundColor3 = COLORS.Secondary,
    BorderSizePixel = 0,
    Text = "—",
    Font = Enum.Font.GothamMedium,
    TextSize = 15,
    TextColor3 = COLORS.TextSoft,
    AutoButtonColor = false,
}, HeaderFrame)

addCorner(MinimizeButton, 9)

-- close

local CloseButton = create("TextButton", {
    Name = "Close",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -13, 0.5, 0),
    Size = UDim2.new(0, 32, 0, 32),
    BackgroundColor3 = COLORS.Secondary,
    BorderSizePixel = 0,
    Text = "×",
    Font = Enum.Font.GothamMedium,
    TextSize = 17,
    TextColor3 = COLORS.TextSoft,
    AutoButtonColor = false,
}, HeaderFrame)

addCorner(CloseButton, 9)

-- body

local Body = create("Frame", {
    Name = "Body",
    Position = UDim2.new(0, 0, 0, 68),
    Size = UDim2.new(1, 0, 1, -68),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, Window)

-- navigation

local Navigation = create("Frame", {
    Name = "Navigation",
    Position = UDim2.new(0, 12, 0, 12),
    Size = UDim2.new(0, 130, 1, -24),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
}, Body)

addCorner(Navigation, 12)
addStroke(Navigation, COLORS.Border, 0.35)

create("UIPadding", {
    PaddingTop = UDim.new(0, 10),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 10),
}, Navigation)

create("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Navigation)

-- content

local Content = create("Frame", {
    Name = "Content",
    Position = UDim2.new(0, 154, 0, 12),
    Size = UDim2.new(1, -166, 1, -24),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
}, Body)

addCorner(Content, 12)
addStroke(Content, COLORS.Border, 0.35)

local ContentTitle = create("TextLabel", {
    Position = UDim2.new(0, 19, 0, 16),
    Size = UDim2.new(1, -38, 0, 24),
    BackgroundTransparency = 1,
    Text = "Main",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = COLORS.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Content)

local ContentDescription = create("TextLabel", {
    Position = UDim2.new(0, 19, 0, 41),
    Size = UDim2.new(1, -38, 0, 18),
    BackgroundTransparency = 1,
    Text = "General controls and utilities.",
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = COLORS.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Content)

-- scroll

local Scroll = create("ScrollingFrame", {
    Name = "Scroll",
    Position = UDim2.new(0, 14, 0, 72),
    Size = UDim2.new(1, -28, 1, -86),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = COLORS.Border,
    ScrollBarImageTransparency = 0.2,
}, Content)

create("UIPadding", {
    PaddingLeft = UDim.new(0, 5),
    PaddingRight = UDim.new(0, 5),
    PaddingBottom = UDim.new(0, 12),
}, Scroll)

create("UIListLayout", {
    Padding = UDim.new(0, 9),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Scroll)

-- logs

local LogBox

local function appendLog(text)
    if not LogBox then
        return
    end

    local current = LogBox.Text

    if current == "" then
        LogBox.Text = tostring(text)
    else
        local lines = string.split(current, "\n")

        table.insert(lines, tostring(text))

        while #lines > 8 do
            table.remove(lines, 1)
        end

        LogBox.Text = table.concat(lines, "\n")
    end
end

local function setStatus(text, color, shouldNotify)
    InfoLabel.Text = tostring(text)
    InfoLabel.TextColor3 = color or COLORS.Muted

    appendLog(os.date("%H:%M:%S") .. "  " .. tostring(text))

    if shouldNotify then
        notify(
            "Tpz Hub",
            tostring(text),
            "rbxassetid://85074945377894"
        )
    end
end

-- notification system

local NotificationHolder = create("Frame", {
    Name = "Notifications",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -18, 1, -18),
    Size = UDim2.new(0, 320, 0, 300),
    BackgroundTransparency = 1,
}, ScreenGui)

create("UIListLayout", {
    Padding = UDim.new(0, 8),
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, NotificationHolder)

local notifications = {}
local notificationId = 0
local MAX_NOTIFICATIONS = 4

function notify(titleText, messageText, icon)
    notificationId += 1

    if #notifications >= MAX_NOTIFICATIONS then
        local oldest = table.remove(notifications, 1)

        if oldest and oldest.Parent then
            local hide = tween(oldest, 0.18, {
                Position = UDim2.new(1, 25, 0, 0),
                BackgroundTransparency = 1,
            })

            hide:Play()

            task.delay(0.19, function()
                if oldest then
                    oldest:Destroy()
                end
            end)
        end
    end

    local notification = create("Frame", {
        Name = "Notification_" .. notificationId,
        Size = UDim2.new(1, 0, 0, 68),
        BackgroundColor3 = Color3.fromRGB(20, 22, 25),
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 30, 0, 0),
    }, NotificationHolder)

    addCorner(notification, 14)
    addStroke(notification, COLORS.Border, 0.28)

    local accent = create("Frame", {
        Position = UDim2.new(0, 0, 0, 14),
        Size = UDim2.new(0, 3, 1, -28),
        BackgroundColor3 = COLORS.Accent,
        BorderSizePixel = 0,
    }, notification)

    addCorner(accent, 2)

    local iconBackground = create("Frame", {
        Position = UDim2.new(0, 13, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 34, 0, 34),
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0,
    }, notification)

    addCorner(iconBackground, 10)

    if icon then
        create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(0, 20, 0, 20),
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = COLORS.TextSoft,
            ScaleType = Enum.ScaleType.Fit,
        }, iconBackground)
    end

    create("TextLabel", {
        Position = UDim2.new(0, 58, 0, 12),
        Size = UDim2.new(1, -70, 0, 18),
        BackgroundTransparency = 1,
        Text = titleText,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, notification)

    create("TextLabel", {
        Position = UDim2.new(0, 58, 0, 34),
        Size = UDim2.new(1, -70, 0, 17),
        BackgroundTransparency = 1,
        Text = messageText,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = COLORS.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, notification)

    table.insert(notifications, notification)

    tween(notification, 0.3, {
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()

    task.delay(4, function()
        if not notification.Parent then
            return
        end

        local hide = tween(notification, 0.25, {
            Position = UDim2.new(1, 25, 0, 0),
            BackgroundTransparency = 1,
        })

        hide:Play()

        task.delay(0.26, function()
            for i, item in ipairs(notifications) do
                if item == notification then
                    table.remove(notifications, i)
                    break
                end
            end

            notification:Destroy()
        end)
    end)
end

-- section

local function createSection(text)
    return create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = COLORS.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Scroll)
end

-- toggle

local function createToggle(name, description, stateName)
    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0,
    }, Scroll)

    addCorner(container, 11)

    create("TextLabel", {
        Position = UDim2.new(0, 13, 0, 8),
        Size = UDim2.new(1, -75, 0, 18),
        BackgroundTransparency = 1,
        Text = name,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)

    create("TextLabel", {
        Position = UDim2.new(0, 13, 0, 28),
        Size = UDim2.new(1, -75, 0, 15),
        BackgroundTransparency = 1,
        Text = description,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = COLORS.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)

    local toggle = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -13, 0.5, 0),
        Size = UDim2.new(0, 38, 0, 21),
        BackgroundColor3 = COLORS.SliderBackground,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, container)

    addCorner(toggle, 12)

    local knob = create("Frame", {
        Position = UDim2.new(0, 3, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 15, 0, 15),
        BackgroundColor3 = COLORS.Text,
        BorderSizePixel = 0,
    }, toggle)

    addCorner(knob, 9)

    local function update()
        if states[stateName] then
            tween(toggle, 0.15, {
                BackgroundColor3 = COLORS.Accent,
            }):Play()

            tween(knob, 0.15, {
                Position = UDim2.new(1, -18, 0.5, 0),
            }):Play()
        else
            tween(toggle, 0.15, {
                BackgroundColor3 = COLORS.SliderBackground,
            }):Play()

            tween(knob, 0.15, {
                Position = UDim2.new(0, 3, 0.5, 0),
            }):Play()
        end
    end

    connect(toggle.MouseButton1Click, function()
        states[stateName] = not states[stateName]
        update()

        appendLog(
            os.date("%H:%M:%S")
            .. "  "
            .. name
            .. ": "
            .. (states[stateName] and "ON" or "OFF")
        )
    end)

    update()

    return container
end

-- slider
local function createSlider(name, description, minimum, maximum, default)
    local value = default

    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 76),
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0,
    }, Scroll)

    addCorner(container, 11)

    create("TextLabel", {
        Position = UDim2.new(0, 13, 0, 9),
        Size = UDim2.new(1, -80, 0, 18),
        BackgroundTransparency = 1,
        Text = name,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)

    local valueLabel = create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -13, 0, 9),
        Size = UDim2.new(0, 50, 0, 18),
        BackgroundTransparency = 1,
        Text = tostring(value),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = COLORS.TextSoft,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, container)

    create("TextLabel", {
        Position = UDim2.new(0, 13, 0, 28),
        Size = UDim2.new(1, -26, 0, 14),
        BackgroundTransparency = 1,
        Text = description,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = COLORS.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)

    local slider = create("Frame", {
        Position = UDim2.new(0, 13, 1, -17),
        Size = UDim2.new(1, -26, 0, 6),
        BackgroundColor3 = COLORS.SliderBackground,
        BorderSizePixel = 0,
    }, container)

    addCorner(slider, 5)

    local normalized = (value - minimum) / (maximum - minimum)

    local fill = create("Frame", {
        Size = UDim2.new(normalized, 0, 1, 0),
        BackgroundColor3 = COLORS.Accent,
        BorderSizePixel = 0,
    }, slider)

    addCorner(fill, 5)

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(normalized, 0, 0.5, 0),
        Size = UDim2.new(0, 15, 0, 15),
        BackgroundColor3 = COLORS.Text,
        BorderSizePixel = 0,
    }, slider)

    addCorner(knob, 10)

    local draggingSlider = false

    local function updateSlider(position)
        if slider.AbsoluteSize.X <= 0 then
            return
        end

        local relative = math.clamp(
            position.X - slider.AbsolutePosition.X,
            0,
            slider.AbsoluteSize.X
        )

        local percent = relative / slider.AbsoluteSize.X

        value = math.floor(
            minimum + ((maximum - minimum) * percent) + 0.5
        )

        local current = (value - minimum) / (maximum - minimum)

        fill.Size = UDim2.new(current, 0, 1, 0)
        knob.Position = UDim2.new(current, 0, 0.5, 0)
        valueLabel.Text = tostring(value)
    end

    connect(slider.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            draggingSlider = true
            updateSlider(input.Position)
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if not draggingSlider then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            updateSlider(input.Position)
        end
    end)

    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            draggingSlider = false
        end
    end)

    return container
end

-- textarea

local function createTextArea(title, placeholder)
    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 125),
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0,
    }, Scroll)

    addCorner(container, 11)

    create("TextLabel", {
        Position = UDim2.new(0, 13, 0, 10),
        Size = UDim2.new(1, -26, 0, 18),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)

    local textBox = create("TextBox", {
        Position = UDim2.new(0, 12, 0, 34),
        Size = UDim2.new(1, -24, 1, -45),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = placeholder,
        PlaceholderColor3 = COLORS.Muted,
        TextColor3 = COLORS.TextSoft,
        Font = Enum.Font.Code,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        ClearTextOnFocus = false,
        MultiLine = true,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = COLORS.Border,
    }, container)

    addCorner(textBox, 8)

    return textBox
end

-- main content

createSection("General")

createToggle(
    "Auto Click",
    "Automatically activate the equipped tool.",
    "autoClick"
)

createToggle(
    "Anti AFK",
    "Prevent the player from becoming idle.",
    "antiAfk"
)

createToggle(
    "Auto Farm",
    "Automatically search for Mythic and Legendary trash.",
    "autoFarm"
)

createToggle(
    "Auto Sell",
    "Automatically sell items when the inventory is full.",
    "autoSell"
)

createSection("Movement")

createSlider(
    "Walk Speed",
    "Movement speed control.",
    16,
    100,
    16
)

createSlider(
    "Jump Power",
    "Jump strength control.",
    50,
    150,
    50
)

createSection("Logs / Statistics")

LogBox = createTextArea(
    "Live Logs",
    "Logs, statistics, status information..."
)

LogBox.Text = "system initialized\nwaiting for activity..."

-- navigation

local tabs = {
    "Main",
    "Player",
    "Farming",
    "Teleport",
    "Settings",
}

local descriptions = {
    Main = "General controls and utilities.",
    Player = "Player movement and character settings.",
    Farming = "Automation and farming controls.",
    Teleport = "Teleport and location utilities.",
    Settings = "Interface and configuration settings.",
}

local navButtons = {}

local function selectTab(tabName)
    currentTab = tabName

    ContentTitle.Text = tabName
    ContentDescription.Text = descriptions[tabName] or ""

    for name, button in pairs(navButtons) do
        if name == tabName then
            tween(button, 0.15, {
                BackgroundColor3 = COLORS.AccentSoft,
            }):Play()

            button.TextColor3 = COLORS.Text
        else
            tween(button, 0.15, {
                BackgroundColor3 = COLORS.Panel,
            }):Play()

            button.TextColor3 = COLORS.Muted
        end
    end
end

for index, tabName in ipairs(tabs) do
    local button = create("TextButton", {
        Name = tabName,
        Size = UDim2.new(1, 0, 0, 37),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        Text = tabName,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = COLORS.Muted,
        AutoButtonColor = false,
        LayoutOrder = index,
    }, Navigation)

    addCorner(button, 10)

    navButtons[tabName] = button

    connect(button.MouseEnter, function()
        if currentTab ~= tabName then
            tween(button, 0.12, {
                BackgroundColor3 = COLORS.Secondary,
            }):Play()
        end
    end)

    connect(button.MouseLeave, function()
        if currentTab ~= tabName then
            tween(button, 0.12, {
                BackgroundColor3 = COLORS.Panel,
            }):Play()
        end
    end)

    connect(button.MouseButton1Click, function()
        selectTab(tabName)
    end)
end

selectTab("Main")

-- floating button

local FloatingButton = create("ImageButton", {
    Name = "FloatingButton",
    Position = UDim2.new(0, 24, 0, 90),
    Size = UDim2.new(0, 52, 0, 52),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
    Image = "rbxassetid://85074945377894",
    ImageTransparency = 0.03,
    Visible = false,
    AutoButtonColor = false,
}, ScreenGui)

addCorner(FloatingButton, 14)
addStroke(FloatingButton, COLORS.Border, 0.18)

-- floating drag

local floatingDragging = false
local floatingMoved = false
local floatingDragStart
local floatingStartPosition

connect(FloatingButton.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        floatingDragging = true
        floatingMoved = false
        floatingDragStart = input.Position
        floatingStartPosition = FloatingButton.Position
    end
end)

connect(FloatingButton.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        floatingDragging = false
    end
end)

connect(UserInputService.InputChanged, function(input)
    if not floatingDragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - floatingDragStart

        if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
            floatingMoved = true
        end

        FloatingButton.Position = UDim2.new(
            floatingStartPosition.X.Scale,
            floatingStartPosition.X.Offset + delta.X,
            floatingStartPosition.Y.Scale,
            floatingStartPosition.Y.Offset + delta.Y
        )
    end
end)

-- minimize

connect(MinimizeButton.MouseButton1Click, function()
    if minimized then
        return
    end

    minimized = true

    tween(Window, 0.22, {
        Size = UDim2.new(0, 570, 0, 68),
    }):Play()

    task.delay(0.22, function()
        if minimized then
            Window.Visible = false
            FloatingButton.Visible = true
        end
    end)
end)

-- reopen

connect(FloatingButton.MouseButton1Click, function()
    if floatingMoved then
        floatingMoved = false
        return
    end

    if not minimized then
        return
    end

    minimized = false
    FloatingButton.Visible = false
    Window.Visible = true

    Window.Size = UDim2.new(0, 570, 0, 68)

    tween(Window, 0.22, {
        Size = UDim2.new(0, 570, 0, 430),
    }):Play()

    task.delay(0.02, updateWindowSize)
end)

-- window drag
local dragging = false
local dragStart
local startPosition

local function updateDrag(input)
    local delta = input.Position - dragStart

    Window.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end

connect(HeaderFrame.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Window.Position
    end
end)

connect(HeaderFrame.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

connect(UserInputService.InputChanged, function(input)
    if not dragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        updateDrag(input)
    end
end)

-- close

connect(CloseButton.MouseButton1Click, function()
    for _, connection in ipairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end

    connections = {}

    ScreenGui:Destroy()
end)

-- anti afk

connect(player.Idled, function()
    if states.antiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- afk script killer

task.spawn(function()
    while task.wait(2) do
        if not ScreenGui.Parent then
            break
        end

        if states.antiAfk then
            for _, obj in pairs(player:GetDescendants()) do
                if obj:IsA("LocalScript") and obj.Name == "AFKScript" then
                    if obj.Disabled == false then
                        obj.Disabled = true

                        setStatus(
                            "AFKScript disabled",
                            COLORS.Success,
                            true
                        )

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

                            setStatus(
                                "AFKScript disabled",
                                COLORS.Success,
                                true
                            )

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

-- trash radar

local function getBestTrashInStick()
    local trashTriggersFolder = workspace:FindFirstChild(
        "TrashTriggers",
        true
    )

    if not trashTriggersFolder then
        return nil, nil
    end

    local stickFolder = trashTriggersFolder:FindFirstChild("Stick")

    if not stickFolder then
        return nil, nil
    end

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
        if prompt:IsA("ProximityPrompt")
            and (
                prompt.ObjectText == "Trash Master"
                or prompt.ActionText == "Open shop"
            ) then

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
            local current, max = string.match(
                v.Text,
                "^(%d+)%s*/%s*(%d+)$"
            )

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
        if v:IsA("TextLabel")
            and string.find(
                string.upper(v.Text),
                string.upper(targetText)
            ) then

            local btn = v.Parent

            if btn and btn:IsA("GuiButton") and getconnections then
                for _, conn in pairs(
                    getconnections(btn.MouseButton1Click)
                ) do
                    conn:Function()
                end

                return true
            end
        end
    end

    return false
end

-- pathfinding 
  local function smoothWalk(targetPos, breakCondition, stopDistance)
    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not rootPart then
        return
    end

    local path = PathfindingService:CreatePath({
        AgentRadius = 1.5,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 3
    })

    local success = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPos)
    end)

    if success
        and (
            path.Status == Enum.PathStatus.Success
            or path.Status == Enum.PathStatus.ClosestNoPath
        ) then

        local waypoints = path:GetWaypoints()

        for i = 2, #waypoints do
            if not states.autoFarm and not states.autoSell then
                return
            end

            if (rootPart.Position - targetPos).Magnitude <= stopDistance then
                return
            end

            if breakCondition and breakCondition() then
                return
            end

            local wp = waypoints[i]

            if wp.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end

            humanoid:MoveTo(wp.Position)

            local timeout = tick()
            local stuckTimer = 0

            while tick() - timeout < 2 do
                task.wait(0.05)

                if (rootPart.Position - targetPos).Magnitude <= stopDistance then
                    return
                end

                if breakCondition and breakCondition() then
                    return
                end

                local distToWp =
                    (
                        Vector2.new(
                            rootPart.Position.X,
                            rootPart.Position.Z
                        )
                        -
                        Vector2.new(
                            wp.Position.X,
                            wp.Position.Z
                        )
                    ).Magnitude

                if distToWp < 1.5 then
                    break
                end

                if rootPart.AssemblyLinearVelocity.Magnitude < 0.5 then
                    stuckTimer += 0.05
                    humanoid.Jump = true

                    if stuckTimer > 1 then
                        setStatus(
                            "Stuck, finding new route...",
                            COLORS.Warning,
                            true
                        )

                        humanoid:MoveTo(
                            rootPart.Position
                            - rootPart.CFrame.LookVector * 5
                        )

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

        local randomOffset = Vector3.new(
            math.random(-5, 5),
            0,
            math.random(-5, 5)
        )

        humanoid:MoveTo(rootPart.Position + randomOffset)

        task.wait(0.5)
    end
end

-- core

local isSellingPhase = false
local sellFailCounter = 0

task.spawn(function()
    while task.wait(0.2) do
        if not ScreenGui.Parent then
            break
        end

        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")

        if not humanoid or not rootPart or humanoid.Health <= 0 then
            continue
        end

        if states.autoClick and not states.autoFarm then
            local tool = character:FindFirstChildOfClass("Tool")

            if tool then
                tool:Activate()
            end
        end

        if states.autoSell
            and isInventoryFull()
            and not isSellingPhase then

            isSellingPhase = true
            sellFailCounter = 0
        end

        -- selling

        if isSellingPhase then
            local shopTargetPos = getShopTargetPosition()
            local npc = getTrashMasterNPC()

            if shopTargetPos and npc then
                local dist = (
                    rootPart.Position - shopTargetPos
                ).Magnitude

                if dist > 4 then
                    setStatus(
                        "Inventory full - going to shop",
                        COLORS.Warning,
                        false
                    )

                    smoothWalk(
                        shopTargetPos,
                        nil,
                        3
                    )
                else
                    humanoid:MoveTo(rootPart.Position)

                    setStatus(
                        "Opening shop...",
                        COLORS.Success,
                        false
                    )

                    local prompt = npc:FindFirstChildOfClass(
                        "ProximityPrompt"
                    )

                    if prompt and fireproximityprompt then
                        fireproximityprompt(prompt)
                    end

                    task.wait(1.5)

                    setStatus(
                        "Selling all items...",
                        COLORS.Success,
                        false
                    )

                    local isClicked = clickGuiButtonByText("SELL ALL")

                    if isClicked then
                        task.wait(1)

                        clickGuiButtonByText("X")

                        isSellingPhase = false

                        local backpack = player:FindFirstChild("Backpack")

                        if backpack then
                            local tool = backpack:FindFirstChildOfClass("Tool")

                            if tool then
                                humanoid:EquipTool(tool)
                            end
                        end

                        task.wait(1)
                    else
                        sellFailCounter += 1

                        setStatus(
                            "Failed to find sell button",
                            COLORS.Danger,
                            true
                        )

                        task.wait(1)

                        if sellFailCounter > 3 then
                            isSellingPhase = false
                            clickGuiButtonByText("X")
                        end
                    end
                end
            else
                setStatus(
                    "Shop target unavailable",
                    COLORS.Danger,
                    true
                )

                isSellingPhase = false

                task.wait(2)
            end

        -- farming

        elseif states.autoFarm then
            local targetPart, currentRarity = getBestTrashInStick()

            if targetPart then
                local dist = (
                    rootPart.Position - targetPart.Position
                ).Magnitude

                if dist > 5 then
                    if currentRarity == "Mythic" then
                        InfoLabel.TextColor3 = COLORS.Danger
                    else
                        InfoLabel.TextColor3 = COLORS.Warning
                    end

                    InfoLabel.Text =
                        "Going to "
                        .. currentRarity
                        .. " - "
                        .. targetPart.Name

                    local breakCheck = function()
                        if currentRarity == "Legendary" then
                            local _, newRarity = getBestTrashInStick()

                            if newRarity == "Mythic" then
                                return true
                            end
                        end

                        return false
                    end

                    smoothWalk(
                        targetPart.Position,
                        breakCheck,
                        4
                    )
                else
                    if currentRarity == "Mythic" then
                        InfoLabel.TextColor3 = COLORS.Danger
                    else
                        InfoLabel.TextColor3 = COLORS.Warning
                    end

                    InfoLabel.Text =
                        "Looting "
                        .. currentRarity
                        .. "!"

                    if targetPart.Position.Y > rootPart.Position.Y + 1 then
                        humanoid.Jump = true
                        humanoid:MoveTo(targetPart.Position)
                    else
                        humanoid:MoveTo(rootPart.Position)
                    end

                    local equippedTool =
                        character:FindFirstChildOfClass("Tool")

                    if not equippedTool then
                        local backpack = player:FindFirstChild("Backpack")

                        if backpack
                            and backpack:FindFirstChildOfClass("Tool") then

                            humanoid:EquipTool(
                                backpack:FindFirstChildOfClass("Tool")
                            )

                            task.wait(0.1)

                            equippedTool =
                                character:FindFirstChildOfClass("Tool")
                        end
                    end

                    if equippedTool then
                        equippedTool:Activate()
                    end
                end
            else
                InfoLabel.Text = "Waiting for Mythic / Legendary..."
                InfoLabel.TextColor3 = COLORS.Muted
            end

        elseif not states.autoFarm and not states.autoClick then
            InfoLabel.Text = "Status: Idle"
            InfoLabel.TextColor3 = COLORS.Muted
        end
    end
end)

-- startup

appendLog("Tpz Hub initialized")
appendLog("Game: " .. GAME_NAME)

task.delay(0.7, function()
    if ScreenGui.Parent then
        notify(
            "Tpz Hub",
            "Interface loaded successfully.",
            "rbxassetid://85074945377894"
        )
    end
end)

-- open animation

local originalSize = Window.Size

Window.Size = UDim2.new(
    originalSize.X.Scale,
    originalSize.X.Offset,
    0,
    0
)

tween(Window, 0.3, {
    Size = originalSize,
}):Play()