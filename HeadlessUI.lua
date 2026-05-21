local HeadlessUI = {}
HeadlessUI.__index = HeadlessUI

-- IMPORTANT: This should be set to your raw GitHub content URL
local BASE_URL = "https://raw.githubusercontent.com/User/Repo/main/"

local function dynamic_fetch(moduleName)
    local success, result = pcall(function()
        -- Attempt to fetch from GitHub if BASE_URL is valid, otherwise use local require if available
        if BASE_URL:find("githubusercontent") then
            local code = game:HttpGet(BASE_URL .. moduleName .. ".lua")
            return loadstring(code)()
        else
            -- Fallback for local testing in Roblox Studio
            local folder = script.Parent
            local module = folder:FindFirstChild(moduleName)
            if module and module:IsA("ModuleScript") then
                return require(module)
            end
        end
    end)

    if success and result then
        return result
    else
        warn("[HeadlessUI] Failed to load module: " .. moduleName .. " | Error: " .. tostring(result))
        return nil
    end
end

function HeadlessUI.new()
    local self = setmetatable({}, HeadlessUI)

    -- Dynamically load modules
    self.EngineModule = dynamic_fetch("Engine")
    self.RendererModule = dynamic_fetch("Renderer")
    self.ComponentsModule = dynamic_fetch("Components")
    self.NotyfModule = dynamic_fetch("Notyf")

    if not (self.EngineModule and self.RendererModule and self.ComponentsModule and self.NotyfModule) then
        error("[HeadlessUI] Critical failure: Could not load all modules.")
    end

    self.Engine = self.EngineModule.new()
    self.Renderer = self.RendererModule.new(self.Engine)
    self.Components = self.ComponentsModule.new(self.Renderer)

    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "HeadlessUI"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.Parent = game:GetService("CoreGui")
    self.Engine:Track(self.ScreenGui)

    self.Notyf = self.NotyfModule.new(self.Renderer)
    self.Notyf.Container.Parent = self.ScreenGui

    return self
end

function HeadlessUI:SetPerformanceMode(high)
    self.Engine:SetPerformanceMode(high)
end

function HeadlessUI:CreateWindow(config)
    local win = self.Components:CreateWindow(config)
    win.Instance.Parent = self.ScreenGui
    return win
end

function HeadlessUI:Notify(title, message, duration)
    self.Notyf:Notify(title, message, duration)
end

function HeadlessUI:Destroy()
    self.Engine:Cleanup()
end

return HeadlessUI
