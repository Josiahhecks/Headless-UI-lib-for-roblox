local Components = {}
Components.__index = Components

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

function Components.new(Renderer)
    local self = setmetatable({}, Components)
    self.Renderer = Renderer
    return self
end

-- Chainable Window Object
local Window = {}
Window.__index = Window

function Window.new(renderer, config)
    local self = setmetatable({}, Window)
    self.Renderer = renderer
    self.Tabs = {}

    self.Instance = renderer:Create("CanvasGroup", {
        Name = "HeadlessWindow",
        Size = UDim2.new(0, 500, 0, 350),
        Position = UDim2.new(0.5, -250, 0.5, -175),
        BackgroundColor3 = renderer.Theme.Background,
        ClipsDescendants = true
    })
    renderer:ApplyGlassEffect(self.Instance)

    local titleBar = renderer:Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = self.Instance
    })

    local titleLabel = renderer:Create("TextLabel", {
        Text = config.Title or "HeadlessUI",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = renderer.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium,
        TextSize = 16,
        Parent = titleBar
    })

    renderer:MakeDraggable(self.Instance, titleBar)

    self.TabContainer = renderer:Create("Frame", {
        Name = "TabContainer",
        Position = UDim2.new(0, 10, 0, 50),
        Size = UDim2.new(0, 120, 1, -60),
        BackgroundTransparency = 1,
        Parent = self.Instance
    })

    self.ContentContainer = renderer:Create("Frame", {
        Name = "ContentContainer",
        Position = UDim2.new(0, 140, 0, 50),
        Size = UDim2.new(1, -150, 1, -60),
        BackgroundTransparency = 1,
        Parent = self.Instance
    })

    renderer:Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        Parent = self.TabContainer
    })

    return self
end

function Window:AddTab(name)
    local Tab = {}
    Tab.__index = Tab

    local tabButton = self.Renderer:Create("TextButton", {
        Text = name,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = self.Renderer.Theme.Accent,
        BackgroundTransparency = 0.8,
        TextColor3 = self.Renderer.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        Parent = self.TabContainer
    })
    self.Renderer:Create("UICorner", {CornerRadius = UDim.new(0, 6)}, tabButton)

    local container = self.Renderer:Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 2,
        Parent = self.ContentContainer,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    self.Renderer:Create("UIListLayout", {Padding = UDim.new(0, 8)}, container)
    self.Renderer:Create("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 5)}, container)

    if #self.Tabs == 0 then
        container.Visible = true
        tabButton.BackgroundTransparency = 0.5
    end

    tabButton.MouseButton1Click:Connect(function()
        for _, t in ipairs(self.Tabs) do
            t.Container.Visible = false
            t.Button.BackgroundTransparency = 0.8
        end
        container.Visible = true
        tabButton.BackgroundTransparency = 0.5
    end)

    local tabObj = setmetatable({Container = container, Button = tabButton, Renderer = self.Renderer}, Tab)
    table.insert(self.Tabs, tabObj)

    function Tab:AddToggle(name, callback)
        local toggle = self.Renderer:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 35),
            BackgroundTransparency = 0.9,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = self.Container
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(0, 6)}, toggle)

        local label = self.Renderer:Create("TextLabel", {
            Text = name,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -50, 1, 0),
            BackgroundTransparency = 1,
            TextColor3 = self.Renderer.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            Parent = toggle
        })

        local button = self.Renderer:Create("TextButton", {
            Text = "",
            Position = UDim2.new(1, -40, 0.5, -10),
            Size = UDim2.new(0, 30, 0, 20),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            Parent = toggle
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(1, 0)}, button)

        local dot = self.Renderer:Create("Frame", {
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = button
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)

        local state = false
        button.MouseButton1Click:Connect(function()
            state = not state
            self.Renderer:Tween(dot, 0.2, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
            self.Renderer:Tween(button, 0.2, {BackgroundColor3 = state and self.Renderer.Theme.Accent or Color3.fromRGB(50, 50, 50)})
            callback(state)
        end)

        return toggle
    end

    function Tab:AddSlider(name, min, max, default, callback)
        local slider = self.Renderer:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 45),
            BackgroundTransparency = 0.9,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = self.Container
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(0, 6)}, slider)

        local label = self.Renderer:Create("TextLabel", {
            Text = name,
            Position = UDim2.new(0, 10, 0, 5),
            Size = UDim2.new(1, -70, 0, 15),
            BackgroundTransparency = 1,
            TextColor3 = self.Renderer.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            Parent = slider
        })

        local valueLabel = self.Renderer:Create("TextLabel", {
            Text = tostring(default),
            Position = UDim2.new(1, -60, 0, 5),
            Size = UDim2.new(0, 50, 0, 15),
            BackgroundTransparency = 1,
            TextColor3 = self.Renderer.Theme.SecondaryText,
            TextXAlignment = Enum.TextXAlignment.Right,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            Parent = slider
        })

        local track = self.Renderer:Create("Frame", {
            Position = UDim2.new(0, 10, 0, 30),
            Size = UDim2.new(1, -20, 0, 4),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            Parent = slider
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(1, 0)}, track)

        local fill = self.Renderer:Create("Frame", {
            Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = self.Renderer.Theme.Accent,
            Parent = track
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)

        local knob = self.Renderer:Create("Frame", {
            Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = track
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)

        local dragging = false
        local function move(input)
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * pos)
            valueLabel.Text = tostring(val)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            knob.Position = UDim2.new(pos, -6, 0.5, -6)
            callback(val)
        end

        self.Renderer.Engine:Track(knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end))

        self.Renderer.Engine:Track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))

        self.Renderer.Engine:Track(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                move(input)
            end
        end))

        return slider
    end

    function Tab:AddButton(name, callback)
        local button = self.Renderer:Create("TextButton", {
            Text = name,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.9,
            TextColor3 = self.Renderer.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            Parent = self.Container
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(0, 6)}, button)
        button.MouseButton1Click:Connect(callback)
        return button
    end

    function Tab:AddDropdown(name, options, callback)
        local dropdown = self.Renderer:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 35),
            BackgroundTransparency = 0.9,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            ClipsDescendants = true,
            Parent = self.Container
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(0, 6)}, dropdown)

        local button = self.Renderer:Create("TextButton", {
            Text = name .. " : " .. (options[1] or "None"),
            Size = UDim2.new(1, 0, 0, 35),
            BackgroundTransparency = 1,
            TextColor3 = self.Renderer.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            Parent = dropdown
        })

        local open = false
        button.MouseButton1Click:Connect(function()
            open = not open
            self.Renderer:Tween(dropdown, 0.3, {Size = open and UDim2.new(1, 0, 0, 35 + (#options * 30)) or UDim2.new(1, 0, 0, 35)})
        end)

        for i, opt in ipairs(options) do
            local optBtn = self.Renderer:Create("TextButton", {
                Text = opt,
                Size = UDim2.new(1, 0, 0, 30),
                Position = UDim2.new(0, 0, 0, 35 + (i-1) * 30),
                BackgroundTransparency = 1,
                TextColor3 = self.Renderer.Theme.SecondaryText,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                Parent = dropdown
            })
            optBtn.MouseButton1Click:Connect(function()
                button.Text = name .. " : " .. opt
                open = false
                self.Renderer:Tween(dropdown, 0.3, {Size = UDim2.new(1, 0, 0, 35)})
                callback(opt)
            end)
        end
        return dropdown
    end

    function Tab:AddKeybind(name, default, callback)
        local keybind = self.Renderer:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 35),
            BackgroundTransparency = 0.9,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = self.Container
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(0, 6)}, keybind)

        local label = self.Renderer:Create("TextLabel", {
            Text = name,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -80, 1, 0),
            BackgroundTransparency = 1,
            TextColor3 = self.Renderer.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            Parent = keybind
        })

        local bindBtn = self.Renderer:Create("TextButton", {
            Text = default.Name,
            Position = UDim2.new(1, -70, 0.5, -10),
            Size = UDim2.new(0, 60, 0, 20),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            TextColor3 = self.Renderer.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            Parent = keybind
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(0, 4)}, bindBtn)

        local currentBind = default
        local listening = false

        bindBtn.MouseButton1Click:Connect(function()
            listening = true
            bindBtn.Text = "..."
        end)

        self.Renderer.Engine:Track(UserInputService.InputBegan:Connect(function(input)
            if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                currentBind = input.KeyCode
                bindBtn.Text = currentBind.Name
                listening = false
            elseif input.KeyCode == currentBind then
                callback()
            end
        end))

        return keybind
    end

    return tabObj
end

function Components:CreateWindow(config)
    return Window.new(self.Renderer, config)
end

return Components
