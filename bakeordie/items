return function(Env)
    local Window, Guard, GetCharacter, GetObjectPosition = Env.Window, Env.Guard, Env.GetCharacter, Env.GetObjectPosition

    local Bring = {
        Enabled = false,
        Mode = "Tất cả",
        Delay = 0.05,
        Interval = 0.3,
    }

    local BringModes = { "Tất cả", "Vật phẩm", "Xác" }

    local function RunBring()
        local _, _, Root = GetCharacter()
        local Folder = workspace:FindFirstChild("Interactables")
        if not (Root and Folder) then return end

        for _, Object in ipairs(Folder:GetChildren()) do
            if not Bring.Enabled then break end
            if Object:IsA("Model") and not Object:FindFirstChild("ProductPriceTag") then
                local IsBody = Object:FindFirstChild("HumanoidRootPart") ~= nil
                local Wanted = Bring.Mode == "Tất cả"
                    or (Bring.Mode == "Xác" and IsBody)
                    or (Bring.Mode == "Vật phẩm" and not IsBody)
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

    task.spawn(function()
        while true do
            task.wait(Bring.Interval)
            if Bring.Enabled then Guard("kéo vật phẩm", RunBring) end
        end
    end)

    local ItemTab = Window:CreateTab("Vật phẩm")

    local BringSection = ItemTab:AddSection("Kéo vật phẩm", true)
    BringSection:AddSwitch("Bật kéo", false, function(Enabled) Bring.Enabled = Enabled end, "bring_enabled")
    BringSection:AddDropdown("Loại", BringModes, function(Choice)
        Bring.Mode = Choice
    end, "bring_mode")
    BringSection:AddSlider("Độ trễ", 0, 0.2, Bring.Delay, function(Value)
        Bring.Delay = math.clamp(Value, 0, 0.2)
    end, 2, "bring_delay")
end
