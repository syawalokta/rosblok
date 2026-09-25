-- tpz ui library

local TpzUI = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local DEFAULTS = {
    Title = "Tpz Hub",
    GameName = nil,
    Icon = "rbxassetid://85074945377894",
    Width = 570,
    Height = 430,
    MaxNotifications = 4,
}

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

local function getGameName()
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)

    if ok and info and info.Name then
        return info.Name
    end

    return "Unknown Game"
end

function TpzUI.new(options)
    options = options or {}

    local self = {}

    for key, value in pairs(DEFAULTS) do
        self[key] = options[key] ~= nil and options[key] or value
    end

    self.GameName = self.GameName or getGameName()
    setmetatable(self, { __index = TpzUI })
    self.Connections = {}
    self.Toggles = {}
    self.Sliders = {}
    self.Buttons = {}
    self.Sections = {}
    self.Notifications = {}
    self.TabButtons = {}
    self.Pages = {}
    self.CurrentTab = "Main"
    self.Minimized = false
    self.Destroyed = false
    self.NotificationId = 0

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local oldGui = playerGui:FindFirstChild("TpzHub_UI")
    if oldGui then
        oldGui:Destroy()
    end

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(self.Connections, connection)
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

    self.Gui = create("ScreenGui", {
        Name = "TpzHub_UI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, playerGui)

    local gui = self.Gui

    self.Window = create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, self.Width, 0, self.Height),
        BackgroundColor3 = COLORS.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, gui)

    local window = self.Window
    addCorner(window, 14)
    addStroke(window, COLORS.Border, 0.18)

    local header = create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 68),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
    }, window)

    create("ImageLabel", {
        Name = "Logo",
        Position = UDim2.new(0, 18, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 38, 0, 38),
        BackgroundTransparency = 1,
        Image = self.Icon,
        ScaleType = Enum.ScaleType.Fit,
    }, header)

    create("TextLabel", {
        Name = "Title",
        Position = UDim2.new(0, 67, 0, 12),
        Size = UDim2.new(0, 240, 0, 27),
        BackgroundTransparency = 1,
        Text = self.Title,
        Font = Enum.Font.GothamBold,
        TextSize = 19,
        TextColor3 = COLORS.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)

    self.GameNameLabel = create("TextLabel", {
        Name = "GameName",
        Position = UDim2.new(0, 68, 0, 38),
        Size = UDim2.new(0, 240, 0, 17),
        BackgroundTransparency = 1,
        Text = self.GameName,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = COLORS.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)

    self.StatusLabel = create("TextLabel", {
        Name = "Status",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -95, 0.5, 0),
        Size = UDim2.new(0, 70, 0, 20),
        BackgroundTransparency = 1,
        Text = "READY",
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = COLORS.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, header)

    self.MinimizeButton = create("TextButton", {
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
    addCorner(self.MinimizeButton, 9)

    self.CloseButton = create("TextButton", {
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
    addCorner(self.CloseButton, 9)

    local body = create("Frame", {
        Name = "Body",
        Position = UDim2.new(0, 0, 0, 68),
        Size = UDim2.new(1, 0, 1, -68),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, window)

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

    local content = create("Frame", {
        Name = "Content",
        Position = UDim2.new(0, 154, 0, 12),
        Size = UDim2.new(1, -166, 1, -24),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
    }, body)
    addCorner(content, 12)
    addStroke(content, COLORS.Border, 0.35)

    self.ContentTitle = create("TextLabel", {
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

    self.ContentDescription = create("TextLabel", {
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

    local pageHolder = create("Frame", {
        Name = "PageHolder",
        Position = UDim2.new(0, 14, 0, 72),
        Size = UDim2.new(1, -28, 1, -86),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, content)

    local descriptions = options.Descriptions or {
        Main = "General controls and utilities.",
        Player = "Player movement and character settings.",
        Farming = "Automation and farming controls.",
        Teleport = "Teleport and location utilities.",
        Settings = "Interface and configuration settings.",
    }

    local function createPage(name)
        local page = create("ScrollingFrame", {
            Name = name .. "Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = COLORS.Border,
            ScrollBarImageTransparency = 0.2,
            Visible = name == "Main",
        }, pageHolder)

        create("UIPadding", {
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 12),
        }, page)

        create("UIListLayout", {
            Padding = UDim.new(0, 9),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, page)

        self.Pages[name] = page
        return page
    end

    self.Descriptions = descriptions

    local tabs = options.Tabs or {"Main", "Player", "Farming", "Teleport", "Settings"}

    for index, tabName in ipairs(tabs) do
        createPage(tabName)

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
        self.TabButtons[tabName] = button

        connect(button.MouseEnter, function()
            if self.CurrentTab ~= tabName then
                tween(button, 0.12, {
                    BackgroundColor3 = COLORS.Secondary,
                }):Play()
            end
        end)

        connect(button.MouseLeave, function()
            if self.CurrentTab ~= tabName then
                tween(button, 0.12, {
                    BackgroundColor3 = COLORS.Panel,
                }):Play()
            end
        end)

        connect(button.MouseButton1Click, function()
            self:SelectTab(tabName)
        end)
    end

    local notificationHolder = create("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.new(0, 320, 0, 300),
        BackgroundTransparency = 1,
    }, gui)

    create("UIListLayout", {
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, notificationHolder)

    self.FloatingButton = create("ImageButton", {
        Name = "FloatingButton",
        Position = UDim2.new(0, 24, 0, 90),
        Size = UDim2.new(0, 52, 0, 52),
        BackgroundColor3 = COLORS.Panel,
        BorderSizePixel = 0,
        Image = self.Icon,
        ImageTransparency = 0.03,
        Visible = false,
        AutoButtonColor = false,
    }, gui)
    addCorner(self.FloatingButton, 14)
    addStroke(self.FloatingButton, COLORS.Border, 0.18)

    local floatingDragging = false
    local floatingDragStart
    local floatingStartPosition

    connect(self.FloatingButton.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            floatingDragging = true
            floatingDragStart = input.Position
            floatingStartPosition = self.FloatingButton.Position
        end
    end)

    connect(self.FloatingButton.InputEnded, function(input)
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
            self.FloatingButton.Position = UDim2.new(
                floatingStartPosition.X.Scale,
                floatingStartPosition.X.Offset + delta.X,
                floatingStartPosition.Y.Scale,
                floatingStartPosition.Y.Offset + delta.Y
            )
        end
    end)

    local dragStarted = false
    local dragStart
    local startPosition

    connect(header.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragStarted = true
            dragStart = input.Position
            startPosition = window.Position
        end
    end)

    connect(header.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragStarted = false
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        if not dragStarted then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart

            window.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    connect(self.MinimizeButton.MouseButton1Click, function()
        self:Minimize()
    end)

    connect(self.FloatingButton.MouseButton1Click, function()
        if not floatingDragging then
            self:Restore()
        end
    end)

    connect(self.CloseButton.MouseButton1Click, function()
        self:Destroy()
    end)

    self:SelectTab("Main")

    local originalSize = window.Size
    window.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 0)

    tween(window, 0.3, {
        Size = originalSize,
    }):Play()

    return self
end

function TpzUI:SelectTab(tabName)
    if self.Destroyed or not self.Pages[tabName] then
        return
    end

    self.CurrentTab = tabName

    self.ContentTitle.Text = tabName

    local descriptions = self.Descriptions
    if descriptions and descriptions[tabName] then
        self.ContentDescription.Text = descriptions[tabName]
    end

    for name, button in pairs(self.TabButtons) do
        local active = name == tabName

        tween(button, 0.15, {
            BackgroundColor3 = active and COLORS.AccentSoft or COLORS.Panel,
        }):Play()

        button.TextColor3 = active and COLORS.Text or COLORS.Muted
    end

    for name, page in pairs(self.Pages) do
        page.Visible = name == tabName
    end
end

function TpzUI:SetStatus(text, color)
    if self.Destroyed or not self.StatusLabel then
        return
    end

    self.StatusLabel.Text = tostring(text)

    if color then
        self.StatusLabel.TextColor3 = color
    end
end

function TpzUI:SetGameName(text)
    if self.GameNameLabel then
        self.GameNameLabel.Text = tostring(text)
    end
end

function TpzUI:Notify(title, message, icon)
    if self.Destroyed then
        return
    end

    local holder = self.Gui:FindFirstChild("Notifications")
    if not holder then
        return
    end

    self.NotificationId += 1

    if #self.Notifications >= self.MaxNotifications then
        local oldest = table.remove(self.Notifications, 1)

        if oldest and oldest.Parent then
            oldest:Destroy()
        end
    end

    local notification = Instance.new("Frame")
    notification.Name = "Notification_" .. self.NotificationId
    notification.Size = UDim2.new(1, 0, 0, 68)
    notification.BackgroundColor3 = COLORS.Notification
    notification.BackgroundTransparency = 0.02
    notification.BorderSizePixel = 0
    notification.LayoutOrder = self.NotificationId
    notification.Parent = holder

    addCorner(notification, 14)
    addStroke(notification, COLORS.Border, 0.28)

    local accent = Instance.new("Frame")
    accent.Position = UDim2.new(0, 0, 0, 14)
    accent.Size = UDim2.new(0, 3, 1, -28)
    accent.BackgroundColor3 = COLORS.Accent
    accent.BorderSizePixel = 0
    accent.Parent = notification
    addCorner(accent, 2)

    local iconBackground = Instance.new("Frame")
    iconBackground.Position = UDim2.new(0, 13, 0.5, 0)
    iconBackground.AnchorPoint = Vector2.new(0, 0.5)
    iconBackground.Size = UDim2.new(0, 34, 0, 34)
    iconBackground.BackgroundColor3 = COLORS.Secondary
    iconBackground.BorderSizePixel = 0
    iconBackground.Parent = notification
    addCorner(iconBackground, 10)

    if icon then
        local image = Instance.new("ImageLabel")
        image.AnchorPoint = Vector2.new(0.5, 0.5)
        image.Position = UDim2.fromScale(0.5, 0.5)
        image.Size = UDim2.new(0, 20, 0, 20)
        image.BackgroundTransparency = 1
        image.Image = icon
        image.ImageColor3 = COLORS.TextSoft
        image.ScaleType = Enum.ScaleType.Fit
        image.Parent = iconBackground
    end

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Position = UDim2.new(0, 58, 0, 12)
    titleLabel.Size = UDim2.new(1, -70, 0, 18)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = tostring(title)
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextSize = 12
    titleLabel.TextColor3 = COLORS.Text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notification

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Position = UDim2.new(0, 58, 0, 34)
    messageLabel.Size = UDim2.new(1, -70, 0, 17)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = tostring(message)
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 10
    messageLabel.TextColor3 = COLORS.Muted
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
    messageLabel.Parent = notification

    table.insert(self.Notifications, notification)

    notification.Position = UDim2.new(1, 30, 0, 0)

    tween(notification, 0.3, {
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()

    task.delay(4, function()
        if notification.Parent then
            for index, item in ipairs(self.Notifications) do
                if item == notification then
                    table.remove(self.Notifications, index)
                    break
                end
            end

            tween(notification, 0.22, {
                Position = UDim2.new(1, 25, 0, 0),
                BackgroundTransparency = 1,
            }):Play()

            task.delay(0.23, function()
                if notification then
                    notification:Destroy()
                end
            end)
        end
    end)
end

function TpzUI:CreateSection(text, tabName)
    tabName = tabName or self.CurrentTab

    local page = self.Pages[tabName]
    if not page then
        return
    end

    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, 0, 0, 20)
    section.BackgroundTransparency = 1
    section.Text = tostring(text)
    section.Font = Enum.Font.GothamMedium
    section.TextSize = 11
    section.TextColor3 = COLORS.Muted
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.Parent = page

    table.insert(self.Sections, section)
    return section
end

function TpzUI:CreateToggle(name, description, defaultState, callback, tabName)
    tabName = tabName or self.CurrentTab

    local page = self.Pages[tabName]
    if not page then
        return
    end

    local state = defaultState == true

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 56)
    container.BackgroundColor3 = COLORS.Secondary
    container.BorderSizePixel = 0
    container.Parent = page
    addCorner(container, 11)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Position = UDim2.new(0, 13, 0, 8)
    titleLabel.Size = UDim2.new(1, -75, 0, 18)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = tostring(name)
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextSize = 12
    titleLabel.TextColor3 = COLORS.Text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = container

    local descLabel = Instance.new("TextLabel")
    descLabel.Position = UDim2.new(0, 13, 0, 28)
    descLabel.Size = UDim2.new(1, -75, 0, 15)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = tostring(description or "")
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 9
    descLabel.TextColor3 = COLORS.Muted
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = container

    local toggle = Instance.new("TextButton")
    toggle.AnchorPoint = Vector2.new(1, 0.5)
    toggle.Position = UDim2.new(1, -13, 0.5, 0)
    toggle.Size = UDim2.new(0, 38, 0, 21)
    toggle.BackgroundColor3 = COLORS.SliderBackground
    toggle.BorderSizePixel = 0
    toggle.Text = ""
    toggle.AutoButtonColor = false
    toggle.Parent = container
    addCorner(toggle, 12)

    local knob = Instance.new("Frame")
    knob.Position = UDim2.new(0, 3, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Size = UDim2.new(0, 15, 0, 15)
    knob.BackgroundColor3 = COLORS.Text
    knob.BorderSizePixel = 0
    knob.Parent = toggle
    addCorner(knob, 9)

    local control = {}

    local function update(fireCallback)
        tween(toggle, 0.15, {
            BackgroundColor3 = state and COLORS.Accent or COLORS.SliderBackground,
        }):Play()

        tween(knob, 0.15, {
            Position = state
                and UDim2.new(1, -18, 0.5, 0)
                or UDim2.new(0, 3, 0.5, 0),
        }):Play()

        if fireCallback ~= false then
            local fn = control.Callback or callback
            if fn then
                fn(state)
            end
        end
    end

    connect(toggle.MouseButton1Click, function()
        state = not state
        update(true)
    end)

    function control:Get()
        return state
    end

    function control:Set(value, fireCallback)
        state = value == true

        tween(toggle, 0.15, {
            BackgroundColor3 = state and COLORS.Accent or COLORS.SliderBackground,
        }):Play()

        tween(knob, 0.15, {
            Position = state
                and UDim2.new(1, -18, 0.5, 0)
                or UDim2.new(0, 3, 0.5, 0),
        }):Play()

        if fireCallback ~= false then
            local fn = control.Callback or callback
            if fn then
                fn(state)
            end
        end
    end

    function control:Destroy()
        container:Destroy()
    end

    self.Toggles[name] = control
    control.Instance = container

    update(false)

    return control
end

function TpzUI:OnToggle(name, callback)
    local toggle = self.Toggles[name]
    if not toggle then
        return false
    end

    toggle.Callback = callback
    return true
end

function TpzUI:SetToggle(name, state)
    local toggle = self.Toggles[name]
    if not toggle then
        return false
    end

    toggle:Set(state)
    return true
end

function TpzUI:CreateSlider(name, description, minimum, maximum, defaultValue, callback, tabName)
    tabName = tabName or self.CurrentTab

    local page = self.Pages[tabName]
    if not page then
        return
    end

    minimum = tonumber(minimum) or 0
    maximum = tonumber(maximum) or 100
    defaultValue = math.clamp(tonumber(defaultValue) or minimum, minimum, maximum)

    local value = defaultValue

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 76)
    container.BackgroundColor3 = COLORS.Secondary
    container.BorderSizePixel = 0
    container.Parent = page
    addCorner(container, 11)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Position = UDim2.new(0, 13, 0, 9)
    titleLabel.Size = UDim2.new(1, -80, 0, 18)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = tostring(name)
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextSize = 12
    titleLabel.TextColor3 = COLORS.Text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, -13, 0, 9)
    valueLabel.Size = UDim2.new(0, 50, 0, 18)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(value)
    valueLabel.Font = Enum.Font.GothamMedium
    valueLabel.TextSize = 11
    valueLabel.TextColor3 = COLORS.TextSoft
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container

    local descLabel = Instance.new("TextLabel")
    descLabel.Position = UDim2.new(0, 13, 0, 28)
    descLabel.Size = UDim2.new(1, -26, 0, 14)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = tostring(description or "")
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 9
    descLabel.TextColor3 = COLORS.Muted
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = container

    local sliderArea = Instance.new("Frame")
    sliderArea.Position = UDim2.new(0, 13, 1, -17)
    sliderArea.Size = UDim2.new(1, -26, 0, 6)
    sliderArea.BackgroundColor3 = COLORS.SliderBackground
    sliderArea.BorderSizePixel = 0
    sliderArea.Parent = container
    addCorner(sliderArea, 5)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((value - minimum) / (maximum - minimum), 0, 1, 0)
    fill.BackgroundColor3 = COLORS.Accent
    fill.BorderSizePixel = 0
    fill.Parent = sliderArea
    addCorner(fill, 5)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((value - minimum) / (maximum - minimum), 0, 0.5, 0)
    knob.Size = UDim2.new(0, 15, 0, 15)
    knob.BackgroundColor3 = COLORS.Text
    knob.BorderSizePixel = 0
    knob.Parent = sliderArea
    addCorner(knob, 10)

    local draggingSlider = false
    local control = {}

    local function setValue(newValue, fireCallback)
        value = math.clamp(math.floor(tonumber(newValue) or minimum + 0.5), minimum, maximum)

        local normalized = 0
        if maximum ~= minimum then
            normalized = (value - minimum) / (maximum - minimum)
        end

        fill.Size = UDim2.new(normalized, 0, 1, 0)
        knob.Position = UDim2.new(normalized, 0, 0.5, 0)
        valueLabel.Text = tostring(value)

        if fireCallback ~= false and callback then
            callback(value)
        end
    end

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
        setValue(minimum + ((maximum - minimum) * percentage))
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

    function control:Get()
        return value
    end

    function control:Set(newValue, fireCallback)
        setValue(newValue, fireCallback)
    end

    function control:Destroy()
        container:Destroy()
    end

    control.Instance = container
    self.Sliders[name] = control

    setValue(value, false)

    return control
end

function TpzUI:CreateTextArea(title, placeholder, defaultText, tabName)
    tabName = tabName or self.CurrentTab

    local page = self.Pages[tabName]
    if not page then
        return
    end

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 125)
    container.BackgroundColor3 = COLORS.Secondary
    container.BorderSizePixel = 0
    container.Parent = page
    addCorner(container, 11)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Position = UDim2.new(0, 13, 0, 10)
    titleLabel.Size = UDim2.new(1, -26, 0, 18)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = tostring(title)
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextSize = 12
    titleLabel.TextColor3 = COLORS.Text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = container

    local textBox = Instance.new("TextBox")
    textBox.Position = UDim2.new(0, 12, 0, 34)
    textBox.Size = UDim2.new(1, -24, 1, -45)
    textBox.BackgroundColor3 = COLORS.Panel
    textBox.BorderSizePixel = 0
    textBox.Text = defaultText or ""
    textBox.PlaceholderText = placeholder or ""
    textBox.PlaceholderColor3 = COLORS.Muted
    textBox.TextColor3 = COLORS.TextSoft
    textBox.Font = Enum.Font.Code
    textBox.TextSize = 10
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.TextYAlignment = Enum.TextYAlignment.Top
    textBox.TextWrapped = true
    textBox.ClearTextOnFocus = false
    textBox.MultiLine = true
    textBox.ScrollBarThickness = 2
    textBox.ScrollBarImageColor3 = COLORS.Border
    textBox.Parent = container
    addCorner(textBox, 8)

    local control = {}

    function control:Get()
        return textBox.Text
    end

    function control:Set(value)
        textBox.Text = tostring(value or "")
    end

    function control:Append(value)
        if textBox.Text == "" then
            textBox.Text = tostring(value)
        else
            textBox.Text = textBox.Text .. "\n" .. tostring(value)
        end

        task.defer(function()
            textBox.CursorPosition = #textBox.Text + 1
        end)
    end

    function control:Clear()
        textBox.Text = ""
    end

    function control:Destroy()
        container:Destroy()
    end

    control.Instance = container
    return control
end

function TpzUI:CreateButton(name, description, callback, tabName)
    tabName = tabName or self.CurrentTab

    local page = self.Pages[tabName]
    if not page then
        return
    end

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 49)
    button.BackgroundColor3 = COLORS.Secondary
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = page
    addCorner(button, 11)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Position = UDim2.new(0, 13, 0, 7)
    titleLabel.Size = UDim2.new(1, -26, 0, 17)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = tostring(name)
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextSize = 12
    titleLabel.TextColor3 = COLORS.Text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = button

    local descLabel = Instance.new("TextLabel")
    descLabel.Position = UDim2.new(0, 13, 0, 26)
    descLabel.Size = UDim2.new(1, -26, 0, 13)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = tostring(description or "")
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 9
    descLabel.TextColor3 = COLORS.Muted
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = button

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

    connect(button.MouseButton1Click, function()
        if callback then
            callback()
        end
    end)

    local control = {
        Instance = button,
    }

    function control:Destroy()
        button:Destroy()
    end

    table.insert(self.Buttons, control)
    return control
end

function TpzUI:SetLogText(text)
    if self.LogBox then
        self.LogBox:Set(text)
    end
end

function TpzUI:AddLog(text)
    if self.LogBox then
        self.LogBox:Append(text)
    end
end

function TpzUI:CreateLogBox(tabName)
    if self.LogBox then
        return self.LogBox
    end

    self.LogBox = self:CreateTextArea(
        "Live Logs",
        "Logs, statistics, status information...",
        "",
        tabName or "Main"
    )

    return self.LogBox
end

function TpzUI:Minimize()
    if self.Destroyed or self.Minimized then
        return
    end

    self.Minimized = true

    tween(self.Window, 0.22, {
        Size = UDim2.new(0, self.Width, 0, 68),
    }):Play()

    task.delay(0.22, function()
        if self.Destroyed or not self.Minimized then
            return
        end

        self.Window.Visible = false
        self.FloatingButton.Visible = true
    end)
end

function TpzUI:Restore()
    if self.Destroyed or not self.Minimized then
        return
    end

    self.Minimized = false
    self.FloatingButton.Visible = false
    self.Window.Visible = true
    self.Window.Size = UDim2.new(0, self.Width, 0, 68)

    tween(self.Window, 0.22, {
        Size = UDim2.new(0, self.Width, 0, self.Height),
    }):Play()
end

function TpzUI:SetVisible(visible)
    if self.Destroyed then
        return
    end

    if visible then
        self.Window.Visible = true
        self.FloatingButton.Visible = false
        self.Minimized = false
    else
        self.Window.Visible = false
        self.FloatingButton.Visible = true
        self.Minimized = true
    end
end

function TpzUI:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true

    for _, connection in ipairs(self.Connections) do
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end

    self.Connections = {}
    self.Notifications = {}

    if self.Gui then
        self.Gui:Destroy()
    end
end

return TpzUI
