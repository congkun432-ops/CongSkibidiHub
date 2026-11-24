return function(Env)
    local RunService, UserInputService, LocalPlayer, FarmTab, State, Guard, SetLoop, GetCharacter, GetMonsterPosition, GetZapRemote, GetInventory, GetController = Env.RunService, Env.UserInputService, Env.LocalPlayer, Env.FarmTab, Env.State, Env.Guard, Env.SetLoop, Env.GetCharacter, Env.GetMonsterPosition, Env.GetZapRemote, Env.GetInventory, Env.GetController

    local ATTACK_PAUSE = 0.03
    local function RunKillAura()
        local _, _, Root = GetCharacter()
        local Folder = workspace:FindFirstChild("Monsters")
        if not (Root and Folder) then return end

        local Targets = {}
        for _, Monster in ipairs(Folder:GetChildren()) do
            local Humanoid = Monster:FindFirstChildOfClass("Humanoid")
            if not Humanoid or Humanoid.Health > 0 then
                local Position = GetMonsterPosition(Monster)
                if Position and (Position - Root.Position).Magnitude <= State.AuraRange then
                    table.insert(Targets, Monster)
                end
            end
        end
        if #Targets == 0 then return end

        pcall(function() Env.Remotes.heldObjectReplication.useTool.fire() end)
        task.wait(State.AuraDelay)
        pcall(function()
            Env.Remotes.meleeAttack.fire({
                monsters = Targets,
                activeSlot = State.AuraSlot,
                civilians = {},
            })
        end)
        task.wait(State.AuraDelay)
    end

    task.spawn(function()
        while true do
            task.wait(ATTACK_PAUSE)
            if State.KillAura and Env.Remotes then Guard("tự đánh quái", RunKillAura) end
        end
    end)

    local DEFAULT_SHOT = "\000\a\216\131u\191/\180@\189\218\003\143\190\001\230\2546\196\016\149MB\191~\232B\1606\238>@\163[?\131\a_\190"

    local function SendReloadFor(Uuid)
        local Remote = GetZapRemote("ZAP_RELIABLE")
        if not (Uuid and Remote) then return false end
        local Buf = buffer.create(3 + #Uuid)
        buffer.writeu8(Buf, 0, 7)
        buffer.writeu16(Buf, 1, #Uuid)
        buffer.writestring(Buf, 3, Uuid)
        Remote:FireServer(Buf, {})
        return true
    end

    local function ReloadSlot(Slot)
        local Inventory = GetInventory()
        if not (Inventory and Slot) then return end
        local Ok, Slots = pcall(Inventory.getState)
        local Entry = Ok and Slots and Slots[Slot]
        local Object = Entry and Entry.storedObjects and Entry.storedObjects[1]
        local Uuid = Object and Object.slotObjectId
        if type(Uuid) ~= "string" then return end
        local Remote = Env.Remotes and Env.Remotes.heldObjectReplication and Env.Remotes.heldObjectReplication.reloadTool
        if Remote and type(Remote.fire) == "function" then
            pcall(Remote.fire, Uuid)
        else
            pcall(SendReloadFor, Uuid)
        end
    end

    local LastReloadSent = 0

    local function RunInstantReload()
        local Controller = GetController()
        if not (Controller and Controller.reloading) then return end
        if os.clock() - LastReloadSent < 0.25 then return end
        LastReloadSent = os.clock()
        ReloadSlot(Controller.activeSlot)
    end

    local function SetInstantReload(Enabled)
        State.InstantReload = Enabled
        SetLoop("nạp đạn tức thì", Enabled, 0.03, RunInstantReload)
    end

    local GUN_MAX_SHOTS_PER_TICK = 40
    local GunCursor = 0
    local GunShots = 0

    local GUN_FALLBACK_MAG = 12
    local AMMO_KEYS = { "ammo", "clip", "magazine", "bullets", "rounds" }
    local AMMO_SKIP = { "max", "reserve", "total", "capacity", "size", "spare" }
    local AmmoPath

    local function ReadAmmo(Container, Depth)
        if type(Container) ~= "table" or Depth > 2 then return end
        for Key, Value in pairs(Container) do
            if type(Key) == "string" and type(Value) == "number" then
                local Lower = string.lower(Key)
                local Skip = false
                for _, Word in ipairs(AMMO_SKIP) do
                    if string.find(Lower, Word, 1, true) then Skip = true break end
                end
                if not Skip then
                    for _, Word in ipairs(AMMO_KEYS) do
                        if string.find(Lower, Word, 1, true) then return Value end
                    end
                end
            end
        end
        for _, Value in pairs(Container) do
            if type(Value) == "table" then
                local Found = ReadAmmo(Value, Depth + 1)
                if Found ~= nil then return Found end
            end
        end
    end

    local function GetGunAmmo(Slot)
        local Inventory = GetInventory()
        local Ok, Slots = pcall(function() return Inventory and Inventory.getState() end)
        local Entry = Ok and Slots and Slots[Slot]
        local Object = Entry and Entry.storedObjects and Entry.storedObjects[1]
        local Ammo = ReadAmmo(Object, 0)
        if Ammo == nil then Ammo = ReadAmmo(Entry, 0) end
        if Ammo == nil then Ammo = ReadAmmo(GetController(), 1) end
        return Ammo
    end

    local LastGunReload = 0

    local function AutoReloadGun()
        local Ammo = GetGunAmmo(State.GunSlot)
        local NeedReload
        if Ammo ~= nil then
            NeedReload = Ammo <= 0
        else
            NeedReload = GunShots >= GUN_FALLBACK_MAG
        end
        if NeedReload and os.clock() - LastGunReload > 0.5 then
            LastGunReload = os.clock()
            GunShots = 0
            ReloadSlot(State.GunSlot)
        end
    end

    local function CountShot()
        GunShots += 1
    end

    local function BuildShot(Slot, Direction, HitPosition, Normal)
        local Buf = buffer.fromstring(DEFAULT_SHOT)
        buffer.writeu8(Buf, 1, Slot)
        buffer.writef32(Buf, 2, Direction.X)
        buffer.writef32(Buf, 6, Direction.Y)
        buffer.writef32(Buf, 10, Direction.Z)
        buffer.writef32(Buf, 15, HitPosition.X)
        buffer.writef32(Buf, 19, HitPosition.Y)
        buffer.writef32(Buf, 23, HitPosition.Z)
        if Normal then
            buffer.writef32(Buf, 27, Normal.X)
            buffer.writef32(Buf, 31, Normal.Y)
            buffer.writef32(Buf, 35, Normal.Z)
        end
        return Buf
    end

    local function RunGunAura()
        local Character, _, Root = GetCharacter()
        local Folder = workspace:FindFirstChild("Monsters")
        local Remote = GetZapRemote("ZAP_UNRELIABLE_0")
        if not (Character and Root and Folder and Remote) then return end

        local Head = Character:FindFirstChild("Head")
        local Origin = Head and Head.Position or Root.Position
        local RangeSquared = State.AuraRange * State.AuraRange

        local Targets = {}
        for _, Monster in ipairs(Folder:GetChildren()) do
            local Humanoid = Monster:FindFirstChildOfClass("Humanoid")
            if Humanoid and Humanoid.Health > 0 then
                local Position = GetMonsterPosition(Monster)
                if Position then
                    local Offset = Position - Origin
                    if Offset:Dot(Offset) <= RangeSquared then
                        table.insert(Targets, { Humanoid = Humanoid, Position = Position })
                    end
                end
            end
        end
        local Count = #Targets
        if Count == 0 then return end

        local Controller = GetController()
        if Controller and Controller.reloading then return end
        AutoReloadGun()

        for _ = 1, math.min(Count, GUN_MAX_SHOTS_PER_TICK) do
            GunCursor = GunCursor % Count + 1
            local Target = Targets[GunCursor]
            local Direction = Target.Position - Origin
            if Direction.Magnitude > 0.001 then
                Remote:FireServer(BuildShot(State.GunSlot, Direction.Unit, Target.Position), { Target.Humanoid })
                CountShot()
                if GetGunAmmo(State.GunSlot) == nil and GunShots >= GUN_FALLBACK_MAG then break end
            end
        end
        AutoReloadGun()
    end

    local function SetGunAura(Enabled)
        State.GunAura = Enabled
        if Enabled then
            GunShots = 0
            if Env.Remotes then
                pcall(function() Env.Remotes.switchSlot.fire(State.GunSlot) end)
            end
        end
        SetLoop("súng tự bắn", Enabled, function() return math.max(0.01, State.AuraDelay) end, RunGunAura)
    end

    local Firing = { Mouse = false, Touches = {} }

    local FireButton

    local function ActionButtonRoot(Input)
        local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local Mobile = PlayerGui and PlayerGui:FindFirstChild("MobileControls")
        if not Mobile then
            local Camera = workspace.CurrentCamera
            if Camera ~= nil and Input.Position.X > Camera.ViewportSize.X * 0.5 then return "any" end
            return nil
        end
        local Ok, Objects = pcall(function()
            return PlayerGui:GetGuiObjectsAtPosition(Input.Position.X, Input.Position.Y)
        end)
        if Ok then
            for _, Object in ipairs(Objects) do
                if Object:IsDescendantOf(Mobile) then
                    local Root = Object
                    while Root.Parent and Root.Parent ~= Mobile do Root = Root.Parent end
                    return Root
                end
            end
        end
        return nil
    end

    local function LearnFireButton(Input, Root)
        for _ = 1, 4 do
            RunService.RenderStepped:Wait()
            local Controller = GetController()
            if Controller and Controller.isFiring then
                FireButton = Root
                if Input.UserInputState ~= Enum.UserInputState.End then
                    Firing.Touches[Input] = true
                end
                return
            end
        end
    end

    UserInputService.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not UserInputService:GetFocusedTextBox() then Firing.Mouse = true end
        elseif Input.UserInputType == Enum.UserInputType.Touch then
            local Root = ActionButtonRoot(Input)
            if Root == "any" then
                Firing.Touches[Input] = true
            elseif Root then
                if FireButton and not FireButton.Parent then FireButton = nil end
                if FireButton then
                    if Root == FireButton then Firing.Touches[Input] = true end
                elseif State.RapidGun then
                    task.spawn(LearnFireButton, Input, Root)
                end
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Firing.Mouse = false
        elseif Input.UserInputType == Enum.UserInputType.Touch then
            Firing.Touches[Input] = nil
        end
    end)

    local function IsFiring()
        if Firing.Mouse then
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return true end
            Firing.Mouse = false
        end
        return next(Firing.Touches) ~= nil
    end

    local RapidOriginal = setmetatable({}, { __mode = "k" })
    local GUN_FIELDS = { "fireRate", "burstCooldown", "windupDuration", "visualKickBack" }
    local MELEE_FIELDS = { "attackDebounce" }

    local function Override(Controller, Field, Value)
        if Controller[Field] == nil then return end
        local Saved = RapidOriginal[Controller]
        if not Saved then
            Saved = {}
            RapidOriginal[Controller] = Saved
        end
        if Saved[Field] == nil then Saved[Field] = Controller[Field] end
        Controller[Field] = Value
    end

    local function RestoreFields(Fields)
        for Controller, Saved in pairs(RapidOriginal) do
            for _, Field in ipairs(Fields) do
                if Saved[Field] ~= nil then
                    pcall(function() Controller[Field] = Saved[Field] end)
                    Saved[Field] = nil
                end
            end
        end
    end

    local function RunRapidGun()
        local Controller = GetController()
        if not (Controller and Controller.fireRate ~= nil) then return end
        Override(Controller, "fireRate", State.RapidGunDelay)
        Override(Controller, "burstCooldown", 0)
        Override(Controller, "windupDuration", 0.05)
        Override(Controller, "visualKickBack", 0)
        if IsFiring() then Controller.isFiring = true end
    end

    local function RunRapidMelee()
        local Controller = GetController()
        if not (Controller and Controller.attackDebounce ~= nil) then return end
        Override(Controller, "attackDebounce", State.RapidMeleeDelay)
    end

    local function SetRapidGun(Enabled)
        State.RapidGun = Enabled
        SetLoop("súng liên tục", Enabled, 0, RunRapidGun)
        if not Enabled then RestoreFields(GUN_FIELDS) end
    end

    local function SetRapidMelee(Enabled)
        State.RapidMelee = Enabled
        SetLoop("cận chiến liên tục", Enabled, 0.1, RunRapidMelee)
        if not Enabled then RestoreFields(MELEE_FIELDS) end
    end

    local AuraSection = FarmTab:AddSection("Kill Aura", true)
    AuraSection:AddSwitch("Kill Aura", false, function(Enabled) State.KillAura = Enabled end, "aura_enabled")
    AuraSection:AddSwitch("Kill Aura Gun", false, SetGunAura, "gun_aura")
    AuraSection:AddSlider("Tốc độ đánh", 0.01, 0.1, State.AuraDelay, function(Value)
        State.AuraDelay = math.clamp(Value, 0.01, 0.1)
    end, 2, "aura_speed")
    AuraSection:AddSlider("Phạm vi", 1, 1000, State.AuraRange, function(Value)
        State.AuraRange = math.clamp(Value, 1, 1000)
    end, 0, "aura_range")

    local SlotOptions = {}
    for Slot = 1, 9 do SlotOptions[Slot] = tostring(Slot) end
    AuraSection:AddDropdown("Ô vũ khí", SlotOptions, function(Choice)
        State.AuraSlot = tonumber(Choice) or 1
    end, "aura_slot")
    AuraSection:AddDropdown("Ô súng", SlotOptions, function(Choice)
        State.GunSlot = tonumber(Choice) or 1
        if State.GunAura and Env.Remotes then
            pcall(function() Env.Remotes.switchSlot.fire(State.GunSlot) end)
        end
    end, "gun_slot")

    local RapidSection = FarmTab:AddSection("Không hồi chiêu", true)
    RapidSection:AddSwitch("Súng không hồi chiêu", false, SetRapidGun, "rapid_gun")
    RapidSection:AddSlider("Tốc độ bắn", 0, 0.3, State.RapidGunDelay, function(Value)
        State.RapidGunDelay = math.clamp(Value, 0, 0.3)
    end, 2, "rapid_gun_delay")
    RapidSection:AddSwitch("Nạp đạn nhanh", false, SetInstantReload, "instant_reload")
    RapidSection:AddSwitch("Cận chiến không hồi chiêu", false, SetRapidMelee, "rapid_melee")
    RapidSection:AddSlider("Tốc độ đánh", 0, 0.3, State.RapidMeleeDelay, function(Value)
        State.RapidMeleeDelay = math.clamp(Value, 0, 0.3)
    end, 2, "rapid_melee_delay")
end
