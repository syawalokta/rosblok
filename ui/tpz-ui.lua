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

-- colors
local COLORS = {
    Background = Color3.fromRGB(18, 20, 23),
    Panel = Color3.fromRGB(25, 28, 32),
    Secondary = Color3.fromRGB(31, 34, 39),
    Hover = Color3.fromRGB(38, 42, 48),

    Border = Color3.fromRGB(49, 53, 59),

    Text = Color3.fromRGB(232, 234, 237),
    Muted = Color3.fromRGB(145, 150, 158),

    Accent = Color3.fromRGB(88, 116, 145),
    AccentDark = Color3.fromRGB(68, 91, 114),
}

-- state
local gui = Instance.new("ScreenGui")
gui.Name = "TpzHub_UI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local minimized = false
local currentTab = "Main"
local connections = {}

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

local function tween(object, duration, properties)
    local info = TweenInfo.new(
        duration,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.Out
    )

    return TweenService:Create(object, info, properties)
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

-- main window
local window = create("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0, 560, 0, 390),
    BackgroundColor3 = COLORS.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, gui)

addCorner(window, 10)
addStroke(window, COLORS.Border, 0.15)

-- responsive size
local function updateWindowSize()
    local viewport = workspace.CurrentCamera.ViewportSize

    if viewport.X <= 700 then
        window.Size = UDim2.new(
            0.92,
            0,
            0,
            math.clamp(viewport.Y * 0.72, 330, 470)
        )
    else
        window.Size = UDim2.new(0, 560, 0, 390)
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
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
}, window)

create("Frame", {
    Name = "Line",
    Position = UDim2.new(0, 0, 1, -1),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = COLORS.Border,
    BorderSizePixel = 0,
}, header)

-- logo
create("ImageLabel", {
    Name = "Logo",
    Position = UDim2.new(0, 15, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    Size = UDim2.new(0, 31, 0, 31),
    BackgroundTransparency = 1,
    Image = "rbxassetid://85074945377894",
    ScaleType = Enum.ScaleType.Fit,
}, header)

-- title
create("TextLabel", {
    Name = "Title",
    Position = UDim2.new(0, 56, 0, 11),
    Size = UDim2.new(0, 220, 0, 21),
    BackgroundTransparency = 1,
    Text = "Tpz Hub",
    Font = Enum.Font.GothamMedium,
    TextSize = 17,
    TextColor3 = COLORS.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

create("TextLabel", {
    Name = "Subtitle",
    Position = UDim2.new(0, 56, 0, 31),
    Size = UDim2.new(0, 220, 0, 15),
    BackgroundTransparency = 1,
    Text = "utility panel",
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = COLORS.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

-- status
create("TextLabel", {
    Name = "Status",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -88, 0.5, 0),
    Size = UDim2.new(0, 60, 0, 22),
    BackgroundTransparency = 1,
    Text = "READY",
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextColor3 = COLORS.Muted,
    TextXAlignment = Enum.TextXAlignment.Right,
}, header)

-- header buttons
local minimizeButton = create("TextButton", {
    Name = "Minimize",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -45, 0.5, 0),
    Size = UDim2.new(0, 28, 0, 28),
    BackgroundColor3 = COLORS.Secondary,
    BorderSizePixel = 0,
    Text = "—",
    Font = Enum.Font.GothamMedium,
    TextSize = 14,
    TextColor3 = COLORS.Muted,
    AutoButtonColor = false,
}, header)

addCorner(minimizeButton, 6)

local closeButton = create("TextButton", {
    Name = "Close",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.new(0, 28, 0, 28),
    BackgroundColor3 = COLORS.Secondary,
    BorderSizePixel = 0,
    Text = "×",
    Font = Enum.Font.GothamMedium,
    TextSize = 16,
    TextColor3 = COLORS.Muted,
    AutoButtonColor = false,
}, header)

addCorner(closeButton, 6)

-- body
local body = create("Frame", {
    Name = "Body",
    Position = UDim2.new(0, 0, 0, 58),
    Size = UDim2.new(1, 0, 1, -58),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, window)

-- navigation
local navigation = create("Frame", {
    Name = "Navigation",
    Position = UDim2.new(0, 10, 0, 10),
    Size = UDim2.new(0, 125, 1, -20),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
}, body)

addCorner(navigation, 8)
addStroke(navigation, COLORS.Border, 0.35)

create("UIPadding", {
    PaddingTop = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 7),
    PaddingRight = UDim.new(0, 7),
    PaddingBottom = UDim.new(0, 8),
}, navigation)

create("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, navigation)

-- content
local content = create("Frame", {
    Name = "Content",
    Position = UDim2.new(0, 145, 0, 10),
    Size = UDim2.new(1, -155, 1, -20),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
}, body)

addCorner(content, 8)
addStroke(content, COLORS.Border, 0.35)

local contentTitle = create("TextLabel", {
    Name = "SectionTitle",
    Position = UDim2.new(0, 18, 0, 16),
    Size = UDim2.new(1, -36, 0, 24),
    BackgroundTransparency = 1,
    Text = "Main",
    Font = Enum.Font.GothamMedium,
    TextSize = 16,
    TextColor3 = COLORS.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
}, content)

local contentDescription = create("TextLabel", {
    Name = "Description",
    Position = UDim2.new(0, 18, 0, 41),
    Size = UDim2.new(1, -36, 0, 18),
    BackgroundTransparency = 1,
    Text = "General controls and utilities.",
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextColor3 = COLORS.Muted,
    TextXAlignment = Enum.TextXAlignment.Left,
}, content)

-- scroll area
local scroll = create("ScrollingFrame", {
    Name = "Scroll",
    Position = UDim2.new(0, 14, 0, 70),
    Size = UDim2.new(1, -28, 1, -84),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = COLORS.Border,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, content)

create("UIPadding", {
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 10),
}, scroll)

create("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, scroll)

-- ui components
local function createSection(text)
    return create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = COLORS.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, scroll)
end

local function createToggle(text, description, default)
    local state = default or false

    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0,
    }, scroll)

    addCorner(container, 6)

    create("TextLabel", {
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -70, 0, 17),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)

    create("TextLabel", {
        Position = UDim2.new(0, 12, 0, 27),
        Size = UDim2.new(1, -70, 0, 15),
        BackgroundTransparency = 1,
        Text = description,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = COLORS.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)

    local toggle = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.new(0, 36, 0, 20),
        BackgroundColor3 = COLORS.Border,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, container)

    addCorner(toggle, 10)

    local knob = create("Frame", {
        Position = UDim2.new(0, 3, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = COLORS.Text,
        BorderSizePixel = 0,
    }, toggle)

    addCorner(knob, 8)

    local function updateToggle()
        if state then
            tween(toggle, 0.15, {
                BackgroundColor3 = COLORS.Accent,
            }):Play()

            tween(knob, 0.15, {
                Position = UDim2.new(1, -17, 0.5, 0),
            }):Play()
        else
            tween(toggle, 0.15, {
                BackgroundColor3 = COLORS.Border,
            }):Play()

            tween(knob, 0.15, {
                Position = UDim2.new(0, 3, 0.5, 0),
            }):Play()
        end
    end

    connect(toggle.MouseButton1Click, function()
        state = not state
        updateToggle()
    end)

    updateToggle()

    return container
end

local function createButton(text, description)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = COLORS.Secondary,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, scroll)

    addCorner(button, 6)

    create("TextLabel", {
        Position = UDim2.new(0, 12, 0, 7),
        Size = UDim2.new(1, -24, 0, 17),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, button)

    if description then
        create("TextLabel", {
            Position = UDim2.new(0, 12, 0, 25),
            Size = UDim2.new(1, -24, 0, 13),
            BackgroundTransparency = 1,
            Text = description,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextColor3 = COLORS.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, button)
    end

    connect(button.MouseEnter, function()
        tween(button, 0.12, {
            BackgroundColor3 = COLORS.Hover,
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
            BackgroundColor3 = COLORS.Hover,
        }):Play()
    end)

    return button
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

createSection("Actions")

createButton(
    "Execute Action",
    "Run the selected utility."
)

createButton(
    "Refresh",
    "Reload available data."
)

createButton(
    "Reset Settings",
    "Restore the default configuration."
)

-- navigation logic
local tabs = {
    "Main",
    "Player",
    "Farming",
    "Teleport",
    "Settings",
}

local navButtons = {}

local function selectTab(tabName)
    currentTab = tabName
    contentTitle.Text = tabName

    local descriptions = {
        Main = "General controls and utilities.",
        Player = "Player related settings.",
        Farming = "Automation and farming controls.",
        Teleport = "Teleport and location utilities.",
        Settings = "Interface and configuration settings.",
    }

    contentDescription.Text = descriptions[tabName] or ""

    for name, button in pairs(navButtons) do
        if name == tabName then
            tween(button, 0.15, {
                BackgroundColor3 = COLORS.AccentDark,
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
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        Text = tabName,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = COLORS.Muted,
        AutoButtonColor = false,
        LayoutOrder = index,
    }, navigation)

    addCorner(button, 6)

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

-- floating open button
local floatingButton = create("ImageButton", {
    Name = "FloatingButton",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -18, 1, -18),
    Size = UDim2.new(0, 48, 0, 48),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
    Image = "rbxassetid://85074945377894",
    ImageTransparency = 0.05,
    Visible = false,
    AutoButtonColor = false,
}, gui)

addCorner(floatingButton, 9)
addStroke(floatingButton, COLORS.Border, 0.1)

-- minimize
connect(minimizeButton.MouseButton1Click, function()
    if minimized then
        return
    end

    minimized = true

    tween(window, 0.22, {
        Size = UDim2.new(0, 560, 0, 58),
    }):Play()

    task.delay(0.22, function()
        window.Visible = false
        floatingButton.Visible = true
    end)
end)

connect(floatingButton.MouseButton1Click, function()
    if not minimized then
        return
    end

    minimized = false
    floatingButton.Visible = false
    window.Visible = true

    window.Size = UDim2.new(0, 560, 0, 58)

    tween(window, 0.22, {
        Size = UDim2.new(0, 560, 0, 390),
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

-- drag system
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

tween(window, 0.28, {
    Size = originalSize,
}):Play()