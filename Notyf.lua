local Notyf = {}
Notyf.__index = Notyf

local TextService = game:GetService("TextService")

function Notyf.new(Renderer)
    local self = setmetatable({}, Notyf)
    self.Renderer = Renderer
    self.Position = "TopRight"

    self.Container = Renderer:Create("Frame", {
        Name = "NotyfContainer",
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(1, -310, 0, 10),
        BackgroundTransparency = 1,
        Parent = game:GetService("CoreGui"):FindFirstChild("HeadlessUI")
    })

    Renderer:Create("UIListLayout", {
        VerticalAlignment = Enum.VerticalAlignment.Top,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 10),
        Parent = self.Container
    })

    return self
end

function Notyf:Notify(title, message, duration)
    duration = duration or 5

    -- Calculate height based on message
    local font = Enum.Font.Gotham
    local fontSize = 12
    local maxWidth = 280
    local textBounds = TextService:GetTextSize(message, fontSize, font, Vector2.new(maxWidth, 1000))
    local height = math.max(60, textBounds.Y + 40)

    local notification = self.Renderer:Create("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = self.Renderer.Theme.Background,
        GroupTransparency = 1,
        ClipsDescendants = true,
        Parent = self.Container
    })
    self.Renderer:ApplyGlassEffect(notification)

    self.Renderer:Create("TextLabel", {
        Text = title,
        Position = UDim2.new(0, 10, 0, 5),
        Size = UDim2.new(1, -20, 0, 20),
        BackgroundTransparency = 1,
        TextColor3 = self.Renderer.Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })

    self.Renderer:Create("TextLabel", {
        Text = message,
        Position = UDim2.new(0, 10, 0, 25),
        Size = UDim2.new(1, -20, 0, textBounds.Y),
        BackgroundTransparency = 1,
        TextColor3 = self.Renderer.Theme.Text,
        Font = font,
        TextSize = fontSize,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })

    -- Animate In
    self.Renderer:Tween(notification, 0.3, {Size = UDim2.new(1, 0, 0, height), GroupTransparency = 0})

    task.delay(duration, function()
        if notification and notification.Parent then
            self.Renderer:Tween(notification, 0.3, {Size = UDim2.new(1, 0, 0, 0), GroupTransparency = 1})
            task.wait(0.3)
            notification:Destroy()
        end
    end)
end

return Notyf
