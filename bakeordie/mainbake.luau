if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/congkun432-ops/CongSkibidiHub/refs/heads/main/menu_raw"
))()

local Window = Library:CreateWindow({
    HubName = "Monster Hub",
    AuthorName = "Courier cat",
    ToggleKey = Enum.KeyCode.RightShift,
})

local BASE_URL = "https://raw.githubusercontent.com/congkun432-ops/CongSkibidiHub/refs/heads/main/bakeordie/"
local MAIN_FILE = "mainbake.luau"
local MODULES = { "player", "combat", "collect", "acorn", "chest", "esp", "items", "misc" }

local Env = {
    Players = Players,
    RunService = RunService,
    UserInputService = UserInputService,
    ReplicatedStorage = ReplicatedStorage,
    LocalPlayer = LocalPlayer,
    Window = Window,
    MainUrl = BASE_URL .. MAIN_FILE,
}

local PlayerTab = Window:CreateTab("Người chơi")
local FarmTab = Window:CreateTab("Cày")
Env.PlayerTab = PlayerTab
Env.FarmTab = FarmTab

local State = {
    KillAura = false,
    AuraDelay = 0.1,
    AuraRange = 30,
    AuraSlot = 1,
    Noclip = false,
    SpeedBoost = false,
    SpeedValue = 30,
    InstantInteract = false,
    CollectRange = 100,
    InstantReload = false,
    GunAura = false,
    GunSlot = 1,
    RapidGun = false,
    RapidGunDelay = 0,
    RapidMelee = false,
    RapidMeleeDelay = 0,
    ArmHide = false,
    SkipCutscene = false,
    InfiniteJump = false,
    Fly = false,
    FlySpeed = 60,
    ThirdPerson = false,
    MaxZoom = 128,
}

local function Guard(Name, Fn)
    pcall(Fn)
end

local Loops = {}

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

local ItemData = {}
local TagCache = {}

task.spawn(function()
    local Success, Result = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Client", 30):WaitForChild("ClientRemotes", 30))
    end)
    if Success and type(Result) == "table" then
        Env.Remotes = Result
    end
end)

local LastItemLoad = 0

local function LoadItemData()
    LastItemLoad = os.clock()
    local Success, ObjectsLibrary = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared", 15):WaitForChild("ObjectsLibrary", 15))
    end)
    if Success and type(ObjectsLibrary) == "table" and type(ObjectsLibrary.Objects) == "table" then
        for Name, Data in pairs(ObjectsLibrary.Objects) do
            if type(Data) == "table" then ItemData[Name] = Data end
        end
    end
end

LoadItemData()

task.spawn(function()
    local Success, Result = pcall(function()
        return ReplicatedStorage:WaitForChild("ZAP", 30):WaitForChild("ZAP_RELIABLE", 30)
    end)
    if Success and Result then
        Env.SafeRemote = Result
    end
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
local InventoryModule
local CharacterModule

local function SafeRequire(Path)
    local Node = ReplicatedStorage
    for _, Name in ipairs(Path) do
        Node = Node and Node:FindFirstChild(Name)
    end
    if not Node then return end
    local Ok, Result = pcall(require, Node)
    if Ok and type(Result) == "table" then return Result end
end

local function GetInventory()
    InventoryModule = InventoryModule or SafeRequire({ "Client", "Systems", "Inventory" })
    return InventoryModule
end

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

Env.State = State
Env.Guard = Guard
Env.SetLoop = SetLoop
Env.GetCharacter = GetCharacter
Env.GetObjectPosition = GetObjectPosition
Env.GetMonsterPosition = GetMonsterPosition
Env.HasTag = HasTag
Env.ItemData = ItemData
Env.GetZapRemote = GetZapRemote
Env.SafeRequire = SafeRequire
Env.GetInventory = GetInventory
Env.GetController = GetController
Env.HubNotify = HubNotify

local function LoadModule(Name)
local Url = BASE_URL .. Name .. ".luau"
    local Ok, Source = pcall(function() return game:HttpGet(Url) end)
    if not (Ok and type(Source) == "string" and #Source > 0) then
        warn("[Monster Hub] không tải được module " .. Name)
        HubNotify("error", "Module", "Không tải được: " .. Name, 8)
        return
    end
    local Chunk, CompileError = loadstring(Source, "=" .. Name)
    if not Chunk then
        warn("[Monster Hub] lỗi cú pháp module " .. Name .. ": " .. tostring(CompileError))
        HubNotify("error", "Module " .. Name, "Lỗi cú pháp, xem console.", 8)
        return
    end
    local Success, Result = xpcall(Chunk, debug.traceback)
    if Success and type(Result) == "function" then
        Success, Result = xpcall(Result, debug.traceback, Env)
    end
    if not Success then
        warn("[Monster Hub] module " .. Name .. " lỗi: " .. tostring(Result))
        HubNotify("error", "Module " .. Name, "Lỗi khi chạy, xem console.", 8)
    end
end

for _, Name in ipairs(MODULES) do
    LoadModule(Name)
end
