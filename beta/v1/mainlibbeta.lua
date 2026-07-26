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
    Background   = Color3.fromRGB(0, 0, 0),
    Sidebar      = Color3.fromRGB(0, 0, 0),
    Panel        = Color3.fromRGB(8, 4, 16),
    Element      = Color3.fromRGB(14, 8, 26),
    ElementHover = Color3.fromRGB(22, 12, 40),
    Accent       = Color3.fromRGB(191, 0, 255),
    AccentBright = Color3.fromRGB(216, 0, 255),
    AccentDeep   = Color3.fromRGB(160, 32, 240),
    AccentDark   = Color3.fromRGB(120, 20, 200),
    AccentGlow   = Color3.fromRGB(224, 102, 255),
    AccentSoft   = Color3.fromRGB(38, 10, 64),
    Text         = Color3.fromRGB(255, 255, 255),
    TextDark     = Color3.fromRGB(138, 123, 168),
    TextMuted    = Color3.fromRGB(90, 77, 112),
    Divider      = Color3.fromRGB(26, 15, 46),
    Success      = Color3.fromRGB(57, 255, 140),
    Warning      = Color3.fromRGB(255, 200, 60),
    Error        = Color3.fromRGB(255, 60, 120),
    Border       = Color3.fromRGB(42, 24, 69),
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
        if prop ~= "Parent" then instance[prop] = value end
    end
    if properties.Parent then instance.Parent = properties.Parent end
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
        PaddingLeft = UDim.new(0, padding), PaddingRight = UDim.new(0, padding), Parent = parent
    })
end

local function TrackTheme(instance, property, themeKey)
    table.insert(_ThemeRefs, { instance, property, themeKey })
end

local function AddGlow(parent, color, pad, transp)
    local g = Create("Frame", {
        Name = "Glow", BackgroundColor3 = color or Theme.Accent,
        BackgroundTransparency = transp or 0.82,
        Position = UDim2.new(0, -pad, 0, -pad), Size = UDim2.new(1, pad * 2, 1, pad * 2),
        ZIndex = 0, Parent = parent
    })
    AddCorner(g, 14)
    return g
end

local function NeonText(label, c1, c2)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c1 or Theme.AccentBright),
        ColorSequenceKeypoint.new(1, c2 or Theme.AccentDeep),
    })
    g.Parent = label
    return g
end

local function MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle = handle or frame
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
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
                BackgroundColor3 = Theme.AccentGlow, BackgroundTransparency = 0.35,
                Position = UDim2.new(0, x, 0, y), Size = UDim2.new(0, 0, 0, 0), Parent = parent
            })
            AddCorner(ripple, 999)
            local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
            Tween(ripple, { Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1 }, Ease.Smooth)
            task.delay(0.4, function() ripple:Destroy() end)
        end
    end)
end

local TooltipGui, TooltipFrame, TooltipLabel = nil, nil, nil
local function InitTooltip()
    if TooltipGui then return end
    TooltipGui = Create("ScreenGui", { Name = "InvokerTooltip", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = game.CoreGui })
    TooltipFrame = Create("Frame", {
        Name = "Tip", BackgroundColor3 = Theme.Element, Size = UDim2.new(0, 200, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 100, Parent = TooltipGui
    })
    AddCorner(TooltipFrame, 6); AddStroke(TooltipFrame, Theme.AccentDeep, 1); AddPadding(TooltipFrame, 8)
    TooltipLabel = Create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham, Text = "", TextColor3 = Theme.Text, TextSize = 11,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 100, Parent = TooltipFrame
    })
end
local function ShowTooltip(text)
    InitTooltip(); TooltipLabel.Text = text; TooltipFrame.Visible = true
    TooltipFrame.Position = UDim2.new(0, Mouse.X + 12, 0, Mouse.Y - 10)
end
local function HideTooltip() if TooltipFrame then TooltipFrame.Visible = false end end
local function BindTooltip(element, description)
    if not description then return end
    element.MouseEnter:Connect(function() ShowTooltip(description) end)
    element.MouseLeave:Connect(function() HideTooltip() end)
end

local function AddElementStroke(elementFrame)
    local stroke = AddStroke(elementFrame, Theme.Border, 1)
    elementFrame.MouseEnter:Connect(function() Tween(stroke, { Color = Theme.Accent, Thickness = 1.5 }, Ease.Snap) end)
    elementFrame.MouseLeave:Connect(function() Tween(stroke, { Color = Theme.Border, Thickness = 1 }, Ease.Smooth) end)
    return stroke
end

function InvokerLib:CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "InvokerLib"
    local windowSub = config.Subtitle or "v1.1 Beta Public Release"
    local windowSize = config.Size or UDim2.new(0, 760, 0, 510)
    local Window = {}
    Window.Tabs = {}
    Window.CurrentTab = nil
    Window._configElements = {}

    if game.CoreGui:FindFirstChild("InvokerLib") then game.CoreGui:FindFirstChild("InvokerLib"):Destroy() end

    local ScreenGui = Create("ScreenGui", { Name = "InvokerLib", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = game.CoreGui })

    local MainFrame = Create("Frame", {
        Name = "MainFrame", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Background,
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = windowSize, ClipsDescendants = true, Parent = ScreenGui
    })
    AddCorner(MainFrame, 10); AddStroke(MainFrame, Theme.AccentDeep, 1)
    TrackTheme(MainFrame, "BackgroundColor3", "Background")

    local ambientA = Create("Frame", { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.93, Position = UDim2.new(0, -120, 0, -140), Size = UDim2.new(0, 360, 0, 360), ZIndex = 0, Active = false, Parent = MainFrame })
    AddCorner(ambientA, 180)
    local ambientB = Create("Frame", { BackgroundColor3 = Theme.AccentDeep, BackgroundTransparency = 0.94, Position = UDim2.new(1, -200, 1, -220), Size = UDim2.new(0, 420, 0, 420), ZIndex = 0, Active = false, Parent = MainFrame })
    AddCorner(ambientB, 210)
    local function PulseBlob(blob, a, b, dur)
        local tw = Tween(blob, { BackgroundTransparency = b }, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
        tw.Completed:Connect(function() if blob.Parent then PulseBlob(blob, b, a, dur) end end)
    end
    PulseBlob(ambientA, 0.93, 0.86, 4.5)
    PulseBlob(ambientB, 0.94, 0.88, 6.0)

    Create("ImageLabel", {
        Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 40, 1, 40),
        Image = "rbxassetid://7912134082", ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.4, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(20, 20, 280, 280), ZIndex = -1, Parent = MainFrame
    })

    local Sidebar = Create("Frame", { Name = "Sidebar", BackgroundColor3 = Theme.Sidebar, Size = UDim2.new(0, 180, 1, 0), ZIndex = 1, Parent = MainFrame })
    AddCorner(Sidebar, 10); TrackTheme(Sidebar, "BackgroundColor3", "Sidebar")
    Create("Frame", { Name = "SidebarFix", BackgroundColor3 = Theme.Sidebar, Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0, 10, 1, 0), BorderSizePixel = 0, Parent = Sidebar })

    local seamGlow = Create("Frame", { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.85, Position = UDim2.new(0, 178, 0, 0), Size = UDim2.new(0, 5, 1, 0), ZIndex = 2, Parent = MainFrame })
    local seam = Create("Frame", { BackgroundColor3 = Theme.AccentBright, Position = UDim2.new(0, 180, 0, 0), Size = UDim2.new(0, 1, 1, 0), ZIndex = 2, Parent = MainFrame })
    for _, f in ipairs({ seamGlow, seam }) do
        local g = Instance.new("UIGradient")
        g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) })
        g.Rotation = 90; g.Parent = f
    end

    local LogoSection = Create("Frame", { Name = "LogoSection", BackgroundTransparency = 1, Active = true, Size = UDim2.new(1, 0, 0, 64), Parent = Sidebar })

    local LogoText = Create("TextLabel", {
        Name = "LogoText", BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 12),
        Size = UDim2.new(1, -28, 0, 24), Font = Enum.Font.GothamBlack, Text = windowTitle,
        TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left, Parent = LogoSection
    })
    NeonText(LogoText, Theme.AccentBright, Theme.AccentDeep)

    Create("TextLabel", {
        Name = "LogoSub", BackgroundTransparency = 1, Position = UDim2.new(0, 17, 0, 37),
        Size = UDim2.new(1, -28, 0, 14), Font = Enum.Font.GothamMedium, Text = windowSub,
        TextColor3 = Theme.TextMuted, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, Parent = LogoSection
    })

    local TabContainer = Create("ScrollingFrame", {
        Name = "TabContainer", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 72),
        Size = UDim2.new(1, 0, 1, -132), ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.AccentGlow,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = Sidebar
    })
    AddPadding(TabContainer, 8)
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), Parent = TabContainer })

    Create("TextLabel", {
        Name = "CategoryLabel", BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 22),
        Font = Enum.Font.GothamMedium, Text = "NAVIGATION", TextColor3 = Theme.TextMuted, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = TabContainer
    })

    local PlayerSection = Create("Frame", { Position = UDim2.new(0, 8, 1, -55), Size = UDim2.new(1, -16, 0, 44), BackgroundColor3 = Theme.Element, ZIndex = 1, Parent = Sidebar })
    AddCorner(PlayerSection, 8); AddStroke(PlayerSection, Theme.Border, 1); TrackTheme(PlayerSection, "BackgroundColor3", "Element")

    local AvatarImage = Create("ImageLabel", {
        Position = UDim2.new(0, 6, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 32, 0, 32),
        Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. Player.UserId .. "&width=48&height=48&format=png",
        BackgroundColor3 = Theme.AccentDark, Parent = PlayerSection
    })
    AddCorner(AvatarImage, 16)
    local avatarStroke = AddStroke(AvatarImage, Theme.AccentGlow, 1.5); avatarStroke.Transparency = 1

    Create("TextLabel", {
        Position = UDim2.new(0, 44, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, -52, 0, 30),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = "Welcome back,\n" .. Player.Name,
        TextColor3 = Theme.Text, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = PlayerSection
    })
    PlayerSection.MouseEnter:Connect(function() Tween(AvatarImage, { ImageColor3 = Theme.AccentGlow }, Ease.Smooth); Tween(avatarStroke, { Transparency = 0 }, Ease.Smooth) end)
    PlayerSection.MouseLeave:Connect(function() Tween(AvatarImage, { ImageColor3 = Color3.fromRGB(255, 255, 255) }, Ease.Smooth); Tween(avatarStroke, { Transparency = 1 }, Ease.Smooth) end)

    local ContentArea = Create("Frame", { Name = "ContentArea", BackgroundColor3 = Theme.Panel, Position = UDim2.new(0, 185, 0, 5), Size = UDim2.new(1, -190, 1, -10), ZIndex = 1, Parent = MainFrame })
    AddCorner(ContentArea, 8); TrackTheme(ContentArea, "BackgroundColor3", "Panel")

    local Header = Create("Frame", { Name = "Header", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50), Parent = ContentArea })
    local Breadcrumb = Create("TextLabel", {
        Name = "Breadcrumb", BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0.6, 0, 0, 20), Font = Enum.Font.Gotham, Text = "Home / Main Settings",
        TextColor3 = Theme.TextDark, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, RichText = true, Parent = Header
    })

    local headerLine = Create("Frame", { BackgroundColor3 = Theme.AccentDeep, Position = UDim2.new(0, 12, 0, 50), Size = UDim2.new(1, -24, 0, 1), BorderSizePixel = 0, Parent = ContentArea })
    local hg = Instance.new("UIGradient")
    hg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 1) })
    hg.Parent = headerLine

    local PagesContainer = Create("Frame", { Name = "PagesContainer", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 55), Size = UDim2.new(1, 0, 1, -55), Parent = ContentArea })

    local CloseButton = Create("TextButton", {
        Name = "CloseButton", BackgroundColor3 = Theme.Element, Position = UDim2.new(1, -40, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 26, 0, 26), Font = Enum.Font.GothamBold, Text = "×", TextColor3 = Theme.Text, TextSize = 18, Parent = Header
    })
    AddCorner(CloseButton, 7); AddStroke(CloseButton, Theme.Border, 1); CreateRipple(CloseButton)
    CloseButton.MouseEnter:Connect(function() Tween(CloseButton, { BackgroundColor3 = Theme.Error }, Ease.Snap) end)
    CloseButton.MouseLeave:Connect(function() Tween(CloseButton, { BackgroundColor3 = Theme.Element }, Ease.Smooth) end)
    CloseButton.MouseButton1Click:Connect(function()
        Tween(MainFrame, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, Ease.Shrink)
        task.wait(0.25); ScreenGui:Destroy()
    end)

    local MinButton = Create("TextButton", {
        Name = "MinButton", BackgroundColor3 = Theme.Element, Position = UDim2.new(1, -72, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 26, 0, 26), Font = Enum.Font.GothamBold, Text = "−", TextColor3 = Theme.Text, TextSize = 18, Parent = Header
    })
    AddCorner(MinButton, 7); AddStroke(MinButton, Theme.Border, 1); CreateRipple(MinButton)
    MinButton.MouseEnter:Connect(function() Tween(MinButton, { BackgroundColor3 = Theme.AccentSoft }, Ease.Snap) end)
    MinButton.MouseLeave:Connect(function() Tween(MinButton, { BackgroundColor3 = Theme.Element }, Ease.Smooth) end)

    local minimized = false
    MinButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            PlayerSection.Visible = false
            Tween(MainFrame, { Size = UDim2.new(0, 180, 0, 64) }, Ease.Smooth)
        else
            Tween(MainFrame, { Size = windowSize }, Ease.Spring)
            task.delay(0.15, function() if not minimized then PlayerSection.Visible = true end end)
        end
    end)

    MakeDraggable(MainFrame, LogoSection)

    MainFrame.Size = UDim2.new(0, 0, 0, 0); MainFrame.BackgroundTransparency = 1
    Tween(MainFrame, { Size = windowSize }, Ease.Spring)
    Tween(MainFrame, { BackgroundTransparency = 0 }, Ease.Smooth)

    function Window:CreateTab(config)
        config = config or {}
        local tabName = config.Name or "Tab"
        local Tab = {}
        Tab.SubTabs = {}; Tab.CurrentSubTab = nil
        local sectionCount = 0

        local TabButton = Create("TextButton", {
            Name = tabName, BackgroundColor3 = Theme.AccentSoft, BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 0, 34), Font = Enum.Font.Gotham, Text = "", Parent = TabContainer
        })
        AddCorner(TabButton, 7)

        local TabLabel = Create("TextLabel", {
            Name = "Label", BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(1, -28, 0, 20), Font = Enum.Font.GothamMedium, Text = tabName,
            TextColor3 = Theme.TextDark, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = TabButton
        })

        local TabIndicator = Create("Frame", {
            Name = "Indicator", BackgroundColor3 = Theme.AccentBright, Position = UDim2.new(0, 3, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 3, 0, 0), Parent = TabButton
        })
        AddCorner(TabIndicator, 2)
        local indGlow = AddGlow(TabIndicator, Theme.Accent, 4, 1)

        local Badge = Create("Frame", { Name = "Badge", BackgroundColor3 = Theme.AccentBright, Position = UDim2.new(1, -12, 0, 5), Size = UDim2.new(0, 8, 0, 8), Visible = false, Parent = TabButton })
        AddCorner(Badge, 4)

        local TabPage = Create("ScrollingFrame", {
            Name = tabName .. "Page", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false,
            ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.AccentGlow, CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = PagesContainer
        })
        AddPadding(TabPage, 15)
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = TabPage })

        local function SelectTab()
            if Window.CurrentTab == Tab then return end
            local function ShowNew()
                for _, tab in pairs(Window.Tabs) do
                    tab.Button.BackgroundTransparency = 1
                    Tween(tab.Indicator, { Size = UDim2.new(0, 3, 0, 0) }, Ease.Snap)
                    if tab.IndGlow then Tween(tab.IndGlow, { BackgroundTransparency = 1 }, Ease.Snap) end
                    tab.Label.TextColor3 = Theme.TextDark
                    tab.Page.Visible = false
                end
                TabButton.BackgroundTransparency = 0; TabButton.BackgroundColor3 = Theme.AccentSoft
                Tween(TabIndicator, { Size = UDim2.new(0, 3, 0.7, 0) }, Ease.Elastic)
                Tween(indGlow, { BackgroundTransparency = 0.6 }, Ease.Smooth)
                TabLabel.TextColor3 = Theme.Text
                TabPage.Visible = true; TabPage.Position = UDim2.new(0, -20, 0, 0)
                Tween(TabPage, { Position = UDim2.new(0, 0, 0, 0) }, Ease.Bounce)
                Window.CurrentTab = Tab
                Tween(Breadcrumb, { TextTransparency = 1 }, Ease.Snap)
                task.delay(0.1, function()
                    Breadcrumb.Text = string.format('<font color="rgb(216,0,255)">%s</font> <font color="rgb(90,77,112)">/ Main Settings</font>', tabName)
                    Tween(Breadcrumb, { TextTransparency = 0 }, Ease.Smooth)
                end)
            end
            local previous = Window.CurrentTab
            if previous and previous.Page and previous.Page.Visible then
                local fade = Create("Frame", { Name = "TabFade", BackgroundColor3 = Theme.Background, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 50, Parent = previous.Page })
                local ft = Tween(fade, { BackgroundTransparency = 0 }, Ease.Smooth)
                ft.Completed:Connect(function() if previous.Page then previous.Page.Visible = false end fade:Destroy(); ShowNew() end)
            else
                ShowNew()
            end
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

        Tab.Button = TabButton; Tab.Label = TabLabel; Tab.Indicator = TabIndicator; Tab.IndGlow = indGlow; Tab.Page = TabPage
        function Tab:SetBadge(visible, color) Badge.Visible = visible; if color then Badge.BackgroundColor3 = color end end
        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then SelectTab() end

        function Tab:CreateSection(name)
            sectionCount = sectionCount + 1
            local localOrder = sectionCount
            local Section = {}

            local SectionFrame = Create("Frame", {
                Name = name or "Section", BackgroundColor3 = Theme.Element, Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = localOrder, Parent = TabPage
            })
            AddCorner(SectionFrame, 9); AddStroke(SectionFrame, Theme.Border, 1); TrackTheme(SectionFrame, "BackgroundColor3", "Element")
            SectionFrame.BackgroundTransparency = 1
            Tween(SectionFrame, { BackgroundTransparency = 0 }, Ease.Bounce)

            local SectionHeader = Create("Frame", { Name = "Header", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), Parent = SectionFrame })
            local accentLine = Create("Frame", { BackgroundColor3 = Theme.AccentBright, Position = UDim2.new(0, 0, 0, 9), Size = UDim2.new(0, 3, 1, -18), Parent = SectionHeader })
            AddCorner(accentLine, 2)
            AddGlow(accentLine, Theme.Accent, 3, 0.55)
            Create("TextLabel", {
                Name = "Title", BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(1, -26, 0, 20), Font = Enum.Font.GothamBold, Text = (name or "Section"):upper(),
                TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = SectionHeader
            })

            local SectionContent = Create("Frame", { Name = "Content", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 36), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = SectionFrame })
            AddPadding(SectionContent, 9)
            Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 7), Parent = SectionContent })
            Section.Frame = SectionFrame; Section.Content = SectionContent

            function Section:CreateToggle(config)
                config = config or {}
                local toggleName = config.Name or "Toggle"
                local default = config.Default or false
                local callback = config.Callback or function() end
                local Toggle = {}; Toggle.Value = default

                local ToggleFrame = Create("Frame", { Name = toggleName, BackgroundColor3 = Theme.ElementHover, Size = UDim2.new(1, 0, 0, 36), Parent = SectionContent })
                AddCorner(ToggleFrame, 7); AddElementStroke(ToggleFrame); BindTooltip(ToggleFrame, config.Description)
                Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, -62, 0, 20), Font = Enum.Font.Gotham, Text = toggleName, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = ToggleFrame })

                local ToggleButton = Create("Frame", { Name = "Button", BackgroundColor3 = Theme.Background, Position = UDim2.new(1, -46, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 38, 0, 20), Parent = ToggleFrame })
                AddCorner(ToggleButton, 10)
                local toggleStroke = AddStroke(ToggleButton, Theme.Border, 1)
                local toggleGlow = AddGlow(ToggleButton, Theme.Accent, 5, 1)
                local ToggleCircle = Create("Frame", { Name = "Circle", BackgroundColor3 = Theme.TextDark, Position = UDim2.new(0, 3, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 14, 0, 14), Parent = ToggleButton })
                AddCorner(ToggleCircle, 7)

                local function UpdateToggle()
                    if Toggle.Value then
                        Tween(ToggleCircle, { Position = UDim2.new(1, -17, 0.5, 0), BackgroundColor3 = Theme.AccentGlow }, Ease.Elastic)
                        Tween(ToggleButton, { BackgroundColor3 = Theme.AccentSoft }, Ease.Smooth)
                        Tween(toggleStroke, { Color = Theme.Accent }, Ease.Smooth)
                        Tween(toggleGlow, { BackgroundTransparency = 0.65 }, Ease.Smooth)
                    else
                        Tween(ToggleCircle, { Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = Theme.TextDark }, Ease.Bounce)
                        Tween(ToggleButton, { BackgroundColor3 = Theme.Background }, Ease.Smooth)
                        Tween(toggleStroke, { Color = Theme.Border }, Ease.Smooth)
                        Tween(toggleGlow, { BackgroundTransparency = 1 }, Ease.Smooth)
                    end
                end
                local ClickDetector = Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = ToggleFrame })
                ClickDetector.MouseButton1Click:Connect(function() Toggle.Value = not Toggle.Value; UpdateToggle(); callback(Toggle.Value) end)
                if default then UpdateToggle() end
                function Toggle:Set(value) Toggle.Value = value; UpdateToggle(); callback(Toggle.Value) end
                Window._configElements[toggleName] = { Get = function() return Toggle.Value end, Set = function(v) Toggle:Set(v) end }
                return Toggle
            end

            function Section:CreateButton(config)
                config = config or {}
                local buttonName = config.Name or "Button"
                local callback = config.Callback or function() end
                local ButtonFrame = Create("TextButton", { Name = buttonName, BackgroundColor3 = Theme.Accent, Size = UDim2.new(1, 0, 0, 36), Font = Enum.Font.GothamMedium, Text = buttonName, TextColor3 = Theme.Text, TextSize = 12, Parent = SectionContent })
                AddCorner(ButtonFrame, 7); AddStroke(ButtonFrame, Theme.AccentDeep, 1); CreateRipple(ButtonFrame); BindTooltip(ButtonFrame, config.Description)
                local grad = Instance.new("UIGradient")
                grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.AccentBright), ColorSequenceKeypoint.new(1, Theme.AccentDeep) })
                grad.Rotation = 135; grad.Parent = ButtonFrame
                local topHi = Create("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.82, Size = UDim2.new(1, -4, 0, 1), Position = UDim2.new(0, 2, 0, 1), Parent = ButtonFrame })
                AddCorner(topHi, 1)
                local sheen = Create("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0, Size = UDim2.new(1, 0, 1, 0), ZIndex = 0, Parent = ButtonFrame })
                local sg = Instance.new("UIGradient")
                sg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 1), NumberSequenceKeypoint.new(0.5, 0.82), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 1) })
                sg.Rotation = 20; sg.Offset = Vector2.new(-0.7, 0); sg.Parent = sheen
                ButtonFrame.MouseEnter:Connect(function() Tween(ButtonFrame, { Size = UDim2.new(1, 0, 0, 38) }, Ease.Snap); Tween(sg, { Offset = Vector2.new(0.7, 0) }, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)) end)
                ButtonFrame.MouseLeave:Connect(function() Tween(ButtonFrame, { Size = UDim2.new(1, 0, 0, 36) }, Ease.Smooth); Tween(sg, { Offset = Vector2.new(-0.7, 0) }, Ease.Smooth) end)
                ButtonFrame.MouseButton1Down:Connect(function() Tween(ButtonFrame, { Size = UDim2.new(1, 0, 0, 33) }, Ease.Snap) end)
                ButtonFrame.MouseButton1Up:Connect(function() Tween(ButtonFrame, { Size = UDim2.new(1, 0, 0, 36) }, Ease.Bounce) end)
                ButtonFrame.MouseButton1Click:Connect(callback)
                return {}
            end

            function Section:CreateSlider(config)
                config = config or {}
                local sliderName = config.Name or "Slider"
                local min = config.Min or 0; local max = config.Max or 100; local step = config.Step or 1
                local suffix = config.Suffix or ""; local default = config.Default or min
                local callback = config.Callback or function() end
                local Slider = {}; Slider.Value = default

                local SliderFrame = Create("Frame", { Name = sliderName, BackgroundColor3 = Theme.ElementHover, Size = UDim2.new(1, 0, 0, 52), Parent = SectionContent })
                AddCorner(SliderFrame, 7); AddElementStroke(SliderFrame); BindTooltip(SliderFrame, config.Description)
                Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(0.5, -12, 0, 20), Font = Enum.Font.Gotham, Text = sliderName, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = SliderFrame })
                local SliderValue = Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.new(0.5, -12, 0, 20), Font = Enum.Font.GothamBold, Text = tostring(default) .. suffix, TextColor3 = Theme.AccentGlow, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Parent = SliderFrame })
                local SliderBar = Create("Frame", { Name = "Bar", BackgroundColor3 = Theme.Background, Position = UDim2.new(0, 12, 0, 32), Size = UDim2.new(1, -24, 0, 8), Parent = SliderFrame })
                AddCorner(SliderBar, 4)
                local SliderFill = Create("Frame", { Name = "Fill", BackgroundColor3 = Theme.Accent, Size = UDim2.new((default - min) / (max - min), 0, 1, 0), Parent = SliderBar })
                AddCorner(SliderFill, 4)
                local fg = Instance.new("UIGradient"); fg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.AccentDeep), ColorSequenceKeypoint.new(1, Theme.AccentBright) }); fg.Parent = SliderFill
                local SliderDot = Create("Frame", { Name = "Dot", BackgroundColor3 = Theme.Text, Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 14, 0, 14), Parent = SliderFill })
                AddCorner(SliderDot, 7); AddStroke(SliderDot, Theme.Accent, 1.5); AddGlow(SliderDot, Theme.AccentGlow, 4, 0.5)

                local dragging = false
                local function UpdateSlider(input)
                    local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                    local raw = min + (max - min) * pos
                    Slider.Value = math.clamp(math.floor(raw / step + 0.5) * step, min, max)
                    local normPos = (Slider.Value - min) / (max - min)
                    SliderValue.Text = tostring(Slider.Value) .. suffix
                    Tween(SliderFill, { Size = UDim2.new(normPos, 0, 1, 0) }, Ease.Snap); callback(Slider.Value)
                end
                SliderBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; Tween(SliderDot, { Size = UDim2.new(0, 18, 0, 18) }, Ease.Bounce); UpdateSlider(input) end end)
                UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then UpdateSlider(input) end end)
                UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false; Tween(SliderDot, { Size = UDim2.new(0, 14, 0, 14) }, Ease.Smooth) end end)
                function Slider:Set(value)
                    Slider.Value = math.clamp(value, min, max); local pos = (Slider.Value - min) / (max - min)
                    SliderValue.Text = tostring(Slider.Value) .. suffix; Tween(SliderFill, { Size = UDim2.new(pos, 0, 1, 0) }, Ease.Smooth); callback(Slider.Value)
                end
                Window._configElements[sliderName] = { Get = function() return Slider.Value end, Set = function(v) Slider:Set(v) end }
                return Slider
            end

            function Section:CreateDropdown(config)
                config = config or {}
                local dropdownName = config.Name or "Dropdown"
                local options = config.Options or { "Option 1", "Option 2", "Option 3" }
                local multiSelect = config.MultiSelect or false
                local default = config.Default or options[1]
                local callback = config.Callback or function() end
                local Dropdown = {}; Dropdown.Value = default; Dropdown.Values = {}; Dropdown.Open = false

                local DropdownFrame = Create("Frame", { Name = dropdownName, BackgroundColor3 = Theme.ElementHover, Size = UDim2.new(1, 0, 0, 36), ClipsDescendants = true, Parent = SectionContent })
                AddCorner(DropdownFrame, 7); AddElementStroke(DropdownFrame); BindTooltip(DropdownFrame, config.Description)
                Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.5, -12, 0, 36), Font = Enum.Font.Gotham, Text = dropdownName, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = DropdownFrame })
                local DropdownSelected = Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -30, 0, 36), Font = Enum.Font.GothamMedium, Text = multiSelect and "0 выбрано" or default, TextColor3 = Theme.AccentGlow, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Parent = DropdownFrame })
                local DropdownArrow = Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -25, 0, 0), Size = UDim2.new(0, 20, 0, 36), Font = Enum.Font.GothamBold, Text = "▼", TextColor3 = Theme.TextDark, TextSize = 10, Parent = DropdownFrame })

                local OptionsScroll = Create("ScrollingFrame", { Name = "Options", BackgroundTransparency = 1, Position = UDim2.new(0, 5, 0, 41), Size = UDim2.new(1, -10, 0, math.min(#options * 30, 150)), ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.AccentGlow, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = DropdownFrame })
                Create("UIListLayout", { Padding = UDim.new(0, 2), Parent = OptionsScroll })
                local function UpdateMultiLabel() DropdownSelected.Text = tostring(#Dropdown.Values) .. " выбрано" end

                for _, option in ipairs(options) do
                    local OptionButton = Create("TextButton", { Name = option, BackgroundColor3 = Theme.Background, Size = UDim2.new(1, 0, 0, 28), Font = Enum.Font.Gotham, Text = "", TextColor3 = Theme.Text, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = OptionsScroll })
                    AddCorner(OptionButton, 4)
                    local checkBox = nil
                    if multiSelect then
                        checkBox = Create("Frame", { BackgroundColor3 = Theme.Border, Position = UDim2.new(0, 8, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 12, 0, 12), Parent = OptionButton })
                        AddCorner(checkBox, 3)
                    end
                    Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, multiSelect and 26 or 12, 0, 0), Size = UDim2.new(1, multiSelect and -30 or -16, 1, 0), Font = Enum.Font.Gotham, Text = option, TextColor3 = Theme.Text, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = OptionButton })
                    OptionButton.MouseEnter:Connect(function() Tween(OptionButton, { BackgroundColor3 = Theme.AccentSoft }, Ease.Snap) end)
                    OptionButton.MouseLeave:Connect(function() Tween(OptionButton, { BackgroundColor3 = Theme.Background }, Ease.Smooth) end)
                    OptionButton.MouseButton1Click:Connect(function()
                        if multiSelect then
                            local idx = table.find(Dropdown.Values, option)
                            if idx then table.remove(Dropdown.Values, idx); if checkBox then Tween(checkBox, { BackgroundColor3 = Theme.Border }, Ease.Snap) end
                            else table.insert(Dropdown.Values, option); if checkBox then Tween(checkBox, { BackgroundColor3 = Theme.Accent }, Ease.Snap) end end
                            UpdateMultiLabel(); callback(Dropdown.Values)
                        else
                            Dropdown.Value = option; DropdownSelected.Text = option; Dropdown.Open = false
                            Tween(DropdownFrame, { Size = UDim2.new(1, 0, 0, 36) }, Ease.Smooth); Tween(DropdownArrow, { Rotation = 0 }, Ease.Bounce); callback(option)
                        end
                    end)
                end
                local ClickDetector = Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36), Text = "", Parent = DropdownFrame })
                ClickDetector.MouseButton1Click:Connect(function()
                    Dropdown.Open = not Dropdown.Open
                    if Dropdown.Open then Tween(DropdownFrame, { Size = UDim2.new(1, 0, 0, math.min(46 + #options * 30, 196)) }, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)); Tween(DropdownArrow, { Rotation = 180 }, Ease.Bounce)
                    else Tween(DropdownFrame, { Size = UDim2.new(1, 0, 0, 36) }, Ease.Smooth); Tween(DropdownArrow, { Rotation = 0 }, Ease.Smooth) end
                end)
                function Dropdown:Set(value)
                    if multiSelect and type(value) == "table" then Dropdown.Values = value; UpdateMultiLabel(); callback(Dropdown.Values)
                    elseif not multiSelect and table.find(options, value) then Dropdown.Value = value; DropdownSelected.Text = value; callback(value) end
                end
                Window._configElements[dropdownName] = { Get = function() return multiSelect and Dropdown.Values or Dropdown.Value end, Set = function(v) Dropdown:Set(v) end }
                return Dropdown
            end

            function Section:CreateKeybind(config)
                config = config or {}
                local keybindName = config.Name or "Keybind"; local default = config.Default or Enum.KeyCode.E
                local callback = config.Callback or function() end
                local Keybind = {}; Keybind.Value = default; Keybind.Listening = false
                local KeybindFrame = Create("Frame", { Name = keybindName, BackgroundColor3 = Theme.ElementHover, Size = UDim2.new(1, 0, 0, 36), Parent = SectionContent })
                AddCorner(KeybindFrame, 7); AddElementStroke(KeybindFrame); BindTooltip(KeybindFrame, config.Description)
                Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.6, -12, 0, 20), Font = Enum.Font.Gotham, Text = keybindName, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = KeybindFrame })
                local KeybindButton = Create("TextButton", { Name = "Button", BackgroundColor3 = Theme.Background, Position = UDim2.new(1, -72, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 62, 0, 25), Font = Enum.Font.GothamMedium, Text = default.Name, TextColor3 = Theme.AccentGlow, TextSize = 11, Parent = KeybindFrame })
                AddCorner(KeybindButton, 5); local kbStroke = AddStroke(KeybindButton, Theme.Border, 1)
                local pulseConn = nil
                KeybindButton.MouseButton1Click:Connect(function()
                    Keybind.Listening = true; KeybindButton.Text = "..."
                    Tween(KeybindButton, { BackgroundColor3 = Theme.AccentDark }, Ease.Snap); Tween(kbStroke, { Color = Theme.Accent }, Ease.Snap)
                    pulseConn = RunService.Heartbeat:Connect(function() kbStroke.Transparency = math.abs(math.sin(tick() * 3)) * 0.5 end)
                end)
                UserInputService.InputBegan:Connect(function(input, processed)
                    if Keybind.Listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        Keybind.Value = input.KeyCode; KeybindButton.Text = input.KeyCode.Name; Keybind.Listening = false
                        Tween(KeybindButton, { BackgroundColor3 = Theme.Background }, Ease.Smooth); Tween(kbStroke, { Color = Theme.Border, Transparency = 0 }, Ease.Smooth)
                        if pulseConn then pulseConn:Disconnect(); pulseConn = nil end
                    elseif not processed and input.KeyCode == Keybind.Value then callback() end
                end)
                function Keybind:Set(key) Keybind.Value = key; KeybindButton.Text = key.Name end
                return Keybind
            end

            function Section:CreateTextbox(config)
                config = config or {}
                local textboxName = config.Name or "Textbox"; local placeholder = config.Placeholder or "Enter text..."
                local callback = config.Callback or function() end
                local Textbox = {}; Textbox.Value = ""
                local TextboxFrame = Create("Frame", { Name = textboxName, BackgroundColor3 = Theme.ElementHover, Size = UDim2.new(1, 0, 0, 36), Parent = SectionContent })
                AddCorner(TextboxFrame, 7); AddElementStroke(TextboxFrame); BindTooltip(TextboxFrame, config.Description)
                Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.4, -12, 0, 20), Font = Enum.Font.Gotham, Text = textboxName, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = TextboxFrame })
                local TextboxInput = Create("TextBox", { Name = "Input", BackgroundColor3 = Theme.Background, Position = UDim2.new(0.4, 5, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.6, -15, 0, 25), Font = Enum.Font.Gotham, PlaceholderText = placeholder, PlaceholderColor3 = Theme.TextMuted, Text = "", TextColor3 = Theme.Text, TextSize = 11, ClearTextOnFocus = false, Parent = TextboxFrame })
                AddCorner(TextboxInput, 5); local inputStroke = AddStroke(TextboxInput, Theme.Border, 1)
                TextboxInput.Focused:Connect(function() Tween(inputStroke, { Color = Theme.Accent, Thickness = 1.5 }, Ease.Snap) end)
                TextboxInput.FocusLost:Connect(function(enterPressed) Tween(inputStroke, { Color = Theme.Border, Thickness = 1 }, Ease.Smooth); Textbox.Value = TextboxInput.Text; callback(TextboxInput.Text, enterPressed) end)
                function Textbox:Set(value) Textbox.Value = value; TextboxInput.Text = value end
                Window._configElements[textboxName] = { Get = function() return Textbox.Value end, Set = function(v) Textbox:Set(v) end }
                return Textbox
            end

            function Section:CreateLabel(text)
                local LabelFrame = Create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.Gotham, Text = text or "Label", TextColor3 = Theme.TextDark, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = SectionContent })
                local Label = {}; function Label:Set(t) LabelFrame.Text = t end; return Label
            end

            function Section:CreateParagraph(config)
                config = config or {}
                local ParagraphFrame = Create("Frame", { BackgroundColor3 = Theme.Background, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = SectionContent })
                AddCorner(ParagraphFrame, 7); AddStroke(ParagraphFrame, Theme.AccentDeep, 1); AddPadding(ParagraphFrame, 11)
                Create("UIListLayout", { Padding = UDim.new(0, 5), Parent = ParagraphFrame })
                local ParagraphTitle = Create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, Text = config.Title or "Title", TextColor3 = Theme.AccentGlow, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = ParagraphFrame })
                local ParagraphContent = Create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.Gotham, Text = config.Content or "Content", TextColor3 = Theme.Text, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = ParagraphFrame })
                local Paragraph = {}; function Paragraph:Set(c) ParagraphTitle.Text = c.Title or ParagraphTitle.Text; ParagraphContent.Text = c.Content or ParagraphContent.Text end; return Paragraph
            end

            function Section:CreateColorPicker(config)
                config = config or {}
                local pickerName = config.Name or "ColorPicker"; local default = config.Default or Color3.fromRGB(191, 0, 255)
                local callback = config.Callback or function() end
                local ColorPicker = {}; ColorPicker.Value = default
                local PickerFrame = Create("Frame", { Name = pickerName, BackgroundColor3 = Theme.ElementHover, Size = UDim2.new(1, 0, 0, 102), Parent = SectionContent })
                AddCorner(PickerFrame, 7); AddElementStroke(PickerFrame)
                Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 7), Size = UDim2.new(0.6, 0, 0, 18), Font = Enum.Font.Gotham, Text = pickerName, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = PickerFrame })
                local Preview = Create("Frame", { BackgroundColor3 = default, Position = UDim2.new(1, -42, 0, 6), Size = UDim2.new(0, 30, 0, 28), Parent = PickerFrame })
                AddCorner(Preview, 7); AddStroke(Preview, Theme.AccentGlow, 1)
                local prevGlow = AddGlow(Preview, default, 6, 0.6)

                local channels = { "R", "G", "B" }; local values = { default.R * 255, default.G * 255, default.B * 255 }; local fills = {}; local valLabels = {}
                for i, ch in ipairs(channels) do
                    local yOff = 40 + (i - 1) * 20
                    Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, yOff), Size = UDim2.new(0, 14, 0, 16), Font = Enum.Font.GothamBold, Text = ch, TextColor3 = Theme.TextDark, TextSize = 10, Parent = PickerFrame })
                    local bar = Create("Frame", { BackgroundColor3 = Theme.Background, Position = UDim2.new(0, 30, 0, yOff + 3), Size = UDim2.new(1, -82, 0, 8), Parent = PickerFrame }); AddCorner(bar, 4)
                    local fill = Create("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new(values[i] / 255, 0, 1, 0), Parent = bar }); AddCorner(fill, 4); fills[i] = fill
                    local valLabel = Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -50, 0, yOff), Size = UDim2.new(0, 32, 0, 16), Font = Enum.Font.Gotham, Text = tostring(math.floor(values[i])), TextColor3 = Theme.Text, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, Parent = PickerFrame }); valLabels[i] = valLabel
                    local dragging = false
                    bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                            local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                            values[i] = math.floor(pos * 255); valLabel.Text = tostring(values[i]); Tween(fill, { Size = UDim2.new(pos, 0, 1, 0) }, Ease.Snap)
                            local c = Color3.fromRGB(values[1], values[2], values[3]); ColorPicker.Value = c; Preview.BackgroundColor3 = c; prevGlow.BackgroundColor3 = c; callback(c)
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
                end
                function ColorPicker:Set(color)
                    values = { color.R * 255, color.G * 255, color.B * 255 }
                    for i = 1, 3 do Tween(fills[i], { Size = UDim2.new(values[i] / 255, 0, 1, 0) }, Ease.Smooth); valLabels[i].Text = tostring(math.floor(values[i])) end
                    ColorPicker.Value = color; Preview.BackgroundColor3 = color; prevGlow.BackgroundColor3 = color; callback(color)
                end
                return ColorPicker
            end

            function Section:CreateDivider(label)
                local DividerFrame = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Parent = SectionContent })
                if label then
                    local ll = Create("Frame", { BackgroundColor3 = Theme.Divider, Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.35, -5, 0, 1), BorderSizePixel = 0, Parent = DividerFrame })
                    local rl = Create("Frame", { BackgroundColor3 = Theme.Divider, Position = UDim2.new(0.65, 5, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.35, -5, 0, 1), BorderSizePixel = 0, Parent = DividerFrame })
                    Create("TextLabel", { BackgroundColor3 = Theme.Element, Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0.3, 0, 0, 16), Font = Enum.Font.GothamMedium, Text = label, TextColor3 = Theme.TextMuted, TextSize = 9, Parent = DividerFrame })
                else
                    Create("Frame", { BackgroundColor3 = Theme.Divider, Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = DividerFrame })
                end
            end

            function Section:CreateProgressBar(config)
                config = config or {}
                local barName = config.Name or "Progress"; local max = config.Max or 100; local value = config.Value or 0; local suffix = config.Suffix or ""
                local ProgressBar = {}; ProgressBar.Value = value
                local ProgressFrame = Create("Frame", { Name = barName, BackgroundColor3 = Theme.ElementHover, Size = UDim2.new(1, 0, 0, 42), Parent = SectionContent }); AddCorner(ProgressFrame, 7)
                Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 5), Size = UDim2.new(0.5, 0, 0, 16), Font = Enum.Font.Gotham, Text = barName, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = ProgressFrame })
                local ProgressLabel = Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 5), Size = UDim2.new(0.5, -12, 0, 16), Font = Enum.Font.GothamBold, Text = tostring(value) .. " / " .. tostring(max) .. " " .. suffix, TextColor3 = Theme.AccentGlow, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Parent = ProgressFrame })
                local Bar = Create("Frame", { BackgroundColor3 = Theme.Background, Position = UDim2.new(0, 12, 0, 26), Size = UDim2.new(1, -24, 0, 8), Parent = ProgressFrame }); AddCorner(Bar, 4)
                local Fill = Create("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new(math.clamp(value / max, 0, 1), 0, 1, 0), Parent = Bar }); AddCorner(Fill, 4)
                local pfg = Instance.new("UIGradient"); pfg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.AccentDeep), ColorSequenceKeypoint.new(1, Theme.AccentBright) }); pfg.Parent = Fill
                function ProgressBar:Set(v) ProgressBar.Value = math.clamp(v, 0, max); ProgressLabel.Text = tostring(ProgressBar.Value) .. " / " .. tostring(max) .. " " .. suffix; Tween(Fill, { Size = UDim2.new(math.clamp(ProgressBar.Value / max, 0, 1), 0, 1, 0) }, Ease.Smooth) end
                return ProgressBar
            end

            return Section
        end
        return Tab
    end

    function Window:Notify(config)
        config = config or {}
        local title = config.Title or "Notification"; local content = config.Content or ""; local duration = config.Duration or 3; local notifType = config.Type or "Info"
        local typeColors = { Info = Theme.Accent, Success = Theme.Success, Warning = Theme.Warning, Error = Theme.Error }
        local icons = { Info = "ℹ", Success = "✓", Warning = "⚠", Error = "✕" }
        local NotifContainer = ScreenGui:FindFirstChild("NotifContainer")
        if not NotifContainer then
            NotifContainer = Create("Frame", { Name = "NotifContainer", BackgroundTransparency = 1, Position = UDim2.new(1, -10, 0, 10), AnchorPoint = Vector2.new(1, 0), Size = UDim2.new(0, 280, 1, -20), Parent = ScreenGui })
            Create("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Top, Parent = NotifContainer })
        end
        local NotifFrame = Create("Frame", { Name = "Notification", BackgroundColor3 = Theme.Element, Size = UDim2.new(1, 0, 0, 70), ClipsDescendants = true, Parent = NotifContainer })
        AddCorner(NotifFrame, 9); AddStroke(NotifFrame, typeColors[notifType], 1)
        Create("Frame", { BackgroundColor3 = typeColors[notifType], Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, 3, 1, 0), Parent = NotifFrame })
        local iconGlow = Create("Frame", { BackgroundColor3 = typeColors[notifType], BackgroundTransparency = 0.6, Position = UDim2.new(0, 8, 0.5, -12), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 24, 0, 24), ZIndex = 0, Parent = NotifFrame }); AddCorner(iconGlow, 12)
        Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0.5, -8), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 16, 0, 16), Font = Enum.Font.GothamBold, Text = icons[notifType], TextColor3 = typeColors[notifType], TextSize = 14, Parent = NotifFrame })
        Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 38, 0, 10), Size = UDim2.new(1, -46, 0, 20), Font = Enum.Font.GothamBold, Text = title, TextColor3 = typeColors[notifType], TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = NotifFrame })
        Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 38, 0, 32), Size = UDim2.new(1, -46, 0, 30), Font = Enum.Font.Gotham, Text = content, TextColor3 = Theme.Text, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = NotifFrame })
        local NotifProgress = Create("Frame", { BackgroundColor3 = typeColors[notifType], Position = UDim2.new(0, 0, 1, -3), Size = UDim2.new(1, 0, 0, 3), BorderSizePixel = 0, Parent = NotifFrame })
        NotifFrame.Position = UDim2.new(1, 60, 0, 0)
        Tween(NotifFrame, { Position = UDim2.new(0, 0, 0, 0) }, Ease.Spring)
        Tween(NotifProgress, { Size = UDim2.new(0, 0, 0, 3) }, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In))
        task.delay(duration, function() Tween(NotifFrame, { Position = UDim2.new(1, 30, 0, 0), BackgroundTransparency = 0.8 }, Ease.Shrink); task.wait(0.25); NotifFrame:Destroy() end)
    end

    function Window:Confirm(config)
        config = config or {}
        local title = config.Title or "Confirm"; local message = config.Message or "Are you sure?"
        local onConfirm = config.OnConfirm or function() end; local onCancel = config.OnCancel or function() end
        local Overlay = Create("Frame", { Name = "ConfirmOverlay", BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 50, Parent = ScreenGui })
        local Card = Create("Frame", { Name = "Card", BackgroundColor3 = Theme.Element, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 0), ZIndex = 51, Parent = Overlay })
        AddCorner(Card, 11); AddStroke(Card, Theme.AccentDeep, 1)
        Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 16), Size = UDim2.new(1, -40, 0, 22), Font = Enum.Font.GothamBold, Text = title, TextColor3 = Theme.AccentGlow, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 51, Parent = Card })
        Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 44), Size = UDim2.new(1, -40, 0, 40), Font = Enum.Font.Gotham, Text = message, TextColor3 = Theme.TextDark, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 51, Parent = Card })
        local ConfirmBtn = Create("TextButton", { BackgroundColor3 = Theme.Accent, Position = UDim2.new(0, 20, 1, -46), Size = UDim2.new(0.5, -30, 0, 32), Font = Enum.Font.GothamMedium, Text = "Подтвердить", TextColor3 = Theme.Text, TextSize = 12, ZIndex = 51, Parent = Card }); AddCorner(ConfirmBtn, 7)
        local cg = Instance.new("UIGradient"); cg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.AccentBright), ColorSequenceKeypoint.new(1, Theme.AccentDeep) }); cg.Rotation = 135; cg.Parent = ConfirmBtn
        local CancelBtn = Create("TextButton", { BackgroundColor3 = Theme.ElementHover, Position = UDim2.new(0.5, 10, 1, -46), Size = UDim2.new(0.5, -30, 0, 32), Font = Enum.Font.GothamMedium, Text = "Отмена", TextColor3 = Theme.Text, TextSize = 12, ZIndex = 51, Parent = Card }); AddCorner(CancelBtn, 7); AddStroke(CancelBtn, Theme.Border, 1)
        Tween(Card, { Size = UDim2.new(0, 330, 0, 155) }, Ease.Spring); Tween(Overlay, { BackgroundTransparency = 0.45 }, Ease.Smooth)
        local function Close() Tween(Card, { Size = UDim2.new(0, 0, 0, 0) }, Ease.Shrink); Tween(Overlay, { BackgroundTransparency = 1 }, Ease.Shrink); task.wait(0.25); Overlay:Destroy() end
        ConfirmBtn.MouseButton1Click:Connect(function() Close(); onConfirm() end)
        CancelBtn.MouseButton1Click:Connect(function() Close(); onCancel() end)
    end

    function Window:SaveConfig(name)
        local data = {}; for key, element in pairs(Window._configElements) do data[key] = element.Get() end
        writefile("invoker_" .. name .. ".cfg", HttpService:JSONEncode(data))
    end
    function Window:LoadConfig(name)
        local file = "invoker_" .. name .. ".cfg"; if not isfile(file) then return end
        local data = HttpService:JSONDecode(readfile(file))
        for key, value in pairs(data) do local element = Window._configElements[key]; if element then element.Set(value) end end
    end

    local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    UserInputService.InputBegan:Connect(function(input, processed) if not processed and input.KeyCode == toggleKey then MainFrame.Visible = not MainFrame.Visible end end)

    return Window
end

function InvokerLib:SetTheme(customTheme)
    for key, value in pairs(customTheme) do if Theme[key] then Theme[key] = value end end
    for _, ref in ipairs(_ThemeRefs) do
        local inst, prop, themeKey = ref[1], ref[2], ref[3]
        if Theme[themeKey] and inst and inst.Parent then inst[prop] = Theme[themeKey] end
    end
end

return InvokerLib
