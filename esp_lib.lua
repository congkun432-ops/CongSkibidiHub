

local ESP = {}

local CloneRef = cloneref or function(O) return O end
local Players        = CloneRef(game:GetService("Players"))
local Workspace      = CloneRef(workspace)
local RunService     = CloneRef(game:GetService("RunService"))
local TweenService   = CloneRef(game:GetService("TweenService"))
local UserInputService = CloneRef(game:GetService("UserInputService"))
local LocalPlayer    = Players.LocalPlayer

-- ============================================================
-- STATE
-- ============================================================
ESP.Font                 = Enum.Font.RobotoCondensed
ESP.Rainbow              = false
ESP.Tracers              = true
ESP.Unloaded             = false
ESP.ShowDistance         = true
ESP.MatchColors          = true
ESP.Arrows               = false
ESP.TextTransparency     = 0
ESP.TracerOrigin         = "Top"
ESP.FillTransparency     = 0.75
ESP.OutlineTransparency  = 0
ESP.TextOutlineTransparency = 0
ESP.FadeTime             = 0
ESP.RenderLimit          = 240
ESP.TracerSize           = 0.5
ESP.ArrowRadius          = 200
ESP.TextSize             = 10
ESP.DistanceSizeRatio    = 1
ESP.OutlineColor         = Color3.fromRGB(255, 255, 255)
ESP.RainbowColor         = Color3.fromRGB(255, 255, 255)
ESP.ElementsEnabled      = {}
ESP.TransparencyEnabled  = {}
ESP.Highlights           = {}
ESP.Labels               = {}
ESP.Frames               = {}
ESP.Lines                = {}
ESP.ArrowsTable          = {}
ESP.ColorTable           = {}
ESP.TextTable            = {}
ESP.ConnectionsTable     = {}
ESP.Objects              = {}
ESP.TotalObjects         = {}

local RainbowState = { HueSetup = 0, Hue = 0, Step = 0, Color = Color3.new() }

-- ============================================================
-- UI
-- ============================================================
local function GetHiddenUI()
    if gethui then return gethui() end
    local Folder = Instance.new("Folder", CloneRef(game:GetService("CoreGui")))
    Folder.Name = ("%032x"):format(math.random(0, 2^31))
    return Folder
end
local HiddenUI = GetHiddenUI()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Name = "ESP_" .. tostring(math.random(1, 999999))
ScreenGui.Parent = HiddenUI

local HighlightsFolder = Instance.new("Folder", ScreenGui)
local BillboardsFolder = Instance.new("Folder", ScreenGui)

local TracersFrame = Instance.new("Frame", ScreenGui)
TracersFrame.Size = UDim2.fromScale(1, 1)
TracersFrame.BackgroundTransparency = 1
TracersFrame.Visible = false

local ArrowsFrame = Instance.new("Frame", ScreenGui)
ArrowsFrame.Size = UDim2.fromScale(1, 1)
ArrowsFrame.BackgroundTransparency = 1
ArrowsFrame.Visible = false

local EntityAlertLabel = Instance.new("TextLabel")
EntityAlertLabel.Name = "EntityAlertLabel"
EntityAlertLabel.Size = UDim2.fromScale(1, 0.08)
EntityAlertLabel.Position = UDim2.fromScale(0, 0.12)
EntityAlertLabel.BackgroundTransparency = 1
EntityAlertLabel.Text = ""
EntityAlertLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
EntityAlertLabel.TextStrokeTransparency = 0
EntityAlertLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
EntityAlertLabel.TextTransparency = 1
EntityAlertLabel.Font = Enum.Font.RobotoCondensed
EntityAlertLabel.TextSize = 32
EntityAlertLabel.RichText = true
EntityAlertLabel.ZIndex = 999
EntityAlertLabel.Parent = ScreenGui

local ArrowTemplate = Instance.new("ImageLabel")
ArrowTemplate.Image = "rbxassetid://16368985219"
ArrowTemplate.Size = UDim2.fromOffset(50, 50)
ArrowTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
ArrowTemplate.BackgroundTransparency = 1
ArrowTemplate.ImageTransparency = 1

local function MakeTween(I, P) return TweenService:Create(I, TweenInfo.new(ESP.FadeTime, Enum.EasingStyle.Quad), P) end
local function PlayTween(I, P) MakeTween(I, P):Play() end

-- ============================================================
-- INTERNAL HELPERS
-- ============================================================
local function DestroyObjectData(Object)
    if ESP.Highlights[Object] then ESP.Highlights[Object]:Destroy(); ESP.Highlights[Object] = nil end
    if ESP.Frames[Object] then ESP.Frames[Object]:Destroy(); ESP.Frames[Object] = nil end
    if ESP.Lines[Object] then if ESP.Lines[Object][1] then ESP.Lines[Object][1]:Destroy() end ESP.Lines[Object] = nil end
    if ESP.ArrowsTable[Object] then ESP.ArrowsTable[Object]:Destroy(); ESP.ArrowsTable[Object] = nil end
    if ESP.ConnectionsTable[Object] then for _, C in ipairs(ESP.ConnectionsTable[Object]) do C:Disconnect() end ESP.ConnectionsTable[Object] = nil end
    ESP.Labels[Object] = nil
    ESP.ColorTable[Object] = nil
    ESP.TextTable[Object] = nil
    ESP.ElementsEnabled[Object] = nil
    ESP.TransparencyEnabled[Object] = nil
    ESP.Objects[Object] = nil
    for I = #ESP.TotalObjects, 1, -1 do
        if ESP.TotalObjects[I] == Object then table.remove(ESP.TotalObjects, I); break end
    end
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function ESP:AddESP(Params)
    local Object = Params.Object
    if ESP.ElementsEnabled[Object] or ESP.Unloaded then return end
    if not Object:IsA("BasePart") and not Object:IsA("Model") then return end

    ESP.ElementsEnabled[Object] = true
    ESP.TransparencyEnabled[Object] = false
    ESP.ConnectionsTable[Object] = ESP.ConnectionsTable[Object] or {}
    if ESP.Highlights[Object] then ESP.Highlights[Object]:Destroy() end

    local Highlight = Instance.new("Highlight")
    Highlight.FillTransparency = 1
    Highlight.OutlineTransparency = 1
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.Adornee = Object
    Highlight.Parent = HighlightsFolder
    ESP.Highlights[Object] = Highlight

    local TextFrame = Instance.new("Frame")
    TextFrame.Visible = false
    TextFrame.Size = UDim2.fromScale(1, 1)
    TextFrame.BackgroundTransparency = 1
    TextFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    TextFrame.Parent = BillboardsFolder

    local TextLabel = Instance.new("TextLabel")
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = Params.Text
    TextLabel.TextTransparency = 1
    TextLabel.TextStrokeTransparency = ESP.TextOutlineTransparency
    TextLabel.Size = UDim2.fromScale(1, 1)
    TextLabel.Font = ESP.Font
    TextLabel.TextSize = ESP.TextSize
    TextLabel.RichText = true
    TextLabel.TextColor3 = Params.Color
    TextLabel.Parent = TextFrame

    ESP.Frames[Object] = TextFrame
    ESP.Labels[Object] = TextLabel
    ESP.ColorTable[Object] = Params.Color
    ESP.TextTable[Object] = Params.Text
    ESP.Objects[Object] = Object
    table.insert(ESP.TotalObjects, Object)

    PlayTween(Highlight, { FillTransparency = ESP.FillTransparency })
    PlayTween(Highlight, { OutlineTransparency = ESP.OutlineTransparency })
    local Fade = MakeTween(TextLabel, { TextTransparency = ESP.TextTransparency })
    Fade.Completed:Once(function() ESP.TransparencyEnabled[Object] = true end)
    Fade:Play()

    local LineFrame = Instance.new("Frame")
    LineFrame.Size = UDim2.fromOffset(0, 0)
    LineFrame.BackgroundTransparency = 1
    LineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    LineFrame.Parent = TracersFrame

    local Stroke = Instance.new("UIStroke", LineFrame)
    Stroke.Thickness = ESP.TracerSize
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Transparency = 1

    PlayTween(LineFrame, { BackgroundTransparency = 0 })
    PlayTween(Stroke, { Transparency = 0 })
    ESP.Lines[Object] = { LineFrame, Stroke }

    task.spawn(function()
        local Last = 0
        local function Render()
            local Camera = Workspace.CurrentCamera
            if not Camera then return end
            if not Object or not Object:IsDescendantOf(game) then ESP:RemoveESP(Object); return end
            local ObjPos = Object:GetPivot().Position
            local SP, OnScreen = Camera:WorldToViewportPoint(ObjPos)
            local Frame = ESP.Frames[Object]
            local Label = ESP.Labels[Object]
            local HL = ESP.Highlights[Object]
            local Line = ESP.Lines[Object]

            if Line and Line[1] then Line[1].Visible = OnScreen end
            if Frame then
                Frame.Visible = OnScreen
                if OnScreen then Frame.Position = UDim2.fromOffset(SP.X, SP.Y) end
            end
            if not OnScreen then
                if HL then HL:Destroy(); ESP.Highlights[Object] = nil; HL = nil end
            elseif ESP.ElementsEnabled[Object] and not HL then
                HL = Instance.new("Highlight")
                HL.FillTransparency = 1
                HL.OutlineTransparency = 1
                HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                HL.Adornee = Object
                HL.Parent = HighlightsFolder
                ESP.Highlights[Object] = HL
            end

            local ActiveColor = ESP.Rainbow and RainbowState.Color or ESP.ColorTable[Object] or Color3.new(1, 1, 1)
            if Label then Label.TextColor3 = ActiveColor end

            if HL then
                local Distance = math.floor((Camera.CFrame.Position - ObjPos).Magnitude)
                local DText = ESP.ShowDistance and ("\n<font size='" .. math.round(ESP.TextSize * ESP.DistanceSizeRatio) .. "'>[" .. Distance .. "]</font>") or ""
                if Label then Label.Text = ESP.TextTable[Object] .. DText end
                HL.Enabled = true
                HL.FillColor = ActiveColor
                HL.OutlineColor = ESP.MatchColors and ActiveColor or ESP.OutlineColor
                if ESP.TransparencyEnabled[Object] then
                    HL.FillTransparency = ESP.FillTransparency
                    HL.OutlineTransparency = ESP.OutlineTransparency
                    if Label then
                        Label.TextTransparency = ESP.TextTransparency
                        Label.TextStrokeTransparency = ESP.TextOutlineTransparency
                    end
                end
            end

            if Line and HL and ESP.Tracers and OnScreen then
                local SS = Camera.ViewportSize
                local Origin
                if ESP.TracerOrigin == "Center" then
                    Origin = Vector2.new(SS.X / 2, SS.Y / 2)
                elseif ESP.TracerOrigin == "Top" then
                    Origin = Vector2.new(SS.X / 2, 0)
                elseif ESP.TracerOrigin == "Mouse" then
                    local M = UserInputService:GetMouseLocation()
                    Origin = Vector2.new(M.X, M.Y)
                else
                    Origin = Vector2.new(SS.X / 2, SS.Y)
                end
                local Dest = Vector2.new(SP.X, SP.Y)
                local Mid = (Origin + Dest) / 2
                local Rot = math.deg(math.atan2(Dest.Y - Origin.Y, Dest.X - Origin.X))
                local Len = (Origin - Dest).Magnitude
                Line[1].Position = UDim2.fromOffset(Mid.X, Mid.Y)
                Line[1].Size = UDim2.fromOffset(Len, 1)
                Line[1].Rotation = Rot
                Line[1].BackgroundColor3 = ActiveColor
                Line[1].BorderSizePixel = 0
                Line[1].Visible = true
                Line[2].Color = ActiveColor
                Line[2].Thickness = ESP.TracerSize
            end

            if ESP.Arrows then
                local Arrow = ESP.ArrowsTable[Object]
                if not Arrow and ESP.ElementsEnabled[Object] then
                    Arrow = ArrowTemplate:Clone()
                    Arrow.Parent = ArrowsFrame
                    ESP.ArrowsTable[Object] = Arrow
                    PlayTween(Arrow, { ImageTransparency = 0 })
                elseif Arrow and ESP.ElementsEnabled[Object] then
                    if OnScreen and SP.Z > 0 then
                        Arrow.Visible = false
                    else
                        local SS = Camera.ViewportSize
                        local C = Vector2.new(SS.X / 2, SS.Y / 2)
                        local ToObj = (ObjPos - Camera.CFrame.Position).Unit
                        local Dir = Vector2.new(SP.X, SP.Y) - C
                        if Camera.CFrame.LookVector:Dot(ToObj) < 0 then Dir = -Dir end
                        local Ang = math.atan2(Dir.Y, Dir.X)
                        local Rad = math.min(SS.X, SS.Y) / 2 - (400 - ESP.ArrowRadius)
                        local AP = C + Dir.Unit * Rad
                        Arrow.Position = UDim2.fromOffset(AP.X, AP.Y)
                        Arrow.Rotation = math.deg(Ang) - 90
                        Arrow.Visible = true
                        Arrow.ImageColor3 = ESP.Rainbow and ESP.RainbowColor or ESP.ColorTable[Object]
                    end
                end
            end
        end

        local Conn
        Conn = RunService.Heartbeat:Connect(function(Dt)
            Last = Last + Dt
            if Last >= 1 / ESP.RenderLimit then
                Last = 0
                if not ESP.ElementsEnabled[Object] then Conn:Disconnect(); return end
                Render()
            end
        end)
        table.insert(ESP.ConnectionsTable[Object], Conn)
    end)
end

function ESP:RemoveESP(Object)
    if ESP.Unloaded or not ESP.ElementsEnabled[Object] then return end
    ESP.ElementsEnabled[Object] = false
    ESP.TransparencyEnabled[Object] = false
    if ESP.Labels[Object] then PlayTween(ESP.Labels[Object], { TextTransparency = 1 }) end
    if ESP.Lines[Object] then
        PlayTween(ESP.Lines[Object][1], { BackgroundTransparency = 1 })
        PlayTween(ESP.Lines[Object][2], { Transparency = 1 })
    end
    if ESP.Highlights[Object] then
        PlayTween(ESP.Highlights[Object], { FillTransparency = 1 })
        PlayTween(ESP.Highlights[Object], { OutlineTransparency = 1 })
    end
    if ESP.ArrowsTable[Object] then PlayTween(ESP.ArrowsTable[Object], { ImageTransparency = 1 }) end
    task.delay(ESP.FadeTime + 0.05, function()
        if ESP.ElementsEnabled[Object] == false then DestroyObjectData(Object) end
    end)
end

function ESP:UpdateObjectColor(Object, Color)
    ESP.ColorTable[Object] = Color
    if ESP.Labels[Object] and not ESP.Rainbow then ESP.Labels[Object].TextColor3 = Color end
end

function ESP:SetTextSize(V)
    ESP.TextSize = V
    for _, L in pairs(ESP.Labels) do L.TextSize = V end
end

function ESP:SetTracers(Enabled)
    ESP.Tracers = Enabled
    TracersFrame.Visible = Enabled
end

function ESP:Unload()
    if ESP.Unloaded then return end
    ESP.Unloaded = true
    for _, C in pairs(ESP.ConnectionsTable) do
        for _, Conn in ipairs(C) do Conn:Disconnect() end
    end
    local objs = {}
    for O in pairs(ESP.Objects) do table.insert(objs, O) end
    for _, O in ipairs(objs) do DestroyObjectData(O) end
    if RainbowConnection then RainbowConnection:Disconnect() end
    if EntityAlertConnection then EntityAlertConnection:Disconnect() end
    ScreenGui.Enabled = false
end

-- ============================================================
-- RAINBOW
-- ============================================================
local RainbowConnection = RunService.RenderStepped:Connect(function(Dt)
    RainbowState.Step = RainbowState.Step + Dt
    if RainbowState.Step >= 1 / 60 then
        RainbowState.Step = 0
        RainbowState.HueSetup = RainbowState.HueSetup + 1 / 400
        if RainbowState.HueSetup > 1 then RainbowState.HueSetup = 0 end
        RainbowState.Hue = RainbowState.HueSetup
        RainbowState.Color = Color3.fromHSV(RainbowState.Hue, 0.8, 1)
        ESP.RainbowColor = RainbowState.Color
    end
end)

-- ============================================================
-- ENTITY ALERT
-- ============================================================
local ActiveEntityAlerts = {}
local LastAlertUpdate    = 0
local LastAlertText      = ""
local AlertVisible       = false
local CurrentAlertTween  = nil

local AlertWhitelist = {
    ["RushMoving"]   = true,
    ["AmbushMoving"] = true,
}

local function CancelAlertTween()
    if CurrentAlertTween then
        pcall(function() CurrentAlertTween:Cancel() end)
        CurrentAlertTween = nil
    end
end

function ESP:AddEntityAlert(Entity, Alias)
    if not AlertWhitelist[Entity.Name] then return end
    ActiveEntityAlerts[Entity] = { Alias = Alias }
    Entity.Destroying:Once(function()
        ActiveEntityAlerts[Entity] = nil
    end)
end

function ESP:ClearEntityAlerts()
    ActiveEntityAlerts = {}
end

function ESP:RefreshEntityAlertLabel()
    for Entity in pairs(ActiveEntityAlerts) do
        if not Entity or not Entity.Parent or not Entity:IsDescendantOf(Workspace) then
            ActiveEntityAlerts[Entity] = nil
        end
    end
    local Entries = {}
    local Char = LocalPlayer.Character
    local RootPart = Char and Char:FindFirstChild("HumanoidRootPart")
    local Cam = Workspace.CurrentCamera
    local RefPos = (RootPart and RootPart.Position) or (Cam and Cam.CFrame.Position) or Vector3.zero
    for Entity, Data in pairs(ActiveEntityAlerts) do
        local Pos
        if Entity.PrimaryPart then
            Pos = Entity.PrimaryPart.Position
        else
            local Ok, P = pcall(function() return Entity:GetPivot().Position end)
            if Ok then Pos = P end
        end
        if Pos then
            local Dist = math.floor((RefPos - Pos).Magnitude)
            table.insert(Entries, { Alias = Data.Alias, Dist = Dist })
        end
    end
    table.sort(Entries, function(a, b) return a.Dist < b.Dist end)
    if #Entries == 0 then
        if AlertVisible then
            AlertVisible = false
            LastAlertText = ""
            CancelAlertTween()
            CurrentAlertTween = TweenService:Create(EntityAlertLabel,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { TextTransparency = 1, TextStrokeTransparency = 1 })
            CurrentAlertTween.Completed:Once(function()
                if not AlertVisible then EntityAlertLabel.Text = "" end
            end)
            CurrentAlertTween:Play()
        end
        return
    end
    local AliasParts, DistParts = {}, {}
    for _, E in ipairs(Entries) do
        table.insert(AliasParts, string.lower(E.Alias))
        table.insert(DistParts, E.Dist .. "m")
    end
    local NewText = "⚠ " .. table.concat(AliasParts, "--") .. " ⚠\n" .. table.concat(DistParts, "--")
    if NewText ~= LastAlertText then
        LastAlertText = NewText
        EntityAlertLabel.Text = NewText
    end
    if not AlertVisible then
        AlertVisible = true
        CancelAlertTween()
        EntityAlertLabel.TextTransparency = 1
        EntityAlertLabel.TextStrokeTransparency = 1
        CurrentAlertTween = TweenService:Create(EntityAlertLabel,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { TextTransparency = 0, TextStrokeTransparency = 0 })
        CurrentAlertTween:Play()
    end
end

local EntityAlertConnection = RunService.Heartbeat:Connect(function()
    local Now = tick()
    if Now - LastAlertUpdate < 0.1 then return end
    LastAlertUpdate = Now
    ESP:RefreshEntityAlertLabel()
end)

-- ============================================================
getgenv().ESPLibrary = ESP
return ESP
