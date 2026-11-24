return function(Env)
    local LocalPlayer, FarmTab, State, Guard, GetCharacter, GetObjectPosition = Env.LocalPlayer, Env.FarmTab, Env.State, Env.Guard, Env.GetCharacter, Env.GetObjectPosition

    local UUID_PATTERN = "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"

    local ScriptStart = os.clock()
    local HOP_IDLE = 10
    local HOP_MIN_STAY = 25
    local MAX_HOPS = 40
    local RESUME_FILE = "MonsterHub_resume.txt"

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

    local AcornCapture = { Original = nil }

    local function OnAcornFire(Args)
        if Acorn.Waiting and not Acorn.Waiting.Id and IsUuidString(Args[1]) then
            Acorn.Waiting.Id = Args[1]
        end
    end

    local function InstallAcornWrapper()
        if AcornCapture.Original then return true end
        local Entry = Env.Remotes and Env.Remotes.candyAcorn and Env.Remotes.candyAcorn.pickupCandyAcorn
        if not (Entry and type(Entry.fire) == "function") then return false end
        local Original = Entry.fire
        local Ok = pcall(function()
            Entry.fire = function(...)
                pcall(OnAcornFire, table.pack(...))
                return Original(...)
            end
        end)
        if Ok then AcornCapture.Original = Original end
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
            pcall(queue_on_teleport, string.format("loadstring(game:HttpGet(%q))()", Env.MainUrl))
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
                Guard("farm hạt dẻ", function()
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

    task.spawn(function()
        for _ = 1, 40 do
            if Env.Remotes and Env.Remotes.candyAcorn and InstallAcornWrapper() then return end
            task.wait(0.5)
        end
    end)

    local AcornSwitch = FarmTab:AddSwitch("Farm hạt dẻ", false, SetAcorn, "auto_acorn")
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
                        pcall(function() AcornSwitch:Set(true) end)
                        SetAcorn(true)
                    end)
                end
            end
        end
    end
end
