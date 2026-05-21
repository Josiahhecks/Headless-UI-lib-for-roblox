local Components = {}
Components.__index = Components

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

function Components.new(Renderer)
    local self = setmetatable({}, Components)
    self.Renderer = Renderer
    return self
end

local Window = {}
Window.__index = Window

function Window.new(renderer, config)
    local self = setmetatable({}, Window)
    self.Renderer = renderer
    self.Tabs = {}

    self.Instance = renderer:Create("CanvasGroup", {
        Name = "HeadlessWindow",
        Size = UDim2.new(0, 550, 0, 400),
        Position = UDim2.new(0.5, -275, 0.5, -200),
        BackgroundColor3 = renderer.Theme.Background,
        ClipsDescendants = true
    })
    renderer:ApplyGlassEffect(self.Instance)

    local titleBar = renderer:Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundTransparency = 1,
        Parent = self.Instance
    })

    renderer:Create("TextLabel", {
        Text = config.Title or "HeadlessUI",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = renderer.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        Parent = titleBar
    })

    renderer:MakeDraggable(self.Instance, titleBar)

    self.TabContainer = renderer:Create("ScrollingFrame", {
        Name = "TabContainer",
        Position = UDim2.new(0, 10, 0, 55),
        Size = UDim2.new(0, 140, 1, -65),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        Parent = self.Instance
    })
    renderer:Create("UIListLayout", {Padding = UDim.new(0, 6), Parent = self.TabContainer})

    self.ContentContainer = renderer:Create("Frame", {
        Name = "ContentContainer",
        Position = UDim2.new(0, 160, 0, 55),
        Size = UDim2.new(1, -170, 1, -65),
        BackgroundTransparency = 1,
        Parent = self.Instance
    })

    return self
end

function Window:AddTab(name)
    local Tab = {}
    Tab.__index = Tab

    local tabButton = self.Renderer:Create("TextButton", {
        Text = name,
        Size = UDim2.new(1, -5, 0, 35),
        BackgroundColor3 = self.Renderer.Theme.Accent,
        BackgroundTransparency = 0.9,
        TextColor3 = self.Renderer.Theme.SecondaryText,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        Parent = self.TabContainer
    })
    self.Renderer:Create("UICorner", {CornerRadius = UDim.new(0, 8)}, tabButton)
    self.Renderer:AddInteraction(tabButton, {BackgroundTransparency = 0.7, TextColor3 = self.Renderer.Theme.Text})

    local container = self.Renderer:Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 2,
        Parent = self.ContentContainer,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    self.Renderer:Create("UIListLayout", {Padding = UDim.new(0, 10), Parent = container})

    if #self.Tabs == 0 then
        container.Visible = true
        tabButton.BackgroundTransparency = 0.5
        tabButton.TextColor3 = self.Renderer.Theme.Text
    end

    tabButton.MouseButton1Click:Connect(function()
        for _, t in ipairs(self.Tabs) do
            t.Container.Visible = false
            t.Button.BackgroundTransparency = 0.9
            t.Button.TextColor3 = self.Renderer.Theme.SecondaryText
        end
        container.Visible = true
        tabButton.BackgroundTransparency = 0.5
        tabButton.TextColor3 = self.Renderer.Theme.Text
    end)

    local tabObj = setmetatable({Container = container, Button = tabButton, Renderer = self.Renderer}, Tab)
    table.insert(self.Tabs, tabObj)

    -- COMPONENT FACTORY
    function Tab:AddToggle(name, callback)
        local toggle = self.Renderer:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = self.Renderer.Theme.ComponentBG,
            BackgroundTransparency = 0.5,
            Parent = self.Container
        })
        self.Renderer:Create("UICorner", {CornerRadius = self.Renderer.Theme.CornerRadius}, toggle)

        self.Renderer:Create("TextLabel", {
            Text = name,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -60, 1, 0),
            BackgroundTransparency = 1,
            TextColor3 = self.Renderer.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            Parent = toggle
        })

        local button = self.Renderer:Create("TextButton", {
            Text = "",
            Position = UDim2.new(1, -45, 0.5, -12),
            Size = UDim2.new(0, 35, 0, 24),
            BackgroundColor3 = Color3.fromRGB(60, 60, 65),
            Parent = toggle
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(1, 0)}, button)

        local dot = self.Renderer:Create("Frame", {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0, 2, 0.5, -10),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = button
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)

        local state = false
        button.MouseButton1Click:Connect(function()
            state = not state
            self.Renderer:Tween(dot, 0.2, {Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)})
            self.Renderer:Tween(button, 0.2, {BackgroundColor3 = state and self.Renderer.Theme.Accent or Color3.fromRGB(60, 60, 65)})
            callback(state)
        end)
        return toggle
    end

    function Tab:AddSlider(name, min, max, default, callback)
        local slider = self.Renderer:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 55),
            BackgroundColor3 = self.Renderer.Theme.ComponentBG,
            BackgroundTransparency = 0.5,
            Parent = self.Container
        })
        self.Renderer:Create("UICorner", {CornerRadius = self.Renderer.Theme.CornerRadius}, slider)

        self.Renderer:Create("TextLabel", {
            Text = name,
            Position = UDim2.new(0, 12, 0, 8),
            Size = UDim2.new(1, -20, 0, 20),
            BackgroundTransparency = 1,
            TextColor3 = self.Renderer.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            Parent = slider
        })

        local valLabel = self.Renderer:Create("TextLabel", {
            Text = tostring(default),
            Position = UDim2.new(1, -50, 0, 8),
            Size = UDim2.new(0, 40, 0, 20),
            BackgroundTransparency = 1,
            TextColor3 = self.Renderer.Theme.SecondaryText,
            TextXAlignment = Enum.TextXAlignment.Right,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            Parent = slider
        })

        local track = self.Renderer:Create("Frame", {
            Position = UDim2.new(0, 12, 0, 38),
            Size = UDim2.new(1, -24, 0, 6),
            BackgroundColor3 = Color3.fromRGB(40, 40, 45),
            Parent = slider
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(1, 0)}, track)

        local fill = self.Renderer:Create("Frame", {
            Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = self.Renderer.Theme.Accent,
            Parent = track
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)

        local dragging = false
        local function move(input)
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * pos)
            valLabel.Text = tostring(val)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            callback(val)
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                move(input)
            end
        end)
        self.Renderer.Engine:Track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end))
        self.Renderer.Engine:Track(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then move(input) end
        end))
        return slider
    end

    function Tab:AddButton(name, callback)
        local btn = self.Renderer:Create("TextButton", {
            Text = name,
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = self.Renderer.Theme.ComponentBG,
            BackgroundTransparency = 0.5,
            TextColor3 = self.Renderer.Theme.Text,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            Parent = self.Container
        })
        self.Renderer:Create("UICorner", {CornerRadius = self.Renderer.Theme.CornerRadius}, btn)
        self.Renderer:AddInteraction(btn, {BackgroundTransparency = 0.3}, {BackgroundTransparency = 0.1})
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    function Tab:AddColorPicker(name, default, callback)
        local cp = self.Renderer:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = self.Renderer.Theme.ComponentBG,
            BackgroundTransparency = 0.5,
            Parent = self.Container
        })
        self.Renderer:Create("UICorner", {CornerRadius = self.Renderer.Theme.CornerRadius}, cp)

        self.Renderer:Create("TextLabel", {
            Text = name,
            Position = UDim2.new(0, 12, 0, 0),
            Size = UDim2.new(1, -60, 1, 0),
            BackgroundTransparency = 1,
            TextColor3 = self.Renderer.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            Parent = cp
        })

        local colorPreview = self.Renderer:Create("TextButton", {
            Text = "",
            Position = UDim2.new(1, -45, 0.5, -10),
            Size = UDim2.new(0, 35, 0, 20),
            BackgroundColor3 = default,
            Parent = cp
        })
        self.Renderer:Create("UICorner", {CornerRadius = UDim.new(0, 4)}, colorPreview)

        -- Logic for color selection would expand here (hiding a rainbow picker)
        colorPreview.MouseButton1Click:Connect(function()
            -- Mock color toggle
            local r, g, b = math.random(), math.random(), math.random()
            local newColor = Color3.new(r, g, b)
            colorPreview.BackgroundColor3 = newColor
            callback(newColor)
        end)
        return cp
    end

    return tabObj
end

function Components:CreateWindow(config)
    return Window.new(self.Renderer, config)
end

return Components
