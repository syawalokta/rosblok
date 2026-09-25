-- cleanup

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("TpzHub_UI")

if oldGui then
    oldGui:Destroy()
end

-- config

local GAME_NAME = "YOUR GAME"

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

-- state

local gui = Instance.new("ScreenGui")
gui.Name = "TpzHub_UI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

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

-- main window

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

-- responsive

local function updateWindowSize()
    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport = camera.ViewportSize

    if viewport.X <= 700 then
        window.Size = UDim2.new(
            0.93,
            0,
            0,
            math.clamp(viewport.Y * 0.76, 350, 520)
        )
    else
        window.Size = UDim2.new(0, 570, 0, 430)
    end
end

updateWindowSize()

connect(
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),
    updateWindowSize
)

-- header

local header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 68),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
}, window)

create("Frame", {
    Name = "Divider",
    Position = UDim2.new(0, 16, 1, -1),
    Size = UDim2.new(1, -32, 0, 1),
    BackgroundColor3 = COLORS.Border,
    BorderSizePixel = 0,
}, header)

-- logo

create("ImageLabel", {
    Name = "Logo",
    Position = UDim2.new(0, 18, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    Size = UDim2.new(0, 38, 0, 38),
    BackgroundTransparency = 1,
    Image = "rbxassetid://85074945377894",
    ScaleType = Enum.ScaleType.Fit,
}, header)

-- title

create("TextLabel", {
    Name = "Title",
    Position = UDim2.new(0, 67, 0, 12),
    Size = UDim2.new(0, 240, 0, 27),
    BackgroundTransparency = 1,
    Text = "Tpz Hub",
    Font = Enum.Font.GothamBold,
    TextSize = 19,
    TextColor3 = COLORS.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

create("TextLabel", {
    Name = "GameName",
    Position = UDim2.new(0, 68, 0, 38),
    Size = UDim2.new(0, 240, 0, 17),
    BackgroundTransparency = 1,
    Text = GAME_NAME,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = COLORS.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

-- status

create("TextLabel", {
    Name = "Status",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -95, 0.5, 0),
    Size = UDim2.new(0, 55, 0, 20),
    BackgroundTransparency = 1,
    Text = "READY",
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextColor3 = COLORS.Muted,
    TextXAlignment = Enum.TextXAlignment.Right,
}, header)

-- minimize

local minimizeButton = create("TextButton", {
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
}, header)

addCorner(minimizeButton, 9)

-- close

local closeButton = create("TextButton", {
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
}, header)

addCorner(closeButton, 9)

-- body

local body = create("Frame", {
    Name = "Body",
    Position = UDim2.new(0, 0, 0, 68),
    Size = UDim2.new(1, 0, 1, -68),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, window)

-- navigation

local navigation = create("Frame", {
    Name = "Navigation",
    Position = UDim2.new(0, 12, 0, 12),
    Size = UDim2.new(0, 130, 1, -24),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
}, body)

addCorner(navigation, 12)
addStroke(navigation, COLORS.Border, 0.35)

create("UIPadding", {
    PaddingTop = UDim.new(0, 10),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 10),
}, navigation)

create("UIListLayout", {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, navigation)

-- content

local content = create("Frame", {
    Name = "Content",
    Position = UDim2.new(0, 154, 0, 12),
    Size = UDim2.new(1, -166, 1, -24),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
}, body)

addCorner(content, 12)
addStroke(content, COLORS.Border, 0.35)

-- content header

local contentTitle = create("TextLabel", {
    Name = "Title",
    Position = UDim2.new(0, 19, 0, 16),
    Size = UDim2.new(1, -38, 0, 24),
    BackgroundTransparency = 1,
    Text = "Main",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = COLORS.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, content)

local contentDescription = create("TextLabel", {
    Name = "Description",
    Position = UDim2.new(0, 19, 0, 41),
    Size = UDim2.new(1, -38, 0, 18),
    BackgroundTransparency = 1,
    Text = "General controls and utilities.",
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = COLORS.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
}, content)

-- scroll

local scroll = create("ScrollingFrame", {
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
}, content)

create("UIPadding", {
    PaddingLeft = UDim.new(0, 5),
    PaddingRight = UDim.new(0, 5),
    PaddingBottom = UDim.new(0, 12),
}, scroll)

create("UIListLayout", {
    Padding = UDim.new(0, 9),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, scroll)

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
    }, scroll)
end

-- toggle

local function createToggle(text, description, default)
    local state = default or false

    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0,
    }, scroll)

    addCorner(container, 11)

    create("TextLabel", {
        Position = UDim2.new(0, 13, 0, 8),
        Size = UDim2.new(1, -75, 0, 18),
        BackgroundTransparency = 1,
        Text = text,
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
        if state then
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
        state = not state
        update()
    end)

    update()

    return container
end

-- slider

local function createSlider(text, description, minimum, maximum, default)
    local value = default or minimum

    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 76),
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0,
    }, scroll)

    addCorner(container, 11)

    create("TextLabel", {
        Position = UDim2.new(0, 13, 0, 9),
        Size = UDim2.new(1, -80, 0, 18),
        BackgroundTransparency = 1,
        Text = text,
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

    local sliderArea = create("Frame", {
        Position = UDim2.new(0, 13, 1, -17),
        Size = UDim2.new(1, -26, 0, 6),
        BackgroundColor3 = COLORS.SliderBackground,
        BorderSizePixel = 0,
    }, container)

    addCorner(sliderArea, 5)

    local normalized = (value - minimum) / (maximum - minimum)

    local fill = create("Frame", {
        Size = UDim2.new(normalized, 0, 1, 0),
        BackgroundColor3 = COLORS.Accent,
        BorderSizePixel = 0,
    }, sliderArea)

    addCorner(fill, 5)

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(normalized, 0, 0.5, 0),
        Size = UDim2.new(0, 15, 0, 15),
        BackgroundColor3 = COLORS.Text,
        BorderSizePixel = 0,
    }, sliderArea)

    addCorner(knob, 10)

    local draggingSlider = false

    local function updateFromPosition(position)
        if sliderArea.AbsoluteSize.X <= 0 then
            return
        end

        local relative = math.clamp(
            position.X - sliderArea.AbsolutePosition.X,
            0,
            sliderArea.AbsoluteSize.X
        )

        local percentage = relative / sliderArea.AbsoluteSize.X

        value = math.floor(
            minimum + ((maximum - minimum) * percentage) + 0.5
        )

        local current = (value - minimum) / (maximum - minimum)

        fill.Size = UDim2.new(current, 0, 1, 0)
        knob.Position = UDim2.new(current, 0, 0.5, 0)

        valueLabel.Text = tostring(value)
    end

    connect(sliderArea.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            draggingSlider = true
            updateFromPosition(input.Position)
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if not draggingSlider then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            updateFromPosition(input.Position)
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

-- text area

local function createTextArea(titleText, placeholder)
    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 125),
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0,
    }, scroll)

    addCorner(container, 11)

    create("TextLabel", {
        Position = UDim2.new(0, 13, 0, 10),
        Size = UDim2.new(1, -26, 0, 18),
        BackgroundTransparency = 1,
        Text = titleText,
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
        PlaceholderText = placeholder or "",
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

-- dummy content

createSection("General")

createToggle(
    "Auto Farm",
    "Automatically perform the selected farming action.",
    false
)

createToggle(
    "Auto Collect",
    "Collect nearby resources automatically.",
    true
)

createToggle(
    "Anti AFK",
    "Prevent the client from becoming idle.",
    false
)

createSection("Movement")

createSlider(
    "Walk Speed",
    "Adjust the player's movement speed.",
    16,
    100,
    16
)

createSlider(
    "Jump Power",
    "Adjust the player's jump strength.",
    50,
    150,
    50
)

createSection("Logs / Statistics")

local logBox = createTextArea(
    "Live Logs",
    "Logs, statistics, status information..."
)

logBox.Text = "system initialized\nwaiting for activity..."

-- log helpers

local function setLogText(text)
    logBox.Text = tostring(text)
end

local function appendLog(text)
    local current = logBox.Text

    if current == "" then
        logBox.Text = tostring(text)
    else
        logBox.Text = current .. "\n" .. tostring(text)
    end

    task.defer(function()
        logBox.CursorPosition = #logBox.Text + 1
    end)
end

-- buttons

local function createButton(text, description)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 49),
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, scroll)

    addCorner(button, 11)

    create("TextLabel", {
        Position = UDim2.new(0, 13, 0, 7),
        Size = UDim2.new(1, -26, 0, 17),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, button)

    create("TextLabel", {
        Position = UDim2.new(0, 13, 0, 26),
        Size = UDim2.new(1, -26, 0, 13),
        BackgroundTransparency = 1,
        Text = description,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = COLORS.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, button)

    connect(button.MouseEnter, function()
        tween(button, 0.12, {
            BackgroundColor3 = COLORS.SecondaryHover,
        }):Play()
    end)

    connect(button.MouseLeave, function()
        tween(button, 0.12, {
            BackgroundColor3 = COLORS.Secondary,
        }):Play()
    end)

    connect(button.MouseButton1Down, function()
        tween(button, 0.08, {
            BackgroundColor3 = COLORS.Border,
        }):Play()
    end)

    connect(button.MouseButton1Up, function()
        tween(button, 0.12, {
            BackgroundColor3 = COLORS.SecondaryHover,
        }):Play()
    end)

    return button
end

-- notifications

local notificationHolder = create("Frame", {
    Name = "Notifications",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -18, 1, -18),
    Size = UDim2.new(0, 320, 0, 300),
    BackgroundTransparency = 1,
}, gui)

local notificationLayout = create("UIListLayout", {
    Padding = UDim.new(0, 8),
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, notificationHolder)

local notifications = {}
local notificationId = 0
local MAX_NOTIFICATIONS = 4

local function removeNotification(notification)
    for index, item in ipairs(notifications) do
        if item == notification then
            table.remove(notifications, index)
            break
        end
    end

    if notification and notification.Parent then
        local hide = tween(notification, 0.22, {
            Position = UDim2.new(1, 25, 0, 0),
            BackgroundTransparency = 1,
        })

        hide:Play()

        task.delay(0.23, function()
            if notification then
                notification:Destroy()
            end
        end)
    end
end

local function notify(titleText, messageText, icon)
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
        BackgroundColor3 = COLORS.Notification,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        LayoutOrder = notificationId,
        Position = UDim2.new(1, 30, 0, 0),
    }, notificationHolder)

    addCorner(notification, 14)
    addStroke(notification, COLORS.Border, 0.28)

    create("Frame", {
        Name = "Accent",
        Position = UDim2.new(0, 0, 0, 14),
        Size = UDim2.new(0, 3, 1, -28),
        BackgroundColor3 = COLORS.Accent,
        BorderSizePixel = 0,
    }, notification)

    addCorner(notification:FindFirstChild("Accent"), 2)

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
        if notification.Parent then
            removeNotification(notification)
        end
    end)
end

-- notification test

local testNotification = createButton(
    "Test Notification",
    "Display a sample notification."
)

connect(testNotification.MouseButton1Click, function()
    notify(
        "Notification example",
        "Your action was successfully executed.",
        "rbxassetid://85074945377894"
    )
end)

createButton(
    "Refresh",
    "Reload available data."
)

createButton(
    "Reset Settings",
    "Restore the default configuration."
)

-- navigation

local tabs = {
    "Main",
    "Player",
    "Farming",
    "Teleport",
    "Settings",
}

local navButtons = {}

local descriptions = {
    Main = "General controls and utilities.",
    Player = "Player movement and character settings.",
    Farming = "Automation and farming controls.",
    Teleport = "Teleport and location utilities.",
    Settings = "Interface and configuration settings.",
}

local function selectTab(tabName)
    currentTab = tabName

    contentTitle.Text = tabName
    contentDescription.Text = descriptions[tabName] or ""

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
    }, navigation)

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

local floatingButton = create("ImageButton", {
    Name = "FloatingButton",
    Position = UDim2.new(0, 24, 0, 90),
    Size = UDim2.new(0, 52, 0, 52),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
    Image = "rbxassetid://85074945377894",
    ImageTransparency = 0.03,
    Visible = false,
    AutoButtonColor = false,
}, gui)

addCorner(floatingButton, 14)
addStroke(floatingButton, COLORS.Border, 0.18)

-- floating button drag

local floatingDragging = false
local floatingDragStart
local floatingStartPosition

connect(floatingButton.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        floatingDragging = true
        floatingDragStart = input.Position
        floatingStartPosition = floatingButton.Position
    end
end)

connect(floatingButton.InputEnded, function(input)
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

        floatingButton.Position = UDim2.new(
            floatingStartPosition.X.Scale,
            floatingStartPosition.X.Offset + delta.X,
            floatingStartPosition.Y.Scale,
            floatingStartPosition.Y.Offset + delta.Y
        )
    end
end)

-- minimize

connect(minimizeButton.MouseButton1Click, function()
    if minimized then
        return
    end

    minimized = true

    tween(window, 0.22, {
        Size = UDim2.new(0, 570, 0, 68),
    }):Play()

    task.delay(0.22, function()
        if not minimized then
            return
        end

        window.Visible = false
        floatingButton.Visible = true
    end)
end)

-- reopen

connect(floatingButton.MouseButton1Click, function()
    if floatingDragging then
        return
    end

    if not minimized then
        return
    end

    minimized = false
    floatingButton.Visible = false
    window.Visible = true

    window.Size = UDim2.new(0, 570, 0, 68)

    tween(window, 0.22, {
        Size = UDim2.new(0, 570, 0, 430),
    }):Play()

    task.delay(0.02, updateWindowSize)
end)

-- close

connect(closeButton.MouseButton1Click, function()
    for _, connection in ipairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end

    connections = {}

    gui:Destroy()
end)

-- window drag

local dragging = false
local dragStart
local startPosition

local function updateDrag(input)
    local delta = input.Position - dragStart

    window.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end

connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = window.Position
    end
end)

connect(header.InputEnded, function(input)
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

-- open animation

local originalSize = window.Size

window.Size = UDim2.new(
    originalSize.X.Scale,
    originalSize.X.Offset,
    0,
    0
)

tween(window, 0.3, {
    Size = originalSize,
}):Play()

-- startup notification

task.delay(0.7, function()
    if gui.Parent then
        notify(
            "Tpz Hub",
            "Interface loaded successfully.",
            "rbxassetid://85074945377894"
        )
    end
end)