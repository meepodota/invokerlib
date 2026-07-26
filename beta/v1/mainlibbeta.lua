local InvokerLib = {}
InvokerLib.__index = InvokerLib

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- ═══════════════════════════════════════════════════════════
--  THEME · ABSOLUTE MONOCHROME
-- ═══════════════════════════════════════════════════════════
local Theme = {
    Background   = Color3.fromRGB(18, 18, 18),  -- #121212
    Sidebar      = Color3.fromRGB(18, 18, 18),
    Panel        = Color3.fromRGB(22, 22, 22),
    Element      = Color3.fromRGB(30, 30, 30),  -- #1E1E1E
    ElementHover = Color3.fromRGB(38, 38, 38),
    Surface      = Color3.fromRGB(26, 26, 26),
    Accent       = Color3.fromRGB(255, 255, 255), -- #FFFFFF
    AccentDim    = Color3.fromRGB(161, 161, 170), -- #A1A1AA
    Invert       = Color3.fromRGB(18, 18, 18),    -- text on white
    Text         = Color3.fromRGB(245, 245, 245),
    TextDark     = Color3.fromRGB(130, 130, 138),
    TextMuted    = Color3.fromRGB(82, 82, 88),
    Hairline     = Color3.fromRGB(42, 42, 46),
    HairlineHi   = Color3.fromRGB(74, 74, 80),
    Divider      = Color3.fromRGB(38, 38, 42),
    Success      = Color3.fromRGB(245, 245, 245),
    Warning      = Color3.fromRGB(161, 161, 170),
    Error        = Color3.fromRGB(255, 255, 255),
    Border       = Color3.fromRGB(42, 42, 46),
}

local Ease = {
    Smooth = TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Snap   = TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Soft   = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.42, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
    Shrink = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
    Linear = TweenInfo.new(0.20, Enum.EasingStyle.Linear,Enum.EasingDirection.InOut),
}

local _ThemeRefs = {}

-- ═══════════════════════════════════════════════════════════
--  CORE UTILITIES
-- ═══════════════════════════════════════════════════════════
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
    return Create("UIStroke", { Color = color or Theme.Hairline, Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent })
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

-- top inset highlight — the single "light from above" cue (no blur, no blob)
local function InsetHighlight(parent, transp)
    local hi = Create("Frame", {
        Name = "InsetHi", BackgroundColor3 = Theme.Accent, BackgroundTransparency = transp or 0.88,
        Position = UDim2.new(0, 1, 0, 1), Size = UDim2.new(1, -2, 0, 1), BorderSizePixel = 0, ZIndex = 4, Parent = parent
    })
    local g = Instance.new("UIGradient")
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)
    })
    g.Parent = hi
    return hi
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

local function CreateRipple(parent, color)
    parent.ClipsDescendants = true
    parent.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local x = input.Position.X - parent.AbsolutePosition.X
            local y = input.Position.Y - parent.AbsolutePosition.Y
            local ripple = Create("Frame", {
                Name = "Ripple", AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = color or Theme.Accent, BackgroundTransparency = 0.85,
                Position = UDim2.new(0, x, 0, y), Size = UDim2.new(0, 0, 0, 0), ZIndex = 6, Parent = parent
            })
            AddCorner(ripple, 999)
            local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.2
            Tween(ripple, { Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1 }, Ease.Soft)
            task.delay(0.32, function() if ripple.Parent then ripple:Destroy() end end)
        end
    end)
end

-- hairline stroke that brightens on hover — the monochrome "alive" cue
local function AddElementStroke(elementFrame, radius)
    local stroke = AddStroke(elementFrame, Theme.Hairline, 1)
    elementFrame.MouseEnter:Connect(function() Tween(stroke, { Color = Theme.HairlineHi }, Ease.Snap) end)
    elementFrame.MouseLeave:Connect(function() Tween(stroke, { Color = Theme.Hairline }, Ease.Smooth) end)
    return stroke
end

-- ═══════════════════════════════════════════════════════════
--  TOOLTIP
-- ═══════════════════════════════════════════════════════════
local TooltipGui, TooltipFrame, TooltipLabel = nil, nil, nil
local function InitTooltip()
    if TooltipGui then return end
    TooltipGui = Create("ScreenGui", { Name = "InvokerTooltip", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = game.CoreGui })
    TooltipFrame = Create("Frame", {
        Name = "Tip", BackgroundColor3 = Theme.Surface, Size = UDim2.new(0, 220, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 100, Parent = TooltipGui
    })
    AddCorner(TooltipFrame, 6); AddStroke(TooltipFrame, Theme.HairlineHi, 1); AddPadding(TooltipFrame, 9)
    TooltipLabel = Create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham, Text = "", TextColor3 = Theme.TextDark, TextSize = 11,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 100, Parent = TooltipFrame
    })
end
local function ShowTooltip(text)
    InitTooltip(); TooltipLabel.Text = text; TooltipFrame.Visible = true
    TooltipFrame.Position = UDim2.new(0, Mouse.X + 14, 0, Mouse.Y - 8)
end
local function HideTooltip() if TooltipFrame then TooltipFrame.Visible = false end end
local function BindTooltip(element, description)
    if not description then return end
    element.MouseEnter:Connect(function() ShowTooltip(description) end)
    element.MouseLeave:Connect(function() HideTooltip() end)
end

-- ═══════════════════════════════════════════════════════════
--  WINDOW
-- ═══════════════════════════════════════════════════════════
function InvokerLib:CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "InvokerLib"
    local windowSub = config.Subtitle or "v1.1 · Beta Release"
    local windowSize = config.Size or UDim2.new(0, 780, 0, 520)
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
    AddCorner(MainFrame, 12); AddStroke(MainFrame, Theme.Hairline, 1); TrackTheme(MainFrame, "BackgroundColor3", "Background")
    InsetHighlight(MainFrame, 0.86)

    Create("ImageLabel", {
        Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 50, 1, 50),
        Image = "rbxassetid://7912134082", ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.55, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(20, 20, 280, 280), ZIndex = -1, Parent = MainFrame
    })

    -- ── Sidebar ──────────────────────────────────────────
    local Sidebar = Create("Frame", { Name = "Sidebar", BackgroundColor3 = Theme.Sidebar, Size = UDim2.new(0, 192, 1, 0), ZIndex = 1, Parent = MainFrame })
    TrackTheme(Sidebar, "BackgroundColor3", "Sidebar")
    Create("Frame", { Name = "SidebarFix", BackgroundColor3 = Theme.Sidebar, Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0, 12, 1, 0), BorderSizePixel = 0, Parent = Sidebar })
    local seam = Create("Frame", { BackgroundColor3 = Theme.Hairline, Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 1, 1, 0), BorderSizePixel = 0, ZIndex = 2, Parent = Sidebar })

    local LogoSection = Create("Frame", { Name = "LogoSection", BackgroundTransparency = 1, Active = true, Size = UDim2.new(1, 0, 0, 70), Parent = Sidebar })
    local LogoText = Create("TextLabel", {
        Name = "LogoText", BackgroundTransparency = 1, Position = UDim2.new(0, 20, 0, 18),
        Size = UDim2.new(1, -32, 0, 24), Font = Enum.Font.GothamBlack, Text = windowTitle,
        TextColor3 = Theme.Accent, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left, Parent = LogoSection
    })
    Create("TextLabel", {
        Name = "LogoSub", BackgroundTransparency = 1, Position = UDim2.new(0, 21, 0, 44),
        Size = UDim2.new(1, -32, 0, 14), Font = Enum.Font.Code, Text = windowSub,
        TextColor3 = Theme.TextMuted, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Parent = LogoSection
    })
    Create("Frame", { BackgroundColor3 = Theme.Hairline, Position = UDim2.new(0, 20, 1, -1), Size = UDim2.new(1, -40, 0, 1), BorderSizePixel = 0, Parent = LogoSection })

    local TabContainer = Create("ScrollingFrame", {
        Name = "TabContainer", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 80),
        Size = UDim2.new(1, 0, 1, -142), ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = Sidebar
    })
    AddPadding(TabContainer, 12)
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = TabContainer })

    Create("TextLabel", {
        Name = "CategoryLabel", BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 22),
        Font = Enum.Font.Code, Text = "// NAVIGATION", TextColor3 = Theme.TextMuted, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = TabContainer
    })

    -- ── Player card ──────────────────────────────────────
    local PlayerSection = Create("Frame", { Position = UDim2.new(0, 12, 1, -58), Size = UDim2.new(1, -24, 0, 46), BackgroundColor3 = Theme.Element, ZIndex = 1, Parent = Sidebar })
    AddCorner(PlayerSection, 8); AddElementStroke(PlayerSection); TrackTheme(PlayerSection, "BackgroundColor3", "Element")
    local AvatarImage = Create("ImageLabel", {
        Position = UDim2.new(0, 8, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 30, 0, 30),
        Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. Player.UserId .. "&width=48&height=48&format=png",
        BackgroundColor3 = Theme.Surface, Parent = PlayerSection
    })
    AddCorner(AvatarImage, 15)
    local avatarStroke = AddStroke(AvatarImage, Theme.HairlineHi, 1)
    Create("TextLabel", {
        Position = UDim2.new(0, 46, 0.5, -1), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, -54, 0, 30),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = "Signed in as\n" .. Player.Name,
        TextColor3 = Theme.Text, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = PlayerSection
    })
    PlayerSection.MouseEnter:Connect(function() Tween(avatarStroke, { Color = Theme.Accent }, Ease.Smooth) end)
    PlayerSection.MouseLeave:Connect(function() Tween(avatarStroke, { Color = Theme.HairlineHi }, Ease.Smooth) end)

    -- ── Content ──────────────────────────────────────────
    local ContentArea = Create("Frame", { Name = "ContentArea", BackgroundColor3 = Theme.Panel, Position = UDim2.new(0, 193, 0, 0), Size = UDim2.new(1, -193, 1, 0), ZIndex = 1, Parent = MainFrame })
    TrackTheme(ContentArea, "BackgroundColor3", "Panel")

    local Header = Create("Frame", { Name = "Header", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 54), Parent = ContentArea })
    local Breadcrumb = Create("TextLabel", {
        Name = "Breadcrumb", BackgroundTransparency = 1, Position = UDim2.new(0, 22, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0.6, 0, 0, 20), Font = Enum.Font.Gotham, Text = "Home  /  Overview",
        TextColor3 = Theme.TextDark, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, RichText = true, Parent = Header
    })

    local headerLine = Create("Frame", { BackgroundColor3 = Theme.Hairline, Position = UDim2.new(0, 22, 1, -1), Size = UDim2.new(1, -44, 0, 1), BorderSizePixel = 0, Parent = Header })

    local PagesContainer = Create("Frame", { Name = "PagesContainer", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 54), Size = UDim2.new(1, 0, 1, -54), Parent = ContentArea })

    -- window controls
    local function MakeControl(symbol, offX)
        local btn = Create("TextButton", {
            BackgroundColor3 = Theme.Surface, Position = UDim2.new(1, offX, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, 28, 0, 28), Font = Enum.Font.GothamMedium, Text = symbol,
            TextColor3 = Theme.TextDark, TextSize = 15, Parent = Header
        })
        AddCorner(btn, 7); AddStroke(btn, Theme.Hairline, 1); CreateRipple(btn, Theme.Accent)
        return btn
    end
    local CloseButton = MakeControl("×", -40)
    local MinButton = MakeControl("–", -74)

    CloseButton.MouseEnter:Connect(function() Tween(CloseButton, { BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Invert }, Ease.Snap) end)
    CloseButton.MouseLeave:Connect(function() Tween(CloseButton, { BackgroundColor3 = Theme.Surface, TextColor3 = Theme.TextDark }, Ease.Smooth) end)
    CloseButton.MouseButton1Click:Connect(function()
        Tween(MainFrame, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, Ease.Shrink)
        task.wait(0.2); ScreenGui:Destroy()
    end)
    MinButton.MouseEnter:Connect(function() Tween(MinButton, { BackgroundColor3 = Theme.ElementHover, TextColor3 = Theme.Text }, Ease.Snap) end)
    MinButton.MouseLeave:Connect(function() Tween(MinButton, { BackgroundColor3 = Theme.Surface, TextColor3 = Theme.TextDark }, Ease.Smooth) end)

    local minimized = false
    MinButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            PlayerSection.Visible = false
            Tween(MainFrame, { Size = UDim2.new(0, 192, 0, 70) }, Ease.Smooth)
        else
            Tween(MainFrame, { Size = windowSize }, Ease.Spring)
            task.delay(0.16, function() if not minimized then PlayerSection.Visible = true end end)
        end
    end)

    MakeDraggable(MainFrame, LogoSection)

    MainFrame.Size = UDim2.new(0, 0, 0, 0); MainFrame.BackgroundTransparency = 1
    Tween(MainFrame, { Size = windowSize }, Ease.Spring)
    Tween(MainFrame, { BackgroundTransparency = 0 }, Ease.Smooth)

    -- ═════════════════════════════════════════════════════
    --  TAB
    -- ═════════════════════════════════════════════════════
    function Window:CreateTab(config)
        config = config or {}
        local tabName = config.Name or "Tab"
        local Tab = {}
        Tab.SubTabs = {}; Tab.CurrentSubTab = nil
        local sectionCount = 0

        local TabButton = Create("TextButton", {
            Name = tabName, BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
            Size = UDim2.new(1, -24, 0, 34), Font = Enum.Font.Gotham, Text = "", Parent = TabContainer
        })
        AddCorner(TabButton, 7)

        local TabLabel = Create("TextLabel", {
            Name = "Label", BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(1, -28, 0, 20), Font = Enum.Font.GothamMedium, Text = tabName,
            TextColor3 = Theme.TextDark, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = TabButton
        })

        local TabIndicator = Create("Frame", {
            Name = "Indicator", BackgroundColor3 = Theme.Accent, Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 2, 0, 0), Parent = TabButton
        })
        AddCorner(TabIndicator, 1)

        local Badge = Create("Frame", { Name = "Badge", BackgroundColor3 = Theme.Accent, Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 6, 0, 6), Visible = false, Parent = TabButton })
        AddCorner(Badge, 3)

        local TabPage = Create("ScrollingFrame", {
            Name = tabName .. "Page", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false,
            ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.HairlineHi, ScrollBarImageTransparency = 0.4,
            CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = PagesContainer
        })
        AddPadding(TabPage, 20)
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 14), Parent = TabPage })

        local function SelectTab()
            if Window.CurrentTab == Tab then return end
            local function ShowNew()
                for _, tab in pairs(Window.Tabs) do
                    tab.Button.BackgroundTransparency = 1
                    Tween(tab.Indicator, { Size = UDim2.new(0, 2, 0, 0) }, Ease.Snap)
                    tab.Label.TextColor3 = Theme.TextDark
                    tab.Page.Visible = false
                end
                TabButton.BackgroundTransparency = 0.94
                Tween(TabIndicator, { Size = UDim2.new(0, 2, 0, 18) }, Ease.Soft)
                TabLabel.TextColor3 = Theme.Text
                TabPage.Visible = true; TabPage.Position = UDim2.new(0, -12, 0, 0)
                Tween(TabPage, { Position = UDim2.new(0, 0, 0, 0) }, Ease.Soft)
                Window.CurrentTab = Tab
                Tween(Breadcrumb, { TextTransparency = 1 }, Ease.Snap)
                task.delay(0.1, function()
                    Breadcrumb.Text = string.format('<font color="rgb(245,245,245)">%s</font>  <font color="rgb(82,82,88)">/  Overview</font>', tabName)
                    Tween(Breadcrumb, { TextTransparency = 0 }, Ease.Smooth)
                end)
            end
            local previous = Window.CurrentTab
            if previous and previous.Page and previous.Page.Visible then
                local fade = Create("Frame", { Name = "TabFade", BackgroundColor3 = Theme.Panel, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 50, Parent = previous.Page })
                local ft = Tween(fade, { BackgroundTransparency = 0 }, Ease.Smooth)
                ft.Completed:Connect(function() if previous.Page then previous.Page.Visible = false end fade:Destroy(); ShowNew() end)
            else
                ShowNew()
            end
        end

        TabButton.MouseButton1Click:Connect(SelectTab)
        TabButton.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabButton, { BackgroundTransparency = 0.96 }, Ease.Snap)
                Tween(TabLabel, { TextColor3 = Theme.Text }, Ease.Snap)
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                Tween(TabButton, { BackgroundTransparency = 1 }, Ease.Smooth)
                Tween(TabLabel, { TextColor3 = Theme.TextDark }, Ease.Smooth)
            end
        end)

        Tab.Button = TabButton; Tab.Label = TabLabel; Tab.Indicator = TabIndicator; Tab.Page = TabPage
        function Tab:SetBadge(visible, color) Badge.Visible = visible; if color then Badge.BackgroundColor3 = color end end
        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then SelectTab() end

        -- ═════════════════════════════════════════════════
        --  SECTION
        -- ═════════════════════════════════════════════════
        function Tab:CreateSection(name)
            sectionCount = sectionCount + 1
            local localOrder = sectionCount
            local Section = {}

            local SectionFrame = Create("Frame", {
                Name = name or "Section", BackgroundColor3 = Theme.Element, Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = localOrder, Parent = TabPage
            })
            AddCorner(SectionFrame, 10); AddStroke(SectionFrame, Theme.Hairline, 1); TrackTheme(SectionFrame, "BackgroundColor3", "Element")
            SectionFrame.BackgroundTransparency = 1
            Tween(SectionFrame, { BackgroundTransparency = 0 }, Ease.Soft)

            local SectionHeader = Create("Frame", { Name = "Header", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = SectionFrame })
            Create("Frame", { BackgroundColor3 = Theme.Accent, Position = UDim2.new(0, 18, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 4, 0, 4), Parent = SectionHeader })
            Create("TextLabel", {
                Name = "Title", BackgroundTransparency = 1, Position = UDim2.new(0, 30, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(1, -42, 0, 20), Font = Enum.Font.GothamBold, Text = (name or "Section"):upper(),
                TextColor3 = Theme.Text, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = SectionHeader
            })

            local SectionContent = Create("Frame", { Name = "Content", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = SectionFrame })
            AddPadding(SectionContent, 12)
            Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = SectionContent })
            Section.Frame = SectionFrame; Section.Content = SectionContent

            -- ── Toggle (inverted track) ──────────────────
            function Section:CreateToggle(config)
                config = config or {}
                local toggleName = config.Name or "Toggle"
                local default = config.Default or false
                local callback = config.Callback or function() end
                local Toggle = {}; Toggle.Value = default

                local ToggleFrame = Create("Frame", { Name = toggleName, BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 40), Parent = SectionContent })
                AddCorner(ToggleFrame, 8); AddElementStroke(ToggleFrame); BindTooltip(ToggleFrame, config.Description)
                Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, -66, 0, 20), Font = Enum.Font.Gotham, Text = toggleName, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = ToggleFrame })

                local ToggleButton = Create("Frame", { Name = "Button", BackgroundColor3 = Theme.Background, Position = UDim2.new(1, -50, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 38, 0, 22), Parent = ToggleFrame })
                AddCorner(ToggleButton, 11)
                local toggleStroke = AddStroke(ToggleButton, Theme.Hairline, 1)
                local ToggleCircle = Create("Frame", { Name = "Circle", BackgroundColor3 = Theme.TextDark, Position = UDim2.new(0, 3, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 16, 0, 16), Parent = ToggleButton })
                AddCorner(ToggleCircle, 8)

                local function UpdateToggle()
                    if Toggle.Value then
                        Tween(ToggleCircle, { Position = UDim2.new(1, -19, 0.5, 0), BackgroundColor3 = Theme.Invert }, Ease.Smooth)
                        Tween(ToggleButton, { BackgroundColor3 = Theme.Accent }, Ease.Smooth)
                        Tween(toggleStroke, { Color = Theme.Accent }, Ease.Smooth)
                    else
                        Tween(ToggleCircle, { Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = Theme.TextDark }, Ease.Smooth)
                        Tween(ToggleButton, { BackgroundColor3 = Theme.Background }, Ease.Smooth)
                        Tween(toggleStroke, { Color = Theme.Hairline }, Ease.Smooth)
                    end
                end
                local ClickDetector = Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = ToggleFrame })
                ClickDetector.MouseButton1Click:Connect(function() Toggle.Value = not Toggle.Value; UpdateToggle(); callback(Toggle.Value) end)
                if default then UpdateToggle() end
                function Toggle:Set(value) Toggle.Value = value; UpdateToggle(); callback(Toggle.Value) end
                Window._configElements[toggleName] = { Get = function() return Toggle.Value end, Set = function(v) Toggle:Set(v) end }
                return Toggle
            end

            -- ── Button (quiet by default, inverted if Primary) ──
            function Section:CreateButton(config)
                config = config or {}
                local buttonName = config.Name or "Button"
                local callback = config.Callback or function() end
                local primary = config.Primary or false

                local ButtonFrame = Create("TextButton", {
                    Name = buttonName, BackgroundColor3 = primary and Theme.Accent or Theme.Surface,
                    Size = UDim2.new(1, 0, 0, 38), Font = Enum.Font.GothamMedium, Text = buttonName,
                    TextColor3 = primary and Theme.Invert or Theme.Text, TextSize = 12, Parent = SectionContent
                })
                AddCorner(ButtonFrame, 8); BindTooltip(ButtonFrame, config.Description)
                local bStroke = AddStroke(ButtonFrame, primary and Theme.Accent or Theme.Hairline, 1)
                CreateRipple(ButtonFrame, primary and Theme.Invert or Theme.Accent)

                if not primary then
                    local sheen = Create("Frame", { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 5, Parent = ButtonFrame })
                    local sg = Instance.new("UIGradient")
                    sg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.45,1), NumberSequenceKeypoint.new(0.5,0.86), NumberSequenceKeypoint.new(0.55,1), NumberSequenceKeypoint.new(1,1) })
                    sg.Rotation = 20; sg.Offset = Vector2.new(-0.8, 0); sg.Parent = sheen
                    ButtonFrame.MouseEnter:Connect(function()
                        Tween(ButtonFrame, { BackgroundColor3 = Theme.ElementHover }, Ease.Snap)
                        Tween(bStroke, { Color = Theme.HairlineHi }, Ease.Snap)
                        Tween(sg, { Offset = Vector2.new(0.8, 0) }, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
                    end)
                    ButtonFrame.MouseLeave:Connect(function()
                        Tween(ButtonFrame, { BackgroundColor3 = Theme.Surface }, Ease.Smooth)
                        Tween(bStroke, { Color = Theme.Hairline }, Ease.Smooth)
                    end)
                else
                    ButtonFrame.MouseEnter:Connect(function() Tween(ButtonFrame, { BackgroundColor3 = Theme.AccentDim }, Ease.Snap) end)
                    ButtonFrame.MouseLeave:Connect(function() Tween(ButtonFrame, { BackgroundColor3 = Theme.Accent }, Ease.Smooth) end)
                end
                ButtonFrame.MouseButton1Down:Connect(function() Tween(ButtonFrame, { Size = UDim2.new(1, -2, 0, 36) }, Ease.Snap) end)
                ButtonFrame.MouseButton1Up:Connect(function() Tween(ButtonFrame, { Size = UDim2.new(1, 0, 0, 38) }, Ease.Smooth) end)
                ButtonFrame.MouseButton1Click:Connect(callback)
                return {}
            end

            -- ── Slider (mono value, double dot) ──────────
            function Section:CreateSlider(config)
                config = config or {}
                local sliderName = config.Name or "Slider"
                local min = config.Min or 0; local max = config.Max or 100; local step = config.Step or 1
                local suffix = config.Suffix or ""; local default = config.Default or min
                local callback = config.Callback or function() end
                local Slider = {}; Slider.Value = default

                local SliderFrame = Create("Frame", { Name = sliderName, BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 56), Parent = SectionContent })
                AddCorner(SliderFrame, 8); AddElementStroke(SliderFrame); BindTooltip(SliderFrame, config.Description)
                Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 9), Size = UDim2.new(0.5, -14, 0, 18), Font = Enum.Font.Gotham, Text = sliderName, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = SliderFrame })
                local SliderValue = Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.new(0.5, -14, 0, 20), Font = Enum.Font.Code, Text = tostring(default) .. suffix, TextColor3 = Theme.Accent, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, Parent = SliderFrame })

                local SliderBar = Create("Frame", { Name = "Bar", BackgroundColor3 = Theme.Background, Position = UDim2.new(0, 14, 0, 36), Size = UDim2.new(1, -28, 0, 6), Parent = SliderFrame })
                AddCorner(SliderBar, 3)
                local SliderFill = Create("Frame", { Name = "Fill", BackgroundColor3 = Theme.Accent, Size = UDim2.new((default - min) / (max - min), 0, 1, 0), Parent = SliderBar })
                AddCorner(SliderFill, 3)
                local SliderDot = Create("Frame", { Name = "Dot", BackgroundColor3 = Theme.Accent, Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 16, 0, 16), Parent = SliderFill })
                AddCorner(SliderDot, 8); AddStroke(SliderDot, Theme.Background, 3)

                local dragging = false
                local function UpdateSlider(input)
                    local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                    local raw = min + (max - min) * pos
                    Slider.Value = math.clamp(math.floor(raw / step + 0.5) * step, min, max)
                    local normPos = (Slider.Value - min) / (max - min)
                    SliderValue.Text = tostring(Slider.Value) .. suffix
                    SliderFill.Size = UDim2.new(normPos, 0, 1, 0); callback(Slider.Value)
                end
                SliderBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; Tween(SliderDot, { Size = UDim2.new(0, 20, 0, 20) }, Ease.Smooth); UpdateSlider(input) end end)
                UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then UpdateSlider(input) end end)
                UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false; Tween(SliderDot, { Size = UDim2.new(0, 16, 0, 16) }, Ease.Smooth) end end)
                function Slider:Set(value)
                    Slider.Value = math.clamp(value, min, max); local pos = (Slider.Value - min) / (max - min)
                    SliderValue.Text = tostring(Slider.Value) .. suffix; Tween(SliderFill, { Size = UDim2.new(pos, 0, 1, 0) }, Ease.Smooth); callback(Slider.Value)
                end
                Window._configElements[sliderName] = { Get = function() return Slider.Value end, Set = function(v) Slider:Set(v) end }
                return Slider
            end

            -- ── Dropdown ─────────────────────────────────
            function Section:CreateDropdown(config)
                config = config or {}
                local dropdownName = config.Name or "Dropdown"
                local options = config.Options or { "Option 1", "Option 2", "Option 3" }
                local multiSelect = config.MultiSelect or false
                local default = config.Default or options[1]
                local callback = config.Callback or function() end
                local Dropdown = {}; Dropdown.Value = default; Dropdown.Values = {}; Dropdown.Open = false

                local DropdownFrame = Create("Frame", { Name = dropdownName, BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 40), ClipsDescendants = true, Parent = SectionContent })
                AddCorner(DropdownFrame, 8); AddElementStroke(DropdownFrame); BindTooltip(DropdownFrame, config.Description)
                Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0.5, -14, 0, 40), Font = Enum.Font.Gotham, Text = dropdownName, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = DropdownFrame })
                local DropdownSelected = Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -34, 0, 40), Font = Enum.Font.Code, Text = multiSelect and "0 selected" or tostring(default), TextColor3 = Theme.AccentDim, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Parent = DropdownFrame })
                local DropdownArrow = Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -28, 0, 0), Size = UDim2.new(0, 20, 0, 40), Font = Enum.Font.GothamBold, Text = "⌄", TextColor3 = Theme.TextDark, TextSize = 16, Parent = DropdownFrame })

                local OptionsScroll = Create("ScrollingFrame", { Name = "Options", BackgroundTransparency = 1, Position = UDim2.new(0, 6, 0, 46), Size = UDim2.new(1, -12, 0, math.min(#options * 32, 156)), ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.HairlineHi, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = DropdownFrame })
                Create("UIListLayout", { Padding = UDim.new(0, 3), Parent = OptionsScroll })
                local function UpdateMultiLabel() DropdownSelected.Text = tostring(#Dropdown.Values) .. " selected" end

                for _, option in ipairs(options) do
                    local OptionButton = Create("TextButton", { Name = option, BackgroundColor3 = Theme.Background, Size = UDim2.new(1, 0, 0, 30), Font = Enum.Font.Gotham, Text = "", TextColor3 = Theme.Text, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = OptionsScroll })
                    AddCorner(OptionButton, 5)
                    local mark = nil
                    if multiSelect then
                        mark = Create("Frame", { BackgroundColor3 = Theme.Background, Position = UDim2.new(0, 9, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 13, 0, 13), Parent = OptionButton })
                        AddCorner(mark, 3); AddStroke(mark, Theme.HairlineHi, 1)
                    else
                        mark = Create("Frame", { BackgroundColor3 = Theme.HairlineHi, Position = UDim2.new(0, 11, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 5, 0, 5), Visible = false, Parent = OptionButton })
                        AddCorner(mark, 3)
                    end
                    Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, multiSelect and 30 or 26, 0, 0), Size = UDim2.new(1, multiSelect and -36 or -32, 1, 0), Font = Enum.Font.Gotham, Text = option, TextColor3 = Theme.Text, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = OptionButton })

                    OptionButton.MouseEnter:Connect(function() Tween(OptionButton, { BackgroundColor3 = Theme.ElementHover }, Ease.Snap) end)
                    OptionButton.MouseLeave:Connect(function() Tween(OptionButton, { BackgroundColor3 = Theme.Background }, Ease.Smooth) end)
                    OptionButton.MouseButton1Click:Connect(function()
                        if multiSelect then
                            local idx = table.find(Dropdown.Values, option)
                            if idx then table.remove(Dropdown.Values, idx); if mark then Tween(mark, { BackgroundColor3 = Theme.Background }, Ease.Snap) end
                            else table.insert(Dropdown.Values, option); if mark then Tween(mark, { BackgroundColor3 = Theme.Accent }, Ease.Snap) end end
                            UpdateMultiLabel(); callback(Dropdown.Values)
                        else
                            Dropdown.Value = option; DropdownSelected.Text = tostring(option); Dropdown.Open = false
                            for _, sib in ipairs(OptionsScroll:GetChildren()) do
                                if sib:IsA("TextButton") then
                                    local m = sib:FindFirstChildOfClass("Frame")
                                    if m then m.Visible = (sib.Name == option) end
                                end
                            end
                            Tween(DropdownFrame, { Size = UDim2.new(1, 0, 0, 40) }, Ease.Smooth); Tween(DropdownArrow, { Rotation = 0 }, Ease.Smooth); callback(option)
                        end
                    end)
                end
                local ClickDetector = Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Text = "", Parent = DropdownFrame })
                ClickDetector.MouseButton1Click:Connect(function()
                    Dropdown.Open = not Dropdown.Open
                    if Dropdown.Open then Tween(DropdownFrame, { Size = UDim2.new(1, 0, 0, math.min(52 + #options * 32, 202)) }, Ease.Soft); Tween(DropdownArrow, { Rotation = 180 }, Ease.Smooth)
                    else Tween(DropdownFrame, { Size = UDim2.new(1, 0, 0, 40) }, Ease.Smooth); Tween(DropdownArrow, { Rotation = 0 }, Ease.Smooth) end
                end)
                function Dropdown:Set(value)
                    if multiSelect and type(value) == "table" then Dropdown.Values = value; UpdateMultiLabel(); callback(Dropdown.Values)
                    elseif not multiSelect and table.find(options, value) then Dropdown.Value = value; DropdownSelected.Text = tostring(value); callback(value) end
                end
                Window._configElements[dropdownName] = { Get = function() return multiSelect and Dropdown.Values or Dropdown.Value end, Set = function(v) Dropdown:Set(v) end }
                return Dropdown
            end

            -- ── Keybind (mono glyph, blinking border) ────
            function Section:CreateKeybind(config)
                config = config or {}
                local keybindName = config.Name or "Keybind"; local default = config.Default or Enum.KeyCode.E
                local callback = config.Callback or function() end
                local Keybind = {}; Keybind.Value = default; Keybind.Listening = false
                local KeybindFrame = Create("Frame", { Name = keybindName, BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 40), Parent = SectionContent })
                AddCorner(KeybindFrame, 8); AddElementStroke(KeybindFrame); BindTooltip(KeybindFrame, config.Description)
                Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.6, -14, 0, 20), Font = Enum.Font.Gotham, Text = keybindName, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = KeybindFrame })
                local KeybindButton = Create("TextButton", { Name = "Button", BackgroundColor3 = Theme.Background, Position = UDim2.new(1, -78, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 66, 0, 26), Font = Enum.Font.Code, Text = default.Name, TextColor3 = Theme.AccentDim, TextSize = 11, Parent = KeybindFrame })
                AddCorner(KeybindButton, 6); local kbStroke = AddStroke(KeybindButton, Theme.Hairline, 1)
                local pulseConn = nil
                KeybindButton.MouseButton1Click:Connect(function()
                    Keybind.Listening = true; KeybindButton.Text = "···"
                    Tween(kbStroke, { Color = Theme.Accent }, Ease.Snap)
                    pulseConn = RunService.Heartbeat:Connect(function() kbStroke.Transparency = 0.3 + math.abs(math.sin(tick() * 4)) * 0.7 end)
                end)
                UserInputService.InputBegan:Connect(function(input, processed)
                    if Keybind.Listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        Keybind.Value = input.KeyCode; KeybindButton.Text = input.KeyCode.Name; Keybind.Listening = false
                        Tween(kbStroke, { Color = Theme.Hairline, Transparency = 0 }, Ease.Smooth)
                        if pulseConn then pulseConn:Disconnect(); pulseConn = nil end
                    elseif not processed and input.KeyCode == Keybind.Value then callback() end
                end)
                function Keybind:Set(key) Keybind.Value = key; KeybindButton.Text = key.Name end
                return Keybind
            end

            -- ── Textbox ──────────────────────────────────
            function Section:CreateTextbox(config)
                config = config or {}
                local textboxName = config.Name or "Textbox"; local placeholder = config.Placeholder or "Type something…"
                local callback = config.Callback or function() end
                local Textbox = {}; Textbox.Value = ""
                local TextboxFrame = Create("Frame", { Name = textboxName, BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 40), Parent = SectionContent })
                AddCorner(TextboxFrame, 8); AddElementStroke(TextboxFrame); BindTooltip(TextboxFrame, config.Description)
                Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.4, -14, 0, 20), Font = Enum.Font.Gotham, Text = textboxName, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = TextboxFrame })
                local TextboxInput = Create("TextBox", { Name = "Input", BackgroundColor3 = Theme.Background, Position = UDim2.new(0.4, 6, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.6, -18, 0, 26), Font = Enum.Font.Gotham, PlaceholderText = placeholder, PlaceholderColor3 = Theme.TextMuted, Text = "", TextColor3 = Theme.Text, TextSize = 11, ClearTextOnFocus = false, Parent = TextboxFrame })
                AddCorner(TextboxInput, 6); local inputStroke = AddStroke(TextboxInput, Theme.Hairline, 1)
                TextboxInput.Focused:Connect(function() Tween(inputStroke, { Color = Theme.Accent }, Ease.Snap) end)
                TextboxInput.FocusLost:Connect(function(enterPressed) Tween(inputStroke, { Color = Theme.Hairline }, Ease.Smooth); Textbox.Value = TextboxInput.Text; callback(TextboxInput.Text, enterPressed) end)
                function Textbox:Set(value) Textbox.Value = value; TextboxInput.Text = value end
                Window._configElements[textboxName] = { Get = function() return Textbox.Value end, Set = function(v) Textbox:Set(v) end }
                return Textbox
            end

            -- ── Label / Paragraph ────────────────────────
            function Section:CreateLabel(text)
                local LabelFrame = Create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Font = Enum.Font.Gotham, Text = text or "Label", TextColor3 = Theme.TextDark, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = SectionContent })
                local Label = {}; function Label:Set(t) LabelFrame.Text = t end; return Label
            end

            function Section:CreateParagraph(config)
                config = config or {}
                local ParagraphFrame = Create("Frame", { BackgroundColor3 = Theme.Background, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = SectionContent })
                AddCorner(ParagraphFrame, 8); AddStroke(ParagraphFrame, Theme.Hairline, 1); AddPadding(ParagraphFrame, 13)
                Create("UIListLayout", { Padding = UDim.new(0, 6), Parent = ParagraphFrame })
                local ParagraphTitle = Create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, Text = config.Title or "Title", TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = ParagraphFrame })
                local ParagraphContent = Create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.Gotham, Text = config.Content or "Content", TextColor3 = Theme.TextDark, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = ParagraphFrame })
                local Paragraph = {}; function Paragraph:Set(c) ParagraphTitle.Text = c.Title or ParagraphTitle.Text; ParagraphContent.Text = c.Content or ParagraphContent.Text end; return Paragraph
            end

            -- ── ColorPicker (the only chromatic surface) ─
            function Section:CreateColorPicker(config)
                config = config or {}
                local pickerName = config.Name or "ColorPicker"; local default = config.Default or Color3.fromRGB(161, 161, 170)
                local callback = config.Callback or function() end
                local ColorPicker = {}; ColorPicker.Value = default
                local PickerFrame = Create("Frame", { Name = pickerName, BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 104), Parent = SectionContent })
                AddCorner(PickerFrame, 8); AddElementStroke(PickerFrame)
                Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 9), Size = UDim2.new(0.6, 0, 0, 18), Font = Enum.Font.Gotham, Text = pickerName, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = PickerFrame })
                local Preview = Create("Frame", { BackgroundColor3 = default, Position = UDim2.new(1, -46, 0, 8), Size = UDim2.new(0, 32, 0, 26), Parent = PickerFrame })
                AddCorner(Preview, 6); AddStroke(Preview, Theme.HairlineHi, 1)

                local channels = { "R", "G", "B" }; local values = { default.R * 255, default.G * 255, default.B * 255 }; local fills = {}; local valLabels = {}
                for i, ch in ipairs(channels) do
                    local yOff = 42 + (i - 1) * 20
                    Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, yOff), Size = UDim2.new(0, 14, 0, 14), Font = Enum.Font.Code, Text = ch, TextColor3 = Theme.TextMuted, TextSize = 10, Parent = PickerFrame })
                    local bar = Create("Frame", { BackgroundColor3 = Theme.Background, Position = UDim2.new(0, 32, 0, yOff + 3), Size = UDim2.new(1, -86, 0, 6), Parent = PickerFrame }); AddCorner(bar, 3)
                    local fill = Create("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new(values[i] / 255, 0, 1, 0), Parent = bar }); AddCorner(fill, 3); fills[i] = fill
                    local valLabel = Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -52, 0, yOff), Size = UDim2.new(0, 34, 0, 14), Font = Enum.Font.Code, Text = tostring(math.floor(values[i])), TextColor3 = Theme.AccentDim, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, Parent = PickerFrame }); valLabels[i] = valLabel
                    local dragging = false
                    bar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                            local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                            values[i] = math.floor(pos * 255); valLabel.Text = tostring(values[i]); fill.Size = UDim2.new(pos, 0, 1, 0)
                            local c = Color3.fromRGB(values[1], values[2], values[3]); ColorPicker.Value = c; Preview.BackgroundColor3 = c; callback(c)
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
                end
                function ColorPicker:Set(color)
                    values = { color.R * 255, color.G * 255, color.B * 255 }
                    for i = 1, 3 do Tween(fills[i], { Size = UDim2.new(values[i] / 255, 0, 1, 0) }, Ease.Smooth); valLabels[i].Text = tostring(math.floor(values[i])) end
                    ColorPicker.Value = color; Preview.BackgroundColor3 = color; callback(color)
                end
                return ColorPicker
            end

            -- ── Divider ──────────────────────────────────
            function Section:CreateDivider(label)
                local DividerFrame = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Parent = SectionContent })
                if label then
                    Create("Frame", { BackgroundColor3 = Theme.Divider, Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.38, -6, 0, 1), BorderSizePixel = 0, Parent = DividerFrame })
                    Create("Frame", { BackgroundColor3 = Theme.Divider, Position = UDim2.new(0.62, 6, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0.38, -6, 0, 1), BorderSizePixel = 0, Parent = DividerFrame })
                    Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0.24, 0, 0, 14), Font = Enum.Font.Code, Text = label:upper(), TextColor3 = Theme.TextMuted, TextSize = 9, Parent = DividerFrame })
                else
                    Create("Frame", { BackgroundColor3 = Theme.Divider, Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = DividerFrame })
                end
            end

            -- ── ProgressBar ──────────────────────────────
            function Section:CreateProgressBar(config)
                config = config or {}
                local barName = config.Name or "Progress"; local max = config.Max or 100; local value = config.Value or 0; local suffix = config.Suffix or ""
                local ProgressBar = {}; ProgressBar.Value = value
                local ProgressFrame = Create("Frame", { Name = barName, BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 46), Parent = SectionContent }); AddCorner(ProgressFrame, 8)
                Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 8), Size = UDim2.new(0.5, 0, 0, 16), Font = Enum.Font.Gotham, Text = barName, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = ProgressFrame })
                local ProgressLabel = Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, 7), Size = UDim2.new(0.5, -14, 0, 18), Font = Enum.Font.Code, Text = tostring(value) .. " / " .. tostring(max) .. " " .. suffix, TextColor3 = Theme.AccentDim, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Parent = ProgressFrame })
                local Bar = Create("Frame", { BackgroundColor3 = Theme.Background, Position = UDim2.new(0, 14, 0, 30), Size = UDim2.new(1, -28, 0, 6), Parent = ProgressFrame }); AddCorner(Bar, 3)
                local Fill = Create("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new(math.clamp(value / max, 0, 1), 0, 1, 0), Parent = Bar }); AddCorner(Fill, 3)
                function ProgressBar:Set(v) ProgressBar.Value = math.clamp(v, 0, max); ProgressLabel.Text = tostring(ProgressBar.Value) .. " / " .. tostring(max) .. " " .. suffix; Tween(Fill, { Size = UDim2.new(math.clamp(ProgressBar.Value / max, 0, 1), 0, 1, 0) }, Ease.Smooth) end
                return ProgressBar
            end

            return Section
        end
        return Tab
    end

    -- ═════════════════════════════════════════════════════
    --  NOTIFY · redesigned minimal toast
    -- ═════════════════════════════════════════════════════
    function Window:Notify(config)
        config = config or {}
        local title = config.Title or "Notification"
        local content = config.Content or ""
        local duration = config.Duration or 3.5
        local notifType = config.Type or "Info"

        local glyphs = { Info = "i", Success = "✓", Warning = "!", Error = "×" }
        local inverted = (notifType == "Error")

        local NotifContainer = ScreenGui:FindFirstChild("NotifContainer")
        if not NotifContainer then
            NotifContainer = Create("Frame", { Name = "NotifContainer", BackgroundTransparency = 1, Position = UDim2.new(1, -16, 0, 16), AnchorPoint = Vector2.new(1, 0), Size = UDim2.new(0, 312, 1, -32), Parent = ScreenGui })
            Create("UIListLayout", { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Top, Parent = NotifContainer })
        end

        local NotifFrame = Create("Frame", { Name = "Notification", BackgroundColor3 = Theme.Element, Size = UDim2.new(1, 0, 0, 66), ClipsDescendants = true, Parent = NotifContainer })
        AddCorner(NotifFrame, 10); AddStroke(NotifFrame, Theme.HairlineHi, 1)

        -- top timer line (shrinks left→right)
        local Timer = Create("Frame", { BackgroundColor3 = inverted and Theme.Invert or Theme.Accent, BackgroundTransparency = inverted and 0.4 or 0.55, Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, ZIndex = 3, Parent = NotifFrame })

        -- glyph marker
        local Marker = Create("Frame", { BackgroundColor3 = inverted and Theme.Accent or Theme.Background, Position = UDim2.new(0, 14, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 24, 0, 24), ZIndex = 2, Parent = NotifFrame })
        AddCorner(Marker, 7)
        if not inverted then AddStroke(Marker, Theme.HairlineHi, 1) end
        Create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.GothamBold, Text = glyphs[notifType], TextColor3 = inverted and Theme.Invert or Theme.Accent, TextSize = 13, Parent = Marker })

        Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 48, 0, 13), Size = UDim2.new(1, -78, 0, 18), Font = Enum.Font.GothamBold, Text = title, TextColor3 = Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = NotifFrame })
        Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 48, 0, 32), Size = UDim2.new(1, -78, 0, 26), Font = Enum.Font.Gotham, Text = content, TextColor3 = Theme.TextDark, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.AtEnd, Parent = NotifFrame })

        -- hover close
        local CloseX = Create("TextButton", { BackgroundTransparency = 1, Position = UDim2.new(1, -26, 0, 8), Size = UDim2.new(0, 18, 0, 18), Font = Enum.Font.GothamMedium, Text = "×", TextColor3 = Theme.TextMuted, TextSize = 13, Visible = false, ZIndex = 3, Parent = NotifFrame })
        NotifFrame.MouseEnter:Connect(function() CloseX.Visible = true end)
        NotifFrame.MouseLeave:Connect(function() CloseX.Visible = false end)

        local dismissed = false
        local function Dismiss()
            if dismissed then return end; dismissed = true
            Tween(NotifFrame, { Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 }, Ease.Shrink)
            task.wait(0.2); if NotifFrame.Parent then NotifFrame:Destroy() end
        end
        CloseX.MouseButton1Click:Connect(Dismiss)

        NotifFrame.Position = UDim2.new(1, 40, 0, 0); NotifFrame.BackgroundTransparency = 1
        Tween(NotifFrame, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 }, Ease.Spring)
        Tween(Timer, { Size = UDim2.new(0, 0, 0, 2) }, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In))
        task.delay(duration, Dismiss)
    end

    -- ═════════════════════════════════════════════════════
    --  CONFIRM · inverted primary action
    -- ═════════════════════════════════════════════════════
    function Window:Confirm(config)
        config = config or {}
        local title = config.Title or "Confirm"
        local message = config.Message or "Are you sure?"
        local onConfirm = config.OnConfirm or function() end
        local onCancel = config.OnCancel or function() end

        local Overlay = Create("Frame", { Name = "ConfirmOverlay", BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 50, Parent = ScreenGui })
        local Card = Create("Frame", { Name = "Card", BackgroundColor3 = Theme.Element, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 0), ZIndex = 51, Parent = Overlay })
        AddCorner(Card, 12); AddStroke(Card, Theme.HairlineHi, 1); InsetHighlight(Card, 0.9)

        Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 24, 0, 20), Size = UDim2.new(1, -48, 0, 22), Font = Enum.Font.GothamBold, Text = title, TextColor3 = Theme.Text, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 51, Parent = Card })
        Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 24, 0, 48), Size = UDim2.new(1, -48, 0, 44), Font = Enum.Font.Gotham, Text = message, TextColor3 = Theme.TextDark, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 51, Parent = Card })

        local ConfirmBtn = Create("TextButton", { BackgroundColor3 = Theme.Accent, Position = UDim2.new(0, 24, 1, -52), Size = UDim2.new(0.5, -32, 0, 34), Font = Enum.Font.GothamMedium, Text = "Confirm", TextColor3 = Theme.Invert, TextSize = 12, ZIndex = 51, Parent = Card })
        AddCorner(ConfirmBtn, 8); CreateRipple(ConfirmBtn, Theme.Invert)
        ConfirmBtn.MouseEnter:Connect(function() Tween(ConfirmBtn, { BackgroundColor3 = Theme.AccentDim }, Ease.Snap) end)
        ConfirmBtn.MouseLeave:Connect(function() Tween(ConfirmBtn, { BackgroundColor3 = Theme.Accent }, Ease.Smooth) end)

        local CancelBtn = Create("TextButton", { BackgroundColor3 = Theme.Surface, Position = UDim2.new(0.5, 8, 1, -52), Size = UDim2.new(0.5, -32, 0, 34), Font = Enum.Font.GothamMedium, Text = "Cancel", TextColor3 = Theme.Text, TextSize = 12, ZIndex = 51, Parent = Card })
        AddCorner(CancelBtn, 8); AddStroke(CancelBtn, Theme.Hairline, 1); CreateRipple(CancelBtn, Theme.Accent)
        CancelBtn.MouseEnter:Connect(function() Tween(CancelBtn, { BackgroundColor3 = Theme.ElementHover }, Ease.Snap) end)
        CancelBtn.MouseLeave:Connect(function() Tween(CancelBtn, { BackgroundColor3 = Theme.Surface }, Ease.Smooth) end)

        Tween(Card, { Size = UDim2.new(0, 340, 0, 162) }, Ease.Spring); Tween(Overlay, { BackgroundTransparency = 0.4 }, Ease.Smooth)
        local function Close() Tween(Card, { Size = UDim2.new(0, 0, 0, 0) }, Ease.Shrink); Tween(Overlay, { BackgroundTransparency = 1 }, Ease.Shrink); task.wait(0.2); Overlay:Destroy() end
        ConfirmBtn.MouseButton1Click:Connect(function() Close(); onConfirm() end)
        CancelBtn.MouseButton1Click:Connect(function() Close(); onCancel() end)
    end

    -- ═════════════════════════════════════════════════════
    --  CONFIG PERSISTENCE
    -- ═════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════
--  LIVE THEME SWAP
-- ═══════════════════════════════════════════════════════════
function InvokerLib:SetTheme(customTheme)
    for key, value in pairs(customTheme) do if Theme[key] then Theme[key] = value end end
    for _, ref in ipairs(_ThemeRefs) do
        local inst, prop, themeKey = ref[1], ref[2], ref[3]
        if Theme[themeKey] and inst and inst.Parent then inst[prop] = Theme[themeKey] end
    end
end

return InvokerLib
