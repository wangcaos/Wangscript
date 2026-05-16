local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- === HỆ THỐNG CẤU HÌNH SONG SONG PC & MOBILE ===
local Config = {
    Aimbot_Enabled = false,
    AimbotMode = "None",
    FOV_Enabled = false,   
    ESP_Enabled = false,   
    Chams_Enabled = false, 
    FOV_Radius = 130,      
    SnapSpeed = 0.35,
    SwitchDelay = 0.4,
    FillTransparency = 0.8
}

local CurrentTarget = nil
local TargetStartTime = 0
local ESP_Data = {}

-- Kiểm tra phân vùng hiển thị UI an toàn cho cả PC và Điện thoại
local ParentGui = game:GetService("CoreGui")
pcall(function()
    if gethui then ParentGui = gethui() end
end)

if ParentGui:FindFirstChild("GH_ClassicModMenu") then
    ParentGui["GH_ClassicModMenu"]:Destroy()
end

-- === THUẬT TOÁN KÉO VUỐT ĐA ĐIỂM (HỖ TRỢ CHUỘT PC & CẢM ỨNG ĐIỆN THOẠI) ===
local function DynamicDrag(guiObject)
    local dragging, dragInput, dragStart, startPos
    
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            guiObject.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- === KHỞI TẠO FRAME GIAO DIỆN PHÙ HỢP CẢ HAI NỀN TẢNG ===
local ScreenGui = Instance.new("ScreenGui", ParentGui)
ScreenGui.Name = "GH_ClassicModMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

-- Nút tròn nổi "GH" (Ẩn/Hiện Menu nhanh trên Điện thoại, PC vẫn dùng được)
local MobileToggleBtn = Instance.new("TextButton", ScreenGui)
MobileToggleBtn.Name = "MobileToggleBtn"
MobileToggleBtn.Size = UDim2.new(0, 45, 0, 45)
MobileToggleBtn.Position = UDim2.new(0, 15, 0.4, 0)
MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MobileToggleBtn.Text = "GH"
MobileToggleBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
MobileToggleBtn.Font = Enum.Font.SourceSansBold
MobileToggleBtn.TextSize = 18
MobileToggleBtn.ZIndex = 20
Instance.new("UICorner", MobileToggleBtn).CornerRadius = UDim.new(1, 0)
local ButtonStroke = Instance.new("UIStroke", MobileToggleBtn)
ButtonStroke.Color = Color3.fromRGB(100, 255, 100)
ButtonStroke.Thickness = 1.5

DynamicDrag(MobileToggleBtn)

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 265)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -132)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true

local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(50, 50, 50)
Stroke.Thickness = 1

MobileToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 24)
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TitleBar.BorderSizePixel = 0

DynamicDrag(MainFrame)
local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Text = "  wangcaos script"
TitleText.TextColor3 = Color3.new(1, 1, 1)
TitleText.Font = Enum.Font.SourceSansBold
TitleText.TextSize = 14
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Size = UDim2.new(1, -50, 1, 0)
TitleText.BackgroundTransparency = 1

local Controls = Instance.new("Frame", TitleBar)
Controls.Name = "Controls"
Controls.Size = UDim2.new(0, 46, 0, 20)
Controls.Position = UDim2.new(1, -48, 0, 2)
Controls.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", Controls)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 16
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local Content = Instance.new("Frame", MainFrame)
Content.Name = "Content"
Content.Size = UDim2.new(1, -20, 1, -34)
Content.Position = UDim2.new(0, 10, 0, 29)
Content.BackgroundTransparency = 1

local ListLayout = Instance.new("UIListLayout", Content)
ListLayout.Padding = UDim.new(0, 8)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- [HÀNG 1]: AIMBOT + MENU THẢ CHỌN CHẾ ĐỘ CHƠI
local AimFrame = Instance.new("Frame", Content)
AimFrame.Size = UDim2.new(1, 0, 0, 24)
AimFrame.BackgroundTransparency = 1
AimFrame.LayoutOrder = 1

local AimBox = Instance.new("TextButton", AimFrame)
AimBox.Size = UDim2.new(0, 14, 0, 14)
AimBox.Position = UDim2.new(0, 0, 0.5, -7)
AimBox.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
AimBox.BorderSizePixel = 0
AimBox.Text = ""
Instance.new("UICorner", AimBox).CornerRadius = UDim.new(0, 4)
AimBox.BackgroundTransparency = 0.8

local AimLabel = Instance.new("TextLabel", AimFrame)
AimLabel.Text = "Aimbot"
AimLabel.TextColor3 = Color3.new(1, 1, 1)
AimLabel.Font = Enum.Font.SourceSansBold
AimLabel.TextSize = 14
AimLabel.TextXAlignment = Enum.TextXAlignment.Left
AimLabel.Size = UDim2.new(0, 60, 1, 0)
AimLabel.Position = UDim2.new(0, 20, 0, 0)
AimLabel.BackgroundTransparency = 1

local DropBtn = Instance.new("TextButton", AimFrame)
DropBtn.Size = UDim2.new(0, 100, 0, 20)
DropBtn.Position = UDim2.new(0, 85, 0.5, -10)
DropBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
DropBtn.Text = "None  ▼"
DropBtn.TextColor3 = Color3.new(1, 1, 1)
DropBtn.Font = Enum.Font.SourceSans
DropBtn.TextSize = 12
Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 4)
local DropStroke = Instance.new("UIStroke", DropBtn)
DropStroke.Color = Color3.fromRGB(50, 50, 50)

AimBox.MouseButton1Click:Connect(function()
    Config.Aimbot_Enabled = not Config.Aimbot_Enabled
    AimBox.BackgroundTransparency = Config.Aimbot_Enabled and 0 or 0.8
end)

local DropMenu = Instance.new("Frame", ScreenGui)
DropMenu.Size = UDim2.new(0, 100, 0, 92)
DropMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DropMenu.Visible = false
DropMenu.BorderSizePixel = 0
DropMenu.ZIndex = 15
Instance.new("UICorner", DropMenu).CornerRadius = UDim.new(0, 4)
local MenuStroke = Instance.new("UIStroke", DropMenu)
MenuStroke.Color = Color3.fromRGB(60, 60, 60)

local MenuLayout = Instance.new("UIListLayout", DropMenu)
MenuLayout.Padding = UDim.new(0, 1)

local function AlignDropdown()
    DropMenu.Position = UDim2.new(0, DropBtn.AbsolutePosition.X, 0, DropBtn.AbsolutePosition.Y + DropBtn.AbsoluteSize.Y + 5)
end
DropBtn:GetPropertyChangedSignal("AbsolutePosition"):Connect(AlignDropdown)

local function AddMode(name)
    local btn = Instance.new("TextButton", DropMenu)
    btn.Size = UDim2.new(1, 0, 0, 22)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 16

    btn.MouseButton1Click:Connect(function()
        Config.AimbotMode = name
        DropBtn.Text = name .. "  ▼"
        DropMenu.Visible = false
    end)
end

AddMode("None")
AddMode("Khác team")
AddMode("Mọi người")
AddMode("Bot")

DropBtn.MouseButton1Click:Connect(function()
    AlignDropdown()
    DropMenu.Visible = not DropMenu.Visible
end)

local function AddToggleRow(labelText, isBold, configKey)
    local frame = Instance.new("Frame", Content)
    frame.Size = UDim2.new(1, 0, 0, 24)
    frame.BackgroundTransparency = 1

    local box = Instance.new("TextButton", frame)
    box.Size = UDim2.new(0, 14, 0, 14)
    box.Position = UDim2.new(0, 0, 0.5, -7)
    box.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
    box.BorderSizePixel = 0
    box.Text = ""
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    box.BackgroundTransparency = 0.8

    local lbl = Instance.new("TextLabel", frame)
    lbl.Text = labelText
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font = isBold and Enum.Font.SourceSansBold or Enum.Font.SourceSans
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Size = UDim2.new(1, -20, 1, 0)
    lbl.Position = UDim2.new(0, 20, 0, 0)
    lbl.BackgroundTransparency = 1

    box.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        box.BackgroundTransparency = Config[configKey] and 0 or 0.8
    end)
    return box
end

local FOVToggleBox = AddToggleRow("FOV", true, "FOV_Enabled")
local ESPToggleBox = AddToggleRow("esp", false, "ESP_Enabled")
local ChamsToggleBox = AddToggleRow("chams", false, "Chams_Enabled")

-- Phím tắt cứng [ trên PC độc lập để bật tắt nhanh Chams
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.LeftBracket then
        Config.Chams_Enabled = not Config.Chams_Enabled
        ChamsToggleBox.BackgroundTransparency = Config.Chams_Enabled and 0 or 0.8
    end
end)

-- Định hình cấu trúc Drawing tương thích đa nhân đồ họa Executor
local FOVCircle = Drawing.new("Circle")
local TraceLine = Drawing.new("Line")

FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.NumSides = 64

TraceLine.Color = Color3.fromRGB(255, 255, 255)
TraceLine.Thickness = 1.5
TraceLine.Transparency = 1
-- === MẠCH KIỂM TRA TƯỜNG RAYCAST (TƯƠNG THÍCH PC & MOBILE CAMERA) ===
local function IsVisible(targetPart, targetChar)
    if not targetPart or not targetChar then return false end
    
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetChar, Camera}
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    
    -- Nếu không chạm vật cản bên ngoài -> Kẻ địch hiển thị lộ diện hoàn toàn
    return result == nil
end

-- === THUẬT TOÁN TÌM KIẾM MỤC TIÊU CHUẨN TRONG VÒNG FOV ===
local function QuetMucTieu()
    if Config.AimbotMode == "None" then return nil end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local selectedTarget, closest = nil, Config.FOV_Radius

    if Config.AimbotMode == "Bot" then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("Head") then
                if not Players:GetPlayerFromCharacter(obj) and obj.Humanoid.Health > 0 then
                    local head = obj.Head
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        if IsVisible(head, obj) then
                            local sizeDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                            if sizeDist < closest then closest = sizeDist selectedTarget = head end
                        end
                    end
                end
            end
        end
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local checkTeam = (Config.AimbotMode == "Mọi người") or (Config.AimbotMode == "Khác team" and p.Team ~= LocalPlayer.Team)
                if checkTeam then
                    local head = p.Character.Head
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        if IsVisible(head, p.Character) then
                            local sizeDist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                            if sizeDist < closest then closest = sizeDist selectedTarget = head end
                        end
                    end
                end
            end
        end
    end
    return selectedTarget
end

-- === VÒNG LẶP LIÊN TỤC RENDER BẢN VẼ FOV & LINE TRẮNG TOÀN DIỆN ===
RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Khóa chặt tâm vòng tròn FOV chuẩn xác giữa màn hình máy tính/điện thoại
    FOVCircle.Position = center
    FOVCircle.Radius = Config.FOV_Radius
    FOVCircle.Visible = Config.FOV_Enabled 

    if Config.Aimbot_Enabled then
        local targetHead = QuetMucTieu()
        if targetHead then
            if CurrentTarget == nil or (targetHead ~= CurrentTarget and os.clock() - TargetStartTime >= Config.SwitchDelay) then
                if targetHead ~= CurrentTarget then TargetStartTime = os.clock() end
                CurrentTarget = targetHead
            end
        else
            CurrentTarget = nil
        end

        if CurrentTarget and CurrentTarget.Parent then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, CurrentTarget.Position), Config.SnapSpeed)
            
            local screenPos, targetOnScreen = Camera:WorldToViewportPoint(CurrentTarget.Position)
            if targetOnScreen then
                TraceLine.From = center
                TraceLine.To = Vector2.new(screenPos.X, screenPos.Y)
                TraceLine.Visible = true
            else
                TraceLine.Visible = false
            end
        else
            TraceLine.Visible = false
        end
    else
        TraceLine.Visible = false
    end
end)

-- === KHỞI TẠO MẢNG DRAWING CHO SIÊU ESP ĐỎ KHÔNG GIỚI HẠN ===
local function createESP(player)
    if player == LocalPlayer then return end
    if ESP_Data[player] then return end
    
    local data = {
        L1 = Drawing.new("Line"), L2 = Drawing.new("Line"), 
        L3 = Drawing.new("Line"), L4 = Drawing.new("Line"),
        Health = Drawing.new("Line"),
        Tracer = Drawing.new("Line")
    }

    for _, line in pairs(data) do
        line.Thickness = 1.5
        line.Color = Color3.fromRGB(255, 0, 0)
        line.Transparency = 1
        line.Visible = false
    end
    data.Health.Thickness = 2 

    ESP_Data[player] = data
end
-- === VÒNG LẶP RENDER CẬP NHẬT SIÊU ESP ĐỎ (VÔ HẠN KHOẢNG CÁCH) ===
local function updateESP()
    for _, player in pairs(Players:GetPlayers()) do
        local data = ESP_Data[player]
        if not data then 
            if player ~= LocalPlayer then createESP(player) end 
            continue 
        end

        local char = player.Character
        -- Không giới hạn khoảng cách, xa bao nhiêu vẫn hiện khung đỏ
        if Config.ESP_Enabled and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
            local root = char.HumanoidRootPart
            local hum = char.Humanoid
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)

            if onScreen then
                local head = char:FindFirstChild("Head")
                if head then
                    local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                    
                    local h = math.abs(headPos.Y - legPos.Y)
                    local w = h / 2
                    local x, y = pos.X - w/2, pos.Y - h/2

                    -- Box Khung vuông Đỏ
                    data.L1.From = Vector2.new(x, y)
                    data.L1.To = Vector2.new(x + w, y)
                    data.L2.From = Vector2.new(x + w, y)
                    data.L2.To = Vector2.new(x + w, y + h)
                    data.L3.From = Vector2.new(x + w, y + h)
                    data.L3.To = Vector2.new(x, y + h)
                    data.L4.From = Vector2.new(x, y + h)
                    data.L4.To = Vector2.new(x, y)

                    -- Thanh máu sát rạt box (cách đúng 2 pixel)
                    local healthX = x - 2 
                    data.Health.From = Vector2.new(healthX, y + h)
                    data.Health.To = Vector2.new(healthX, y + h - (h * (hum.Health / hum.MaxHealth)))
                    data.Health.Color = Color3.fromRGB(255, 0, 0) 

                    -- Tracer từ đáy box thẳng xuống đáy giữa màn hình
                    data.Tracer.From = Vector2.new(x + w/2, y + h)
                    data.Tracer.To = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

                    for _, line in pairs(data) do line.Visible = true end
                else
                    for _, line in pairs(data) do line.Visible = false end
                end
            else
                for _, line in pairs(data) do line.Visible = false end
            end
        else
            for _, line in pairs(data) do line.Visible = false end
        end
    end
end

RunService.RenderStepped:Connect(updateESP)

-- === MẠCH ĐIỀU KHIỂN CHAMS KHỐI ĐẶC 20% MÀU ===
local function GetPlayerColor(Player)
    if Player.Team then return Player.TeamColor.Color end
    if Player.TeamColor ~= BrickColor.new("White") and Player.TeamColor ~= BrickColor.new("Medium stone grey") then
        return Player.TeamColor.Color
    end
    return Color3.fromRGB(0, 255, 0)
end

local function GetEquippedTool(Character)
    local Tool = Character:FindFirstChildOfClass("Tool")
    return Tool and Tool.Name or "None"
end

local function ApplyChams(Player)
    if Player == LocalPlayer then return end

    local function Setup(Character)
        local Root = Character:WaitForChild("HumanoidRootPart", 15)
        local Head = Character:WaitForChild("Head", 15)
        if not Root or not Head then return end

        if Root:FindFirstChild("BéBoxFill") then Root["BéBoxFill"]:Destroy() end
        local Box = Instance.new("BoxHandleAdornment")
        Box.Name = "BéBoxFill"
        Box.Parent = Root
        Box.Adornee = Root
        Box.AlwaysOnTop = true
        Box.ZIndex = 5
        Box.Size = Vector3.new(4, 6, 4)
        Box.Transparency = Config.FillTransparency

        if Head:FindFirstChild("BéInfoTag") then Head["BéInfoTag"]:Destroy() end
        local Gui = Instance.new("BillboardGui")
        Gui.Name = "BéInfoTag"
        Gui.Adornee = Head
        Gui.Size = UDim2.new(0, 200, 0, 100)
        Gui.StudsOffset = Vector3.new(0, 4, 0)
        Gui.AlwaysOnTop = true

        local Label = Instance.new("TextLabel", Gui)
        Label.Size = UDim2.new(1, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Font = Enum.Font.Code
        Label.TextSize = 14
        Label.TextStrokeTransparency = 0
        Label.TextColor3 = Color3.new(1, 1, 1)
        Gui.Parent = Head

        local Connection
        Connection = RunService.RenderStepped:Connect(function()
            if not Character.Parent or not Root.Parent or not Head.Parent then
                Connection:Disconnect()
                if Gui then Gui:Destroy() end
                return
            end

            local Hum = Character:FindFirstChild("Humanoid")
            if Config.Chams_Enabled and Hum and Hum.Health > 0 then
                local color = GetPlayerColor(Player)
                local dist = math.floor((Root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
                local teamName = Player.Team and Player.Team.Name or "No Team"
                local toolName = GetEquippedTool(Character)

                Box.Visible = true
                Box.Color3 = color

                Label.Visible = true
                Label.TextColor3 = color
                Label.Text = string.format("%s (%dm)\n(%s)(%s)", Player.Name, dist, teamName, toolName)
                
                Gui.Enabled = (dist <= 500)
            else
                Box.Visible = false
                Label.Visible = false
            end
        end)
    end

    Player.CharacterAdded:Connect(Setup)
    if Player.Character then Setup(Player.Character) end
end

-- === VẬN HÀNH TOÀN BỘ HỆ THỐNG ===
Players.PlayerRemoving:Connect(function(player)
    if ESP_Data[player] then
        for _, line in pairs(ESP_Data[player]) do line:Remove() end
        ESP_Data[player] = nil
    end
end)

Players.PlayerAdded:Connect(function(p)
    createESP(p)
    ApplyChams(p)
end)

for _, v in pairs(Players:GetPlayers()) do 
    createESP(v) 
    ApplyChams(v)
end

print("--- [Wangcaos Engine V6 Dual PC/Mobile Cross-Platform Loaded!] ---")
