local Engine = {}
Engine.__index = Engine

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

function Engine.new()
    local self = setmetatable({}, Engine)
    self.HighPerformance = true
    self.Objects = {}
    self.FPS = 60

    self:StartPerformanceMonitor()
    return self
end

function Engine:StartPerformanceMonitor()
    local lastTime = os.clock()
    local frameCount = 0

    self.MonitorConnection = RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        local currentTime = os.clock()

        if currentTime - lastTime >= 1 then
            self.FPS = frameCount / (currentTime - lastTime)

            -- Auto-detect performance
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
            elseif typeof(obj) == "RBXScriptConnection" then
                obj:Disconnect()
            end
        end)
    end
    table.clear(self.Objects)
end

function Engine:IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

return Engine
