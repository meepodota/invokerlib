InvokerLib Docs - Getting Started
Documentation Guide

Getting Started
Loading the Library

Copy
local InvokerLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/meepodota/invokerlib/refs/heads/main/mainlib.lua"))()
Creating a Window

Copy
local Window = InvokerLib:CreateWindow({
    Title = "My Hub",           -- Window title
    Size = UDim2.new(0, 750, 0, 500),  -- Window size
    ToggleKey = Enum.KeyCode.RightControl  -- Key to toggle visibility
})

Components
Components
Tabs
Tabs appear in the left sidebar and contain sections.


Copy
local Tab = Window:CreateTab({
    Name = "Tab Name",
    Icon = "⚙️"  -- Emoji or text icon
})
Sections
Sections group related elements within a tab.


Copy
local Section = Tab:CreateSection("Section Name")
Toggle
A switch that can be turned on/off.


Copy
local Toggle = Section:CreateToggle({
    Name = "Toggle Name",
    Default = false,
    Callback = function(value)
        print("Toggle:", value)
    end
})

-- Methods
Toggle:Set(true)  -- Programmatically set value
Button
A clickable button that executes a function.


Copy
Section:CreateButton({
    Name = "Button Name",
    Callback = function()
        print("Button clicked!")
    end
})
Slider
A draggable slider for numeric values.


Copy
local Slider = Section:CreateSlider({
    Name = "Slider Name",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(value)
        print("Slider:", value)
    end
})

-- Methods
Slider:Set(75)  -- Programmatically set value
Dropdown
A dropdown menu with multiple options.


Copy
local Dropdown = Section:CreateDropdown({
    Name = "Dropdown Name",
    Options = {"Option 1", "Option 2", "Option 3"},
    Default = "Option 1",
    Callback = function(option)
        print("Selected:", option)
    end
})

-- Methods
Dropdown:Set("Option 2")  -- Programmatically set value
Keybind
Allows users to set custom keybinds.


Copy
local Keybind = Section:CreateKeybind({
    Name = "Keybind Name",
    Default = Enum.KeyCode.E,
    Callback = function()
        print("Keybind pressed!")
    end
})

-- Methods
Keybind:Set(Enum.KeyCode.F)  -- Change keybind
Textbox
An input field for text.


Copy
local Textbox = Section:CreateTextbox({
    Name = "Textbox Name",
    Placeholder = "Enter text...",
    Callback = function(text, enterPressed)
        print("Text:", text)
    end
})

-- Methods
Textbox:Set("Hello")  -- Set text programmatically
Label
Simple text display.


Copy
local Label = Section:CreateLabel("Label Text")

-- Methods
Label:Set("New Text")  -- Update label text
Paragraph
A titled text block for information.


Copy
local Paragraph = Section:CreateParagraph({
    Title = "Title",
    Content = "This is the content of the paragraph."
})

-- Methods
Paragraph:Set({Title = "New Title", Content = "New content"})
Notifications
Display toast notifications.


Copy
Window:Notify({
    Title = "Notification Title",
    Content = "Notification content text",
    Type = "Info",      -- Info, Success, Warning, Error
    Duration = 3        -- Seconds
})
Type
Color
Info

Red (accent)

Success

Green

Warning

Yellow

Error

Red

Theme Customization
Customize the UI colors:


Copy
InvokerLib:SetTheme({
    Background = Color3.fromRGB(20, 20, 30),
    Accent = Color3.fromRGB(100, 150, 255),
    Text = Color3.fromRGB(255, 255, 255)
})
Available Theme Properties
Property
Description
Background

Main background

Sidebar

Sidebar background

Panel

Content panel background

Element

Element backgrounds

ElementHover

Element hover state

Accent

Accent color (buttons, highlights)

AccentDark

Darker accent

Text

Primary text

TextDark

Secondary text

Divider

Divider lines

Success

Success notification

Warning

Warning notification

Border

Border colors

Keyboard Shortcuts
Key
Action
RightControl (default)

Toggle UI visibility

Click + Drag on title

Move window

Complete Example Structure

Copy
local InvokerLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/meepodota/invokerlib/refs/heads/main/mainlib.lua"))()

local Window = InvokerLib:CreateWindow({Title = "My Hub"})

local Tab1 = Window:CreateTab({Name = "Main", Icon = "🏠"})
    local Section1 = Tab1:CreateSection("Features")
        Section1:CreateToggle({...})
        Section1:CreateButton({...})
        Section1:CreateSlider({...})
    
local Tab2 = Window:CreateTab({Name = "Settings", Icon = "⚙️"})
    local Section2 = Tab2:CreateSection("Config")
        Section2:CreateDropdown({...})
        Section2:CreateKeybind({...})

Window:Notify({Title = "Loaded!", Type = "Success"})
