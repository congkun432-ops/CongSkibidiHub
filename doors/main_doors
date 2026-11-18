local LoadStart = tick()
local UILibrary = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/congkun432-ops/CongSkibidiHub/refs/heads/main/menu_raw"
))()
local ESP = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/congkun432-ops/CongSkibidiHub/refs/heads/main/doors/esplbri_v2"
))()
local CloneRef = cloneref or function(O) return O end
local Players = CloneRef(game:GetService("Players"))
local Workspace = CloneRef(workspace)
local RunService = CloneRef(game:GetService("RunService"))
local TweenService = CloneRef(game:GetService("TweenService"))
local UserInputService = CloneRef(game:GetService("UserInputService"))
local ProximityPromptService = CloneRef(game:GetService("ProximityPromptService"))
local Lighting = CloneRef(game:GetService("Lighting"))
local LocalPlayer = Players.LocalPlayer

local Character, Humanoid, RootPart
local Collision, CollisionClone, CollisionPart, CollisionPartClone
local CurrentCamera = Workspace.CurrentCamera
local Camera = Workspace.CurrentCamera
local OldJump = nil
local JumpButtonConnection = nil
local CanJumpConn = nil
local Main_Game = nil
local State

local RemotesFolder = game:GetService("ReplicatedStorage"):WaitForChild("RemotesFolder", 30)
local CurrentRooms  = Workspace:WaitForChild("CurrentRooms", 30)
local GameData      = game:GetService("ReplicatedStorage"):WaitForChild("GameData")
local Floor         = GameData:WaitForChild("Floor").Value
local LiveModifiers = game:GetService("ReplicatedStorage"):FindFirstChild("LiveModifiers") or Instance.new("Folder")
local LatestRoom     = GameData:WaitForChild("LatestRoom")

local FakeEvents = {
    Screech = Instance.new("RemoteEvent"), Shade = Instance.new("RemoteEvent"),
    A90 = Instance.new("RemoteEvent"), Surge = Instance.new("RemoteEvent"),
}
FakeEvents.Screech.Name = "Screech"
FakeEvents.Shade.Name   = "ShadeResult"
FakeEvents.A90.Name     = "A90"
FakeEvents.Surge.Name   = "SurgeRemote"
FakeEvents.Screech_Real = RemotesFolder and RemotesFolder:FindFirstChild("Screech")     or nil
FakeEvents.Shade_Real   = RemotesFolder and RemotesFolder:FindFirstChild("ShadeResult") or nil
FakeEvents.A90_Real     = RemotesFolder and RemotesFolder:FindFirstChild("A90")         or nil
FakeEvents.Surge_Real   = RemotesFolder and RemotesFolder:FindFirstChild("SurgeRemote") or nil

local ModuleRefs = { Screech = nil, GlitchScreech = nil, Shade = nil, A90 = nil, Dread = nil, SpiderJumpscare = nil }
local JumpscareModules = {}

local Services = setmetatable({}, { __index = function(_, n) return CloneRef(game:GetService(n)) end })

local Connections, ESPConnections, Functions = {}, {}, {}
local FakePrompts = {}

local Objects = {
    Prompts = {}, Objectives = {}, Doors = {}, HidingSpots = {},
    Entities = {}, Items = {}, Chests = {}, Currency = {}, Ladders = {},
    Obstructions = {}, EventTriggers = {}, SeekObstructions = {}, SeekHighlights = {},
    EyestalkHighlights = {}, SeekNodes = {}, SeekDuckBoards = {}, SeekBridges = {}, PathLights = {}, Traps = {},
}

local function _RandStr()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local t = {}
    for i = 1, 24 do local idx = math.random(1, #chars); t[i] = chars:sub(idx, idx) end
    return table.concat(t)
end

local Globals = { NearestTurnNode = nil, AutoMinecartDucked = false, LastDuck = 0, OriginalGetMoveVector = nil,
BreakerBoxInteracted      = false,
BreakerBoxNotified        = false,
BreakerBoxStartNotified   = false,
BreakerBoxFinishedNotified = false,
}

local SeekNodesFolder = Instance.new("Folder", Workspace); SeekNodesFolder.Name = _RandStr()
local RoomsNodesFolder = Instance.new("Folder", Workspace); RoomsNodesFolder.Name = _RandStr()
Globals.SeekNodesFolder = SeekNodesFolder
Globals.RoomsNodesFolder = RoomsNodesFolder

local function GetHiddenUI()
    if gethui then return gethui() end
    local Folder = Instance.new("Folder", CloneRef(game:GetService("CoreGui")))
    Folder.Name = ("%032x"):format(math.random(0, 2^31 - 1))
    return Folder
end
local HiddenUI = GetHiddenUI()

Globals.PromptContainer = Instance.new("Folder")
Globals.PromptContainer.Name = "PromptContainer"
Globals.PromptContainer.Parent = HiddenUI

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false; ScreenGui.IgnoreGuiInset = true
ScreenGui.Name = "ESP_" .. tostring(math.random(1, 999999))
ScreenGui.Parent = HiddenUI

local HighlightsFolder = Instance.new("Folder", ScreenGui)
local BillboardsFolder = Instance.new("Folder", ScreenGui)

local TracersFrame = Instance.new("Frame", ScreenGui)
TracersFrame.Size = UDim2.fromScale(1, 1); TracersFrame.BackgroundTransparency = 1; TracersFrame.Visible = false

local ArrowsFrame = Instance.new("Frame", ScreenGui)
ArrowsFrame.Size = UDim2.fromScale(1, 1); ArrowsFrame.BackgroundTransparency = 1; ArrowsFrame.Visible = false

local EntityAlertLabel = Instance.new("TextLabel")
EntityAlertLabel.Name = "EntityAlertLabel"
EntityAlertLabel.Size = UDim2.fromScale(1, 0.08); EntityAlertLabel.Position = UDim2.fromScale(0, 0.12)
EntityAlertLabel.BackgroundTransparency = 1; EntityAlertLabel.Text = ""
EntityAlertLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
EntityAlertLabel.TextStrokeTransparency = 0; EntityAlertLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
EntityAlertLabel.TextTransparency = 1; EntityAlertLabel.Font = Enum.Font.RobotoCondensed
EntityAlertLabel.TextSize = 32; EntityAlertLabel.RichText = true; EntityAlertLabel.ZIndex = 999
EntityAlertLabel.Parent = ScreenGui

local ArrowTemplate = Instance.new("ImageLabel")
ArrowTemplate.Image = "rbxassetid://16368985219"; ArrowTemplate.Size = UDim2.fromOffset(50, 50)
ArrowTemplate.AnchorPoint = Vector2.new(0.5, 0.5); ArrowTemplate.BackgroundTransparency = 1; ArrowTemplate.ImageTransparency = 1

local function MakeTween(I, P) return TweenService:Create(I, TweenInfo.new(ESP.FadeTime, Enum.EasingStyle.Quad), P) end
local function PlayTween(I, P) MakeTween(I, P):Play() end

local ESPBlacklist = {}
local AlertTween, AlertIDCounter = nil, 0
local NotifyEnabled = true
local LastCrouchFire = 0
local OldFog = Lighting.FogEnd
local FogInstances = {}
local LastClean = tick()
local ObjectQueue = {}

local AllowedNames = {
    Lava=true, KeyObtain=true, Key=true, FuseObtain=true, MinesGenerator=true, JeffTheKiller=true,
    Snare=true, ChestBox=true, ChestBoxLocked=true, Ladder=true, Door=true,
    Wardrobe=true, Locker_Large=true, Bed=true, RetroWardrobe=true, Backdoor_Wardrobe=true,
    Rooms_Locker=true, Toolbox=true, Toolbox_Locked=true, Locker_Small_Locked=true,
    GiggleCeiling=true, GloomPile=true, DoorFake=true, FakeDoor=true, SideroomSpace=true,
    ScaryWall=true, BananaPeel=true, Seek_Arm=true, ChandelierObstruction=true, SeekFloodline=true, TriggerEventCollision=true,
    LeverForGate=true, LiveHintBook=true,
    PathLights=true, SeekMovingNewClone=true, RunnerNodes=true, DuckBoard=true, Bridge=true,
    Padlock=true,
    ElevatorBreaker = true,
        ElevatorCar     = true,
    MinesAnchor     = true,
}

function ESP:GenerateRandomString() return _RandStr() end

function Functions.GetCurrentSpeed()
    local Speed = 15
    if Character then
        Speed += Character:GetAttribute("SpeedBoost") or 0
        Speed += Character:GetAttribute("SpeedBoostBehind") or 0
        Speed += Character:GetAttribute("SpeedBoostExtra") or 0
    end
    Speed += (LiveModifiers:FindFirstChild("PlayerFast") and 3 or 0)
    Speed += (LiveModifiers:FindFirstChild("PlayerFaster") and 6 or 0)
    Speed += (LiveModifiers:FindFirstChild("PlayerFastest") and 20 or 0)
    return Speed
end
function Functions.IsCrouching()
    if not CollisionPart then return false end
    if Floor == "Fools" or Floor == "OldHotel" then return Character and Character:GetAttribute("Crouching") end
    return CollisionPart.CollisionGroup == "PlayerCrouching"
end
function Functions.HasItem(Name, OnlyChar)
    if not OnlyChar and LocalPlayer.Backpack:FindFirstChild(Name) then return LocalPlayer.Backpack:FindFirstChild(Name) end
    if Character then return Character:FindFirstChild(Name) end
end
function Functions.GetDoorNumber(Object)
    local P = Object.Parent
    local N = tonumber(P and P.Name) or tonumber(P and P.Parent and P.Parent.Name)
    if not N then return "?" end
    N = N + 1
    if Floor == "Mines" then N = N + 100 end
    if Floor == "Backdoor" then N = N - 50 end
    return tostring(N)
end

local I18N
do
    local Ok, Mod = pcall(function()
        return loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/congkun432-ops/CongSkibidiHub/refs/heads/main/doors/I18n"
        ))()
    end)
    if Ok and type(Mod) == "table" then
        I18N = Mod
    else
        I18N = { Lang = "vi", File = "CourierCatHub/Lang.dat", Dict = {}, RDict = {}, Frags = {}, RFrags = {} }
        function I18N.Convert(Text) return Text end
        function I18N.Tr(Text) return Text end
        function I18N.Save() end
        function I18N.Load() end
    end
end

function Functions.Notify(Title, Body, Color)
    if Globals and Globals.MuteNotify then return end
    local cfg = {
        Title    = I18N.Tr(tostring(Title or "Thông báo")),
        Content  = I18N.Tr(tostring(Body or "")),
        Duration = 5,
    }
    if Color then cfg.Color = Color end
    local ok = pcall(function() UILibrary:Notify(cfg) end)
    if not ok then
        pcall(function() print("[Notify] " .. tostring(Title) .. " — " .. tostring(Body)) end)
    end
end

function Functions.NotifySuccess(T, B) Functions.Notify(T, B, Color3.fromRGB(0, 255, 130)) end
function Functions.NotifyError(T, B)   Functions.Notify(T, B, Color3.fromRGB(255, 80, 80))  end
function Functions.NotifyWarn(T, B)    Functions.Notify(T, B, Color3.fromRGB(255, 180, 0))  end
function Functions.NotifyInfo(T, B)    Functions.Notify(T, B, Color3.fromRGB(0, 212, 255))  end

function Functions.GetMainGame()
    if Main_Game then return Main_Game end
    local Gui = LocalPlayer.PlayerGui:FindFirstChild("MainUI"); if not Gui then return nil end
    local Initiator = Gui:FindFirstChild("Initiator"); if not Initiator then return nil end
    local MGObj = Initiator:FindFirstChild("Main_Game"); if not MGObj then return nil end
    if MGObj:IsA("ModuleScript") and type(require) == "function" then
        local ok, Mod = pcall(require, MGObj)
        if ok and type(Mod) == "table" then
            Main_Game = Mod
            return Main_Game
        end
    end
    Main_Game = MGObj
    return Main_Game
end

function Functions.GetModules()
    local Gui = LocalPlayer.PlayerGui:FindFirstChild("MainUI"); if not Gui then return nil end
    local Initiator = Gui:FindFirstChild("Initiator"); if not Initiator then return nil end
    local MG = Initiator:FindFirstChild("Main_Game"); if not MG then return nil end
    local Listener = MG:FindFirstChild("RemoteListener"); if not Listener then return nil end
    return Listener:FindFirstChild("Modules")
end

function Functions.GetCutscenes()
    local Gui = LocalPlayer.PlayerGui:FindFirstChild("MainUI"); if not Gui then return nil end
    local Initiator = Gui:FindFirstChild("Initiator"); if not Initiator then return nil end
    local MG = Initiator:FindFirstChild("Main_Game"); if not MG then return nil end
    local Listener = MG:FindFirstChild("RemoteListener"); if not Listener then return nil end
    return Listener:FindFirstChild("Cutscenes") or Listener:FindFirstChild("Cutscenes_Disabled")
end

function Functions.ResolveModules()
    local UIModules = Functions.GetModules()
    local RStorage = game:GetService("ReplicatedStorage")
    local ClientModules = RStorage:FindFirstChild("ModulesClient") or RStorage:FindFirstChild("ClientModules")
    local EntityModules = ClientModules and ClientModules:FindFirstChild("EntityModules")
    local function tryFind(...)
        for i = 1, select("#", ...) do
            local name = select(i, ...)
            if UIModules then local f = UIModules:FindFirstChild(name); if f then return f end end
            if EntityModules then local f = EntityModules:FindFirstChild(name); if f then return f end end
        end
    end
    ModuleRefs.Screech         = tryFind("Screech", "Screech_Disabled")
    ModuleRefs.Shade           = tryFind("Shade", "Shade_Disabled")
    ModuleRefs.A90             = tryFind("A90", "A90_Disabled")
    ModuleRefs.Dread           = tryFind("Dread", "Dread_Disabled")
    ModuleRefs.GlitchScreech   = tryFind("GlitchScreech", "GlitchScreech_Disabled")
    ModuleRefs.SpiderJumpscare = tryFind("SpiderJumpscare", "SpiderJumpscare_Disabled")
end

function Functions.GetMinecart() return Camera and Camera:FindFirstChild("MinecartRig") ~= nil end

function Functions.CheckCompatability(Features)
    for _, F in ipairs(Features) do
        if F == "require" and type(require) ~= "function" then return false end
        if F == "getconnections" and type(getconnections) ~= "function" then return false end
        if F == "hookmetamethod" and type(hookmetamethod) ~= "function" then return false end
    end
    return true
end

function Functions.GetNearestTurnNode()
    local Nearest = { Distance = math.huge, Object = nil }
    for _, Node in Objects.SeekNodes do
        if Node and Node.Parent then
            local D = LocalPlayer:DistanceFromCharacter(Node.Position)
            if D < State.MinecartTurnDistance and D < Nearest.Distance then Nearest.Distance = D; Nearest.Object = Node end
        end
    end
    return Nearest.Object
end

function Functions.GetNearestDuckBoard()
    local Nearest = { Distance = math.huge, Object = nil }
    for _, Board in Objects.SeekDuckBoards do
        if Board and Board.PrimaryPart and Board.Parent then
            local D = LocalPlayer:DistanceFromCharacter(Board.PrimaryPart.Position)
            if D < State.MinecartDuckDistance and D < Nearest.Distance then Nearest.Distance = D; Nearest.Object = Board end
        end
    end
    return Nearest.Object
end

local DoorReachConnections = {}
local DoorReachTargets     = {}
local DoorReachEnabled     = false
local DoorReachDistance    = 75
local DoorReachCooldown    = 0.1

local function IsDoorObject(obj)
    if not obj or obj.Name ~= "Door" then return false end
    if not obj.Parent then return false end
    return tonumber(obj.Parent.Name) ~= nil
end

function Functions.SetupDoorReach(DoorObject)
    if not DoorObject or DoorReachConnections[DoorObject] then return end
    if not IsDoorObject(DoorObject) then return end

    local lastFire = tick()

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not DoorObject or not DoorObject.Parent then
            conn:Disconnect()
            DoorReachConnections[DoorObject] = nil
            return
        end

        local DoorPart   = DoorObject:FindFirstChild("Door")
        local ClientOpen = DoorObject:FindFirstChild("ClientOpen")
        if DoorPart and ClientOpen then
            if LocalPlayer:DistanceFromCharacter(DoorPart.Position) < DoorReachDistance
                and tick() - lastFire > DoorReachCooldown
                and (DoorReachEnabled or Functions.GetMinecart())
            then
                ClientOpen:FireServer()
                lastFire = tick()
                Globals.LastDoorFire = tick()
            end
        end
    end)

    DoorReachConnections[DoorObject] = conn

    task.spawn(function()
        local OpenSound = DoorObject:WaitForChild("Door"):WaitForChild("Open")
        OpenSound.Played:Once(function()
            conn:Disconnect()
        end)
    end)

    DoorObject.Destroying:Connect(function()
        local c = DoorReachConnections[DoorObject]
        if c then c:Disconnect(); DoorReachConnections[DoorObject] = nil end
    end)
end

function Functions.ScanAllDoors()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if IsDoorObject(obj) then
            task.spawn(Functions.SetupDoorReach, obj)
        end
    end
end
Connections.DoorReachDetection = Workspace.DescendantAdded:Connect(function(obj)
    if DoorReachEnabled and IsDoorObject(obj) then
        task.spawn(Functions.SetupDoorReach, obj)
    end
end)

local Entities = {
["RushMoving"] = { Alias = "Rush" }, ["AmbushMoving"] = { Alias = "Ambush" },
["BackdoorRush"] = { Alias = "Blitz" },
["A60"] = { Alias = "A-60" },
["A120"] = { Alias = "A-120" },
["Groundskeeper"] = { Alias = "Groundskeeper" },
["Snare"] = { Alias = "Snare" },["Grumbo"] = {Alias = "Grumbo"},
["FigureRig"] = {Alias = "Con Mù"},
["GiggleCeiling"] = {Alias = "Giggle"},
}

local ItemNames = {
    ["Lighter"] = "Bật lửa", ["Flashlight"] = "Đèn pin", ["Lockpick"] = "Cậy cửa",
    ["Vitamins"] = "Thuốc", ["Bandage"] = "Băng gạc", ["StarVial"] = "Starlight Vial",
    ["Shakelight"] = "Gummy Flashlight", ["Battery"] = "Pin", ["Candle"] = "Nến",
    ["Crucifix"] = "Thánh giá", ["Glowsticks"] = "Que phát sáng", ["SkeletonKey"] = "Chìa khoá xương",
    ["Bread"] = "Bánh mì", ["Cheese"] = "Phô mai", ["Scanner"] = "Máy tính bảng",
    ["Shears"] = "Kéo", ["Smoothie"] = "Sinh tố", ["Multitool"] = "Đa dụng", ["LiveBreakerPolePickup"] = "Pin",

["FuseObtain"] = "Cầu chì",
}

function Functions.AddESP(Opt, RoomBased)
    local Obj = Opt.Object; if not Obj then return end
    if type(Opt.Text) == "string" then Opt.Text = I18N.Tr(Opt.Text) end
    if table.find(ESPBlacklist, Obj) then return end
    if not Obj:IsA("BasePart") and not Obj:IsA("Model") then
        local Found = nil
        for _, Desc in Obj:GetDescendants() do
            if Desc:IsA("BasePart") or Desc:IsA("Model") then Found = Desc; break end
        end
        if Found then Opt.Object = Found; Obj = Found else return end
    end
    if RoomBased then
        local CR = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
        local OR = tonumber(Obj:GetAttribute("ParentRoom"))
        if OR == CR or (table.find(Objects.Doors, Obj) and OR == CR + 1) then ESP:AddESP(Opt) end
        local Conn = LocalPlayer:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
            if ESP.ColorTable[Obj] then Opt.Color = ESP.ColorTable[Obj] end
            local NR = tonumber(LocalPlayer:GetAttribute("CurrentRoom"))
            local NOR = tonumber(Obj:GetAttribute("ParentRoom"))
            if NOR == NR or (table.find(Objects.Doors, Obj) and NOR == NR + 1) then ESP:AddESP(Opt) else ESP:RemoveESP(Obj) end
        end)
        table.insert(Connections, Conn); ESPConnections[Obj] = Conn
        Obj.Destroying:Once(function()
            Conn:Disconnect(); ESP:RemoveESP(Obj)
            local P = table.find(Connections, Conn); if P then table.remove(Connections, P) end
        end)
    else
        ESP:AddESP(Opt)
    end
end

function Functions.RemoveESP(Obj)
    if not Obj then return end
    if not Obj:IsA("BasePart") and not Obj:IsA("Model") then
        local Found = nil
        for _, Desc in Obj:GetDescendants() do
            if Desc:IsA("BasePart") or Desc:IsA("Model") then Found = Desc; break end
        end
        if Found then Obj = Found end
    end
    local C = ESPConnections[Obj]
    if C then C:Disconnect(); ESPConnections[Obj] = nil; local P = table.find(Connections, C); if P then table.remove(Connections, P) end end
    ESP:RemoveESP(Obj)
end

function Functions.BlacklistESP(Obj) table.insert(ESPBlacklist, Obj) end

function Functions.GetEntityText(Obj)
    if not (State and State.EntityNameESP) then return "" end
    local Data = Entities[Obj.Name]
    return Data and I18N.Tr(Data.Alias) or Obj.Name
end

local FigureNames = { FigureRig = true, FigureRagdoll = true, Figure = true }

function Functions.GetNearestFigure()
    local Nearest = { Distance = math.huge, Object = nil }
    for _, Object in ipairs(Objects.Entities) do
        if Object and Object:IsA("Model") and Object.PrimaryPart and FigureNames[Object.Name] then
            local D = LocalPlayer:DistanceFromCharacter(Object.PrimaryPart.Position)
            if D < Nearest.Distance and D < 25 then
                Nearest.Distance = D
                Nearest.Object = Object
            end
        end
    end
    return Nearest.Object
end

function Functions.GetLibraryCode()
    if not Character then return Floor == "Fools" and "__________" or "_____" end
    local Paper = Character:FindFirstChild("LibraryHintPaper")
        or Character:FindFirstChild("LibraryHintPaperHard")
        or LocalPlayer.Backpack:FindFirstChild("LibraryHintPaper")
        or LocalPlayer.Backpack:FindFirstChild("LibraryHintPaperHard")

    if Paper and Paper:FindFirstChild("UI") then
        local Code = {}
        local CodeLength = Floor == "Fools" and 10 or 5
        for I = 1, CodeLength do Code[I] = "_" end

        local PermUI = LocalPlayer.PlayerGui:FindFirstChild("PermUI")
        local Hints  = PermUI and PermUI:FindFirstChild("Hints")
        if not Hints then return table.concat(Code) end

        for _, Hint in ipairs(Hints:GetChildren()) do
            for _, UIChild in ipairs(Paper.UI:GetChildren()) do
                if Hint:IsA("ImageLabel") and UIChild:IsA("ImageLabel")
                    and Hint.ImageRectOffset == UIChild.ImageRectOffset
                    and Code[tonumber(UIChild.Name)] then
                    Code[tonumber(UIChild.Name)] = Hint.TextLabel.Text
                end
            end
        end
        return table.concat(Code)
    end
    return Floor == "Fools" and "__________" or "_____"
end

-- ============================================================
-- MÃ HOÁ FILE CÀI ĐẶT
-- PBKDF2-HMAC-SHA256 (tạo khoá) + ChaCha20 (mã hoá) + HMAC-SHA256 (chống sửa file)
-- Viết bằng Luau thuần, không phụ thuộc executor.
-- ============================================================
local Crypto = {}
do
    local band, bor, bxor, bnot = bit32.band, bit32.bor, bit32.bxor, bit32.bnot
    local rrot, lrot, rshift = bit32.rrotate, bit32.lrotate, bit32.rshift
    local MOD = 4294967296
    local K = {
        0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
        0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
        0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
        0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
        0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
        0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
        0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
        0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
    }

    local function sha256(msg)
        local h1, h2, h3, h4 = 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a
        local h5, h6, h7, h8 = 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
        local len = #msg
        msg = msg .. "\128" .. string.rep("\0", (55 - len) % 64) .. "\0\0\0\0" .. string.pack(">I4", len * 8)
        local w = table.create(64, 0)
        for chunk = 1, #msg, 64 do
            for i = 1, 16 do
                w[i] = (string.unpack(">I4", msg, chunk + (i - 1) * 4))
            end
            for i = 17, 64 do
                local a, b = w[i - 15], w[i - 2]
                local s0 = bxor(rrot(a, 7), rrot(a, 18), rshift(a, 3))
                local s1 = bxor(rrot(b, 17), rrot(b, 19), rshift(b, 10))
                w[i] = (w[i - 16] + s0 + w[i - 7] + s1) % MOD
            end
            local a, b, c, d, e, f, g, h = h1, h2, h3, h4, h5, h6, h7, h8
            for i = 1, 64 do
                local S1 = bxor(rrot(e, 6), rrot(e, 11), rrot(e, 25))
                local ch = bxor(band(e, f), band(bnot(e), g))
                local t1 = (h + S1 + ch + K[i] + w[i]) % MOD
                local S0 = bxor(rrot(a, 2), rrot(a, 13), rrot(a, 22))
                local maj = bxor(band(a, b), band(a, c), band(b, c))
                local t2 = (S0 + maj) % MOD
                h = g; g = f; f = e
                e = (d + t1) % MOD
                d = c; c = b; b = a
                a = (t1 + t2) % MOD
            end
            h1 = (h1 + a) % MOD; h2 = (h2 + b) % MOD; h3 = (h3 + c) % MOD; h4 = (h4 + d) % MOD
            h5 = (h5 + e) % MOD; h6 = (h6 + f) % MOD; h7 = (h7 + g) % MOD; h8 = (h8 + h) % MOD
        end
        return string.pack(">I4I4I4I4I4I4I4I4", h1, h2, h3, h4, h5, h6, h7, h8)
    end

    local function xorstr(a, b)
        local t = table.create(#a)
        for i = 1, #a do t[i] = string.char(bxor(string.byte(a, i), string.byte(b, i))) end
        return table.concat(t)
    end

    local function hmac(key, msg)
        if #key > 64 then key = sha256(key) end
        key = key .. string.rep("\0", 64 - #key)
        local ik = xorstr(key, string.rep("\54", 64))
        local ok = xorstr(key, string.rep("\92", 64))
        return sha256(ok .. sha256(ik .. msg))
    end
    Crypto.hmac = hmac
    Crypto.sha256 = sha256

    function Crypto.pbkdf2(password, salt, iters, blocks)
        local out = {}
        for i = 1, blocks do
            local u = hmac(password, salt .. string.pack(">I4", i))
            local t = u
            for _ = 2, iters do
                u = hmac(password, u)
                t = xorstr(t, u)
            end
            out[i] = t
        end
        return table.concat(out)
    end

    local function qr(s, a, b, c, d)
        s[a] = (s[a] + s[b]) % MOD; s[d] = lrot(bxor(s[d], s[a]), 16)
        s[c] = (s[c] + s[d]) % MOD; s[b] = lrot(bxor(s[b], s[c]), 12)
        s[a] = (s[a] + s[b]) % MOD; s[d] = lrot(bxor(s[d], s[a]), 8)
        s[c] = (s[c] + s[d]) % MOD; s[b] = lrot(bxor(s[b], s[c]), 7)
    end

    local function chachaBlock(key, counter, nonce)
        local init = { 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574 }
        for i = 0, 7 do init[5 + i] = (string.unpack("<I4", key, i * 4 + 1)) end
        init[13] = counter
        for i = 0, 2 do init[14 + i] = (string.unpack("<I4", nonce, i * 4 + 1)) end
        local s = table.clone(init)
        for _ = 1, 10 do
            qr(s, 1, 5, 9, 13); qr(s, 2, 6, 10, 14); qr(s, 3, 7, 11, 15); qr(s, 4, 8, 12, 16)
            qr(s, 1, 6, 11, 16); qr(s, 2, 7, 12, 13); qr(s, 3, 8, 9, 14); qr(s, 4, 5, 10, 15)
        end
        local out = table.create(16)
        for i = 1, 16 do out[i] = string.pack("<I4", (s[i] + init[i]) % MOD) end
        return table.concat(out)
    end

    -- mã hoá và giải mã dùng chung một hàm (stream cipher)
    function Crypto.chacha20(key, nonce, data)
        local out = {}
        local counter = 1
        for pos = 1, #data, 64 do
            local blk = string.sub(data, pos, pos + 63)
            local ks = chachaBlock(key, counter, nonce)
            out[#out + 1] = xorstr(blk, string.sub(ks, 1, #blk))
            counter = counter + 1
        end
        return table.concat(out)
    end

    function Crypto.tohex(s)
        return (string.gsub(s, ".", function(c) return string.format("%02x", string.byte(c)) end))
    end

    function Crypto.fromhex(h)
        if #h % 2 ~= 0 or string.find(h, "[^0-9a-fA-F]") then return nil end
        return (string.gsub(h, "%x%x", function(x) return string.char(tonumber(x, 16)) end))
    end

    -- so sánh không rò rỉ thời gian
    function Crypto.equal(a, b)
        if #a ~= #b then return false end
        local diff = 0
        for i = 1, #a do diff = bor(diff, bxor(string.byte(a, i), string.byte(b, i))) end
        return diff == 0
    end

    local RandCounter = 0
    function Crypto.randomBytes(n)
        local rng = Random.new()
        local pool = { tostring(tick()), tostring(os.clock()), tostring(os.time()) }
        for _ = 1, 8 do pool[#pool + 1] = tostring(rng:NextNumber()) end
        pcall(function() pool[#pool + 1] = game:GetService("HttpService"):GenerateGUID(false) end)
        pcall(function() pool[#pool + 1] = game:GetService("HttpService"):GenerateGUID(false) end)
        pcall(function()
            if typeof(crypt) == "table" and typeof(crypt.generatebytes) == "function" then
                pool[#pool + 1] = tostring(crypt.generatebytes(32))
            end
        end)
        RandCounter = RandCounter + 1
        pool[#pool + 1] = tostring(RandCounter)
        local seed = sha256(table.concat(pool, "|"))
        local out, i = {}, 0
        while #table.concat(out) < n do
            i = i + 1
            out[#out + 1] = hmac(seed, string.pack(">I4", i))
        end
        return string.sub(table.concat(out), 1, n)
    end
end

local HubFolder      = "CourierCatHub"
local SettingsFile   = HubFolder .. "/Settings.dat"
local KeyFile        = HubFolder .. "/Key.dat"
-- tên file cũ nằm ngoài thư mục, chỉ dùng để chuyển vào trong thư mục
local OldRootFiles   = {
    { "CongSkibidiHub_DoorsTest_Settings.dat", SettingsFile },
    { "CongSkibidiHub_DoorsTest_Key.dat",      KeyFile },
    { "SetChauPhiHub/Settings.dat", SettingsFile },
    { "SetChauPhiHub/Key.dat",      KeyFile },
}
local LegacyFile     = "CongSkibidiHub_DoorsTest_Settings.json"
local SettingsMagic  = "CSH2"
local SettingsHttp   = game:GetService("HttpService")
local SettingsData   = { Enabled = false, Values = {} }
local PendingApply   = {}
local SettingsCrypto = { Salt = nil, EncKey = nil, MacKey = nil }

local function SettingsFSReady()
    return typeof(isfile) == "function" and typeof(readfile) == "function" and typeof(writefile) == "function"
end

-- tạo thư mục CourierCatHub và chuyển file cũ (nếu có) vào trong
if SettingsFSReady() then
    pcall(function()
        if typeof(makefolder) == "function" and typeof(isfolder) == "function" and not isfolder(HubFolder) then
            makefolder(HubFolder)
        end
    end)
    local FolderOk = false
    pcall(function() FolderOk = typeof(isfolder) == "function" and isfolder(HubFolder) end)
    if FolderOk then
        for _, Pair in ipairs(OldRootFiles) do
            pcall(function()
                local Old, New = Pair[1], Pair[2]
                if isfile(Old) and not isfile(New) then writefile(New, readfile(Old)) end
                if isfile(Old) and isfile(New) and typeof(delfile) == "function" then delfile(Old) end
            end)
        end
    else
        -- executor không hỗ trợ thư mục: dùng tên file phẳng như cũ để không mất cài đặt
        SettingsFile = OldRootFiles[1][1]
        KeyFile      = OldRootFiles[2][1]
        I18N.File    = "CourierCatHub_Lang.dat"
    end
end
I18N.Load()

-- khoá gốc: 32 byte ngẫu nhiên tạo một lần cho mỗi máy, lưu ở file riêng, trộn thêm UserId
local function GetMasterSecret()
    local Master
    pcall(function()
        if isfile(KeyFile) then
            local Raw = Crypto.fromhex((string.gsub(readfile(KeyFile), "%s", "")))
            if Raw and #Raw == 32 then Master = Raw end
        end
    end)
    if not Master then
        Master = Crypto.randomBytes(32)
        pcall(function() writefile(KeyFile, Crypto.tohex(Master)) end)
    end
    return Master .. "|" .. tostring(LocalPlayer and LocalPlayer.UserId or 0) .. "|CongSkibidiHub"
end

local function DeriveSettingsKeys(Salt)
    local Keys = Crypto.pbkdf2(GetMasterSecret(), Salt, 1000, 2)
    SettingsCrypto.Salt   = Salt
    SettingsCrypto.EncKey = string.sub(Keys, 1, 32)
    SettingsCrypto.MacKey = string.sub(Keys, 33, 64)
end

local function EncryptSettings(Plain)
    if not SettingsCrypto.EncKey then DeriveSettingsKeys(Crypto.randomBytes(16)) end
    local Nonce  = Crypto.randomBytes(12)
    local Cipher = Crypto.chacha20(SettingsCrypto.EncKey, Nonce, Plain)
    local Body   = SettingsMagic .. SettingsCrypto.Salt .. Nonce .. Cipher
    return Crypto.tohex(Body .. Crypto.hmac(SettingsCrypto.MacKey, Body))
end

-- trả về nil nếu file sai định dạng, bị sửa, hoặc không đúng khoá
local function DecryptSettings(Raw)
    local Bin = Crypto.fromhex((string.gsub(Raw, "%s", "")))
    if not Bin or #Bin < 64 or string.sub(Bin, 1, 4) ~= SettingsMagic then return nil end
    local Salt   = string.sub(Bin, 5, 20)
    local Nonce  = string.sub(Bin, 21, 32)
    local Tag    = string.sub(Bin, #Bin - 31)
    local Cipher = string.sub(Bin, 33, #Bin - 32)
    if SettingsCrypto.Salt ~= Salt then DeriveSettingsKeys(Salt) end
    local Expected = Crypto.hmac(SettingsCrypto.MacKey, string.sub(Bin, 1, #Bin - 32))
    if not Crypto.equal(Expected, Tag) then
        SettingsCrypto.Salt, SettingsCrypto.EncKey, SettingsCrypto.MacKey = nil, nil, nil
        return nil
    end
    return Crypto.chacha20(SettingsCrypto.EncKey, Nonce, Cipher)
end

local function SaveSettings()
    if not SettingsFSReady() then return end
    pcall(function()
        writefile(SettingsFile, EncryptSettings(SettingsHttp:JSONEncode({
            Enabled = SettingsData.Enabled,
            Values  = SettingsData.Enabled and SettingsData.Values or {},
        })))
    end)
end

if SettingsFSReady() then
    pcall(function()
        local Plain, Migrate
        if isfile(SettingsFile) then
            Plain = DecryptSettings(readfile(SettingsFile))
        elseif isfile(LegacyFile) then
            -- file cũ chưa mã hoá: đọc một lần, mã hoá lại rồi xoá bản cũ
            Plain, Migrate = readfile(LegacyFile), true
        end
        if Plain then
            local D = SettingsHttp:JSONDecode(Plain)
            if type(D) == "table" then
                SettingsData.Enabled = D.Enabled == true
                SettingsData.Values = type(D.Values) == "table" and D.Values or {}
            end
        end
        if Migrate then
            SaveSettings()
            if typeof(delfile) == "function" then pcall(delfile, LegacyFile) end
        end
    end)
end

local SectionKeys = { ["Figure"] = "Figure" }
local WrapTab
WrapTab = function(Tab, TabName)
    local function Wrap(Method, DefaultIndex, CbIndex)
        local Orig = Tab[Method]
        if type(Orig) ~= "function" then return end
        Tab[Method] = function(self, ...)
            local Args = table.pack(...)
            local Key = TabName .. "/" .. tostring(Args[1])
            Args[1] = I18N.Tr(Args[1])
            local Default, Cb = Args[DefaultIndex], Args[CbIndex]
            local Saved = nil
            if SettingsData.Enabled then Saved = SettingsData.Values[Key] end
            if Saved ~= nil and type(Saved) == type(Default) then
                Args[DefaultIndex] = Saved
            else
                Saved = nil
            end
            SettingsData.Values[Key] = Args[DefaultIndex]
            if type(Cb) == "function" then
                Args[CbIndex] = function(V, ...)
                    SettingsData.Values[Key] = V
                    if SettingsData.Enabled then SaveSettings() end
                    return Cb(V, ...)
                end
                if Saved ~= nil and Saved ~= Default then
                    table.insert(PendingApply, function() Cb(Saved) end)
                end
            end
            return Orig(self, table.unpack(Args, 1, Args.n))
        end
    end
    local function WrapText(Method, Fn)
        local Orig = Tab[Method]
        if type(Orig) ~= "function" then return end
        Tab[Method] = function(self, ...)
            local Args = table.pack(...)
            Fn(Args)
            return Orig(self, table.unpack(Args, 1, Args.n))
        end
    end
    WrapText("AddButton", function(A) A[1] = I18N.Tr(A[1]); A[2] = I18N.Tr(A[2]) end)
    WrapText("AddDropdown", function(A)
        A[1] = I18N.Tr(A[1])
        if type(A[2]) == "table" then
            local Map, Opts = {}, {}
            for I, O in ipairs(A[2]) do
                local Shown = I18N.Tr(O)
                Opts[I] = Shown
                Map[Shown] = O
                Map[O] = O
                Map[I18N.Dict[O] or O] = O
            end
            A[2] = Opts
            local Cb = A[3]
            if type(Cb) == "function" then
                A[3] = function(V, ...) return Cb(Map[V] or V, ...) end
            end
        end
    end)
    Wrap("AddSwitch", 2, 3)
    Wrap("AddSlider", 4, 5)
    Wrap("AddTextBox", 2, 3)

    local OrigSection = Tab.AddSection
    if type(OrigSection) == "function" then
        Tab.AddSection = function(self, ...)
            local SecArgs = table.pack(...)
            SecArgs[1] = I18N.Tr(SecArgs[1])
            local Sec = OrigSection(self, table.unpack(SecArgs, 1, SecArgs.n))
            if type(Sec) == "table" then pcall(WrapTab, Sec, SectionKeys[tostring((...))] or TabName) end
            return Sec
        end
        Tab.AddSubTab = Tab.AddSection
    end
end

local HubGuis = {}
local function ListGuis()
    local Set = {}
    local Roots = {}
    pcall(function() if typeof(gethui) == "function" then table.insert(Roots, gethui()) end end)
    pcall(function() table.insert(Roots, game:GetService("CoreGui")) end)
    pcall(function() table.insert(Roots, LocalPlayer:FindFirstChildOfClass("PlayerGui")) end)
    for _, Root in ipairs(Roots) do
        pcall(function()
            for _, G in ipairs(Root:GetDescendants()) do
                if G:IsA("ScreenGui") then Set[G] = true end
            end
        end)
    end
    return Set
end
local GuisBefore = ListGuis()

local Window = UILibrary:CreateWindow({ HubName = "CourierCat Hub", AuthorName = "Courier cat" })
local Tabs = {
General = Window:CreateTab("Player"),
Exploits = Window:CreateTab("Anti entities"),
Visuals = Window:CreateTab("Visual"),
Camera = Window:CreateTab("Camera"),
Floors = Window:CreateTab("Seek & Figure"),
Utility = Window:CreateTab(I18N.Tr("Tiện ích")),
Misc = Window:CreateTab(I18N.Tr("Linh tinh")),
}
for TabName, Tab in pairs(Tabs) do pcall(WrapTab, Tab, TabName) end

for G in pairs(ListGuis()) do
    if not GuisBefore[G] and G ~= ScreenGui then table.insert(HubGuis, G) end
end
pcall(function()
    if type(Window) == "table" then
        for _, V in pairs(Window) do
            if typeof(V) == "Instance" then
                local G = V:IsA("ScreenGui") and V or V:FindFirstAncestorOfClass("ScreenGui")
                if G and G ~= ScreenGui and not table.find(HubGuis, G) then table.insert(HubGuis, G) end
            end
        end
    elseif typeof(Window) == "Instance" then
        local G = Window:IsA("ScreenGui") and Window or Window:FindFirstAncestorOfClass("ScreenGui")
        if G and G ~= ScreenGui and not table.find(HubGuis, G) then table.insert(HubGuis, G) end
    end
end)

State = {

SpeedBoost = false,
SpeedValue = 16,
InfiniteJumps = false, EnableCharacterJump = false,
InstantPrompts = false,
AutoInteract = false,
AutoCloset = false,
DoorReach = false,
DoorReachDistance = 75, DoorReachCooldown = 0.1,
InteractCooldown = 0.75,
PromptReach = 1,

    AutoInteractIgnore = { ["Locks"]=false, ["Glitch Fragments"]=false, ["Dropped Items"]=true, ["Jeff Items"]=false, ["Minecarts"]=false, ["Currency"]=false },

BypassGiggle=false,
BypassDupe=false,
BypassEyes=false,
BypassLookman=false,
EntityNameESP=false, BypassGloombatEggs=false, BypassKillbricks=false, BypassSnare=false,
BypassJeff=false,
BypassVacuum=false, BypassBanana=false, BypassSeekingWall=false,
RemoveScreech=false,
RemoveHalt=false,
RemoveA90=false,
RemoveDread=false,
RemoveSurge=false, RemoveFootstepSounds=false, DisableEntityJumpscares=false,
NoScreechDamage=false, NoHaltDamage=false,
NoA90Damage=false, NoSurgeDamage=false,

    PositionSpoof=false, CrouchSpoof=false,
    WallPass=false, WallPassSpeed=2.25,

FigureGodmode = false,
RemoveFigure=false,
AutoUnlockPadlock = false, AutoUnlockDistance = 10,
AutoHeartbeatMinigame = false,
AutoBreakerBox = false,

Ambient=false,
AmbientColor = Color3.fromRGB(255, 255, 255),
FieldOfView=70,
ThirdPerson=false, ThirdPersonX=1.5, ThirdPersonY=1, ThirdPersonZ=5, ThirdPersonWallCheck=false,
FOVEnabled=false, RemoveCutscenes=false, RemoveFog=false, RemoveCameraShake=false, RemoveCameraBobbing=false,

ObjectiveESP=false,
ObjectiveColor = Color3.fromRGB(0, 255, 0),
DoorESP=false,
DoorColor = Color3.fromRGB(0, 255, 0),
HidingESP=false,
HidingColor = Color3.fromRGB(255, 170, 0),
PlayerESP=false,
PlayerColor = Color3.fromRGB(255, 255, 255),
ChestESP=false,
ChestColor = Color3.fromRGB(255, 255, 0),
ItemESP=false,
ItemColor = Color3.fromRGB(170, 0, 255),
LadderESP=false,
LadderColor = Color3.fromRGB(255, 255, 255),
EntityESP=false,
EntityColor = Color3.fromRGB(255, 0, 0),
LeverESP=false,
HintBookESP=false,

ESPRainbow=false, ESPShowDistance=false, ESPTracers=false,
ESPArrows=false,
ESPFillTrans=0.75,
ESPOutlineTrans=0,
ESPTextSize=20,

AutoSteerMinecart=false, ShowSeekPath=false, RemoveSeekTrigger=false,
AutoRevive=false,
ShowSeekPathColor = Color3.fromRGB(0, 255, 0),
ShowEyestalkPath=false, ShowEyestalkPathColor = Color3.fromRGB(0, 120, 255),
BypassSeekObstructions=false, MinecartTurnDistance=30, MinecartDuckDistance=50,
}

local function MakeSection(Tab, Title, Open)
    if type(Tab.AddSection) == "function" then return Tab:AddSection(Title, Open) end
    return Tab
end
local SecPlayer   = MakeSection(Tabs.General, "Người chơi", true)
local SecInteract = MakeSection(Tabs.General, "Tương tác", true)

SecPlayer:AddSwitch("Bật tốc độ", false, function(S)
    State.SpeedBoost = S
    if Humanoid then Humanoid.WalkSpeed = S and State.SpeedValue or Functions.GetCurrentSpeed() end
end)

SecPlayer:AddSlider("Tốc độ", 1, 60, 16, function(v)
    State.SpeedValue = v
    if State.SpeedBoost and Humanoid then Humanoid.WalkSpeed = State.SpeedValue end
end)

SecPlayer:AddSwitch("Hiện nút nhảy", false, function(S)
    State.EnableCharacterJump = S
    if Character then Character:SetAttribute("CanJump", S and true or OldJump) end
    if Functions.RefreshJumpWidget then Functions.RefreshJumpWidget() end
end)

local Widgets = {}
local WidgetLock = { Jump = false, ThirdPerson = false, WallPass = false, ESPMute = false }
local WidgetRestored = {}

local function RefreshWidget(Id)
    local W = Widgets[Id]
    if not W or not W.Button then return end
    local On = W.Getter()
    W.Button.Text = I18N.Tr(W.Raw or W.Title) .. ": " .. (On and I18N.Tr("BẬT") or I18N.Tr("TẮT"))
    W.Button.BackgroundColor3 = On and Color3.fromRGB(0, 160, 85) or Color3.fromRGB(170, 50, 50)
end

local function SetWidget(Id, Enabled, Title, YOffset, Getter, Toggle)
    local Old = Widgets[Id]
    if Old then
        if Connections["WidgetDrag_" .. Id] then Connections["WidgetDrag_" .. Id]:Disconnect(); Connections["WidgetDrag_" .. Id] = nil end
        if Old.Button then Old.Button:Destroy() end
        Widgets[Id] = nil
    end
    if not Enabled then return end

    local Raw = Title
    Title = I18N.Tr(Title)
    local Btn = Instance.new("TextButton")
    Btn.Name = "Widget_" .. Id
    Btn.Size = UDim2.fromOffset(150, 34)
    Btn.Position = UDim2.new(1, -170, 0.4, YOffset)
    local PosKey = "Utility/WidgetPos_" .. Id
    local SavedPos = SettingsData.Enabled and SettingsData.Values[PosKey] or nil
    if type(SavedPos) == "table" and #SavedPos == 4 then
        Btn.Position = UDim2.new(SavedPos[1], SavedPos[2], SavedPos[3], SavedPos[4])
    end
    Btn.TextColor3 = Color3.new(1, 1, 1)
    Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 14
    Btn.BorderSizePixel = 0; Btn.AutoButtonColor = true; Btn.Active = true; Btn.ZIndex = 50
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    Btn.Parent = ScreenGui
    Widgets[Id] = { Button = Btn, Title = Title, Raw = Raw, Getter = Getter }
    RefreshWidget(Id)

    -- khôi phục trạng thái bật/tắt của nút nổi đã lưu (chỉ một lần khi script khởi động)
    local StateKey = "Utility/WidgetState_" .. Id
    if not WidgetRestored[Id] then
        WidgetRestored[Id] = true
        local SavedState = nil
        if SettingsData.Enabled then SavedState = SettingsData.Values[StateKey] end
        if type(SavedState) == "boolean" and SavedState ~= (Getter() and true or false) then
            pcall(Toggle)
            RefreshWidget(Id)
        end
    end

    local Dragging, Moved, StartInput, StartPos = false, false, nil, nil
    Btn.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.Touch then
            Dragging, Moved = true, false
            StartInput, StartPos = Input.Position, Btn.Position
            local EndConn
            EndConn = Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then
                    EndConn:Disconnect()
                    Dragging = false
                    if not Moved then
                        Toggle()
                        RefreshWidget(Id)
                        SettingsData.Values[StateKey] = Getter() and true or false
                        if SettingsData.Enabled then SaveSettings() end
                    else
                        local P = Btn.Position
                        SettingsData.Values[PosKey] = { P.X.Scale, P.X.Offset, P.Y.Scale, P.Y.Offset }
                        if SettingsData.Enabled then SaveSettings() end
                    end
                end
            end)
        end
    end)
    Connections["WidgetDrag_" .. Id] = UserInputService.InputChanged:Connect(function(Input)
        if Dragging and not WidgetLock[Id] and Input.UserInputType == Enum.UserInputType.Touch then
            local D = Input.Position - StartInput
            if D.Magnitude > 6 then Moved = true end
            if Moved then
                Btn.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + D.X, StartPos.Y.Scale, StartPos.Y.Offset + D.Y)
            end
        end
    end)
end

function Functions.RefreshJumpWidget() RefreshWidget("Jump") end
function Functions.RefreshThirdPersonWidget() RefreshWidget("ThirdPerson") end
function Functions.RefreshWallPassWidget() RefreshWidget("WallPass") end

local function ConvertTrim(Text, ToEn)
    if type(Text) ~= "string" or Text == "" then return Text end
    local Lead, Core, Trail = string.match(Text, "^(%s*)(.-)(%s*)$")
    if Core == "" then return Text end
    local New = I18N.Convert(Core, ToEn)
    if New == Core then return Text end
    return Lead .. New .. Trail
end

local function TranslateInstance(D, ToEn)
    pcall(function()
        if D:IsA("TextLabel") or D:IsA("TextButton") then
            local N = ConvertTrim(D.Text, ToEn)
            if N ~= D.Text then D.Text = N end
        elseif D:IsA("TextBox") then
            local N = ConvertTrim(D.PlaceholderText, ToEn)
            if N ~= D.PlaceholderText then D.PlaceholderText = N end
        end
    end)
end

local HubHooked = {}
local function HookGui(G)
    if HubHooked[G] then return end
    HubHooked[G] = true
    G.DescendantAdded:Connect(function(D)
        if I18N.Lang == "en" then
            task.defer(function() TranslateInstance(D, true) end)
        end
    end)
end

local function FindHubGui()
    local Roots = {}
    pcall(function() if typeof(gethui) == "function" then table.insert(Roots, gethui()) end end)
    pcall(function() table.insert(Roots, game:GetService("CoreGui")) end)
    pcall(function() table.insert(Roots, LocalPlayer:FindFirstChildOfClass("PlayerGui")) end)
    for _, Root in ipairs(Roots) do
        local Found
        pcall(function()
            for _, G in ipairs(Root:GetDescendants()) do
                if G:IsA("ScreenGui") and G ~= ScreenGui then
                    for _, D in ipairs(G:GetDescendants()) do
                        if (D:IsA("TextLabel") or D:IsA("TextButton")) and string.find(string.lower(D.Text), "couriercat", 1, true) then
                            Found = G
                            return
                        end
                    end
                end
            end
        end)
        if Found then return Found end
    end
end

local function ApplyLanguage()
    local ToEn = I18N.Lang == "en"
    for Id in pairs(Widgets) do RefreshWidget(Id) end
    local Alive = {}
    for _, G in ipairs(HubGuis) do
        if G.Parent then table.insert(Alive, G) end
    end
    if #Alive == 0 then
        local G = FindHubGui()
        if G then table.insert(Alive, G); table.insert(HubGuis, G) end
    end
    if #Alive == 0 then return false end
    for _, G in ipairs(Alive) do
        HookGui(G)
        for _, D in ipairs(G:GetDescendants()) do
            TranslateInstance(D, ToEn)
        end
    end
    return true
end

for _, G in ipairs(HubGuis) do HookGui(G) end
if I18N.Lang == "en" then task.defer(ApplyLanguage) end

Tabs.Misc:AddDropdown("Ngôn ngữ / Language", I18N.Lang == "en" and { "English", "Tiếng Việt" } or { "Tiếng Việt", "English" }, function(V)
    local New = V == "English" and "en" or "vi"
    if New == I18N.Lang then return end
    I18N.Lang = New
    I18N.Save()
    local Ok = ApplyLanguage()
    local Msg = New == "en" and "Switched to English." or "Đã chuyển sang Tiếng Việt."
    if not Ok then
        Msg = Msg .. (New == "en" and " Re-execute the script to update the menu." or " Chạy lại script để cập nhật menu.")
    end
    Functions.NotifyInfo("Ngôn ngữ / Language", Msg)
end)

local SecUtilJump  = MakeSection(Tabs.Utility, "Nút nhảy", true)
local SecUtilThird = MakeSection(Tabs.Utility, "Góc nhìn 3", false)
local SecUtilWall  = MakeSection(Tabs.Utility, "Xuyên tường", false)

SecUtilJump:AddSwitch("Nút nhảy", false, function(S)
    SetWidget("Jump", S, "Nút nhảy", 0,
        function() return State.EnableCharacterJump end,
        function()
            State.EnableCharacterJump = not State.EnableCharacterJump
            if Character then Character:SetAttribute("CanJump", State.EnableCharacterJump and true or OldJump) end
        end)
end)

SecUtilJump:AddSwitch("Khoá nút nhảy", false, function(S)
    WidgetLock.Jump = S
end)

SecUtilThird:AddSwitch("Nút góc nhìn 3", false, function(S)
    SetWidget("ThirdPerson", S, "Góc nhìn 3", 44,
        function() return State.ThirdPerson end,
        function()
            State.ThirdPerson = not State.ThirdPerson
            if Functions.RefreshThirdPersonParts then Functions.RefreshThirdPersonParts() end
        end)
end)

SecUtilThird:AddSwitch("Khoá nút góc nhìn", false, function(S)
    WidgetLock.ThirdPerson = S
end)

SecUtilWall:AddSwitch("Xuyên tường", false, function(S)
    State.WallPass = S
    Functions.RefreshWallPassWidget()
    Functions.Notify("Xuyên tường", S and "Đang kéo bạn chậm về phía trước — nhìn hướng muốn đi" or "Đã tắt")
end)

SecUtilWall:AddSlider("Tốc độ xuyên", 1, 2.8, 2.25, function(v)
    State.WallPassSpeed = v
end, 2)

SecUtilWall:AddSwitch("Nút xuyên tường", false, function(S)
    SetWidget("WallPass", S, "Xuyên tường", 88,
        function() return State.WallPass end,
        function() State.WallPass = not State.WallPass end)
end)

SecUtilWall:AddSwitch("Khoá nút xuyên tường", false, function(S)
    WidgetLock.WallPass = S
end)
SecPlayer:AddSwitch("Nhảy vô hạn", false, function(S) State.InfiniteJumps = S end)

SecInteract:AddSwitch("Mở cửa từ xa", false, function(S)
    State.DoorReach  = S
    DoorReachEnabled = S
    if S then
        Functions.ScanAllDoors()
        Functions.Notify("Door Reach", "Đã bật — bán kính " .. DoorReachDistance .. " studs")
    else
        Functions.Notify("Door Reach", "Đã tắt")
    end
end)

Tabs.General:AddSwitch("Lưu cài đặt", false, function(S)
    SettingsData.Enabled = S
    SaveSettings()
    Functions.Notify("Lưu cài đặt", S and "Đã bật — lần sau tự khôi phục các cài đặt" or "Đã tắt — xoá cài đặt đã lưu")
end)

SecInteract:AddSwitch("Tự tương tác", false, function(S)
    State.AutoInteract = S
    if S then Functions.Notify("AutoInteract", "Đã bật tự động tương tác") end
end)

SecInteract:AddSwitch("Tương tác nhanh", false, function(S)
    State.InstantPrompts = S
    for _, Prompt in Objects.Prompts do
        if Prompt and Prompt.Parent then
            local Old = Prompt:GetAttribute("HoldDuration_Old")
            if Old == nil then
                Old = Prompt.HoldDuration
                Prompt:SetAttribute("HoldDuration_Old", Old)
            end
            Prompt.HoldDuration = S and 0 or Old
        end
    end
    Functions.Notify("Prompt tức thì", S and "Đã bật" or "Đã tắt")
end)

SecInteract:AddSlider("Tốc độ tương tác", 0.1, 0.75, 0.75, function(V)
    State.InteractCooldown = V
end, 2)

SecInteract:AddSlider("Tốc độ mở cửa", 0.1, 0.75, 0.1, function(V)
    DoorReachCooldown = V
    State.DoorReachCooldown = V
end, 2)

SecInteract:AddSlider("Tầm mở cửa", 1, 75, 75, function(V)
    DoorReachDistance = V
    State.DoorReachDistance = V
end)

SecInteract:AddSlider("Tầm tương tác", 1, 2, 1, function(V)
    State.PromptReach = V
    for _, Prompt in Objects.Prompts do
        if Prompt and Prompt.Parent then
            local Old = Prompt:GetAttribute("MaxActivationDistance_Old")
            if Old then Prompt.MaxActivationDistance = Old * V end
        end
    end
end, 1)

Tabs.General:AddButton("Chơi lại", "Bấm", function()
    if RemotesFolder and RemotesFolder:FindFirstChild("PlayAgain") then RemotesFolder.PlayAgain:FireServer() end
end)

Tabs.General:AddButton("Về sảnh", "Bấm", function()
    if RemotesFolder and RemotesFolder:FindFirstChild("Lobby") then RemotesFolder.Lobby:FireServer() end
end)

Tabs.General:AddButton("Hồi sinh", "Bấm", function()
    if RemotesFolder and RemotesFolder:FindFirstChild("Revive") then RemotesFolder.Revive:FireServer() end
end)

local SecCh1 = MakeSection(Tabs.Exploits, "Doors Chapter 1", true)
local SecCh2 = MakeSection(Tabs.Exploits, "Doors Chapter 2", false)
local SecFun = MakeSection(Tabs.Exploits, "Doors giải trí", false)

SecCh2:AddSwitch("Anti Giggle", false, function(S)
    State.BypassGiggle = S
    for _, O in Objects.Entities do
        if O.Name == "GiggleCeiling" then
            for _, D in O:GetDescendants() do
                if D.Name == "Hitbox" and D:IsA("BasePart") then
                    D.CanTouch = not S
                end
            end
            if S and not O:GetAttribute("_GiggleWatcher") then
                O:SetAttribute("_GiggleWatcher", true)
                local HC = O.DescendantAdded:Connect(function(D)
                    if State.BypassGiggle and D.Name == "Hitbox" and D:IsA("BasePart") then
                        D.CanTouch = false
                    end
                end)
                table.insert(Connections, HC)
            end
        end
    end
end)

SecCh1:AddSwitch("Anti Dupe", false, function(S)
    State.BypassDupe = S
    for _, O in Objects.Traps do
        if O.Name == "DoorFake" or O.Name == "FakeDoor" then
            if O:FindFirstChild("Hidden") then O.Hidden.CanTouch = not S end
            if O:FindFirstChild("Lock") and O.Lock:FindFirstChild("UnlockPrompt") then O.Lock.UnlockPrompt.Enabled = not S end
        end
    end
end)

local function FireEyesBypass()
    if RemotesFolder and RemotesFolder:FindFirstChild("MotorReplication") then
        if Floor == "Fools" or Floor == "OldHotel" then RemotesFolder.MotorReplication:FireServer(0, 65, 0, false)
        else RemotesFolder.MotorReplication:FireServer(-650) end
    end
end

SecCh1:AddSwitch("Anti Eyes", false, function(S)
    State.BypassEyes = S
    if S then FireEyesBypass() end
end)

SecFun:AddSwitch("Anti Lookman", false, function(S)
    State.BypassLookman = S
    if S then FireEyesBypass() end
end)

SecCh2:AddSwitch("Anti Gloombat", false, function(S)
    State.BypassGloombatEggs = S
    for _, O in Objects.Traps do
        if O.Name == "GloomPile" then
            for _, P in O:GetDescendants() do
                if P:IsA("BasePart") then P.CanTouch = not S end
            end
        end
    end
end)

SecFun:AddSwitch("Anti Killbricks", false, function(S)
    State.BypassKillbricks = S
    for _, O in Objects.Obstructions do if O.Name == "Lava" then O.CanTouch = not S end end
end)

SecCh1:AddSwitch("Anti Snare", false, function(S)
    State.BypassSnare = S
    for _, O in Objects.Entities do
        if O.Name == "Snare" then for _, P in O:GetDescendants() do if P:IsA("BasePart") then P.CanTouch = not S end end end
    end
end)

SecFun:AddSwitch("Anti Vacuum", false, function(S)
    State.BypassVacuum = S
    for _, O in Objects.Traps do
        if O.Name == "SideroomSpace" then
            local Col = O:FindFirstChild("Collision")
            if Col then Col.CanCollide = S; Col.CanTouch = not S end
        end
    end
end)

SecFun:AddSwitch("Anti Banana", false, function(S)
    State.BypassBanana = S
    for _, O in Objects.Traps do
        if O.Name == "BananaPeel" then O.CanTouch = not S end
    end
end)

SecCh1:AddSwitch("Anti Jeff", false, function(S)
    State.BypassJeff = S
    for _, O in Objects.Traps do
        if O.Name == "JeffTheKiller" then
            for _, P in O:GetDescendants() do
                if P:IsA("BasePart") then P.CanCollide = not S; P.CanTouch = not S end
            end
            local Hum = O:FindFirstChild("Humanoid")
            if S and Hum then Hum.Health = 0 end
        end
    end
end)

local function SwapDamageRemotes(Keys, S)
    if not RemotesFolder then return end
    for _, Key in Keys do
        local Fake, Real = FakeEvents[Key], FakeEvents[Key .. "_Real"]
        if Real then
            if S then Fake.Parent = RemotesFolder; Real.Parent = nil
            else Real.Parent = RemotesFolder; Fake.Parent = nil end
        end
    end
end

SecCh1:AddSwitch("Anti Screech,Halt", false, function(S)
    State.NoScreechDamage = S
    State.NoHaltDamage = S
    SwapDamageRemotes({ "Screech", "Shade" }, S)
end)

SecFun:AddSwitch("Anti A-90,Surge", false, function(S)
    State.NoA90Damage = S
    State.NoSurgeDamage = S
    SwapDamageRemotes({ "A90", "Surge" }, S)
end)

SecCh1:AddSwitch("Tắt Jumpscare", false, function(S)
    State.DisableEntityJumpscares = S
    if ModuleRefs.SpiderJumpscare then ModuleRefs.SpiderJumpscare.Name = S and "SpiderJumpscare_Disabled" or "SpiderJumpscare" end
    for _, J in ipairs(JumpscareModules) do
        if J and J.Parent then
            local Orig = J:GetAttribute("OriginalName") or J.Name:gsub("_Disabled$", "")
            J.Name = S and (Orig .. "_Disabled") or Orig
        end
    end
end)

local function UpdateBeamVisibility(BeamTable, Visible)
    local Vis = Visible and 0 or 1
    local Seq = NumberSequence.new({ NumberSequenceKeypoint.new(0, Vis), NumberSequenceKeypoint.new(1, Vis) })
    for _, Beam in BeamTable do if Beam and Beam.Parent then Beam.Transparency = Seq end end
end
local function UpdateBeamColor(BeamTable, Value)
    local Seq = ColorSequence.new({ ColorSequenceKeypoint.new(0, Value), ColorSequenceKeypoint.new(1, Value) })
    for _, Beam in BeamTable do if Beam and Beam.Parent then Beam.Color = Seq end end
end

local SecSeek   = MakeSection(Tabs.Floors, "Seek", true)
local SecEye    = MakeSection(Tabs.Floors, "Eyestalk", false)
local SecFigure = MakeSection(Tabs.Floors, "Figure", false)

SecSeek:AddSwitch("Đường Seek", false, function(S) State.ShowSeekPath = S; UpdateBeamVisibility(Objects.SeekHighlights, S) end)

Globals.ColorChoices = { ["Hồng"] = Color3.fromRGB(255, 105, 180), ["Xanh lá"] = Color3.fromRGB(0, 255, 0), ["Xanh biển"] = Color3.fromRGB(0, 120, 255), ["Đen"] = Color3.fromRGB(0, 0, 0) }

SecSeek:AddDropdown("Màu Seek", { "Xanh lá", "Hồng", "Xanh biển", "Đen" }, function(V)
    local C = Globals.ColorChoices[V]
    if C then State.ShowSeekPathColor = C; UpdateBeamColor(Objects.SeekHighlights, C) end
end)

SecEye:AddSwitch("Đường Eyestalk", false, function(S) State.ShowEyestalkPath = S; UpdateBeamVisibility(Objects.EyestalkHighlights, S) end)

SecEye:AddDropdown("Màu Eyestalk", { "Xanh biển", "Hồng", "Xanh lá", "Đen" }, function(V)
    local C = Globals.ColorChoices[V]
    if C then State.ShowEyestalkPathColor = C; UpdateBeamColor(Objects.EyestalkHighlights, C) end
end)

SecSeek:AddSwitch("Tự lái Minecart", false, function(S) State.AutoSteerMinecart = S end)

SecSeek:AddTextBox("Cự ly rẽ", "30", function(T) State.MinecartTurnDistance = tonumber(T) or 30 end)

SecSeek:AddTextBox("Cự ly cúi", "50", function(T) State.MinecartDuckDistance = tonumber(T) or 50 end)

SecSeek:AddSwitch("Bỏ chướng ngại", false, function(S)
    State.BypassSeekObstructions = S
    for _, Obj in Objects.SeekObstructions do
        if Obj and Obj.Parent then
            Obj.CanTouch = not S
            if Obj.Name == "SeekFloodline" then Obj.CanCollide = S end
        end
    end
    for _, Bridge in Objects.SeekBridges do
        if Bridge and Bridge.Parent then Bridge.CanCollide = S; Bridge.Transparency = S and 0 or 1 end
    end
end)

SecSeek:AddSwitch("Anti Seeking Wall", false, function(S)
    State.BypassSeekingWall = S
    for _, O in Objects.Obstructions do
        if O.Name == "ScaryWall" then
            for _, P in O:GetDescendants() do
                if P:IsA("BasePart") then P.CanTouch = not S; P.CanCollide = not S end
            end
        end
    end
end)

SecSeek:AddSwitch("Xoá trigger Seek", false, function(S)
    State.RemoveSeekTrigger = S
    if S then
        for _, O in Objects.EventTriggers do Functions.StartSeekTrigger(O) end
    end
end)

SecFigure:AddSwitch("Figure Godmode", false, function(S)
    State.FigureGodmode = S
    Functions.Notify("Figure Godmode", S
        and "Đã bật — tự đẩy va chạm xuống khi Figure tới gần"
        or  "Đã tắt")
end)

SecFigure:AddSwitch("Auto Minigame(beta)", false, function(S)
    State.AutoHeartbeatMinigame = S
    Functions.Notify("Heartbeat Minigame", S
        and "Đã bật — sẽ không bao giờ thua khi Figure bắt"
        or  "Đã tắt")
end)

SecFigure:AddSwitch("Xoá Figure", false, function(S)
    State.RemoveFigure = S
    if S then
        for _, O in ipairs(Objects.Entities) do
            if FigureNames[O.Name] then
                for _, P in O:GetDescendants() do
                    if P:IsA("BasePart") then
                        P.CanCollide = false
                        pcall(function() P.Position = Vector3.new(-49999, -49999, -49999) end)
                    end
                end
            end
        end
    end
    Functions.Notify("Xoá Figure", S and "Đã bật" or "Đã tắt")
end)

SecFigure:AddSwitch("Tự mở khoá thư viện", false, function(S)
    State.AutoUnlockPadlock = S
    Functions.Notify("Auto Padlock", S and "Đã bật — tự nhập code khi tới gần ổ khoá" or "Đã tắt")
end)

SecFigure:AddSlider("Cự ly mở khoá", 1, 50, 10, function(V)
    State.AutoUnlockDistance = V
end)

SecFigure:AddSwitch("Tự giải cầu giao", false, function(S)
    State.AutoBreakerBox = S
    Globals.BreakerBoxNotified         = false
    Globals.BreakerBoxStartNotified    = false
    Globals.BreakerBoxFinishedNotified = false
    if S then
        local BreakerBox = CurrentRooms:FindFirstChild("ElevatorBreaker", true)
        if BreakerBox then
            if not Globals.BreakerBoxInteracted then
                Functions.Notify("Breaker Box", "Hãy tương tác với hộp cầu giao — sẽ tự động giải")
                Globals.BreakerBoxNotified = true
            else
                pcall(function() RemotesFolder.EBF:FireServer() end)
            end
        else
            Functions.Notify("Breaker Box", "Bật — sẽ tự giải khi gặp hộp cầu giao")
        end
    else
        Functions.Notify("Breaker Box", "Đã tắt")
    end
end)

-- ============================================================
-- ESP: ESPApply[Key](S) bật/tắt thật sự; ESPWanted[Key]: người dùng muốn bật hay không
-- Tiện ích "Tắt ESP đã chọn" (tab Tiện ích) có thể tạm tắt một số loại ESP
-- ============================================================
local ESPApply, ESPWanted = {}, {}
Globals.ESPMuteOn = false
Globals.ESPMuteSel = {}
local ESPApplied = {}

ESPApply.Door = function(S)
    State.DoorESP = S
    for _, O in Objects.Doors do
        if S then Functions.AddESP({ Object = O, Text = "Cửa " .. Functions.GetDoorNumber(O), Color = State.DoorColor }, true)
        else Functions.RemoveESP(O) end
    end
end

ESPApply.Entity = function(S)
    State.EntityESP = S
    for _, O in Objects.Entities do
        if S then
            Functions.AddESP({ Object = O, Text = Functions.GetEntityText(O), Color = State.EntityColor, AlwaysTracer = (O.Name ~= "Snare"), NoTracer = (O.Name == "Snare") }, false)
        else Functions.RemoveESP(O) end
    end

    for _, O in Objects.Traps do
        if O.Name == "DoorFake" or O.Name == "FakeDoor" then
            if S then
                Functions.AddESP({ Object = O, Text = "Dupe", Color = State.EntityColor, AlwaysTracer = true }, O:GetAttribute("ParentRoom") ~= nil)
            else
                Functions.RemoveESP(O)
            end
        end
    end
end

ESPApply.Item = function(S)
    State.ItemESP = S
    State.LeverESP = S
    State.HintBookESP = S
    for _, O in Objects.Items do
        if S then
            local Label = O:GetAttribute("ESP_Label") or ItemNames[O.Name] or O.Name
            local Col = State.ItemColor
            if O.Name == "Key" then Col = Color3.fromRGB(255, 215, 0) end
            Functions.AddESP({ Object = O, Text = Label, Color = Col }, O:GetAttribute("ParentRoom") ~= nil)
        else
            Functions.RemoveESP(O)
        end
    end
end

ESPApply.Player = function(S)
    State.PlayerESP = S
    for _, P in Services.Players:GetPlayers() do
        if P ~= LocalPlayer and P.Character then
            if S then Functions.AddESP({ Object = P.Character, Text = P.Name, Color = State.PlayerColor })
            else Functions.RemoveESP(P.Character) end
        end
    end
end

ESPApply.Chest = function(S)
    State.ChestESP = S
    for _, O in Objects.Chests do
        if S then Functions.AddESP({ Object = O, Text = "Rương", Color = State.ChestColor }, true)
        else Functions.RemoveESP(O) end
    end
end

ESPApply.Hiding = function(S)
    State.HidingESP = S
    for _, O in Objects.HidingSpots do
        if S then Functions.AddESP({ Object = O, Text = "Tủ", Color = State.HidingColor }, true)
        else Functions.RemoveESP(O) end
    end
end

ESPApply.Ladder = function(S)
    State.LadderESP = S
    for _, O in Objects.Ladders do
        if O.Name == "Ladder" then
            if S then Functions.AddESP({ Object = O, Text = "Thang", Color = State.LadderColor }, true)
            else Functions.RemoveESP(O) end
        end
    end
end

local ESPOrder = { "Door", "Entity", "Item", "Player", "Chest", "Hiding", "Ladder" }

local function IsESPMuted(Key)
    return Globals.ESPMuteOn == true and Globals.ESPMuteSel[Key] == true
end

-- đồng bộ ESP thật sự với: người dùng có muốn bật không và có đang bị tiện ích tắt không
local function SyncESP(Key)
    local Want = ESPWanted[Key] == true and not IsESPMuted(Key)
    if Want ~= (ESPApplied[Key] == true) then
        ESPApplied[Key] = Want
        pcall(ESPApply[Key], Want)
    end
end

local function BindESPSwitch(Title, Key)
    Tabs.Visuals:AddSwitch(Title, false, function(S)
        ESPWanted[Key] = S and true or false
        SyncESP(Key)
    end)
end

BindESPSwitch("ESP Cửa", "Door")
BindESPSwitch("ESP Thực thể", "Entity")

Tabs.Visuals:AddSwitch("Hiện tên quái vật", false, function(S)
    State.EntityNameESP = S
    for _, O in Objects.Entities do
        if ESP.ElementsEnabled[O] then ESP.TextTable[O] = Functions.GetEntityText(O) end
    end
end)

BindESPSwitch("ESP Vật phẩm", "Item")
BindESPSwitch("ESP Người", "Player")
BindESPSwitch("ESP Rương", "Chest")
BindESPSwitch("ESP Chỗ trốn", "Hiding")
BindESPSwitch("ESP Thang", "Ladder")

-- Tiện ích (tab Tiện ích): bật công tắc chính thì tắt các loại ESP đã chọn, tắt công tắc thì bật lại
-- những ESP mà bạn đã bật từ trước
local SecUtilESP = MakeSection(Tabs.Utility, "Tắt ESP tạm thời", false)
local ESPTitles = {
    Door = "ESP Cửa", Entity = "ESP Thực thể", Item = "ESP Vật phẩm", Player = "ESP Người",
    Chest = "ESP Rương", Hiding = "ESP Chỗ trốn", Ladder = "ESP Thang",
}

local function SetESPMute(On)
    Globals.ESPMuteOn = On and true or false
    for _, Key in ipairs(ESPOrder) do SyncESP(Key) end
end

SecUtilESP:AddSwitch("Nút tắt ESP", false, function(S)
    SetWidget("ESPMute", S, "Tắt ESP", 132,
        function() return Globals.ESPMuteOn end,
        function() SetESPMute(not Globals.ESPMuteOn) end)
    -- ẩn nút thì trả ESP về bình thường để không bị kẹt ở trạng thái đang tắt
    if not S and Globals.ESPMuteOn then
        SetESPMute(false)
        SettingsData.Values["Utility/WidgetState_ESPMute"] = false
        if SettingsData.Enabled then SaveSettings() end
    end
end)

SecUtilESP:AddSwitch("Khoá nút tắt ESP", false, function(S)
    WidgetLock.ESPMute = S
end)

for _, Key in ipairs(ESPOrder) do
    SecUtilESP:AddSwitch("Chọn tắt: " .. ESPTitles[Key], false, function(S)
        Globals.ESPMuteSel[Key] = S and true or false
        SyncESP(Key)
    end)
end

Tabs.Visuals:AddSwitch("ESP Cầu vồng", false, function(S) State.ESPRainbow = S; ESP.Rainbow = S end)

Tabs.Visuals:AddSwitch("khoảng cách", false, function(S) State.ESPShowDistance = S; ESP.ShowDistance = S end)

ESP.TracerOrigin = "Bottom"
ESP.TracerSize = 0.75
Tabs.Visuals:AddSwitch("Đường Kẻ", false, function(S)
    State.ESPTracers = S
    ESP.TracerOrigin = "Bottom"
    ESP.TracerSize = 0.75
    ESP:SetTracers(S)
end)


Tabs.Visuals:AddTextBox("Cỡ chữ ESP", "20", function(T)
    local V = tonumber(T) or 20
    State.ESPTextSize = V
    ESP:SetTextSize(V)
end)

Tabs.Visuals:AddSwitch("Bỏ Cutscene", false, function(S)
    State.RemoveCutscenes = S
    local CutsceneNames = {"Figure","FigureEnd","FigureHotelEnd","FigureHotelFire","SeekIntroFools","SeekIntroHotel","SeekIntroMines","SewerSeekLower","GrumbleNestEnd","EyestalkIntro"}
    local Cutscenes = Functions.GetCutscenes(); if not Cutscenes then return end
    for _, O in Cutscenes:GetChildren() do
        if O:IsA("ModuleScript") then
            local Orig = O:GetAttribute("OriginalName") or O.Name
            if table.find(CutsceneNames, Orig) then
                O:SetAttribute("OriginalName", Orig)
                O.Name = S and (Orig .. "_Disabled") or Orig
            end
        end
    end
end)

Tabs.Visuals:AddSwitch("Cảnh báo thực thể", true, function(S)
    NotifyEnabled = S
    if not S then
        ESP:ClearEntityAlerts()
        ESP:RefreshEntityAlertLabel()
    end
end)

Tabs.Camera:AddSwitch("Bật FOV", false, function(S)
    State.FOVEnabled = S
    local cam = Workspace.CurrentCamera
    if cam then
        cam.FieldOfView = S and State.FieldOfView or 70
    end
end)

Tabs.Camera:AddSlider("POV", 70, 120, 70, function(v)
    State.FieldOfView = v
    if State.FOVEnabled then
        local cam = Workspace.CurrentCamera
        if cam then cam.FieldOfView = v end
    end
end)

Tabs.Camera:AddSwitch("Không rung camera", false, function(S)
    State.RemoveCameraShake = S
    if S then
        local MG = Functions.GetMainGame()
        if MG and type(MG) == "table" then
            pcall(function() MG.csgo = CFrame.new() end)
        end
    end
end)

Tabs.Camera:AddSwitch("Khoá cứng camera", false, function(S)
    State.RemoveCameraBobbing = S
    local MG = Functions.GetMainGame()
    if MG and type(MG) == "table" then
        pcall(function()
            if MG.spring then MG.spring.Speed = S and 9e9 or 8 end
        end)
    end
end)

local SecThird = MakeSection(Tabs.Camera, "Góc nhìn thứ ba", false)
SecThird:AddSwitch("Góc nhìn thứ ba", false, function(S)
    State.ThirdPerson = S
    if Functions.RefreshThirdPersonParts then Functions.RefreshThirdPersonParts() end
    if Functions.RefreshThirdPersonWidget then Functions.RefreshThirdPersonWidget() end
end)

SecThird:AddSlider("X", -10, 10, 1.5, function(v) State.ThirdPersonX = v end, 1)
SecThird:AddSlider("Y", -10, 10, 1, function(v) State.ThirdPersonY = v end, 1)
SecThird:AddSlider("Z", -10, 10, 5, function(v) State.ThirdPersonZ = v end, 1)

SecThird:AddSwitch("Chống camera xuyên tường", false, function(S)
    State.ThirdPersonWallCheck = S
end)

Tabs.Camera:AddSwitch("Night Vision", false, function(S)
    State.Ambient = S
    local CR = CurrentRooms:FindFirstChild(tostring(LocalPlayer:GetAttribute("CurrentRoom")))
    if CR then
        local OldAmbient = CR:GetAttribute("Ambient") or Color3.fromRGB(0,0,0)
        TweenService:Create(Lighting, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {
            Ambient = S and State.AmbientColor or OldAmbient
        }):Play()
    end
end)

Tabs.Camera:AddSwitch("Xoá sương mù", false, function(S)
    State.RemoveFog = S
    Lighting.FogEnd = S and 10000000 or OldFog
    for _, Object in FogInstances do Object.Density = S and 0 or (Object:GetAttribute("Density_Old") or 0) end
end)

local PromptLastFire = setmetatable({}, { __mode = "k" })
local PromptsToFire = {}; local PromptCooldown = {}; local TriggerDebounce = false; local LastAutoInteractFire = 0

if typeof(fireproximityprompt) == "function" then
    Functions.FirePrompt = function(P)
        if not P or not P:IsA("ProximityPrompt") then return end
        pcall(fireproximityprompt, P)
    end
    Functions.ForceFirePrompt = Functions.FirePrompt
else
    Functions.FirePrompt = function(P)
        if not P or not P:IsA("ProximityPrompt") then return end
        if PromptCooldown[P] or table.find(PromptsToFire, P) or not Camera then return end
        table.insert(PromptsToFire, P)
    end
    Functions.ForceFirePrompt = Functions.FirePrompt
    task.spawn(function()
        while task.wait() do
            local Prompt = table.remove(PromptsToFire, 1); if not Prompt then continue end
            PromptCooldown[Prompt] = true
            local OldDist, OldEnable, OldParent = Prompt.MaxActivationDistance, Prompt.Enabled, Prompt.Parent
            local OldHold, OldLOS = Prompt.HoldDuration, Prompt.RequiresLineOfSight
            Prompt.MaxActivationDistance = 99999; Prompt.Enabled = true
            Prompt.HoldDuration = 0; Prompt.RequiresLineOfSight = false
            local TempPart = Instance.new("Part", Workspace)
            TempPart.CanCollide = false; TempPart.CanQuery = false; TempPart.CanTouch = false
            TempPart.Anchored = true; TempPart.Transparency = 1
            TempPart.Size = Vector3.new(0.001, 0.001, 0.001)
            TempPart.Position = Camera.CFrame:ToWorldSpace(CFrame.new(0, 0, -0.1)).Position
            if not Prompt or not OldParent then TempPart:Destroy(); PromptCooldown[Prompt] = nil; continue end
            pcall(function() Prompt.Parent = TempPart end)
            local Shown, Fired = false, false
            local SC = ProximityPromptService.PromptShown:Connect(function(P) if P == Prompt then Shown = true end end)
            local FC = Prompt.Triggered:Connect(function() Fired = true end)
            local T1 = 0; while not Shown and T1 < 5 do T1 += 1 task.wait() end
            local T2 = 0; while not Fired and T2 < 5 do Prompt:InputHoldBegin(); Prompt:InputHoldEnd(); T2 += 1 task.wait() end
            Prompt.MaxActivationDistance = OldDist; Prompt.Enabled = OldEnable
            Prompt.HoldDuration = OldHold; Prompt.RequiresLineOfSight = OldLOS
            pcall(function() Prompt.Parent = OldParent end)
            task.wait(); PromptCooldown[Prompt] = nil; TempPart:Destroy(); SC:Disconnect(); FC:Disconnect()
        end
    end)
end

local AutoInteractBlacklist = {
    HidePrompt=true, RiftPrompt=true, StarRiftPrompt=true, InteractPrompt=true, ClimbPrompt=true,
    DonatePrompt=true, DialoguePrompt=true, RevivePrompt=true, EnterPrompt=true, AnimatePrompt=true,
    ToolEventPrompt=true, Prompt=true, PropPrompt=true, SeatPrompt=true
}

local function PackFull(Pack)
    local D, M = Pack:GetAttribute("Durability"), Pack:GetAttribute("DurabilityMax")
    return D ~= nil and M ~= nil and D >= M
end

function Functions.TriggerPrompt(Prompt)
    if not Prompt or not Prompt.Parent then return end
    if AutoInteractBlacklist[Prompt.Name] then return end

    local Last = PromptLastFire[Prompt]
    if Last and tick() - Last < State.InteractCooldown then return end
    if TriggerDebounce then return end
    if not Character or not Humanoid then return end
    local Parent = Prompt.Parent; local ParentName = Parent.Name; local GrandParent = Parent.Parent
    local ParentItem = Functions.HasItem(ParentName)
    if ParentItem and ParentItem:GetAttribute("Durability") and ParentItem:GetAttribute("DurabilityMax")
        and ParentItem:GetAttribute("Durability") >= ParentItem:GetAttribute("DurabilityMax") then return end
    local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }
    local IsLockPrompt = LockPromptNames[Prompt.Name] or Parent:GetAttribute("Locked") == true
        or (GrandParent and GrandParent.Name == "Locker_Small_Locked" and Prompt.Name == "ActivateEventPrompt")
    if IsLockPrompt then
        if State.AutoInteractIgnore["Locks"] then return end
        local KeyItems = { "Key","GeneratorFuse","KeyBackdoor","KeyElectrical","KeyIron","Lockpick","SkeletonKey","Shears","Multitool" }
        local OffhandKeyItems = { "Key","GeneratorFuse","KeyElectrical","KeyIron" }
        local HasKey = false
        for _, K in KeyItems do if Functions.HasItem(K, true) then HasKey = true; break end end
        for _, K in OffhandKeyItems do if Functions.HasItem(K) then HasKey = true; break end end
        if not HasKey then return end
    end
    if (ParentName == "CuttableVines" or ParentName == "Chest_Vine" or ParentName == "Cellar")
        and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) then return end
    if ParentName == "SkullLock" and not Functions.HasItem("SkeletonKey", true) then return end
    if (ParentName == "Lock1" or ParentName == "Lock2")
        and not Functions.HasItem("Lockpick", true) and not Functions.HasItem("Multitool", true) then return end
    if Functions.HasItem("Shears", true) and IsLockPrompt
        and ParentName ~= "CuttableVines" and ParentName ~= "Chest_Vine" and ParentName ~= "Cellar" then return end
    if ParentName == "GlitchCube" and State.AutoInteractIgnore["Glitch Fragments"] then return end
    if (ParentName == "KeyObtain" and (Functions.HasItem("Key") or Functions.HasItem("KeyBackdoor")))
        or (ParentName == "ElectricalKeyObtain" and Functions.HasItem("KeyElectrical")) then return end
    local Drops = Workspace:FindFirstChild("Drops")
    if Drops and Prompt:IsDescendantOf(Drops) then return end
    if ParentName == "TrackLever" then return end
    if Prompt.Name == "ActivateEventPrompt" and (Prompt.ActionText == "Close"
        or ParentName == "ElevatorBreaker" or (GrandParent and GrandParent.Name == "IndustrialGate")) then return end
    if Prompt.Name == "ActivateEventPrompt" and (ParentName == "Padlock" or ParentName == "MinesAnchor") then return end
    if ParentName == "LeverForGate" and Prompt:GetAttribute("Interactions") then return end
    if GrandParent and (GrandParent.Name == "DoorFake" or GrandParent.Name == "FakeDoor") then return end
    if Parent:GetAttribute("JeffShop") and State.AutoInteractIgnore["Jeff Items"] then return end
    if Prompt:GetAttribute("AutoInteractIgnore") then return end
    if Prompt.Name == "PushPrompt" and State.AutoInteractIgnore["Minecarts"] then return end
    if (ParentName == "GoldPile" or ParentName == "StardustPickup") and State.AutoInteractIgnore["Currency"] then return end
    if ParentName == "Bandage" then
        local BPack = Functions.HasItem("BandagePack")
        if Humanoid.Health >= Humanoid.MaxHealth and not BPack then return end
        if BPack and PackFull(BPack) then return end
    end
    if ParentName == "Battery" then
        local Tool = Character:FindFirstChildOfClass("Tool"); local BPack = Functions.HasItem("BatteryPack")
        if not Tool and not BPack then return end
        if Tool and Tool:GetAttribute("LightSource") then
            if Tool:GetAttribute("Durability") and Tool:GetAttribute("DurabilityMax")
                and Tool:GetAttribute("Durability") > Tool:GetAttribute("DurabilityMax") then return end
        elseif not BPack then return end
        if BPack and PackFull(BPack) then return end
    end
    if Prompt.Name == "HerbPrompt" then
        local MainUI = LocalPlayer.PlayerGui:FindFirstChild("MainUI")
        if MainUI then
            local Healthbar = MainUI.MainFrame and MainUI.MainFrame:FindFirstChild("Healthbar")
            local Effects = Healthbar and Healthbar:FindFirstChild("Effects")
            if Effects and Effects:FindFirstChild("HerbGreenEffect") and Effects.HerbGreenEffect.Visible then return end
        end
    end
    if (ParentName == "LibraryHintPaper" or ParentName == "PickupItem")
        and (Functions.HasItem("LibraryHintPaper") or Functions.HasItem("LibraryHintPaperHard")) then return end
    if ParentName == "AlarmClock" and Functions.HasItem("AlarmClock") then return end
    if ParentName == "KeyObtainFake" or ParentName == "TithingPlate" then return end
    PromptLastFire[Prompt] = tick()
    Functions.FirePrompt(Prompt)
    TriggerDebounce = true; if Floor == "OldHotel" then task.wait() end; TriggerDebounce = false
end

Connections.AutoInteract = RunService.Heartbeat:Connect(function()
    if not State.AutoInteract then return end
    if tick() - LastAutoInteractFire < 1/60 then return end
    for _, Prompt in Objects.Prompts do
        if not Prompt or not Prompt.Parent then continue end
        local PRoom = Prompt:GetAttribute("ParentRoom")
        if PRoom and tonumber(PRoom) ~= tonumber(LocalPlayer:GetAttribute("CurrentRoom")) then continue end
        local Parent = Prompt.Parent; local Distance
        if Parent:IsA("BasePart") then Distance = LocalPlayer:DistanceFromCharacter(Parent.Position)
        elseif Parent:IsA("Model") and Parent.PrimaryPart then Distance = LocalPlayer:DistanceFromCharacter(Parent.PrimaryPart.Position)
        else continue end
        if Distance and Distance <= Prompt.MaxActivationDistance
            and (Prompt.Enabled or Prompt.Name == "LongPushPrompt" or Prompt.Name == "BigPropPrompt") then
            task.spawn(Functions.TriggerPrompt, Prompt)
        end
    end
    LastAutoInteractFire = tick()
end)

function Functions.HandleCharacter(NewChar)
    if Connections.MainHandler then Connections.MainHandler:Disconnect() end
    if Connections.AutoClosetHandler then Connections.AutoClosetHandler:Disconnect() end

    Character = NewChar
    Humanoid = NewChar:WaitForChild("Humanoid", 9e9)

    if Connections.SpeedLock then Connections.SpeedLock:Disconnect() end
    pcall(function()
        local LT = NewChar:FindFirstChild("LowerTorso")
        if LT and LT:FindFirstChild("Root") then Globals.OriginalC1 = LT.Root.C1 end
    end)
    Globals.C1Locked = false
    Globals.WallPassLinger = false
    Globals.WallPassPrev = false
    Globals.WallPassY = nil
    Connections.SpeedLock = Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if State.SpeedBoost and Humanoid and Humanoid.WalkSpeed ~= State.SpeedValue then
            Humanoid.WalkSpeed = State.SpeedValue
        end
    end)
    RootPart = NewChar:FindFirstChild("HumanoidRootPart")
    CurrentCamera = Workspace.CurrentCamera
    Camera = Workspace.CurrentCamera

    while not LocalPlayer.PlayerGui:FindFirstChild("MainUI") do task.wait() end

    task.spawn(function()
        task.wait(0.8)
        Functions.ResolveModules()
        if RemotesFolder then
            if not FakeEvents.Screech_Real then FakeEvents.Screech_Real = RemotesFolder:FindFirstChild("Screech") end
            if not FakeEvents.Shade_Real then FakeEvents.Shade_Real = RemotesFolder:FindFirstChild("ShadeResult") end
            if not FakeEvents.A90_Real then FakeEvents.A90_Real = RemotesFolder:FindFirstChild("A90") end
            if not FakeEvents.Surge_Real then FakeEvents.Surge_Real = RemotesFolder:FindFirstChild("SurgeRemote") end
        end
        if State.NoScreechDamage and FakeEvents.Screech_Real then FakeEvents.Screech.Parent = RemotesFolder; FakeEvents.Screech_Real.Parent = nil end
        if State.NoHaltDamage and FakeEvents.Shade_Real then FakeEvents.Shade.Parent = RemotesFolder; FakeEvents.Shade_Real.Parent = nil end
        if State.NoA90Damage and FakeEvents.A90_Real then FakeEvents.A90.Parent = RemotesFolder; FakeEvents.A90_Real.Parent = nil end
        if State.NoSurgeDamage and FakeEvents.Surge_Real then FakeEvents.Surge.Parent = RemotesFolder; FakeEvents.Surge_Real.Parent = nil end
        if State.RemoveScreech then
            if ModuleRefs.Screech then ModuleRefs.Screech.Name = "Screech_Disabled" end
            if ModuleRefs.GlitchScreech then ModuleRefs.GlitchScreech.Name = "GlitchScreech_Disabled" end
        end
        if State.RemoveHalt and ModuleRefs.Shade then ModuleRefs.Shade.Name = "Shade_Disabled" end
        if State.RemoveA90 and ModuleRefs.A90 then ModuleRefs.A90.Name = "A90_Disabled" end
        if State.RemoveDread and ModuleRefs.Dread then ModuleRefs.Dread.Name = "Dread_Disabled" end
        if State.DisableEntityJumpscares and ModuleRefs.SpiderJumpscare then ModuleRefs.SpiderJumpscare.Name = "SpiderJumpscare_Disabled" end
    end)

    Collision = NewChar:WaitForChild("Collision", 9e9)
    CollisionPart = NewChar:FindFirstChild("CollisionPart") or NewChar:FindFirstChild("Collision")
    if CollisionClone then CollisionClone:Destroy() end
    if CollisionPartClone then CollisionPartClone:Destroy() end
    CollisionClone = Collision:Clone(); CollisionClone.Parent = NewChar; CollisionClone.Name = "CollisionClone"; CollisionClone.Massless = true
    CollisionPartClone = CollisionPart:Clone(); CollisionPartClone.Parent = NewChar; CollisionPartClone.Name = "CollisionPartClone"; CollisionPartClone.CanCollide = false; CollisionPartClone.Massless = true

    Connections.MainHandler = RunService.RenderStepped:Connect(function()
        if not Character or not Humanoid or not RootPart or not Collision then return end

        if State.SpeedBoost and Humanoid.WalkSpeed ~= State.SpeedValue then Humanoid.WalkSpeed = State.SpeedValue end
        if State.WallPass then
            Globals.WallPassLinger = false
        elseif Globals.WallPassPrev then
            Globals.WallPassLinger = true
        elseif Globals.WallPassLinger and Humanoid.MoveDirection.Magnitude > 0 then
            Globals.WallPassLinger = false
        end
        Globals.WallPassPrev = State.WallPass and true or false
        local NoCol = State.PositionSpoof or State.WallPass or Globals.WallPassLinger == true

        if Floor == "OldHotel" or Floor == "Fools" then
            local GodmodeSpoof = State.FigureGodmode and Functions.GetNearestFigure() ~= nil
            local SpoofOffset = (State.PositionSpoof or GodmodeSpoof) and 200 or 0
            Globals.SpoofOffset = SpoofOffset
            Collision.Position = RootPart.Position + Vector3.new(0, SpoofOffset, 0)
            Collision.CanCollide = false
            if Floor == "Fools" and Collision:FindFirstChild("CollisionCrouch") then
                Collision.CollisionCrouch.CanCollide = false
                if CollisionClone and CollisionClone:FindFirstChild("CollisionCrouch") then CollisionClone.CollisionCrouch.CanCollide = false end
            end
            RootPart.CanCollide = not NoCol
        else
            Collision.CanCollide = false
            if Collision:FindFirstChild("CollisionCrouch") then Collision.CollisionCrouch.CanCollide = false end
            if CollisionClone and CollisionClone:FindFirstChild("CollisionCrouch") then
                local IsCrouch = Functions.IsCrouching()
                CollisionClone.CanCollide = not (NoCol or IsCrouch)
                CollisionClone.CollisionCrouch.CanCollide = not (NoCol or not IsCrouch)
            else
                RootPart.CanCollide = not NoCol
            end
        end

        if CollisionClone then
            CollisionClone.CollisionGroup = Collision.CollisionGroup
            local SrcCrouch = Collision:FindFirstChild("CollisionCrouch")
            local CloneCrouch = CollisionClone:FindFirstChild("CollisionCrouch")
            if SrcCrouch and CloneCrouch then CloneCrouch.CollisionGroup = SrcCrouch.CollisionGroup end
        end

        if State.WallPass then
            for _, Part in Character:GetChildren() do
                if Part:IsA("BasePart") and Part.CanCollide then Part.CanCollide = false end
            end
        end

        if not Globals.WallPassBody then
            Globals.WallPassBody = Instance.new("BodyVelocity")
            Globals.WallPassBody.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        end
        local WPCam = Workspace.CurrentCamera
        local WPActive = State.WallPass or Globals.WallPassLinger == true
        if WPActive and WPCam then
            if not Globals.WallPassY then Globals.WallPassY = RootPart.Position.Y end
            local Dir = Vector3.zero
            if State.WallPass then
                local Look = WPCam.CFrame.LookVector
                local Flat = Vector3.new(Look.X, 0, Look.Z)
                if Flat.Magnitude > 0.01 then Dir = Flat.Unit * State.WallPassSpeed end
            end
            Globals.WallPassBody.MaxForce = State.WallPass and Vector3.new(9e9, 9e9, 9e9) or Vector3.new(0, 9e9, 0)
            Globals.WallPassBody.Velocity = Vector3.new(Dir.X, 0, Dir.Z)
            Globals.WallPassBody.Parent = RootPart
            local DY = Globals.WallPassY - RootPart.Position.Y
            if math.abs(DY) > 0.05 then RootPart.CFrame = RootPart.CFrame + Vector3.new(0, DY, 0) end
        else
            Globals.WallPassBody.Parent = nil
            Globals.WallPassY = nil
        end

        if State.RemoveFog then Lighting.FogEnd = 1e7 end

        local MG = Main_Game or Functions.GetMainGame()
if MG and type(MG) == "table" then
    if State.RemoveCameraShake then
        pcall(function() MG.csgo = CFrame.new() end)
    end
    if State.RemoveCameraBobbing then
        pcall(function() if MG.spring then MG.spring.Speed = 9e9 end end)
    end
end
end)

    local LastHide = 0
    Connections.AutoClosetHandler = RunService.Heartbeat:Connect(function()
        if not State.AutoCloset then return end
        if tick() - LastHide < 0.2 then return end
        LastHide = tick()
        for _, E in Objects.Entities do
            local Alias = Entities[E.Name] and Entities[E.Name].Alias
            if Alias and E.PrimaryPart then
                local D = LocalPlayer:DistanceFromCharacter(E.PrimaryPart.Position)
                if D < 85 and Character:GetAttribute("Hiding") ~= true then
                    local Closest, CD = nil, math.huge
                    for _, H in Objects.HidingSpots do
                        if H.PrimaryPart then
                            local HD = LocalPlayer:DistanceFromCharacter(H.PrimaryPart.Position)
                            if HD < CD and HD < 50 then CD = HD; Closest = H end
                        end
                    end
                    if Closest and Closest:FindFirstChild("HidePrompt") then
                        if fireproximityprompt then pcall(fireproximityprompt, Closest.HidePrompt) end
                    end
                end
            end
        end
    end)

    if JumpButtonConnection then JumpButtonConnection:Disconnect() end
    if CanJumpConn then CanJumpConn:Disconnect() end
    if OldJump == nil then OldJump = NewChar:GetAttribute("CanJump") end
    Character:SetAttribute("CanJump", State.EnableCharacterJump and true or OldJump)

    task.spawn(function()
        local MainUI = LocalPlayer.PlayerGui:WaitForChild("MainUI", 10); if not MainUI then return end
        local MainFrame = MainUI:FindFirstChild("MainFrame"); if not MainFrame then return end
        local MobileButtons = MainFrame:FindFirstChild("MobileButtons"); if not MobileButtons then return end
        local JumpButton = MobileButtons:FindFirstChild("JumpButton"); if not JumpButton then return end
        JumpButtonConnection = JumpButton.MouseButton1Down:Connect(function()
            if not State.InfiniteJumps then return end
            if not Humanoid or Humanoid.Health <= 0 then return end
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end)

    CanJumpConn = NewChar:GetAttributeChangedSignal("CanJump"):Connect(function()
        if State.EnableCharacterJump and NewChar:GetAttribute("CanJump") ~= true then NewChar:SetAttribute("CanJump", true) end
    end)

    if Connections.NoDamageHook then Connections.NoDamageHook:Disconnect() end
    local Thresholds = { Screech = 5, Halt = 10, A90 = 5, Surge = 5 }
    local LastHealth = Humanoid.Health
    Connections.NoDamageHook = Humanoid.HealthChanged:Connect(function(NewHealth)
        if NewHealth >= LastHealth then LastHealth = NewHealth; return end
        local Delta = LastHealth - NewHealth; LastHealth = NewHealth
        local function Heal(Flag, Key)
            if Flag and Delta <= Thresholds[Key] and Humanoid.Health + Delta <= Humanoid.MaxHealth then
                Humanoid.Health = Humanoid.Health + Delta
            end
        end
        Heal(State.NoScreechDamage, "Screech")
        Heal(State.NoHaltDamage, "Halt")
        Heal(State.NoA90Damage, "A90")
        Heal(State.NoSurgeDamage, "Surge")
    end)
end

function Functions.StartSeekTrigger(Object)
    if not Object or Object:GetAttribute("_SeekTriggerRunning") then return end
    if typeof(firetouchinterest) ~= "function" then return end
    if not (Floor == "Fools" or Floor == "OldHotel") then return end
    Object:SetAttribute("_SeekTriggerRunning", true)
    task.spawn(function()
        while State.RemoveSeekTrigger and Object:IsDescendantOf(game) do
            for _, Part in Object:GetChildren() do
                if Part:IsA("BasePart") and RootPart then
                    firetouchinterest(RootPart, Part, 0)
                    task.wait()
                    firetouchinterest(RootPart, Part, 1)
                end
            end
            task.wait()
        end
        pcall(function() Object:SetAttribute("_SeekTriggerRunning", nil) end)
    end)
end

function Functions.HandleObject(Object)

    for _, Room in CurrentRooms:GetChildren() do
        if Object:IsDescendantOf(Room) then Object:SetAttribute("ParentRoom", tonumber(Room.Name)); break end
    end
    local Name = Object.Name

    if Name == "Door" and Object.Parent and tonumber(Object.Parent.Name) then
        local DoorParts = {}
        for _, C in Object:GetChildren() do
            if C.Name == "Door" and C:IsA("BasePart") then table.insert(DoorParts, C) end
        end
        if #DoorParts >= 1 then

            local Model = Instance.new("Model", Object)
            Model.Name = "ESPModel"; Instance.new("Humanoid", Model).Name = "ESPHumanoid"
            Model:SetAttribute("ParentRoom", tonumber(Object.Parent.Name))
            for _, D in DoorParts do
                local HP = Instance.new("Part", Model)
                HP.Transparency = 0.999; HP.Size = D.Size; HP.CanCollide = false; HP.CFrame = D.CFrame
                HP:SetAttribute("ParentRoom", tonumber(Object.Parent.Name))
                local W = Instance.new("WeldConstraint", HP); W.Part0 = HP; W.Part1 = D
            end
            table.insert(Objects.Doors, Model)
            if State.DoorESP then
                Functions.AddESP({ Object = Model, Text = "Cửa " .. Functions.GetDoorNumber(Object), Color = State.DoorColor }, true)
            end
        end
        table.insert(DoorReachTargets, Object)
        Functions.SetupDoorReach(Object)

    elseif Name == "Wardrobe" or Name == "Locker_Large" or Name == "Bed"
        or Name == "RetroWardrobe" or Name == "Backdoor_Wardrobe" or Name == "Rooms_Locker" then
        local Label = "Tủ"
        if Name == "Locker_Large" or Name == "Rooms_Locker" then Label = "Tủ lớn"
        elseif Name == "Bed" then Label = "Giường" end
        table.insert(Objects.HidingSpots, Object)
        if State.HidingESP then Functions.AddESP({ Object = Object, Text = Label, Color = State.HidingColor }, true) end

    elseif Name == "ChestBox" or Name == "ChestBoxLocked" or Name == "Toolbox"
        or Name == "Toolbox_Locked" or Name == "Locker_Small_Locked" then
        table.insert(Objects.Chests, Object)
        if State.ChestESP then Functions.AddESP({ Object = Object, Text = "Rương", Color = State.ChestColor }, true) end

    elseif ItemNames[Name] and (Object:FindFirstChild("ModulePrompt") or Name == "FuseHolder") then
        table.insert(Objects.Items, Object)
        if (Name == "Crucifix" or Name == "SkeletonKey") and not Object:GetAttribute("RareNotified")
            and not (Object.Parent and Object.Parent.Name == "Drops") then
            Object:SetAttribute("RareNotified", true)
            local Body = "Vật phẩm hiếm vừa xuất hiện"
            if Object.PrimaryPart then
                Body = Body .. " — cách bạn " .. math.round(LocalPlayer:DistanceFromCharacter(Object.PrimaryPart.Position)) .. " studs"
            end
            Functions.Notify("⭐ " .. I18N.Tr(ItemNames[Name]), Body, Color3.fromRGB(255, 215, 0))
        end
        if State.ItemESP then
            local Label = ItemNames[Name]
            local Col = State.ItemColor
            Functions.AddESP({ Object = Object, Text = Label, Color = Col }, Object:GetAttribute("ParentRoom") ~= nil)
        end

    elseif Name == "Key" then
        table.insert(Objects.Items, Object)
        Object:SetAttribute("ESP_Label", "Chìa khoá")
        if State.ItemESP then
            Functions.AddESP({ Object = Object, Text = "Chìa khoá", Color = Color3.fromRGB(255, 215, 0) }, true)
        end
    elseif Name == "LiveHintBook" then
        table.insert(Objects.Items, Object)
        Object:SetAttribute("ESP_Label", "Sách")
        if State.ItemESP or State.HintBookESP then
            Functions.AddESP({ Object = Object, Text = "Sách", Color = State.ItemColor }, true)
        end
    elseif Name == "LeverForGate" then
        table.insert(Objects.Items, Object)
        Object:SetAttribute("ESP_Label", "Cần gạt")
        if State.ItemESP or State.LeverESP then
            Functions.AddESP({ Object = Object, Text = "Cần gạt", Color = State.ItemColor }, true)
        end

    elseif Name == "LiveBreakerPolePickup" or Name == "MinesAnchor" then

        if not Object.PrimaryPart then
            for _, P in ipairs(Object:GetDescendants()) do
                if P:IsA("BasePart") then
                    Object.PrimaryPart = P
                    break
                end
            end
        end
        table.insert(Objects.Items, Object)
        local MLabel = ItemNames[Name] or "Máy"
        Object:SetAttribute("ESP_Label", MLabel)
        if State.ItemESP then
            Functions.AddESP({
                Object = Object,
                Text   = MLabel,
                Color  = State.ItemColor
            }, false)
        end

    elseif Name == "Ladder" then
        table.insert(Objects.Ladders, Object)
        if State.LadderESP then Functions.AddESP({ Object = Object, Text = "Thang", Color = State.LadderColor }, true) end

    elseif Name == "Lava" then
        table.insert(Objects.Obstructions, Object)
        if State.BypassKillbricks then Object.CanTouch = false end

    elseif Name == "ScaryWall" then
        for _, Part in Object:GetDescendants() do
            if Part:IsA("BasePart") then
                Part.CanTouch = not State.BypassSeekingWall
                Part.CanCollide = not State.BypassSeekingWall

                local C1 = Part:GetPropertyChangedSignal("CanTouch"):Connect(function()
                    if Part.CanTouch == State.BypassSeekingWall then
                        Part.CanTouch = not State.BypassSeekingWall
                    end
                end)
                local C2 = Part:GetPropertyChangedSignal("CanCollide"):Connect(function()
                    if Part.CanCollide == State.BypassSeekingWall then
                        Part.CanCollide = not State.BypassSeekingWall
                    end
                end)
                table.insert(Connections, C1)
                table.insert(Connections, C2)
            end
        end
        table.insert(Objects.Obstructions, Object)

    elseif Name == "SideroomSpace" then
        if State.BypassVacuum then
            local Col = Object:WaitForChild("Collision", 10)
            if Col then Col.CanCollide = true; Col.CanTouch = false end
        end
        table.insert(Objects.Traps, Object)

    elseif Name == "BananaPeel" then
        if State.BypassBanana then Object.CanTouch = false end
        table.insert(Objects.Traps, Object)

    elseif Name == "JeffTheKiller" then
        if State.BypassJeff then
            for _, Part in Object:GetDescendants() do
                if Part:IsA("BasePart") then Part.CanCollide = false; Part.CanTouch = false end
            end
            local Hum = Object:WaitForChild("Humanoid", 10)
            if Hum then Hum.Health = 0 end
        end
        table.insert(Objects.Traps, Object)

    elseif Name == "Seek_Arm" or Name == "ChandelierObstruction" then
        for _, Part in Object:GetDescendants() do
            if Part:IsA("BasePart") then
                Part.CanTouch = not State.BypassSeekObstructions
                table.insert(Objects.SeekObstructions, Part)
            end
        end
    elseif Name == "SeekFloodline" then
        Object.CanCollide = State.BypassSeekObstructions
        local FloodConn = Object:GetPropertyChangedSignal("CanCollide"):Connect(function()
            if Object.CanCollide ~= State.BypassSeekObstructions then
                Object.CanCollide = State.BypassSeekObstructions
            end
        end)
        Object.Destroying:Once(function() FloodConn:Disconnect() end)
        table.insert(Objects.SeekObstructions, Object)

    elseif Name == "TriggerEventCollision" then
        table.insert(Objects.EventTriggers, Object)
        if State.RemoveSeekTrigger then Functions.StartSeekTrigger(Object) end

elseif Entities[Name] then
    table.insert(Objects.Entities, Object)
    if State.EntityESP then
        Functions.AddESP({ Object = Object, Text = Functions.GetEntityText(Object), Color = State.EntityColor, AlwaysTracer = (Object.Name ~= "Snare"), NoTracer = (Object.Name == "Snare") })
    end

    if Name == "GiggleCeiling" then
        local function KillHitbox(Part)
            if Part.Name == "Hitbox" and Part:IsA("BasePart") then
                Part.CanTouch = false
            end
        end
        if State.BypassGiggle then
            for _, D in Object:GetDescendants() do KillHitbox(D) end
            local HC = Object.DescendantAdded:Connect(function(D)
                if State.BypassGiggle then KillHitbox(D) end
            end)
            table.insert(Connections, HC)
            Object.Destroying:Once(function() HC:Disconnect() end)
        end
    end

    if Name == "Snare" then
        if State.BypassSnare then
            for _, P in Object:GetDescendants() do
                if P:IsA("BasePart") then P.CanTouch = false end
            end
        end
        local SC = Object.DescendantAdded:Connect(function(P)
            if P:IsA("BasePart") and State.BypassSnare then P.CanTouch = false end
        end)
        table.insert(Connections, SC)
        Object.Destroying:Once(function() SC:Disconnect() end)

        task.spawn(function()
            local SnareFolder = Object:FindFirstChild("Snare") or Object:WaitForChild("Snare", 5)
            if SnareFolder then
                local Roots = SnareFolder:FindFirstChild("Roots")
                if Roots and Roots:IsA("BasePart") then Roots.Transparency = 1 end
                local Base = SnareFolder:FindFirstChild("SnareBase")
                if Base and Base:IsA("BasePart") then Base.Transparency = 1 end
            end
            local Void = Object:FindFirstChild("Void")
            if Void and Void:IsA("BasePart") then
                Void.Transparency = 0
                Void.Color = Color3.fromRGB(76, 67, 55)
            end
        end)
    end

    if FigureNames[Name] then
        for _, P in Object:GetDescendants() do
            if P:IsA("BasePart") then P.CanTouch = false end
        end
        if State.RemoveFigure then
            for _, P in Object:GetDescendants() do
                if P:IsA("BasePart") then
                    P.CanCollide = false
                    pcall(function() P.Position = Vector3.new(-49999, -49999, -49999) end)
                end
            end
        end
    end

elseif Name == "GloomPile" then
    table.insert(Objects.Traps, Object)
    local function Apply(P)
        if State.BypassGloombatEggs and P:IsA("BasePart") then P.CanTouch = false end
    end
    for _, P in Object:GetDescendants() do Apply(P) end
    local GC = Object.DescendantAdded:Connect(Apply)
    table.insert(Connections, GC)
    Object.Destroying:Once(function() GC:Disconnect() end)

elseif Name == "DoorFake" or Name == "FakeDoor" then

    if Object.Parent and Object:FindFirstChild("Hidden") then
        table.insert(Objects.Traps, Object)
        if State.EntityESP then
            Functions.AddESP({ Object = Object, Text = "Dupe", Color = State.EntityColor, AlwaysTracer = true }, Object:GetAttribute("ParentRoom") ~= nil)
        end
        if State.BypassDupe then
            Object.Hidden.CanTouch = false
            local Lock = Object:FindFirstChild("Lock")
            local UP = Lock and Lock:FindFirstChild("UnlockPrompt")
            if UP then UP.Enabled = false end
        end
    end

elseif Name == "ElevatorBreaker" then
    if State.AutoBreakerBox and not Globals.BreakerBoxNotified then
        Functions.Notify("Breaker Box", "Hãy tương tác với hộp cầu giao — sẽ tự động giải")
        Globals.BreakerBoxNotified = true
    end
    task.spawn(function()
        local SurfaceGui = Object:WaitForChild("SurfaceGui", 10)
        if not SurfaceGui then return end
        local Frame = SurfaceGui:WaitForChild("Frame", 5)
        if not Frame then return end
        local Code = Frame:WaitForChild("Code", 5)
        if not Code then return end

        if Connections.BreakerConnection then
            Connections.BreakerConnection:Disconnect()
        end

        Connections.BreakerConnection = Code:GetPropertyChangedSignal("Text"):Connect(function()
            Globals.BreakerBoxInteracted = true
            if State.AutoBreakerBox then
                if not Globals.BreakerBoxStartNotified
                   and (Floor == "Fools" or Floor == "OldHotel") then
                    Functions.Notify("Breaker Box", "Đang giải... vui lòng đợi")
                    Globals.BreakerBoxStartNotified = true
                end
                pcall(function() RemotesFolder.EBF:FireServer() end)
            end
        end)
    end)
    Object.Destroying:Once(function()
        if Connections.BreakerConnection then
            Connections.BreakerConnection:Disconnect()
            Connections.BreakerConnection = nil
        end
    end)

elseif Name == "ElevatorCar" then
    local ElevConn = Object.DescendantAdded:Connect(function(Desc)
        if State.AutoBreakerBox
           and Desc.Name == "TouchInterest"
           and not Globals.BreakerBoxFinishedNotified then
            Functions.Notify("Breaker Box", "Đã giải thành công! Hãy tới thang máy")
            Globals.BreakerBoxFinishedNotified = true
        end
    end)
    Object.Destroying:Once(function() ElevConn:Disconnect() end)

elseif Name == "Padlock" then
        if Connections.PadlockConnection then
            Connections.PadlockConnection:Disconnect()
            Connections.PadlockConnection = nil
        end
        local LastPadlockFire = 0
        local PadlockFired = false
        local PadlockDist = math.huge
        Connections.PadlockConnection = RunService.Heartbeat:Connect(function()
            if not Object or not Object.Parent or not Object.PrimaryPart then return end
            if not RemotesFolder or not RemotesFolder:FindFirstChild("PL") then return end
            if tick() - LastPadlockFire < 0.25 then return end
            LastPadlockFire = tick()
            local Dist = LocalPlayer:DistanceFromCharacter(Object.PrimaryPart.Position)
            PadlockDist = Dist
            if State.AutoUnlockPadlock then
                local Code = Functions.GetLibraryCode()
                if Code and tonumber(Code) and Dist < State.AutoUnlockDistance then
                    PadlockFired = true
                    pcall(function() RemotesFolder.PL:FireServer(Code) end)
                end
            end
        end)

        Object.Destroying:Once(function()
            if PadlockFired and PadlockDist <= 100 then
                Functions.Notify("Thư viện", "Đã mở khoá thư viện thành công!", Color3.fromRGB(0, 255, 130))
            end
            if Connections.PadlockConnection then
                Connections.PadlockConnection:Disconnect()
                Connections.PadlockConnection = nil
            end
        end)

    elseif Name == "PathLights" then
        local ObjectsToHighlight = {}; local PreviousNode = nil
        local function CreateSeekNode(Light)
            if Light.Name ~= "SeekGuidingLight" or Light:GetAttribute("Highlighted") then return end
            Light:SetAttribute("Highlighted", true)
            local NewNode = Instance.new("Part")
            NewNode.Size = Vector3.one; NewNode.Transparency = 1; NewNode.Parent = Globals.SeekNodesFolder
            NewNode.Anchored = true; NewNode.CFrame = Light.CFrame; NewNode.CanCollide = false; NewNode.Name = "SeekLightNode"
            local PrevNode2 = PreviousNode or NewNode; PreviousNode = NewNode
            local Beam = Instance.new("Beam")
            Beam.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, State.ShowSeekPathColor), ColorSequenceKeypoint.new(1, State.ShowSeekPathColor) })
            Beam.FaceCamera = true; Beam.Width0 = 0.2; Beam.Width1 = 0.2; Beam.Brightness = 10
            Beam.LightInfluence = 0; Beam.LightEmission = 0; Beam.Enabled = true
            local Vis = State.ShowSeekPath and 0 or 1
            Beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, Vis), NumberSequenceKeypoint.new(1, Vis) })
            Beam.Parent = Globals.SeekNodesFolder
            local A0 = Instance.new("Attachment", NewNode); local A1 = Instance.new("Attachment", PrevNode2)
            Beam.Attachment0 = A0; Beam.Attachment1 = A1
            table.insert(Objects.SeekHighlights, Beam)
        end
        for _, Child in Object:GetChildren() do table.insert(ObjectsToHighlight, Child) end
        local PLConn = Object.ChildAdded:Connect(function(Child) table.insert(ObjectsToHighlight, Child) end)
        task.spawn(function()
            while task.wait() do
                if not Object or not Object.Parent then return end
                local Light = table.remove(ObjectsToHighlight, 1)
                if Light then pcall(CreateSeekNode, Light) end
            end
        end)
        table.insert(Connections, PLConn); table.insert(Objects.PathLights, Object)
        Object.Destroying:Once(function() PLConn:Disconnect() end)
    elseif Name == "SeekMovingNewClone" then
        local Conn = Object.Destroying:Connect(function()
            for _, Folder in pairs(Objects.PathLights) do if Folder and Folder.Parent then Folder:ClearAllChildren() end end
            if Globals.SeekNodesFolder then Globals.SeekNodesFolder:ClearAllChildren() end
            table.clear(Objects.SeekHighlights)
        end)
        table.insert(Connections, Conn)

    elseif Name == "RunnerNodes" then
        local function IsBehind(P1, P2)
            local A = (P1.CFrame + P1.CFrame.LookVector).Position
            local B = (P1.CFrame + P1.CFrame.LookVector * -1).Position
            return (A - P2.Position).Magnitude > (B - P2.Position).Magnitude
        end
        local function GetDirection(P1, P2)
            local RD = P1.CFrame.RightVector:Dot(P1.Position - P2.Position)
            if RD > 0.5 then return IsBehind(P1, P2) and "Right" or "Left" end
            if RD < -0.5 then return IsBehind(P1, P2) and "Left" or "Right" end
            return "Straight"
        end
        local function GetClosestNode(Node)
            local Best, BestDist = nil, math.huge
            local ID2 = tonumber(Node.Name:match("MinecartNode(%d+)"))
            for _, Other in Object:GetChildren() do
                local OID = tonumber(Other.Name:match("MinecartNode(%d+)"))
                if Other ~= Node and OID and ID2 and OID > ID2 then
                    local D = (Node.Position - Other.Position).Magnitude
                    if D < BestDist and Other:GetAttribute("DistanceBlacklist") ~= true then BestDist = D; Best = Other end
                end
            end
            return Best
        end
        task.spawn(function()

            for _, Node in Object:GetChildren() do
                local NID = tonumber(Node.Name:match("MinecartNode(%d+)"))
                if Node:GetAttribute("DeathType") then Node:SetAttribute("DistanceBlacklist", true) end
                for I = 1, 20 do
                    local NextNode = NID and Object:FindFirstChild("MinecartNode" .. (NID + I))
                    if NextNode and NextNode:GetAttribute("DeathType") ~= nil then Node:SetAttribute("DistanceBlacklist", true) end
                end
                local PrevNode3 = NID and Object:FindFirstChild("MinecartNode" .. (NID - 1))
                if PrevNode3 and PrevNode3:GetAttribute("ForceConnect") then Node:SetAttribute("DistanceBlacklist", nil) end
                task.wait()
            end

            for _, Node in Object:GetChildren() do
                if Node:GetAttribute("ForceConnect") then
                    local NextNode = GetClosestNode(Node)
                    if NextNode then Node:SetAttribute("Turn", GetDirection(Node, NextNode)); table.insert(Objects.SeekNodes, Node) end
                end
                task.wait()
            end
        end)

    elseif Name == "DuckBoard" then
        table.insert(Objects.SeekDuckBoards, Object)

    elseif Name == "Bridge" then
        task.spawn(function()
            for _, Child in Object:GetChildren() do
                if Child.Name == "PlayerBarrier" and Child.Size.Y == 2.75
                    and (Child.Rotation.X == 0 or Child.Rotation.X == 180) then
                    local NB = Child:Clone()
                    NB.CFrame = NB.CFrame * CFrame.new(0, 0, -5)
                    NB.Name = _RandStr()
                    NB.Size = Vector3.new(NB.Size.X, NB.Size.Y, 11)
                    NB.Parent = Object
                    NB.CanCollide = State.BypassSeekObstructions
                    NB.Color = Color3.fromRGB(0, 255, 255)
                    NB.Transparency = State.BypassSeekObstructions and 0 or 1
                    NB.Material = Enum.Material.ForceField
                    table.insert(Objects.SeekBridges, NB)
                end
                task.wait()
            end
        end)

    elseif Object:IsA("ProximityPrompt") and not Object:GetAttribute("FakePrompt") then
        if Object:HasTag("DisableWhenEnabledOnClient") then
            pcall(function() Object:RemoveTag("DisableWhenEnabledOnClient") end)
        end

        if Object:GetAttribute("HoldDuration_Old") == nil then
            Object:SetAttribute("HoldDuration_Old", Object.HoldDuration)
        end
        if State.InstantPrompts then
            Object.HoldDuration = 0
        end
        if Object:GetAttribute("MaxActivationDistance_Old") == nil then
            Object:SetAttribute("MaxActivationDistance_Old", Object.MaxActivationDistance)
        end
        Object.MaxActivationDistance = Object:GetAttribute("MaxActivationDistance_Old") * State.PromptReach
        local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }

        if typeof(fireproximityprompt) == "function" and Floor ~= "OldHotel" and Floor ~= "Fools" then
            local IsLockPrompt = LockPromptNames[Object.Name]
                or (Object.Parent and Object.Parent:GetAttribute("Locked") == true)
                or (Object.Parent and Object.Parent.Parent and Object.Parent.Parent.Name == "Locker_Small_Locked" and Object.Name == "ActivateEventPrompt")

            if IsLockPrompt then
                local FakePrompt = Object:Clone()
                FakePrompt:SetAttribute("FakePrompt", true)
                task.wait()
                FakePrompt.Parent = Object.Parent

                FakePrompt:SetAttribute("HoldDuration_Old", Object:GetAttribute("HoldDuration_Old"))

                FakePrompt.HoldDuration = Object.HoldDuration
                FakePrompt.RequiresLineOfSight = Object.RequiresLineOfSight
                FakePrompt.MaxActivationDistance = Object.MaxActivationDistance
                FakePrompt:SetAttribute("MaxActivationDistance_Old", Object:GetAttribute("MaxActivationDistance_Old"))

                if State.InstantPrompts then FakePrompt.HoldDuration = 0 end

                FakePrompts[FakePrompt] = Object
                pcall(function() Object.Parent = Globals.PromptContainer end)

                local FPEnabledConn = Object:GetPropertyChangedSignal("Enabled"):Connect(function()
                    FakePrompt.Enabled = Object.Enabled
                end)
                Object:GetPropertyChangedSignal("ActionText"):Once(function()
                    Object.Parent = FakePrompt.Parent
                    FakePrompt:Destroy()
                    FPEnabledConn:Disconnect()
                end)
                Object.Destroying:Once(function()
                    FakePrompt:Destroy()
                    FPEnabledConn:Disconnect()
                end)
                table.insert(Connections, FPEnabledConn)
                table.insert(Objects.Prompts, FakePrompt)

                FakePrompt.Enabled = false
                task.wait()
                FakePrompt.Enabled = Object.Enabled
            end
        end
        table.insert(Objects.Prompts, Object)
	end
end

local function QueueObject(Object)
    if not AllowedNames[Object.Name] and Object.ClassName ~= "ProximityPrompt"
        and not ItemNames[Object.Name] and not Entities[Object.Name] then return end
    table.insert(ObjectQueue, Object)
end

Connections.QueueHandler = RunService.RenderStepped:Connect(function()
    local Obj = table.remove(ObjectQueue, 1)
    if Obj then pcall(Functions.HandleObject, Obj) end
end)

for _, Obj in Workspace:GetDescendants() do task.spawn(function() QueueObject(Obj) end) end
Connections.InstanceAdded = Workspace.DescendantAdded:Connect(QueueObject)

Connections.FakePromptHandler = ProximityPromptService.PromptTriggered:Connect(function(Object)
    if not Object:GetAttribute("FakePrompt") then return end

    local Prompt = Object
    if not Prompt.Parent then return end
    local LockPromptNames = { UnlockPrompt=true, SkullPrompt=true, LockPrompt=true, ThingToEnable=true, FusesPrompt=true }
    local IsLockPrompt = LockPromptNames[Object.Name]
        or (Object.Parent and Object.Parent:GetAttribute("Locked") == true)
        or (Object.Parent and Object.Parent.Parent and Object.Parent.Parent.Name == "Locker_Small_Locked" and Object.Name == "ActivateEventPrompt")
    if IsLockPrompt then
        if State.AutoInteractIgnore["Locks"] then return end
        local KeyItems = { "Key","GeneratorFuse","KeyBackdoor","KeyElectrical","KeyIron","Lockpick","SkeletonKey","Shears","Multitool" }
        local OffhandKeyItems = { "Key","GeneratorFuse","KeyElectrical","KeyIron" }
        local HasKey = false
        for _, K in KeyItems do if Functions.HasItem(K, true) then HasKey = true break end end
        for _, K in OffhandKeyItems do if Functions.HasItem(K) then HasKey = true break end end
        if not HasKey then return end
    end

    local PName = Prompt.Parent.Name
    if (PName == "CuttableVines" or PName == "Chest_Vine" or PName == "Cellar")
        and not Functions.HasItem("Shears", true) and not Functions.HasItem("Multitool", true) then return end
    if PName == "SkullLock" and not Functions.HasItem("SkeletonKey", true) then return end
    if (PName == "Lock1" or PName == "Lock2")
        and not Functions.HasItem("Lockpick", true) and not Functions.HasItem("Multitool", true) then return end
    if Functions.HasItem("Shears", true) and IsLockPrompt and PName ~= "CuttableVines" and PName ~= "Chest_Vine" and PName ~= "Cellar" then return end

    local RealPrompt = FakePrompts[Object]
    Functions.FirePrompt(RealPrompt)
end)

Connections.EntityHandler = Workspace.ChildAdded:Connect(function(Entity)
    local Data = Entities[Entity.Name]; if not Data then return end
    local Tries = 0
    while not Entity.PrimaryPart and Tries < 50 do
        for _, C in Entity:GetChildren() do if C:IsA("BasePart") then Entity.PrimaryPart = C end end
        task.wait(0.1); Tries += 1
    end
    if not Entity.PrimaryPart then return end
    if NotifyEnabled then
        ESP:AddEntityAlert(Entity, I18N.Tr(Data.Alias))
    end

end)

task.spawn(function()
    local RStorage = game:GetService("ReplicatedStorage")
    local FloorReplicated = RStorage:FindFirstChild("FloorReplicated") or RStorage:WaitForChild("FloorReplicated", 120)
    if not FloorReplicated then return end
    local function HandleLate(Object)
        if Object.Name == "GlitchScreech" then
            ModuleRefs.GlitchScreech = Object
            if State.RemoveScreech then Object.Name = "GlitchScreech_Disabled" end
        end
        if Object.Name:find("Jumpscare") and Object:IsA("ModuleScript")
            and not Object.Name:find("Eyestalk") and not Object.Name:find("Groundskeeper")
            and not Object.Name:find("Monument") then
            Object:SetAttribute("OriginalName", Object.Name)
            if State.DisableEntityJumpscares then Object.Name = Object.Name .. "_Disabled" end
            table.insert(JumpscareModules, Object)
        end
    end
    for _, Obj in FloorReplicated:GetDescendants() do HandleLate(Obj) end
    Connections.FloorReplicatedHandler = FloorReplicated.DescendantAdded:Connect(HandleLate)
end)

Connections.RoomsHandler = task.spawn(function()
    local CR = CurrentRooms or Workspace:WaitForChild("CurrentRooms", 120); if not CR then return end
    local Conn = CR.ChildAdded:Connect(function(Room)
        local Raw = Room:GetAttribute("RawName")
        if not Raw or not string.find(Raw, "Eyestalk") then return end
        local PreviousNode = nil
        local function CreateEyestalkNode(WaypointPos)
            local NN = Instance.new("Part")
            NN.Size = Vector3.one; NN.Transparency = 1; NN.Parent = Globals.SeekNodesFolder
            NN.Anchored = true; NN.Position = WaypointPos; NN.CanCollide = false; NN.Name = "EyestalkNode"
            local PrevNode = PreviousNode or NN; PreviousNode = NN
            local Beam = Instance.new("Beam")
            Beam.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, State.ShowEyestalkPathColor), ColorSequenceKeypoint.new(1, State.ShowEyestalkPathColor) })
            Beam.FaceCamera = true; Beam.Width0 = 0.2; Beam.Width1 = 0.2; Beam.Brightness = 10
            Beam.LightInfluence = 0; Beam.LightEmission = 0; Beam.Enabled = true
            local Vis = State.ShowEyestalkPath and 0 or 1
            Beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, Vis), NumberSequenceKeypoint.new(1, Vis) })
            Beam.Parent = Globals.SeekNodesFolder
            local A0 = Instance.new("Attachment", NN); local A1 = Instance.new("Attachment", PrevNode)
            Beam.Attachment0 = A0; Beam.Attachment1 = A1
            table.insert(Objects.EyestalkHighlights, Beam)
        end
        task.spawn(function()
            local Entrance = Room:WaitForChild("RoomEntrance", 30); local Exit = Room:WaitForChild("RoomExit", 30)
            if not Entrance or not Exit or not RootPart then return end
            while not Room:GetAttribute("PathFound") do
                if not Room.Parent then return end
                if State.ShowEyestalkPath then
                    local Ok, EyePath = pcall(function()
                        local P = game:GetService("PathfindingService"):CreatePath({ AgentCanJump=false, AgentCanClimb=false, WaypointSpacing=2, AgentRadius=1, AgentHeight=1 })
                        P:ComputeAsync(RootPart.Position, Exit.Position); return P
                    end)
                    if Ok and EyePath and EyePath.Status == Enum.PathStatus.Success then
                        Room:SetAttribute("PathFound", true)
                        for _, WP in EyePath:GetWaypoints() do CreateEyestalkNode(WP.Position); task.wait() end
                        break
                    end
                end
                task.wait(0.25)
            end
        end)
    end)
    table.insert(Connections, Conn)
end)

Connections.BypassHandler = RunService.Heartbeat:Connect(function()
    if not Character or not RootPart or not Collision then return end
    if State.PositionSpoof then Collision.Position = RootPart.Position + Vector3.new(0, 2.328, 0) end
    local IsEyes    = Workspace:FindFirstChild("Eyes") ~= nil
local IsLookman = Workspace:FindFirstChild("Lookman") ~= nil
local IsBackdoorLookman = Workspace:FindFirstChild("BackdoorLookman") ~= nil
if ((State.BypassEyes and IsEyes) or (State.BypassLookman and (IsLookman or IsBackdoorLookman)))
    and RemotesFolder and RemotesFolder:FindFirstChild("MotorReplication") then
    if Floor == "Fools" or Floor == "OldHotel" then RemotesFolder.MotorReplication:FireServer(0, 65, 0, false)
    else RemotesFolder.MotorReplication:FireServer(-650) end
end
    if RemotesFolder and RemotesFolder:FindFirstChild("Crouch") and tick() - LastCrouchFire > 0.1 then
        local IsCrouch = Functions.IsCrouching()
        if State.CrouchSpoof or State.PositionSpoof then IsCrouch = true end
        pcall(function() RemotesFolder.Crouch:FireServer(IsCrouch, true) end)
        LastCrouchFire = tick()
    end
end)

Globals.LastDuck = 0
Connections.AutoSteerMinecartDuckHandler = RunService.Heartbeat:Connect(function()
    if not State.AutoSteerMinecart or not Functions.GetMinecart() then return end
    if tick() - Globals.LastDuck < 0.1 then return end
    Globals.NearestTurnNode = Functions.GetNearestTurnNode()
    local MG = Main_Game or Functions.GetMainGame()
if not MG or type(MG) ~= "table" or type(MG.crouch) ~= "function" then
    Globals.LastDuck = tick(); return
end
    if not Globals.AutoMinecartDucked and Functions.GetNearestDuckBoard() then
        pcall(function() MG.crouch(true) end); Globals.AutoMinecartDucked = true
    elseif not Functions.GetNearestDuckBoard() and Globals.AutoMinecartDucked then
        pcall(function() MG.crouch(false) end); Globals.AutoMinecartDucked = false
    end
    Globals.LastDuck = tick()
end)

task.spawn(function()
    local PS = LocalPlayer:WaitForChild("PlayerScripts", 30); if not PS then return end
    local PM = PS:WaitForChild("PlayerModule", 30); if not PM then return end
    if not Functions.CheckCompatability({"require"}) then return end
    local Ok, Controls = pcall(function() return require(PM):GetControls() end)
    if not Ok or not Controls then return end
    local Original = Controls.GetMoveVector; Globals.OriginalGetMoveVector = Original
    Controls.GetMoveVector = function(...)
        if State.AutoSteerMinecart and Floor == "Mines" then
            local Node = Globals.NearestTurnNode
            if Node and Node.Parent and Functions.GetMinecart() then
                local Turn = Node:GetAttribute("Turn")
                if Turn == "Left" then return Vector3.new(-1, 0, 0) end
                if Turn == "Right" then return Vector3.new(1, 0, 0) end
                return Vector3.zero
            end
        end
        return Original(...)
    end
end)

if Functions.CheckCompatability({"hookmetamethod"}) then
    task.spawn(function()
        local ok = pcall(function()
            local oldHook
            oldHook = hookmetamethod(game, "__namecall", newcclosure(function(Self, ...)
                local Method = getnamecallmethod()
                if State.AutoHeartbeatMinigame then
                    if (Self.Name == "ClutchHeartbeat" or Self.Name == "HideMonster")
                        and Method == "FireServer" then
                        return
                    end
                end
                return oldHook(Self, ...)
            end))
        end)
    end)
end

for _, Object in Lighting:GetChildren() do
    if Object:IsA("Atmosphere") then
        if not Object:GetAttribute("Density_Old") then Object:SetAttribute("Density_Old", Object.Density) end
        table.insert(FogInstances, Object)
    end
end
Connections.FogHandler2 = Lighting.DescendantAdded:Connect(function(Object)
    if not Object:IsA("Atmosphere") then return end
    Object:SetAttribute("Density_Old", Object.Density)
    if State.RemoveFog then Object.Density = 0 end
    table.insert(FogInstances, Object)
end)

Connections.FogHandler = Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
    if Lighting.FogEnd ~= 10000000 then OldFog = Lighting.FogEnd end
    if State.RemoveFog then Lighting.FogEnd = 10000000 end
end)
local LastAmbient = Lighting.Ambient
Connections.AmbientSetup = LocalPlayer:GetAttributeChangedSignal("CurrentRoom"):Connect(function()
    local CR = CurrentRooms:FindFirstChild(tostring(LocalPlayer:GetAttribute("CurrentRoom")))
    if CR then local RA = CR:GetAttribute("Ambient"); if RA and type(RA) == "Color3" then LastAmbient = RA end end
end)
local AmbientApplied, SavedOutdoor, SavedBrightness = false, nil, nil
Connections.AmbientHandler = RunService.RenderStepped:Connect(function()
    if State.Ambient then
        if not AmbientApplied then
            AmbientApplied = true
            SavedOutdoor, SavedBrightness = Lighting.OutdoorAmbient, Lighting.Brightness
        end
        Lighting.Ambient = State.AmbientColor; Lighting.OutdoorAmbient = State.AmbientColor; Lighting.Brightness = 3
    elseif AmbientApplied then

        AmbientApplied = false
        Lighting.Ambient = LastAmbient
        if SavedOutdoor then Lighting.OutdoorAmbient = SavedOutdoor end
        if SavedBrightness then Lighting.Brightness = SavedBrightness end
    end
end)

Connections.Cleaner = RunService.Heartbeat:Connect(function()
    if tick() - LastClean < 0.5 then return end
    LastClean = tick()
    for _, Array in Objects do
        local I = #Array
        while I >= 1 do
            local O = Array[I]
            if not O or not O:IsDescendantOf(Workspace) then
                table.remove(Array, I)
                if ESPConnections[O] then ESPConnections[O]:Disconnect(); ESPConnections[O] = nil end
            end
            I -= 1
        end
    end
    local I2 = #DoorReachTargets
    while I2 >= 1 do
        local O = DoorReachTargets[I2]
        if not O or not O:IsDescendantOf(Workspace) then
            table.remove(DoorReachTargets, I2)
            if DoorReachConnections[O] then DoorReachConnections[O]:Disconnect(); DoorReachConnections[O] = nil end
        end
        I2 -= 1
    end
end)

local LastPromptFix = tick()
Connections.PromptFixer = RunService.Heartbeat:Connect(function()
    if tick() - LastPromptFix <= 0.5 then return end
    LastPromptFix = tick()
    for _, Prompt in Objects.Prompts do
        if Prompt and Prompt.Parent and Prompt:HasTag("DisableWhenEnabledOnClient") then
            pcall(function() Prompt:RemoveTag("DisableWhenEnabledOnClient") end)
        end
    end
end)

local function SetupPlayerESP(Player)
    if Player == LocalPlayer then return end
    if Player.Character and State.PlayerESP then
        Functions.AddESP({ Object = Player.Character, Text = Player.Name, Color = State.PlayerColor })
    end
    local CharConn = Player.CharacterAdded:Connect(function(NewChar)
        if State.PlayerESP then Functions.AddESP({ Object = NewChar, Text = Player.Name, Color = State.PlayerColor }) end
    end)
    table.insert(Connections, CharConn)
end
for _, P in Services.Players:GetPlayers() do SetupPlayerESP(P) end
Connections.PlayerAdded = Services.Players.PlayerAdded:Connect(SetupPlayerESP)

if LocalPlayer.Character then task.spawn(function() Functions.HandleCharacter(LocalPlayer.Character) end) end
Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function(NewChar) task.wait(0.5); Functions.HandleCharacter(NewChar) end)

function Functions.Unload()
    for _, C in pairs(Connections) do
        pcall(function()
            if typeof(C) == "RBXScriptConnection" then C:Disconnect()
            elseif type(C) == "thread" then task.cancel(C) end
        end)
    end
    for _, Prompt in Objects.Prompts do
        pcall(function()
            if FakePrompts[Prompt] then
                FakePrompts[Prompt].Parent = Prompt.Parent
                Prompt:Destroy()
            end
            if Prompt.Parent then
                Prompt.HoldDuration = Prompt:GetAttribute("HoldDuration_Old") or Prompt.HoldDuration
                Prompt.MaxActivationDistance = Prompt:GetAttribute("MaxActivationDistance_Old") or Prompt.MaxActivationDistance
            end
        end)
    end
    pcall(function() RunService:UnbindFromRenderStep("DoorsForceFOV") end)
    pcall(function() RunService:UnbindFromRenderStep("DoorsThirdPerson") end)
    State.ThirdPerson = false
    State.WallPass = false
    pcall(function() if Globals.WallPassBody then Globals.WallPassBody:Destroy() end end)
    pcall(function()
        local LT = Character and Character:FindFirstChild("LowerTorso")
        if LT and LT:FindFirstChild("Root") and Globals.OriginalC1 and not Globals.C1Locked then LT.Root.C1 = Globals.OriginalC1 end
    end)
    pcall(function() ScreenGui:Destroy() end)
    pcall(function()
    if Globals.SeekNodesFolder then Globals.SeekNodesFolder:Destroy() end
    if Globals.RoomsNodesFolder then Globals.RoomsNodesFolder:Destroy() end
    if Globals.OriginalGetMoveVector and Functions.CheckCompatability({"require"}) then
        local PS = LocalPlayer:FindFirstChild("PlayerScripts")
        local PM = PS and PS:FindFirstChild("PlayerModule")
        if PM then
            local Ok, Controls = pcall(function() return require(PM):GetControls() end)
            if Ok and Controls then Controls.GetMoveVector = Globals.OriginalGetMoveVector end
        end
    end
end)
end

pcall(function() RunService:UnbindFromRenderStep("DoorsForceFOV") end)
RunService:BindToRenderStep("DoorsForceFOV", Enum.RenderPriority.Camera.Value + 1, function()
    local cam = Workspace.CurrentCamera
    if not cam or not State.FOVEnabled then return end
    local target = State.FieldOfView
    if math.abs(cam.FieldOfView - target) > 0.01 then
        cam.FieldOfView = target
    end
end)

do
    local TPParts, TPChar, TPWasOn = {}, nil, false
    local RayParams = RaycastParams.new()
    RayParams.FilterType = Enum.RaycastFilterType.Exclude

    function Functions.RefreshThirdPersonParts()
        table.clear(TPParts)
        TPChar = Character
        if not Character then return end
        for _, O in Character:GetDescendants() do
            if O:IsA("Accessory") and O:FindFirstChild("Handle") then table.insert(TPParts, O.Handle) end
        end
        local Head = Character:FindFirstChild("Head")
        if Head then table.insert(TPParts, Head) end
    end

    pcall(function() RunService:UnbindFromRenderStep("DoorsThirdPerson") end)
    RunService:BindToRenderStep("DoorsThirdPerson", Enum.RenderPriority.Camera.Value + 2, function()
        local Cam = Workspace.CurrentCamera
        if not Cam or not Character then return end
        if TPChar ~= Character then Functions.RefreshThirdPersonParts() end

        if State.ThirdPerson then
            local Offset = CFrame.new(State.ThirdPersonX, State.ThirdPersonY, State.ThirdPersonZ)
            local Moved = false
            if State.ThirdPersonWallCheck then
                RayParams.FilterDescendantsInstances = { Character }
                local Dir = (Cam.CFrame * Offset).Position - Cam.CFrame.Position
                if Dir.Magnitude > 0.01 then
                    local Hit = Workspace:Spherecast(Cam.CFrame.Position, 0.2, Dir, RayParams)
                    if Hit and Hit.Instance.CanCollide then
                        local NewPos = Cam.CFrame.Position + Dir.Unit * Hit.Distance
                        Cam.CFrame = CFrame.new(NewPos, NewPos + Cam.CFrame.LookVector)
                        Moved = true
                    end
                end
            end
            if not Moved then Cam.CFrame = Cam.CFrame * Offset end
            TPWasOn = true
            for _, P in TPParts do
                if P.Parent then P.Transparency = 0; P.LocalTransparencyModifier = 0 end
            end
        elseif TPWasOn then
            TPWasOn = false
            for _, P in TPParts do
                if P.Parent then P.Transparency = 1; P.LocalTransparencyModifier = 1 end
            end
        end
    end)
end

task.spawn(function()
    task.wait(1)
    Globals.MuteNotify = true
    for _, Apply in PendingApply do
        pcall(Apply)
        task.wait()
    end
    table.clear(PendingApply)
    Globals.MuteNotify = false
end)

local LoadTime = math.floor((tick() - LoadStart) * 1000) / 1000
Functions.NotifySuccess(
    "✅ CourierCat Hub đã load",
    ("Thời gian: %ss"):format(LoadTime)
)
return ESP
