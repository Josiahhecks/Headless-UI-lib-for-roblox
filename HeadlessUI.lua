local HeadlessUI = {}
HeadlessUI.__index = HeadlessUI

-- SET TO YOUR RAW GITHUB BASE URL
local BASE_URL = "https://raw.githubusercontent.com/User/Repo/main/"

local function dynamic_fetch(moduleName)
    local success, result = pcall(function()
        if BASE_URL:find("githubusercontent") then
            local code = game:HttpGet(BASE_URL .. moduleName .. ".lua")
            return loadstring(code)()
        else
            local folder = script.Parent
            local module = folder:FindFirstChild(moduleName)
            if module then return require(module) end
        end
    end)
    return success and result or nil
end

function HeadlessUI.new()
    local self = setmetatable({}, HeadlessUI)

    self.EngineModule = dynamic_fetch("Engine")
    self.RendererModule = dynamic_fetch("Renderer")
    self.ComponentsModule = dynamic_fetch("Components")
    self.NotyfModule = dynamic_fetch("Notyf")

    if not (self.EngineModule and self.RendererModule and self.ComponentsModule and self.NotyfModule) then
        error("[HeadlessUI] CRITICAL: Failed to initialize modules.")
    end

    self.Engine = self.EngineModule.new()
    self.Renderer = self.RendererModule.new(self.Engine)
    self.Components = self.ComponentsModule.new(self.Renderer)

    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "HeadlessUI_Core"
    self.ScreenGui.DisplayOrder = 100
    self.ScreenGui.Parent = game:GetService("CoreGui")
    self.Engine:Track(self.ScreenGui)

    self.Notyf = self.NotyfModule.new(self.Renderer)
    self.Notyf.Container.Parent = self.ScreenGui

    return self
end

function HeadlessUI:CreateWindow(config)
    local win = self.Components:CreateWindow(config)
    win.Instance.Parent = self.ScreenGui
    return win
end

function HeadlessUI:Notify(title, message, duration)
    self.Notyf:Notify(title, message, duration)
end

function HeadlessUI:SetPerformanceMode(enabled)
    self.Engine:SetPerformanceMode(enabled)
end

function HeadlessUI:Destroy()
    self.Engine:Cleanup()
end

return HeadlessUI
