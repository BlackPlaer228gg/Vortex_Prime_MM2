--[[
    ====================================================================
    ⚡ VORTEX PRIME MM2 • FULL LEGACY EDITION (XENO & SOLARA COMPATIBLE)
    GitHub: https://github.com/Plaer228gg/Vortex_Prime_MM2
    Author: Plaer228gg
    Engine: 100% Level 3 / Low-UNC Compatible (Xeno 40% sUNC, Solara, Celery)
    Features: Full AutoFarm, Murderer Avoid, Prone Mode, Safe Underground,
              Auto-Reconnect, Auto-Inject (QOT), Auto-Pass (600 Candies),
              Stretched Res, Combat & Visuals.
    ====================================================================
--]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Safe Container Resolver for Low-UNC Executors
local function getSafeContainer()
    local container = nil
    pcall(function()
        if gethui then container = gethui() end
    end)
    if not container then
        pcall(function() container = game:GetService("CoreGui") end)
    end
    if not container or not pcall(function() local t = Instance.new("Folder", container); t:Destroy() end) then
        container = LocalPlayer:WaitForChild("PlayerGui", 5)
    end
    return container
end

local Container = getSafeContainer()

-- Cleanup previous instance
if _G.Vortex_Legacy_Cleanup then
    pcall(_G.Vortex_Legacy_Cleanup)
end

-- ====================================================================
-- CONFIGURATION
-- ====================================================================
local Config = {
    -- Auto Farm (Full Suite)
    CoinAutoFarm = false,
    CoinFarmMethod = "Tween", -- "Tween", "Teleport"
    CoinTweenSpeed = 26,
    CoinAura = true,
    CoinAuraRadius = 7.0,
    CoinFarmYOffset = -2.5,
    CoinFarmProne = true,
    CoinFarmUnderground = true,
    CoinFarmAvoidMurderer = true,
    CoinUndergroundPlatform = true,
    CoinLobbyHide = true,
    CoinPostAction = "KillAll_Or_Shoot", -- "KillAll_Or_Shoot", "Afk", "Reset"
    MaxCoins = 40,
    CoinAntiVoid = true,
    AutoGrabGun = true,

    -- Auto Reconnect & Auto Inject
    AutoReconnect = true,
    AutoReconnectDelay = 3.0,
    AutoQueueOnTeleport = true,
    AutoHopBrokenServer = true,
    BrokenServerTimeout = 65,
    MinServerPlayers = 3,

    -- Battle Pass & Events
    AutoClaimPass = true,
    AutoBuyPassTiers = false,

    -- Combat
    AutoShoot = false,
    SilentAim = false,
    FlingMurderer = false,

    -- Visuals & ESP
    ESPEnabled = true,
    ESPShowMurderer = true,
    ESPShowSheriff = true,
    ESPShowInnocent = true,
    ESPShowGun = true,
    ESPShowNames = true,
    ESPShowDistance = true,

    -- Stretched Res & Camera
    StretchedRes = false,
    StretchPreset = "4:3 (CS:GO Wide)",
    StretchFactor = 0.75,
    StretchBlackBars = false,
    CameraFOV = 70,
    FPSBooster = false,

    -- Movement
    SpeedHack = false,
    WalkSpeed = 24,
    InfiniteJump = false,
    Noclip = false,
    AntiAFK = true,
}

local Roles = {
    Murderer = nil,
    Sheriff = nil,
    Hero = nil,
}

local CurrentFarmStatus = "Ожидание запуска..."
local TotalCoinsCollectedRound = 0
local TotalCoinsSession = 0
local activeCoinTween = nil
local UndergroundPlatform = nil
local isFlingRunning = false

-- Notification helper
local function notify(title, text, duration)
    duration = duration or 3
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration,
        })
    end)
end

-- ====================================================================
-- AUTO-INJECT (QUEUE ON TELEPORT) & AUTO-RECONNECT
-- ====================================================================
local function setupAutoQueue()
    if not Config.AutoQueueOnTeleport then return end
    local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if qot then
        pcall(function()
            qot('loadstring(game:HttpGet("https://raw.githubusercontent.com/Plaer228gg/Vortex_Prime_MM2/main/Loader.lua"))()')
        end)
    end
end

-- Setup queue on initial load
setupAutoQueue()

local function reconnectToServer()
    setupAutoQueue()
    notify("🔄 RECONNECT", "Перезаход на сервер через 3 сек...", 4)
    task.wait(Config.AutoReconnectDelay or 3.0)
    pcall(function()
        if #Players:GetPlayers() <= 1 then
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end)
    task.wait(4.0)
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- Listen for disconnects
pcall(function()
    GuiService.ErrorMessageChanged:Connect(function(msg)
        if Config.AutoReconnect and msg and #msg > 0 then
            task.spawn(reconnectToServer)
        end
    end)
end)

pcall(function()
    local coreGui = game:GetService("CoreGui")
    local promptOverlay = coreGui:WaitForChild("RobloxPromptGui", 5) and coreGui.RobloxPromptGui:WaitForChild("promptOverlay", 5)
    if promptOverlay then
        promptOverlay.ChildAdded:Connect(function(child)
            if Config.AutoReconnect and child.Name == "ErrorPrompt" then
                task.spawn(reconnectToServer)
            end
        end)
    end
end)

-- Server Hop helper
local function serverHop(lowPlayers)
    setupAutoQueue()
    notify("🚀 SERVER HOP", "Поиск подходящего сервера...", 3)
    task.spawn(function()
        local placeId = game.PlaceId
        local curJob = game.JobId
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", placeId)
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if ok and body then
            local data = nil
            pcall(function() data = HttpService:JSONDecode(body) end)
            if data and data.data then
                local candidates = {}
                for _, s in ipairs(data.data) do
                    if s.id ~= curJob and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
                        if not lowPlayers or (s.playing >= (Config.MinServerPlayers or 3) and s.playing <= 8) then
                            table.insert(candidates, s.id)
                        end
                    end
                end
                if #candidates > 0 then
                    local targetServer = candidates[math.random(1, #candidates)]
                    notify("🚀 SERVER HOP", "Переход на сервер: " .. targetServer:sub(1, 8), 3)
                    task.wait(0.5)
                    TeleportService:TeleportToPlaceInstance(placeId, targetServer, LocalPlayer)
                    return
                end
            end
        end
        notify("🚀 SERVER HOP", "Сервер через API не найден, обычный переход...", 2)
        TeleportService:Teleport(placeId, LocalPlayer)
    end)
end

_G.Vortex_Legacy_ServerHop = serverHop
_G.Vortex_Legacy_Reconnect = reconnectToServer

-- Broken / Frozen Server Watchdog
task.spawn(function()
    local lobbyWaitStart = os.clock()
    while _G.Vortex_Legacy_Running do
        task.wait(3)
        if Config.AutoHopBrokenServer ~= false then
            local roundActive = isRoundActive and isRoundActive()
            local inLobby = isPlayerInLobby and isPlayerInLobby(LocalPlayer)
            if roundActive and not inLobby then
                lobbyWaitStart = os.clock()
            else
                local waited = os.clock() - lobbyWaitStart
                local timeout = tonumber(Config.BrokenServerTimeout) or 65
                if waited >= timeout then
                    notify("⚠️ ЗАВИСШИЙ СЕРВЕР!", "Катка не начинается " .. math.floor(waited) .. "с. Ищем новый сервер...", 4)
                    task.wait(2)
                    serverHop(false)
                    lobbyWaitStart = os.clock()
                end
            end
        end
    end
end)

-- ====================================================================
-- GAME STATE & ROLE SCANNER
-- ====================================================================
local function getLocalRoot()
    local char = LocalPlayer.Character
    return char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
end

local function getLocalHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getPlayerRole(player)
    if not player then return "Innocent" end
    local char = player.Character
    local bp = player:FindFirstChild("Backpack")
    local function hasItem(itemName)
        if char and char:FindFirstChild(itemName) then return true end
        if bp and bp:FindFirstChild(itemName) then return true end
        return false
    end
    if hasItem("Knife") then return "Murderer" end
    if hasItem("Gun") then return "Sheriff" end
    return "Innocent"
end

local function updateRoles()
    Roles.Murderer = nil
    Roles.Sheriff = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local role = getPlayerRole(p)
            if role == "Murderer" then
                Roles.Murderer = p
            elseif role == "Sheriff" then
                Roles.Sheriff = p
            end
        end
    end
end

local function isRoundActive()
    local rtp = workspace:FindFirstChild("RoundTimerPart")
    local rtpTime = rtp and rtp:GetAttribute("Time")
    if rtpTime and type(rtpTime) == "number" and rtpTime > 0 then
        return true
    end
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local mainGui = pGui and pGui:FindFirstChild("MainGUI")
    local gameTimer = mainGui and mainGui:FindFirstChild("GameTimer", true)
    if gameTimer and gameTimer:IsA("TextLabel") and gameTimer.Visible and gameTimer.Text:find("%d+:%d+") then
        return true
    end
    -- Normal map exists
    if workspace:FindFirstChild("Normal") then
        return true
    end
    return false
end

local function isPlayerInLobby(plr)
    if not plr then return true end
    local char = plr.Character
    if not char then return true end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return true end
    if not isRoundActive() then return true end
    return root.Position.Z < 2500
end

local function isMurdererDead()
    if not Roles.Murderer then return false end
    local char = Roles.Murderer.Character
    if not char then return true end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return true end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root or not root.Parent then return true end
    if isRoundActive() and root.Position.Z < 2500 then return true end
    return false
end

local function isCoinBagFull()
    if isPlayerInLobby(LocalPlayer) or not isRoundActive() then
        return false
    end
    -- 1. Check MM2 Coin GUI
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    local mg = pg and (pg:FindFirstChild("MainGUI") or pg:FindFirstChild("GameGUI"))
    local cb = mg and mg:FindFirstChild("CoinBags", true)
    local container = cb and (cb:FindFirstChild("Container") or cb)
    if container then
        for _, bag in ipairs(container:GetChildren()) do
            if bag:IsA("Frame") and bag.Visible then
                local fullLbl = bag:FindFirstChild("Full", true)
                local fullIcon = bag:FindFirstChild("FullBagIcon", true)
                if (fullLbl and fullLbl.Visible == true) or (fullIcon and fullIcon.Visible == true) then
                    return true
                end
                local coinsLbl = bag:FindFirstChild("Coins", true) or bag:FindFirstChild("Coin", true)
                if coinsLbl and coinsLbl:IsA("TextLabel") then
                    local count = tonumber(coinsLbl.Text:match("%d+"))
                    if count and count >= (Config.MaxCoins or 40) then
                        return true
                    end
                end
            end
        end
    end
    -- 2. Check internal counter
    if TotalCoinsCollectedRound >= (Config.MaxCoins or 40) then
        return true
    end
    return false
end

-- ====================================================================
-- UNDERGROUND PLATFORM & SAFE LOBBY HIDE
-- ====================================================================
local function getOrCreateUndergroundPlatform(basePos)
    local part = UndergroundPlatform or workspace:FindFirstChild("MM2_UndergroundPlatform")
    if not part or not part.Parent then
        part = Instance.new("Part")
        part.Name = "MM2_UndergroundPlatform"
        part.Size = Vector3.new(40, 3, 40)
        part.Anchored = true
        part.CanCollide = true
        part.Transparency = 0.5
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(45, 140, 255)
        part.Parent = workspace
    end
    if basePos then
        part.CFrame = CFrame.new(basePos.X, -35, basePos.Z)
    end
    UndergroundPlatform = part
    return part
end

local function getObjectPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local bp = obj:FindFirstChildWhichIsA("BasePart", true)
        if bp then return bp.Position end
        return obj:GetPivot().Position
    end
    return nil
end

local function hideSafelyUnderground(statusText)
    local root = getLocalRoot()
    if not root then return end
    CurrentFarmStatus = statusText or "Скрыт под землёй 🛡️"
    local basePos = root.Position
    local curMap = workspace:FindFirstChild("Normal")
    if curMap then
        local sp = curMap:FindFirstChild("Spawns") or curMap:FindFirstChildWhichIsA("BasePart", true)
        local pos = getObjectPos(sp)
        if pos then basePos = pos end
    end
    local plat = getOrCreateUndergroundPlatform(basePos)
    root.CFrame = plat.CFrame + Vector3.new(0, 4.5, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end

local function hideUnderLobby()
    local root = getLocalRoot()
    if not root then return end
    CurrentFarmStatus = "Скрыт под лобби 🛡️"
    local lobby = workspace:FindFirstChild("Lobby")
    if lobby then
        local sp = lobby:FindFirstChild("Spawns") or lobby:FindFirstChildWhichIsA("BasePart", true)
        local pos = getObjectPos(sp)
        if pos then
            root.CFrame = CFrame.new(pos.X, pos.Y - 14, pos.Z)
            root.AssemblyLinearVelocity = Vector3.zero
            return
        end
    end
    root.CFrame = CFrame.new(root.Position.X, -20, root.Position.Z)
    root.AssemblyLinearVelocity = Vector3.zero
end

-- ====================================================================
-- FULL AUTO-FARM ENGINE
-- ====================================================================
local function getActiveCoins()
    local coins = {}
    local normal = workspace:FindFirstChild("Normal")
    local container = normal and normal:FindFirstChild("CoinContainer")
    if not container then
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc.Name == "CoinContainer" or desc.Name == "CoinArea" then
                container = desc
                break
            end
        end
    end
    if container then
        for _, c in ipairs(container:GetChildren()) do
            if c:IsA("BasePart") and c.Transparency < 0.9 then
                table.insert(coins, c)
            end
        end
    end
    return coins
end

local function executePostLimitAction()
    CurrentFarmStatus = "Лимит монет достигнут! 💰"
    local act = Config.CoinPostAction or "KillAll_Or_Shoot"
    if act == "KillAll_Or_Shoot" then
        if _G.Vortex_Legacy_Fling and Roles.Murderer then
            _G.Vortex_Legacy_Fling()
        end
        hideUnderLobby()
    elseif act == "Afk" then
        if Config.CoinUndergroundPlatform then
            hideSafelyUnderground("Лимит монет • В укрытии 🛡️")
        else
            hideUnderLobby()
        end
    elseif act == "Reset" then
        local hum = getLocalHumanoid()
        if hum then hum.Health = 0 end
    end
end

-- Main Auto Farm Loop
task.spawn(function()
    while _G.Vortex_Legacy_Running do
        task.wait(0.08)
        if Config.CoinAutoFarm then
            local root = getLocalRoot()
            local hum = getLocalHumanoid()

            if root and hum and hum.Health > 0 then
                -- 1. Check Round Active
                if not isRoundActive() then
                    CurrentFarmStatus = "Раунд не начат • В лобби ⏳"
                    if Config.CoinLobbyHide then hideUnderLobby() end
                    TotalCoinsCollectedRound = 0
                    task.wait(1.5)
                -- 2. Check Local Player in Lobby
                elseif isPlayerInLobby(LocalPlayer) then
                    CurrentFarmStatus = "В лобби • Ожидание телепорта ⏳"
                    task.wait(1.0)
                -- 3. Check Murderer Dead
                elseif isMurdererDead() then
                    CurrentFarmStatus = "Мардер убит • В укрытие 🛡️"
                    if Config.CoinUndergroundPlatform then
                        hideSafelyUnderground("Мардер убит • В укрытие 🛡️")
                    else
                        hideUnderLobby()
                    end
                    task.wait(1.5)
                -- 4. Check Bag Full
                elseif isCoinBagFull() then
                    executePostLimitAction()
                    task.wait(2.0)
                else
                    -- 5. Find Best Coin (Avoiding Murderer)
                    local coins = getActiveCoins()
                    local nearestCoin = nil
                    local nearestDist = math.huge
                    local myPos = root.Position

                    for _, coin in ipairs(coins) do
                        local cPos = coin.Position
                        local dangerous = false

                        -- Avoid Murderer Check
                        if Config.CoinFarmAvoidMurderer and Roles.Murderer and Roles.Murderer.Character then
                            local mRoot = Roles.Murderer.Character:FindFirstChild("HumanoidRootPart")
                            if mRoot and not isPlayerInLobby(Roles.Murderer) then
                                local distM = (Vector2.new(cPos.X, cPos.Z) - Vector2.new(mRoot.Position.X, mRoot.Position.Z)).Magnitude
                                if distM < 22 then dangerous = true end
                            end
                        end

                        if not dangerous then
                            local dist = (cPos - myPos).Magnitude
                            if dist < nearestDist then
                                nearestDist = dist
                                nearestCoin = coin
                            end
                        end
                    end

                    if not nearestCoin then
                        CurrentFarmStatus = "Ожидание спавна монет ⏳"
                        if Config.CoinUndergroundPlatform then
                            hideSafelyUnderground("Ожидание спавна монет ⏳")
                        end
                        task.wait(0.3)
                    else
                        CurrentFarmStatus = "Полёт к монете 🚀"
                        local cPos = nearestCoin.Position
                        local yOff = Config.CoinFarmUnderground and (Config.CoinFarmYOffset or -2.5) or 0
                        local targetPos = Vector3.new(cPos.X, cPos.Y + yOff, cPos.Z)

                        local moveDir = (targetPos - root.Position)
                        local dist = moveDir.Magnitude
                        local speed = math.clamp(Config.CoinTweenSpeed or 26, 15, 35)

                        local targetCf = CFrame.new(targetPos)
                        if Config.CoinFarmProne then
                            hum.PlatformStand = true
                            targetCf = targetCf * CFrame.Angles(math.rad(-90), 0, 0)
                        else
                            hum.PlatformStand = false
                        end

                        if Config.CoinFarmMethod == "Teleport" then
                            root.CFrame = targetCf
                            root.AssemblyLinearVelocity = Vector3.zero
                            task.wait(0.08)
                        else
                            local dur = math.max(dist / speed, 0.04)
                            activeCoinTween = TweenService:Create(root, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
                                CFrame = targetCf
                            })
                            activeCoinTween:Play()

                            local startT = tick()
                            local vel = (dist > 0.1) and (moveDir.Unit * speed) or Vector3.zero

                            while activeCoinTween and activeCoinTween.PlaybackState == Enum.PlaybackState.Playing and (tick() - startT < dur + 0.08) do
                                RunService.Heartbeat:Wait()
                                if not Config.CoinAutoFarm or hum.Health <= 0 then
                                    activeCoinTween:Cancel()
                                    break
                                end
                                root.AssemblyLinearVelocity = vel
                                -- Touch check
                                if (targetPos - root.Position).Magnitude <= 3.8 and firetouchinterest then
                                    pcall(function() firetouchinterest(root, nearestCoin, 0) end)
                                end
                            end
                        end

                        TotalCoinsCollectedRound = TotalCoinsCollectedRound + 1
                        TotalCoinsSession = TotalCoinsSession + 1
                    end
                end
            end
        else
            if activeCoinTween then
                activeCoinTween:Cancel()
                activeCoinTween = nil
            end
            task.wait(0.5)
        end
    end
end)

-- Coin Magnet Aura
RunService.Heartbeat:Connect(function()
    if not Config.CoinAutoFarm or not Config.CoinAura then return end
    local root = getLocalRoot()
    if not root then return end
    local auraRad = Config.CoinAuraRadius or 7.0

    for _, c in ipairs(getActiveCoins()) do
        if (c.Position - root.Position).Magnitude <= auraRad then
            c.CFrame = root.CFrame
        end
    end
end)

-- Anti-Void Safety Loop
RunService.Heartbeat:Connect(function()
    if not Config.CoinAntiVoid then return end
    local root = getLocalRoot()
    if not root then return end
    if root.Position.Y < -55 then
        if isRoundActive() and not isPlayerInLobby(LocalPlayer) then
            hideSafelyUnderground("Спасение из войда 🛡️")
        else
            hideUnderLobby()
        end
    end
end)

-- Auto Grab Dropped Gun
task.spawn(function()
    while _G.Vortex_Legacy_Running do
        task.wait(0.4)
        if Config.AutoGrabGun then
            local gun = workspace:FindFirstChild("GunDrop")
            local root = getLocalRoot()
            if gun and root and isRoundActive() then
                local oldCf = root.CFrame
                root.CFrame = gun.CFrame
                task.wait(0.1)
                root.CFrame = oldCf
            end
        end
    end
end)

-- ====================================================================
-- COMBAT (AUTO SHOOT & FLING MURDERER)
-- ====================================================================
local function getMurdererChar()
    if Roles.Murderer and Roles.Murderer.Character then
        local hum = Roles.Murderer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then return Roles.Murderer.Character end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and getPlayerRole(p) == "Murderer" then
            return p.Character
        end
    end
    return nil
end

task.spawn(function()
    while _G.Vortex_Legacy_Running do
        task.wait(0.15)
        if Config.AutoShoot then
            local char = LocalPlayer.Character
            local gun = char and char:FindFirstChild("Gun")
            if not gun then
                local bp = LocalPlayer:FindFirstChild("Backpack")
                gun = bp and bp:FindFirstChild("Gun")
                if gun and char:FindFirstChildOfClass("Humanoid") then
                    char.Humanoid:EquipTool(gun)
                    task.wait(0.1)
                end
            end
            if gun then
                local mChar = getMurdererChar()
                local mRoot = mChar and mChar:FindFirstChild("HumanoidRootPart")
                local root = getLocalRoot()
                if mRoot and root then
                    local dir = (mRoot.Position - root.Position).Unit
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, mRoot.Position)
                    pcall(function()
                        local shootRemote = gun:FindFirstChild("Shoot") or gun:FindFirstChildWhichIsA("RemoteEvent")
                        if shootRemote then
                            shootRemote:FireServer(dir, mRoot.Position)
                        else
                            gun:Activate()
                        end
                    end)
                    task.wait(0.4)
                end
            end
        end
    end
end)

_G.Vortex_Legacy_Fling = function()
    if isFlingRunning then return end
    isFlingRunning = true
    task.spawn(function()
        local mChar = getMurdererChar()
        local mRoot = mChar and mChar:FindFirstChild("HumanoidRootPart")
        local root = getLocalRoot()
        if not mRoot or not root then
            notify("⚔️ FLING", "Мардер не найден или мёртв!", 2)
            isFlingRunning = false
            return
        end
        notify("⚔️ FLING", "Атака флингом на Мардера!", 2.5)
        local startCf = root.CFrame
        local startT = tick()
        local bv = Instance.new("BodyAngularVelocity")
        bv.MaxTorque = Vector3.new(1e8, 1e8, 1e8)
        bv.AngularVelocity = Vector3.new(0, 99999, 0)
        bv.Parent = root

        while isFlingRunning and (tick() - startT < 4.5) do
            RunService.Heartbeat:Wait()
            if not mRoot or not mRoot.Parent or isMurdererDead() then break end
            root.CFrame = CFrame.new(mRoot.Position) * CFrame.Angles(math.random(), math.random(), math.random())
            root.AssemblyLinearVelocity = Vector3.new(0, 50, 0)
        end

        bv:Destroy()
        root.CFrame = startCf
        root.AssemblyLinearVelocity = Vector3.zero
        isFlingRunning = false
        notify("⚔️ FLING", "Флинг завершён!", 2)
    end)
end

-- ====================================================================
-- BATTLE PASS (AUTO CLAIM & AUTO BUY FOR 600 CANDIES)
-- ====================================================================
local function claimBattlePassRewards()
    pcall(function()
        local rs = ReplicatedStorage
        local events = rs:FindFirstChild("Remotes") and rs.Remotes:FindFirstChild("Events")
        local halloween = events and events:FindFirstChild("Halloween2026Remotes")
        if not halloween then
            for _, ch in ipairs(events:GetChildren()) do
                if ch.Name:find("Remotes") and ch:FindFirstChild("ClaimBattlePassReward") then
                    halloween = ch
                    break
                end
            end
        end
        if not halloween then return end
        local claimRemote = halloween:FindFirstChild("ClaimBattlePassReward")
        local profileData = require(rs.Modules.ProfileData)
        local pData = profileData and (profileData.Halloween2026 or profileData[next(profileData)])
        if not claimRemote or not pData then return end
        local curTier = pData.CurrentTier or 0
        local claimed = pData.ClaimedRewards or {}

        for tier = 1, curTier do
            local tStr = tostring(tier)
            if tier ~= 30 and claimed[tStr] ~= true then
                claimRemote:FireServer(tStr)
                task.wait(0.1)
            end
        end
    end)
end

local function buyBattlePassTier()
    local success = false
    pcall(function()
        local rs = ReplicatedStorage
        local profileData = require(rs.Modules.ProfileData)
        local owned = (profileData.Materials and profileData.Materials.Owned and profileData.Materials.Owned.Candies2026) or 0
        local curTier = (profileData.Halloween2026 and profileData.Halloween2026.CurrentTier) or 0

        if curTier >= 30 then
            notify("🎃 BATTLE PASS", "Пасс уже на максимуме (30/30)!", 2.5)
            return
        end
        if owned < 600 then
            notify("🎃 BATTLE PASS", string.format("Недостаточно конфет! (%d / 600)", owned), 2.5)
            return
        end

        -- Method 1: UI Button Simulation
        local lp = Players.LocalPlayer
        local buyFrame = lp and lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("CrossPlatform")
        local h = buyFrame and buyFrame:FindFirstChild("Halloween2026")
        local main = h and h:FindFirstChild("MainEvent") and h.MainEvent:FindFirstChild("Main")
        local bp = main and main:FindFirstChild("BattlePass")
        local buyTiers = bp and bp:FindFirstChild("BuyTiers")
        local tokenBuy = buyTiers and buyTiers:FindFirstChild("TokenBuy")
        local buyBtn = tokenBuy and tokenBuy:FindFirstChild("Container") and tokenBuy.Container:FindFirstChild("BuyButton")
        local btn = buyBtn and buyBtn:FindFirstChild("Button")

        if btn and getconnections then
            for _, c in ipairs(getconnections(btn.MouseButton1Down)) do c:Fire() end
            task.wait(0.04)
            for _, c in ipairs(getconnections(btn.MouseButton1Up)) do c:Fire() end
            success = true
        else
            -- Method 2: Direct Remote
            local events = rs:FindFirstChild("Remotes") and rs.Remotes:FindFirstChild("Events")
            local halloween = events and events:FindFirstChild("Halloween2026Remotes")
            local buyRemote = halloween and halloween:FindFirstChild("BuyBattlePassTiers")
            if buyRemote then
                buyRemote:FireServer(1)
                success = true
            end
        end

        if success then
            notify("🎃 BATTLE PASS", "Куплен 1 уровень за 600 конфет!", 3.5)
            task.delay(0.6, claimBattlePassRewards)
        end
    end)
    return success
end

_G.Vortex_Legacy_BuyPassTier = buyBattlePassTier
_G.Vortex_Legacy_ClaimPass = claimBattlePassRewards

task.spawn(function()
    while _G.Vortex_Legacy_Running do
        task.wait(7.5)
        if Config.AutoBuyPassTiers then buyBattlePassTier() end
        if Config.AutoClaimPass then claimBattlePassRewards() end
    end
end)

-- ====================================================================
-- STRETCHED RESOLUTION & CAMERA
-- ====================================================================
local blackBarsGui = nil
local leftBar, rightBar = nil, nil

local function getAspectPresetRatio(preset)
    if preset:find("4:3") then return 4 / 3 end
    if preset:find("5:4") then return 5 / 4 end
    if preset:find("16:10") then return 16 / 10 end
    if preset:find("1:1") then return 1 / 1 end
    return 4 / 3
end

local function setupBlackBars()
    if not blackBarsGui then
        blackBarsGui = Instance.new("ScreenGui")
        blackBarsGui.Name = "Vortex_Legacy_BlackBars"
        blackBarsGui.ResetOnSpawn = false
        blackBarsGui.DisplayOrder = 5
        blackBarsGui.IgnoreGuiInset = true
        blackBarsGui.Parent = Container

        leftBar = Instance.new("Frame")
        leftBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        leftBar.BorderSizePixel = 0
        leftBar.Parent = blackBarsGui

        rightBar = Instance.new("Frame")
        rightBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        rightBar.BorderSizePixel = 0
        rightBar.Parent = blackBarsGui
    end
end

RunService.RenderStepped:Connect(function()
    if Config.StretchedRes and Camera then
        local vp = Camera.ViewportSize
        if vp.X > 0 and vp.Y > 0 then
            local nativeAspect = vp.X / vp.Y
            local preset = Config.StretchPreset or "4:3 (CS:GO Wide)"
            local targetAspect = getAspectPresetRatio(preset)
            local factor = targetAspect / nativeAspect

            if preset:find("Custom") then
                factor = Config.StretchFactor or 0.75
            end

            if Config.StretchBlackBars then
                setupBlackBars()
                blackBarsGui.Enabled = true
                local targetW = vp.Y * targetAspect
                local barW = math.floor((vp.X - targetW) / 2)
                if barW > 0 then
                    leftBar.Visible = true
                    leftBar.Position = UDim2.new(0, 0, 0, 0)
                    leftBar.Size = UDim2.new(0, barW, 1, 0)

                    rightBar.Visible = true
                    rightBar.Position = UDim2.new(1, -barW, 0, 0)
                    rightBar.Size = UDim2.new(0, barW, 1, 0)
                end
            else
                if blackBarsGui then blackBarsGui.Enabled = false end
                Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, factor, 0, 0, 0, 1)
            end
        end
    else
        if blackBarsGui then blackBarsGui.Enabled = false end
    end
end)

-- ====================================================================
-- ESP SYSTEM (HIGHLIGHTS & BILLBOARDS)
-- ====================================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "Vortex_Legacy_ESP"
ESPFolder.Parent = Container

local function clearESP(char)
    if not char then return end
    local h = char:FindFirstChild("Vortex_HL")
    if h then h:Destroy() end
    local bb = char:FindFirstChild("Vortex_BB")
    if bb then bb:Destroy() end
end

local function applyPlayerESP(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not head or not root then return end

    if not Config.ESPEnabled then
        clearESP(char)
        return
    end

    local role = getPlayerRole(player)
    local col = Color3.fromRGB(80, 255, 120)
    if role == "Murderer" then
        col = Color3.fromRGB(255, 50, 70)
        if not Config.ESPShowMurderer then clearESP(char); return end
    elseif role == "Sheriff" then
        col = Color3.fromRGB(60, 160, 255)
        if not Config.ESPShowSheriff then clearESP(char); return end
    else
        if not Config.ESPShowInnocent then clearESP(char); return end
    end

    local hl = char:FindFirstChild("Vortex_HL")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "Vortex_HL"
        hl.FillTransparency = 0.55
        hl.OutlineTransparency = 0.1
        hl.Parent = char
    end
    hl.FillColor = col
    hl.OutlineColor = col

    if Config.ESPShowNames or Config.ESPShowDistance then
        local bb = head:FindFirstChild("Vortex_BB")
        if not bb then
            bb = Instance.new("BillboardGui")
            bb.Name = "Vortex_BB"
            bb.Size = UDim2.new(0, 140, 0, 36)
            bb.StudsOffset = Vector3.new(0, 2.2, 0)
            bb.AlwaysOnTop = true
            bb.Parent = head

            local txt = Instance.new("TextLabel")
            txt.Name = "Label"
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.Font = Enum.Font.GothamBold
            txt.TextSize = 11
            txt.TextColor3 = col
            txt.TextStrokeTransparency = 0.2
            txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            txt.Parent = bb
        end
        local myRoot = getLocalRoot()
        local dist = (myRoot and Config.ESPShowDistance) and string.format(" [%d m]", math.floor((root.Position - myRoot.Position).Magnitude)) or ""
        local label = bb:FindFirstChild("Label")
        if label then
            label.TextColor3 = col
            label.Text = string.format("%s\n(%s)%s", player.DisplayName, role, dist)
        end
    end
end

-- ====================================================================
-- MOVEMENT (SPEED, JUMP, NOCLIP, ANTI-AFK)
-- ====================================================================
RunService.Stepped:Connect(function()
    if Config.SpeedHack and LocalPlayer.Character then
        local hum = getLocalHumanoid()
        if hum then hum.WalkSpeed = Config.WalkSpeed or 24 end
    end
    if Config.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump and LocalPlayer.Character then
        local hum = getLocalHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Anti-AFK
pcall(function()
    local vu = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if Config.AntiAFK then
            vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end
    end)
end)

-- ====================================================================
-- USER INTERFACE
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Vortex_Legacy_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Container

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 380)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -70, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 13
TitleLabel.TextColor3 = Color3.fromRGB(255, 75, 95)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Text = "⚡ VORTEX PRIME • FULL LEGACY (XENO/SOLARA)"
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Sidebar Tabs
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0, 115, 1, -44)
TabBar.Position = UDim2.new(0, 6, 0, 42)
TabBar.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -133, 1, -44)
ContentArea.Position = UDim2.new(0, 127, 0, 42)
ContentArea.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainFrame
Instance.new("UICorner", ContentArea).CornerRadius = UDim.new(0, 8)

local TabPages = {}
local TabButtons = {}

local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, -12, 1, -12)
    page.Position = UDim2.new(0, 6, 0, 6)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.Visible = false
    page.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 14)
    end)

    TabPages[name] = page
    return page
end

local function selectTab(name)
    for tName, page in pairs(TabPages) do page.Visible = (tName == name) end
    for tName, btn in pairs(TabButtons) do
        btn.BackgroundColor3 = (tName == name) and Color3.fromRGB(255, 65, 85) or Color3.fromRGB(28, 34, 46)
    end
end

local function addTabButton(name, icon, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.Position = UDim2.new(0, 5, 0, 6 + (order - 1) * 36)
    btn.BackgroundColor3 = Color3.fromRGB(28, 34, 46)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = Color3.fromRGB(240, 245, 255)
    btn.Text = icon .. " " .. name
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    TabButtons[name] = btn
end

local function addToggle(parent, title, configKey, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 34)
    card.BackgroundColor3 = Color3.fromRGB(28, 34, 46)
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -55, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(230, 240, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = title
    lbl.Parent = card

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 42, 0, 22)
    switch.Position = UDim2.new(1, -48, 0.5, -11)
    switch.BackgroundColor3 = Config[configKey] and Color3.fromRGB(45, 200, 110) or Color3.fromRGB(50, 58, 76)
    switch.Text = Config[configKey] and "ON" or "OFF"
    switch.Font = Enum.Font.GothamBlack
    switch.TextSize = 9
    switch.TextColor3 = Color3.fromRGB(255, 255, 255)
    switch.Parent = card
    Instance.new("UICorner", switch).CornerRadius = UDim.new(0, 5)

    switch.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        switch.BackgroundColor3 = Config[configKey] and Color3.fromRGB(45, 200, 110) or Color3.fromRGB(50, 58, 76)
        switch.Text = Config[configKey] and "ON" or "OFF"
        if callback then callback(Config[configKey]) end
    end)
    return card
end

local function addButton(parent, title, col, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = col or Color3.fromRGB(35, 42, 58)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = title
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function addHeader(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(255, 95, 115)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "• " .. text:upper()
    lbl.Parent = parent
end

-- ====================================================================
-- BUILD TABS
-- ====================================================================
addTabButton("Full Farm", "💰", 1)
addTabButton("Reconnect", "🔄", 2)
addTabButton("Pass", "🎃", 3)
addTabButton("Combat", "🎯", 4)
addTabButton("Visuals", "👁️", 5)
addTabButton("Misc", "⚡", 6)

-- 1. Full Farm Tab
local pFarm = createPage("Full Farm")
addHeader(pFarm, "Основной модуль фарминга")
addToggle(pFarm, "💰 Включить Coin Auto-Farm", "CoinAutoFarm", function(on)
    TotalCoinsCollectedRound = 0
    notify("💰 АВТО-ФАРМ", on and "Фарм запущен! (Smart Mode)" or "Фарм остановлен", 2.5)
end)
addToggle(pFarm, "🧲 Coin Magnet (Аура сбора монет)", "CoinAura")
addToggle(pFarm, "🦹 Avoid Murderer (Обходить мардера)", "CoinFarmAvoidMurderer")
addToggle(pFarm, "🛌 Prone Mode (Снизить хитбокс / лежать)", "CoinFarmProne")
addToggle(pFarm, "⛏️ Underground Y (-2.5 studs под пол)", "CoinFarmUnderground")
addToggle(pFarm, "🏗️ Подземная платформа безопасности", "CoinUndergroundPlatform")
addToggle(pFarm, "🛡️ Прятаться под лобби после сбора", "CoinLobbyHide")
addToggle(pFarm, "🛡️ Anti-Void (Защита от падения в войд)", "CoinAntiVoid")
addToggle(pFarm, "🔫 Авто-подбор пистолета (Auto Grab Gun)", "AutoGrabGun")

local methodBtn
local methods = {"Tween", "Teleport"}
local curMIdx = 1
methodBtn = addButton(pFarm, "🚀 Метод полёта: " .. Config.CoinFarmMethod, Color3.fromRGB(36, 44, 62), function()
    curMIdx = (curMIdx % #methods) + 1
    Config.CoinFarmMethod = methods[curMIdx]
    methodBtn.Text = "🚀 Метод полёта: " .. Config.CoinFarmMethod
end)

local postBtn
local postActions = {"KillAll_Or_Shoot", "Afk", "Reset"}
local curPIdx = 1
postBtn = addButton(pFarm, "🎯 Действие после лимита: " .. Config.CoinPostAction, Color3.fromRGB(36, 44, 62), function()
    curPIdx = (curPIdx % #postActions) + 1
    Config.CoinPostAction = postActions[curPIdx]
    postBtn.Text = "🎯 Действие после лимита: " .. Config.CoinPostAction
end)

addButton(pFarm, "📍 Спрятаться под лобби прямо сейчас", Color3.fromRGB(45, 120, 220), hideUnderLobby)
addButton(pFarm, "📍 Спрятаться на платформу (-35 studs)", Color3.fromRGB(45, 120, 220), function()
    hideSafelyUnderground("Ручной уход в укрытие 🛡️")
end)

-- 2. Reconnect & Server Hop Tab
local pRec = createPage("Reconnect")
addHeader(pRec, "Авто-перезаход и авто-инжект")
addToggle(pRec, "🔄 Auto-Reconnect (Перезаход при кике/вылете)", "AutoReconnect")
addToggle(pRec, "💉 Auto-Queue on Teleport (Авто-инжект)", "AutoQueueOnTeleport", function(on)
    if on then setupAutoQueue() end
end)
addButton(pRec, "🔄 Перезайти на этот сервер (Rejoin)", Color3.fromRGB(50, 75, 110), reconnectToServer)
addButton(pRec, "🚀 Найти случайный сервер (Server Hop)", Color3.fromRGB(45, 140, 255), function() serverHop(false) end)
addButton(pRec, "👥 Найти сервер с малым онлайном (Low Players)", Color3.fromRGB(35, 160, 120), function() serverHop(true) end)

-- 3. Battle Pass Tab
local pPass = createPage("Pass")
addHeader(pPass, "Event & Battle Pass")
addToggle(pPass, "🎁 Auto Claim Pass (Авто-забор наград)", "AutoClaimPass")
addToggle(pPass, "🎃 Auto Buy Pass (Авто-покупка за 600 конфет)", "AutoBuyPassTiers", function(on)
    if on then buyBattlePassTier() end
end)
addButton(pPass, "🛒 Купить 1 уровень Пасса (600 конфет)", Color3.fromRGB(255, 140, 20), function()
    buyBattlePassTier()
end)
addButton(pPass, "🎁 Забрать все открытые награды", Color3.fromRGB(255, 175, 40), function()
    claimBattlePassRewards()
    notify("🎁 PASS", "Запрос на забор наград отправлен!", 3)
end)

-- 4. Combat Tab
local pCombat = createPage("Combat")
addHeader(pCombat, "Combat Suite")
addToggle(pCombat, "🔫 Auto Shoot Murderer (Стрельба в Мардера)", "AutoShoot")
addButton(pCombat, "⚔️ Fling Murderer (Запустить мардера в войд)", Color3.fromRGB(220, 45, 65), function()
    _G.Vortex_Legacy_Fling()
end)

-- 5. Visuals Tab
local pVis = createPage("Visuals")
addHeader(pVis, "Player & Item ESP")
addToggle(pVis, "👁️ Включить ESP (Highlights)", "ESPEnabled")
addToggle(pVis, "🔴 Показывать Murderer (Красный)", "ESPShowMurderer")
addToggle(pVis, "🔵 Показывать Sheriff (Синий)", "ESPShowSheriff")
addToggle(pVis, "🟢 Показывать Innocents (Зелёный)", "ESPShowInnocent")
addToggle(pVis, "🔫 Подсветка выпавшего пистолета", "ESPShowGun")
addToggle(pVis, "🏷️ Теги с никами и дистанцией", "ESPShowNames")

addHeader(pVis, "Растяг экрана (Stretched Res)")
addToggle(pVis, "📐 Включить растяг экрана", "StretchedRes")
local stretchBtn
local sPresets = {"4:3 (CS:GO Wide)", "5:4 (Ultra Wide)", "16:10 (Comfort Wide)", "1:1 (Square Pro)"}
local curSIdx = 1
stretchBtn = addButton(pVis, "🖥️ Пресет: " .. Config.StretchPreset, Color3.fromRGB(40, 50, 70), function()
    curSIdx = (curSIdx % #sPresets) + 1
    Config.StretchPreset = sPresets[curSIdx]
    stretchBtn.Text = "🖥️ Пресет: " .. Config.StretchPreset
    notify("📐 РАСТЯГ", "Выбран: " .. Config.StretchPreset, 2)
end)
addToggle(pVis, "🎬 Чёрные полосы (4:3 Black Bars)", "StretchBlackBars")

addHeader(pVis, "Оптимизация")
addToggle(pVis, "⚡ FPS Booster (Удаление лагов)", "FPSBooster", function(on)
    if on then
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            Lighting.GlobalShadows = false
        end)
    end
end)

-- 6. Misc Tab
local pMisc = createPage("Misc")
addHeader(pMisc, "Movement & Utility")
addToggle(pMisc, "🏃 Speed Hack (24 WalkSpeed)", "SpeedHack")
addToggle(pMisc, "🦘 Infinite Jump (Бесконечный прыжок)", "InfiniteJump")
addToggle(pMisc, "👻 Noclip (Ходить сквозь стены)", "Noclip")
addToggle(pMisc, "🛡️ Anti-AFK (Защита от дисконнекта)", "AntiAFK")
addButton(pMisc, "❌ Полная выгрузка Legacy скрипта", Color3.fromRGB(200, 40, 50), function()
    pcall(_G.Vortex_Legacy_Cleanup)
    notify("⚡ VORTEX", "Скрипт полностью выгружен!", 3)
end)

selectTab("Full Farm")

-- ====================================================================
-- MAIN LOOPS & INITIALIZATION
-- ====================================================================
_G.Vortex_Legacy_Running = true

_G.Vortex_Legacy_Cleanup = function()
    _G.Vortex_Legacy_Running = false
    if activeCoinTween then activeCoinTween:Cancel() end
    if UndergroundPlatform then pcall(function() UndergroundPlatform:Destroy() end) end
    if ESPFolder then ESPFolder:Destroy() end
    if ScreenGui then ScreenGui:Destroy() end
    if blackBarsGui then blackBarsGui:Destroy() end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then clearESP(p.Character) end
    end
end

-- Refresh ESP & Roles loop
task.spawn(function()
    while _G.Vortex_Legacy_Running do
        updateRoles()
        for _, p in ipairs(Players:GetPlayers()) do
            applyPlayerESP(p)
        end
        task.wait(0.6)
    end
end)

notify("⚡ VORTEX PRIME", "Full Legacy Edition успешно запущена! Нажмите RightShift для меню.", 4)
print("[VORTEX PRIME] Full Legacy Edition (Xeno/Solara) successfully loaded!")
