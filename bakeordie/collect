return function(Env)
    local Window, FarmTab, State, Guard, SetLoop, GetCharacter, GetObjectPosition, HasTag, ItemData, GetZapRemote, GetInventory = Env.Window, Env.FarmTab, Env.State, Env.Guard, Env.SetLoop, Env.GetCharacter, Env.GetObjectPosition, Env.HasTag, Env.ItemData, Env.GetZapRemote, Env.GetInventory

    local COLLECT_INTERVAL = 0.25
    local PICKUP_RETRY = 1
    local PickupAttempts = {}
    local function FindPickups(Accepts)
        local Pickups = {}
        local Stats = { Total = 0, WrongTag = 0, Cooldown = 0, OutOfRange = 0, Nearest = nil }
        local _, _, Root = GetCharacter()
        local Folder = workspace:FindFirstChild("Interactables")
        if not (Root and Folder) then return Pickups, Folder, Stats end
        local Now = os.clock()
        for _, Object in ipairs(Folder:GetChildren()) do
            local Id = Object:GetAttribute("ObjectUUID")
            if type(Id) == "string" then
                Stats.Total += 1
                if not Accepts(Object) then
                    Stats.WrongTag += 1
                else
                    local Position = GetObjectPosition(Object)
                    local Distance = Position and (Position - Root.Position).Magnitude
                    if Distance and (not Stats.Nearest or Distance < Stats.Nearest) then
                        Stats.Nearest = Distance
                    end
                    local LastAttempt = PickupAttempts[Id]
                    if LastAttempt and Now - LastAttempt <= PICKUP_RETRY then
                        Stats.Cooldown += 1
                    elseif Distance and Distance <= State.CollectRange then
                        table.insert(Pickups, { Object = Object, Id = Id })
                    else
                        Stats.OutOfRange += 1
                    end
                end
            end
        end
        return Pickups, Folder, Stats
    end

    local function Pickup(Id)
        PickupAttempts[Id] = os.clock()
        pcall(function() Env.Remotes.pickupObject.fire(Id) end)
    end

    local Collect = {
        Categories = { "Nguyên liệu", "Item", "Vật liệu", "Xác Zombie", "Đồ y tế" },
        Selected = {},
        Enabled = false,
        Allowed = {},
    }

    do

    local function ToSet(List)
        local Set = {}
        for _, Name in ipairs(List) do Set[Name] = true end
        return Set
    end

    local FallbackSets = {
        ["Nguyên liệu"] = ToSet({
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
        ["Vật liệu"] = ToSet({
            "BrokenLantern", "CarBattery", "CrackedBell", "CrushedCan", "Gear", "GoldFlakes", "IronScrap",
            "Lamp", "Lantern", "MetalBarrel", "MetalBucket", "MetalGear", "MetalScrap", "Nail", "Nut",
            "OldBattery", "OldCan", "Painting", "RefinedSteel", "RockingChair", "Skull", "SteelOfMars", "Teapot",
            "Toaster", "VintageTV", "Wheel", "WheelBarrow", "WoodChair", "WoodenNail", "WoodStool",
        }),
        ["Đồ y tế"] = ToSet({ "Bandage", "FirstAidKit", "ReviveKit" }),
    }

    local CategoryCache = {}

    function Collect.Classify(Name)
        local Cached = CategoryCache[Name]
        if Cached then return Cached end
        local Category = "Item"
        if HasTag(Name, "Corpse") then
            Category = "Xác Zombie"
        elseif HasTag(Name, "Ingredient") or FallbackSets["Nguyên liệu"][Name] then
            Category = "Nguyên liệu"
        elseif HasTag(Name, "CraftingPart") or FallbackSets["Vật liệu"][Name] then
            Category = "Vật liệu"
        elseif FallbackSets["Đồ y tế"][Name] then
            Category = "Đồ y tế"
        end
        CategoryCache[Name] = Category
        return Category
    end

    local function ClassifyPickup(Object)
        if Object:FindFirstChild("HumanoidRootPart") then return "Xác Zombie" end
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
    end

    local function RunAutoCollect()
        if not Env.Remotes or next(Collect.Allowed) == nil then return end
        for _, Pickable in ipairs(FindPickups(Collect.IsAllowed)) do
            Pickup(Pickable.Id)
        end
    end

    task.spawn(function()
        while true do
            task.wait(COLLECT_INTERVAL)
            if next(Collect.Allowed) ~= nil then Guard("tự nhặt", RunAutoCollect) end
        end
    end)

    local CollectSection = FarmTab:AddSection("Tự động nhặt", false)
    CollectSection:AddSlider("Phạm vi", 1, 2000, State.CollectRange, function(Value)
        State.CollectRange = math.clamp(Value, 1, 2000)
    end, 0, "collect_range")

    CollectSection:AddSwitch("Bật tự nhặt", false, function(Enabled)
        Collect.Enabled = Enabled
        Collect.Refresh()
    end, "collect_enabled")
    CollectSection:AddMultiDropdown("Loại nhặt", Collect.Categories, function(List)
        local Set = {}
        for _, Category in ipairs(List) do Set[Category] = true end
        Collect.Selected = Set
        Collect.Refresh()
    end, "collect_types", {})

    do
    local GRIND_REACH = 12
    local GRIND_BUFFER = "0\001"
    local GrindStations = {
        ["Vật liệu"] = "BlueprintsTable",
        ["Xác Zombie"] = "Grinder",
    }
    local GrindCategories = { "Vật liệu", "Xác Zombie" }
    local STORED_NAME_KEYS = { "objectName", "name", "Name", "objectType", "type", "itemName", "item", "id", "objectId" }

    local Grind = {
        Selected = {},
        Delay = 0.3,
        Origin = nil,
    }

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

    local function ReturnFromGrind()
        if not Grind.Origin then return end
        local _, _, Root = GetCharacter()
        if Root then Root.CFrame = Grind.Origin end
        Grind.Origin = nil
    end

    local function RunGrind()
        local Slot, Deposit = FindGrindJob()
        local _, _, Root = GetCharacter()
        if not (Slot and Root) then
            ReturnFromGrind()
            return
        end
        local Remote = GetZapRemote("ZAP_RELIABLE")
        if not Remote then return end

        local Position = GetObjectPosition(Deposit)
        if Position and (Position - Root.Position).Magnitude > GRIND_REACH then
            if not Grind.Origin then Grind.Origin = Root.CFrame end
            Root.CFrame = CFrame.new(Position + Vector3.new(0, 3, 0))
            task.wait(0.15)
        end
        if Env.Remotes and Env.Remotes.switchSlot then
            pcall(function() Env.Remotes.switchSlot.fire(Slot) end)
            task.wait(0.1)
        end
        pcall(function()
            Remote:FireServer(buffer.fromstring(GRIND_BUFFER), { Deposit })
        end)
    end

    local function SetGrind(Enabled)
        SetLoop("tự nghiền", Enabled, function() return math.max(0.05, Grind.Delay) end, RunGrind)
        if not Enabled then ReturnFromGrind() end
    end

    local function DumpInventory()
        local function Notify(Type, Content)
            pcall(function()
                Window:Notify({ Type = Type, Title = "Túi đồ", Content = Content, Duration = 5 })
            end)
        end
        local Slots = GetInventorySlots()
        if not Slots then
            Notify("error", "Không đọc được Inventory.")
            return
        end
        local Lines = {}
        for Slot, Entry in pairs(Slots) do
            local Object = type(Entry) == "table" and type(Entry.storedObjects) == "table" and Entry.storedObjects[1]
            local Parts = {}
            if type(Object) == "table" then
                for Key, Value in pairs(Object) do
                    table.insert(Parts, tostring(Key) .. "=" .. tostring(Value))
                end
            end
            table.insert(Lines, tostring(Slot) .. ": " .. table.concat(Parts, ", "))
        end
        table.sort(Lines)
        for _, Line in ipairs(Lines) do print("[Túi đồ] " .. Line) end
        Notify("success", "Đã in " .. #Lines .. " ô ra console.")
    end

    local GrindSection = FarmTab:AddSection("Tự động nghiền", false)
    GrindSection:AddSwitch("Bật tự nghiền", false, SetGrind, "grind_enabled")
    GrindSection:AddMultiDropdown("Loại nghiền", GrindCategories, function(List)
        local Set = {}
        for _, Category in ipairs(List) do Set[Category] = true end
        Grind.Selected = Set
    end, "grind_types", {})
    GrindSection:AddSlider("Tốc độ nghiền", 0.05, 2, Grind.Delay, function(Value)
        Grind.Delay = math.clamp(Value, 0.05, 2)
    end, 2, "grind_delay")
    GrindSection:AddButton("In túi đồ ra console", "In", DumpInventory)
    end
end
