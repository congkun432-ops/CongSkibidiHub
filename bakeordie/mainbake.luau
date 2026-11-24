if not game:IsLoaded() then game.Loaded:Wait() end

--[[ ============================================================
    MONSTER HUB - Bake or Die  (VI / EN)

    3 file cùng thư mục bakeordie/ :
      mainbake.luau : file này - core + player/combat/collect/acorn/chest/items/misc/settings
      esp.luau      : chỉ ESP
      lang.luau     : toàn bộ chuỗi giao diện (mỗi dòng = { Tiếng Việt, English })

    Thêm chuỗi mới : thêm 1 dòng vào lang.luau rồi gọi T("key") ở đây
============================================================ ]]

local Genv = (getgenv and getgenv()) or _G
if Genv.MonsterHubUnload then pcall(Genv.MonsterHubUnload) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- 1. CONFIG
-- ============================================================
local LIBRARY_URL = "https://raw.githubusercontent.com/congkun432-ops/CongSkibidiHub/refs/heads/main/menu_raw"
-- URL của CHÍNH file này (dùng cho queue_on_teleport khi đổi server). Upload file này lên đúng link này.
local BASE_URL = "https://raw.githubusercontent.com/congkun432-ops/CongSkibidiHub/refs/heads/main/bakeordie/"
local MAIN_URL = BASE_URL .. "mainbake.luau"
local RESUME_FILE = "MonsterHub_resume.txt"

local Library = loadstring(game:HttpGet(LIBRARY_URL))()

-- Tải 1 file phụ, trả về kết quả chunk (nil nếu lỗi)
local function Fetch(Name)
    local Ok, Result = pcall(function()
        local Chunk, CompileError = loadstring(game:HttpGet(BASE_URL .. Name), "=" .. Name)
        assert(Chunk, CompileError)
        return Chunk()
    end)
    if not Ok then warn("[Monster Hub] không tải được " .. Name .. ": " .. tostring(Result)) end
    return Ok and Result or nil
end

-- ============================================================
-- 2. TEXT (i18n) - dữ liệu nằm trong lang.luau
-- ============================================================
local LangData = Fetch("lang.luau")
if type(LangData) ~= "table" or type(LangData.Text) ~= "table" then
    LangData = { Text = {}, Langs = { "vi", "en" }, Names = { vi = "Tiếng Việt", en = "English" } }
end
local Text, LANGS, LANG_NAMES = LangData.Text, LangData.Langs, LangData.Names
local EspFactory = Fetch("esp.luau")

-- Ngôn ngữ dùng chung với thư viện menu (CyberVibe tự lưu lựa chọn vào CyberVibe_Settings.json)
local Lang = "vi"
do
    local Ok, Current = pcall(function() return Library:GetLanguage() end)
    for _, Code in ipairs(LANGS) do
        if Ok and Code == Current then Lang = Current end
    end
end

local function LangIndex()
    for Index, Code in ipairs(LANGS) do
        if Code == Lang then return Index end
    end
    return 1
end

-- T("key") hoặc T("key", ...) với string.format
local function T(Key, ...)
    local Entry = Text[Key]
    local Result = Entry and (Entry[LangIndex()] or Entry[1]) or Key
    if select("#", ...) > 0 then
        local Ok, Formatted = pcall(string.format, Result, ...)
        if Ok then return Formatted end
    end
    return Result
end

-- Danh sách nhãn cho dropdown từ danh sách id
local function Labels(Prefix, Ids)
    local List = {}
    for Index, Id in ipairs(Ids) do List[Index] = T(Prefix .. Id) end
    return List
end

-- Nhãn -> id (nhận nhãn của MỌI ngôn ngữ, nên config cũ lưu tiếng Việt vẫn đọc được)
local function IdFromLabel(Prefix, Ids, Label)
    for _, Id in ipairs(Ids) do
        local Entry = Text[Prefix .. Id]
        if Entry then
            for _, Name in ipairs(Entry) do
                if Name == Label then return Id end
            end
        end
        if Id == Label then return Id end
    end
end

local function LabelsToSet(Prefix, Ids, List)
    local Set = {}
    for _, Label in ipairs(List) do
        local Id = IdFromLabel(Prefix, Ids, Label)
        if Id then Set[Id] = true end
    end
    return Set
end

-- ============================================================
-- 3. CORE
-- ============================================================
local DEFAULTS = {
    KillAura = false, AuraDelay = 0.1, AuraRange = 30, AuraSlot = 1,
    Noclip = false, SpeedBoost = false, SpeedValue = 30, InstantInteract = false,
    CollectRange = 100, InstantReload = false,
    GunAura = false, GunSlot = 1, RapidGun = false, RapidGunDelay = 0,
    RapidMelee = false, RapidMeleeDelay = 0,
    ArmHide = false, SkipCutscene = false, InfiniteJump = false,
    Fly = false, FlySpeed = 60, ThirdPerson = false, MaxZoom = 128,
}
local State = {}
local function ResetState()
    for Key, Value in pairs(DEFAULTS) do State[Key] = Value end
end
ResetState()

local Window, PlayerTab, FarmTab
local Remotes
local SafeRemote

local Generation = 0       -- tăng mỗi lần dọn dẹp, mọi vòng lặp cũ tự thoát
local Loops = {}
local Connections = {}
local Unloaders = {}

local function Guard(_, Fn)
    pcall(Fn)
end

local function Track(Connection)
    table.insert(Connections, Connection)
    return Connection
end

local function OnUnload(Fn)
    table.insert(Unloaders, Fn)
end

local function SetLoop(Name, Enabled, Step, Body)
    if not Enabled then
        Loops[Name] = nil
        return
    end
    if Loops[Name] then return end
    local Token = {}
    Loops[Name] = Token
    task.spawn(function()
        while Loops[Name] == Token do
            Guard(Name, Body)
            local Wait = type(Step) == "function" and Step() or Step
            task.wait(Wait)
        end
    end)
end

-- Vòng lặp nền chạy suốt đời menu: Every(khoảng nghỉ, điều kiện, hàm)
local function Every(Interval, Condition, Fn)
    local Gen = Generation
    task.spawn(function()
        while Gen == Generation do
            task.wait(Interval)
            if Gen ~= Generation then break end
            if Condition() then Guard("loop", Fn) end
        end
    end)
end

local ItemData = {}
local TagCache = {}

task.spawn(function()
    local Success, Result = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Client", 30):WaitForChild("ClientRemotes", 30))
    end)
    if Success and type(Result) == "table" then Remotes = Result end
end)

do
    local Success, ObjectsLibrary = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared", 15):WaitForChild("ObjectsLibrary", 15))
    end)
    if Success and type(ObjectsLibrary) == "table" and type(ObjectsLibrary.Objects) == "table" then
        for Name, Data in pairs(ObjectsLibrary.Objects) do
            if type(Data) == "table" then ItemData[Name] = Data end
        end
    end
end

task.spawn(function()
    local Success, Result = pcall(function()
        return ReplicatedStorage:WaitForChild("ZAP", 30):WaitForChild("ZAP_RELIABLE", 30)
    end)
    if Success and Result then SafeRemote = Result end
end)

local function GetCharacter()
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")
    if Character and Humanoid and Root and Humanoid.Health > 0 then
        return Character, Humanoid, Root
    end
end

local function GetObjectPosition(Object)
    local Success, Position = pcall(function() return Object:GetPivot().Position end)
    if Success then return Position end
end

local function GetMonsterPosition(Monster)
    local Part = Monster:FindFirstChild("HumanoidRootPart")
        or Monster.PrimaryPart
        or Monster:FindFirstChildWhichIsA("BasePart", true)
    return Part and Part.Position
end

local function GetItemTags(Name)
    local Cached = TagCache[Name]
    if Cached then return Cached end
    local Data = ItemData[Name]
    if not Data then return {} end
    local Tags = {}
    if type(Data.Tags) == "table" then
        for Key, Value in pairs(Data.Tags) do
            if type(Value) == "string" then
                Tags[Value] = true
            elseif type(Key) == "string" and Value then
                Tags[Key] = true
            end
        end
    end
    if next(Tags) == nil and Data.StackGroup then
        Tags[Data.StackGroup] = true
    end
    TagCache[Name] = Tags
    return Tags
end

local function HasTag(Name, Tag)
    return GetItemTags(Name)[Tag] == true
end

local function GetZapRemote(Name)
    local Folder = ReplicatedStorage:FindFirstChild("ZAP")
    return Folder and Folder:FindFirstChild(Name)
end

local function SafeRequire(Path)
    local Node = ReplicatedStorage
    for _, Name in ipairs(Path) do
        Node = Node and Node:FindFirstChild(Name)
    end
    if not Node then return end
    local Ok, Result = pcall(require, Node)
    if Ok and type(Result) == "table" then return Result end
end

local InventoryModule
local function GetInventory()
    InventoryModule = InventoryModule or SafeRequire({ "Client", "Systems", "Inventory" })
    return InventoryModule
end

local CharacterModule
local function GetController()
    CharacterModule = CharacterModule or SafeRequire({ "Client", "Systems", "CharacterController" })
    local Fn = CharacterModule and CharacterModule.setIsFiring
    if type(Fn) ~= "function" then return end
    local Ok, A, B = pcall(debug.getupvalue, Fn, 1)
    if not Ok then return end
    if type(A) == "table" then return A end
    if type(B) == "table" then return B end
end

local function HubNotify(Type, Title, Content, Duration)
    pcall(function()
        Window:Notify({ Type = Type, Title = Title, Content = Content, Duration = Duration or 5 })
    end)
end

-- Danh sách module: Module("tên", function() ... end), chạy theo thứ tự khai báo
local ModuleList = {}
local function Module(Name, Fn)
    table.insert(ModuleList, { Name = Name, Fn = Fn })
end

-- ============================================================
-- 4. MODULES
-- ============================================================

-- ------------------------------------------------------------
-- player
-- ------------------------------------------------------------
Module("player", function()
    Track(RunService.Heartbeat:Connect(function(DeltaTime)
        if not State.SpeedBoost then return end
        local _, Humanoid, Root = GetCharacter()
        if not Humanoid then return end
        local Direction = Humanoid.MoveDirection
        if Direction.Magnitude > 0 then
            Root.CFrame = Root.CFrame + Direction.Unit * State.SpeedValue * DeltaTime
        end
    end))

    local NoclipParts = {}

    Track(RunService.Stepped:Connect(function()
        if not State.Noclip then return end
        local Character = LocalPlayer.Character
        if not Character then return end
        for _, Part in ipairs(Character:GetDescendants()) do
            if Part:IsA("BasePart") and Part.CanCollide then
                NoclipParts[Part] = true
                Part.CanCollide = false
            end
        end
    end))

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

    -- Fly
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

    Track(UserInputService.JumpRequest:Connect(function()
        FlyUpUntil = os.clock() + 0.2
        if State.InfiniteJump and not State.Fly then
            local _, Humanoid = GetCharacter()
            if Humanoid then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end))

    Track(RunService.Heartbeat:Connect(function()
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
    end))

    -- Third person
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
        SetLoop("third_person", Enabled, 0.5, SampleZoom)
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

    Track(LocalPlayer.CharacterAdded:Connect(function()
        if State.ThirdPerson then
            task.delay(0.8, function() CheckThirdPerson(true) end)
        end
    end))

    -- Arm hide
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
        SetLoop("arm_hide", Enabled, 0.1, UpdateArm)
        if not Enabled then
            RestoreArm()
            WatchArm(nil)
            ArmState.ShouldHide = false
        end
    end

    OnUnload(function()
        SetNoclip(false)
        SetFly(false)
        SetInstantInteract(false)
        SetThirdPerson(false)
    end)

    -- UI
    PlayerTab:AddSwitch(T("player.speed"), false, function(Enabled) State.SpeedBoost = Enabled end, "speed")
    PlayerTab:AddSlider(T("player.speed_value"), 1, 200, State.SpeedValue, function(Value)
        State.SpeedValue = math.clamp(Value, 1, 200)
    end, 0, "speed_value")
    PlayerTab:AddSwitch(T("player.fly"), false, SetFly, "fly")
    PlayerTab:AddSlider(T("player.fly_speed"), 10, 300, State.FlySpeed, function(Value)
        State.FlySpeed = math.clamp(Value, 10, 300)
    end, 0, "fly_speed")
    PlayerTab:AddSwitch(T("player.noclip"), false, SetNoclip, "noclip")
    PlayerTab:AddSwitch(T("player.infjump"), false, function(Enabled) State.InfiniteJump = Enabled end, "infinite_jump")
    PlayerTab:AddSwitch(T("player.instant"), false, SetInstantInteract, "instant_interact")
    PlayerTab:AddSwitch(T("player.third"), false, SetThirdPerson, "third_person")
    PlayerTab:AddSlider(T("player.zoom"), 20, 500, State.MaxZoom, function(Value)
        State.MaxZoom = math.clamp(Value, 20, 500)
    end, 0, "max_zoom")
end)

-- ------------------------------------------------------------
-- combat
-- ------------------------------------------------------------
Module("combat", function()
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

        pcall(function() Remotes.heldObjectReplication.useTool.fire() end)
        task.wait(State.AuraDelay)
        pcall(function()
            Remotes.meleeAttack.fire({
                monsters = Targets,
                activeSlot = State.AuraSlot,
                civilians = {},
            })
        end)
        task.wait(State.AuraDelay)
    end

    Every(ATTACK_PAUSE, function() return State.KillAura and Remotes end, RunKillAura)

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
        local Remote = Remotes and Remotes.heldObjectReplication and Remotes.heldObjectReplication.reloadTool
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
        SetLoop("instant_reload", Enabled, 0.03, RunInstantReload)
    end

    local GUN_MAX_SHOTS_PER_TICK = 40
    local GunCursor = 0
    local GunShots = 0

    local GUN_FALLBACK_MAG = 12
    local AMMO_KEYS = { "ammo", "clip", "magazine", "bullets", "rounds" }
    local AMMO_SKIP = { "max", "reserve", "total", "capacity", "size", "spare" }

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
                GunShots += 1
                if GetGunAmmo(State.GunSlot) == nil and GunShots >= GUN_FALLBACK_MAG then break end
            end
        end
        AutoReloadGun()
    end

    local function SetGunAura(Enabled)
        State.GunAura = Enabled
        if Enabled then
            GunShots = 0
            if Remotes then
                pcall(function() Remotes.switchSlot.fire(State.GunSlot) end)
            end
        end
        SetLoop("gun_aura", Enabled, function() return math.max(0.01, State.AuraDelay) end, RunGunAura)
    end

    -- Rapid fire / melee
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

    Track(UserInputService.InputBegan:Connect(function(Input)
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
    end))

    Track(UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Firing.Mouse = false
        elseif Input.UserInputType == Enum.UserInputType.Touch then
            Firing.Touches[Input] = nil
        end
    end))

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
        SetLoop("rapid_gun", Enabled, 0, RunRapidGun)
        if not Enabled then RestoreFields(GUN_FIELDS) end
    end

    local function SetRapidMelee(Enabled)
        State.RapidMelee = Enabled
        SetLoop("rapid_melee", Enabled, 0.1, RunRapidMelee)
        if not Enabled then RestoreFields(MELEE_FIELDS) end
    end

    OnUnload(function()
        SetGunAura(false)
        SetInstantReload(false)
        SetRapidGun(false)
        SetRapidMelee(false)
    end)

    -- UI
    local AuraSection = FarmTab:AddSection(T("combat.aura_section"), true)
    AuraSection:AddSwitch(T("combat.aura"), false, function(Enabled) State.KillAura = Enabled end, "aura_enabled")
    AuraSection:AddSwitch(T("combat.gun_aura"), false, SetGunAura, "gun_aura")
    AuraSection:AddSlider(T("combat.aura_speed"), 0.01, 0.1, State.AuraDelay, function(Value)
        State.AuraDelay = math.clamp(Value, 0.01, 0.1)
    end, 2, "aura_speed")
    AuraSection:AddSlider(T("combat.range"), 1, 1000, State.AuraRange, function(Value)
        State.AuraRange = math.clamp(Value, 1, 1000)
    end, 0, "aura_range")

    local SlotOptions = {}
    for Slot = 1, 9 do SlotOptions[Slot] = tostring(Slot) end
    AuraSection:AddDropdown(T("combat.weapon_slot"), SlotOptions, function(Choice)
        State.AuraSlot = tonumber(Choice) or 1
    end, "aura_slot")
    AuraSection:AddDropdown(T("combat.gun_slot"), SlotOptions, function(Choice)
        State.GunSlot = tonumber(Choice) or 1
        if State.GunAura and Remotes then
            pcall(function() Remotes.switchSlot.fire(State.GunSlot) end)
        end
    end, "gun_slot")

    local RapidSection = FarmTab:AddSection(T("combat.rapid_section"), true)
    RapidSection:AddSwitch(T("combat.rapid_gun"), false, SetRapidGun, "rapid_gun")
    RapidSection:AddSlider(T("combat.fire_rate"), 0, 0.3, State.RapidGunDelay, function(Value)
        State.RapidGunDelay = math.clamp(Value, 0, 0.3)
    end, 2, "rapid_gun_delay")
    RapidSection:AddSwitch(T("combat.reload"), false, SetInstantReload, "instant_reload")
    RapidSection:AddSwitch(T("combat.rapid_melee"), false, SetRapidMelee, "rapid_melee")
    RapidSection:AddSlider(T("combat.melee_speed"), 0, 0.3, State.RapidMeleeDelay, function(Value)
        State.RapidMeleeDelay = math.clamp(Value, 0, 0.3)
    end, 2, "rapid_melee_delay")
end)

-- ------------------------------------------------------------
-- collect (auto pickup + auto grind)
-- ------------------------------------------------------------
-- Category id: Ingredient / Item / Material / Corpse / Medical (nhãn hiển thị lấy từ Text "cat.*")
local COLLECT_CATEGORIES = { "Ingredient", "Item", "Material", "Corpse", "Medical" }
local GRIND_CATEGORIES = { "Material", "Corpse" }

Module("collect", function()
    local COLLECT_INTERVAL = 0.25
    local PICKUP_RETRY = 1
    local PickupAttempts = {}

    local function FindPickups(Accepts)
        local Pickups = {}
        local _, _, Root = GetCharacter()
        local Folder = workspace:FindFirstChild("Interactables")
        if not (Root and Folder) then return Pickups end
        local Now = os.clock()
        for _, Object in ipairs(Folder:GetChildren()) do
            local Id = Object:GetAttribute("ObjectUUID")
            if type(Id) == "string" and Accepts(Object) then
                local Position = GetObjectPosition(Object)
                local Distance = Position and (Position - Root.Position).Magnitude
                local LastAttempt = PickupAttempts[Id]
                if not (LastAttempt and Now - LastAttempt <= PICKUP_RETRY)
                    and Distance and Distance <= State.CollectRange then
                    table.insert(Pickups, { Object = Object, Id = Id })
                end
            end
        end
        return Pickups
    end

    local function Pickup(Id)
        PickupAttempts[Id] = os.clock()
        pcall(function() Remotes.pickupObject.fire(Id) end)
    end

    local Collect = { Selected = {}, Enabled = false, Allowed = {} }

    local function ToSet(List)
        local Set = {}
        for _, Name in ipairs(List) do Set[Name] = true end
        return Set
    end

    local FallbackSets = {
        Ingredient = ToSet({
            "Apple", "Banana", "Blackberry", "Blueberry", "CactusMeat", "Carrot", "Cheese", "CherryBomb",
            "Chicken", "ChiliPepper", "ChocolateMilk", "Coconut", "Corn", "Cranberry", "DevilEgg", "Doomberry",
            "EasterEgg", "Egg", "Eggplant", "EnragedYeast", "ExplosiveMeat", "flour", "GhostPepper",
            "Gingerbread", "GoldenApple", "GoldenCarrot", "Grape", "GreenJelly", "GreenPea", "HyperYeast",
            "IceCream", "Mango", "Marshmallow", "Meat", "Milk", "Mushroom", "Onion", "Orange", "OrangeJelly",
            "Peanut", "Pickle", "PieDough", "PinkJelly", "PinkPricklyPear", "Pineapple", "Potato", "PricklyPear",
            "Pumpkin", "RadioactiveApple", "RadioactiveBanana", "RadioactiveCarrot", "RadioactiveCorn",
            "RadioactiveEgg", "RadioactiveRatMeat", "RatMeat", "RedPricklyPear", "Squash", "Strawberry",
            "SweetPotato", "Tamarind", "Tomato", "Turkey", "Watermelon", "Yeast",
        }),
        Material = ToSet({
            "BrokenLantern", "CarBattery", "CrackedBell", "CrushedCan", "Gear", "GoldFlakes", "IronScrap",
            "Lamp", "Lantern", "MetalBarrel", "MetalBucket", "MetalGear", "MetalScrap", "Nail", "Nut",
            "OldBattery", "OldCan", "Painting", "RefinedSteel", "RockingChair", "Skull", "SteelOfMars", "Teapot",
            "Toaster", "VintageTV", "Wheel", "WheelBarrow", "WoodChair", "WoodenNail", "WoodStool",
        }),
        Medical = ToSet({ "Bandage", "FirstAidKit", "ReviveKit" }),
    }

    local CategoryCache = {}

    function Collect.Classify(Name)
        local Cached = CategoryCache[Name]
        if Cached then return Cached end
        local Category = "Item"
        if HasTag(Name, "Corpse") then
            Category = "Corpse"
        elseif HasTag(Name, "Ingredient") or FallbackSets.Ingredient[Name] then
            Category = "Ingredient"
        elseif HasTag(Name, "CraftingPart") or FallbackSets.Material[Name] then
            Category = "Material"
        elseif FallbackSets.Medical[Name] then
            Category = "Medical"
        end
        CategoryCache[Name] = Category
        return Category
    end

    local function ClassifyPickup(Object)
        if Object:FindFirstChild("HumanoidRootPart") then return "Corpse" end
        return Collect.Classify(Object.Name)
    end

    function Collect.Refresh()
        Collect.Allowed = Collect.Enabled and Collect.Selected or {}
    end

    local CollectBlacklist = { Skull = true }

    function Collect.IsAllowed(Object)
        if CollectBlacklist[Object.Name] then return false end
        if Object:FindFirstChild("ProductPriceTag") then return false end
        return Collect.Allowed[ClassifyPickup(Object)] == true
    end

    Every(COLLECT_INTERVAL, function() return Remotes and next(Collect.Allowed) ~= nil end, function()
        for _, Pickable in ipairs(FindPickups(Collect.IsAllowed)) do
            Pickup(Pickable.Id)
        end
    end)

    local CollectSection = FarmTab:AddSection(T("collect.section"), false)
    CollectSection:AddSlider(T("collect.range"), 1, 2000, State.CollectRange, function(Value)
        State.CollectRange = math.clamp(Value, 1, 2000)
    end, 0, "collect_range")
    CollectSection:AddSwitch(T("collect.enable"), false, function(Enabled)
        Collect.Enabled = Enabled
        Collect.Refresh()
    end, "collect_enabled")
    CollectSection:AddMultiDropdown(T("collect.types"), Labels("cat.", COLLECT_CATEGORIES), function(List)
        Collect.Selected = LabelsToSet("cat.", COLLECT_CATEGORIES, List)
        Collect.Refresh()
    end, "collect_types", {})

    -- Grind
    local GRIND_BUFFER = "0\001"
    local GrindStations = { Material = "BlueprintsTable", Corpse = "Grinder" }
    local STORED_NAME_KEYS = { "objectName", "name", "Name", "objectType", "type", "itemName", "item", "id", "objectId" }
    local Grind = { Selected = {}, Delay = 0.3 }

    local function StoredObjectName(Object)
        if type(Object) ~= "table" then return nil end
        for _, Key in ipairs(STORED_NAME_KEYS) do
            local Value = Object[Key]
            if type(Value) == "string" and ItemData[Value] then return Value end
        end
        for _, Value in pairs(Object) do
            if type(Value) == "string" and ItemData[Value] then return Value end
        end
        for _, Value in pairs(Object) do
            if type(Value) == "table" then
                for _, Inner in pairs(Value) do
                    if type(Inner) == "string" and ItemData[Inner] then return Inner end
                end
            end
        end
        for _, Key in ipairs(STORED_NAME_KEYS) do
            local Value = Object[Key]
            if type(Value) == "string" then return Value end
        end
        return nil
    end

    local function GetInventorySlots()
        local Inventory = GetInventory()
        if not Inventory then return nil end
        local Ok, Slots = pcall(Inventory.getState)
        if Ok and type(Slots) == "table" then return Slots end
        return nil
    end

    local function GetDepositPart(StationName)
        local Stations = workspace:FindFirstChild("Stations")
        local Station = Stations and Stations:FindFirstChild(StationName)
        return Station and Station:FindFirstChild("ObjectDeposit")
    end

    local function FindGrindJob()
        local Slots = GetInventorySlots()
        if not Slots then return nil end
        local Indexes = {}
        for Slot, Entry in pairs(Slots) do
            if type(Slot) == "number" and type(Entry) == "table" and type(Entry.storedObjects) == "table" then
                table.insert(Indexes, Slot)
            end
        end
        table.sort(Indexes)
        for _, Slot in ipairs(Indexes) do
            -- Bỏ qua ô vũ khí của Kill Aura và ô súng của Kill Gun
            if Slot == State.AuraSlot or Slot == State.GunSlot then continue end
            local Name = StoredObjectName(Slots[Slot].storedObjects[1])
            if Name then
                local Category = Collect.Classify(Name)
                local StationName = Grind.Selected[Category] and GrindStations[Category]
                local Deposit = StationName and GetDepositPart(StationName)
                if Deposit then return Slot, Deposit end
            end
        end
        return nil
    end

    local function RunGrind()
        local Slot, Deposit = FindGrindJob()
        local _, _, Root = GetCharacter()
        if not (Slot and Root) then return end
        local Remote = GetZapRemote("ZAP_RELIABLE")
        if not Remote then return end

        if Remotes and Remotes.switchSlot then
            pcall(function() Remotes.switchSlot.fire(Slot) end)
            task.wait(0.1)
        end
        pcall(function()
            Remote:FireServer(buffer.fromstring(GRIND_BUFFER), { Deposit })
        end)
    end

    local function SetGrind(Enabled)
        SetLoop("grind", Enabled, function() return math.max(0.05, Grind.Delay) end, RunGrind)
    end

    OnUnload(function() SetGrind(false) end)

    local GrindSection = FarmTab:AddSection(T("grind.section"), false)
    GrindSection:AddSwitch(T("grind.enable"), false, SetGrind, "grind_enabled")
    GrindSection:AddMultiDropdown(T("grind.types"), Labels("cat.", GRIND_CATEGORIES), function(List)
        Grind.Selected = LabelsToSet("cat.", GRIND_CATEGORIES, List)
    end, "grind_types", {})
    GrindSection:AddSlider(T("grind.speed"), 0.05, 2, Grind.Delay, function(Value)
        Grind.Delay = math.clamp(Value, 0.05, 2)
    end, 2, "grind_delay")
end)

-- ------------------------------------------------------------
-- acorn (farm hạt dẻ + hop server)
-- ------------------------------------------------------------
local ScriptStart = os.clock()

Module("acorn", function()
    local UUID_PATTERN = "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"
    local HOP_IDLE = 10
    local HOP_MIN_STAY = 25
    local MAX_HOPS = 40

    local Acorn = {
        Farm = false,
        Token = nil,
        Wake = nil,
        Origin = nil,
        Waiting = nil,
        Busy = false,
        Hopping = false,
        HopCount = 0,
        IdleSince = nil,
        Ids = setmetatable({}, { __mode = "k" }),
        Tries = setmetatable({}, { __mode = "k" }),
        LastSent = setmetatable({}, { __mode = "k" }),
    }

    local function GetAcornFolder()
        return workspace:FindFirstChild("CandyAcornDrops")
    end

    local function IsUuidString(Value)
        return type(Value) == "string" and #Value == 36 and string.find(Value, "^" .. UUID_PATTERN .. "$") ~= nil
    end

    local AcornCapture = { Original = nil, Entry = nil }

    local function OnAcornFire(Args)
        if Acorn.Waiting and not Acorn.Waiting.Id and IsUuidString(Args[1]) then
            Acorn.Waiting.Id = Args[1]
        end
    end

    local function InstallAcornWrapper()
        if AcornCapture.Original then return true end
        local Entry = Remotes and Remotes.candyAcorn and Remotes.candyAcorn.pickupCandyAcorn
        if not (Entry and type(Entry.fire) == "function") then return false end
        local Original = Entry.fire
        local Ok = pcall(function()
            Entry.fire = function(...)
                pcall(OnAcornFire, table.pack(...))
                return Original(...)
            end
        end)
        if Ok then
            AcornCapture.Original = Original
            AcornCapture.Entry = Entry
        end
        return Ok
    end

    local ScanningIds = false
    local LastIdScan = -100
    local AcornInstanceKeys = { "model", "Model", "instance", "Instance", "object", "part", "Part", "acorn", "Acorn" }

    local function ScanAcornIds()
        if ScanningIds or not getgc then return end
        local Folder = GetAcornFolder()
        if not Folder then return end
        ScanningIds = true
        LastIdScan = os.clock()
        task.spawn(function()
            pcall(function()
                local Tables = {}
                for _, Obj in ipairs(getgc(true)) do
                    if type(Obj) == "table" then table.insert(Tables, Obj) end
                end
                local function Top(Inst)
                    if typeof(Inst) ~= "Instance" or not Inst:IsDescendantOf(Folder) then return nil end
                    local Node = Inst
                    while Node.Parent and Node.Parent ~= Folder do Node = Node.Parent end
                    if Node.Parent == Folder then return Node end
                    return nil
                end
                for Index, Candidate in ipairs(Tables) do
                    if Index % 3000 == 0 then task.wait() end
                    pcall(function()
                        local Count = 0
                        for Key, Value in pairs(Candidate) do
                            Count += 1
                            if Count > 200 then break end
                            if IsUuidString(Key) then
                                local Node = Top(Value)
                                if not Node and type(Value) == "table" then
                                    for _, Field in ipairs(AcornInstanceKeys) do
                                        Node = Top(rawget(Value, Field))
                                        if Node then break end
                                    end
                                end
                                if Node then Acorn.Ids[Node] = Key end
                            elseif type(Value) == "table" then
                                local Id = rawget(Value, "id") or rawget(Value, "Id") or rawget(Value, "uuid")
                                if IsUuidString(Id) then
                                    for _, Field in ipairs(AcornInstanceKeys) do
                                        local Node = Top(rawget(Value, Field))
                                        if Node then
                                            Acorn.Ids[Node] = Id
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
            ScanningIds = false
        end)
    end

    local function RunAcornCollect()
        local Folder = GetAcornFolder()
        local _, _, Root = GetCharacter()
        if not (Folder and Root) then return 0, 0 end

        local Now = os.clock()
        local Pending, Unknown, Total = 0, 0, 0
        local Acted = false
        local Original = AcornCapture.Original

        for _, Child in ipairs(Folder:GetChildren()) do
            Total += 1
            local Tries = Acorn.Tries[Child] or 0
            if Tries < 4 then
                Pending += 1
                if not Acorn.Ids[Child] then Unknown += 1 end
                local Last = Acorn.LastSent[Child]
                if not Acted and (not Last or Now - Last > 1.2) then
                    local Position = GetObjectPosition(Child)
                    if Position then
                        Acorn.Tries[Child] = Tries + 1
                        Acorn.LastSent[Child] = Now
                        Acted = true
                        local Id = Acorn.Ids[Child]
                        local Distance = (Position - Root.Position).Magnitude

                        if Id and Original and Tries == 0 and Distance <= State.CollectRange then
                            pcall(Original, Id)
                        else
                            if not Acorn.Origin then Acorn.Origin = Root.CFrame end
                            local Waiting = { Id = nil }
                            Acorn.Waiting = Waiting
                            Root.CFrame = CFrame.new(Position + Vector3.new(0, 1, 0))
                            if not Id then
                                local Deadline = os.clock() + 0.7
                                while not Waiting.Id and os.clock() < Deadline do task.wait(0.05) end
                                Id = Waiting.Id
                                if Id then Acorn.Ids[Child] = Id end
                            end
                            Acorn.Waiting = nil
                            task.wait(0.4)
                            if Id and Original then
                                pcall(Original, Id)
                                task.wait(0.15)
                                pcall(Original, Id)
                            end
                        end
                    end
                end
            end
        end

        if Unknown > 0 and os.clock() - LastIdScan > 20 then ScanAcornIds() end

        if Pending == 0 and Acorn.Origin then
            Root.CFrame = Acorn.Origin
            Acorn.Origin = nil
        end
        return Pending, Total
    end

    local function RunAcornOnce()
        if Acorn.Busy then return 1, 0 end
        Acorn.Busy = true
        local Ok, Pending, Total = pcall(RunAcornCollect)
        Acorn.Busy = false
        if not Ok then error(Pending, 0) end
        return Pending, Total
    end

    local function PickServer()
        local Ok, Result = pcall(function()
            local Url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
            return game:GetService("HttpService"):JSONDecode(game:HttpGet(Url))
        end)
        if not (Ok and type(Result) == "table" and type(Result.data) == "table") then return nil end
        local Choices = {}
        for _, Server in ipairs(Result.data) do
            if Server.id ~= game.JobId and type(Server.playing) == "number"
                and type(Server.maxPlayers) == "number" and Server.playing < Server.maxPlayers then
                table.insert(Choices, Server.id)
            end
        end
        if #Choices == 0 then return nil end
        return Choices[math.random(#Choices)]
    end

    local function HopServer()
        if Acorn.Hopping then return end
        if Acorn.HopCount >= MAX_HOPS then
            Acorn.Hopping = true
            return
        end
        Acorn.Hopping = true

        if writefile then pcall(writefile, RESUME_FILE, "acorn:" .. (Acorn.HopCount + 1)) end
        if queue_on_teleport then
            pcall(queue_on_teleport, string.format("loadstring(game:HttpGet(%q))()", MAIN_URL))
        end

        task.spawn(function()
            local TeleportService = game:GetService("TeleportService")
            for _ = 1, 6 do
                if not Acorn.Farm then break end
                local JobId = PickServer()
                pcall(function()
                    if JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, JobId, LocalPlayer)
                    else
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    end
                end)
                task.wait(10)
            end
            Acorn.Hopping = false
        end)
    end

    local function SetAcorn(Enabled)
        Acorn.Farm = Enabled
        if not Enabled then
            Acorn.Token = nil
            if Acorn.Wake then pcall(function() Acorn.Wake:Fire() end) end
            local _, _, Root = GetCharacter()
            if Root and Acorn.Origin then Root.CFrame = Acorn.Origin end
            Acorn.Origin = nil
            return
        end
        Acorn.Tries = setmetatable({}, { __mode = "k" })
        Acorn.LastSent = setmetatable({}, { __mode = "k" })
        Acorn.IdleSince = nil
        ScanAcornIds()
        if Acorn.Token then return end
        local Token = {}
        Acorn.Token = Token
        task.spawn(function()
            while Acorn.Token == Token do
                Guard("acorn", function()
                    local Pending = RunAcornOnce()
                    if Pending == 0 then
                        Acorn.IdleSince = Acorn.IdleSince or os.clock()
                        if os.clock() - Acorn.IdleSince > HOP_IDLE and os.clock() - ScriptStart > HOP_MIN_STAY then
                            HopServer()
                        end
                    else
                        Acorn.IdleSince = nil
                    end
                end)
                local Folder = GetAcornFolder()
                if not Folder then
                    task.wait(3)
                elseif #Folder:GetChildren() == 0 then
                    local Event = Instance.new("BindableEvent")
                    Acorn.Wake = Event
                    local Connection = Folder.ChildAdded:Connect(function() Event:Fire() end)
                    task.delay(3, function() pcall(function() Event:Fire() end) end)
                    Event.Event:Wait()
                    Connection:Disconnect()
                    Event:Destroy()
                    Acorn.Wake = nil
                else
                    task.wait(0.4)
                end
            end
        end)
    end

    local Gen = Generation
    task.spawn(function()
        for _ = 1, 40 do
            if Gen ~= Generation then return end
            if Remotes and Remotes.candyAcorn and InstallAcornWrapper() then return end
            task.wait(0.5)
        end
    end)

    OnUnload(function()
        SetAcorn(false)
        if AcornCapture.Original and AcornCapture.Entry then
            pcall(function() AcornCapture.Entry.fire = AcornCapture.Original end)
            AcornCapture.Original = nil
        end
    end)

    local AcornSwitch = FarmTab:AddSwitch(T("acorn.farm"), false, SetAcorn, "auto_acorn")
    do
        local Ok, Content = pcall(function()
            if isfile and readfile and isfile(RESUME_FILE) then return readfile(RESUME_FILE) end
        end)
        if Ok and type(Content) == "string" then
            if delfile then pcall(delfile, RESUME_FILE) end
            local Count = tonumber(string.match(Content, "^acorn:(%d+)"))
            if Count then
                Acorn.HopCount = Count
                if Count < MAX_HOPS then
                    task.delay(4, function()
                        if Gen ~= Generation then return end
                        pcall(function() AcornSwitch:Set(true) end)
                        SetAcorn(true)
                    end)
                end
            end
        end
    end
end)

-- ------------------------------------------------------------
-- chest
-- ------------------------------------------------------------
local CHEST_TYPES = { "Chest", "Fridge", "Cactus" }

Module("chest", function()
    local function OpenSafe()
        if not SafeRemote then return end
        pcall(function()
            SafeRemote:FireServer(buffer.fromstring("G"), {})
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

    local ChestFilter = { Chest = true, Fridge = true }

    local function ChestCategory(Container)
        local Lower = string.lower(Container.Name)
        if string.find(Lower, "cactus", 1, true) then return "Cactus" end
        if string.find(Lower, "fridge", 1, true) then return "Fridge" end
        return "Chest"
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
        SetLoop("auto_chest", Enabled, function() return ChestState.Idle and 2 or 0.2 end, RunAutoChest)
    end

    OnUnload(function() SetAutoChest(false) end)

    FarmTab:AddSwitch(T("chest.auto"), false, SetAutoChest, "auto_chest")
    FarmTab:AddMultiDropdown(T("chest.types"), Labels("chest.", CHEST_TYPES), function(List)
        ChestFilter = LabelsToSet("chest.", CHEST_TYPES, List)
    end, "chest_types", { T("chest.Chest"), T("chest.Fridge") })
    FarmTab:AddButton(T("chest.safe"), T("chest.safe_btn"), function()
        Guard("safe", OpenSafe)
    end)
end)

-- ------------------------------------------------------------
-- esp (code nằm trong esp.luau)
-- ------------------------------------------------------------
Module("esp", function()
    if type(EspFactory) ~= "function" then
        HubNotify("error", "ESP", T("sys.module_error"), 8)
        return
    end
    EspFactory({
        Players = Players,
        LocalPlayer = LocalPlayer,
        Window = Window,
        SetLoop = SetLoop,
        OnUnload = OnUnload,
        GetCharacter = GetCharacter,
        T = T,
    })
end)

-- ------------------------------------------------------------
-- items (bring)
-- ------------------------------------------------------------
local BRING_MODES = { "All", "Item", "Body" }

Module("items", function()
    local Bring = { Enabled = false, Mode = "All", Delay = 0.05, Interval = 0.3 }

    local function RunBring()
        local _, _, Root = GetCharacter()
        local Folder = workspace:FindFirstChild("Interactables")
        if not (Root and Folder) then return end

        for _, Object in ipairs(Folder:GetChildren()) do
            if not Bring.Enabled then break end
            if Object:IsA("Model") and not Object:FindFirstChild("ProductPriceTag") then
                local IsBody = Object:FindFirstChild("HumanoidRootPart") ~= nil
                local Wanted = Bring.Mode == "All"
                    or (Bring.Mode == "Body" and IsBody)
                    or (Bring.Mode == "Item" and not IsBody)
                if Wanted then
                    local Position = GetObjectPosition(Object)
                    if Position and (Position - Root.Position).Magnitude > 4 then
                        if Object.PrimaryPart then
                            Object.PrimaryPart.CFrame = Root.CFrame
                        else
                            Object:PivotTo(Root.CFrame)
                        end
                        if Bring.Delay > 0 then task.wait(Bring.Delay) end
                    end
                end
            end
        end
    end

    Every(Bring.Interval, function() return Bring.Enabled end, RunBring)

    local ItemTab = Window:CreateTab(T("tab.items"))
    local BringSection = ItemTab:AddSection(T("bring.section"), true)
    BringSection:AddSwitch(T("bring.enable"), false, function(Enabled) Bring.Enabled = Enabled end, "bring_enabled")
    BringSection:AddDropdown(T("bring.type"), Labels("bring.", BRING_MODES), function(Choice)
        Bring.Mode = IdFromLabel("bring.", BRING_MODES, Choice) or "All"
    end, "bring_mode")
    BringSection:AddSlider(T("bring.delay"), 0, 0.2, Bring.Delay, function(Value)
        Bring.Delay = math.clamp(Value, 0, 0.2)
    end, 2, "bring_delay")
end)

-- ------------------------------------------------------------
-- misc (teleport, cutscene, codes)
-- ------------------------------------------------------------
Module("misc", function()
    -- Skip cutscene
    local SetSkipCutscene
    do
        local Cutscene = { Connection = nil, Busy = false }

        local function FinishCutsceneNow()
            local Entry = Remotes and Remotes.finishCutscene
            if not (Entry and Entry.fire) then return false end
            local Ok, Params = pcall(debug.info, Entry.fire, "a")
            if not (Ok and Params == 0) then return false end
            return pcall(Entry.fire)
        end

        local function SkipCurrentCutscene()
            if Cutscene.Busy then return end
            Cutscene.Busy = true
            task.spawn(function()
                local Attempts = 0
                while State.SkipCutscene and LocalPlayer:GetAttribute("IsInCutscene") == true and Attempts < 5 do
                    Attempts += 1
                    task.wait(Attempts == 1 and 0.3 or 1)
                    if not (State.SkipCutscene and LocalPlayer:GetAttribute("IsInCutscene") == true) then break end
                    if not FinishCutsceneNow() then break end
                end
                task.wait(0.5)
                local Camera = workspace.CurrentCamera
                local _, Humanoid = GetCharacter()
                if State.SkipCutscene and LocalPlayer:GetAttribute("IsInCutscene") == true and Camera and Humanoid then
                    Camera.CameraType = Enum.CameraType.Custom
                    Camera.CameraSubject = Humanoid
                end
                Cutscene.Busy = false
            end)
        end

        local CutsceneBackup = { Connections = {} }
        local CutsceneHook = { Installed = false, Original = nil }
        local CutsceneNames = {}
        local CUTSCENE_SUFFIX = "_MHoff"

        local function RenameCutsceneObject(Object)
            if CutsceneNames[Object] then return end
            if string.sub(Object.Name, -#CUTSCENE_SUFFIX) == CUTSCENE_SUFFIX then return end
            CutsceneNames[Object] = Object.Name
            Object.Name = Object.Name .. CUTSCENE_SUFFIX
        end

        local function RenameCutsceneFolder(Folder)
            for _, Child in ipairs(Folder:GetChildren()) do
                pcall(RenameCutsceneObject, Child)
            end
            pcall(RenameCutsceneObject, Folder)
            table.insert(CutsceneBackup.Connections, Folder.ChildAdded:Connect(function(Child)
                pcall(RenameCutsceneObject, Child)
            end))
        end

        local function RenameCutscenes()
            local Folders = {}
            local WorldFolder = workspace:FindFirstChild("Cutscenes")
            if WorldFolder then table.insert(Folders, WorldFolder) end
            local Client = ReplicatedStorage:FindFirstChild("Client")
            local Systems = Client and Client:FindFirstChild("Systems")
            local Controller = Systems and Systems:FindFirstChild("CharacterController")
            local CodeFolder = Controller and Controller:FindFirstChild("Cutscenes")
            if CodeFolder then table.insert(Folders, CodeFolder) end
            for _, Folder in ipairs(Folders) do RenameCutsceneFolder(Folder) end

            table.insert(CutsceneBackup.Connections, workspace.ChildAdded:Connect(function(Child)
                if Child.Name == "Cutscenes" then task.defer(RenameCutsceneFolder, Child) end
            end))
        end

        local function RestoreCutsceneNames()
            for Object, Name in pairs(CutsceneNames) do
                pcall(function() Object.Name = Name end)
            end
            table.clear(CutsceneNames)
        end

        local function InstallCutsceneBlock()
            if CutsceneHook.Installed then return end
            local Start = Remotes and Remotes.startCutscene
            local Finish = Remotes and Remotes.finishCutscene
            if not (Start and Start.setCallback and Finish and Finish.fire) then return end
            local Ok, Params = pcall(debug.info, Finish.fire, "a")
            if not (Ok and Params == 0) then return end

            local Callbacks
            local UpOk, Ups = pcall(debug.getupvalues, Start.setCallback)
            if UpOk and type(Ups) == "table" and type(Ups[1]) == "table" then Callbacks = Ups[1] end
            local Before = {}
            if Callbacks then
                for Key, Value in pairs(Callbacks) do Before[Key] = Value end
            end

            local function Blocker()
                task.defer(function() pcall(Finish.fire) end)
            end
            if not pcall(Start.setCallback, Blocker) then return end
            if Callbacks then
                for Key, Value in pairs(Callbacks) do
                    if Value == Blocker then CutsceneHook.Original = Before[Key] end
                end
            end
            CutsceneHook.Installed = true
        end

        local function RemoveCutsceneBlock()
            if not CutsceneHook.Installed then return end
            if CutsceneHook.Original then
                pcall(Remotes.startCutscene.setCallback, CutsceneHook.Original)
                CutsceneHook.Original = nil
                CutsceneHook.Installed = false
            end
        end

        local function ClearCutsceneConnections()
            for _, Connection in ipairs(CutsceneBackup.Connections) do Connection:Disconnect() end
            CutsceneBackup.Connections = {}
        end

        SetSkipCutscene = function(Enabled)
            State.SkipCutscene = Enabled
            if Cutscene.Connection then
                Cutscene.Connection:Disconnect()
                Cutscene.Connection = nil
            end
            ClearCutsceneConnections()
            if not Enabled then
                RemoveCutsceneBlock()
                RestoreCutsceneNames()
                return
            end

            RenameCutscenes()
            task.spawn(InstallCutsceneBlock)

            Cutscene.Connection = LocalPlayer:GetAttributeChangedSignal("IsInCutscene"):Connect(function()
                if LocalPlayer:GetAttribute("IsInCutscene") == true then SkipCurrentCutscene() end
            end)
            if LocalPlayer:GetAttribute("IsInCutscene") == true then SkipCurrentCutscene() end
        end
    end

    OnUnload(function() SetSkipCutscene(false) end)

    -- Codes
    local CODE_WORDS = { "clipboard", "keypad", "password", "passcode", "combination", "code", "note", "paper", "memo", "sticky", "safe" }

    local function FindBankClipboard()
        local World = workspace:FindFirstChild("World")
        return (World and World:FindFirstChild("BankClipboard", true)) or workspace:FindFirstChild("BankClipboard", true)
    end

    local function CollectTexts(Root)
        local Found = {}
        local function Consider(Source, Content)
            if type(Content) == "string" and Content ~= "" then
                table.insert(Found, { Source = Source, Text = Content })
            end
        end
        local function Scan(Object)
            if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
                Consider(Object:GetFullName(), Object.Text)
            elseif Object:IsA("StringValue") or Object:IsA("IntValue") or Object:IsA("NumberValue") then
                Consider(Object:GetFullName(), tostring(Object.Value))
            end
            for Key, Value in pairs(Object:GetAttributes()) do
                Consider(Object:GetFullName() .. "@" .. Key, tostring(Value))
            end
        end
        Scan(Root)
        for _, Descendant in ipairs(Root:GetDescendants()) do Scan(Descendant) end
        return Found
    end

    local function PickCodeText(Found)
        for _, Entry in ipairs(Found) do
            if string.find(Entry.Text, "%d%d%d") then return Entry end
        end
    end

    local function Shorten(Content)
        Content = string.gsub(Content, "%s+", " ")
        if #Content > 120 then Content = string.sub(Content, 1, 117) .. "..." end
        return Content
    end

    local function ShowBankCode()
        local Clipboard = FindBankClipboard()
        if not Clipboard then
            HubNotify("error", T("code.Safe"), T("code.no_clipboard"), 6)
            return
        end
        local Entry = PickCodeText(CollectTexts(Clipboard))
        if not Entry then
            local Prompt = Clipboard:FindFirstChildWhichIsA("ProximityPrompt", true)
            if Prompt and fireproximityprompt then
                pcall(fireproximityprompt, Prompt)
                task.wait(0.5)
                Entry = PickCodeText(CollectTexts(Clipboard))
            end
        end
        if Entry then
            HubNotify("success", T("code.Safe"), Shorten(Entry.Text) .. "  (" .. os.date("%H:%M:%S") .. ")", 10)
        else
            HubNotify("warning", T("code.Safe"), T("code.empty_clipboard"), 6)
        end
    end

    local function NameLooksLikeCode(Name)
        local Lower = string.lower(Name)
        for _, Word in ipairs(CODE_WORDS) do
            if string.find(Lower, Word, 1, true) then return true end
        end
        return false
    end

    local function ScanByName(Results, Seen)
        local Roots = {}
        for _, Descendant in ipairs(workspace:GetDescendants()) do
            if (Descendant:IsA("Model") or Descendant:IsA("BasePart") or Descendant:IsA("Folder"))
                and NameLooksLikeCode(Descendant.Name) then
                local Nested = false
                local Node = Descendant.Parent
                while Node and Node ~= workspace do
                    if Roots[Node] then
                        Nested = true
                        break
                    end
                    Node = Node.Parent
                end
                if not Nested then
                    Roots[Descendant] = true
                    local Entry = PickCodeText(CollectTexts(Descendant))
                    if Entry then
                        local Key = Descendant.Name .. "|" .. Entry.Text
                        if not Seen[Key] then
                            Seen[Key] = true
                            table.insert(Results, { Name = Descendant.Name, Text = Shorten(Entry.Text) })
                        end
                    end
                end
            end
        end
    end

    local function GetCodeTargets()
        local Targets = {}
        local function Add(LabelKey, Object)
            if Object then table.insert(Targets, { Label = T(LabelKey), Object = Object }) end
        end
        local World = workspace:FindFirstChild("World")
        local Science = World and World:FindFirstChild("ScienceFacility")
        local Hospital = World and World:FindFirstChild("Hospital")
        local Sewer = World and World:FindFirstChild("Sewer")
        local KeyUses = workspace:FindFirstChild("KeyItemUses")
        local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        Add("code.Safe", FindBankClipboard())
        Add("code.Raygun", Science and Science:FindFirstChild("RaygunCode"))
        Add("code.Keypad", Science and Science:FindFirstChild("Keypad"))
        Add("code.Sewer", Sewer and Sewer:FindFirstChild("Part"))
        Add("code.Gate", KeyUses and KeyUses:FindFirstChild("FacilityGateCode"))
        Add("code.Notes", workspace:FindFirstChild("Clipboard"))
        Add("code.Notes", Hospital and Hospital:FindFirstChild("Clipboard"))
        Add("code.Notes", World and World:FindFirstChild("Model"))
        for _, Child in ipairs(workspace:GetChildren()) do
            if Child.Name == "Display" then Add("code.Display", Child) end
        end
        Add("code.KeyItems", PlayerGui and PlayerGui:FindFirstChild("KeyItemsHud"))
        Add("code.KeyItems", PlayerGui and PlayerGui:FindFirstChild("KeyItemDiscovered"))
        return Targets
    end

    local function ShowAllCodes()
        local Results, Seen = {}, {}
        for _, Target in ipairs(GetCodeTargets()) do
            local Entry = PickCodeText(CollectTexts(Target.Object))
            if Entry then
                local Key = Target.Label .. "|" .. Entry.Text
                if not Seen[Key] then
                    Seen[Key] = true
                    table.insert(Results, { Name = Target.Label, Text = Shorten(Entry.Text) })
                end
            end
        end
        if #Results == 0 then ScanByName(Results, Seen) end
        if #Results == 0 then
            HubNotify("warning", T("code.title"), T("code.none"), 6)
            return
        end
        for Index, Result in ipairs(Results) do
            if Index > 8 then break end
            HubNotify("success", Result.Name, Result.Text, 12)
        end
    end

    -- Teleport
    local TeleportDropdown
    local TeleportMap = {}
    local TeleportRefreshQueued = false
    local Gen = Generation

    local function BuildTeleportList()
        local Folder = workspace:FindFirstChild("TeleportPoints")
        local Names, Map, Used = {}, {}, {}
        if Folder then
            for _, Point in ipairs(Folder:GetChildren()) do
                if GetObjectPosition(Point) then
                    local Name = Point.Name
                    Used[Name] = (Used[Name] or 0) + 1
                    if Used[Name] > 1 then Name = Name .. " (" .. Used[Name] .. ")" end
                    table.insert(Names, Name)
                    Map[Name] = Point
                end
            end
        end
        table.sort(Names)
        return Names, Map
    end

    local function RefreshTeleportList()
        local Names, Map = BuildTeleportList()
        TeleportMap = Map
        if #Names == 0 then Names = { T("tp.empty") } end
        if TeleportDropdown then TeleportDropdown:Refresh(Names, true) end
        return Names
    end

    local function QueueTeleportRefresh()
        if TeleportRefreshQueued then return end
        TeleportRefreshQueued = true
        task.delay(0.3, function()
            TeleportRefreshQueued = false
            if Gen == Generation then RefreshTeleportList() end
        end)
    end

    local function TeleportToSelected()
        local Choice = TeleportDropdown and TeleportDropdown:Get()
        local Point = Choice and TeleportMap[Choice]
        local _, _, Root = GetCharacter()
        if not Root then return end
        if not (Point and Point.Parent) then
            RefreshTeleportList()
            return
        end
        local Position = GetObjectPosition(Point)
        if Position then
            Root.CFrame = CFrame.new(Position + Vector3.new(0, 4, 0))
        end
    end

    local TeleportTab = Window:CreateTab(T("tab.teleport"))
    local InitialNames
    InitialNames, TeleportMap = BuildTeleportList()
    if #InitialNames == 0 then InitialNames = { T("tp.empty") } end
    TeleportDropdown = TeleportTab:AddDropdown(T("tp.location"), InitialNames, function() end, "teleport_point")
    TeleportTab:AddButton(T("tp.button"), T("tp.go"), TeleportToSelected)

    do
        local Folder = workspace:FindFirstChild("TeleportPoints")
        if Folder then
            Track(Folder.ChildAdded:Connect(QueueTeleportRefresh))
            Track(Folder.ChildRemoved:Connect(QueueTeleportRefresh))
        end
    end

    local MiscTab = Window:CreateTab(T("tab.misc"))
    MiscTab:AddSwitch(T("misc.cutscene"), false, SetSkipCutscene, "skip_cutscene")
    MiscTab:AddButton(T("misc.safe_code"), T("misc.code_btn"), ShowBankCode)
    MiscTab:AddButton(T("misc.all_codes"), T("misc.scan"), function()
        task.spawn(Guard, "scan_codes", ShowAllCodes)
    end)
end)

-- ------------------------------------------------------------
-- settings (đổi ngôn ngữ)
-- ------------------------------------------------------------
local Teardown, Boot, DestroyWindow, CanDestroyWindow, CaptureLayout
local Switching = false
local LangConnection

-- Gọi khi ngôn ngữ đổi (từ nút của hub, hoặc từ menu Cài đặt có sẵn của thư viện)
local function OnLanguageChanged(Code)
    if Code == Lang or not Text then return end
    local Known = false
    for _, Name in ipairs(LANGS) do
        if Name == Code then Known = true end
    end
    if not Known then return end
    Lang = Code

    if Switching then return end
    if not CanDestroyWindow() then
        -- Không nhận diện được menu để dựng lại: áp dụng ở lần chạy sau
        HubNotify("warning", T("lang.notify"), T("lang.reload", LANG_NAMES[Lang]), 8)
        return
    end
    Switching = true
    task.defer(function()
        local Layout = CaptureLayout()   -- nhớ vị trí menu trước khi huỷ
        Teardown()
        DestroyWindow()
        Boot(Layout)                     -- dựng lại và trả đúng vị trí cũ
        HubNotify("success", T("lang.notify"), T("lang.changed", LANG_NAMES[Lang]), 4)
        task.delay(1.5, function() Switching = false end)
    end)
end

Module("settings", function()
    local SettingsTab = Window:CreateTab(T("tab.settings"))
    local Other = (Lang == "vi") and "en" or "vi"
    SettingsTab:AddButton(T("lang.title", LANG_NAMES[Lang]), T("lang.button", LANG_NAMES[Other]), function()
        -- Thư viện lưu lựa chọn + phát sự kiện; OnLanguageChanged sẽ dựng lại menu
        pcall(function() Library:SetLanguage(Other) end)
        if not LangConnection then OnLanguageChanged(Other) end   -- thư viện bản cũ không có sự kiện
    end)
end)

do
    local Ok, Connection = pcall(function()
        if type(Library.OnLanguageChanged) == "function" then
            return Library:OnLanguageChanged(OnLanguageChanged)
        end
    end)
    if Ok then LangConnection = Connection end
end

-- ============================================================
-- 5. BOOT
-- ============================================================
local WINDOW_DESTROY_METHODS = { "Destroy", "Unload", "Delete" }

-- Theo dõi các ScreenGui do thư viện menu tạo ra (so sánh trước/sau CreateWindow)
-- để tự huỷ sạch menu cũ và giữ nguyên vị trí menu khi dựng lại.
local MenuGuis = {}

local function GetGuiRoots()
    local Roots = {}
    pcall(function() if gethui then table.insert(Roots, gethui()) end end)
    pcall(function() table.insert(Roots, game:GetService("CoreGui")) end)
    local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if PlayerGui then table.insert(Roots, PlayerGui) end
    return Roots
end

local function SnapshotGuis()
    local Set = {}
    for _, Root in ipairs(GetGuiRoots()) do
        pcall(function()
            for _, Child in ipairs(Root:GetChildren()) do Set[Child] = true end
        end)
    end
    return Set
end

local function CollectMenuGuis(Before)
    for _, Root in ipairs(GetGuiRoots()) do
        pcall(function()
            for _, Child in ipairs(Root:GetChildren()) do
                if Child:IsA("ScreenGui") and not Before[Child] and not table.find(MenuGuis, Child) then
                    table.insert(MenuGuis, Child)
                end
            end
        end)
    end
end

local function Viewport()
    local Camera = workspace.CurrentCamera
    return Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
end

-- Khung cửa sổ: Frame cỡ vừa (không phải overlay toàn màn hình), sâu tối đa 3 cấp
local function WindowKey(Obj, Gui, View)
    if not (Obj:IsA("Frame") or Obj:IsA("CanvasGroup")) then return nil end
    local Size = Obj.AbsoluteSize
    if Size.X < 250 or Size.Y < 150 then return nil end
    if Size.X > View.X * 0.95 and Size.Y > View.Y * 0.95 then return nil end
    local Parts, Node = {}, Obj
    while Node and Node ~= Gui do
        table.insert(Parts, 1, Node.Name .. ":" .. Node.ClassName)
        Node = Node.Parent
    end
    if #Parts > 3 then return nil end
    return Gui.Name .. "|" .. table.concat(Parts, "/")
end

function CaptureLayout()
    local Layout, View = {}, Viewport()
    for _, Gui in ipairs(MenuGuis) do
        if Gui.Parent then
            for _, Obj in ipairs(Gui:GetDescendants()) do
                local Key = WindowKey(Obj, Gui, View)
                if Key then Layout[Key] = Obj.Position end
            end
        end
    end
    return Layout
end

local function ApplyLayout(Layout)
    local View = Viewport()
    for _, Gui in ipairs(MenuGuis) do
        if Gui.Parent then
            for _, Obj in ipairs(Gui:GetDescendants()) do
                local Key = WindowKey(Obj, Gui, View)
                if Key then
                    if Layout[Key] then Obj.Position = Layout[Key] end
                    -- Chống mất menu: nếu ra khỏi màn hình thì đưa về giữa
                    local Pos, Size = Obj.AbsolutePosition, Obj.AbsoluteSize
                    if Pos.X > View.X - 60 or Pos.Y > View.Y - 60 or Pos.X + Size.X < 60 or Pos.Y + Size.Y < 60 then
                        Obj.AnchorPoint = Vector2.new(0.5, 0.5)
                        Obj.Position = UDim2.fromScale(0.5, 0.5)
                    end
                end
            end
        end
    end
end

function CanDestroyWindow()
    if #MenuGuis > 0 then return true end
    if not Window then return false end
    for _, Name in ipairs(WINDOW_DESTROY_METHODS) do
        local Ok, Method = pcall(function() return Window[Name] end)
        if Ok and type(Method) == "function" then return true end
    end
    return false
end

function DestroyWindow()
    if Window then
        for _, Name in ipairs(WINDOW_DESTROY_METHODS) do
            local Ok, Method = pcall(function() return Window[Name] end)
            if Ok and type(Method) == "function" then
                pcall(Method, Window)
                break
            end
        end
    end
    -- Huỷ chắc chắn các ScreenGui cũ để không bị chồng/lệch menu
    for _, Gui in ipairs(MenuGuis) do pcall(function() Gui:Destroy() end) end
    table.clear(MenuGuis)
    Window, PlayerTab, FarmTab = nil, nil, nil
end

-- Tắt mọi tính năng, ngắt kết nối, dừng vòng lặp
function Teardown()
    Generation += 1
    for Name in pairs(Loops) do Loops[Name] = nil end
    for Index = #Unloaders, 1, -1 do pcall(Unloaders[Index]) end
    table.clear(Unloaders)
    for _, Connection in ipairs(Connections) do pcall(function() Connection:Disconnect() end) end
    table.clear(Connections)
    ResetState()
end

function Boot(Layout)
    local Before = SnapshotGuis()
    local Gen = Generation
    Window = Library:CreateWindow({
        HubName = "Monster Hub",
        AuthorName = "Courier cat",
        ToggleKey = Enum.KeyCode.RightShift,
    })
    PlayerTab = Window:CreateTab(T("tab.player"))
    FarmTab = Window:CreateTab(T("tab.farm"))

    for _, Mod in ipairs(ModuleList) do
        local Ok, Err = xpcall(Mod.Fn, debug.traceback)
        if not Ok then
            warn("[Monster Hub] module " .. Mod.Name .. ": " .. tostring(Err))
            HubNotify("error", Mod.Name, T("sys.module_error"), 8)
        end
    end

    CollectMenuGuis(Before)
    if Layout then
        -- Thư viện có thể tự đặt/tween vị trí lúc mở: trả lại vị trí cũ vài lần
        task.spawn(function()
            for _, Delay in ipairs({ 0.2, 0.5, 1 }) do
                task.wait(Delay)
                if Gen ~= Generation then return end
                CollectMenuGuis(Before)
                ApplyLayout(Layout)
            end
        end)
    end
end

Genv.MonsterHubUnload = function()
    if LangConnection then pcall(function() LangConnection:Disconnect() end) end
    Teardown()
    DestroyWindow()
end

Boot()
