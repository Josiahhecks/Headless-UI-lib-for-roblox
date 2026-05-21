local Renderer = {}
Renderer.__index = Renderer

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

function Renderer.new(Engine)
    local self = setmetatable({}, Renderer)
    self.Engine = Engine
    self.Theme = {
        Background = Color3.fromRGB(25, 25, 25),
        Accent = Color3.fromRGB(0, 122, 255), -- iOS Blue
        Text = Color3.fromRGB(255, 255, 255),
        SecondaryText = Color3.fromRGB(150, 150, 150),
        GlassOpacity = 0.7,
        CornerRadius = UDim.new(0, 12)
    }
    self.Windows = {}
    return self
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

function Renderer:Tween(obj, duration, properties)
    if not self.Engine.HighPerformance then
        for k, v in pairs(properties) do
            obj[k] = v
        end
        return
    end

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(obj, tweenInfo, properties)
    tween:Play()
    return tween
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

        -- Snapping Logic
        if self.Engine.HighPerformance then
            local snapDistance = 20
            local viewportSize = workspace.CurrentCamera.ViewportSize

            -- Snap to Screen Edges
            if targetX < snapDistance then targetX = 0
            elseif targetX + frame.AbsoluteSize.X > viewportSize.X - snapDistance then
                targetX = viewportSize.X - frame.AbsoluteSize.X
            end

            if targetY < snapDistance then targetY = 0
            elseif targetY + frame.AbsoluteSize.Y > viewportSize.Y - snapDistance then
                targetY = viewportSize.Y - frame.AbsoluteSize.Y
            end

            -- Snap to Other Windows
            for _, other in ipairs(self.Windows) do
                if other ~= frame and other.Parent then
                    -- Simple offset-based snapping
                    local otherPos = other.AbsolutePosition
                    local otherSize = other.AbsoluteSize

                    if math.abs(targetX - (otherPos.X + otherSize.X)) < snapDistance then
                        targetX = otherPos.X + otherSize.X + 5
                    elseif math.abs((targetX + frame.AbsoluteSize.X) - otherPos.X) < snapDistance then
                        targetX = otherPos.X - frame.AbsoluteSize.X - 5
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
