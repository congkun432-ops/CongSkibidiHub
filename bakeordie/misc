return function(Env)
    local ReplicatedStorage, LocalPlayer, Window, State, Guard, GetCharacter, GetObjectPosition, HubNotify = Env.ReplicatedStorage, Env.LocalPlayer, Env.Window, Env.State, Env.Guard, Env.GetCharacter, Env.GetObjectPosition, Env.HubNotify

    local SetSkipCutscene

    do
    local Cutscene = { Connection = nil, Busy = false }

    local function FinishCutsceneNow()
        local Entry = Env.Remotes and Env.Remotes.finishCutscene
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
        local Start = Env.Remotes and Env.Remotes.startCutscene
        local Finish = Env.Remotes and Env.Remotes.finishCutscene
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
            pcall(Env.Remotes.startCutscene.setCallback, CutsceneHook.Original)
            CutsceneHook.Original = nil
            CutsceneHook.Installed = false
        end
    end

    local function ClearCutsceneConnections()
        for _, Connection in ipairs(CutsceneBackup.Connections) do Connection:Disconnect() end
        CutsceneBackup.Connections = {}
    end

    function SetSkipCutscene(Enabled)
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

    local CODE_WORDS = { "clipboard", "keypad", "password", "passcode", "combination", "code", "note", "paper", "memo", "sticky", "safe" }

    local function FindBankClipboard()
        local World = workspace:FindFirstChild("World")
        return (World and World:FindFirstChild("BankClipboard", true)) or workspace:FindFirstChild("BankClipboard", true)
    end

    local function CollectTexts(Root)
        local Found = {}
        local function Consider(Source, Text)
            if type(Text) == "string" and Text ~= "" then
                table.insert(Found, { Source = Source, Text = Text })
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

    local function Shorten(Text)
        Text = string.gsub(Text, "%s+", " ")
        if #Text > 120 then Text = string.sub(Text, 1, 117) .. "..." end
        return Text
    end

    local function ShowBankCode()
        local Clipboard = FindBankClipboard()
        if not Clipboard then
            HubNotify("error", "Mã két", "Không thấy BankClipboard.", 6)
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
            HubNotify("success", "Mã két", Shorten(Entry.Text) .. "  (" .. os.date("%H:%M:%S") .. ")", 10)
        else
            HubNotify("warning", "Mã két", "Không có mã trong BankClipboard.", 6)
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
        local function Add(Label, Object)
            if Object then table.insert(Targets, { Label = Label, Object = Object }) end
        end
        local World = workspace:FindFirstChild("World")
        local Science = World and World:FindFirstChild("ScienceFacility")
        local Hospital = World and World:FindFirstChild("Hospital")
        local Sewer = World and World:FindFirstChild("Sewer")
        local KeyUses = workspace:FindFirstChild("KeyItemUses")
        local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        Add("Mã két", FindBankClipboard())
        Add("Mã Raygun", Science and Science:FindFirstChild("RaygunCode"))
        Add("Mã Keypad", Science and Science:FindFirstChild("Keypad"))
        Add("Mã cống", Sewer and Sewer:FindFirstChild("Part"))
        Add("Mã cổng cơ sở", KeyUses and KeyUses:FindFirstChild("FacilityGateCode"))
        Add("Bảng ghi chú", workspace:FindFirstChild("Clipboard"))
        Add("Bảng ghi chú", Hospital and Hospital:FindFirstChild("Clipboard"))
        Add("Bảng ghi chú", World and World:FindFirstChild("Model"))
        for _, Child in ipairs(workspace:GetChildren()) do
            if Child.Name == "Display" then Add("Màn hình", Child) end
        end
        Add("Vật phẩm chính", PlayerGui and PlayerGui:FindFirstChild("KeyItemsHud"))
        Add("Vật phẩm chính", PlayerGui and PlayerGui:FindFirstChild("KeyItemDiscovered"))
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
            HubNotify("warning", "Code", "Không tìm thấy code nào trong map.", 6)
            return
        end
        for Index, Result in ipairs(Results) do
            if Index > 8 then break end
            HubNotify("success", Result.Name, Result.Text, 12)
        end
    end

    local TeleportDropdown
    local TeleportMap = {}
    local TeleportRefreshQueued = false

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

    local EMPTY_TELEPORT = "(chưa có điểm dịch chuyển)"

    local function RefreshTeleportList()
        local Names, Map = BuildTeleportList()
        TeleportMap = Map
        if #Names == 0 then Names = { EMPTY_TELEPORT } end
        if TeleportDropdown then TeleportDropdown:Refresh(Names, true) end
        return Names
    end

    local function QueueTeleportRefresh()
        if TeleportRefreshQueued then return end
        TeleportRefreshQueued = true
        task.delay(0.3, function()
            TeleportRefreshQueued = false
            RefreshTeleportList()
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

    local TeleportTab = Window:CreateTab("Dịch chuyển")
    local InitialTeleportNames
    InitialTeleportNames, TeleportMap = BuildTeleportList()
    if #InitialTeleportNames == 0 then InitialTeleportNames = { EMPTY_TELEPORT } end
    TeleportDropdown = TeleportTab:AddDropdown("Địa điểm", InitialTeleportNames, function() end, "teleport_point")
    TeleportTab:AddButton("Dịch chuyển", "Đi", TeleportToSelected)

    do
        local Folder = workspace:FindFirstChild("TeleportPoints")
        if Folder then
            Folder.ChildAdded:Connect(QueueTeleportRefresh)
            Folder.ChildRemoved:Connect(QueueTeleportRefresh)
        end
    end

    local MiscTab = Window:CreateTab("Khác")
    MiscTab:AddSwitch("Bỏ qua cảnh phim", false, SetSkipCutscene, "skip_cutscene")
    MiscTab:AddButton("Mã két", "Code", ShowBankCode)
    MiscTab:AddButton("Tất cả code", "Quét", function()
        task.spawn(Guard, "quét code", ShowAllCodes)
    end)
end
