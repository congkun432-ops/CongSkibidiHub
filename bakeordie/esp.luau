--[[ esp.luau : chỉ chứa ESP. Được mainbake.luau tải và gọi với Env. ]]

return function(Env)
    local Players, LocalPlayer, Window = Env.Players, Env.LocalPlayer, Env.Window
    local SetLoop, OnUnload, GetCharacter, T = Env.SetLoop, Env.OnUnload, Env.GetCharacter, Env.T

    local ESP = {
        Player = false, Zombie = false, Item = false, Body = false, Chest = false,
        Names = true, Distance = true, Highlight = true, MaxDistance = 1000,
    }

    local ESP_INTERVAL = 0.25
    local MAX_HIGHLIGHTS = 30

    local ESPColors = {
        Player = Color3.fromRGB(80, 170, 255),
        Zombie = Color3.fromRGB(255, 50, 50),
        Item = Color3.fromRGB(50, 255, 50),
        Body = Color3.fromRGB(255, 165, 0),
        Chest = Color3.fromRGB(255, 215, 0),
    }

    local ESPHolder
    do
        local Ok, Result = pcall(function()
            local Folder = Instance.new("Folder")
            Folder.Name = "MonsterHubESP"
            Folder.Parent = (gethui and gethui()) or game:GetService("CoreGui")
            return Folder
        end)
        if Ok then
            ESPHolder = Result
        else
            ESPHolder = Instance.new("Folder")
            ESPHolder.Name = "MonsterHubESP"
            ESPHolder.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
    end

    local ESPEntries = {}

    local function DestroyEntry(Object)
        local Entry = ESPEntries[Object]
        if not Entry then return end
        ESPEntries[Object] = nil
        if Entry.Billboard then Entry.Billboard:Destroy() end
        if Entry.Highlight then Entry.Highlight:Destroy() end
    end

    local function GetESPPart(Object)
        if Object:IsA("BasePart") then return Object end
        return Object:FindFirstChild("HumanoidRootPart")
            or Object.PrimaryPart
            or Object:FindFirstChild("Head")
            or Object:FindFirstChildWhichIsA("BasePart", true)
    end

    local function EnsureEntry(Object, Part, Color)
        local Entry = ESPEntries[Object]
        if Entry and Entry.Part == Part and Entry.Billboard.Parent then return Entry end
        DestroyEntry(Object)

        local Billboard = Instance.new("BillboardGui")
        Billboard.Name = "ESPText"
        Billboard.Adornee = Part
        Billboard.Size = UDim2.new(0, 200, 0, 40)
        Billboard.StudsOffset = Vector3.new(0, 3, 0)
        Billboard.AlwaysOnTop = true
        Billboard.Parent = ESPHolder

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color
        Label.TextSize = 14
        Label.Font = Enum.Font.GothamBold
        Label.TextStrokeTransparency = 0
        Label.TextStrokeColor3 = Color3.new(0, 0, 0)
        Label.Parent = Billboard

        local Highlight = Instance.new("Highlight")
        Highlight.Name = "ESPHighlight"
        Highlight.Adornee = Object:IsA("Model") and Object or Part
        Highlight.FillColor = Color
        Highlight.OutlineColor = Color3.new(1, 1, 1)
        Highlight.FillTransparency = 0.4
        Highlight.OutlineTransparency = 0
        Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        Highlight.Enabled = false
        Highlight.Parent = ESPHolder

        Entry = { Part = Part, Billboard = Billboard, Label = Label, Highlight = Highlight }
        ESPEntries[Object] = Entry
        return Entry
    end

    local function CollectESPTargets(Root)
        local Targets = {}

        local function Add(Object, Kind, Name)
            local Part = GetESPPart(Object)
            if not Part then return end
            local Distance = (Part.Position - Root.Position).Magnitude
            if Distance > ESP.MaxDistance then return end
            table.insert(Targets, {
                Object = Object,
                Part = Part,
                Color = ESPColors[Kind],
                Kind = Kind,
                Name = Name,
                Distance = Distance,
            })
        end

        if ESP.Player then
            for _, Other in ipairs(Players:GetPlayers()) do
                local Character = Other ~= LocalPlayer and Other.Character
                local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                if Character and (not Humanoid or Humanoid.Health > 0) then
                    Add(Character, "Player", Other.DisplayName)
                end
            end
        end

        if ESP.Zombie then
            local Folder = workspace:FindFirstChild("Monsters")
            if Folder then
                for _, Monster in ipairs(Folder:GetChildren()) do
                    if Monster:IsA("Model") then
                        local Humanoid = Monster:FindFirstChildOfClass("Humanoid")
                        if not Humanoid or Humanoid.Health > 0 then
                            Add(Monster, "Zombie", Monster.Name)
                        end
                    end
                end
            end
        end

        if ESP.Item or ESP.Body then
            local Folder = workspace:FindFirstChild("Interactables")
            if Folder then
                for _, Object in ipairs(Folder:GetChildren()) do
                    if (Object:IsA("Model") or Object:IsA("BasePart"))
                        and not Object:FindFirstChild("ProductPriceTag") then
                        local IsBody = Object:FindFirstChild("HumanoidRootPart") ~= nil
                        if IsBody and ESP.Body then
                            Add(Object, "Body", Object.Name)
                        elseif not IsBody and ESP.Item then
                            Add(Object, "Item", Object.Name)
                        end
                    end
                end
            end
        end

        if ESP.Chest then
            local Containers = workspace:FindFirstChild("Containers")
            if Containers then
                for _, Container in ipairs(Containers:GetChildren()) do
                    if Container:IsA("Model") or Container:IsA("BasePart") then
                        Add(Container, "Chest", Container.Name)
                    end
                end
            end
        end

        return Targets
    end

    local function ClearAll()
        for Object in pairs(ESPEntries) do DestroyEntry(Object) end
    end

    local function UpdateESP()
        local Anything = ESP.Player or ESP.Zombie or ESP.Item or ESP.Body or ESP.Chest
        local _, _, Root = GetCharacter()
        if not (Anything and Root) then
            ClearAll()
            return
        end

        local Targets = CollectESPTargets(Root)
        table.sort(Targets, function(A, B) return A.Distance < B.Distance end)

        local Seen = {}
        for Index, Target in ipairs(Targets) do
            Seen[Target.Object] = true
            local Entry = EnsureEntry(Target.Object, Target.Part, Target.Color)

            local Label = T("esp.tag." .. Target.Kind, Target.Name)
            local Studs = T("esp.studs", math.floor(Target.Distance))
            local Content
            if ESP.Names and ESP.Distance then
                Content = Label .. "\n" .. Studs
            elseif ESP.Names then
                Content = Label
            elseif ESP.Distance then
                Content = Studs
            end
            Entry.Billboard.Enabled = Content ~= nil
            Entry.Label.Text = Content or ""
            Entry.Highlight.Enabled = ESP.Highlight and Index <= MAX_HIGHLIGHTS
        end

        for Object in pairs(ESPEntries) do
            if not Seen[Object] then DestroyEntry(Object) end
        end
    end

    local function RefreshESP()
        local Any = ESP.Player or ESP.Zombie or ESP.Item or ESP.Body or ESP.Chest
        SetLoop("esp", Any, ESP_INTERVAL, UpdateESP)
        if not Any then ClearAll() end
    end

    OnUnload(function()
        SetLoop("esp", false)
        ClearAll()
        if ESPHolder then ESPHolder:Destroy() end
    end)

    local ESPTab = Window:CreateTab(T("tab.esp"))
    local function Toggle(Key, Name, Flag)
        ESPTab:AddSwitch(T(Name), false, function(Enabled)
            ESP[Key] = Enabled
            RefreshESP()
        end, Flag)
    end
    Toggle("Player", "esp.player", "esp_player")
    Toggle("Zombie", "esp.zombie", "esp_zombie")
    Toggle("Item", "esp.item", "esp_item")
    Toggle("Body", "esp.body", "esp_body")
    Toggle("Chest", "esp.chest", "esp_chest")

    local ESPSettings = ESPTab:AddSection(T("esp.settings"), false)
    ESPSettings:AddSwitch(T("esp.names"), true, function(Enabled) ESP.Names = Enabled end, "esp_names")
    ESPSettings:AddSwitch(T("esp.distance"), true, function(Enabled) ESP.Distance = Enabled end, "esp_distance")
    ESPSettings:AddSwitch(T("esp.highlight"), true, function(Enabled) ESP.Highlight = Enabled end, "esp_highlight")
    ESPSettings:AddSlider(T("esp.range"), 50, 3000, ESP.MaxDistance, function(Value)
        ESP.MaxDistance = math.clamp(Value, 50, 3000)
    end, 0, "esp_range")
end
