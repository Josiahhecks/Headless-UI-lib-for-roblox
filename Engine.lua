local Engine = {}
Engine.__index = Engine

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Internal Signal Class for robust event handling
local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({}, Signal)
    self._connections = {}
    return self
end

function Signal:Connect(fn)
    local connection = {
        _fn = fn,
        _connected = true,
        Disconnect = function(c)
            c._connected = false
            for i, conn in ipairs(self._connections) do
                if conn == c then
                    table.remove(self._connections, i)
                    break
                end
            end
        end
    }
    table.insert(self._connections, connection)
    return connection
end

function Signal:Fire(...)
    for _, conn in ipairs(self._connections) do
        if conn._connected then
            task.spawn(conn._fn, ...)
        end
    end
end

Engine.Signal = Signal

function Engine.new()
    local self = setmetatable({}, Engine)
    self.HighPerformance = true
    self.Objects = {}
    self.FPS = 60
    self.State = {}
    self.InputManager = {
        KeysDown = {},
        MousePos = Vector2.new()
    }

    self:StartPerformanceMonitor()
    self:InitInputManager()
    return self
end

function Engine:InitInputManager()
    self:Track(UserInputService.InputBegan:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            self.InputManager.KeysDown[input.KeyCode] = true
        end
    end))

    self:Track(UserInputService.InputEnded:Connect(function(input, gpe)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            self.InputManager.KeysDown[input.KeyCode] = false
        end
    end))
end

function Engine:StartPerformanceMonitor()
    local lastTime = os.clock()
    local frameCount = 0

    self.MonitorConnection = RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        local currentTime = os.clock()

        if currentTime - lastTime >= 1 then
            self.FPS = frameCount / (currentTime - lastTime)

            if self.FPS < 30 and self.HighPerformance then
                print("[HeadlessUI] Low performance detected (" .. math.floor(self.FPS) .. " FPS). Switching to Lite Mode.")
                self:SetPerformanceMode(false)
            end

            frameCount = 0
            lastTime = currentTime
        end
    end)
end

function Engine:SetPerformanceMode(high)
    self.HighPerformance = high
    if not high then
        for _, obj in ipairs(self.Objects) do
            if typeof(obj) == "Instance" and obj:IsA("CanvasGroup") then
                obj.GroupTransparency = 0
            end
        end
    end
end

function Engine:Track(object)
    table.insert(self.Objects, object)
    return object
end

function Engine:Cleanup()
    if self.MonitorConnection then
        self.MonitorConnection:Disconnect()
    end

    for _, obj in ipairs(self.Objects) do
        pcall(function()
            if typeof(obj) == "Instance" then
                obj:Destroy()
            elseif typeof(obj) == "RBXScriptConnection" or (typeof(obj) == "table" and obj.Disconnect) then
                obj:Disconnect()
            end
        end)
    end
    table.clear(self.Objects)
end

return Engine
