return function(Env)
    local RunService, UserInputService, LocalPlayer, PlayerTab, State, SetLoop, GetCharacter = Env.RunService, Env.UserInputService, Env.LocalPlayer, Env.PlayerTab, Env.State, Env.SetLoop, Env.GetCharacter

    RunService.Heartbeat:Connect(function(DeltaTime)
        if not State.SpeedBoost then return end
        local _, Humanoid, Root = GetCharacter()
        if not Humanoid then return end
        local Direction = Humanoid.MoveDirection
        if Direction.Magnitude > 0 then
            Root.CFrame = Root.CFrame + Direction.Unit * State.SpeedValue * DeltaTime
        end
    end)

    local NoclipParts = {}

    RunService.Stepped:Connect(function()
        if not State.Noclip then return end
        local Character = LocalPlayer.Character
        if not Character then return end
        for _, Part in ipairs(Character:GetDescendants()) do
            if Part:IsA("BasePart") and Part.CanCollide then
                NoclipParts[Part] = true
                Part.CanCollide = false
            end
        end
    end)

    local function SetNoclip(Enabled)
        State.Noclip = Enabled
        if Enabled then return end
        for Part in pairs(NoclipParts) do
            if Part.Parent then Part.CanCollide = true end
        end
        NoclipParts = {}
    end

    local PromptConnection

    local function MakePromptInstant(Prompt)
        if not Prompt:IsA("ProximityPrompt") then return end
        if Prompt:GetAttribute("HoldDuration_Old") == nil then
            Prompt:SetAttribute("HoldDuration_Old", Prompt.HoldDuration)
        end
        Prompt.HoldDuration = 0
    end

    local function SetInstantInteract(Enabled)
        State.InstantInteract = Enabled
        if PromptConnection then
            PromptConnection:Disconnect()
            PromptConnection = nil
        end
        if Enabled then
            for _, Descendant in ipairs(workspace:GetDescendants()) do
                MakePromptInstant(Descendant)
            end
            PromptConnection = workspace.DescendantAdded:Connect(function(Descendant)
                if Descendant:IsA("ProximityPrompt") then
                    task.defer(MakePromptInstant, Descendant)
                end
            end)
            return
        end
        for _, Descendant in ipairs(workspace:GetDescendants()) do
            if Descendant:IsA("ProximityPrompt") then
                local OldDuration = Descendant:GetAttribute("HoldDuration_Old")
                if OldDuration ~= nil then Descendant.HoldDuration = OldDuration end
            end
        end
    end

    local FlyBody, FlyGyro
    local FlyUpUntil = 0
    local Controls

    task.spawn(function()
        local Success, Result = pcall(function()
            local PlayerModule = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 15)
            return require(PlayerModule):GetControls()
        end)
        if Success then Controls = Result end
    end)

    local function StopFly()
        if FlyBody then FlyBody:Destroy() FlyBody = nil end
        if FlyGyro then FlyGyro:Destroy() FlyGyro = nil end
        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then Humanoid.PlatformStand = false end
    end

    local function SetFly(Enabled)
        State.Fly = Enabled
        if not Enabled then StopFly() end
    end

    UserInputService.JumpRequest:Connect(function()
        FlyUpUntil = os.clock() + 0.2
        if State.InfiniteJump and not State.Fly then
            local _, Humanoid = GetCharacter()
            if Humanoid then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)

    RunService.Heartbeat:Connect(function()
        if not State.Fly then return end
        local _, Humanoid, Root = GetCharacter()
        local Camera = workspace.CurrentCamera
        if not (Humanoid and Root and Camera) then return end

        if not (FlyBody and FlyBody.Parent == Root and FlyGyro and FlyGyro.Parent == Root) then
            if FlyBody then FlyBody:Destroy() end
            if FlyGyro then FlyGyro:Destroy() end
            FlyBody = Instance.new("BodyVelocity")
            FlyBody.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            FlyBody.Velocity = Vector3.zero
            FlyBody.Parent = Root
            FlyGyro = Instance.new("BodyGyro")
            FlyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            FlyGyro.P = 90000
            FlyGyro.CFrame = Root.CFrame
            FlyGyro.Parent = Root
        end
        Humanoid.PlatformStand = true

        local Move
        if Controls then
            local Success, Result = pcall(function() return Controls:GetMoveVector() end)
            if Success then Move = Result end
        end
        if not Move then
            Move = Camera.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)
        end

        local CameraCFrame = Camera.CFrame
        local Direction = Vector3.zero
        local Flat = Vector3.new(Move.X, 0, Move.Z)
        if Flat.Magnitude > 0.01 then
            Flat = Flat.Unit
            Direction = CameraCFrame.RightVector * Flat.X + CameraCFrame.LookVector * -Flat.Z
        end

        local Vertical = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or os.clock() < FlyUpUntil then
            Vertical += 1
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
            Vertical -= 1
        end

        local Velocity = Direction + Vector3.new(0, Vertical, 0)
        if Velocity.Magnitude > 1 then Velocity = Velocity.Unit end
        FlyBody.Velocity = Velocity * State.FlySpeed

        local Look = Vector3.new(CameraCFrame.LookVector.X, 0, CameraCFrame.LookVector.Z)
        if Look.Magnitude > 0.01 then
            FlyGyro.CFrame = CFrame.lookAt(Root.Position, Root.Position + Look)
        end
    end)

    local SavedCamera
    local PinningZoom = false
    local DesiredZoom = 12
    local ThirdPersonConnections = {}
    local CheckQueued = false

    local function CameraDistance()
        local Camera = workspace.CurrentCamera
        local Character = LocalPlayer.Character
        local Head = Character and Character:FindFirstChild("Head")
        if Camera and Head then
            return (Camera.CFrame.Position - Head.Position).Magnitude
        end
    end

    local function ApplyThirdPerson()
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = State.MaxZoom
    end

    local function PinZoom(Distance)
        if PinningZoom then return end
        PinningZoom = true
        LocalPlayer.CameraMinZoomDistance = Distance
        LocalPlayer.CameraMaxZoomDistance = Distance
        task.delay(0.25, function()
            PinningZoom = false
            if State.ThirdPerson then ApplyThirdPerson() end
        end)
    end

    local function CheckThirdPerson(Force)
        if not State.ThirdPerson or PinningZoom then return end
        local Broken = LocalPlayer.CameraMode ~= Enum.CameraMode.Classic
            or LocalPlayer.CameraMaxZoomDistance ~= State.MaxZoom
            or LocalPlayer.CameraMinZoomDistance ~= 0.5
        if Broken then ApplyThirdPerson() end
        if Broken or Force then
            local Distance = CameraDistance()
            if Distance and Distance < 1.5 then PinZoom(DesiredZoom) end
        end
    end

    local function QueueCheck()
        if CheckQueued then return end
        CheckQueued = true
        task.defer(function()
            CheckQueued = false
            CheckThirdPerson(false)
        end)
    end

    local function SampleZoom()
        if PinningZoom then return end
        local Distance = CameraDistance()
        if Distance and Distance > 2 then
            DesiredZoom = math.min(Distance, State.MaxZoom)
        end
        CheckThirdPerson(false)
    end

    local function ClearThirdPersonConnections()
        for _, Connection in ipairs(ThirdPersonConnections) do Connection:Disconnect() end
        ThirdPersonConnections = {}
    end

    local SetArmHide

    local function SetThirdPerson(Enabled)
        State.ThirdPerson = Enabled
        SetArmHide(Enabled)
        ClearThirdPersonConnections()
        SetLoop("góc nhìn thứ 3", Enabled, 0.5, SampleZoom)
        if Enabled then
            if not SavedCamera then
                SavedCamera = {
                    Mode = LocalPlayer.CameraMode,
                    Min = LocalPlayer.CameraMinZoomDistance,
                    Max = LocalPlayer.CameraMaxZoomDistance,
                }
            end
            ApplyThirdPerson()
            for _, Property in ipairs({ "CameraMode", "CameraMinZoomDistance", "CameraMaxZoomDistance" }) do
                table.insert(ThirdPersonConnections, LocalPlayer:GetPropertyChangedSignal(Property):Connect(QueueCheck))
            end
            local Camera = workspace.CurrentCamera
            if Camera then
                table.insert(ThirdPersonConnections, Camera:GetPropertyChangedSignal("CameraType"):Connect(function()
                    task.delay(0.3, function() CheckThirdPerson(true) end)
                end))
            end
            local Distance = CameraDistance()
            if Distance and Distance < 1.5 then PinZoom(DesiredZoom) end
        elseif SavedCamera then
            LocalPlayer.CameraMode = SavedCamera.Mode
            LocalPlayer.CameraMinZoomDistance = SavedCamera.Min
            LocalPlayer.CameraMaxZoomDistance = SavedCamera.Max
            SavedCamera = nil
        end
    end

    LocalPlayer.CharacterAdded:Connect(function()
        if State.ThirdPerson then
            task.delay(0.8, function() CheckThirdPerson(true) end)
        end
    end)

    local ArmState = {
        Original = setmetatable({}, { __mode = "k" }),
        Cache = nil,
        LastSearch = 0,
        Connection = nil,
        Watching = nil,
        ShouldHide = false,
    }

    local function IsArmVisual(Object)
        return Object:IsA("BasePart") or Object:IsA("Decal") or Object:IsA("Texture")
    end

    local function HideArmPart(Part)
        if ArmState.Original[Part] == nil then ArmState.Original[Part] = Part.Transparency end
        if Part.Transparency ~= 1 then Part.Transparency = 1 end
    end

    local function FindArm()
        if ArmState.Cache and ArmState.Cache.Parent then return ArmState.Cache end
        ArmState.Cache = nil
        local Camera = workspace.CurrentCamera
        local Holder = Camera and Camera:FindFirstChild("FirstPersonArm")
        if not Holder then
            local Character = LocalPlayer.Character
            Holder = Character and Character:FindFirstChild("FirstPersonArm", true)
        end
        if not Holder and os.clock() - ArmState.LastSearch > 3 then
            ArmState.LastSearch = os.clock()
            Holder = workspace:FindFirstChild("FirstPersonArm", true)
        end
        if Holder then ArmState.Cache = Holder end
        return Holder
    end

    local function WatchArm(Holder)
        if ArmState.Watching == Holder then return end
        if ArmState.Connection then
            ArmState.Connection:Disconnect()
            ArmState.Connection = nil
        end
        ArmState.Watching = Holder
        if Holder then

            ArmState.Connection = Holder.DescendantAdded:Connect(function(Descendant)
                if State.ArmHide and ArmState.ShouldHide and IsArmVisual(Descendant) then
                    pcall(HideArmPart, Descendant)
                end
            end)
        end
    end

    local function RestoreArm()
        for Part, Original in pairs(ArmState.Original) do
            pcall(function() Part.Transparency = Original end)
        end
        table.clear(ArmState.Original)
    end

    local function IsFirstPerson()
        local Camera = workspace.CurrentCamera
        if not Camera then return false end
        local Character = LocalPlayer.Character
        local Head = Character and Character:FindFirstChild("Head")
        if Head and Head.LocalTransparencyModifier >= 0.9 then return true end
        if (Camera.CFrame.Position - Camera.Focus.Position).Magnitude < 2 then return true end
        local Distance = CameraDistance()
        return Distance ~= nil and Distance < 2
    end

    local function UpdateArm()
        local Holder = FindArm()
        if not Holder then return end
        WatchArm(Holder)
        ArmState.ShouldHide = not IsFirstPerson()

        local function Apply(Part)
            if ArmState.ShouldHide then
                HideArmPart(Part)
            else
                local Original = ArmState.Original[Part]
                if Original ~= nil then
                    Part.Transparency = Original
                    ArmState.Original[Part] = nil
                end
            end
        end
        if IsArmVisual(Holder) then Apply(Holder) end
        for _, Descendant in ipairs(Holder:GetDescendants()) do
            if IsArmVisual(Descendant) then Apply(Descendant) end
        end
    end

    SetArmHide = function(Enabled)
        State.ArmHide = Enabled
        SetLoop("ẩn tay", Enabled, 0.1, UpdateArm)
        if not Enabled then
            RestoreArm()
            WatchArm(nil)
            ArmState.ShouldHide = false
        end
    end

    PlayerTab:AddSwitch("Tăng tốc", false, function(Enabled) State.SpeedBoost = Enabled end, "speed")
    PlayerTab:AddSlider("Tốc độ chạy", 1, 200, State.SpeedValue, function(Value)
        State.SpeedValue = math.clamp(Value, 1, 200)
    end, 0, "speed_value")
    PlayerTab:AddSwitch("Bay", false, SetFly, "fly")
    PlayerTab:AddSlider("Tốc độ bay", 10, 300, State.FlySpeed, function(Value)
        State.FlySpeed = math.clamp(Value, 10, 300)
    end, 0, "fly_speed")
    PlayerTab:AddSwitch("Xuyên tường", false, SetNoclip, "noclip")
    PlayerTab:AddSwitch("Nhảy vô hạn", false, function(Enabled) State.InfiniteJump = Enabled end, "infinite_jump")
    PlayerTab:AddSwitch("Tương tác tức thì", false, SetInstantInteract, "instant_interact")
    PlayerTab:AddSwitch("Góc nhìn thứ 3", false, SetThirdPerson, "third_person")
    PlayerTab:AddSlider("Zoom xa tối đa", 20, 500, State.MaxZoom, function(Value)
        State.MaxZoom = math.clamp(Value, 20, 500)
    end, 0, "max_zoom")
end
