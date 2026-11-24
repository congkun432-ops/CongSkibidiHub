return function(Env)
    local FarmTab, Guard, SetLoop, GetCharacter, GetObjectPosition = Env.FarmTab, Env.Guard, Env.SetLoop, Env.GetCharacter, Env.GetObjectPosition

    local function OpenSafe()
        if not Env.SafeRemote then return end
        pcall(function()
            Env.SafeRemote:FireServer(buffer.fromstring("G"), {})
        end)
    end

    local ChestState = {
        Opened = setmetatable({}, { __mode = "k" }),
        Origin = nil,
        Idle = false,
    }

    local function PromptPosition(Prompt, Fallback)
        local Parent = Prompt.Parent
        if Parent and Parent:IsA("BasePart") then return Parent.Position end
        if Parent and Parent:IsA("Attachment") then return Parent.WorldPosition end
        return Fallback
    end

    local function PressPrompt(Prompt)
        local HoldDuration, LineOfSight = Prompt.HoldDuration, Prompt.RequiresLineOfSight
        Prompt.HoldDuration = 0
        Prompt.RequiresLineOfSight = false
        local Fired = false
        if fireproximityprompt then
            Fired = pcall(fireproximityprompt, Prompt)
        end
        if not Fired then
            Fired = pcall(function()
                local VirtualInput = game:GetService("VirtualInputManager")
                VirtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.1)
                VirtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end)
        end
        task.wait(0.1)
        if Prompt.Parent then
            Prompt.HoldDuration = HoldDuration
            Prompt.RequiresLineOfSight = LineOfSight
        end
        return Fired
    end

    local ChestFilter = { ["Rương"] = true, ["Tủ lạnh"] = true }

    local function ChestCategory(Container)
        local Lower = string.lower(Container.Name)
        if string.find(Lower, "cactus", 1, true) then return "Xương rồng" end
        if string.find(Lower, "fridge", 1, true) then return "Tủ lạnh" end
        return "Rương"
    end

    local function RunAutoChest()
        local Folder = workspace:FindFirstChild("Containers")
        local _, _, Root = GetCharacter()
        if not (Folder and Root) then
            ChestState.Idle = true
            return
        end

        local Best, BestPrompt, BestDistance
        for _, Container in ipairs(Folder:GetChildren()) do
            local Prompt = Container:FindFirstChildWhichIsA("ProximityPrompt", true)
            if Prompt then
                if Prompt.Enabled and not ChestState.Opened[Container] and ChestFilter[ChestCategory(Container)] then
                    local Position = PromptPosition(Prompt, GetObjectPosition(Container))
                    if Position then
                        local Distance = (Position - Root.Position).Magnitude
                        if not BestDistance or Distance < BestDistance then
                            Best, BestPrompt, BestDistance = Container, Prompt, Distance
                        end
                    end
                end
            end
        end

        if not Best then
            ChestState.Idle = true
            if ChestState.Origin then
                Root.CFrame = ChestState.Origin
                ChestState.Origin = nil
            end
            return
        end

        ChestState.Idle = false
        ChestState.Opened[Best] = true
        if not ChestState.Origin then ChestState.Origin = Root.CFrame end
        local Position = PromptPosition(BestPrompt, GetObjectPosition(Best))
        Root.CFrame = CFrame.new(Position + Vector3.new(0, 3, 0))
        task.wait(0.2)
        PressPrompt(BestPrompt)
        task.wait(0.2)
    end

    local function SetAutoChest(Enabled)
        if Enabled then
            ChestState.Opened = setmetatable({}, { __mode = "k" })
            ChestState.Origin = nil
            ChestState.Idle = false
        end
        SetLoop("tự mở rương", Enabled, function() return ChestState.Idle and 2 or 0.2 end, RunAutoChest)
    end

    FarmTab:AddSwitch("Tự mở rương", false, SetAutoChest, "auto_chest")
    FarmTab:AddMultiDropdown("Loại mở", { "Rương", "Tủ lạnh", "Xương rồng" }, function(List)
        ChestFilter = {}
        for _, Name in ipairs(List) do ChestFilter[Name] = true end
    end, "chest_types", { "Rương", "Tủ lạnh" })
    FarmTab:AddButton("Mở két sắt", "Mở", function()
        Guard("mở két", OpenSafe)
    end)
end
