local Renderer = {}
Renderer.__index = Renderer

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

Renderer.Themes = {
    ["iOS Dark"] = {
        Background = Color3.fromRGB(25, 25, 25),
        Accent = Color3.fromRGB(0, 122, 255),
        Text = Color3.fromRGB(255, 255, 255),
        SecondaryText = Color3.fromRGB(150, 150, 150),
        GlassOpacity = 0.7,
        CornerRadius = UDim.new(0, 12),
        ComponentBG = Color3.fromRGB(45, 45, 45)
    },
    ["Midnight"] = {
        Background = Color3.fromRGB(10, 10, 12),
        Accent = Color3.fromRGB(170, 0, 255),
        Text = Color3.fromRGB(255, 255, 255),
        SecondaryText = Color3.fromRGB(100, 100, 100),
        GlassOpacity = 0.8,
        CornerRadius = UDim.new(0, 8),
        ComponentBG = Color3.fromRGB(20, 20, 25)
    }
}

function Renderer.new(Engine)
    local self = setmetatable({}, Renderer)
    self.Engine = Engine
    self.Theme = Renderer.Themes["iOS Dark"]
    self.Windows = {}
    return self
end

function Renderer:SetTheme(themeName)
    if Renderer.Themes[themeName] then
        self.Theme = Renderer.Themes[themeName]
        -- Logic to update existing UI instances would go here
    end
end

function Renderer:Create(className, properties, parent)
    local obj = Instance.new(className)
    for k, v in pairs(properties) do
        obj[k] = v
    end
    if parent then
        obj.Parent = parent
    end
    self.Engine:Track(obj)
    return obj
end

function Renderer:Tween(obj, duration, properties, easing)
    if not self.Engine.HighPerformance then
        for k, v in pairs(properties) do
            obj[k] = v
        end
        return
    end

    local tweenInfo = TweenInfo.new(duration, easing or Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(obj, tweenInfo, properties)
    tween:Play()
    return tween
end

function Renderer:AddInteraction(obj, hoverProps, pressProps)
    local originalProps = {}
    for k, _ in pairs(hoverProps or pressProps) do
        originalProps[k] = obj[k]
    end

    self.Engine:Track(obj.MouseEnter:Connect(function()
        if hoverProps then self:Tween(obj, 0.2, hoverProps) end
    end))

    self.Engine:Track(obj.MouseLeave:Connect(function()
        self:Tween(obj, 0.2, originalProps)
    end))

    self.Engine:Track(obj.MouseButton1Down:Connect(function()
        if pressProps then self:Tween(obj, 0.1, pressProps) end
    end))

    self.Engine:Track(obj.MouseButton1Up:Connect(function()
        if hoverProps then self:Tween(obj, 0.2, hoverProps) else self:Tween(obj, 0.2, originalProps) end
    end))
end

function Renderer:MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos

    if frame.Name == "HeadlessWindow" then
        table.insert(self.Windows, frame)
    end

    local function update(input)
        local delta = input.Position - dragStart
        local targetX = startPos.X.Offset + delta.X
        local targetY = startPos.Y.Offset + delta.Y

        if self.Engine.HighPerformance then
            local snapDistance = 20
            local viewportSize = workspace.CurrentCamera.ViewportSize
            local absPos = frame.AbsolutePosition
            local absSize = frame.AbsoluteSize

            -- Screen edge snapping
            if math.abs(absPos.X + delta.X) < snapDistance then
                targetX = targetX - (absPos.X + delta.X)
            elseif math.abs((absPos.X + delta.X + absSize.X) - viewportSize.X) < snapDistance then
                targetX = targetX + (viewportSize.X - (absPos.X + delta.X + absSize.X))
            end

            if math.abs(absPos.Y + delta.Y) < snapDistance then
                targetY = targetY - (absPos.Y + delta.Y)
            elseif math.abs((absPos.Y + delta.Y + absSize.Y) - viewportSize.Y) < snapDistance then
                targetY = targetY + (viewportSize.Y - (absPos.Y + delta.Y + absSize.Y))
            end

            -- Window snapping
            for _, other in ipairs(self.Windows) do
                if other ~= frame and other.Parent then
                    local otherPos = other.AbsolutePosition
                    local otherSize = other.AbsoluteSize

                    -- Horizontal snap to other window
                    if math.abs((absPos.X + delta.X) - (otherPos.X + otherSize.X)) < snapDistance then
                        targetX = targetX - ((absPos.X + delta.X) - (otherPos.X + otherSize.X + 5))
                    elseif math.abs((absPos.X + delta.X + absSize.X) - otherPos.X) < snapDistance then
                        targetX = targetX - ((absPos.X + delta.X + absSize.X) - (otherPos.X - 5))
                    end
                end
            end
        end

        frame.Position = UDim2.new(startPos.X.Scale, targetX, startPos.Y.Scale, targetY)
    end

    self.Engine:Track(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end))

    self.Engine:Track(handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    self.Engine:Track(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end))
end

function Renderer:ApplyGlassEffect(frame)
    if frame:IsA("CanvasGroup") then
        frame.GroupTransparency = 1 - self.Theme.GlassOpacity
    end
    frame.BackgroundColor3 = self.Theme.Background
    frame.BackgroundTransparency = 1 - self.Theme.GlassOpacity

    self:Create("UICorner", {
        CornerRadius = self.Theme.CornerRadius
    }, frame)

    self:Create("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 0.8,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, frame)
end

return Renderer
