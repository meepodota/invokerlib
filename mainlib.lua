local InvokerLib = {}
InvokerLib.__index = InvokerLib

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- Theme Configuration
local Theme = {
    Background = Color3.fromRGB(15, 15, 20),
    Sidebar = Color3.fromRGB(20, 20, 28),
    Panel = Color3.fromRGB(25, 25, 35),
    Element = Color3.fromRGB(35, 35, 45),
    ElementHover = Color3.fromRGB(45, 45, 58),
    Accent = Color3.fromRGB(180, 60, 60),
    AccentDark = Color3.fromRGB(140, 45, 45),
    Text = Color3.fromRGB(220, 220, 220),
    TextDark = Color3.fromRGB(140, 140, 140),
    Divider = Color3.fromRGB(50, 50, 60),
    Success = Color3.fromRGB(80, 180, 80),
    Warning = Color3.fromRGB(200, 150, 50),
    Border = Color3.fromRGB(60, 60, 75)
}

-- Utility Functions
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

local function Tween(object, properties, duration, style, direction)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

local function AddCorner(parent, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 6),
        Parent = parent
    })
end

local function AddStroke(parent, color, thickness)
    return Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Parent = parent
    })
end

local function AddPadding(parent, padding)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, padding),
        PaddingBottom = UDim.new(0, padding),
        PaddingLeft = UDim.new(0, padding),
        PaddingRight = UDim.new(0, padding),
        Parent = parent
    })
end

-- Dragging System
local function MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    
    handle = handle or frame
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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

-- Ripple Effect
local function CreateRipple(parent)
    parent.ClipsDescendants = true
    
    local function DoRipple(x, y)
        local ripple = Create("Frame", {
            Name = "Ripple",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.7,
            Position = UDim2.new(0, x, 0, y),
            Size = UDim2.new(0, 0, 0, 0),
            Parent = parent
        })
        AddCorner(ripple, 999)
        
        local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
        Tween(ripple, {Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1}, 0.5)
        
        task.delay(0.5, function()
            ripple:Destroy()
        end)
    end
    
    parent.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local x = input.Position.X - parent.AbsolutePosition.X
            local y = input.Position.Y - parent.AbsolutePosition.Y
            DoRipple(x, y)
        end
    end)
end

-- Main Library Function
function InvokerLib:CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "InvokerLib"
    local windowSize = config.Size or UDim2.new(0, 750, 0, 500)
    local windowIcon = config.Icon or "rbxassetid://7733960981"
    
    local Window = {}
    Window.Tabs = {}
    Window.CurrentTab = nil
    
    -- Destroy existing UI
    if game.CoreGui:FindFirstChild("InvokerLib") then
        game.CoreGui:FindFirstChild("InvokerLib"):Destroy()
    end
    
    -- Main ScreenGui
    local ScreenGui = Create("ScreenGui", {
        Name = "InvokerLib",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = game.CoreGui
    })
    
    -- Main Frame
    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = windowSize,
        Parent = ScreenGui
    })
    AddCorner(MainFrame, 8)
    AddStroke(MainFrame, Theme.Border, 1)
    
    -- Shadow
    local Shadow = Create("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 40, 1, 40),
        Image = "rbxassetid://7912134082",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(20, 20, 280, 280),
        ZIndex = -1,
        Parent = MainFrame
    })
    
    -- Sidebar
    local Sidebar = Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme.Sidebar,
        Size = UDim2.new(0, 180, 1, 0),
        Parent = MainFrame
    })
    AddCorner(Sidebar, 8)
    
    -- Sidebar Fix (cover right corners)
    local SidebarFix = Create("Frame", {
        Name = "SidebarFix",
        BackgroundColor3 = Theme.Sidebar,
        Position = UDim2.new(1, -8, 0, 0),
        Size = UDim2.new(0, 8, 1, 0),
        BorderSizePixel = 0,
        Parent = Sidebar
    })
    
    -- Logo Section
    local LogoSection = Create("Frame", {
        Name = "LogoSection",
        BackgroundTransparency = 1,
        Active = true,
        Size = UDim2.new(1, 0, 0, 60),
        Parent = Sidebar
    })
    
    local LogoIcon = Create("ImageLabel", {
        Name = "LogoIcon",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 30, 0, 30),
        Image = windowIcon,
        ImageColor3 = Theme.Accent,
        Parent = LogoSection
    })
    
    local LogoText = Create("TextLabel", {
        Name = "LogoText",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 55, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(1, -70, 0, 20),
        Font = Enum.Font.GothamBold,
        Text = windowTitle,
        TextColor3 = Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = LogoSection
    })
    
    -- Tab Container
    local TabContainer = Create("ScrollingFrame", {
        Name = "TabContainer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 70),
        Size = UDim2.new(1, 0, 1, -120),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Sidebar
    })
    AddPadding(TabContainer, 8)
    
    local TabListLayout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = TabContainer
    })
    
    -- Category Label
    local CategoryLabel = Create("TextLabel", {
        Name = "CategoryLabel",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 0, 25),
        Font = Enum.Font.GothamMedium,
        Text = "📋 Navigation",
        TextColor3 = Theme.TextDark,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TabContainer
    })
    
    -- Search Bar
    local SearchFrame = Create("Frame", {
        Name = "SearchFrame",
        BackgroundColor3 = Theme.Element,
        Position = UDim2.new(0, 10, 1, -45),
        Size = UDim2.new(1, -20, 0, 35),
        Parent = Sidebar
    })
    AddCorner(SearchFrame, 6)
    
    local SearchIcon = Create("TextLabel", {
        Name = "SearchIcon",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 20, 0, 20),
        Font = Enum.Font.GothamMedium,
        Text = "🔍",
        TextColor3 = Theme.TextDark,
        TextSize = 12,
        Parent = SearchFrame
    })
    
    local SearchBox = Create("TextBox", {
        Name = "SearchBox",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 35, 0, 0),
        Size = UDim2.new(1, -45, 1, 0),
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search...",
        PlaceholderColor3 = Theme.TextDark,
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = SearchFrame
    })
    
    -- Content Area
    local ContentArea = Create("Frame", {
        Name = "ContentArea",
        BackgroundColor3 = Theme.Panel,
        Position = UDim2.new(0, 185, 0, 5),
        Size = UDim2.new(1, -190, 1, -10),
        Parent = MainFrame
    })
    AddCorner(ContentArea, 6)
    
    -- Header
    local Header = Create("Frame", {
        Name = "Header",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 50),
        Parent = ContentArea
    })
    
    -- Breadcrumb
    local Breadcrumb = Create("TextLabel", {
        Name = "Breadcrumb",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0.5, 0, 0, 20),
        Font = Enum.Font.Gotham,
        Text = "Home / Main Settings",
        TextColor3 = Theme.TextDark,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true,
        Parent = Header
    })
    
    -- Sub Tabs Container
    local SubTabContainer = Create("Frame", {
        Name = "SubTabContainer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 400, 0, 30),
        Parent = Header
    })
    
    local SubTabLayout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 20),
        Parent = SubTabContainer
    })
    
    -- Close Button
    local CloseButton = Create("TextButton", {
        Name = "CloseButton",
        BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(1, -40, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 25, 0, 25),
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Theme.Text,
        TextSize = 18,
        Parent = Header
    })
    AddCorner(CloseButton, 6)
    CreateRipple(CloseButton)
    
    CloseButton.MouseButton1Click:Connect(function()
        Tween(MainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        task.wait(0.3)
        ScreenGui:Destroy()
    end)
    
    -- Minimize Button
    local MinButton = Create("TextButton", {
        Name = "MinButton",
        BackgroundColor3 = Theme.Element,
        Position = UDim2.new(1, -70, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 25, 0, 25),
        Font = Enum.Font.GothamBold,
        Text = "−",
        TextColor3 = Theme.Text,
        TextSize = 18,
        Parent = Header
    })
    AddCorner(MinButton, 6)
    CreateRipple(MinButton)
    
    local minimized = false
    MinButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(MainFrame, {Size = UDim2.new(0, 180, 0, 60)}, 0.3)
        else
            Tween(MainFrame, {Size = windowSize}, 0.3)
        end
    end)
    
    -- Divider
    local Divider = Create("Frame", {
        Name = "Divider",
        BackgroundColor3 = Theme.Divider,
        Position = UDim2.new(0, 10, 0, 50),
        Size = UDim2.new(1, -20, 0, 1),
        BorderSizePixel = 0,
        Parent = ContentArea
    })
    
    -- Pages Container
    local PagesContainer = Create("Frame", {
        Name = "PagesContainer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 55),
        Size = UDim2.new(1, 0, 1, -55),
        Parent = ContentArea
    })
    
    -- Make Window Draggable
    MakeDraggable(MainFrame, LogoSection)
    
    -- Intro Animation
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    Tween(MainFrame, {Size = windowSize}, 0.4, Enum.EasingStyle.Back)
    
    -- Tab Creation Function
    function Window:CreateTab(config)
        config = config or {}
        local tabName = config.Name or "Tab"
        local tabIcon = config.Icon or "⚙️"
        
        local Tab = {}
        Tab.SubTabs = {}
        Tab.CurrentSubTab = nil
        
        -- Tab Button
        local TabButton = Create("TextButton", {
            Name = tabName,
            BackgroundColor3 = Theme.Element,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 0, 35),
            Font = Enum.Font.Gotham,
            Text = "",
            Parent = TabContainer
        })
        AddCorner(TabButton, 6)
        
        local TabIcon = Create("TextLabel", {
            Name = "Icon",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, 20, 0, 20),
            Font = Enum.Font.Gotham,
            Text = tabIcon,
            TextColor3 = Theme.TextDark,
            TextSize = 14,
            Parent = TabButton
        })
        
        local TabLabel = Create("TextLabel", {
            Name = "Label",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 38, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(1, -50, 0, 20),
            Font = Enum.Font.Gotham,
            Text = tabName,
            TextColor3 = Theme.TextDark,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TabButton
        })
        
        local TabIndicator = Create("Frame", {
            Name = "Indicator",
            BackgroundColor3 = Theme.Accent,
            Position = UDim2.new(0, 3, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, 3, 0, 0),
            Parent = TabButton
        })
        AddCorner(TabIndicator, 2)
        
        -- Tab Page
        local TabPage = Create("ScrollingFrame", {
            Name = tabName .. "Page",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = PagesContainer
        })
        AddPadding(TabPage, 15)
        
        local PageLayout = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = TabPage
        })
        
        -- Tab Interaction
        local function SelectTab()
            -- Deselect all tabs
            for _, tab in pairs(Window.Tabs) do
                tab.Button.BackgroundTransparency = 1
                Tween(tab.Indicator, {Size = UDim2.new(0, 3, 0, 0)}, 0.2)
                tab.Label.TextColor3 = Theme.TextDark
                tab.Icon.TextColor3 = Theme.TextDark
                tab.Page.Visible = false
            end
            
            -- Select this tab
            TabButton.BackgroundTransparency = 0
            Tween(TabIndicator, {Size = UDim2.new(0, 3, 0.6, 0)}, 0.2)
            TabLabel.TextColor3 = Theme.Text
            TabIcon.TextColor3 = Theme.Accent
            TabPage.Visible = true
            Window.CurrentTab = Tab
            
            Breadcrumb.Text = string.format('<font color="rgb(180,60,60)">%s</font> / Main Settings', tabName)
        end
        
        TabButton.MouseButton1Click:Connect(SelectTab)
        
        TabButton.MouseEnter:Connect(function()
            if Window.CurrentTab ~= Tab then
                TabButton.BackgroundTransparency = 0.5
            end
        end)
        
        TabButton.MouseLeave:Connect(function()
            if Window.CurrentTab ~= Tab then
                TabButton.BackgroundTransparency = 1
            end
        end)
        
        -- Store tab data
        Tab.Button = TabButton
        Tab.Label = TabLabel
        Tab.Icon = TabIcon
        Tab.Indicator = TabIndicator
        Tab.Page = TabPage
        
        table.insert(Window.Tabs, Tab)
        
        -- Select first tab
        if #Window.Tabs == 1 then
            SelectTab()
        end
        
        -- Section Creation
        function Tab:CreateSection(name)
            local Section = {}
            
            local SectionFrame = Create("Frame", {
                Name = name or "Section",
                BackgroundColor3 = Theme.Element,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = TabPage
            })
            AddCorner(SectionFrame, 8)
            AddStroke(SectionFrame, Theme.Border, 1)
            
            local SectionHeader = Create("Frame", {
                Name = "Header",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 35),
                Parent = SectionFrame
            })
            
            local SectionTitle = Create("TextLabel", {
                Name = "Title",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(1, -24, 0, 20),
                Font = Enum.Font.GothamBold,
                Text = name or "Section",
                TextColor3 = Theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SectionHeader
            })
            
            local SectionContent = Create("Frame", {
                Name = "Content",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 35),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = SectionFrame
            })
            AddPadding(SectionContent, 8)
            
            local ContentLayout = Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 6),
                Parent = SectionContent
            })
            
            Section.Frame = SectionFrame
            Section.Content = SectionContent
            
            -- Toggle Element
            function Section:CreateToggle(config)
                config = config or {}
                local toggleName = config.Name or "Toggle"
                local default = config.Default or false
                local callback = config.Callback or function() end
                
                local Toggle = {}
                Toggle.Value = default
                
                local ToggleFrame = Create("Frame", {
                    Name = toggleName,
                    BackgroundColor3 = Theme.ElementHover,
                    Size = UDim2.new(1, 0, 0, 35),
                    Parent = SectionContent
                })
                AddCorner(ToggleFrame, 6)
                
                local ToggleLabel = Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(1, -60, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = toggleName,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ToggleFrame
                })
                
                local ToggleButton = Create("Frame", {
                    Name = "Button",
                    BackgroundColor3 = Theme.Background,
                    Position = UDim2.new(1, -45, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0, 38, 0, 20),
                    Parent = ToggleFrame
                })
                AddCorner(ToggleButton, 10)
                AddStroke(ToggleButton, Theme.Border, 1)
                
                local ToggleCircle = Create("Frame", {
                    Name = "Circle",
                    BackgroundColor3 = Theme.TextDark,
                    Position = UDim2.new(0, 3, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0, 14, 0, 14),
                    Parent = ToggleButton
                })
                AddCorner(ToggleCircle, 7)
                
                local function UpdateToggle()
                    if Toggle.Value then
                        Tween(ToggleCircle, {Position = UDim2.new(1, -17, 0.5, 0), BackgroundColor3 = Theme.Accent}, 0.2)
                        Tween(ToggleButton, {BackgroundColor3 = Theme.AccentDark}, 0.2)
                    else
                        Tween(ToggleCircle, {Position = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = Theme.TextDark}, 0.2)
                        Tween(ToggleButton, {BackgroundColor3 = Theme.Background}, 0.2)
                    end
                end
                
                local ClickDetector = Create("TextButton", {
                    Name = "Click",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    Parent = ToggleFrame
                })
                
                ClickDetector.MouseButton1Click:Connect(function()
                    Toggle.Value = not Toggle.Value
                    UpdateToggle()
                    callback(Toggle.Value)
                end)
                
                if default then
                    UpdateToggle()
                end
                
                function Toggle:Set(value)
                    Toggle.Value = value
                    UpdateToggle()
                    callback(Toggle.Value)
                end
                
                return Toggle
            end
            
            -- Button Element
            function Section:CreateButton(config)
                config = config or {}
                local buttonName = config.Name or "Button"
                local callback = config.Callback or function() end
                
                local Button = {}
                
                local ButtonFrame = Create("TextButton", {
                    Name = buttonName,
                    BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new(1, 0, 0, 35),
                    Font = Enum.Font.GothamMedium,
                    Text = buttonName,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    Parent = SectionContent
                })
                AddCorner(ButtonFrame, 6)
                CreateRipple(ButtonFrame)
                
                ButtonFrame.MouseEnter:Connect(function()
                    Tween(ButtonFrame, {BackgroundColor3 = Theme.AccentDark}, 0.2)
                end)
                
                ButtonFrame.MouseLeave:Connect(function()
                    Tween(ButtonFrame, {BackgroundColor3 = Theme.Accent}, 0.2)
                end)
                
                ButtonFrame.MouseButton1Click:Connect(callback)
                
                return Button
            end
            
            -- Slider Element
            function Section:CreateSlider(config)
                config = config or {}
                local sliderName = config.Name or "Slider"
                local min = config.Min or 0
                local max = config.Max or 100
                local default = config.Default or min
                local callback = config.Callback or function() end
                
                local Slider = {}
                Slider.Value = default
                
                local SliderFrame = Create("Frame", {
                    Name = sliderName,
                    BackgroundColor3 = Theme.ElementHover,
                    Size = UDim2.new(1, 0, 0, 50),
                    Parent = SectionContent
                })
                AddCorner(SliderFrame, 6)
                
                local SliderLabel = Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 5),
                    Size = UDim2.new(0.5, -10, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = sliderName,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = SliderFrame
                })
                
                local SliderValue = Create("TextLabel", {
                    Name = "Value",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, 0, 0, 5),
                    Size = UDim2.new(0.5, -10, 0, 20),
                    Font = Enum.Font.GothamBold,
                    Text = tostring(default),
                    TextColor3 = Theme.Accent,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = SliderFrame
                })
                
                local SliderBar = Create("Frame", {
                    Name = "Bar",
                    BackgroundColor3 = Theme.Background,
                    Position = UDim2.new(0, 10, 0, 30),
                    Size = UDim2.new(1, -20, 0, 8),
                    Parent = SliderFrame
                })
                AddCorner(SliderBar, 4)
                
                local SliderFill = Create("Frame", {
                    Name = "Fill",
                    BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                    Parent = SliderBar
                })
                AddCorner(SliderFill, 4)
                
                local SliderDot = Create("Frame", {
                    Name = "Dot",
                    BackgroundColor3 = Theme.Text,
                    Position = UDim2.new(1, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Size = UDim2.new(0, 14, 0, 14),
                    Parent = SliderFill
                })
                AddCorner(SliderDot, 7)
                
                local dragging = false
                
                local function UpdateSlider(input)
                    local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                    Slider.Value = math.floor(min + (max - min) * pos)
                    SliderValue.Text = tostring(Slider.Value)
                    Tween(SliderFill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.05)
                    callback(Slider.Value)
                end
                
                SliderBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
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
                    end
                end)
                
                function Slider:Set(value)
                    Slider.Value = math.clamp(value, min, max)
                    local pos = (Slider.Value - min) / (max - min)
                    SliderValue.Text = tostring(Slider.Value)
                    Tween(SliderFill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.2)
                    callback(Slider.Value)
                end
                
                return Slider
            end
            
            -- Dropdown Element
            function Section:CreateDropdown(config)
                config = config or {}
                local dropdownName = config.Name or "Dropdown"
                local options = config.Options or {"Option 1", "Option 2", "Option 3"}
                local default = config.Default or options[1]
                local callback = config.Callback or function() end
                
                local Dropdown = {}
                Dropdown.Value = default
                Dropdown.Open = false
                
                local DropdownFrame = Create("Frame", {
                    Name = dropdownName,
                    BackgroundColor3 = Theme.ElementHover,
                    Size = UDim2.new(1, 0, 0, 35),
                    ClipsDescendants = true,
                    Parent = SectionContent
                })
                AddCorner(DropdownFrame, 6)
                
                local DropdownLabel = Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.5, -10, 0, 35),
                    Font = Enum.Font.Gotham,
                    Text = dropdownName,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = DropdownFrame
                })
                
                local DropdownSelected = Create("TextLabel", {
                    Name = "Selected",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, 0, 0, 0),
                    Size = UDim2.new(0.5, -30, 0, 35),
                    Font = Enum.Font.GothamMedium,
                    Text = default,
                    TextColor3 = Theme.Accent,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = DropdownFrame
                })
                
                local DropdownArrow = Create("TextLabel", {
                    Name = "Arrow",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -25, 0, 0),
                    Size = UDim2.new(0, 20, 0, 35),
                    Font = Enum.Font.GothamBold,
                    Text = "▼",
                    TextColor3 = Theme.TextDark,
                    TextSize = 10,
                    Parent = DropdownFrame
                })
                
                local DropdownOptions = Create("Frame", {
                    Name = "Options",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 5, 0, 40),
                    Size = UDim2.new(1, -10, 0, #options * 30),
                    Parent = DropdownFrame
                })
                
                local OptionsLayout = Create("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    Parent = DropdownOptions
                })
                
                for _, option in ipairs(options) do
                    local OptionButton = Create("TextButton", {
                        Name = option,
                        BackgroundColor3 = Theme.Background,
                        Size = UDim2.new(1, 0, 0, 28),
                        Font = Enum.Font.Gotham,
                        Text = option,
                        TextColor3 = Theme.Text,
                        TextSize = 11,
                        Parent = DropdownOptions
                    })
                    AddCorner(OptionButton, 4)
                    
                    OptionButton.MouseEnter:Connect(function()
                        Tween(OptionButton, {BackgroundColor3 = Theme.Accent}, 0.1)
                    end)
                    
                    OptionButton.MouseLeave:Connect(function()
                        Tween(OptionButton, {BackgroundColor3 = Theme.Background}, 0.1)
                    end)
                    
                    OptionButton.MouseButton1Click:Connect(function()
                        Dropdown.Value = option
                        DropdownSelected.Text = option
                        Dropdown.Open = false
                        Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 35)}, 0.2)
                        Tween(DropdownArrow, {Rotation = 0}, 0.2)
                        callback(option)
                    end)
                end
                
                local ClickDetector = Create("TextButton", {
                    Name = "Click",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 35),
                    Text = "",
                    Parent = DropdownFrame
                })
                
                ClickDetector.MouseButton1Click:Connect(function()
                    Dropdown.Open = not Dropdown.Open
                    if Dropdown.Open then
                        Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 45 + #options * 30)}, 0.2)
                        Tween(DropdownArrow, {Rotation = 180}, 0.2)
                    else
                        Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 35)}, 0.2)
                        Tween(DropdownArrow, {Rotation = 0}, 0.2)
                    end
                end)
                
                function Dropdown:Set(value)
                    if table.find(options, value) then
                        Dropdown.Value = value
                        DropdownSelected.Text = value
                        callback(value)
                    end
                end
                
                return Dropdown
            end
            
            -- Keybind Element
            function Section:CreateKeybind(config)
                config = config or {}
                local keybindName = config.Name or "Keybind"
                local default = config.Default or Enum.KeyCode.E
                local callback = config.Callback or function() end
                
                local Keybind = {}
                Keybind.Value = default
                Keybind.Listening = false
                
                local KeybindFrame = Create("Frame", {
                    Name = keybindName,
                    BackgroundColor3 = Theme.ElementHover,
                    Size = UDim2.new(1, 0, 0, 35),
                    Parent = SectionContent
                })
                AddCorner(KeybindFrame, 6)
                
                local KeybindLabel = Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0.6, -10, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = keybindName,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = KeybindFrame
                })
                
                local KeybindButton = Create("TextButton", {
                    Name = "Button",
                    BackgroundColor3 = Theme.Background,
                    Position = UDim2.new(1, -70, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0, 60, 0, 25),
                    Font = Enum.Font.GothamMedium,
                    Text = default.Name,
                    TextColor3 = Theme.Accent,
                    TextSize = 11,
                    Parent = KeybindFrame
                })
                AddCorner(KeybindButton, 4)
                
                KeybindButton.MouseButton1Click:Connect(function()
                    Keybind.Listening = true
                    KeybindButton.Text = "..."
                end)
                
                UserInputService.InputBegan:Connect(function(input, processed)
                    if Keybind.Listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        Keybind.Value = input.KeyCode
                        KeybindButton.Text = input.KeyCode.Name
                        Keybind.Listening = false
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
            
            -- Textbox Element
            function Section:CreateTextbox(config)
                config = config or {}
                local textboxName = config.Name or "Textbox"
                local placeholder = config.Placeholder or "Enter text..."
                local callback = config.Callback or function() end
                
                local Textbox = {}
                Textbox.Value = ""
                
                local TextboxFrame = Create("Frame", {
                    Name = textboxName,
                    BackgroundColor3 = Theme.ElementHover,
                    Size = UDim2.new(1, 0, 0, 35),
                    Parent = SectionContent
                })
                AddCorner(TextboxFrame, 6)
                
                local TextboxLabel = Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0.4, -10, 0, 20),
                    Font = Enum.Font.Gotham,
                    Text = textboxName,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = TextboxFrame
                })
                
                local TextboxInput = Create("TextBox", {
                    Name = "Input",
                    BackgroundColor3 = Theme.Background,
                    Position = UDim2.new(0.4, 5, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0.6, -15, 0, 25),
                    Font = Enum.Font.Gotham,
                    PlaceholderText = placeholder,
                    PlaceholderColor3 = Theme.TextDark,
                    Text = "",
                    TextColor3 = Theme.Text,
                    TextSize = 11,
                    ClearTextOnFocus = false,
                    Parent = TextboxFrame
                })
                AddCorner(TextboxInput, 4)
                
                TextboxInput.FocusLost:Connect(function(enterPressed)
                    Textbox.Value = TextboxInput.Text
                    callback(TextboxInput.Text, enterPressed)
                end)
                
                function Textbox:Set(value)
                    Textbox.Value = value
                    TextboxInput.Text = value
                end
                
                return Textbox
            end
            
            -- Label Element
            function Section:CreateLabel(text)
                local LabelFrame = Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 25),
                    Font = Enum.Font.Gotham,
                    Text = text or "Label",
                    TextColor3 = Theme.TextDark,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = SectionContent
                })
                
                local Label = {}
                function Label:Set(newText)
                    LabelFrame.Text = newText
                end
                
                return Label
            end
            
            -- Paragraph Element  
            function Section:CreateParagraph(config)
                config = config or {}
                local title = config.Title or "Title"
                local content = config.Content or "Content"
                
                local ParagraphFrame = Create("Frame", {
                    Name = "Paragraph",
                    BackgroundColor3 = Theme.Background,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = SectionContent
                })
                AddCorner(ParagraphFrame, 6)
                AddPadding(ParagraphFrame, 10)
                
                local ParagraphLayout = Create("UIListLayout", {
                    Padding = UDim.new(0, 5),
                    Parent = ParagraphFrame
                })
                
                local ParagraphTitle = Create("TextLabel", {
                    Name = "Title",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Font = Enum.Font.GothamBold,
                    Text = title,
                    TextColor3 = Theme.Accent,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ParagraphFrame
                })
                
                local ParagraphContent = Create("TextLabel", {
                    Name = "Content",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Font = Enum.Font.Gotham,
                    Text = content,
                    TextColor3 = Theme.Text,
                    TextSize = 11,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = ParagraphFrame
                })
                
                local Paragraph = {}
                function Paragraph:Set(config)
                    ParagraphTitle.Text = config.Title or ParagraphTitle.Text
                    ParagraphContent.Text = config.Content or ParagraphContent.Text
                end
                
                return Paragraph
            end
            
            return Section
        end
        
        return Tab
    end
    
    -- Notification System
    function Window:Notify(config)
        config = config or {}
        local title = config.Title or "Notification"
        local content = config.Content or ""
        local duration = config.Duration or 3
        local notifType = config.Type or "Info" -- Info, Success, Warning, Error
        
        local typeColors = {
            Info = Theme.Accent,
            Success = Theme.Success,
            Warning = Theme.Warning,
            Error = Color3.fromRGB(200, 60, 60)
        }
        
        local NotifContainer = ScreenGui:FindFirstChild("NotifContainer")
        if not NotifContainer then
            NotifContainer = Create("Frame", {
                Name = "NotifContainer",
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -10, 0, 10),
                AnchorPoint = Vector2.new(1, 0),
                Size = UDim2.new(0, 280, 1, -20),
                Parent = ScreenGui
            })
            
            Create("UIListLayout", {
                Padding = UDim.new(0, 8),
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                Parent = NotifContainer
            })
        end
        
        local NotifFrame = Create("Frame", {
            Name = "Notification",
            BackgroundColor3 = Theme.Panel,
            Size = UDim2.new(1, 0, 0, 70),
            Parent = NotifContainer
        })
        AddCorner(NotifFrame, 8)
        AddStroke(NotifFrame, typeColors[notifType], 1)
        
        local NotifAccent = Create("Frame", {
            Name = "Accent",
            BackgroundColor3 = typeColors[notifType],
            Size = UDim2.new(0, 4, 1, -10),
            Position = UDim2.new(0, 5, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Parent = NotifFrame
        })
        AddCorner(NotifAccent, 2)
        
        local NotifTitle = Create("TextLabel", {
            Name = "Title",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 0, 10),
            Size = UDim2.new(1, -25, 0, 20),
            Font = Enum.Font.GothamBold,
            Text = title,
            TextColor3 = typeColors[notifType],
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = NotifFrame
        })
        
        local NotifContent = Create("TextLabel", {
            Name = "Content",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 0, 32),
            Size = UDim2.new(1, -25, 0, 30),
            Font = Enum.Font.Gotham,
            Text = content,
            TextColor3 = Theme.Text,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = NotifFrame
        })
        
        -- Animation
        NotifFrame.Position = UDim2.new(1, 50, 0, 0)
        Tween(NotifFrame, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back)
        
        task.delay(duration, function()
            Tween(NotifFrame, {Position = UDim2.new(1, 50, 0, 0)}, 0.3)
            task.wait(0.3)
            NotifFrame:Destroy()
        end)
    end
    
    -- Toggle Keybind
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == toggleKey then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)
    
    return Window
end

-- Theme Customization
function InvokerLib:SetTheme(customTheme)
    for key, value in pairs(customTheme) do
        if Theme[key] then
            Theme[key] = value
        end
    end
end

return InvokerLib
