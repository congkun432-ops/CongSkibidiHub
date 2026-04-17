local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
if CoreGui:FindFirstChild("MainHub_FPS") then CoreGui["MainHub_FPS"]:Destroy() end
_G.EspBox = false
_G.EspName = false
_G.EspDistance = false
_G.EspHealth = false
_G.EspTracer = false
_G.EspBot = false
_G.FieldOfView = 70
_G.AimSmoothness = 0.5
_G.AimbotEnabled = false
_G.ShowFOV = false
_G.FOVRadius = 100
_G.HubName = "roblox rác"
_G.AuthorName = "công skibidi"
_G.InfiniteJump = false
_G.CustomCrosshair = false
_G.CrosshairType = "Classic"
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1; FOVCircle.Transparency = 0.7; FOVCircle.Filled = false; FOVCircle.Visible = false
local function CreateSwitch(name, parent, callback)
    local SwitchFrame = Instance.new("Frame", parent)
    SwitchFrame.Size = UDim2.new(1, 0, 0, 35); SwitchFrame.BackgroundTransparency = 1
    local Label = Instance.new("TextLabel", SwitchFrame)
    Label.Size = UDim2.new(0.6, 0, 1, 0); Label.Text = name; Label.TextColor3 = Color3.new(1, 1, 1)
    Label.Font = Enum.Font.GothamMedium; Label.TextSize = 12; Label.BackgroundTransparency = 1; Label.TextXAlignment = 0
    local BG = Instance.new("Frame", SwitchFrame)
    BG.Size = UDim2.new(0, 35, 0, 18); BG.Position = UDim2.new(1, -40, 0.5, -9)
    BG.BackgroundColor3 = Color3.fromRGB(50, 50, 50); Instance.new("UICorner", BG).CornerRadius = UDim.new(1, 0)
    local Ball = Instance.new("Frame", BG)
    Ball.Size = UDim2.new(0, 14, 0, 14); Ball.Position = UDim2.new(0, 2, 0.5, -7)
    Ball.BackgroundColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", Ball).CornerRadius = UDim.new(1, 0)
    local ClickBtn = Instance.new("TextButton", SwitchFrame)
    ClickBtn.Size = UDim2.new(1, 0, 1, 0); ClickBtn.BackgroundTransparency = 1; ClickBtn.Text = ""
    local state = false
    ClickBtn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(Ball, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}):Play()
        TweenService:Create(BG, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 50, 50)}):Play()
        callback(state)
    end)
end

local function CreateTextBox(name, parent, placeholder, callback)
    local BoxFrame = Instance.new("Frame", parent)
    BoxFrame.Size = UDim2.new(1, 0, 0, 35); BoxFrame.BackgroundTransparency = 1
    local Label = Instance.new("TextLabel", BoxFrame)
    Label.Size = UDim2.new(0.5, 0, 1, 0); Label.Text = name; Label.TextColor3 = Color3.new(1, 1, 1)
    Label.Font = Enum.Font.GothamMedium; Label.TextSize = 12; Label.BackgroundTransparency = 1; Label.TextXAlignment = 0
    local Input = Instance.new("TextBox", BoxFrame)
    Input.Size = UDim2.new(0, 60, 0, 25); Input.Position = UDim2.new(1, -65, 0.5, -12)
    Input.BackgroundColor3 = Color3.fromRGB(35, 35, 35); Input.TextColor3 = Color3.new(1, 1, 1)
    Input.Text = placeholder; Input.TextSize = 12; Instance.new("UICorner", Input); Input.ClearTextOnFocus = true
    Input.FocusLost:Connect(function() 
        callback(Input.Text) 
        if name == "Tầm nhìn (Zoom)" then 
            _G.FieldOfView = tonumber(Input.Text) or 70 
        end 
    end)
end

local function AddInfo(text, parent)
    local Label = Instance.new("TextLabel", parent)
    Label.Size = UDim2.new(1, 0, 0, 25); Label.BackgroundTransparency = 1; Label.Text = text; Label.TextColor3 = Color3.new(1, 1, 1); Label.Font = Enum.Font.Gotham; Label.TextSize = 11; Label.TextXAlignment = 0
end
local ScreenGui = Instance.new("ScreenGui", CoreGui); ScreenGui.Name = "MainHub_FPS"
local ToggleBtn = Instance.new("TextButton", ScreenGui)
ToggleBtn.Size = UDim2.new(0, 60, 0, 60); ToggleBtn.Position = UDim2.new(0, 10, 0.4, 0); ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); ToggleBtn.Text = "OPEN"; ToggleBtn.TextColor3 = Color3.fromRGB(255, 165, 0); ToggleBtn.Font = Enum.Font.GothamBold; ToggleBtn.TextSize = 14; ToggleBtn.Draggable = true; Instance.new("UICorner", ToggleBtn)
local BtnStroke = Instance.new("UIStroke", ToggleBtn); BtnStroke.Color = Color3.fromRGB(255, 165, 0); BtnStroke.Thickness = 2

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 450, 0, 300); MainFrame.Position = UDim2.new(0.5, -225, 0.5, -150); MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10); MainFrame.Visible = false; MainFrame.Active = true; MainFrame.Draggable = true
local MainStroke = Instance.new("UIStroke", MainFrame); MainStroke.Thickness = 3; Instance.new("UICorner", MainFrame)

local TitleLabel = Instance.new("TextLabel", MainFrame)
TitleLabel.Size = UDim2.new(1, 0, 0, 35); TitleLabel.BackgroundTransparency = 1; TitleLabel.Font = Enum.Font.GothamBold; TitleLabel.TextSize = 14; TitleLabel.ZIndex = 2

task.spawn(function()
    while true do
        local rainbow = Color3.fromHSV(tick() % 5 / 5, 1, 1)
        MainStroke.Color = rainbow; FOVCircle.Color = rainbow; TitleLabel.TextColor3 = rainbow
        TitleLabel.Text = _G.HubName .. " | Tác giả: " .. _G.AuthorName
        task.wait()
    end
end)

local TabContainer = Instance.new("Frame", MainFrame)
TabContainer.Size = UDim2.new(0, 100, 1, -45); TabContainer.Position = UDim2.new(0, 10, 0, 40); TabContainer.BackgroundTransparency = 1
Instance.new("UIListLayout", TabContainer).Padding = UDim.new(0, 5)
local ContentContainer = Instance.new("Frame", MainFrame)
ContentContainer.Size = UDim2.new(1, -135, 1, -45); ContentContainer.Position = UDim2.new(0, 125, 0, 40); ContentContainer.BackgroundTransparency = 1

local Pages = {}
local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame", ContentContainer)
    Page.Name = name.."Page"; Page.Size = UDim2.new(1, 0, 1, 0); Page.BackgroundTransparency = 1; Page.Visible = false; Page.ScrollBarThickness = 2; Page.CanvasSize = UDim2.new(0, 0, 2, 0)
    Instance.new("UIListLayout", Page).Padding = UDim.new(0, 8)
    Pages[name] = Page; return Page
end

local function AddTabBtn(name)
    local TabBtn = Instance.new("TextButton", TabContainer)
    TabBtn.Size = UDim2.new(1, 0, 0, 35); TabBtn.Text = name; TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); TabBtn.TextColor3 = Color3.fromRGB(200, 200, 200); TabBtn.Font = Enum.Font.GothamBold; TabBtn.TextSize = 11; Instance.new("UICorner", TabBtn)
    TabBtn.MouseButton1Click:Connect(function()
        for i, v in pairs(Pages) do v.Visible = (i == name) end
        for _, btn in pairs(TabContainer:GetChildren()) do if btn:IsA("TextButton") then btn.TextColor3 = Color3.fromRGB(200, 200, 200) end end
        TabBtn.TextColor3 = Color3.fromRGB(255, 165, 0)
    end)
end
local PageAim = CreatePage("AIMBOT")
local PageVisual = CreatePage("ESP")
local PagePlayer = CreatePage("NHÂN VẬT")
local PageInfo = CreatePage("THÔNG TIN")

-- [[ TAB AIMBOT ]]
CreateTextBox("Tốc độ Aim", PageAim, "0.5", function(v) _G.AimSmoothness = tonumber(v) or 0.5 end)
CreateSwitch("Bật Aimbot", PageAim, function(s) _G.AimbotEnabled = s end)
CreateSwitch("Vòng tròn FOV", PageAim, function(s) _G.ShowFOV = s end)
CreateTextBox("Kích thước FOV", PageAim, "100", function(v) _G.FOVRadius = tonumber(v) or 100 end)
-- --- PHẦN CHỌN MẪU TÂM CÓ SẴN ---
AddInfo("-----------------------------", PageAim)
AddInfo("MẪU TÂM SÚNG (CROSSHAIR)", PageAim)
CreateSwitch("Bật Tâm Tùy Chỉnh", PageAim, function(s) _G.CustomCrosshair = s end)

local function AddCrosshairBtn(name)
    local Btn = Instance.new("TextButton", PageAim)
    Btn.Size = UDim2.new(1, -10, 0, 30)
    Btn.Text = "Kiểu: " .. name
    Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Btn.TextColor3 = Color3.new(1, 1, 1)
    Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 12
    Instance.new("UICorner", Btn)
    
    Btn.MouseButton1Click:Connect(function()
        _G.CrosshairType = name
        -- Reset màu các nút khác
        for _, v in pairs(PageAim:GetChildren()) do
            if v:IsA("TextButton") and v.Text:find("Kiểu:") then v.TextColor3 = Color3.new(1, 1, 1) end
        end
        Btn.TextColor3 = Color3.fromRGB(255, 165, 0) -- Đổi màu khi chọn
    end)
end

AddCrosshairBtn("Classic")
AddCrosshairBtn("Dot")
AddCrosshairBtn("Circle")
AddCrosshairBtn("Square")
-- [[ TAB ESP ]]
CreateSwitch("Hiện khung (Box)", PageVisual, function(s) _G.EspBox = s end)
CreateSwitch("Tên và Khoảng cách", PageVisual, function(s) _G.EspName = s; _G.EspDistance = s end)
CreateSwitch("Hiện máu", PageVisual, function(s) _G.EspHealth = s end)
CreateSwitch("Vẽ đường kẻ (Tracer)", PageVisual, function(s) _G.EspTracer = s end)
CreateSwitch("ESP cho Bot", PageVisual, function(s) _G.EspBot = s end)
CreateTextBox("Tầm nhìn (Zoom)", PageVisual, "70", function(v) _G.FieldOfView = tonumber(v) or 70 end)
-- DÁN ĐOẠN NÀY VÀO TAB NHÂN VẬT:
AddInfo("--- DI CHUYỂN ---", PagePlayer)
CreateSwitch("Nhảy vô hạn (Inf Jump)", PagePlayer, function(s)
    _G.InfiniteJump = s
end)

CreateTextBox("Tốc độ chạy", PagePlayer, "16", function(v) 
    local speed = tonumber(v) or 16
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = speed
end)

CreateTextBox("Sức mạnh nhảy", PagePlayer, "50", function(v)
    local power = tonumber(v) or 50
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = power
end)

AddInfo("------game rác-------", PageInfo)
AddInfo("bố mày mới là người tạo:công đẹp trai", PageInfo)
AddInfo("Phiên bản: 3.6.36", PageInfo)
AddInfo("-----------------------------", PageInfo)
AddInfo("bản này bị lỗi rất nhiều :)))", PageInfo)
AddInfo("-----------------------------", PageInfo)
AddInfo("Chức năng bổ sung:", PageInfo)
CreateTextBox("Đổi tên Hub", PageInfo, _G.HubName, function(v) if v ~= "" then _G.HubName = v end end)
CreateTextBox("Đổi tên tác giả", PageInfo, _G.AuthorName, function(v) if v ~= "" then _G.AuthorName = v end end)
-- [[ TÍNH NĂNG NOCLIP - XUYÊN VẠN VẬT ]]
AddInfo("--- DI CHUYỂN ĐẶC BIỆT ---", PagePlayer)

_G.Noclip = false
CreateSwitch("Bật Xuyên Tường (Noclip)", PagePlayer, function(state)
    _G.Noclip = state
end)

-- Logic xử lý Noclip (Chạy ngầm)
RunService.Stepped:Connect(function()
    if _G.Noclip then
        local char = game.Players.LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide == true then
                    part.CanCollide = false
                end
            end
        end
    end
end)

AddInfo("Mẹo: Bật Noclip để né bị kẹt khi Teleport!", PagePlayer)

AddTabBtn("AIMBOT"); AddTabBtn("ESP"); AddTabBtn("NHÂN VẬT"); AddTabBtn("THÔNG TIN")
Pages["AIMBOT"].Visible = true
ToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible; ToggleBtn.Text = MainFrame.Visible and "CLOSE" or "OPEN" end)
local function GetClosestPlayer()
    local Target, MaxDist = nil, _G.FOVRadius or 100
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= game.Players.LocalPlayer and v.Character and v.Character:FindFirstChild("Head") and v.Character.Humanoid.Health > 0 then
            local ScreenPos, OnScreen = workspace.CurrentCamera:WorldToViewportPoint(v.Character.Head.Position)
            if OnScreen then
                local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2)).Magnitude
                if Dist < MaxDist then
                    if #workspace.CurrentCamera:GetPartsObscuringTarget({v.Character.Head.Position}, {game.Players.LocalPlayer.Character, v.Character}) == 0 then
                        Target = v; MaxDist = Dist
                    end
                end
            end
        end
    end
    return Target
end
local function CreateESP(Obj, isBot)
    local BoxOutline = Drawing.new("Square"); BoxOutline.Visible = false; BoxOutline.Color = Color3.new(0, 0, 0); BoxOutline.Thickness = 3; BoxOutline.Transparency = 0.7; BoxOutline.Filled = false
    local BoxMain = Drawing.new("Square"); BoxMain.Visible = false; BoxMain.Color = isBot and Color3.new(0, 1, 0) or Color3.new(0, 1, 1); BoxMain.Thickness = 1; BoxMain.Transparency = 1; BoxMain.Filled = false
    local Name = Drawing.new("Text"); Name.Visible = false; Name.Size = 14; Name.Center = true; Name.Outline = true; Name.Color = Color3.new(1, 1, 1)
    local Tracer = Drawing.new("Line"); local HealthBar = Drawing.new("Line")

    local Connection
    Connection = RunService.RenderStepped:Connect(function()
        if Obj and Obj.Parent and Obj:FindFirstChild("Humanoid") and Obj.Humanoid.Health > 0 then
            local Root = Obj:FindFirstChild("HumanoidRootPart") or Obj:FindFirstChild("Head")
            if not Root then return end
            local Pos, OnScreen = workspace.CurrentCamera:WorldToViewportPoint(Root.Position)     
            if OnScreen and (not isBot or _G.EspBot) then
                local SizeY = math.abs(workspace.CurrentCamera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0)).Y - workspace.CurrentCamera:WorldToViewportPoint(Root.Position + Vector3.new(0, 2.6, 0)).Y)
                local BoxSize = Vector2.new(SizeY * 1.2, SizeY); local BoxPos = Vector2.new(Pos.X - BoxSize.X / 2, Pos.Y - BoxSize.Y / 2)
                BoxOutline.Visible = _G.EspBox; BoxOutline.Size = BoxSize; BoxOutline.Position = BoxPos
                BoxMain.Visible = _G.EspBox; BoxMain.Size = BoxSize; BoxMain.Position = BoxPos
                Name.Visible = _G.EspName; Name.Text = (isBot and "[BOT] " or "") .. Obj.Name .. " [" .. math.floor((workspace.CurrentCamera.CFrame.Position - Root.Position).Magnitude) .. "m]"; Name.Position = Vector2.new(Pos.X, BoxPos.Y - 15)
                if _G.EspTracer and not isBot then
                    Tracer.Visible = true;	Tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, 0)
Tracer.To = Vector2.new(Pos.X, BoxPos.Y)
                else Tracer.Visible = false end
                if _G.EspHealth and not isBot then
                    HealthBar.Visible = true; HealthBar.Color = Color3.new(0, 1, 0); HealthBar.From = Vector2.new(BoxPos.X - 5, BoxPos.Y + BoxSize.Y); HealthBar.To = Vector2.new(BoxPos.X - 5, BoxPos.Y + BoxSize.Y - (BoxSize.Y * (Obj.Humanoid.Health / Obj.Humanoid.MaxHealth)))
                else HealthBar.Visible = false end
            else
                BoxOutline.Visible = false; BoxMain.Visible = false; Name.Visible = false; Tracer.Visible = false; HealthBar.Visible = false
            end
        else
            BoxOutline:Destroy(); BoxMain:Destroy(); Name:Destroy(); Tracer:Destroy(); HealthBar:Destroy()
            if Connection then Connection:Disconnect() end
        end
    end)
end

for _, p in pairs(game.Players:GetPlayers()) do if p ~= game.Players.LocalPlayer then p.CharacterAdded:Connect(function(c) CreateESP(c, false) end) if p.Character then CreateESP(p.Character, false) end end end
game.Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(c) CreateESP(c, false) end) end)
task.spawn(function() while task.wait(3) do for _, o in pairs(workspace:GetChildren()) do if o:IsA("Model") and o:FindFirstChild("Humanoid") and not game.Players:GetPlayerFromCharacter(o) and not o:FindFirstChild("ESP_Added") then Instance.new("BoolValue", o).Name = "ESP_Added"; CreateESP(o, true) end end end end)

RunService.RenderStepped:Connect(function()
    workspace.CurrentCamera.FieldOfView = _G.FieldOfView
    if _G.ShowFOV then FOVCircle.Visible = true; FOVCircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2); FOVCircle.Radius = _G.FOVRadius else FOVCircle.Visible = false end
    if _G.AimbotEnabled then
        local T = GetClosestPlayer()
        if T then workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, T.Character.Head.Position), _G.AimSmoothness) end
    end
end)
UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJump then     game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)
local CrossLines = {}
local CrossCircle = Drawing.new("Circle")
CrossCircle.Visible = false

local function ClearCross()
    for _, v in pairs(CrossLines) do v:Destroy() end
    CrossLines = {}
    CrossCircle.Visible = false
end

RunService.RenderStepped:Connect(function()
    ClearCross()
    if not _G.CustomCrosshair then return end

    local Center = workspace.CurrentCamera.ViewportSize / 2
    local Color = Color3.fromRGB(0, 255, 255) -- Màu xanh Cyan
    local Size = 10

    if _G.CrosshairType == "Classic" then
        local l1 = Drawing.new("Line"); l1.Visible = true; l1.From = Center - Vector2.new(Size, 0); l1.To = Center + Vector2.new(Size, 0); l1.Color = Color; l1.Thickness = 2
        local l2 = Drawing.new("Line"); l2.Visible = true; l2.From = Center - Vector2.new(0, Size); l2.To = Center + Vector2.new(0, Size); l2.Color = Color; l2.Thickness = 2
        table.insert(CrossLines, l1); table.insert(CrossLines, l2)
    elseif _G.CrosshairType == "Dot" then
        CrossCircle.Visible = true; CrossCircle.Position = Center; CrossCircle.Radius = 3; CrossCircle.Color = Color; CrossCircle.Filled = true
    elseif _G.CrosshairType == "Circle" then
        CrossCircle.Visible = true; CrossCircle.Position = Center; CrossCircle.Radius = 8; CrossCircle.Color = Color; CrossCircle.Filled = false; CrossCircle.Thickness = 2
    elseif _G.CrosshairType == "Square" then
        local l1 = Drawing.new("Line"); l1.Visible = true; l1.From = Center + Vector2.new(-5,-5); l1.To = Center + Vector2.new(5,-5); l1.Color = Color; l1.Thickness = 2
        local l2 = Drawing.new("Line"); l2.Visible = true; l2.From = Center + Vector2.new(5,-5); l2.To = Center + Vector2.new(5,5); l2.Color = Color; l2.Thickness = 2
        local l3 = Drawing.new("Line"); l3.Visible = true; l3.From = Center + Vector2.new(5,5); l3.To = Center + Vector2.new(-5,5); l3.Color = Color; l3.Thickness = 2
        local l4 = Drawing.new("Line"); l4.Visible = true; l4.From = Center + Vector2.new(-5,5); l4.To = Center + Vector2.new(-5,-5); l4.Color = Color; l4.Thickness = 2
        table.insert(CrossLines, l1); table.insert(CrossLines, l2); table.insert(CrossLines, l3); table.insert(CrossLines, l4)
    end
end)
