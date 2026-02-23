-- WangScript v2.4 FULL - Phần 1: Biến, Drawing, ESP/Trace
-- Right Ctrl mở GUI | Alt acc only!

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- States & Keys
local states = {
    Fly = false, Noclip = false, ESP = false, Trace = false,
    Aimbot = false, SilentAim = false, Invisible = false, Bypass = false,
    KillAura = false, Speed = false, Illusion = false
}
local keys = {
    Fly = Enum.KeyCode.X, Noclip = Enum.KeyCode.N, ESP = Enum.KeyCode.V,
    Trace = Enum.KeyCode.B, Aimbot = Enum.KeyCode.C, SilentAim = Enum.KeyCode.Z,
    Invisible = Enum.KeyCode.I, KillAura = Enum.KeyCode.K, Speed = Enum.KeyCode.Q,
    Illusion = Enum.KeyCode.L
}
local config = {
    FlySpeed = 50,
    WalkSpeed = 100,
    AimbotSmoothness = 0.12,
    AimbotPrediction = 0.165,
    AimbotFOV = 150,
    KillAuraRange = 6,
    KillAuraDamage = 10
}

local flying = false
local aiming = false
local guivisible = false
local bindingFeature = nil
local BodyVelocity, BodyAngularVelocity, noclipConn
local ESP_Boxes, Tracers = {}, {}
local bypassActive = false
local illusionShadows = {}

-- Drawing
local fovCircle = Drawing.new("Circle")
fovCircle.NumSides = 100; fovCircle.Thickness = 2; fovCircle.Filled = false
fovCircle.Transparency = 0.7; fovCircle.Color = Color3.fromRGB(255,100,100)
fovCircle.Radius = config.AimbotFOV; fovCircle.Visible = false

local lockHighlight = Drawing.new("Square")
lockHighlight.Thickness = 4; lockHighlight.Color = Color3.fromRGB(0,255,80); lockHighlight.Filled = false
lockHighlight.Transparency = 1; lockHighlight.Visible = false

-- Notification
local function notify(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 3
    })
end

-- Remove health bars
workspace.DescendantAdded:Connect(function(obj)
    task.wait()
    if obj.Name == "Health" and obj.Parent:IsA("BillboardGui") then obj.Parent:Destroy() end
end)

-- ESP
local function addESP(target)
    if target == player then return end
    local drawings = {
        box = Drawing.new("Square"),
        healthBg = Drawing.new("Line"),
        healthBar = Drawing.new("Line")
    }
    drawings.box.Thickness = 3; drawings.box.Color = Color3.new(1,0,0); drawings.box.Filled = false; drawings.box.Transparency = 1
    drawings.healthBg.Thickness = 4; drawings.healthBg.Color = Color3.new(0,0,0); drawings.healthBg.Transparency = 0.5
    drawings.healthBar.Thickness = 4; drawings.healthBar.Color = Color3.new(0,1,0); drawings.healthBar.Transparency = 1
    ESP_Boxes[target] = drawings

    RunService.RenderStepped:Connect(function()
        local char = target.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            for _, d in pairs(drawings) do d:Remove() end
            ESP_Boxes[target] = nil
            return
        end

        local rootPos, onScreen = camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
        if onScreen then
            local headPos = camera:WorldToViewportPoint(char.Head.Position)
            local legPos = camera:WorldToViewportPoint(char.HumanoidRootPart.Position - Vector3.new(0,4,0))
            local boxHeight = math.clamp(math.abs(headPos.Y - legPos.Y), 20, 300)
            local boxWidth = boxHeight * 0.45

            drawings.box.Size = Vector2.new(boxWidth, boxHeight)
            drawings.box.Position = Vector2.new(rootPos.X - boxWidth/2, rootPos.Y - boxHeight/2)
            drawings.box.Visible = true

            local barX = rootPos.X - boxWidth/2 - 6
            local barY = legPos.Y
            drawings.healthBg.From = Vector2.new(barX, barY)
            drawings.healthBg.To = Vector2.new(barX + 4, barY)
            drawings.healthBg.Visible = true

            local pct = char.Humanoid.Health / char.Humanoid.MaxHealth
            drawings.healthBar.From = Vector2.new(barX, barY)
            drawings.healthBar.To = Vector2.new(barX + 4 * pct, barY)
            drawings.healthBar.Visible = true
        else
            drawings.box.Visible = false
            drawings.healthBg.Visible = false
            drawings.healthBar.Visible = false
        end
    end)
end

-- Trace
local function addTrace(target)
    if target == player then return end
    local line = Drawing.new("Line")
    line.Thickness = 2; line.Color = Color3.new(1,0,0); line.Transparency = 0.5; line.Visible = false
    Tracers[target] = line

    RunService.RenderStepped:Connect(function()
        local char = target.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then line:Remove(); Tracers[target] = nil; return end
        local pos, onScreen = camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
        if onScreen then
            line.From = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
            line.To = Vector2.new(pos.X, pos.Y)
            line.Visible = true
        else line.Visible = false end
    end)
end
-- WangScript v2.4 - Phần 2: Fly, Speed, Illusion, Noclip

-- Fly
local function toggleFly(enable)
    flying = enable
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    if enable then
        BodyVelocity = Instance.new("BodyVelocity", root); BodyVelocity.MaxForce = Vector3.new(4e5,4e5,4e5)
        BodyAngularVelocity = Instance.new("BodyAngularVelocity", root); BodyAngularVelocity.MaxTorque = Vector3.new(4e5,4e5,4e5)
    else
        if BodyVelocity then BodyVelocity:Destroy() end
        if BodyAngularVelocity then BodyAngularVelocity:Destroy() end
    end
    notify("Fly", enable and "BẬT" or "TẮT", 3)
end

RunService.Heartbeat:Connect(function()
    if flying and BodyVelocity then
        local move = Vector3.new()
        local cf = camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end
        BodyVelocity.Velocity = move * config.FlySpeed
    end
end)

-- Speed Hack
local function toggleSpeed(enable)
    states.Speed = enable
    if enable and player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = config.WalkSpeed
            humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                humanoid.WalkSpeed = config.WalkSpeed
            end)
        end
        notify("Speed", "BẬT - " .. config.WalkSpeed, 3)
    else
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = 16 end
        notify("Speed", "TẮT", 3)
    end
end

-- Illusion Shadow (Naoya JJK style)
local function toggleIllusion(enable)
    states.Illusion = enable
    if enable then
        RunService.Heartbeat:Connect(function()
            if states.Illusion and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local root = player.Character.HumanoidRootPart
                if root.Velocity.Magnitude > 1 then
                    local shadow = player.Character:Clone()
                    shadow.Parent = workspace
                    shadow.HumanoidRootPart.CFrame = root.CFrame
                    shadow.Humanoid:Destroy()
                    for _, part in pairs(shadow:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = 0.5
                            part.Anchored = true
                            part.CanCollide = false
                        end
                    end
                    table.insert(illusionShadows, shadow)
                    task.delay(0.5, function()
                        if shadow and shadow.Parent then shadow:Destroy() end
                    end)
                end
            end
        end)
        notify("Illusion Shadow", "BẬT", 3)
    else
        notify("Illusion Shadow", "TẮT", 3)
    end
end

-- Noclip
local function toggleNoclip(enable)
    if noclipConn then noclipConn:Disconnect() end
    if enable and player.Character then
        noclipConn = RunService.Stepped:Connect(function()
            for _, part in player.Character:GetDescendants() do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    end
    notify("Noclip", enable and "BẬT" or "TẮT", 3)
end
-- WangScript v2.4 - Phần 3: Aimbot, Silent Aim, Invisible, KillAura

-- Aimbot
local function getClosest()
    local closest, minDist = nil, config.AimbotFOV
    local mouseLoc = UserInputService:GetMouseLocation()
    for _, p in Players:GetPlayers() do
        if p \~= player and p.Character and p.Character:FindFirstChild("Head") and p.Character.Humanoid.Health > 0 then
            local headPos, onScreen = camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(headPos.X, headPos.Y) - mouseLoc).Magnitude
                if dist < minDist then minDist = dist; closest = p.Character end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function(dt)
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Radius = config.AimbotFOV
    fovCircle.Visible = states.Aimbot
    lockHighlight.Visible = false

    if states.Aimbot and aiming then
        local target = getClosest()
        if target then
            local predPos = target.Head.Position + (target.HumanoidRootPart.Velocity * config.AimbotPrediction)
            local targetCF = CFrame.lookAt(camera.CFrame.Position, predPos)
            camera.CFrame = camera.CFrame:Lerp(targetCF, config.AimbotSmoothness * dt * 60)

            local rootPos, onScreen = camera:WorldToViewportPoint(target.HumanoidRootPart.Position)
            if onScreen then
                local headPos = camera:WorldToViewportPoint(target.Head.Position)
                local legPos = camera:WorldToViewportPoint(target.HumanoidRootPart.Position - Vector3.new(0, 4, 0))
                local boxHeight = math.clamp(math.abs(headPos.Y - legPos.Y), 20, 300)
                local boxWidth = boxHeight * 0.45

                lockHighlight.Size = Vector2.new(boxWidth, boxHeight)
                lockHighlight.Position = Vector2.new(rootPos.X - boxWidth / 2, rootPos.Y - boxHeight / 2)
                lockHighlight.Visible = true
            end
        end
    end
end)

-- Silent Aim
local mt = getrawmetatable(game)
local oldnc = mt.__namecall
setreadonly(mt, false)
mt.__namecall = function(self, ...)
    local args = {...}
    if states.SilentAim and self:IsA("RemoteEvent") and getnamecallmethod() == "FireServer" and (self.Name:lower():find("aim") or self.Name:lower():find("shoot") or self.Name:lower():find("fire")) then
        local target = getClosest()
        if target then
            args[2] = target.Head.Position + (target.HumanoidRootPart.Velocity * config.AimbotPrediction)
            args[3] = target.Head
        end
    end
    return oldnc(self, unpack(args))
end
setreadonly(mt, true)

-- Invisible FE
local function toggleInvisible(enable)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    if enable then
        hrp.CFrame = hrp.CFrame + Vector3.new(0, 10000, 0)
        task.wait(0.1)
        for _, obj in char:GetDescendants() do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then obj.LocalTransparencyModifier = 0 end
        end
        notify("Invisible", "BẬT", 3)
    else
        hrp.CFrame = workspace.SpawnLocation.CFrame + Vector3.new(0, 5, 0) or hrp.CFrame - Vector3.new(0, 10000, 0)
        notify("Invisible", "TẮT", 3)
    end
end

-- KillAura
local function toggleKillAura(enable)
    states.KillAura = enable
    if enable then
        RunService.Heartbeat:Connect(function()
            if states.KillAura and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                for _, obj in workspace:GetChildren() do
                    if obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 and obj \~= player.Character then
                        local dist = (obj.HumanoidRootPart.Position - hrp.Position).Magnitude
                        if dist <= config.KillAuraRange then
                            obj.Humanoid:TakeDamage(config.KillAuraDamage)
                        end
                    end
                end
            end
        end)
        notify("KillAura", "BẬT - Range: " .. config.KillAuraRange, 3)
    else
        notify("KillAura", "TẮT", 3)
    end
end
-- WangScript v2.4 - Phần 4: GUI, Tab, Slider, Bind, Lệnh chat

-- Pill Switch mượt
local function createToggle(parent, initialOn, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(0, 80, 0, 35)
    frame.BackgroundColor3 = initialOn and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(80, 80, 80)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", frame)
    knob.Size = UDim2.new(0, 30, 0, 30)
    knob.Position = initialOn and UDim2.new(1, -34, 0.5, -15) or UDim2.new(0, 3, 0.5, -15)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local isOn = initialOn

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isOn = not isOn
            callback(isOn)
            TweenService:Create(frame, tweenInfo, {BackgroundColor3 = isOn and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(80, 80, 80)}):Play()
            TweenService:Create(knob, tweenInfo, {Position = isOn and UDim2.new(1, -34, 0.5, -15) or UDim2.new(0, 3, 0.5, -15)}):Play()
        end
    end)
end

-- GUI
local sg = Instance.new("ScreenGui", game.CoreGui)
sg.Name = "WangScript"
sg.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", sg)
mainFrame.Size = UDim2.new(0, 600, 0, 450)
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

-- Title Bar
local titleBar = Instance.new("Frame", mainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "wangscript v2.4"
title.TextColor3 = Color3.fromRGB(200, 200, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 24

-- Tab Bar
local tabBar = Instance.new("Frame", mainFrame)
tabBar.Size = UDim2.new(1, 0, 0, 50)
tabBar.Position = UDim2.new(0, 0, 0, 50)
tabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
local tabNames = {"Combat", "Movement", "Player", "Misc"}
local tabContents = {}

for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/#tabNames, -8, 1, -8)
    btn.Position = UDim2.new((i-1)/#tabNames, 4, 0, 4)
    btn.BackgroundColor3 = (i == 1) and Color3.fromRGB(60, 60, 100) or Color3.fromRGB(35, 35, 50)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 16
    btn.BorderSizePixel = 0
    btn.Parent = tabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -20, 1, -80)
    content.Position = UDim2.new(0, 10, 0, 100)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 4
    content.Visible = (i == 1)
    content.Parent = mainFrame
    Instance.new("UIListLayout", content).Padding = UDim.new(0, 10)

    tabContents[name] = content

    btn.MouseButton1Click:Connect(function()
        for _, frame in pairs(tabContents) do frame.Visible = false end
        content.Visible = true
        for _, b in pairs(tabBar:GetChildren()) do
            if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(35, 35, 50) end
        end
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    end)
end

-- Draggable GUI
local dragging, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Toggle GUI with Right Ctrl
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightControl then
        guivisible = not guivisible
        mainFrame.Visible = guivisible
    end
end)

-- Bind phím logic
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if bindingFeature then
        if input.KeyCode \~= Enum.KeyCode.Unknown then
            keys[bindingFeature] = input.KeyCode
            bindingFeature = nil
        end
        return
    end

    if input.KeyCode == keys.Fly and states.Fly then toggleFly(not states.Fly); states.Fly = not states.Fly end
    if input.KeyCode == keys.Noclip and states.Noclip then toggleNoclip(not states.Noclip); states.Noclip = not states.Noclip end
    if input.KeyCode == keys.Aimbot and states.Aimbot then aiming = not aiming end
    if input.KeyCode == keys.KillAura and states.KillAura then toggleKillAura(not states.KillAura); states.KillAura = not states.KillAura end
    if input.KeyCode == keys.Speed and states.Speed then toggleSpeed(not states.Speed); states.Speed = not states.Speed end
    if input.KeyCode == keys.Illusion and states.Illusion then toggleIllusion(not states.Illusion); states.Illusion = not states.Illusion end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == keys.Aimbot then aiming = false; lockHighlight.Visible = false end
end)

-- Lệnh chat
local prefix = "."
local chatCommands = {
    fly = function() states.Fly = not states.Fly; toggleFly(states.Fly); notify("Fly", states.Fly and "ON" or "OFF", 2) end,
    noclip = function() states.Noclip = not states.Noclip; toggleNoclip(states.Noclip); notify("Noclip", states.Noclip and "ON" or "OFF", 2) end,
    esp = function() states.ESP = not states.ESP; notify("ESP", states.ESP and "ON" or "OFF", 2) end,
    aimbot = function() states.Aimbot = not states.Aimbot; fovCircle.Visible = states.Aimbot; notify("Aimbot", states.Aimbot and "ON" or "OFF", 2) end,
    killaura = function() states.KillAura = not states.KillAura; toggleKillAura(states.KillAura); notify("KillAura", states.KillAura and "ON" or "OFF", 2) end,
    speed = function() states.Speed = not states.Speed; toggleSpeed(states.Speed); notify("Speed", states.Speed and "ON" or "OFF", 2) end,
    illusion = function() states.Illusion = not states.Illusion; toggleIllusion(states.Illusion); notify("Illusion", states.Illusion and "ON" or "OFF", 2) end,
    help = function() notify("Commands", ".fly .noclip .esp .aimbot .killaura .speed .illusion .help", 5) end
}

player.Chatted:Connect(function(msg)
    if msg:sub(1,1) == prefix then
        local cmd = msg:sub(2):lower()
        if chatCommands[cmd] then chatCommands[cmd]() end
    end
end)

print("WangScript v2.4 FULL loaded! Right Ctrl mở GUI.")
