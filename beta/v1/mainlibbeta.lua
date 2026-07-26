local InvokerLib = {}
InvokerLib.__index = InvokerLib

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local Theme = {
    Background   = Color3.fromRGB(13, 11, 20),
    Sidebar      = Color3.fromRGB(18, 16, 28),
    Panel        = Color3.fromRGB(26, 23, 38),
    Element      = Color3.fromRGB(34, 30, 48),
    ElementHover = Color3.fromRGB(45, 40, 64),
    Accent       = Color3.fromRGB(139, 92, 246),
    AccentDark   = Color3.fromRGB(109, 40, 217),
    AccentGlow   = Color3.fromRGB(167, 139, 250),
    AccentSoft   = Color3.fromRGB(59, 44, 110),
    Text         = Color3.fromRGB(237, 233, 254),
    TextDark     = Color3.fromRGB(139, 122, 180),
    Divider      = Color3.fromRGB(30, 26, 46),
    Success      = Color3.fromRGB(74, 222, 128),
    Warning      = Color3.fromRGB(251, 191, 36),
    Error        = Color3.fromRGB(248, 113, 113),
    Border       = Color3.fromRGB(45, 36, 80),
}

local Ease = {
    Spring  = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Smooth  = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Snap    = TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Elastic = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    Bounce  = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Shrink  = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
}

local _ThemeRefs = {}

local function Create(instanceType, properties)
    local instance = Instance.new(instanceType)
    for prop, value in pairs(properties) do
        if prop ~= "Parent" then
            instance[prop] = value
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

local function Tween(obj, props, tweenInfo)
    local t = TweenService:Create(obj, tweenInfo or Ease.Smooth, props)
    t:Play()
    return t
end

local function AddCorner(parent, radius)
    return Create("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = parent })
end

local function AddStroke(parent, color, thickness)
    return Create("UIStroke", { Color = color or Theme.Border, Thickness = thickness or 1, Parent = parent })
end

local function AddPadding(parent, padding)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, padding), PaddingBottom = UDim.new(0, padding),
        PaddingLeft = UDim.new(0, padding), PaddingRight = UDim.new(0, padding),
        Parent = parent
    })
end

local function TrackTheme(instance, property, themeKey)
    table.insert(_ThemeRefs, { instance, property, themeKey })
end

local function MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle = handle or frame
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function CreateRipple(parent)
    parent.ClipsDescendants = true
    parent.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local x = input.Position.X - parent.AbsolutePosition.X
            local y = input.Position.Y - parent.AbsolutePosition.Y
            local ripple = Create("Frame", {
                Name = "Ripple", AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Theme.AccentGlow, BackgroundTransparency = 0.4,
                Position = UDim2.new(0, x, 0, y), Size = UDim2.new(0, 0, 0, 0),
                Parent = parent
            })
            AddCorner(ripple, 999)
            local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
            Tween(ripple, { Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1 }, Ease.Smooth)
            task.delay(0.4, function() ripple:Destroy() end)
        end
    end)
end

local TooltipGui = nil
local TooltipFrame = nil
local TooltipLabel = nil

local function InitTooltip()
    if TooltipGui then return end
    TooltipGui = Create("ScreenGui", { Name = "InvokerTooltip", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = game.CoreGui })
    TooltipFrame = Create("Frame", {
        Name = "Tip", BackgroundColor3 = Theme.Panel, Size = UDim2.new(0, 200, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 100, Parent = TooltipGui
    })
    AddCorner(TooltipFrame, 6)
    AddStroke(TooltipFrame, Theme.Border, 1)
    AddPadding(TooltipFrame, 8)
    TooltipLabel = Create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham, Text = "", TextColor3 = Theme.Text, TextSize = 11,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 100, Parent = TooltipFrame
    })
end

local function ShowTooltip(text)
    InitTooltip()
    TooltipLabel.Text = text
    TooltipFrame.Visible = true
    TooltipFrame.Position = UDim2.new(0, Mouse.X + 12, 0, Mouse.Y - 10)
end

local function HideTooltip()
    if TooltipFrame then TooltipFrame.Visible = false end
end

local function BindTooltip(element, description)
    if not description then return end
    element.MouseEnter:Connect(function() ShowTooltip(description) end)
    element.MouseLeave:Connect(function() HideTooltip() end)
end

local function AddElementStroke(elementFrame)
    local stroke = AddStroke(elementFrame, Theme.Border, 1)
    elementFrame.MouseEnter:Connect(function()
        Tween(stroke, { Color = Theme.Accent, Thickness = 1.5 }, Ease.Snap)
    end)
    elementFrame.MouseLeave:Connect(function()
        Tween(stroke, { Color = Theme.Border, Thickness = 1 }, Ease.Smooth)
    end)
    return stroke
end

function InvokerLib:CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "InvokerLib"
    local windowSize = config.Size or UDim2.new(0, 750, 0, 500)
    local windowIcon = config.Icon or "rbxassetid://7733960981"
    local Window = {}
    Window.Tabs = {}
    Window.CurrentTab = nil
    Window._configElements = {}

    if game.CoreGui:FindFirstChild("InvokerLib") then
        game.CoreGui:FindFirstChild("InvokerLib"):Destroy()
    end

    local ScreenGui = Create("ScreenGui", {
        Name = "InvokerLib", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = game.CoreGui
    })

    local MainFrame = Create("Frame", {
        Name = "MainFrame", AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background, Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = windowSize, Parent = ScreenGui
    })
    AddCorner(MainFrame, 8)
    AddStroke(MainFrame, Theme.Border, 1)
    TrackTheme(MainFrame, "BackgroundColor3", "Background")

    Create("ImageLabel", {
        Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 40, 1, 40),
        Image = "rbxassetid://7912134082", ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5, ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(20, 20, 280, 280), ZIndex = -1, Parent = MainFrame
    })

    local Sidebar = Create("Frame", {
        Name = "Sidebar", BackgroundColor3 = Theme.Sidebar,
        Size = UDim2.new(0, 180, 1, 0), Parent = MainFrame
    })
    AddCorner(Sidebar, 8)
    TrackTheme(Sidebar, "BackgroundColor3", "Sidebar")

    Create("Frame", {
        Name = "SidebarFix", BackgroundColor3 = Theme.Sidebar,
        Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0, 8, 1, 0),
        BorderSizePixel = 0, Parent = Sidebar
    })

    local LogoSection = Create("Frame", {
        Name = "LogoSection", BackgroundTransparency = 1, Active = true,
        Size = UDim2.new(1, 0, 0, 60), Parent = Sidebar
    })

    Create("ImageLabel", {
        Name = "LogoIcon", BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 30, 0, 30), Image = windowIcon,
        ImageColor3 = Theme.Accent, Parent = LogoSection
    })

    Create("TextLabel", {
        Name = "LogoText", BackgroundTransparency = 1,
        Position = UDim2.new(0, 55, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(1, -70, 0, 20), Font = Enum.Font.GothamBold,
        Text = windowTitle, TextColor3 = Theme.Text, TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = LogoSection
    })

    local TabContainer = Create("ScrollingFrame", {
        Name = "TabContainer", BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 70), Size = UDim2.new(1, 0, 1, -130),
        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.AccentGlow,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Sidebar
    })
    AddPadding(TabContainer, 8)
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = TabContainer })

    Create("TextLabel", {
        Name = "CategoryLabel", BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 0, 25), Font = Enum.Font.GothamMedium,
        Text = "📋 Navigation", TextColor3 = Theme.TextDark, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = TabContainer
    })

    local PlayerSection = Create("Frame", {
        Position = UDim2.new(0, 8, 1, -55), Size = UDim2.new(1, -16, 0, 44),
        BackgroundColor3 = Theme.Element, Parent = Sidebar
    })
    AddCorner(PlayerSection, 8)
    TrackTheme(PlayerSection, "BackgroundColor3", "Element")

    local AvatarImage = Create("ImageLabel", {
        Position = UDim2.new(0, 6, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 32, 0, 32),
        Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. Player.UserId .. "&width=48&height=48&format=png",
        BackgroundColor3 = Theme.AccentDark, Parent = PlayerSection
    })
    AddCorner(AvatarImage, 16)
    local avatarStroke = AddStroke(AvatarImage, Theme.AccentGlow, 1.5)
    avatarStroke.Transparency = 1

    Create("TextLabel", {
        Position = UDim2.new(0, 44, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(1, -52, 0, 30), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, Text = "Welcome back,\n" .. Player.Name,
        TextColor3 = Theme.Text, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = PlayerSection
    })

    PlayerSection.MouseEnter:Connect(function()
        Tween(AvatarImage, { ImageColor3 = Theme.AccentGlow }, Ease.Smooth)
        Tween(avatarStroke, { Transparency = 0 }, Ease.Smooth)
    end)
    PlayerSection.MouseLeave:Connect(function()
        Tween(AvatarImage, { ImageColor3 = Color3.fromRGB(255, 255, 255) }, Ease.Smooth)
        Tween(avatarStroke, { Transparency = 1 }, Ease.Smooth)
    end)

    local ContentArea = Create("Frame", {
        Name = "ContentArea", BackgroundColor3 = Theme.Panel,
        Position = UDim2.new(0, 185, 0, 5), Size = UDim2.new(1, -190, 1, -10), Parent = MainFrame
    })
    AddCorner(ContentArea, 6)
    TrackTheme(ContentArea, "BackgroundColor3", "Panel")

    local Header = Create("Frame", {
        Name = "Header", BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 50), Parent = ContentArea
    })

    local Breadcrumb = Create("TextLabel", {
        Name = "Breadcrumb", BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0.5, 0, 0, 20), Font = Enum.Font.Gotham,
        Text = "Home / Main Settings", TextColor3 = Theme.TextDark, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, RichText = true, Parent = Header
    })

    Create("Frame", {
        Name = "Divider", BackgroundColor3 = Theme.Divider,
        Position = UDim2.new(0, 10, 0, 50), Size = UDim2.new(1, -20, 0, 1),
        BorderSizePixel = 0, Parent = ContentArea
    })

    local PagesContainer = Create("Frame", {
        Name = "PagesContainer", BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 55), Size = UDim2.new(1, 0, 1, -55), Parent = ContentArea
    })

    local CloseButton = Create("TextButton", {
        Name = "CloseButton", BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(1, -40, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 25, 0, 25), Font = Enum.Font.GothamBold,
        Text = "×", TextColor3 = Theme.Text, TextSize = 18, Parent = Header
    })
    AddCorner(CloseButton, 6)
    CreateRipple(CloseButton)
    CloseButton.MouseEnter:Connect(function()
        Tween(CloseButton, { BackgroundColor3 = Color3.fromRGB(200, 60, 60) }, Ease.Snap)
    end)
    CloseButton.MouseLeave:Connect(function()
        Tween(CloseButton, { BackgroundColor3 = Theme.Accent }, Ease.Smooth)
    end)
    CloseButton.MouseButton1Click:Connect(function()
        Tween(MainFrame, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, Ease.Shrink)
        task.wait(0.25)
        ScreenGui:Destroy()
    end)

    local MinButton = Create("TextButton", {
        Name = "MinButton", BackgroundColor3 = Theme.Element,
        Position = UDim2.new(1, -70, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 25, 0, 25), Font = Enum.Font.GothamBold,
        Text = "−", TextColor3 = Theme.Text, TextSize = 18, Parent = Header
    })
    AddCorner(MinButton, 6)
    CreateRipple(MinButton)
    MinButton.MouseEnter:Connect(function()
        Tween(MinButton, { BackgroundColor3 = Theme.AccentSoft }, Ease.Snap)
    end)
    MinButton.MouseLeave:Connect(function()
        Tween(MinButton, { BackgroundColor3 = Theme.Element }, Ease.Smooth)
    end)

    local minimized = false
    MinButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(MainFrame, { Size = UDim2.new(0, 180, 0, 60) }, Ease.Smooth)
        else
            Tween(MainFrame, { Size = windowSize }, Ease.Spring)
        end
    end)

    MakeDraggable(MainFrame, LogoSection)

    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.BackgroundTransparency = 1
    Tween(MainFrame, { Size = windowSize }, Ease.Spring)
    Tween(MainFrame, { BackgroundTransparency = 0 }, Ease.Smooth)

    function Window:CreateTab(config)
        config = config or {}
        local tabName = config.Name or "Tab"
        local tabIcon = config.Icon or "⚙️"
        local Tab = {}
        Tab.SubTabs = {}
        Tab.CurrentSubTab = nil
        local sectionCount = 0

        local TabButton = Create("TextButton", {
            Name = tabName, BackgroundColor3 = Theme.AccentSoft,
            BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 35),
            Font = Enum.Font.Gotham, Text = "", Parent = TabContainer
        })
        AddCorner(TabButton, 6)

        local TabIconLabel = Create("TextLabel", {
            Name = "Icon", BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, 20, 0, 20), Font = Enum.Font.Gotham,
            Text = tabIcon, TextColor3 = Theme.TextDark, TextSize = 14, Parent = TabButton
        })

        local TabLabel = Create("TextLabel", {
            Name = "Label", BackgroundTransparency = 1,
            Position = UDim2.new(0, 38, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(1, -50, 0, 20), Font = Enum.Font.Gotham,
            Text = tabName, TextColor3 = Theme.TextDark, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = TabButton
        })

        local TabIndicator = Create("Frame", {
            Name = "Indicator", BackgroundColor3 = Theme.Accent,
            Position = UDim2.new(0, 3, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, 3, 0, 0), Parent = TabButton
        })
        AddCorner(TabIndicator, 2)

        local Badge = Create("Frame", {
            Name = "Badge", BackgroundColor3 = Theme.Accent,
            Position = UDim2.new(1, -12, 0, 4), Size = UDim2.new(0, 8, 0, 8),
            Visible = false, Parent = TabButton
        })
        AddCorner(Badge, 4)

        local TabPage = Create("ScrollingFrame", {
            Name = tabName .. "Page", BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0), Visible = false,
            ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.AccentGlow,
            CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = PagesContainer
        })
        AddPadding(TabPage, 15)
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = TabPage })

        local function SelectTab()
            for _, tab in pairs(Window.Tabs) do
                tab.Button.BackgroundTransparency = 1
                Tween(tab.Indicator, { Size = UDim2.new(0, 3, 0, 0) }, Ease.Snap)
                tab.Label.TextColor3 = Theme.TextDark
                tab.Icon.TextColor3 = Theme.TextDark
                if tab.Page.Visible then
                    Tween(tab.Page, { Position = UDim2.new(0, 20, 0, 0) }, Ease.Snap)
                    task.delay(0.14, function() tab.Page.Visible = false end)
                end
            end
            TabButton.BackgroundTransparency = 0
            TabButton.BackgroundColor3 = Theme.AccentSoft
            Tween(TabIndicator, { Size = UDim2.new(0, 3, 0.65, 0) }, Ease.Elastic)
            TabLabel.TextColor3 = Theme.Text
            TabIconLabel.TextColor3 = Theme.AccentGlow
            TabPage.Visible = true
            TabPage.Position = UDim2.new(0, -20, 0, 0)
            Tween(TabPage, { Position = UDim2.new(0, 0, 0, 0) }, Ease.Bounce)
            Window.CurrentTab = Tab

            Tween(Breadcrumb, { TextTransparency = 1 }, Ease.Snap)
            task.delay(0.1, function()
                Breadcrumb.Text = string.format('<font color="rgb(139,92,246)">%s</font> / Main Settings', tabName)
                Tween(Breadcrumb, { TextTransparency = 0 }, Ease.Smooth)
            end)
        end

        TabButton.MouseButton1Click:Connect(SelectTab)
        TabButton.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabButton, { BackgroundTransparency = 0.85 }, Ease.Snap)
                Tween(TabLabel, { TextColor3 = Theme.AccentGlow }, Ease.Snap)
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabButton, { BackgroundTransparency = 1 }, Ease.Smooth)
                Tween(TabLabel, { TextColor3 = Theme.TextDark }, Ease.Smooth)
            end
        end)

        Tab.Button = TabButton
        Tab.Label = TabLabel
        Tab.Icon = TabIconLabel
        Tab.Indicator = TabIndicator
        Tab.Page = TabPage

        function Tab:SetBadge(visible, color)
            Badge.Visible = visible
            if color then Badge.BackgroundColor3 = color end
        end

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then SelectTab() end

        function Tab:CreateSection(name)
            sectionCount = sectionCount + 1
            local localOrder = sectionCount
            local Section = {}

            local SectionFrame = Create("Frame", {
                Name = name or "Section", BackgroundColor3 = Theme.Element,
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = localOrder, Parent = TabPage
            })
            AddCorner(SectionFrame, 8)
            AddStroke(SectionFrame, Theme.Border, 1)
            TrackTheme(SectionFrame, "BackgroundColor3", "Element")

            SectionFrame.BackgroundTransparency = 1
            Tween(SectionFrame, { BackgroundTransparency = 0 }, Ease.Bounce)

            local SectionHeader = Create("Frame", {
                Name = "Header", BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 35), Parent = SectionFrame
            })

            Create("Frame", {
                BackgroundColor3 = Theme.Accent, Position = UDim2.new(0, 0, 0, 8),
                Size = UDim2.new(0, 3, 1, -16), Parent = SectionHeader
            })

            Create("TextLabel", {
                Name = "Title", BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(1, -24, 0, 20), Font = Enum.Font.GothamBold,
                Text = name or "Section", TextColor3 = Theme.Text, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = SectionHeader
            })

            local SectionContent = Create("Frame", {
                Name = "Content", BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 35), Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y, Parent = SectionFrame
            })
            AddPadding(SectionContent, 8)
            Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = SectionContent })

            Section.Frame = SectionFrame
            Section.Content = SectionContent

            function Section:CreateToggle(config)
                config = config or {}
                local toggleName = config.Name or "Toggle"
                local default = config.Default or false
                local callback = config.Callback or function() end
                local Toggle = {}
                Toggle.Value = default

                local ToggleFrame = Create("Frame", {
                    Name = toggleName, BackgroundColor3 = Theme.ElementHover,
                    Size = UDim2.new(1, 0, 0, 35), Parent = SectionContent
                })
                AddCorner(ToggleFrame, 6)
                AddElementStroke(ToggleFrame)
                BindTooltip(ToggleFrame, config.Description)

                Create("TextLabel", {
                    BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, -60, 0, 20),
                    Font = Enum.Font.Gotham, Text = toggleName, TextColor3 = Theme.Text,
                    TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = ToggleFrame
                })

                local ToggleButton = Create("Frame", {
                    Name = "Button", BackgroundColor3 = Theme.Background,
                    Position = UDim2.new(1, -45, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0, 38, 0, 20), Parent = ToggleFrame
                })
                AddCorner(ToggleButton, 10)
                local toggleStroke = AddStroke(ToggleButton, Theme.Border, 1)

                local ToggleCircle = Create("Frame", {
                    Name = "Circle", BackgroundColor3 = Theme.TextDark,
                    Position = UDim2.new(0, 3, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0, 14, 0, 14), Parent = ToggleButton
                })
                AddCorner(ToggleCircle, 7)

                local function UpdateToggle()
                    if Toggle.Value then
                        Tween(ToggleCircle, { Position = UDim2.new(1, -17, 0.5, 0), BackgroundColor3 = Theme.AccentGlow }, Ease.Elastic)
                        Tween(ToggleButton, { BackgroundColor3 = Theme.AccentSoft }, Ease.Smooth)
                        Tween(toggleStroke, { Color = Theme.Accent }, Ease.Smooth)
                    else
                        Tween(ToggleCircle, { Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = Theme.TextDark }, Ease.Bounce)
                        Tween(ToggleButton, { BackgroundColor3 = Theme.Background }, Ease.Smooth)
                        Tween(toggleStroke, { Color = Theme.Border }, Ease.Smooth)
                    end
                end

                local ClickDetector = Create("TextButton", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = ToggleFrame
                })
                ClickDetector.MouseButton1Click:Connect(function()
                    Toggle.Value = not Toggle.Value
                    UpdateToggle()
                    callback(Toggle.Value)
                end)

                if default then UpdateToggle() end

                function Toggle:Set(value)
                    Toggle.Value = value
                    UpdateToggle()
                    callback(Toggle.Value)
                end

                Window._configElements[toggleName] = {
                    Get = function() return Toggle.Value end,
                    Set = function(v) Toggle:Set(v) end
                }
                return Toggle
            end

            function Section:CreateButton(config)
                config = config or {}
                local buttonName = config.Name or "Button"
                local callback = config.Callback or function() end

                local ButtonFrame = Create("TextButton", {
                    Name = buttonName, BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new(1, 0, 0, 35), Font = Enum.Font.GothamMedium,
                    Text = buttonName, TextColor3 = Theme.Text, TextSize = 12, Parent = SectionContent
                })
                AddCorner(ButtonFrame, 6)
                CreateRipple(ButtonFrame)
                BindTooltip(ButtonFrame, config.Description)

                local grad = Instance.new("UIGradient")
                grad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 92, 246)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(99, 56, 220)),
                })
                grad.Rotation = 135
                grad.Parent = ButtonFrame

                ButtonFrame.MouseEnter:Connect(function()
                    Tween(ButtonFrame, { Size = UDim2.new(1, 0, 0, 37) }, Ease.Snap)
                end)
                ButtonFrame.MouseLeave:Connect(function()
                    Tween(ButtonFrame, { Size = UDim2.new(1, 0, 0, 35) }, Ease.Smooth)
                end)
                ButtonFrame.MouseButton1Down:Connect(function()
                    Tween(ButtonFrame, { Size = UDim2.new(1, 0, 0, 32) }, Ease.Snap)
                end)
                ButtonFrame.MouseButton1Up:Connect(function()
                    Tween(ButtonFrame, { Size = UDim2.new(1, 0, 0, 35) }, Ease.Bounce)
                end)
                ButtonFrame.MouseButton1Click:Connect(callback)
                return {}
            end

            function Section:CreateSlider(config)
                config = config or {}
                local sliderName = config.Name or "Slider"
                local min = config.Min or 0
                local max = config.Max or 100
                local step = config.Step or 1
                local suffix = config.Suffix or ""
                local default = config.Default or min
                local callback = config.Callback or function() end
                local Slider = {}
                Slider.Value = default

                local SliderFrame = Create("Frame", {
                    Name = sliderName, BackgroundColor3 = Theme.ElementHover,
                    Size = UDim2.new(1, 0, 0, 50), Parent = SectionContent
                })
                AddCorner(SliderFrame, 6)
                AddElementStroke(SliderFrame)
                BindTooltip(SliderFrame, config.Description)

                Create("TextLabel", {
                    BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5),
                    Size = UDim2.new(0.5, -10, 0, 20), Font = Enum.Font.Gotham,
                    Text = sliderName, TextColor3 = Theme.Text, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = SliderFrame
                })

                local SliderValue = Create("TextLabel", {
                    BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 5),
                    Size = UDim2.new(0.5, -10, 0, 20), Font = Enum.Font.GothamBold,
                    Text = tostring(default) .. suffix, TextColor3 = Theme.AccentGlow,
                    TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Parent = SliderFrame
                })

                local SliderBar = Create("Frame", {
                    Name = "Bar", BackgroundColor3 = Theme.Background,
                    Position = UDim2.new(0, 10, 0, 30), Size = UDim2.new(1, -20, 0, 8), Parent = SliderFrame
                })
                AddCorner(SliderBar, 4)

                local SliderFill = Create("Frame", {
                    Name = "Fill", BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new((default - min) / (max - min), 0, 1, 0), Parent = SliderBar
                })
                AddCorner(SliderFill, 4)

                local SliderDot = Create("Frame", {
                    Name = "Dot", BackgroundColor3 = Theme.Text,
                    Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
                    Size = UDim2.new(0, 14, 0, 14), Parent = SliderFill
                })
                AddCorner(SliderDot, 7)

                local dragging = false
                local function UpdateSlider(input)
                    local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                    local raw = min + (max - min) * pos
                    Slider.Value = math.floor(raw / step + 0.5) * step
                    Slider.Value = math.clamp(Slider.Value, min, max)
                    local normPos = (Slider.Value - min) / (max - min)
                    SliderValue.Text = tostring(Slider.Value) .. suffix
                    Tween(SliderFill, { Size = UDim2.new(normPos, 0, 1, 0) }, Ease.Snap)
                    callback(Slider.Value)
                end

                SliderBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        Tween(SliderDot, { Size = UDim2.new(0, 18, 0, 18) }, Ease.Bounce)
                        UpdateSlider(input)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateSlider(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                        Tween(SliderDot, { Size = UDim2.new(0, 14, 0, 14) }, Ease.Smooth)
                    end
                end)

                function Slider:Set(value)
                    Slider.Value = math.clamp(value, min, max)
                    local pos = (Slider.Value - min) / (max - min)
                    SliderValue.Text = tostring(Slider.Value) .. suffix
                    Tween(SliderFill, { Size = UDim2.new(pos, 0, 1, 0) }, Ease.Smooth)
                    callback(Slider.Value)
                end

                Window._configElements[sliderName] = {
                    Get = function() return Slider.Value end,
                    Set = function(v) Slider:Set(v) end
                }
                return Slider
            end

            function Section:CreateDropdown(config)
                config = config or {}
                local dropdownName = config.Name or "Dropdown"
                local options = config.Options or { "Option 1", "Option 2", "Option 3" }
                local multiSelect = config.MultiSelect or false
                local default = config.Default or options[1]
                local callback = config.Callback or function() end
                local Dropdown = {}
                Dropdown.Value = default
                Dropdown.Values = {}
                Dropdown.Open = false

                local DropdownFrame = Create("Frame", {
                    Name = dropdownName, BackgroundColor3 = Theme.ElementHover,
                    Size = UDim2.new(1, 0, 0, 35), ClipsDescendants = true, Parent = SectionContent
                })
                AddCorner(DropdownFrame, 6)
                AddElementStroke(DropdownFrame)
                BindTooltip(DropdownFrame, config.Description)

                Create("TextLabel", {
                    BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.5, -10, 0, 35), Font = Enum.Font.Gotham,
                    Text = dropdownName, TextColor3 = Theme.Text, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = DropdownFrame
                })

                local DropdownSelected = Create("TextLabel", {
                    BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 0),
                    Size = UDim2.new(0.5, -30, 0, 35), Font = Enum.Font.GothamMedium,
                    Text = multiSelect and "0 выбрано" or default,
                    TextColor3 = Theme.AccentGlow, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right, Parent = DropdownFrame
                })

                local DropdownArrow = Create("TextLabel", {
                    BackgroundTransparency = 1, Position = UDim2.new(1, -25, 0, 0),
                    Size = UDim2.new(0, 20, 0, 35), Font = Enum.Font.GothamBold,
                    Text = "▼", TextColor3 = Theme.TextDark, TextSize = 10, Parent = DropdownFrame
                })

                local OptionsScroll = Create("ScrollingFrame", {
                    Name = "Options", BackgroundTransparency = 1,
                    Position = UDim2.new(0, 5, 0, 40), Size = UDim2.new(1, -10, 0, math.min(#options * 30, 150)),
                    ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.AccentGlow,
                    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    Parent = DropdownFrame
                })
                Create("UIListLayout", { Padding = UDim.new(0, 2), Parent = OptionsScroll })

                local function UpdateMultiLabel()
                    DropdownSelected.Text = tostring(#Dropdown.Values) .. " выбрано"
                end

                for _, option in ipairs(options) do
                    local OptionButton = Create("TextButton", {
                        Name = option, BackgroundColor3 = Theme.Background,
                        Size = UDim2.new(1, 0, 0, 28), Font = Enum.Font.Gotham,
                        Text = multiSelect and ("  " .. option) or option,
                        TextColor3 = Theme.Text, TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left, Parent = OptionsScroll
                    })
                    AddCorner(OptionButton, 4)

                    local checkBox = nil
                    if multiSelect then
                        checkBox = Create("Frame", {
                            BackgroundColor3 = Theme.Border, Position = UDim2.new(0, 6, 0.5, 0),
                            AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 12, 0, 12), Parent = OptionButton
                        })
                        AddCorner(checkBox, 3)
                    end

                    OptionButton.MouseEnter:Connect(function()
                        Tween(OptionButton, { BackgroundColor3 = Theme.AccentSoft }, Ease.Snap)
                    end)
                    OptionButton.MouseLeave:Connect(function()
                        Tween(OptionButton, { BackgroundColor3 = Theme.Background }, Ease.Smooth)
                    end)
                    OptionButton.MouseButton1Click:Connect(function()
                        if multiSelect then
                            local idx = table.find(Dropdown.Values, option)
                            if idx then
                                table.remove(Dropdown.Values, idx)
                                if checkBox then Tween(checkBox, { BackgroundColor3 = Theme.Border }, Ease.Snap) end
                            else
                                table.insert(Dropdown.Values, option)
                                if checkBox then Tween(checkBox, { BackgroundColor3 = Theme.Accent }, Ease.Snap) end
                            end
                            UpdateMultiLabel()
                            callback(Dropdown.Values)
                        else
                            Dropdown.Value = option
                            DropdownSelected.Text = option
                            Dropdown.Open = false
                            Tween(DropdownFrame, { Size = UDim2.new(1, 0, 0, 35) }, Ease.Smooth)
                            Tween(DropdownArrow, { Rotation = 0 }, Ease.Bounce)
                            callback(option)
                        end
                    end)
                end

                local ClickDetector = Create("TextButton", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35), Text = "", Parent = DropdownFrame
                })
                ClickDetector.MouseButton1Click:Connect(function()
                    Dropdown.Open = not Dropdown.Open
                    local expandInfo = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    if Dropdown.Open then
                        local h = math.min(45 + #options * 30, 195)
                        Tween(DropdownFrame, { Size = UDim2.new(1, 0, 0, h) }, expandInfo)
                        Tween(DropdownArrow, { Rotation = 180 }, Ease.Bounce)
                    else
                        Tween(DropdownFrame, { Size = UDim2.new(1, 0, 0, 35) }, Ease.Smooth)
                        Tween(DropdownArrow, { Rotation = 0 }, Ease.Smooth)
                    end
                end)

                function Dropdown:Set(value)
                    if multiSelect and type(value) == "table" then
                        Dropdown.Values = value
                        UpdateMultiLabel()
                        callback(Dropdown.Values)
                    elseif not multiSelect and table.find(options, value) then
                        Dropdown.Value = value
                        DropdownSelected.Text = value
                        callback(value)
                    end
                end

                Window._configElements[dropdownName] = {
                    Get = function() return multiSelect and Dropdown.Values or Dropdown.Value end,
                    Set = function(v) Dropdown:Set(v) end
                }
                return Dropdown
            end

            function Section:CreateKeybind(config)
                config = config or {}
                local keybindName = config.Name or "Keybind"
                local default = config.Default or Enum.KeyCode.E
                local callback = config.Callback or function() end
                local Keybind = {}
                Keybind.Value = default
                Keybind.Listening = false

                local KeybindFrame = Create("Frame", {
                    Name = keybindName, BackgroundColor3 = Theme.ElementHover,
                    Size = UDim2.new(1, 0, 0, 35), Parent = SectionContent
                })
                AddCorner(KeybindFrame, 6)
                AddElementStroke(KeybindFrame)
                BindTooltip(KeybindFrame, config.Description)

                Create("TextLabel", {
                    BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.6, -10, 0, 20),
                    Font = Enum.Font.Gotham, Text = keybindName, TextColor3 = Theme.Text,
                    TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = KeybindFrame
                })

                local KeybindButton = Create("TextButton", {
                    Name = "Button", BackgroundColor3 = Theme.Background,
                    Position = UDim2.new(1, -70, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0, 60, 0, 25), Font = Enum.Font.GothamMedium,
                    Text = default.Name, TextColor3 = Theme.AccentGlow, TextSize = 11, Parent = KeybindFrame
                })
                AddCorner(KeybindButton, 4)
                local kbStroke = AddStroke(KeybindButton, Theme.Border, 1)

                local pulseConn = nil

                KeybindButton.MouseButton1Click:Connect(function()
                    Keybind.Listening = true
                    KeybindButton.Text = "..."
                    Tween(KeybindButton, { BackgroundColor3 = Theme.AccentDark }, Ease.Snap)
                    Tween(kbStroke, { Color = Theme.Accent }, Ease.Snap)
                    pulseConn = RunService.Heartbeat:Connect(function()
                        kbStroke.Transparency = math.abs(math.sin(tick() * 3)) * 0.5
                    end)
                end)

                UserInputService.InputBegan:Connect(function(input, processed)
                    if Keybind.Listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        Keybind.Value = input.KeyCode
                        KeybindButton.Text = input.KeyCode.Name
                        Keybind.Listening = false
                        Tween(KeybindButton, { BackgroundColor3 = Theme.Background }, Ease.Smooth)
                        Tween(kbStroke, { Color = Theme.Border, Transparency = 0 }, Ease.Smooth)
                        if pulseConn then pulseConn:Disconnect(); pulseConn = nil end
                    elseif not processed and input.KeyCode == Keybind.Value then
                        callback()
                    end
                end)

                function Keybind:Set(key)
                    Keybind.Value = key
                    KeybindButton.Text = key.Name
                end
                return Keybind
            end

            function Section:CreateTextbox(config)
                config = config or {}
                local textboxName = config.Name or "Textbox"
                local placeholder = config.Placeholder or "Enter text..."
                local callback = config.Callback or function() end
                local Textbox = {}
                Textbox.Value = ""

                local TextboxFrame = Create("Frame", {
                    Name = textboxName, BackgroundColor3 = Theme.ElementHover,
                    Size = UDim2.new(1, 0, 0, 35), Parent = SectionContent
                })
                AddCorner(TextboxFrame, 6)
                AddElementStroke(TextboxFrame)
                BindTooltip(TextboxFrame, config.Description)

                Create("TextLabel", {
                    BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.4, -10, 0, 20),
                    Font = Enum.Font.Gotham, Text = textboxName, TextColor3 = Theme.Text,
                    TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = TextboxFrame
                })

                local TextboxInput = Create("TextBox", {
                    Name = "Input", BackgroundColor3 = Theme.Background,
                    Position = UDim2.new(0.4, 5, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0.6, -15, 0, 25), Font = Enum.Font.Gotham,
                    PlaceholderText = placeholder, PlaceholderColor3 = Theme.TextDark,
                    Text = "", TextColor3 = Theme.Text, TextSize = 11,
                    ClearTextOnFocus = false, Parent = TextboxFrame
                })
                AddCorner(TextboxInput, 4)
                local inputStroke = AddStroke(TextboxInput, Theme.Border, 1)

                TextboxInput.Focused:Connect(function()
                    Tween(inputStroke, { Color = Theme.Accent, Thickness = 1.5 }, Ease.Snap)
                end)
                TextboxInput.FocusLost:Connect(function(enterPressed)
                    Tween(inputStroke, { Color = Theme.Border, Thickness = 1 }, Ease.Smooth)
                    Textbox.Value = TextboxInput.Text
                    callback(TextboxInput.Text, enterPressed)
                end)

                function Textbox:Set(value)
                    Textbox.Value = value
                    TextboxInput.Text = value
                end

                Window._configElements[textboxName] = {
                    Get = function() return Textbox.Value end,
                    Set = function(v) Textbox:Set(v) end
                }
                return Textbox
            end

            function Section:CreateLabel(text)
                local LabelFrame = Create("TextLabel", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 25),
                    Font = Enum.Font.Gotham, Text = text or "Label",
                    TextColor3 = Theme.TextDark, TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = SectionContent
                })
                local Label = {}
                function Label:Set(newText) LabelFrame.Text = newText end
                return Label
            end

            function Section:CreateParagraph(config)
                config = config or {}
                local ParagraphFrame = Create("Frame", {
                    BackgroundColor3 = Theme.Background, Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y, Parent = SectionContent
                })
                AddCorner(ParagraphFrame, 6)
                AddPadding(ParagraphFrame, 10)
                Create("UIListLayout", { Padding = UDim.new(0, 5), Parent = ParagraphFrame })

                local ParagraphTitle = Create("TextLabel", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18),
                    Font = Enum.Font.GothamBold, Text = config.Title or "Title",
                    TextColor3 = Theme.Accent, TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = ParagraphFrame
                })
                local ParagraphContent = Create("TextLabel", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.Gotham,
                    Text = config.Content or "Content", TextColor3 = Theme.Text, TextSize = 11,
                    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = ParagraphFrame
                })
                local Paragraph = {}
                function Paragraph:Set(cfg)
                    ParagraphTitle.Text = cfg.Title or ParagraphTitle.Text
                    ParagraphContent.Text = cfg.Content or ParagraphContent.Text
                end
                return Paragraph
            end

            function Section:CreateColorPicker(config)
                config = config or {}
                local pickerName = config.Name or "ColorPicker"
                local default = config.Default or Color3.fromRGB(139, 92, 246)
                local callback = config.Callback or function() end
                local ColorPicker = {}
                ColorPicker.Value = default

                local PickerFrame = Create("Frame", {
                    Name = pickerName, BackgroundColor3 = Theme.ElementHover,
                    Size = UDim2.new(1, 0, 0, 90), Parent = SectionContent
                })
                AddCorner(PickerFrame, 6)
                AddElementStroke(PickerFrame)

                Create("TextLabel", {
                    BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 4),
                    Size = UDim2.new(0.6, 0, 0, 18), Font = Enum.Font.Gotham,
                    Text = pickerName, TextColor3 = Theme.Text, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = PickerFrame
                })

                local Preview = Create("Frame", {
                    BackgroundColor3 = default, Position = UDim2.new(1, -40, 0, 6),
                    Size = UDim2.new(0, 30, 0, 30), Parent = PickerFrame
                })
                AddCorner(Preview, 6)
                AddStroke(Preview, Theme.Border, 1)

                local channels = { "R", "G", "B" }
                local values = { default.R * 255, default.G * 255, default.B * 255 }
                local fills = {}

                for i, ch in ipairs(channels) do
                    local yOff = 24 + (i - 1) * 22
                    Create("TextLabel", {
                        BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, yOff),
                        Size = UDim2.new(0, 14, 0, 16), Font = Enum.Font.GothamBold,
                        Text = ch, TextColor3 = Theme.TextDark, TextSize = 10, Parent = PickerFrame
                    })
                    local bar = Create("Frame", {
                        BackgroundColor3 = Theme.Background, Position = UDim2.new(0, 28, 0, yOff + 3),
                        Size = UDim2.new(1, -80, 0, 8), Parent = PickerFrame
                    })
                    AddCorner(bar, 4)
                    local fill = Create("Frame", {
                        BackgroundColor3 = Theme.Accent, Size = UDim2.new(values[i] / 255, 0, 1, 0), Parent = bar
                    })
                    AddCorner(fill, 4)
                    fills[i] = fill

                    local valLabel = Create("TextLabel", {
                        BackgroundTransparency = 1, Position = UDim2.new(1, -48, 0, yOff),
                        Size = UDim2.new(0, 30, 0, 16), Font = Enum.Font.Gotham,
                        Text = tostring(math.floor(values[i])), TextColor3 = Theme.Text,
                        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, Parent = PickerFrame
                    })

                    local dragging = false
                    bar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = true
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                            local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                            values[i] = math.floor(pos * 255)
                            valLabel.Text = tostring(values[i])
                            Tween(fill, { Size = UDim2.new(pos, 0, 1, 0) }, Ease.Snap)
                            local c = Color3.fromRGB(values[1], values[2], values[3])
                            ColorPicker.Value = c
                            Preview.BackgroundColor3 = c
                            callback(c)
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                    end)
                end

                function ColorPicker:Set(color)
                    values = { color.R * 255, color.G * 255, color.B * 255 }
                    for i = 1, 3 do
                        Tween(fills[i], { Size = UDim2.new(values[i] / 255, 0, 1, 0) }, Ease.Smooth)
                    end
                    ColorPicker.Value = color
                    Preview.BackgroundColor3 = color
                    callback(color)
                end
                return ColorPicker
            end

            function Section:CreateDivider(label)
                local DividerFrame = Create("Frame", {
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Parent = SectionContent
                })
                if label then
                    Create("Frame", {
                        BackgroundColor3 = Theme.Divider, Position = UDim2.new(0, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.35, -5, 0, 1),
                        BorderSizePixel = 0, Parent = DividerFrame
                    })
                    Create("Frame", {
                        BackgroundColor3 = Theme.Divider, Position = UDim2.new(0.65, 5, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.35, -5, 0, 1),
                        BorderSizePixel = 0, Parent = DividerFrame
                    })
                    Create("TextLabel", {
                        BackgroundColor3 = Theme.Element, Position = UDim2.new(0.5, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0.3, 0, 0, 16),
                        Font = Enum.Font.Gotham, Text = label, TextColor3 = Theme.TextDark,
                        TextSize = 10, Parent = DividerFrame
                    })
                else
                    Create("Frame", {
                        BackgroundColor3 = Theme.Divider, Position = UDim2.new(0, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, 0, 0, 1),
                        BorderSizePixel = 0, Parent = DividerFrame
                    })
                end
            end

            function Section:CreateProgressBar(config)
                config = config or {}
                local barName = config.Name or "Progress"
                local max = config.Max or 100
                local value = config.Value or 0
                local suffix = config.Suffix or ""
                local ProgressBar = {}
                ProgressBar.Value = value

                local ProgressFrame = Create("Frame", {
                    Name = barName, BackgroundColor3 = Theme.ElementHover,
                    Size = UDim2.new(1, 0, 0, 40), Parent = SectionContent
                })
                AddCorner(ProgressFrame, 6)

                Create("TextLabel", {
                    BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 4),
                    Size = UDim2.new(0.5, 0, 0, 16), Font = Enum.Font.Gotham,
                    Text = barName, TextColor3 = Theme.Text, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = ProgressFrame
                })

                local ProgressLabel = Create("TextLabel", {
                    BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 4),
                    Size = UDim2.new(0.5, -10, 0, 16), Font = Enum.Font.GothamBold,
                    Text = tostring(value) .. " / " .. tostring(max) .. " " .. suffix,
                    TextColor3 = Theme.AccentGlow, TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right, Parent = ProgressFrame
                })

                local Bar = Create("Frame", {
                    BackgroundColor3 = Theme.Background, Position = UDim2.new(0, 10, 0, 24),
                    Size = UDim2.new(1, -20, 0, 8), Parent = ProgressFrame
                })
                AddCorner(Bar, 4)

                local Fill = Create("Frame", {
                    BackgroundColor3 = Theme.Accent, Size = UDim2.new(math.clamp(value / max, 0, 1), 0, 1, 0), Parent = Bar
                })
                AddCorner(Fill, 4)

                function ProgressBar:Set(newVal)
                    ProgressBar.Value = math.clamp(newVal, 0, max)
                    ProgressLabel.Text = tostring(ProgressBar.Value) .. " / " .. tostring(max) .. " " .. suffix
                    Tween(Fill, { Size = UDim2.new(math.clamp(ProgressBar.Value / max, 0, 1), 0, 1, 0) }, Ease.Smooth)
                end
                return ProgressBar
            end

            return Section
        end
        return Tab
    end

    function Window:Notify(config)
        config = config or {}
        local title = config.Title or "Notification"
        local content = config.Content or ""
        local duration = config.Duration or 3
        local notifType = config.Type or "Info"

        local typeColors = {
            Info = Theme.Accent, Success = Theme.Success,
            Warning = Theme.Warning, Error = Theme.Error
        }
        local icons = { Info = "ℹ", Success = "✓", Warning = "⚠", Error = "✕" }

        local NotifContainer = ScreenGui:FindFirstChild("NotifContainer")
        if not NotifContainer then
            NotifContainer = Create("Frame", {
                Name = "NotifContainer", BackgroundTransparency = 1,
                Position = UDim2.new(1, -10, 0, 10), AnchorPoint = Vector2.new(1, 0),
                Size = UDim2.new(0, 280, 1, -20), Parent = ScreenGui
            })
            Create("UIListLayout", {
                Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Top, Parent = NotifContainer
            })
        end

        local NotifFrame = Create("Frame", {
            Name = "Notification", BackgroundColor3 = Theme.Panel,
            Size = UDim2.new(1, 0, 0, 70), ClipsDescendants = true, Parent = NotifContainer
        })
        AddCorner(NotifFrame, 8)
        AddStroke(NotifFrame, typeColors[notifType], 1)

        Create("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, -8),
            AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 16, 0, 16),
            Font = Enum.Font.GothamBold, Text = icons[notifType],
            TextColor3 = typeColors[notifType], TextSize = 14, Parent = NotifFrame
        })

        Create("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 32, 0, 10),
            Size = UDim2.new(1, -40, 0, 20), Font = Enum.Font.GothamBold,
            Text = title, TextColor3 = typeColors[notifType], TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = NotifFrame
        })

        Create("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 32, 0, 32),
            Size = UDim2.new(1, -40, 0, 30), Font = Enum.Font.Gotham,
            Text = content, TextColor3 = Theme.Text, TextSize = 11,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top, Parent = NotifFrame
        })

        local NotifProgress = Create("Frame", {
            BackgroundColor3 = typeColors[notifType], Position = UDim2.new(0, 0, 1, -3),
            Size = UDim2.new(1, 0, 0, 3), BorderSizePixel = 0, Parent = NotifFrame
        })

        NotifFrame.Position = UDim2.new(1, 60, 0, 0)
        Tween(NotifFrame, { Position = UDim2.new(0, 0, 0, 0) }, Ease.Spring)
        Tween(NotifProgress, { Size = UDim2.new(0, 0, 0, 3) }, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In))

        task.delay(duration, function()
            Tween(NotifFrame, { Position = UDim2.new(1, 30, 0, 0), BackgroundTransparency = 0.8 }, Ease.Shrink)
            task.wait(0.25)
            NotifFrame:Destroy()
        end)
    end

    function Window:Confirm(config)
        config = config or {}
        local title = config.Title or "Confirm"
        local message = config.Message or "Are you sure?"
        local onConfirm = config.OnConfirm or function() end
        local onCancel = config.OnCancel or function() end

        local Overlay = Create("Frame", {
            Name = "ConfirmOverlay", BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.5, Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 50, Parent = ScreenGui
        })

        local Card = Create("Frame", {
            Name = "Card", BackgroundColor3 = Theme.Panel,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 0, 0), ZIndex = 51, Parent = Overlay
        })
        AddCorner(Card, 10)
        AddStroke(Card, Theme.Border, 1)

        Create("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 15),
            Size = UDim2.new(1, -40, 0, 22), Font = Enum.Font.GothamBold,
            Text = title, TextColor3 = Theme.Text, TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 51, Parent = Card
        })

        Create("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 42),
            Size = UDim2.new(1, -40, 0, 40), Font = Enum.Font.Gotham,
            Text = message, TextColor3 = Theme.TextDark, TextSize = 12,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 51, Parent = Card
        })

        local ConfirmBtn = Create("TextButton", {
            BackgroundColor3 = Theme.Accent, Position = UDim2.new(0, 20, 1, -45),
            Size = UDim2.new(0.5, -30, 0, 32), Font = Enum.Font.GothamMedium,
            Text = "Подтвердить", TextColor3 = Theme.Text, TextSize = 12, ZIndex = 51, Parent = Card
        })
        AddCorner(ConfirmBtn, 6)

        local CancelBtn = Create("TextButton", {
            BackgroundColor3 = Theme.Element, Position = UDim2.new(0.5, 10, 1, -45),
            Size = UDim2.new(0.5, -30, 0, 32), Font = Enum.Font.GothamMedium,
            Text = "Отмена", TextColor3 = Theme.Text, TextSize = 12, ZIndex = 51, Parent = Card
        })
        AddCorner(CancelBtn, 6)

        Tween(Card, { Size = UDim2.new(0, 320, 0, 150) }, Ease.Spring)
        Tween(Overlay, { BackgroundTransparency = 0.5 }, Ease.Smooth)

        local function Close()
            Tween(Card, { Size = UDim2.new(0, 0, 0, 0) }, Ease.Shrink)
            Tween(Overlay, { BackgroundTransparency = 1 }, Ease.Shrink)
            task.wait(0.25)
            Overlay:Destroy()
        end

        ConfirmBtn.MouseButton1Click:Connect(function() Close(); onConfirm() end)
        CancelBtn.MouseButton1Click:Connect(function() Close(); onCancel() end)
    end

    function Window:SaveConfig(name)
        local data = {}
        for key, element in pairs(Window._configElements) do
            data[key] = element.Get()
        end
        local json = HttpService:JSONEncode(data)
        writefile("invoker_" .. name .. ".cfg", json)
    end

    function Window:LoadConfig(name)
        local file = "invoker_" .. name .. ".cfg"
        if not isfile(file) then return end
        local json = readfile(file)
        local data = HttpService:JSONDecode(json)
        for key, value in pairs(data) do
            local element = Window._configElements[key]
            if element then element.Set(value) end
        end
    end

    local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == toggleKey then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    return Window
end

function InvokerLib:SetTheme(customTheme)
    for key, value in pairs(customTheme) do
        if Theme[key] then Theme[key] = value end
    end
    for _, ref in ipairs(_ThemeRefs) do
        local inst, prop, themeKey = ref[1], ref[2], ref[3]
        if Theme[themeKey] and inst and inst.Parent then
            inst[prop] = Theme[themeKey]
        end
    end
end

return InvokerLib
