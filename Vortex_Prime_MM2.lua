--[[
    ====================================================================
    🔪 MM2 POTASSIUM HUB - Ultimate Murder Mystery 2 Suite
    Engineered for Potassium MCP Executor:
      • 🛡️ Anti-Stacking Singleton Architecture (_G.MM2_Hub_Running)
      • 🛡️ Clean Anti-Fling: Zero collision with other players (No teleport drops)
      • 🎯 Silent Aim Target ESP & Nametag: 3D Billboard + 2D Lock Reticle in Combat
      • 👁️ Role ESP (Murderer, Sheriff, Hero, Innocents, Gun Drop, Coins)
      • 🪙 Fixed Coins ESP: Auto-detects CoinContainer & active TouchInterest
      • 🎯 Fixed Off-Screen Radar: Un-mirrored 2D math, supports both Murderer & Sheriff targets
      • 🎯 Sheriff Silent Aim & Movement Prediction (Hooks WeaponService)
      • ⭐ Instant / Auto-Grab Dropped Gun (Zero-delay retrieval)
      • 💰 Smart Coin Auto-Farm (Rate-limited, anti-kick protection)
      • 🔪 Murderer Knife Aura & Proximity Hazard Alerts
      • 🏃 Movement Suite: Speed, Infinite Jump, Noclip, Fly, Fullbright
      • 🎨 Glassmorphism Dark GUI with Keybind (RightShift / Insert / F4)
      • 💾 Auto-saving JSON Configuration
    ====================================================================
--]]
-- ====================================================================
-- 🛡️ UNIVERSAL EXECUTOR COMPATIBILITY LAYER (SOLARA & XENO 40% sUNC)
-- ====================================================================
do
    local getgenv = getgenv or function() return _G end
    local genv = getgenv()

    -- 1. Identity & Caller Detection
    if not genv.checkcaller then
        genv.checkcaller = function() return true end
    end
    if not genv.newcclosure then
        genv.newcclosure = function(f) return f end
    end
    if not genv.clonefunction then
        genv.clonefunction = function(f) return f end
    end

    -- 2. GUI Container Resolver (Safe across all Level 2/3 Sandbox environments)
    local function safeGetContainer()
        if genv.gethui then
            local s, h = pcall(genv.gethui)
            if s and h and typeof(h) == "Instance" then
                local testOk = pcall(function() return h.Name end)
                if testOk then return h end
            end
        end
        local s, cg = pcall(function() return game:GetService("CoreGui") end)
        if s and cg then
            local canAccess = pcall(function()
                local testFolder = Instance.new("Folder")
                testFolder.Parent = cg
                testFolder:Destroy()
            end)
            if canAccess then return cg end
        end
        local lp = game:GetService("Players").LocalPlayer
        if not lp then
            pcall(function()
                lp = game:GetService("Players"):GetPropertyChangedSignal("LocalPlayer"):Wait()
            end)
        end
        local pGui = lp and (lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5))
        if pGui then return pGui end
        return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end

    if not genv.gethui then
        genv.gethui = safeGetContainer
    end

    -- 3. Universal Drawing Library Compatibility Shim (for Xeno/Solara missing Drawing.new)
    if not genv.Drawing or typeof(genv.Drawing) ~= "table" or not genv.Drawing.new then
        local drawingContainer = nil
        local function getDrawingContainer()
            if not drawingContainer or not drawingContainer.Parent then
                local parent = safeGetContainer()
                drawingContainer = Instance.new("ScreenGui")
                drawingContainer.Name = "MM2_Universal_Drawing_Overlay"
                drawingContainer.ResetOnSpawn = false
                drawingContainer.DisplayOrder = 9999
                drawingContainer.IgnoreGuiInset = true
                pcall(function() drawingContainer.Parent = parent end)
            end
            return drawingContainer
        end

        local DrawingShim = {}
        DrawingShim.Fonts = { UI = 0, System = 1, Plex = 2, Monospace = 3 }

        function DrawingShim.new(drawType)
            local props = {
                Visible = false,
                Color = Color3.fromRGB(255, 255, 255),
                Transparency = 1,
                Thickness = 1,
                From = Vector2.zero,
                To = Vector2.zero,
                PointA = Vector2.zero,
                PointB = Vector2.zero,
                PointC = Vector2.zero,
                Position = Vector2.zero,
                Text = "",
                Size = 14,
                Center = false,
                Outline = false,
                OutlineColor = Color3.fromRGB(0, 0, 0),
                Filled = false,
                Radius = 10,
                NumSides = 16,
                ZIndex = 1,
            }

            local frame = nil
            pcall(function()
                local c = getDrawingContainer()
                if drawType == "Line" then
                    frame = Instance.new("Frame")
                    frame.AnchorPoint = Vector2.new(0.5, 0.5)
                    frame.BorderSizePixel = 0
                    frame.Parent = c
                elseif drawType == "Text" then
                    frame = Instance.new("TextLabel")
                    frame.BackgroundTransparency = 1
                    frame.Font = Enum.Font.GothamBold
                    frame.Parent = c
                elseif drawType == "Circle" then
                    frame = Instance.new("Frame")
                    frame.AnchorPoint = Vector2.new(0.5, 0.5)
                    frame.BackgroundTransparency = 1
                    local stroke = Instance.new("UIStroke")
                    stroke.Parent = frame
                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(1, 0)
                    corner.Parent = frame
                    frame.Parent = c
                elseif drawType == "Square" or drawType == "Triangle" then
                    frame = Instance.new("Frame")
                    frame.BorderSizePixel = 0
                    frame.Parent = c
                end
            end)

            local obj = {}
            local mt = {
                __index = function(_, k)
                    if k == "Remove" or k == "Destroy" then
                        return function()
                            pcall(function()
                                if frame and frame.Parent then frame:Destroy() end
                            end)
                            frame = nil
                        end
                    end
                    return props[k]
                end,
                __newindex = function(_, k, v)
                    props[k] = v
                    pcall(function()
                        if not frame then return end
                        if k == "Visible" then
                            frame.Visible = v
                        elseif k == "Color" then
                            if frame:IsA("TextLabel") then
                                frame.TextColor3 = v
                            else
                                frame.BackgroundColor3 = v
                                local s = frame:FindFirstChildOfClass("UIStroke")
                                if s then s.Color = v end
                            end
                        elseif k == "Transparency" then
                            local alpha = 1 - math.clamp(v, 0, 1)
                            if frame:IsA("TextLabel") then
                                frame.TextTransparency = alpha
                            else
                                frame.BackgroundTransparency = props.Filled and alpha or 1
                            end
                        elseif k == "From" or k == "To" then
                            if drawType == "Line" and props.From and props.To then
                                local from, to = props.From, props.To
                                local dist = (to - from).Magnitude
                                local center = (from + to) / 2
                                local rot = math.deg(math.atan2(to.Y - from.Y, to.X - from.X))
                                frame.Size = UDim2.new(0, dist, 0, props.Thickness or 1)
                                frame.Position = UDim2.new(0, center.X, 0, center.Y)
                                frame.Rotation = rot
                            end
                        elseif k == "Position" then
                            if drawType == "Text" then
                                frame.Position = UDim2.new(0, v.X, 0, v.Y)
                                if props.Center then frame.AnchorPoint = Vector2.new(0.5, 0) else frame.AnchorPoint = Vector2.new(0, 0) end
                            elseif drawType == "Circle" then
                                frame.Position = UDim2.new(0, v.X, 0, v.Y)
                            end
                        elseif k == "Text" and frame:IsA("TextLabel") then
                            frame.Text = tostring(v)
                        elseif k == "Size" and frame:IsA("TextLabel") then
                            frame.TextSize = tonumber(v) or 14
                        elseif k == "Radius" and drawType == "Circle" then
                            local diam = (tonumber(v) or 10) * 2
                            frame.Size = UDim2.new(0, diam, 0, diam)
                        elseif k == "Thickness" then
                            local s = frame:FindFirstChildOfClass("UIStroke")
                            if s then s.Thickness = tonumber(v) or 1 end
                            if drawType == "Line" then
                                frame.Size = UDim2.new(0, frame.Size.X.Offset, 0, tonumber(v) or 1)
                            end
                        end
                    end)
                end
            }
            return setmetatable(obj, mt)
        end

        genv.Drawing = DrawingShim
    end

    -- 4. Simulated firetouchinterest (for Solara/Xeno touch trigger)
    if not genv.firetouchinterest or typeof(genv.firetouchinterest) ~= "function" then
        genv.firetouchinterest = function(part1, part2, toggle)
            if not part1 or not part2 then return end
            pcall(function()
                if toggle == 0 then
                    local tt = part2:FindFirstChildOfClass("TouchTransmitter") or part1:FindFirstChildOfClass("TouchTransmitter")
                    if genv.firesignal and tt then
                        genv.firesignal(part2.Touched, part1)
                        genv.firesignal(part1.Touched, part2)
                    end
                end
            end)
        end
    end

    -- 5. Universal getconnections fallback
    if not genv.getconnections or typeof(genv.getconnections) ~= "function" then
        genv.getconnections = function(signal)
            return {}
        end
    end

    -- 6. Universal firesignal fallback
    if not genv.firesignal or typeof(genv.firesignal) ~= "function" then
        genv.firesignal = function(signal, ...)
            local conns = genv.getconnections and genv.getconnections(signal)
            if conns then
                for _, conn in ipairs(conns) do
                    if conn and conn.Fire then
                        pcall(conn.Fire, conn, ...)
                    end
                end
            end
        end
    end

    -- 7. Universal sethiddenproperty & gethiddenproperty fallback
    if not genv.sethiddenproperty then
        genv.sethiddenproperty = function(inst, prop, val)
            pcall(function() inst[prop] = val end)
        end
    end
    if not genv.gethiddenproperty then
        genv.gethiddenproperty = function(inst, prop)
            local ok, val = pcall(function() return inst[prop] end)
            return ok and val or nil
        end
    end

    -- 8. Universal queue_on_teleport fallback
    if not genv.queue_on_teleport then
        genv.queue_on_teleport = (genv.syn and genv.syn.queue_on_teleport)
            or (genv.queueonteleport)
            or (genv.fluxus and genv.fluxus.queue_on_teleport)
            or function() end
    end

    -- 9. Universal Request Function (request / http_request / syn.request)
    if not genv.request then
        genv.request = genv.http_request
            or (genv.syn and genv.syn.request)
            or (genv.fluxus and genv.fluxus.request)
            or function(options) return { StatusCode = 400, Body = "" } end
    end

    -- 10. File System Fallback (InMemory for executors without writefile/readfile)
    if not genv.writefile or not genv.readfile or not genv.isfile then
        local inMemoryFS = {}
        if not genv.writefile then
            genv.writefile = function(path, content)
                inMemoryFS[path] = tostring(content)
            end
        end
        if not genv.readfile then
            genv.readfile = function(path)
                local data = inMemoryFS[path]
                if not data then error("File not found: " .. tostring(path)) end
                return data
            end
        end
        if not genv.isfile then
            genv.isfile = function(path)
                return inMemoryFS[path] ~= nil
            end
        end
        if not genv.isfolder then
            genv.isfolder = function() return true end
        end
        if not genv.makefolder then
            genv.makefolder = function() end
        end
    end
end

-- 0. HARD ANTI-DOUBLE EXECUTION GUARD
if _G.MM2_Hub_Initializing then
    return
end
_G.MM2_Hub_Initializing = true

-- 1. HARD SINGLETON: Clean up existing instance before re-injecting
if _G.MM2_Hub_Running and _G.MM2_Hub_Cleanup then
    pcall(function() _G.MM2_Hub_Cleanup() end)
    task.wait(0.05)
end
-- Global Highlight Sweep: Delete all legacy / orphaned highlights to prevent green screen
for _, h in ipairs(game:GetDescendants()) do
    if h:IsA("Highlight") and (string.find(h.Name, "MM2_HL_") or string.find(h.Name, "MM2_KnifeHover") or h.Adornee == nil) then
        pcall(function() h:Destroy() end)
    end
end
local InstanceID = tostring(os.clock()) .. "_" .. tostring(math.random(10000, 99999))
_G.MM2_Hub_Running = true
_G.MM2_Hub_InstanceID = InstanceID

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for game & character load
do
    if not game:IsLoaded() then
        pcall(function() game.Loaded:Wait() end)
    end
    if not Players.LocalPlayer then
        local r = 0
        while not Players.LocalPlayer and r < 50 do
            task.wait(0.2)
            r = r + 1
        end
    end
    local p = Players.LocalPlayer
    if p then
        local c = p.Character or p.CharacterAdded:Wait()
        if c then
            pcall(function()
                c:WaitForChild("HumanoidRootPart", 15)
                c:WaitForChild("Humanoid", 15)
            end)
        end
    end
end

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local showNotification = nil
local flashDynamicIslandAlert = nil
local toggleMenu = nil

local CONFIG_FILE = "Vortex_Prime_Config.json"
local LEGACY_CONFIG_FILE = "MM2_Potassium_Config.json"

-- Default Configuration Table (All Automation & Combat OFF by default for new users)
local Config = {
    -- Visuals (Active by default for instant ESP on inject)
    MurdererESP = true,
    SheriffESP = true,
    HeroESP = true,
    InnocentESP = true,
    LobbyESP = true,
    GunDropESP = true,
    CoinESP = true,
    TrapESP = true,
    ZombieESP = true,
    SurvivorESP = true,
    Tracers = false,
    TracerOrigin = "Bottom",
    OffscreenRadar = false,
    -- Nametags Settings
    ESPShowAvatar = true,
    ESPShowNames = true,
    ESPShowRole = true,
    ESPShowWeapon = true,
    ESPShowPing = true,
    ESPShowDistance = true,
    ESPTextSize = 10,
    -- World Visuals & Performance
    JumpCircles = true,
    MotionTrail = false,
    SelfAuraGlow = false,
    BulletTracers = true,
    BulletTracerColor = "Electric Cyan",
    BulletTracerThickness = 0.3,
    BulletTracerThicknessInt = 3,
    BulletTracerLifetime = 1,
    BulletImpactRings = true,
    KnifeThrowTracers = true,
    -- 24 New Visuals Suite
    CustomCrosshair = false,
    CrosshairStyle = "Classic Cross",
    CrosshairColor = "Electric Cyan",
    CrosshairSize = 12,
    GlowBloom = false,
    ColorCorrectionPreset = "None",
    DepthOfField = false,
    SunRaysFX = false,
    DamageVignette = false,
    CustomSkybox = "Default",
    FootstepRipples = false,
    LandingShockwave = true,
    HaloAura = false,
    FeetTrails = false,
    ChromaSkin = false,
    BackWingsVisual = false,
    LaserEyes = false,
    HitmarkerScreenPulse = false,
    WeaponChromaFlame = false,
    DeathSoulEffect = true,
    CoinCollectPulse = true,
    BigWeaponVisual = false,
    ShoulderCamera = false,
    DynamicSprintFOV = false,
    CameraFOV = 70,
    -- Stretched Resolution & Aspect Ratio Suite
    StretchedRes = false,
    StretchPreset = "4:3 (CS:GO Wide)",
    StretchAutoAspect = true,
    StretchFactorPercent = 75,
    StretchFactor = 0.75,
    StretchModelWidthPercent = 100,
    StretchModelWidth = 1.0,
    StretchBlackBars = false,
    NoFog = false,
    WorldAmbiencePreset = "Default",
    FPSBooster = false,
    -- Notifications & Alerts
    EventNotifications = true,
    NotificationSounds = true,
    -- Dynamic Island Customization
    DynamicIsland = true,
    IslandShowTime = true,
    IslandShowRoundTimer = true,
    IslandShowFPS = true,
    IslandShowPing = true,
    IslandShowRole = true,
    IslandShowStatus = true,
    IslandHoverExpand = true,
    IslandFlashAlerts = true,
    IslandWidth = 510,
    IslandHeight = 34,
    IslandYOffset = 12,
    IslandTransparency = 0.15,
    IslandTransparencyPct = 15,
    IslandTheme = "Red",
    IslandSyncTheme = true,
    IslandTextSize = 10,
    -- Combat & Silent Aim (All OFF by default)
    SilentAim = false,
    SilentAimVisuals = false,
    SilentAimWeaponOnly = false,
    SilentAimWallBang = false,
    WallBangAllMap = false,
    WallPenetrationOffset = 0.35,
    AutoShot = false,
    AutoShotDelay = 0.8,
    WallBang = false,
    WallCheck = true,
    PredictionBulletSpeed = 320,
    PredictMovement = true,
    PredictionPingCompensation = true,
    PredictionPingMultiplier = 1.15,
    MurdererAlert = false,
    AlertDistance = 35,
    KnifeAura = false,
    KnifeAuraRadius = 24,
    KnifeAuraShowRadius = true,
    KnifeAuraWallCheck = false,
    KnifeReachEnabled = false,
    KnifeReachKeybind = "F",
    KnifeAutoEquip = false,
    KnifeReachHighlight = false,
    KnifeReachBlink = false,
    KnifeReachMaxDist = 2500,
    KnifeTargetHUDMode = "Above", -- "Above", "Below", "Side", "IslandOnly"
    KnifeThrowEnabled = false,
    KnifeThrowKeybind = "E",
    KnifeThrowOnLeftClick = false,
    KnifeThrowOnRightClick = false,
    AntiFling = false,
    AutoKillAllOnRoundStart = false,
    -- Traps & Hitmarker
    TrapESP = false,
    AutoDisarmTraps = false,
    HitmarkerEnabled = true,
    HitmarkerVisual = true,
    HitmarkerSound = true,
    HitmarkerStyle = "Classic X",
    HitmarkerColor = "Crimson",
    HitmarkerSize = 28,
    HitmarkerDuration = 0.25,
    HitmarkerSoundPreset = "Neverlose",
    HitmarkerCustomSoundFile = "Hitsounds/sounds/neverlose.mp3",
    HitmarkerVolume = 80,
    HitmarkerKillEffect = true,
    HitmarkerKillSoundPreset = "Kill 1 (Echo)",
    HitmarkerKillVolume = 90,
    -- Prestige, Camera & Fun
    AutoPrestige = false,
    CoinCinematicCamera = false,
    CoinTargetHighlight = false,
    Disable3DRender = false,
    KnifeSpin = false,
    FakeDead = false,
    -- Fling Engine & Multi-Target Settings
    FlingActive = false,
    FlingMethod = "BodyThrust",
    FlingPower = 10,
    FlingDuration = 1.5,
    FlingReturnToOldPos = true,
    FlingPriority = "Murderer",
    FlingAirVoidCheck = true,
    -- Vote Dupe Settings
    VoteDupeActive = false,
    VoteDupeSelectedSlot = 1,
    VoteDupeDelay = 0.35,
    VoteDupeDelayScaled = 3.5,
    VoteDupeFastTeleport = true,
    -- Gun & Coins
    AutoGrabGun = false,
    CoinAutoFarm = false,
    CoinFarmMethod = "Tween",
    CoinTeleportCooldown = 0.05,
    CoinAura = true,
    CoinAuraRadius = 7.0,
    CoinFarmDelay = 0.05,
    CoinTweenSpeed = 26,
    CoinFarmYOffset = -2.5,
    CoinFarmProne = true,
    CoinFarmUnderground = true,
    CoinFarmAvoidMurderer = true,
    CoinAutoRespawn = false,
    CoinUndergroundPlatform = true,
    CoinLobbyHide = true,
    CoinPostAction = "KillAll_Or_Shoot", -- "Reset", "Afk", "KillAll_Or_Shoot"
    CoinAntiVoid = true,
    MaxCoins = 40,
    AutoSaveConfig = true,
    AutoClaimPass = true,
    AutoBuyPassTiers = true,
    -- Movement & Misc (All OFF by default)
    SpeedHack = false,
    WalkSpeed = 24,
    InfiniteJump = false,
    Noclip = false,
    AntiAFK = false,
    TabPosition = "Bottom", -- "Bottom", "Top", "Left", "Right"
    Fly = false,
    FlySpeed = 32,
    Fullbright = false,
    -- Personalization & Settings
    UITheme = "Red",
    CustomColorR = 255,
    CustomColorG = 45,
    CustomColorB = 85,
    UIGlassTransparency = 0.12,
    UIGlassTransparencyPct = 12,
    ShowWelcome = true,
    HubLogoImage = "",
    UISounds = true,
    AutoLoadConfig = true,
    AutoQueueOnTeleport = true,
    AutoReconnect = true,
    AutoReconnectOnKick = true,
    AutoReconnectDelay = 6.0,
    TeleportInjectDelay = 4.0,
    AutoServerHopLowPlayers = false,
    MinServerPlayers = 3,
    AutoHopBrokenServer = true,
    BrokenServerTimeout = 65,
    UIRootWidth = 550,
    UIRootHeight = 420,
    UIRootPosX = -275,
    UIRootPosY = -210,
    UIRootScaleX = 0.5,
    UIRootScaleY = 0.5,
    MenuKeybind = "RightShift",
    SilentAimKeybind = "None",
    ShootOnLeftClick = false,
    ShootOnRightClick = false,
    AutoShotKeybind = "None",
    InstantShootKeybind = "E",
    CameraNoclip = false,
    CameraMaxZoom = 400,
    -- Mobile Device Support & Optimization
    MobileFloatingButton = true,
    MobileButtonSize = 46,
    MobileButtonPosX = 20,
    MobileButtonPosY = 140,
    MobileButtonTransparency = 0.15,
    MobileButtonTransparencyPct = 15,
    MobileAutoScaling = true,
    MobileActionHUD = true,
    MobileUIScalePct = 65,
    MobileLockButtons = false,
    MobileShootBtnEnabled = true,
    MobileKnifeBtnEnabled = true,
    MobileFarmBtnEnabled = true,
    MobileShootPosX = -105,
    MobileShootPosY = -190,
    MobileKnifePosX = -105,
    MobileKnifePosY = -145,
    MobileFarmPosX = -105,
    MobileFarmPosY = -100,
    MobileHudBtnWidth = 84,
    MobileHudBtnHeight = 36,
    MobileHudTransparency = 0.20,
    MobileHudTransparencyPct = 20,
    ShowMobileTabOnPC = false,
    MobileIslandClickToggle = false,
}
_G.MM2_Config = Config

-- Load configuration function
local isNewUserSession = false
local function loadConfig()
    local loaded = false
    pcall(function()
        local targetFile = (isfile and isfile(CONFIG_FILE)) and CONFIG_FILE or ((isfile and isfile(LEGACY_CONFIG_FILE)) and LEGACY_CONFIG_FILE or nil)
        if targetFile and readfile then
            local data = HttpService:JSONDecode(readfile(targetFile))
            if type(data) == "table" then
                for k, v in pairs(data) do
                    if Config[k] ~= nil then Config[k] = v end
                end
                loaded = true
            end
        end
    end)
    if not loaded then
        isNewUserSession = true
        _G.MM2_IsNewUser = true
    end
    return loaded
end

-- Save configuration function with auto-saving, dirty tracking, and lifecycle hooks
local configDirty = false
local function saveConfig()
    pcall(function()
        if writefile then
            writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
            configDirty = false
        end
    end)
end
_G.MM2_SaveConfig = saveConfig
_G.MM2_MarkConfigDirty = function()
    configDirty = true
end

-- Periodic background auto-saver (every 4 seconds if dirty / modified)
task.spawn(function()
    while true do
        task.wait(4.0)
        pcall(function()
            if Config.AutoSaveConfig ~= false then
                if configDirty then
                    saveConfig()
                end
            end
        end)
    end
end)

-- Safe lifecycle auto-save hooks
pcall(function()
    game:BindToClose(function()
        pcall(saveConfig)
        if _G.MM2_SaveAllTimeStats then pcall(_G.MM2_SaveAllTimeStats) end
    end)
end)

pcall(function()
    Players.PlayerRemoving:Connect(function(plr)
        if plr == LocalPlayer then
            pcall(saveConfig)
            if _G.MM2_SaveAllTimeStats then pcall(_G.MM2_SaveAllTimeStats) end
        end
    end)
end)

-- Lifetime & Server Statistics Management
do
    _G.MM2_Stats = _G.MM2_Stats or {
        ServerCoins = 0,
        AllTimeCoins = 0,
        AllTimeRounds = 0
    }
    _G.MM2_Stats.ServerCoins = 0
    local STATS_FILE = "MM2_Stats_Data.json"
    pcall(function()
        if isfile and isfile(STATS_FILE) and readfile then
            local st = HttpService:JSONDecode(readfile(STATS_FILE))
            if type(st) == "table" then
                _G.MM2_Stats.AllTimeCoins = tonumber(st.AllTimeCoins) or 0
                _G.MM2_Stats.AllTimeRounds = tonumber(st.AllTimeRounds) or 0
            end
        end
    end)

    _G.MM2_SaveAllTimeStats = function()
        pcall(function()
            if writefile then
                writefile(STATS_FILE, HttpService:JSONEncode({
                    AllTimeCoins = _G.MM2_Stats.AllTimeCoins or 0,
                    AllTimeRounds = _G.MM2_Stats.AllTimeRounds or 0
                }))
            end
        end)
    end

    _G.MM2_ResetStats = function()
        _G.MM2_Stats.ServerCoins = 0
        _G.MM2_Stats.AllTimeCoins = 0
        _G.MM2_Stats.AllTimeRounds = 0
        TotalCoinsSession = 0
        CoinsCollectedThisRound = 0
        if _G.MM2_SaveAllTimeStats then _G.MM2_SaveAllTimeStats() end
        if showNotification then
            showNotification("🗑️ СТАТИСТИКА СБРОШЕНА", "Статистика за сессию и всё время сброшена на 0!", Color3.fromRGB(255, 90, 90), "🗑️", 3.5)
        end
    end
end

-- Auto-load saved config on startup
if Config.AutoLoadConfig ~= false then
    loadConfig()
end

-- Resolve GUI container (Safe for Xeno & Solara Level 2/3 Sandbox)
local function getContainer()
    if gethui then
        local s, h = pcall(gethui)
        if s and h and typeof(h) == "Instance" then
            local testOk = pcall(function() return h.Name end)
            if testOk then return h end
        end
    end
    local s, c = pcall(function() return game:GetService("CoreGui") end)
    if s and c then
        local canAccess = pcall(function()
            local t = Instance.new("Folder")
            t.Parent = c
            t:Destroy()
        end)
        if canAccess then return c end
    end
    local lp = LocalPlayer or game:GetService("Players").LocalPlayer
    return lp and (lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5)) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

local container = getContainer()

-- Clear any existing GUI leftovers
for _, child in ipairs(container:GetChildren()) do
    if child.Name == "MM2_Potassium_Hub_GUI" or child.Name:find("MM2_ESP_") or child.Name:find("MM2_CoinESP_") or child.Name == "MM2_SilentAim_Nametag" then
        child:Destroy()
    end
end

-- Lighting Backup
local OriginalLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
}

-- 2D Drawing Objects
local MurdererTracer = Drawing.new("Line")
MurdererTracer.Visible = false
MurdererTracer.Color = Color3.fromRGB(255, 45, 60)
MurdererTracer.Thickness = 2
MurdererTracer.Transparency = 1

local SheriffTracer = Drawing.new("Line")
SheriffTracer.Visible = false
SheriffTracer.Color = Color3.fromRGB(45, 140, 255)
SheriffTracer.Thickness = 1.8
SheriffTracer.Transparency = 1

-- 2D Off-Screen Radar Arrows (Murderer & Sheriff)
local MurdererArrow = Drawing.new("Triangle")
MurdererArrow.Visible = false
MurdererArrow.Color = Color3.fromRGB(255, 45, 60)
MurdererArrow.Filled = true
MurdererArrow.Thickness = 1

local MurdererArrowText = Drawing.new("Text")
MurdererArrowText.Visible = false
MurdererArrowText.Size = 13
MurdererArrowText.Center = true
MurdererArrowText.Outline = true
MurdererArrowText.Color = Color3.fromRGB(255, 235, 240)
MurdererArrowText.OutlineColor = Color3.fromRGB(15, 10, 15)

local SheriffArrow = Drawing.new("Triangle")
SheriffArrow.Visible = false
SheriffArrow.Color = Color3.fromRGB(45, 140, 255)
SheriffArrow.Filled = true
SheriffArrow.Thickness = 1

local SheriffArrowText = Drawing.new("Text")
SheriffArrowText.Visible = false
SheriffArrowText.Size = 13
SheriffArrowText.Center = true
SheriffArrowText.Outline = true
SheriffArrowText.Color = Color3.fromRGB(220, 240, 255)
SheriffArrowText.OutlineColor = Color3.fromRGB(10, 15, 25)

-- Silent Aim 2D Reticle Drawing Objects
local SilentAimCircle = Drawing.new("Circle")
SilentAimCircle.Visible = false
SilentAimCircle.Radius = 15
SilentAimCircle.Thickness = 2
SilentAimCircle.Color = Color3.fromRGB(0, 240, 255)
SilentAimCircle.Transparency = 1

local SilentAimLockText = Drawing.new("Text")
SilentAimLockText.Visible = false
SilentAimLockText.Size = 13
SilentAimLockText.Center = true
SilentAimLockText.Outline = true
SilentAimLockText.Color = Color3.fromRGB(0, 240, 255)
SilentAimLockText.OutlineColor = Color3.fromRGB(10, 15, 25)

-- Connection and ESP Tracker
local ScriptConnections = {}
local ActiveESP = {}
local ActiveCoinESP = {}

local function addConn(conn)
    table.insert(ScriptConnections, conn)
    return conn
end

local function safeHover(guiObj, enterFn, leaveFn)
    if not guiObj then return end
    pcall(function()
        local me = guiObj.MouseEnter
        if me and typeof(me) == "RBXScriptSignal" then
            addConn(me:Connect(enterFn))
        elseif enterFn and guiObj.InputBegan then
            addConn(guiObj.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    enterFn()
                end
            end))
        end
    end)
    pcall(function()
        local ml = guiObj.MouseLeave
        if ml and typeof(ml) == "RBXScriptSignal" then
            addConn(ml:Connect(leaveFn))
        elseif leaveFn and guiObj.InputEnded then
            addConn(guiObj.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    leaveFn()
                end
            end))
        end
    end)
end

-- Silent Aim 3D Billboard Nametag
local SilentAimBillboard = Instance.new("BillboardGui")
SilentAimBillboard.Name = "MM2_SilentAim_Nametag"
SilentAimBillboard.Size = UDim2.new(0, 165, 0, 36)
SilentAimBillboard.StudsOffset = Vector3.new(0, 3.6, 0)
SilentAimBillboard.AlwaysOnTop = true
SilentAimBillboard.MaxDistance = 800
SilentAimBillboard.Enabled = false
SilentAimBillboard.Parent = container

local SAB_Frame = Instance.new("Frame")
SAB_Frame.Size = UDim2.new(1, 0, 1, 0)
SAB_Frame.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
SAB_Frame.BackgroundTransparency = 0.15
SAB_Frame.BorderSizePixel = 0
SAB_Frame.Parent = SilentAimBillboard
Instance.new("UICorner", SAB_Frame).CornerRadius = UDim.new(0, 8)

local SAB_Stroke = Instance.new("UIStroke")
SAB_Stroke.Color = Color3.fromRGB(0, 240, 255)
SAB_Stroke.Thickness = 1.2
SAB_Stroke.Transparency = 0.2
SAB_Stroke.Parent = SAB_Frame

do
    local av = Instance.new("ImageLabel")
    av.Name = "Avatar"
    av.Size = UDim2.new(0, 26, 0, 26)
    av.Position = UDim2.new(0, 5, 0.5, -13)
    av.BackgroundTransparency = 1
    av.BorderSizePixel = 0
    av.Parent = SAB_Frame
    Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)
    local avSt = Instance.new("UIStroke")
    avSt.Name = "Stroke"
    avSt.Color = Color3.fromRGB(0, 240, 255)
    avSt.Thickness = 1
    avSt.Transparency = 0.35
    avSt.Parent = av
end

local SAB_Title = Instance.new("TextLabel")
SAB_Title.Size = UDim2.new(1, -40, 0, 15)
SAB_Title.Position = UDim2.new(0, 36, 0, 3)
SAB_Title.BackgroundTransparency = 1
SAB_Title.Font = Enum.Font.GothamBold
SAB_Title.TextSize = 11
SAB_Title.TextColor3 = Color3.fromRGB(245, 250, 255)
SAB_Title.Text = "Target"
SAB_Title.TextXAlignment = Enum.TextXAlignment.Left
SAB_Title.TextTruncate = Enum.TextTruncate.AtEnd
SAB_Title.Parent = SAB_Frame

local SAB_Sub = Instance.new("TextLabel")
SAB_Sub.Size = UDim2.new(1, -40, 0, 13)
SAB_Sub.Position = UDim2.new(0, 36, 0, 18)
SAB_Sub.BackgroundTransparency = 1
SAB_Sub.Font = Enum.Font.GothamMedium
SAB_Sub.TextSize = 9
SAB_Sub.TextColor3 = Color3.fromRGB(0, 240, 255)
SAB_Sub.Text = "0m • Ready"
SAB_Sub.TextXAlignment = Enum.TextXAlignment.Left
SAB_Sub.TextTruncate = Enum.TextTruncate.AtEnd
SAB_Sub.Parent = SAB_Frame

-- Murderer Long-Range Strike Target Highlight & Reticle
local KnifeHoverHighlight = Instance.new("Highlight")
KnifeHoverHighlight.Name = "MM2_KnifeHover_Highlight"
KnifeHoverHighlight.FillColor = Color3.fromRGB(255, 35, 55)
KnifeHoverHighlight.FillTransparency = 0.4
KnifeHoverHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
KnifeHoverHighlight.OutlineTransparency = 0.05
KnifeHoverHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
KnifeHoverHighlight.Enabled = false
KnifeHoverHighlight.Parent = container

local KnifeLockBillboard = Instance.new("BillboardGui")
KnifeLockBillboard.Name = "MM2_KnifeLock_Billboard"
KnifeLockBillboard.Size = UDim2.new(0, 180, 0, 36)
KnifeLockBillboard.StudsOffset = Vector3.new(0, 6.0, 0)
KnifeLockBillboard.AlwaysOnTop = true
KnifeLockBillboard.MaxDistance = 2500
KnifeLockBillboard.Enabled = false
KnifeLockBillboard.Parent = container

local KLB_Frame = Instance.new("Frame")
KLB_Frame.Size = UDim2.new(1, 0, 1, 0)
KLB_Frame.BackgroundColor3 = Color3.fromRGB(24, 12, 16)
KLB_Frame.BackgroundTransparency = 0.15
KLB_Frame.BorderSizePixel = 0
KLB_Frame.Parent = KnifeLockBillboard
Instance.new("UICorner", KLB_Frame).CornerRadius = UDim.new(0, 7)

local KLB_Stroke = Instance.new("UIStroke")
KLB_Stroke.Color = Color3.fromRGB(255, 45, 65)
KLB_Stroke.Thickness = 1.6
KLB_Stroke.Transparency = 0.2
KLB_Stroke.Parent = KLB_Frame

local KLB_Title = Instance.new("TextLabel")
KLB_Title.Size = UDim2.new(1, -8, 0, 18)
KLB_Title.Position = UDim2.new(0, 4, 0, 2)
KLB_Title.BackgroundTransparency = 1
KLB_Title.Font = Enum.Font.GothamBlack
KLB_Title.TextSize = 10
KLB_Title.TextColor3 = Color3.fromRGB(255, 50, 70)
KLB_Title.Text = "🗡️ TARGET LOCKED [HOVER]"
KLB_Title.Parent = KLB_Frame

local KLB_Sub = Instance.new("TextLabel")
KLB_Sub.Size = UDim2.new(1, -8, 0, 16)
KLB_Sub.Position = UDim2.new(0, 4, 0, 20)
KLB_Sub.BackgroundTransparency = 1
KLB_Sub.Font = Enum.Font.GothamBold
KLB_Sub.TextSize = 9
KLB_Sub.TextColor3 = Color3.fromRGB(255, 230, 235)
KLB_Sub.Text = "Press [F] to Strike"
KLB_Sub.Parent = KLB_Frame

-- Knife Aura 3D Radius Circle on Ground
do
    pcall(function()
        local existing = workspace.Terrain:FindFirstChild("MM2_KnifeAura_Circle")
        if existing then existing:Destroy() end
        local a = Instance.new("CylinderHandleAdornment")
        a.Name = "MM2_KnifeAura_Circle"
        a.Height = 0.15
        a.Radius = Config.KnifeAuraRadius or 24
        a.Color3 = Color3.fromRGB(255, 35, 60)
        a.Transparency = 0.68
        a.AlwaysOnTop = false
        a.ZIndex = 1
        a.CFrame = CFrame.Angles(math.rad(90), 0, 0) * CFrame.new(0, 0, 2.7)
        a.Visible = false
        a.Parent = workspace.Terrain
        _G.MM2_KnifeAuraCircle = a
    end)
end

local function cleanCharacterPhysics(char)
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyThrust") or 
           v:IsA("LinearVelocity") or v:IsA("VectorForce") or v:IsA("RocketPropulsion") or
           v:IsA("AlignPosition") or v:IsA("Torque") or v:IsA("BodyGyro") or v:IsA("BodyPosition") then
            pcall(function() v:Destroy() end)
        end
        if v:IsA("BasePart") then
            pcall(function()
                v.CanCollide = true
                v.Transparency = 0
                v.LocalTransparencyModifier = 0
            end)
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
    local cam = workspace.CurrentCamera
    if cam and (cam.Focus.Position - cam.CFrame.Position).Magnitude < 1.0 then
        pcall(function()
            cam.CFrame = cam.CFrame * CFrame.new(0, 2, 8)
        end)
    end
end

-- Cleanup Handler (Complete Unload: 100% Wipe of ESP, UI, Drawings, Physics, Platform)
_G.MM2_Hub_Cleanup = function()
    _G.MM2_Hub_Running = false
    _G.MM2_Hub_InstanceID = nil

    -- 1. Disconnect all script connections
    for _, conn in ipairs(ScriptConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(ScriptConnections)

    -- 2. Stop coin auto-farm, active tweens, bodyvelocity & noclip
    isFarmingCoin = false
    if activeCoinTween then
        pcall(function() activeCoinTween:Cancel() end)
        activeCoinTween = nil
    end
    if activeFarmBv and activeFarmBv.Parent then
        pcall(function() activeFarmBv:Destroy() end)
        activeFarmBv = nil
    end
    if activeFarmNoclipConn then
        pcall(function() activeFarmNoclipConn:Disconnect() end)
        activeFarmNoclipConn = nil
    end
    if _G.MM2_StopCoinFarmLoop then pcall(_G.MM2_StopCoinFarmLoop) end
    if _G.MM2_StopCoinFarm then pcall(_G.MM2_StopCoinFarm) end

    -- 3. Destroy all 2D Drawings
    pcall(function() MurdererTracer:Remove() end)
    pcall(function() SheriffTracer:Remove() end)
    pcall(function() MurdererArrow:Remove() end)
    pcall(function() MurdererArrowText:Remove() end)
    pcall(function() SheriffArrow:Remove() end)
    pcall(function() SheriffArrowText:Remove() end)
    pcall(function() SilentAimCircle:Remove() end)
    pcall(function() SilentAimLockText:Remove() end)

    -- 4. Destroy Billboards and Highlights
    pcall(function() SilentAimBillboard:Destroy() end)
    pcall(function() KnifeHoverHighlight:Destroy() end)
    pcall(function() KnifeLockBillboard:Destroy() end)
    pcall(function() if _G.MM2_KnifeAuraCircle then _G.MM2_KnifeAuraCircle:Destroy() end end)

    for _, v in pairs(ActiveESP) do
        if v.Billboard then pcall(function() v.Billboard:Destroy() end) end
        if v.Highlight then pcall(function() v.Highlight:Destroy() end) end
    end
    table.clear(ActiveESP)

    for _, v in pairs(ActiveCoinESP) do
        if v.Billboard then pcall(function() v.Billboard:Destroy() end) end
    end
    table.clear(ActiveCoinESP)

    -- 5. Comprehensive sweep of any leftover ESP/Highlights/Billboards across game and workspace
    pcall(function()
        for _, h in ipairs(game:GetDescendants()) do
            if h:IsA("Highlight") and (string.find(h.Name, "MM2_") or string.find(h.Name, "Vortex_")) then
                pcall(function() h:Destroy() end)
            elseif h:IsA("BillboardGui") and (string.find(h.Name, "MM2_") or string.find(h.Name, "Vortex_")) then
                pcall(function() h:Destroy() end)
            end
        end
    end)

    -- 6. Destroy underground safe platform
    pcall(function()
        if UndergroundPlatform then UndergroundPlatform:Destroy() UndergroundPlatform = nil end
        local p = workspace:FindFirstChild("MM2_UndergroundPlatform")
        if p then p:Destroy() end
    end)

    -- 7. Restore Player physics, platform stand, walking & jumping
    pcall(function()
        local char = LocalPlayer.Character
        cleanCharacterPhysics(char)
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if hum then
                hum.PlatformStand = false
                hum.Sit = false
                hum.WalkSpeed = 16
                hum.JumpPower = 50
                hum.AutoRotate = true
            end
            if root then
                root.Anchored = false
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)

    -- 8. Restore Fullbright & Lighting
    pcall(function()
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
    end)
    pcall(function()
        if _G.MM2_CleanupVisuals then _G.MM2_CleanupVisuals() end
    end)

    -- 9. Restore Camera
    pcall(function()
        Camera.CameraType = Enum.CameraType.Custom
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then Camera.CameraSubject = hum end
    end)

    -- 10. Restore 3D Rendering & FPS
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
    pcall(function() if setfpscap then setfpscap(0) end end)

    -- 11. Destroy all GUI elements (Main GUI, Dynamic Island, Notifications, Disable3D)
    if container:FindFirstChild("MM2_Disable3D_Screen") then
        pcall(function() container.MM2_Disable3D_Screen:Destroy() end)
    end
    pcall(function()
        if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
    end)
    pcall(function()
        for _, child in ipairs(container:GetChildren()) do
            if child.Name == "MM2_Potassium_Hub_GUI" or child.Name:find("MM2_") or child.Name:find("Vortex_") then
                child:Destroy()
            end
        end
    end)

    -- 12. Reset Globals
    _G.MM2_Hub_Running = false
    _G.MM2_Hub_InstanceID = nil
    _G.MM2_Hub_Cleanup = nil
    _G.MM2_FlingingActive = false
    _G.MM2_LocalPlayerDiedThisRound = false
    _G.MM2_RoundLimitReached = false
    _G.MM2_MurdererEliminatedThisRound = false
    _G.MM2_TargetCoin = nil
    _G.MM2_CoinBlacklist = {}

    print("[VORTEX PRIME] Completely unloaded successfully. All ESP, UI, drawings, and hooks removed.")
end

-- Helper: Get Local Root
local function getLocalRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char.PrimaryPart
end

-- ====================================================================
-- 📦 CACHED GAME & ROUND STATE (Topologically ordered before coin helpers)
-- ====================================================================
local CachedMurderer = nil
local CachedSheriff = nil
local CachedHero = nil
local CachedGunDrop = nil
local CachedMap = nil
local CachedCoinContainer = nil
local RoundActive = false
local CoinsCollectedThisRound = 0
local TotalCoinsSession = 0
local CurrentFarmStatus = "Ожидание"
local hasExecutedPostActionThisRound = false
_G.MM2_HasExecutedPostActionThisRound = false
_G.MM2_IsExecutingPostAction = false

local CurrentRoundClient = nil
pcall(function()
    CurrentRoundClient = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CurrentRoundClient"))
end)

_G.MM2_GetGameMode = function()
    local gm = workspace:GetAttribute("GameMode")
    if gm and type(gm) == "string" and gm ~= "" then
        return gm
    end
    if CurrentRoundClient and CurrentRoundClient.PlayerData then
        for _, pData in pairs(CurrentRoundClient.PlayerData) do
            if type(pData) == "table" and pData.Role then
                if pData.Role == "Zombie" or pData.Role == "Survivor" then
                    return "Infection"
                elseif pData.Role == "Freezer" or pData.Role == "Runner" then
                    return "FreezeTag"
                end
            end
        end
    end
    return "Classic"
end

_G.MM2_IsInfectionRound = function()
    return _G.MM2_GetGameMode() == "Infection"
end

-- Helper: Get Active Map (Strictly match arena maps at Z > 2500, cached & throttled)
local getCurrentMap
do
    local lastMapSearchTime = 0
    function getCurrentMap()
        if CachedMap and CachedMap.Parent == workspace then
            return CachedMap
        end
        local now = os.clock()
        if (now - lastMapSearchTime < 0.5) then
            return CachedMap
        end
        lastMapSearchTime = now

        -- 1. First priority: any model with CoinContainer located at match arena (Z > 2500)
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj.Name ~= "Lobby" and obj.Name ~= "RegularLobby" and obj.Name ~= "EffectLoader" and obj.Name ~= "ServerStatus" and obj.Name ~= "MM2_UndergroundPlatform" and not Players:GetPlayerFromCharacter(obj) then
                if obj:FindFirstChild("CoinContainer") or obj:FindFirstChild("Coin_Container") or obj:FindFirstChild("Coins") then
                    local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if p and p.Position.Z > 2500 then
                        CachedMap = obj
                        return obj
                    end
                end
            end
        end
        -- 2. Second priority: any map model with Spawns or parts at arena (Z > 2500) and Y < 400
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj.Name ~= "Lobby" and obj.Name ~= "RegularLobby" and obj.Name ~= "EffectLoader" and obj.Name ~= "ServerStatus" and obj.Name ~= "MM2_UndergroundPlatform" and not Players:GetPlayerFromCharacter(obj) then
                local sp = obj:FindFirstChild("Spawns") or obj:FindFirstChild("Spawn") or obj:FindFirstChild("SpawnLocation")
                if sp then
                    local spPart = sp:FindFirstChildWhichIsA("BasePart") or (sp:IsA("BasePart") and sp)
                    if spPart and spPart.Position.Z > 2500 and spPart.Position.Y < 400 then
                        CachedMap = obj
                        return obj
                    end
                end
                local primaryOrFirst = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if primaryOrFirst and primaryOrFirst.Position.Z > 2500 and primaryOrFirst.Position.Y < 400 and #obj:GetChildren() >= 5 then
                    CachedMap = obj
                    return obj
                end
            end
        end
        return nil
    end
end

local function isRoundActive()
    local rtp = workspace:FindFirstChild("RoundTimerPart")
    local rtpTime = rtp and rtp:GetAttribute("Time")
    if rtpTime and type(rtpTime) == "number" and rtpTime > 0 then
        return true
    end
    if RoundActive == true or _G.MM2_RoundActive == true then
        return true
    end
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local mainGui = pGui and pGui:FindFirstChild("MainGUI")
    local gameTimer = mainGui and mainGui:FindFirstChild("GameTimer", true)
    if gameTimer and gameTimer:IsA("TextLabel") and gameTimer.Visible and gameTimer.Text:find("%d+:%d+") then
        return true
    end
    if CurrentRoundClient and CurrentRoundClient.PlayerData and next(CurrentRoundClient.PlayerData) ~= nil then
        local curMap = CachedMap or getCurrentMap()
        if curMap then
            return true
        end
    end
    return false
end
_G.MM2_IsRoundActive = isRoundActive

-- Helper: Check if a player is in the Lobby (Lobby floor is at Y ~ 458, under-lobby at Y ~ 400, arena matches at Z > 2500)
local function isPlayerInLobby(plr)
    if not plr then return true end
    local char = plr.Character
    if not char then return true end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return true end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") or char.PrimaryPart
    if not root then return true end

    -- Guard: If local player is actively flinging, do NOT falsely classify local player as in lobby mid-flight
    if plr == LocalPlayer and (_G.MM2_FlingingActive or isFlingRunning) then
        local rootPart = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
        if rootPart and (rootPart.Position.Z > 2500 or rootPart.Position.Y < 400) then
            return false
        end
    end

    -- If no match round is active on server, all players are in lobby
    if not isRoundActive() then
        return true
    end

    local pos = root.Position

    -- In MM2, match maps are located at Z > 2500 (typically Z ~ 8000-10000) or Y < 400.
    -- Lobby is located around X ~ 500, Y ~ 450-520, Z ~ 0.
    if pos.Z < 2500 and pos.Y >= 400 then
        return true
    end

    return false
end
_G.MM2_IsPlayerInLobby = isPlayerInLobby

-- Helper: Robust Resolver for GunDrop BasePart (Supports Model, Tool, MeshPart, Part)
local function resolveGunBasePart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("Folder") then
        if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart end
        local handle = obj:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then return handle end
        local bp = obj:FindFirstChildWhichIsA("BasePart", true)
        if bp then return bp end
    end
    return nil
end

-- Helper: Get Dropped Gun (Comprehensive Workspace & Map Scan)
local function getGunDrop()
    -- 1. Direct workspace top-level check
    local direct = workspace:FindFirstChild("GunDrop")
    local p = resolveGunBasePart(direct)
    if p then return p, direct end

    -- 2. Check current active map
    local curMap = CachedMap or getCurrentMap()
    if curMap then
        local inMap = curMap:FindFirstChild("GunDrop")
        p = resolveGunBasePart(inMap)
        if p then return p, inMap end
        local inMapGun = curMap:FindFirstChild("Gun")
        p = resolveGunBasePart(inMapGun)
        if p then return p, inMapGun end
    end

    -- 3. Top-level workspace children scan (supports DroppedGun / Gun names)
    for _, obj in ipairs(workspace:GetChildren()) do
        if (obj.Name == "GunDrop" or obj.Name == "Gun" or obj.Name == "DroppedGun") and not Players:GetPlayerFromCharacter(obj) then
            p = resolveGunBasePart(obj)
            if p then return p, obj end
        end
    end

    -- 4. Fast native recursive search in workspace
    local recursive = workspace:FindFirstChild("GunDrop", true)
    p = resolveGunBasePart(recursive)
    if p then return p, recursive end

    return nil, nil
end

local function isPlayerDead(plr)
    if not plr or not plr.Parent then return true end
    local char = plr.Character
    if not char or not char.Parent then return true end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return true end

    -- Authoritative server attribute
    local aliveAttr = plr:GetAttribute("Alive")
    if plr == LocalPlayer then
        if aliveAttr == true and hum and hum.Health > 0 then
            _G.MM2_LocalPlayerDiedThisRound = false
            return false
        elseif aliveAttr == false then
            return true
        end
        return _G.MM2_LocalPlayerDiedThisRound == true
    else
        if aliveAttr == false then
            return true
        end
        if aliveAttr == true and hum and hum.Health > 0 then
            return false
        end
    end

    if CurrentRoundClient and CurrentRoundClient.PlayerData then
        local pData = CurrentRoundClient.PlayerData[plr.Name]
        if type(pData) == "table" then
            if pData.Dead == true or pData.Killed == true then
                return true
            elseif pData.Dead == false and pData.Killed == false then
                return false
            end
        end
    end

    return false
end

local function isPlayerAlive(plr)
    if not plr or not plr.Parent then return false end
    if not isRoundActive() then return false end
    if isPlayerInLobby(plr) then return false end
    return not isPlayerDead(plr)
end

-- Universal Alive checker: verifies whether LocalPlayer is Alive = true in match
local function isLocalPlayerAlive()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum or hum.Health <= 0 then return false end
    if not isRoundActive() then return false end

    -- Primary Authoritative: Check official MM2 server attribute
    local aliveAttr = LocalPlayer:GetAttribute("Alive")
    if aliveAttr == true and hum.Health > 0 then
        _G.MM2_LocalPlayerDiedThisRound = false
        return true
    elseif aliveAttr == false then
        return false
    end

    if _G.MM2_LocalPlayerDiedThisRound then return false end
    if isPlayerInLobby(LocalPlayer) then return false end

    -- Synchronization: Check CurrentRoundClient
    if CurrentRoundClient and CurrentRoundClient.PlayerData and CurrentRoundClient.PlayerData[LocalPlayer.Name] then
        local pData = CurrentRoundClient.PlayerData[LocalPlayer.Name]
        if type(pData) == "table" and (pData.Dead == true or pData.Killed == true) then
            return false
        end
    end

    return true
end
_G.MM2_IsLocalPlayerAlive = isLocalPlayerAlive

-- Reliable check: Is LocalPlayer actively living and playing in the current match arena?
local function isLocalPlayerPlayingInRound()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hum or hum.Health <= 0 or not root then return false end
    if not isRoundActive() then return false end

    -- Primary Authoritative: If server attribute says Alive == true, player is definitely alive!
    local aliveAttr = LocalPlayer:GetAttribute("Alive")
    if aliveAttr == true and hum.Health > 0 then
        _G.MM2_LocalPlayerDiedThisRound = false
        if not isPlayerInLobby(LocalPlayer) then
            return true
        end
    end

    if _G.MM2_LocalPlayerDiedThisRound then return false end
    if isPlayerInLobby(LocalPlayer) then return false end
    local curMap = CachedMap or (getCurrentMap and getCurrentMap())
    if not curMap then return false end
    if not isLocalPlayerAlive() then return false end

    return true
end
_G.MM2_IsLocalPlayerPlayingInRound = isLocalPlayerPlayingInRound


local CoinTracker = { Time = 0, Amount = 0, Max = 40, Bag = "Candy", LastProcessedAmt = 0 }

_G.MM2_ResetRoundCoinState = function()
    CoinsCollectedThisRound = 0
    if CoinTracker then
        CoinTracker.Amount = 0
        CoinTracker.LastProcessedAmt = 0
    end
    _G.MM2_RoundLimitReached = false
    _G.MM2_LocalPlayerDiedThisRound = false
    _G.MM2_MurdererEliminatedThisRound = false
    _G.MM2_LocalPlayerRole = nil
    hasExecutedPostActionThisRound = false
    _G.MM2_HasExecutedPostActionThisRound = false
    _G.MM2_IsExecutingPostAction = false
    pcall(function()
        LocalPlayer:SetAttribute("BagFull", false)
        LocalPlayer:SetAttribute("CoinBagFull", false)
    end)
    CachedCoinContainer = nil
    if _G.MM2_CoinBlacklist then table.clear(_G.MM2_CoinBlacklist) end
    if _G.MM2_SetTargetCoinHighlight then _G.MM2_SetTargetCoinHighlight(nil) end
    _G.MM2_TargetCoin = nil
end

local function recordCoinsCollected(newCount)
    if not newCount or type(newCount) ~= "number" then return end
    local prev = CoinTracker.LastProcessedAmt or 0
    if newCount > prev then
        local diff = newCount - prev
        CoinTracker.LastProcessedAmt = newCount
        CoinTracker.Amount = newCount
        CoinsCollectedThisRound = newCount
        TotalCoinsSession = (TotalCoinsSession or 0) + diff
        if _G.MM2_TriggerCoinCollectPulse then
            _G.MM2_TriggerCoinCollectPulse()
        end
        if _G.MM2_Stats then
            _G.MM2_Stats.ServerCoins = TotalCoinsSession
            _G.MM2_Stats.AllTimeCoins = (_G.MM2_Stats.AllTimeCoins or 0) + diff
            if _G.MM2_SaveAllTimeStats then _G.MM2_SaveAllTimeStats() end
        end
    elseif newCount < prev then
        -- New round started: server count reset to 1..N
        CoinTracker.LastProcessedAmt = newCount
        CoinTracker.Amount = newCount
        CoinsCollectedThisRound = newCount
        _G.MM2_RoundLimitReached = false
        hasExecutedPostActionThisRound = false
        pcall(function()
            LocalPlayer:SetAttribute("BagFull", false)
            LocalPlayer:SetAttribute("CoinBagFull", false)
        end)
        if newCount > 0 then
            TotalCoinsSession = (TotalCoinsSession or 0) + newCount
            if _G.MM2_Stats then
                _G.MM2_Stats.ServerCoins = TotalCoinsSession
                _G.MM2_Stats.AllTimeCoins = (_G.MM2_Stats.AllTimeCoins or 0) + newCount
                if _G.MM2_SaveAllTimeStats then _G.MM2_SaveAllTimeStats() end
            end
        end
    end
end
_G.MM2_RecordCoinsCollected = recordCoinsCollected

local function isCoinBagFull()
    if isPlayerInLobby(LocalPlayer) then
        if _G.MM2_ResetRoundCoinState then _G.MM2_ResetRoundCoinState() end
        return false
    end
    if not isRoundActive() then
        if _G.MM2_ResetRoundCoinState then _G.MM2_ResetRoundCoinState() end
        return false
    end
    if _G.MM2_LocalPlayerDiedThisRound then return false end

    local maxCap = (CoinTracker and CoinTracker.Max and CoinTracker.Max > 0) and CoinTracker.Max or Config.MaxCoins or 40

    -- 1. Check official MM2 Coin GUI FIRST (Authoritative visual source of truth)
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
                    _G.MM2_RoundLimitReached = true
                    return true
                end
                local coinsLbl = bag:FindFirstChild("Coins", true) or bag:FindFirstChild("Coin", true)
                if coinsLbl and coinsLbl:IsA("TextLabel") then
                    local count = tonumber(coinsLbl.Text:match("%d+"))
                    if count ~= nil then
                        if count >= maxCap then
                            _G.MM2_RoundLimitReached = true
                            return true
                        elseif count < maxCap then
                            _G.MM2_RoundLimitReached = false
                            return false
                        end
                    end
                end
            end
        end
    end

    -- 2. Direct Attributes Check
    if LocalPlayer:GetAttribute("BagFull") == true or LocalPlayer:GetAttribute("CoinBagFull") == true then
        _G.MM2_RoundLimitReached = true
        return true
    end

    -- 3. Direct CurrentRoundClient Check
    if CurrentRoundClient and CurrentRoundClient.PlayerData and CurrentRoundClient.PlayerData[LocalPlayer.Name] then
        local pData = CurrentRoundClient.PlayerData[LocalPlayer.Name]
        if type(pData) == "table" and type(pData.Coins) == "number" and maxCap > 0 then
            if pData.Coins >= maxCap then
                _G.MM2_RoundLimitReached = true
                return true
            elseif pData.Coins < maxCap then
                _G.MM2_RoundLimitReached = false
                return false
            end
        end
    end

    -- 4. CoinTracker or local counter check
    local curCoins = (CoinTracker and CoinTracker.Amount) or CoinsCollectedThisRound or 0
    if curCoins >= maxCap and maxCap > 0 then
        _G.MM2_RoundLimitReached = true
        return true
    end

    return false
end
_G.MM2_IsCoinBagFull = isCoinBagFull

pcall(function()
    local CoinCollected = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("CoinCollected")
    CoinCollected.OnClientEvent:Connect(function(bagName, newAmt, maxAmt, extra)
        local cur = tonumber(newAmt)
        if not cur then return end
        local maxCap = tonumber(maxAmt) or 40

        CoinTracker.Time = os.clock()
        CoinTracker.Amount = cur
        CoinTracker.Max = maxCap
        CoinTracker.Bag = tostring(bagName or "Candy")

        -- Single authoritative recording of verified server coins:
        recordCoinsCollected(cur)

        if cur >= maxCap then
            LocalPlayer:SetAttribute("BagFull", true)
            LocalPlayer:SetAttribute("CoinBagFull", true)
            _G.MM2_RoundLimitReached = true
        end
    end)
end)

-- Helper: Get Active Coins (Ultra-Optimized & Resilient)
local function getCoinContainer()
    local curMap = CachedMap or (getCurrentMap and getCurrentMap())
    if CachedCoinContainer and CachedCoinContainer.Parent and (not curMap or CachedCoinContainer:IsDescendantOf(curMap)) and #CachedCoinContainer:GetChildren() > 0 then
        return CachedCoinContainer
    end
    CachedCoinContainer = nil

    local containerNames = {
        "CoinContainer", "Coins",
        "CandyContainer", "Candies", "HalloweenContainer",
        "SnowflakeContainer", "HolidayContainer", "ChristmasContainer", "Snowflakes",
        "EventContainer", "EventCoins", "Tokens", "EggContainer", "Eggs", "BeachBalls", "SummerContainer"
    }

    if curMap then
        for _, name in ipairs(containerNames) do
            local cc = curMap:FindFirstChild(name, true)
            if cc and #cc:GetChildren() > 0 then
                CachedCoinContainer = cc
                return CachedCoinContainer
            end
        end
    end

    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name ~= "RegularLobby" and obj.Name ~= "Terrain" then
            for _, name in ipairs(containerNames) do
                local cc = obj:FindFirstChild(name, true)
                if cc and #cc:GetChildren() > 0 then
                    CachedCoinContainer = cc
                    return CachedCoinContainer
                end
            end
        end
    end

    for _, name in ipairs(containerNames) do
        local standalone = workspace:FindFirstChild(name)
        if standalone and #standalone:GetChildren() > 0 then
            CachedCoinContainer = standalone
            return CachedCoinContainer
        end
    end

    return nil
end

local function getCoinServerPart(coinObj)
    if not coinObj then return nil end
    if coinObj.Name == "Coin_Server" and coinObj:IsA("BasePart") then
        return coinObj
    end
    if coinObj:IsA("BasePart") and coinObj:FindFirstChildWhichIsA("TouchTransmitter") then
        return coinObj
    end
    local cs = coinObj:FindFirstChild("Coin_Server")
    if cs and cs:IsA("BasePart") then
        return cs
    end
    local tt = coinObj:FindFirstChildWhichIsA("TouchTransmitter")
    if tt and tt.Parent and tt.Parent:IsA("BasePart") then
        return tt.Parent
    end
    if coinObj:IsA("BasePart") then
        return coinObj
    end
    return coinObj:FindFirstChildWhichIsA("BasePart")
end
_G.MM2_GetCoinServerPart = getCoinServerPart

-- Strict blacklist checker: GunDrop, guns, knives, and weapons are NEVER coins!
local function isWeaponOrForbiddenItem(item)
    if not item then return true end
    local name = item.Name
    local nameLow = name:lower()
    if name == "GunDrop" or name == "Gun" or name == "DroppedGun" or name == "Knife" or name == "Revolver" or name == "Pistol" then return true end
    if nameLow:find("gun") or nameLow:find("revolver") or nameLow:find("knife") or nameLow:find("weapon") or nameLow:find("pistol") then return true end
    local p = item.Parent
    if p then
        local pName = p.Name
        local pNameLow = pName:lower()
        if pName == "GunDrop" or pName == "DroppedGun" or pNameLow:find("gun") or pNameLow:find("revolver") or pNameLow:find("knife") then
            return true
        end
    end
    return false
end
_G.MM2_IsWeaponOrForbiddenItem = isWeaponOrForbiddenItem

local getActiveCoins
do
    local cachedActiveCoins = {}
    local lastActiveCoinsTime = 0
    local lastDescendantScanTime = 0

    function getActiveCoins()
        if not isRoundActive() then
            return {}
        end
        local now = os.clock()
        if (now - lastActiveCoinsTime < 0.25) and (#cachedActiveCoins > 0 or (now - lastActiveCoinsTime < 0.15)) then
            return cachedActiveCoins
        end
        lastActiveCoinsTime = now

        local coins = {}
        local seen = {}
        local curMap = CachedMap or (getCurrentMap and getCurrentMap())

        local containerNames = {
            "CoinContainer", "Coins", "Coin_Container",
            "CandyContainer", "Candies", "HalloweenContainer", "HalloweenCoins",
            "SnowflakeContainer", "HolidayContainer", "ChristmasContainer", "Snowflakes", "ChristmasCoins",
            "EventContainer", "EventCoins", "Event_Coins", "Tokens", "EventTokens",
            "EggContainer", "Eggs", "EasterContainer",
            "BeachBalls", "SummerContainer", "SummerCoins", "Presents", "Gifts"
        }

        local function addCoinsFrom(parent)
            if not parent then return end
            for _, c in ipairs(parent:GetChildren()) do
                if not isWeaponOrForbiddenItem(c) then
                    -- A coin is DEAD if marked collected or delete
                    local isDead = (c:GetAttribute("Collected") == true)
                        or (c:GetAttribute("Delete") == true)

                    local cv = c:FindFirstChild("CoinVisual")
                    if cv and not isDead then
                        if (cv:GetAttribute("Collected") == true) or (cv:GetAttribute("Delete") == true) or (cv:IsA("BasePart") and cv.Transparency >= 0.85) then
                            isDead = true
                        end
                    end

                    if not isDead then
                        -- Target Coin_Server (the actual server part that has the TouchTransmitter for coins and candies)
                        local serverPart = getCoinServerPart(c) or (c:IsA("BasePart") and c)
                        if serverPart and not seen[serverPart] and not isWeaponOrForbiddenItem(serverPart) then
                            local bl = _G.MM2_CoinBlacklist and _G.MM2_CoinBlacklist[serverPart]
                            if not (bl and (now < bl)) then
                                seen[serverPart] = true
                                table.insert(coins, serverPart)
                            end
                        end
                    end
                end
            end
        end

        if curMap then
            for _, name in ipairs(containerNames) do
                local cc = curMap:FindFirstChild(name) or curMap:FindFirstChild(name, true)
                if cc then addCoinsFrom(cc) end
            end
        end

        for _, name in ipairs(containerNames) do
            local wsObj = workspace:FindFirstChild(name)
            if wsObj then addCoinsFrom(wsObj) end
        end

        -- Universal Fallback: scan active map for ANY event item/coin with TouchInterest (Strictly never GunDrop!)
        -- Throttled to at most once every 2 seconds, and strictly only when CoinAutoFarm is active
        if #coins == 0 and curMap and Config.CoinAutoFarm and (now - lastDescendantScanTime > 2.0) then
            lastDescendantScanTime = now
            for _, c in ipairs(curMap:GetDescendants()) do
                if c:IsA("BasePart") and not seen[c] and not isWeaponOrForbiddenItem(c) then
                    local nameLow = c.Name:lower()
                    if (nameLow:find("coin") or nameLow:find("candy") or nameLow:find("snow") or nameLow:find("token") or nameLow:find("event") or nameLow:find("egg") or nameLow:find("candydrop") or nameLow:find("coindrop") or nameLow:find("pumpkin") or nameLow:find("beach") or nameLow:find("gift") or nameLow:find("present")) and not nameLow:find("gun") and not nameLow:find("knife") and not nameLow:find("revolver") and not nameLow:find("pistol") then
                        local hasTI = c:FindFirstChild("TouchInterest") or c:FindFirstChildWhichIsA("TouchTransmitter")
                        local isDead = (c:GetAttribute("Collected") == true) or (c:GetAttribute("Delete") == true)
                        if hasTI and not isDead and not (_G.MM2_CoinBlacklist and _G.MM2_CoinBlacklist[c] and (now < _G.MM2_CoinBlacklist[c])) then
                            seen[c] = true
                            table.insert(coins, c)
                        end
                    end
                end
            end
        end

        cachedActiveCoins = coins
        return coins
    end
end

local function getMM2CoinBagInfo()
    local maxCap = (CoinTracker and CoinTracker.Max and CoinTracker.Max > 0) and CoinTracker.Max or Config.MaxCoins or 50
    local bagName = (CoinTracker and CoinTracker.Bag) or "Coin"

    -- In lobby or between rounds, round bag ALWAYS has 0 coins
    if isPlayerInLobby(LocalPlayer) or not isRoundActive() then
        return 0, false, bagName, maxCap
    end

    local isFull = isCoinBagFull()
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    local mg = pg and (pg:FindFirstChild("MainGUI") or pg:FindFirstChild("GameGUI") or pg:FindFirstChild("ScreenGui"))
    if mg then
        local cb = mg:FindFirstChild("CoinBags", true)
        local container = cb and cb:FindFirstChild("Container") or cb
        if container then
            for _, bag in ipairs(container:GetChildren()) do
                if bag:IsA("Frame") and bag.Visible then
                    local curFrame = bag:FindFirstChild("CurrencyFrame") or bag
                    local icon = curFrame and curFrame:FindFirstChild("Icon") or curFrame
                    local coinsLbl = (icon and (icon:FindFirstChild("Coins") or icon:FindFirstChild("Coin") or icon:FindFirstChild("Amount"))) or bag:FindFirstChild("Coins", true) or bag:FindFirstChild("Coin", true)
                    if coinsLbl and coinsLbl:IsA("TextLabel") then
                        local rawText = coinsLbl.Text:match("%d+")
                        local count = tonumber(rawText) or tonumber(coinsLbl.Text) or 0
                        return count, isFull, bag.Name, maxCap
                    end
                end
            end
        end
    end
    if CurrentRoundClient and CurrentRoundClient.PlayerData and CurrentRoundClient.PlayerData[LocalPlayer.Name] then
        local pData = CurrentRoundClient.PlayerData[LocalPlayer.Name]
        if type(pData) == "table" and type(pData.Coins) == "number" and pData.Coins > 0 then
            return pData.Coins, isFull, bagName, maxCap
        end
    end
    return CoinsCollectedThisRound or 0, isFull, bagName, maxCap
end

local function getLocalPlayerCoinBalance()
    local success, val = pcall(function()
        local ProfileData = require(ReplicatedStorage.Modules.ProfileData)
        if ProfileData and ProfileData.Materials and ProfileData.Materials.Owned then
            local c = ProfileData.Materials.Owned.Coins
            if type(c) == "number" then return c end
        end
    end)
    if success and val then return val end

    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local cp = pg:FindFirstChild("CrossPlatform")
        local amt = cp and cp:FindFirstChild("Amount", true)
        if amt and amt:IsA("TextLabel") and amt.Text ~= "" then
            local n = tonumber(amt.Text:gsub("[^%d]", ""))
            if n then return n end
        end
        local mg = pg:FindFirstChild("MainGUI")
        if mg then
            local shop = mg:FindFirstChild("Shop", true)
            local titleCoins = shop and shop:FindFirstChild("Coins", true)
            local shopAmt = titleCoins and titleCoins:FindFirstChild("Amount", true)
            if shopAmt and shopAmt:IsA("TextLabel") and shopAmt.Text ~= "" then
                local n = tonumber(shopAmt.Text:gsub("[^%d]", ""))
                if n then return n end
            end
        end
    end
    return 0
end
_G.MM2_GetCoinBalance = getLocalPlayerCoinBalance

local function getLocalPlayerCandyBalance()
    local success, val = pcall(function()
        local ProfileData = require(ReplicatedStorage.Modules.ProfileData)
        if ProfileData and ProfileData.Materials and ProfileData.Materials.Owned then
            local c = ProfileData.Materials.Owned.Candies2026 or ProfileData.Materials.Owned.Candies
            if type(c) == "number" then return c end
        end
    end)
    if success and val then return val end

    local lp = LocalPlayer
    local cp = lp and lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("CrossPlatform")
    local hw = cp and cp:FindFirstChild("Halloween2026", true)
    local tokens = hw and hw:FindFirstChild("Tokens", true)
    local amt = tokens and tokens:FindFirstChild("Amount", true)
    if amt and amt:IsA("TextLabel") and amt.Text ~= "" then
        local n = tonumber(amt.Text:gsub("[^%d]", ""))
        if n then return n end
    end
    return 0
end
_G.MM2_GetCandyBalance = getLocalPlayerCandyBalance

-- (Game State, isPlayerDead, isPlayerAlive, isRoundActive and recordCoinsCollected moved to top of module)

_G.MM2_GetRoundTimerSeconds = function()
    local rtp = workspace:FindFirstChild("RoundTimerPart")
    local rtpTime = rtp and rtp:GetAttribute("Time")
    if rtpTime and type(rtpTime) == "number" then
        return rtpTime
    end
    return -1
end

local function isMurdererDead()
    if _G.MM2_IsInfectionRound and _G.MM2_IsInfectionRound() then return false end
    if not isRoundActive() then return false end

    -- 1. Locate current murderer (cached or dynamic scan)
    local murd = CachedMurderer
    if not murd or not murd.Parent or not murd.Character then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local foundKnife = false
                for _, cont in ipairs({p.Character, p:FindFirstChild("Backpack")}) do
                    if cont then
                        for _, item in ipairs(cont:GetChildren()) do
                            if item:IsA("Tool") then
                                local n = item.Name:lower()
                                if n:find("knife") or n:find("blade") or n:find("scythe") or n:find("dagger") or n:find("sword") or item:FindFirstChild("KnifeServer") or item:FindFirstChild("Stab") then
                                    foundKnife = true
                                    break
                                end
                            end
                        end
                    end
                    if foundKnife then break end
                end
                if foundKnife then
                    murd = p
                    CachedMurderer = p
                    break
                end
            end
        end
    end

    -- 2. Physical reality check: If murderer is alive in the arena match, they are NOT dead!
    if murd and murd.Parent == Players and murd.Character then
        local mHum = murd.Character:FindFirstChildOfClass("Humanoid")
        local mRoot = murd.Character:FindFirstChild("HumanoidRootPart") or murd.Character:FindFirstChild("Head")
        if mHum and mHum.Health > 0 and mRoot and mRoot.Position.Z > 2500 and mRoot.Position.Y > -50 then
            _G.MM2_MurdererEliminatedThisRound = false
            return false
        end
    end

    -- 3. If murderer died, fell into void, or returned to lobby
    if murd and murd.Parent == Players then
        if isPlayerDead(murd) then return true end
        local mChar = murd.Character
        if not mChar or not mChar.Parent then return true end
        local mHum = mChar:FindFirstChildOfClass("Humanoid")
        local mRoot = mChar:FindFirstChild("HumanoidRootPart") or mChar:FindFirstChild("Head")
        if not mHum or mHum.Health <= 0 then return true end
        if mRoot and (mRoot.Position.Y < -50 or mRoot.Position.Z < 2500) then return true end
    elseif murd and not murd.Parent then
        return true
    end

    -- 4. Check Round PlayerData
    if CurrentRoundClient and CurrentRoundClient.PlayerData then
        local foundMurd = false
        local anyMurdAlive = false
        for pName, pData in pairs(CurrentRoundClient.PlayerData) do
            if type(pData) == "table" and pData.Role == "Murderer" then
                foundMurd = true
                local p = Players:FindFirstChild(pName)
                if p and p.Parent and p.Character then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    local root = p.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and root and root.Position.Z > 2500 and root.Position.Y > -50 and pData.Dead ~= true and pData.Killed ~= true then
                        anyMurdAlive = true
                        break
                    end
                end
            end
        end
        if foundMurd and not anyMurdAlive then
            return true
        end
    end

    if _G.MM2_MurdererEliminatedThisRound then
        return true
    end

    return false
end

-- Helper: Detect Role of any Player (Authoritative, Hero-aware, Tool-aware)
local function isPlayerMurderer(plr)
    if not plr or not plr.Parent then return false end
    if _G.MM2_IsInfectionRound and _G.MM2_IsInfectionRound() then return false end
    if plr == LocalPlayer and _G.MM2_LocalPlayerRole == "Murderer" then
        return true
    end
    if CachedMurderer and CachedMurderer == plr and not isPlayerDead(plr) then
        return true
    end
    if CurrentRoundClient and CurrentRoundClient.PlayerData then
        local pData = CurrentRoundClient.PlayerData[plr.Name]
        if type(pData) == "table" and pData.Role == "Murderer" then
            if plr == LocalPlayer then _G.MM2_LocalPlayerRole = "Murderer" end
            return true
        end
    end
    local function hasKnife(cont)
        if not cont then return false end
        for _, item in ipairs(cont:GetChildren()) do
            if item:IsA("Tool") then
                local n = item.Name:lower()
                if n:find("knife") or n:find("blade") or n:find("scythe") or n:find("dagger") or n:find("sword") then
                    return true
                end
                if item:FindFirstChild("KnifeServer") or item:FindFirstChild("KnifeClient") or item:FindFirstChild("KnifeScript") then
                    return true
                end
                if item:FindFirstChild("Stab") or item:FindFirstChild("Slash") or item:FindFirstChild("Throw") then
                    return true
                end
                if item:FindFirstChild("Events") and item.Events:FindFirstChild("KnifeStabbed") then
                    return true
                end
            end
        end
        return false
    end
    if hasKnife(plr:FindFirstChild("Backpack")) or (plr.Character and hasKnife(plr.Character)) then
        if plr == LocalPlayer then _G.MM2_LocalPlayerRole = "Murderer" end
        return true
    end
    return false
end
_G.MM2_IsPlayerMurderer = isPlayerMurderer

local function detectPlayerRole(plr)
    if not plr or not plr.Parent then return "None" end

    -- 1. If round is not active or player is in lobby, their role is strictly "Lobby"
    if not isRoundActive() or isPlayerInLobby(plr) then
        return "Lobby"
    end

    local curMap = CachedMap or (getCurrentMap and getCurrentMap())
    if not curMap then
        return "Lobby"
    end

    if isPlayerDead(plr) then
        return "Lobby"
    end

    -- Infection Mode Special Roles
    if _G.MM2_IsInfectionRound and _G.MM2_IsInfectionRound() then
        if CurrentRoundClient and CurrentRoundClient.PlayerData then
            local pData = CurrentRoundClient.PlayerData[plr.Name]
            if type(pData) == "table" and pData.Role then
                if pData.Role == "Zombie" then return "Zombie" end
                if pData.Role == "Survivor" then return "Survivor" end
            end
        end
        local hasK = false
        local function scan(cont)
            if not cont then return end
            for _, item in ipairs(cont:GetChildren()) do
                if item:IsA("Tool") then
                    local n = item.Name:lower()
                    if n:find("knife") or n:find("blade") or n:find("scythe") or n:find("dagger") or n:find("claw")
                        or item:FindFirstChild("KnifeServer") or item:FindFirstChild("KnifeClient") or item:FindFirstChild("Stab")
                        or (item:FindFirstChild("Events") and item.Events:FindFirstChild("KnifeStabbed")) then
                        hasK = true
                    end
                end
            end
        end
        pcall(function() scan(plr:FindFirstChild("Backpack")) end)
        pcall(function() scan(plr.Character) end)
        if hasK then return "Zombie" end
        return "Survivor"
    end

    -- Fast-path for Murderer
    if isPlayerMurderer(plr) then
        return "Murderer"
    end

    local hasKnife = false
    local hasGun = false

    local function scan(cont)
        if not cont then return end
        for _, item in ipairs(cont:GetChildren()) do
            if item:IsA("Tool") then
                local n = item.Name:lower()
                if n:find("knife") or n:find("blade") or n:find("scythe") or n:find("dagger") or n:find("sword")
                    or item:FindFirstChild("KnifeServer") or item:FindFirstChild("KnifeClient") or item:FindFirstChild("KnifeScript")
                    or item:FindFirstChild("Stab") or item:FindFirstChild("Slash")
                    or (item:FindFirstChild("Events") and item.Events:FindFirstChild("KnifeStabbed")) then
                    hasKnife = true
                elseif n:find("gun") or n:find("revolver") or n:find("pistol") or n:find("luger")
                    or item:FindFirstChild("Shoot") or item:FindFirstChild("GunServer") or item:FindFirstChild("GunClient") then
                    hasGun = true
                end
            end
        end
    end

    pcall(function() scan(plr:FindFirstChild("Backpack")) end)
    pcall(function() scan(plr.Character) end)

    -- If player has Knife, they are 100% Murderer
    if hasKnife then
        if plr == LocalPlayer then _G.MM2_LocalPlayerRole = "Murderer" end
        return "Murderer"
    end

    -- If player has Gun, differentiate between Sheriff and Hero (Strict Round & Drop Validation)
    if hasGun then
        local origRole = nil
        if CurrentRoundClient and CurrentRoundClient.PlayerData and CurrentRoundClient.PlayerData[plr.Name] then
            origRole = CurrentRoundClient.PlayerData[plr.Name].Role
        end
        if origRole == "Sheriff" then
            return "Sheriff"
        elseif (origRole == "Innocent" or origRole == "Hero") and (GunHasDropped or GunDropAnnounced) and not isPlayerInLobby(plr) and not isMurdererDead() then
            return "Hero" -- An innocent picked up the dropped gun!
        else
            return "Sheriff" -- Fallback: in lobby, post-round or before drop, never classify as Hero
        end
    end

    -- Authoritative initial round check from CurrentRoundClient.PlayerData
    if CurrentRoundClient and CurrentRoundClient.PlayerData then
        local pData = CurrentRoundClient.PlayerData[plr.Name]
        if not pData then
            return "Lobby"
        end
        if type(pData) == "table" then
            if pData.Dead == true or pData.Killed == true then
                return "Lobby"
            end
            local r = pData.Role
            if r and r ~= "" then
                return r
            end
        end
    end

    return "Innocent"
end

-- Helper: Check if LocalPlayer has Gun (or Knife for Murderer) equipped in hand
local function hasWeaponInHand()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            local n = item.Name:lower()
            -- Gun / Revolver
            if n == "gun" or item:FindFirstChild("Shoot") or item:FindFirstChild("GunServer") or item:FindFirstChild("GunClient") then
                return true, "Gun"
            end
            -- Knife (if player is Murderer)
            if (n == "knife" or item:FindFirstChild("KnifeServer") or item:FindFirstChild("KnifeClient")) and detectPlayerRole(LocalPlayer) == "Murderer" then
                return true, "Knife"
            end
        end
    end
    return false, nil
end

local function getAliveInnocentsCount()
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and not isPlayerInLobby(p) and not isPlayerDead(p) then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                count = count + 1
            end
        end
    end
    return count
end
_G.MM2_GetAliveInnocentsCount = getAliveInnocentsCount

-- Helper: Get Silent Aim Target (Murderer targets all alive non-lobby players; Sheriff/Hero targets Murderer)
local function getSilentAimTarget()
    local myRole = detectPlayerRole(LocalPlayer)
    local myRoot = getLocalRoot()
    local myPos = myRoot and myRoot.Position or Vector3.zero
    local mousePos = UserInputService:GetMouseLocation()

    if myRole == "Murderer" or myRole == "Zombie" then
        -- Hostile Mode: Target ALL alive opponents in the match, strictly ignoring Lobby!
        local bestTarget = nil
        local bestScreenDist = math.huge
        local fallbackTarget = nil
        local fallback3DDist = math.huge

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and root then
                    -- Strictly ignore any players in Lobby!
                    if not isPlayerInLobby(plr) then
                        local role = detectPlayerRole(plr)
                        if role ~= "Murderer" and role ~= "Zombie" then
                            -- 3D Distance Fallback
                            local dist3D = (root.Position - myPos).Magnitude
                            if dist3D < fallback3DDist then
                                fallback3DDist = dist3D
                                fallbackTarget = plr
                            end

                            -- Screen / Mouse Cursor Proximity Check (prioritizes crosshair target)
                            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                            if onScreen then
                                local sDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                                if sDist < bestScreenDist then
                                    bestScreenDist = sDist
                                    bestTarget = plr
                                end
                            end
                        end
                    end
                end
            end
        end

        return bestTarget or fallbackTarget
    elseif myRole == "Survivor" then
        -- Survivor Mode: Target nearest or crosshair Zombie
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and root and not isPlayerInLobby(plr) then
                    if detectPlayerRole(plr) == "Zombie" then
                        return plr
                    end
                end
            end
        end
        return nil
    else
        -- Non-Murderer (Sheriff, Hero, Innocent with gun): Target Murderer
        if CachedMurderer and CachedMurderer.Character then
            local hum = CachedMurderer.Character:FindFirstChildOfClass("Humanoid")
            local root = CachedMurderer.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                local inLobby = isPlayerInLobby(CachedMurderer)
                local curMap = CachedMap or getCurrentMap()
                if not curMap or not inLobby then
                    return CachedMurderer
                end
            end
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and root then
                    if detectPlayerRole(plr) == "Murderer" then
                        CachedMurderer = plr
                        local inLobby = isPlayerInLobby(plr)
                        local curMap = CachedMap or getCurrentMap()
                        if not curMap or not inLobby then
                            return plr
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- Helper: Advanced Movement Prediction with Dynamic Lead, Dual-Source Ping & Jump Parabola
local function getPredictedPosition(targetPart, myOriginPos, customSpeed)
    if not targetPart then return Vector3.zero end
    local basePos = targetPart.Position
    if not Config.PredictMovement then return basePos end

    local char = targetPart.Parent
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local vel = targetPart.AssemblyLinearVelocity or Vector3.zero

    -- 1. Intention-Based Velocity Blending (Humanoid.MoveDirection)
    -- When a player turns or changes strafe direction, AssemblyLinearVelocity has momentum delay.
    -- MoveDirection represents their real-time input intent.
    if hum and hum.MoveDirection.Magnitude > 0.05 then
        local walkSpeed = hum.WalkSpeed
        if not walkSpeed or walkSpeed <= 0 then walkSpeed = 16 end
        local intent = hum.MoveDirection * walkSpeed
        -- Blend 65% input intent + 35% physics momentum on XZ plane
        vel = Vector3.new(
            intent.X * 0.65 + vel.X * 0.35,
            vel.Y,
            intent.Z * 0.65 + vel.Z * 0.35
        )
    end

    local originPos = myOriginPos or (getLocalRoot() and getLocalRoot().Position or Vector3.zero)
    local dist = (basePos - originPos).Magnitude
    local bulletSpeed = customSpeed or Config.PredictionBulletSpeed or 320
    local travelTime = dist / bulletSpeed

    -- 2. Dual-Source Network Ping Compensation (LocalPlayer:GetNetworkPing + Stats fallback)
    local pingSeconds = 0.06
    if Config.PredictionPingCompensation ~= false then
        pcall(function()
            if LocalPlayer.GetNetworkPing then
                local p = LocalPlayer:GetNetworkPing()
                if type(p) == "number" and p > 0.005 and p < 1.2 then
                    pingSeconds = p
                end
            end
        end)
        if pingSeconds == 0.06 then
            pcall(function()
                local sStats = game:GetService("Stats").Network.ServerStatsItem
                local pingItem = sStats and sStats:FindFirstChild("Data Ping")
                if pingItem then
                    local val = pingItem:GetValue()
                    if val and val > 0 then
                        pingSeconds = math.clamp(val / 1000, 0.015, 0.60)
                    end
                end
            end)
        end
    else
        pingSeconds = 0
    end

    local pingMult = tonumber(Config.PredictionPingMultiplier) or 1.15
    local totalLeadTime = travelTime + (pingSeconds * pingMult)

    -- 3. Horizontal Displacement & Wall Raycast Prevention
    local leadX = vel.X * totalLeadTime
    local leadZ = vel.Z * totalLeadTime
    local horizontalOffset = Vector3.new(leadX, 0, leadZ)

    -- If target is running into a wall or corner, don't project them inside solid geometry!
    if horizontalOffset.Magnitude > 0.5 then
        local wallRayParams = RaycastParams.new()
        wallRayParams.FilterDescendantsInstances = { char, LocalPlayer.Character }
        wallRayParams.FilterType = Enum.RaycastFilterType.Exclude
        wallRayParams.IgnoreWater = true

        local wallHit = workspace:Raycast(basePos, horizontalOffset, wallRayParams)
        if wallHit then
            local hitDist = math.max(0, wallHit.Distance - 0.4)
            horizontalOffset = (horizontalOffset.Magnitude > 0.001) and (horizontalOffset.Unit * hitDist) or Vector3.zero
        end
    end

    -- 4. Parabolic Jump, Apex & Fall Gravity Physics
    local leadY = 0
    local grav = workspace.Gravity or 196.2
    local humState = hum and hum:GetState()

    local isAirborne = (humState == Enum.HumanoidStateType.Jumping)
        or (humState == Enum.HumanoidStateType.Freefall)
        or (math.abs(vel.Y) > 2.5)

    if isAirborne then
        -- Full kinematic formula: Y(t) = V_y * t - 0.5 * g * t^2
        leadY = (vel.Y * totalLeadTime) - (0.5 * grav * (totalLeadTime ^ 2))

        -- Ground collision clamp: a player cannot fall through the floor!
        local floorRayParams = RaycastParams.new()
        floorRayParams.FilterDescendantsInstances = { char, LocalPlayer.Character }
        floorRayParams.FilterType = Enum.RaycastFilterType.Exclude
        floorRayParams.IgnoreWater = true

        local floorCheck = workspace:Raycast(basePos, Vector3.new(0, -30, 0), floorRayParams)
        if floorCheck then
            local floorY = floorCheck.Position.Y + (targetPart.Size.Y * 0.5)
            local predictedY = basePos.Y + leadY
            if predictedY < floorY then
                leadY = floorY - basePos.Y
            end
        end
    else
        leadY = 0
    end

    -- 5. Safety bounds
    local finalOffset = Vector3.new(horizontalOffset.X, leadY, horizontalOffset.Z)
    local maxOffset = 36
    if finalOffset.Magnitude > maxOffset then
        finalOffset = finalOffset.Unit * maxOffset
    end

    return basePos + finalOffset
end

-- Helper: Raycast Wall Check (Line of Sight with Penetration)
local function hasLineOfSight(fromPos, toPos, targetChar)
    local rayParams = RaycastParams.new()
    local ignoreList = { LocalPlayer.Character }
    if targetChar then table.insert(ignoreList, targetChar) end
    if CachedMap and CachedMap:FindFirstChild("CoinContainer") then
        table.insert(ignoreList, CachedMap.CoinContainer)
    end
    pcall(function()
        local cs = game:GetService("CollectionService")
        for _, obj in ipairs(cs:GetTagged("WeaponPassthrough")) do
            table.insert(ignoreList, obj)
        end
    end)
    rayParams.FilterDescendantsInstances = ignoreList
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true

    local curOrigin = fromPos
    for _ = 1, 8 do
        local dir = toPos - curOrigin
        if dir.Magnitude < 0.5 then return true end
        local hit = workspace:Raycast(curOrigin, dir, rayParams)
        if not hit then
            return true
        end
        if hit.Instance and (hit.Instance.Transparency >= 0.5 or not hit.Instance.CanCollide) then
            table.insert(ignoreList, hit.Instance)
            rayParams.FilterDescendantsInstances = ignoreList
            curOrigin = hit.Position + dir.Unit * 0.1
        else
            return false
        end
    end
    return false
end

-- ====================================================================
-- 🎯 SILENT AIM HOOK (WeaponService)
-- ====================================================================
pcall(function()
    local WeaponService = require(ReplicatedStorage:WaitForChild("ClientServices"):WaitForChild("WeaponService"))
    if not _G.MM2_WS_OrigMouseTarget then
        _G.MM2_WS_OrigMouseTarget = WeaponService.GetMouseTargetCFrame
    end
    WeaponService.GetMouseTargetCFrame = function(self, ...)
        if Config.SilentAim then
            local target = nil
            pcall(function()
                target = getHoveredVictim() or getSilentAimTarget()
            end)
            if target and target.Character then
                local mRoot = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("UpperTorso") or target.Character:FindFirstChild("Head")
                if mRoot then
                    local myRoot = getLocalRoot()
                    local myPos = myRoot and myRoot.Position or Vector3.zero
                    local targetPos = getPredictedPosition(mRoot, myPos)
                    if Config.SilentAimWallBang or Config.WallBang or not Config.WallCheck or hasLineOfSight(myPos, targetPos, target.Character) then
                        return CFrame.new(targetPos)
                    end
                end
            end
        end
        return _G.MM2_WS_OrigMouseTarget(self, ...)
    end

    if not _G.MM2_WS_OrigTargetPos then
        _G.MM2_WS_OrigTargetPos = WeaponService.GetTargetPosition
    end
    if _G.MM2_WS_OrigTargetPos then
        WeaponService.GetTargetPosition = function(self, ...)
            if Config.SilentAim then
                local target = nil
                pcall(function()
                    target = getHoveredVictim() or getSilentAimTarget()
                end)
                if target and target.Character then
                    local mRoot = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("UpperTorso") or target.Character:FindFirstChild("Head")
                    if mRoot then
                        local myRoot = getLocalRoot()
                        local myPos = myRoot and myRoot.Position or Vector3.zero
                        local targetPos = getPredictedPosition(mRoot, myPos)
                        if Config.SilentAimWallBang or Config.WallBang or not Config.WallCheck or hasLineOfSight(myPos, targetPos, target.Character) then
                            return CFrame.new(targetPos)
                        end
                    end
                end
            end
            return _G.MM2_WS_OrigTargetPos(self, ...)
        end
    end
end)

-- Metamethod Hook for Mouse.Hit and Mouse.Target (Direct Knife Throw redirection)
pcall(function()
    if hookmetamethod and not _G.MM2_Mouse_Hooked then
        _G.MM2_Mouse_Hooked = true
        local oldIndex = nil
        oldIndex = hookmetamethod(game, "__index", function(self, key)
            if not checkcaller() and Config.SilentAim and typeof(self) == "Instance" and self:IsA("Mouse") then
                if key == "Hit" or key == "Target" then
                    local target = getSilentAimTarget()
                    if target and target.Character then
                        local tRoot = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Head")
                        if tRoot then
                            local myRoot = getLocalRoot()
                            local myPos = myRoot and myRoot.Position or Vector3.zero
                            local targetPos = getPredictedPosition(tRoot, myPos)
                            if Config.SilentAimWallBang or not Config.WallCheck or hasLineOfSight(myPos, targetPos, target.Character) then
                                if key == "Hit" then
                                    return CFrame.new(targetPos)
                                elseif key == "Target" then
                                    return tRoot
                                end
                            end
                        end
                    end
                end
            end
            return oldIndex(self, key)
        end)
    end
end)

-- Metamethod Hook for KnifeThrown and KnifeStabbed (Universal WallBang & Silent Aim for Knife)
_G.MM2_Namecall_Handler = function(oldNamecall, self, method, ...)
    -- 🛡️ Anti-Kick Protection (Bypass for "Invalid Position" & client anti-cheat kicks)
    if method == "Kick" or method == "kick" then
        local reason = tostring(...)
        warn("[MM2 Anti-Kick Protected]: Blocked attempt to kick LocalPlayer! Reason: " .. tostring(reason))
        pcall(function()
            if _G.MM2_ShowDynamicIslandNotification then
                _G.MM2_ShowDynamicIslandNotification("🛡️ Anti-Kick Protected", "Blocked Kick: " .. tostring(reason), 4)
            end
        end)
        return nil
    end

    if not checkcaller() and (method == "FireServer" or method == "fireServer") then
        if self and (self.Name == "KnifeThrown") then
            if Config.SilentAim then
                local myRole = detectPlayerRole(LocalPlayer)
                local target = nil
                local myRoot = getLocalRoot()
                local myPos = myRoot and myRoot.Position or Vector3.zero

                if myRole == "Murderer" or self.Name == "KnifeThrown" then
                    target = getHoveredVictim() or getSilentAimTarget()
                    if not target then
                        local closestDist = math.huge
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character and not isPlayerInLobby(p) then
                                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                                local root = p.Character:FindFirstChild("HumanoidRootPart")
                                if hum and hum.Health > 0 and root then
                                    local d = (root.Position - myPos).Magnitude
                                    if d < closestDist then
                                        closestDist = d
                                        target = p
                                    end
                                end
                            end
                        end
                    end
                end

                if target and target.Character then
                    local tRoot = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("UpperTorso") or target.Character:FindFirstChild("Head")
                    if tRoot then
                        local targetPos = getPredictedPosition(tRoot, myPos, 96)
                        local isWallBang = (Config.SilentAimWallBang or Config.WallBang)
                        local hasLOS = hasLineOfSight(myPos, targetPos, target.Character)
                        local canShoot = not Config.WallCheck or isWallBang or hasLOS

                        if canShoot then
                            local args = {...}
                            local dir = (targetPos - myPos).Magnitude > 0.01 and (targetPos - myPos).Unit or Vector3.new(0, 0, -1)
                            if not hasLOS and isWallBang and myRoot then
                                -- TRUE ZERO-TELEPORT WALLBANG: Direct origin placement in front of target
                                local offset = math.clamp(tonumber(Config.WallPenetrationOffset) or 0.8, 0.1, 2.0)
                                args[1] = CFrame.lookAt(targetPos - (dir * offset), targetPos)
                                args[2] = targetPos
                                if setnamecallmethod then setnamecallmethod(method) end
                                return oldNamecall(self, table.unpack(args))
                            else
                                args[1] = myRoot and myRoot.CFrame or CFrame.lookAt(targetPos - dir * 1.5, targetPos)
                                args[2] = targetPos
                                if setnamecallmethod then setnamecallmethod(method) end
                                return oldNamecall(self, table.unpack(args))
                            end
                        end
                    end
                end
            end
            if setnamecallmethod then
                setnamecallmethod(method)
            end
            return oldNamecall(self, ...)
        elseif self and (self.Name == "Shoot" or self.Name == "shoot") then
            if Config.SilentAim or Config.SilentAimWallBang or Config.WallBang then
                local target = getHoveredVictim() or getSilentAimTarget()
                local myRoot = getLocalRoot()
                local myPos = myRoot and myRoot.Position or Vector3.zero
                if not target then
                    local closestDist = math.huge
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and not isPlayerInLobby(p) then
                            local hum = p.Character:FindFirstChildOfClass("Humanoid")
                            local root = p.Character:FindFirstChild("HumanoidRootPart")
                            if hum and hum.Health > 0 and root then
                                local r = detectPlayerRole(p)
                                if r == "Murderer" then
                                    target = p
                                    break
                                end
                                local d = (root.Position - myPos).Magnitude
                                if d < closestDist then
                                    closestDist = d
                                    target = p
                                end
                            end
                        end
                    end
                end

                if target and target.Character then
                    local tRoot = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("UpperTorso") or target.Character:FindFirstChild("Head")
                    if tRoot then
                        local targetPos = getPredictedPosition(tRoot, myPos, 96)
                        local isWallBang = (Config.SilentAimWallBang or Config.WallBang)
                        local hasLOS = hasLineOfSight(myPos, targetPos, target.Character)
                        local canShoot = not Config.WallCheck or isWallBang or hasLOS

                        if canShoot then
                            local args = {...}
                            local dir = (targetPos - myPos).Magnitude > 0.01 and (targetPos - myPos).Unit or Vector3.new(0, 0, -1)
                            if not hasLOS and isWallBang and myRoot then
                                -- TRUE ZERO-TELEPORT WALLBANG: Direct ray origin placement past any wall (0 character movement)
                                local offset = math.clamp(tonumber(Config.WallPenetrationOffset) or 0.8, 0.1, 2.0)
                                args[1] = CFrame.lookAt(targetPos - (dir * offset), targetPos)
                                args[2] = CFrame.new(targetPos)
                                if setnamecallmethod then setnamecallmethod(method) end
                                return oldNamecall(self, table.unpack(args))
                            else
                                local att = myRoot and myRoot:FindFirstChild("GunRaycastAttachment")
                                args[1] = att and att.WorldCFrame or (myRoot and myRoot.CFrame)
                                args[2] = CFrame.new(targetPos)
                                if setnamecallmethod then setnamecallmethod(method) end
                                return oldNamecall(self, table.unpack(args))
                            end
                        end
                    end
                end
            end
            if setnamecallmethod then
                setnamecallmethod(method)
            end
            return oldNamecall(self, ...)
        elseif self and (self.Name == "KnifeStabbed") then
            if _G.MM2_IsThrowingKnife then
                return nil
            end
            pcall(function()
                local char = LocalPlayer.Character
                local knife = char and char:FindFirstChild("Knife")
                local events = knife and knife:FindFirstChild("Events")
                local touchEv = events and events:FindFirstChild("HandleTouched")
                local handle = knife and knife:FindFirstChild("Handle")
                if touchEv and char then
                    local myRoot = char:FindFirstChild("HumanoidRootPart")
                    local myPos = myRoot and myRoot.Position or Vector3.zero
                    local bestPart = nil
                    local bestDist = 28
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Character and not isPlayerInLobby(plr) then
                            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                            local root = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Head")
                            if hum and hum.Health > 0 and root then
                                local d = (root.Position - myPos).Magnitude
                                if d < bestDist then
                                    bestDist = d
                                    bestPart = root
                                end
                            end
                        end
                    end
                    if bestPart and handle then
                        touchEv:FireServer(bestPart, handle)
                    end
                end
            end)
        end
    end
    if setnamecallmethod then
        setnamecallmethod(method)
    end
    return oldNamecall(self, ...)
end

-- Hook __namecall metamethod reliably across all executors
pcall(function()
    if hookmetamethod and not _G.MM2_Namecall_Hooked then
        _G.MM2_Namecall_Hooked = true
        local oldNamecall = nil
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod and getnamecallmethod() or ""
            if _G.MM2_Namecall_Handler then
                return _G.MM2_Namecall_Handler(oldNamecall, self, method, ...)
            end
            if setnamecallmethod then
                setnamecallmethod(method)
            end
            return oldNamecall(self, ...)
        end)
    end
end)

-- Direct Kick hookfunction protection
pcall(function()
    if hookfunction and not _G.MM2_Kick_Hooked then
        _G.MM2_Kick_Hooked = true
        local oldKick = nil
        oldKick = hookfunction(game.Players.LocalPlayer.Kick, function(self, ...)
            local reason = tostring(...)
            warn("[MM2 Anti-Kick Protected]: Blocked direct LocalPlayer:Kick! Reason: " .. tostring(reason))
            pcall(function()
                if _G.MM2_ShowDynamicIslandNotification then
                    _G.MM2_ShowDynamicIslandNotification("🛡️ Anti-Kick Protected", "Blocked Kick: " .. tostring(reason), 4)
                end
            end)
            return nil
        end)
    end
end)


local function shootMurderer(isManual)
    if not isManual and Config.AutoShot ~= true then
        return false, "Auto-Shot is disabled"
    end
    if not isRoundActive() or isPlayerInLobby(LocalPlayer) or _G.MM2_LocalPlayerDiedThisRound or isPlayerDead(LocalPlayer) then
        return false, "Cannot shoot while dead or in lobby"
    end

    local myRole = detectPlayerRole(LocalPlayer)
    if myRole == "Murderer" or myRole == "Lobby" then
        return false, "Cannot shoot as Murderer or Lobby"
    end

    local myRole = detectPlayerRole(LocalPlayer)
    if myRole == "Murderer" then
        return false, "Cannot shoot as Murderer"
    end

    local target = getSilentAimTarget()
    if not target or not target.Character then
        if CachedMurderer and CachedMurderer.Character then
            target = CachedMurderer
        else
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and detectPlayerRole(p) == "Murderer" then
                    target = p
                    CachedMurderer = p
                    break
                end
            end
        end
    end

    if not target or not target.Character then
        if isManual then
            local closestDist = math.huge
            local myPos = getLocalRoot() and getLocalRoot().Position or Vector3.zero
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    local root = p.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and root then
                        local d = (root.Position - myPos).Magnitude
                        if d < closestDist then
                            closestDist = d
                            target = p
                        end
                    end
                end
            end
        end
    end

    if not target or not target.Character then return false, "No target found" end

    local mHum = target.Character:FindFirstChildOfClass("Humanoid")
    if mHum and mHum.Health <= 0 then return false, "Murderer is dead" end

    local mRoot = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("UpperTorso") or target.Character:FindFirstChild("Head")
    if not mRoot then return false, "No target root" end

    local char = LocalPlayer.Character
    if not char then return false, "No character" end

    -- Check and auto-equip Gun from Character or Backpack (supports any skin/name)
    local gun, isEquipped = _G.MM2_GetLocalGunTool and _G.MM2_GetLocalGunTool()
    if gun and not isEquipped and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid"):EquipTool(gun)
        task.wait(0.06)
    end
    if not gun then
        return false, "Gun not equipped (Pick up Gun first)"
    end

    local shootEvent = gun:FindFirstChild("Shoot") or gun:FindFirstChild("shoot")
    if not shootEvent then return false, "Shoot remote not found on Gun" end

    local myRoot = char:FindFirstChild("HumanoidRootPart") or getLocalRoot()
    if not myRoot then return false, "No character root" end
    local att = myRoot:FindFirstChild("GunRaycastAttachment")
    local origin = att and att.WorldCFrame or myRoot.CFrame

    local targetPos = getPredictedPosition(mRoot, origin.Position)

    -- Wall Check (Auto-Shot and WallBang automatically pierce all walls)
    local isWallBang = (Config.SilentAimWallBang or Config.WallBang or Config.WallBangAllMap) or (isManual == true) or (Config.AutoShot == true)
    local hasLOS = hasLineOfSight(origin.Position, targetPos, target.Character)
    if not hasLOS and not isWallBang and Config.WallCheck and not isManual and not Config.AutoShot then
        return false, "Target behind wall (Enable WallBang to bypass)"
    end

    local shootOrigin = origin
    if not hasLOS and isWallBang then
        -- TRUE ZERO-TELEPORT WALLBANG:
        -- Project bullet ray origin directly to target surface, piercing all walls/floors with 0 character movement!
        local dir = (targetPos - origin.Position).Magnitude > 0.01 and (targetPos - origin.Position).Unit or Vector3.new(0, 0, -1)
        local offset = math.clamp(tonumber(Config.WallPenetrationOffset) or 0.8, 0.1, 2.0)
        shootOrigin = CFrame.lookAt(targetPos - (dir * offset), targetPos)
    end

    -- Authoritative Gun Shoot Dispatch (Zero-Teleport WallBang):
    -- MM2 Gun expects (GunRaycastAttachment.WorldCFrame, TargetCFrame)
    local targetCFrame = CFrame.new(targetPos)
    pcall(function()
        shootEvent:FireServer(shootOrigin, targetCFrame)
    end)
    if _G.MM2_SpawnBulletTracer then
        pcall(function()
            _G.MM2_SpawnBulletTracer(shootOrigin.Position, targetPos)
        end)
    end

    -- Play client animations and gunshot sound
    pcall(function()
        local anims = gun:FindFirstChild("Animations")
        local shootAnim = anims and anims:FindFirstChild("Shoot")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if shootAnim and hum then
            hum:LoadAnimation(shootAnim):Play()
        end
    end)
    pcall(function()
        local snd = gun:FindFirstChild("Gunshot") or (gun:FindFirstChild("Sounds") and gun.Sounds:FindFirstChild("Shoot"))
        if snd then snd:Play() end
    end)
    _G.MM2_LastShotTarget = target
    _G.MM2_LastShotTime = tick()

    if target and (target == CachedMurderer or detectPlayerRole(target) == "Murderer") then
        task.delay(0.2, function()
            if isMurdererDead() or (CachedMurderer and isPlayerDead(CachedMurderer)) then
                _G.MM2_MurdererEliminatedThisRound = true
                if _G.MM2_OnMurdererEliminated then _G.MM2_OnMurdererEliminated() end
            end
        end)
    end

    if isManual then
        if showNotification then
            showNotification("💥 SHOT FIRED!", string.format("Bullet fired directly at Murderer (%s)!", target.Name), Color3.fromRGB(50, 220, 100), "💥", 2)
        end
        if flashDynamicIslandAlert then
            flashDynamicIslandAlert("💥 SHOT FIRED AT " .. target.Name:upper(), Color3.fromRGB(50, 220, 100), 2.0)
        end
    end

    return true, "Shot fired successfully"
end


local function grabGun()
    if not isRoundActive() then return false end
    if isPlayerInLobby(LocalPlayer) then return false end
    if _G.MM2_LocalPlayerDiedThisRound or isPlayerDead(LocalPlayer) then return false end
    if not isLocalPlayerPlayingInRound() then return false end

    -- STRICT GUARD: Murderers can NEVER pick up a gun in MM2!
    if isPlayerMurderer(LocalPlayer) or (_G.MM2_LocalPlayerRole == "Murderer") or (detectPlayerRole(LocalPlayer) == "Murderer") then
        return false, "Murderer cannot pick up gun"
    end

    -- If player already has gun, do not grab
    if playerHasGun and playerHasGun() then
        return false, "Already has gun"
    end

    local gunDrop = getGunDrop()
    if not gunDrop or not gunDrop.Parent then return false end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return false end

    local gPos = gunDrop.Position
    hrp.CFrame = CFrame.new(gPos + Vector3.new(0, 1.0, 0))
    if firetouchinterest then
        pcall(function()
            firetouchinterest(hrp, gunDrop, 0)
            firetouchinterest(gunDrop, hrp, 0)
            task.wait(0.08)
            firetouchinterest(hrp, gunDrop, 1)
            firetouchinterest(gunDrop, hrp, 1)
        end)
    end
    task.wait(0.12)
    return true
end

-- ====================================================================
-- 🗡️ MURDERER LONG-RANGE KNIFE STRIKE ENGINE
-- ====================================================================
local function getHoveredVictim()
    local myRole = detectPlayerRole(LocalPlayer)
    if myRole ~= "Murderer" then return nil end
    if isPlayerInLobby(LocalPlayer) then return nil end

    local mousePos = UserInputService:GetMouseLocation()
    local myRoot = getLocalRoot()
    local myPos = myRoot and myRoot.Position or Vector3.zero

    -- 1. Direct 3D Raycast under cursor
    local mouseRay = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    if LocalPlayer.Character then
        rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    end
    local rayRes = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 5000, rayParams)
    if rayRes and rayRes.Instance then
        local model = rayRes.Instance:FindFirstAncestorOfClass("Model")
        local plr = Players:GetPlayerFromCharacter(model)
        if plr and plr ~= LocalPlayer and plr.Character and not isPlayerInLobby(plr) then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                return plr
            end
        end
    end

    -- 2. 2D Screen proximity to cursor (within 240px radius)
    local bestPlr = nil
    local bestDist = 240

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and not isPlayerInLobby(plr) then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local sDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if sDist < bestDist then
                        bestDist = sDist
                        bestPlr = plr
                    end
                end
            end
        end
    end

    return bestPlr
end

local function ensureKnifeEquipped()
    local char = LocalPlayer.Character
    if not char then return nil end

    -- Check character for knife
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then
            local n = t.Name:lower()
            if n:find("knife") or n:find("blade") or n:find("scythe") or n:find("dagger") or n:find("sword")
                or t:FindFirstChild("KnifeServer") or t:FindFirstChild("KnifeClient") or t:FindFirstChild("KnifeScript")
                or t:FindFirstChild("Stab") or t:FindFirstChild("Slash")
                or (t:FindFirstChild("Events") and t.Events:FindFirstChild("KnifeStabbed")) then
                return t
            end
        end
    end

    if Config.KnifeAutoEquip ~= false then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            local knifeTool = nil
            for _, t in ipairs(backpack:GetChildren()) do
                if t:IsA("Tool") then
                    local n = t.Name:lower()
                    if n:find("knife") or n:find("blade") or n:find("scythe") or n:find("dagger") or n:find("sword")
                        or t:FindFirstChild("KnifeServer") or t:FindFirstChild("KnifeClient") or t:FindFirstChild("KnifeScript")
                        or t:FindFirstChild("Stab") or t:FindFirstChild("Slash")
                        or (t:FindFirstChild("Events") and t.Events:FindFirstChild("KnifeStabbed")) then
                        knifeTool = t
                        break
                    end
                end
            end
            if knifeTool then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:EquipTool(knifeTool)
                    local waited = 0
                    while knifeTool.Parent ~= char and waited < 0.2 do
                        waited = waited + task.wait(0.02)
                    end
                    return knifeTool
                end
            end
        end
    end
    return nil
end

local function performLongRangeKnifeStrike(specificTarget)
    local myRole = detectPlayerRole(LocalPlayer)
    if myRole ~= "Murderer" then
        showNotification("⚠️ NOT MURDERER", "Long-Range Strike is only available for Murderer role!", Color3.fromRGB(255, 70, 70), "🗡️", 2.5)
        return false, "Not Murderer"
    end

    if isPlayerInLobby(LocalPlayer) then
        showNotification("⚠️ IN LOBBY", "Cannot strike players while in Lobby!", Color3.fromRGB(255, 180, 50), "🗡️", 2.5)
        return false, "In Lobby"
    end

    local target = specificTarget or getHoveredVictim() or getSilentAimTarget()
    if not target or not target.Character then
        showNotification("⚠️ NO TARGET", "Hover cursor over an Innocent or Sheriff to lock!", Color3.fromRGB(255, 180, 50), "🎯", 2.5)
        return false, "No target found"
    end

    local tHum = target.Character:FindFirstChildOfClass("Humanoid")
    local tRoot = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Head")
    if not tHum or tHum.Health <= 0 or not tRoot then
        return false, "Target is dead"
    end

    local char = LocalPlayer.Character
    local myRoot = getLocalRoot()
    if not myRoot then return false, "No character root" end

    local knife = ensureKnifeEquipped()
    if not knife then
        showNotification("⚠️ NO KNIFE", "Knife not found in Backpack or Character!", Color3.fromRGB(255, 70, 70), "🗡️", 2.5)
        return false, "No knife equipped"
    end

    local handle = knife:FindFirstChild("Handle")
    local events = knife:FindFirstChild("Events")
    local touchEv = events and events:FindFirstChild("HandleTouched")
    local stabEv = events and events:FindFirstChild("KnifeStabbed")
    local dist = math.floor((tRoot.Position - myRoot.Position).Magnitude)

    if Config.KnifeReachBlink ~= false then
        -- Micro-blink (0.04s flick TP) so MM2 server validates physical contact
        local origCFrame = myRoot.CFrame
        myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1.8)

        pcall(function() knife:Activate() end)
        if touchEv then
            pcall(function() touchEv:FireServer(tRoot) end)
            local tHead = target.Character:FindFirstChild("Head")
            if tHead then pcall(function() touchEv:FireServer(tHead) end) end
        end
        if stabEv then
            pcall(function() stabEv:FireServer("Slash") end)
            pcall(function() stabEv:FireServer() end)
        end
        if firetouchinterest and handle then
            pcall(function()
                firetouchinterest(handle, tRoot, 0)
                task.wait()
                firetouchinterest(handle, tRoot, 1)
            end)
        end

        task.wait(0.04)
        if myRoot and myRoot.Parent then
            myRoot.CFrame = origCFrame
        end
    else
        pcall(function() knife:Activate() end)
        if touchEv then
            pcall(function() touchEv:FireServer(tRoot) end)
            local tHead = target.Character:FindFirstChild("Head")
            if tHead then pcall(function() touchEv:FireServer(tHead) end) end
        end
        if stabEv then
            pcall(function() stabEv:FireServer("Slash") end)
            pcall(function() stabEv:FireServer() end)
        end
        if firetouchinterest and handle then
            pcall(function()
                firetouchinterest(handle, tRoot, 0)
                task.wait()
                firetouchinterest(handle, tRoot, 1)
            end)
        end
    end

    if _G.MM2_TriggerLocalHitmarker then
        _G.MM2_TriggerLocalHitmarker(target, false)
    end

    showNotification("🗡️ LONG-RANGE STRIKE!", string.format("Struck %s across %dm!", target.Name, dist), Color3.fromRGB(255, 45, 60), "🗡️", 2.5)
    if flashDynamicIslandAlert then
        flashDynamicIslandAlert(string.format("🗡️ STRUCK %s (%dm)", target.Name:upper(), dist), Color3.fromRGB(255, 45, 60), 2.0)
    end
    return true
end

-- ====================================================================
-- 🎯 MURDERER SILENT AIM KNIFE THROW ENGINE
-- ====================================================================
local lastKnifeThrowTime = 0
local function throwKnifeAtTarget(isManual)
    if isManual and os.clock() - lastKnifeThrowTime < 0.6 then
        return false, "Knife on cooldown"
    end

    local char = LocalPlayer.Character
    if not char then return false, "No character" end

    local knife = ensureKnifeEquipped()
    if not knife then
        if isManual then
            showNotification("⚠️ NO KNIFE", "Knife not found in Backpack or Character!", Color3.fromRGB(255, 70, 70), "🗡️", 2.5)
        end
        return false, "No knife equipped"
    end

    local events = knife:FindFirstChild("Events")
    local throwEvent = events and events:FindFirstChild("KnifeThrown")
    if not throwEvent then return false, "KnifeThrown remote not found" end

    local handle = knife:FindFirstChild("Handle")
    local myRoot = char:FindFirstChild("HumanoidRootPart") or getLocalRoot()
    local origin = handle and handle.CFrame or (myRoot and myRoot.CFrame or workspace.CurrentCamera.CFrame)

    local target = getHoveredVictim() or getSilentAimTarget()
    if not target or not target.Character then
        local closestDist = math.huge
        local myPos = origin.Position
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not isPlayerInLobby(p) then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and root then
                    local d = (root.Position - myPos).Magnitude
                    if d < closestDist then
                        closestDist = d
                        target = p
                    end
                end
            end
        end
    end

    local targetPos = nil
    local hasLOS = false
    local isWallBang = (Config.SilentAimWallBang or Config.WallBang)
    if target and target.Character then
        local tRoot = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("UpperTorso") or target.Character:FindFirstChild("Head")
        if tRoot then
            targetPos = getPredictedPosition(tRoot, origin.Position, 96)
            hasLOS = hasLineOfSight(origin.Position, targetPos, target.Character)
            if Config.WallCheck and not isWallBang and not hasLOS then
                return false, "Target behind wall (Enable WallBang to bypass)"
            end
        end
    end

    if not targetPos then
        pcall(function()
            local ws = _G.MM2_WeaponService or require(game:GetService("ReplicatedStorage"):WaitForChild("ClientServices"):WaitForChild("WeaponService"))
            if ws and ws.GetMouseTargetCFrame then
                local cf = ws:GetMouseTargetCFrame()
                if cf and cf.Position then
                    targetPos = cf.Position
                end
            end
        end)
    end

    if not targetPos then
        local mousePos = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        targetPos = ray.Origin + ray.Direction * 300
    end

    lastKnifeThrowTime = os.clock()
    _G.MM2_IsThrowingKnife = true
    task.delay(0.6, function()
        _G.MM2_IsThrowingKnife = false
    end)

    local throwOrigin = origin
    if targetPos and not hasLOS and isWallBang then
        local dir = (targetPos - origin.Position).Magnitude > 0.01 and (targetPos - origin.Position).Unit or Vector3.new(0, 0, -1)
        throwOrigin = CFrame.lookAt(targetPos - dir * 1.5, targetPos)
    end

    local targetCFrame = CFrame.new(targetPos)
    pcall(function()
        throwEvent:FireServer(throwOrigin, targetCFrame)
    end)

    pcall(function()
        local sounds = knife:FindFirstChild("Sounds")
        local throwSound = sounds and sounds:FindFirstChild("Throw")
        if throwSound then throwSound:Play() end
    end)

    pcall(function()
        local kClient = knife:FindFirstChild("KnifeClient")
        local throwAnim = (kClient and kClient:FindFirstChild("ThrowKnife")) or knife:FindFirstChild("ThrowKnife")
        local hum = char:FindFirstChildOfClass("Humanoid")
        local animator = hum and (hum:FindFirstChildOfClass("Animator") or hum)
        if throwAnim and animator then
            animator:LoadAnimation(throwAnim):Play(0.1, 6, 1)
        end
    end)

    if isManual and target then
        showNotification("🗡️ KNIFE THROWN!", string.format("Knife thrown directly at %s!", target.Name), Color3.fromRGB(255, 60, 80), "🗡️", 2)
        if flashDynamicIslandAlert then
            flashDynamicIslandAlert("🗡️ KNIFE THROWN AT " .. target.Name:upper(), Color3.fromRGB(255, 60, 80), 2.0)
        end
    end

    return true, "Knife thrown successfully"
end

-- ====================================================================
-- 🎨 MODERN GLASS GUI
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_Potassium_Hub_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = container

-- ====================================================================
-- 🏝️ SLEEK DYNAMIC ISLAND (OS Time, Roles & Dynamic Alerts)
-- ====================================================================
local DynamicIsland = Instance.new("Frame")
DynamicIsland.Name = "DynamicIsland"
DynamicIsland.Size = UDim2.new(0, Config.IslandWidth or 430, 0, Config.IslandHeight or 34)
DynamicIsland.Position = UDim2.new(0.5, -(Config.IslandWidth or 430) / 2, 0, Config.IslandYOffset or 12)
DynamicIsland.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
DynamicIsland.BackgroundTransparency = Config.IslandTransparency or 0.15
DynamicIsland.BorderSizePixel = 0
DynamicIsland.ClipsDescendants = true
DynamicIsland.Visible = false
DynamicIsland.Parent = ScreenGui
Instance.new("UICorner", DynamicIsland).CornerRadius = UDim.new(1, 0)

-- Luxury Obsidian Glass Gradient
do
    local diGradient = Instance.new("UIGradient")
    diGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 22, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 10, 15)),
    })
    diGradient.Rotation = 90
    diGradient.Parent = DynamicIsland
    
    -- Top Glass Specular Highlight Sheen (Apple-style frosted glass line)
    local diTopSheen = Instance.new("Frame")
    diTopSheen.Name = "TopSheen"
    diTopSheen.Size = UDim2.new(1, -24, 0, 1)
    diTopSheen.Position = UDim2.new(0, 12, 0, 1)
    diTopSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    diTopSheen.BackgroundTransparency = 0.72
    diTopSheen.BorderSizePixel = 0
    diTopSheen.Parent = DynamicIsland
    Instance.new("UICorner", diTopSheen).CornerRadius = UDim.new(1, 0)
    
    local sheenGrad = Instance.new("UIGradient")
    sheenGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 0.45),
        NumberSequenceKeypoint.new(0.8, 0.45),
        NumberSequenceKeypoint.new(1, 1),
    })
    sheenGrad.Parent = diTopSheen
end

-- Theme color presets
local IslandThemeColors = {
    Red = Color3.fromRGB(235, 50, 75),
    Blue = Color3.fromRGB(45, 140, 255),
    Purple = Color3.fromRGB(165, 60, 245),
    Green = Color3.fromRGB(45, 215, 105),
    Gold = Color3.fromRGB(255, 205, 35),
    Sunset = Color3.fromRGB(255, 95, 45),
    Silver = Color3.fromRGB(160, 175, 195),
}

local diStroke = Instance.new("UIStroke")
diStroke.Color = IslandThemeColors[Config.IslandTheme] or IslandThemeColors.Blue
diStroke.Thickness = 1.3
diStroke.Transparency = 0.35
diStroke.Parent = DynamicIsland

-- Left: Role Badge Pill
local diRoleBadge = Instance.new("Frame")
diRoleBadge.Name = "RoleBadge"
diRoleBadge.Size = UDim2.new(0, 0, 0, 24)
diRoleBadge.AnchorPoint = Vector2.new(0, 0.5)
diRoleBadge.Position = UDim2.new(0, 8, 0.5, 0)
diRoleBadge.AutomaticSize = Enum.AutomaticSize.X
diRoleBadge.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
diRoleBadge.BackgroundTransparency = 0.2
diRoleBadge.BorderSizePixel = 0
diRoleBadge.Visible = (Config.IslandShowRole ~= false)
diRoleBadge.Parent = DynamicIsland
Instance.new("UICorner", diRoleBadge).CornerRadius = UDim.new(1, 0)

do
    local roleBadgeStroke = Instance.new("UIStroke")
    roleBadgeStroke.Color = Color3.fromRGB(255, 255, 255)
    roleBadgeStroke.Thickness = 1
    roleBadgeStroke.Transparency = 0.88
    roleBadgeStroke.Parent = diRoleBadge
    
    local diRoleLayout = Instance.new("UIListLayout")
    diRoleLayout.FillDirection = Enum.FillDirection.Horizontal
    diRoleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    diRoleLayout.SortOrder = Enum.SortOrder.LayoutOrder
    diRoleLayout.Padding = UDim.new(0, 5)
    diRoleLayout.Parent = diRoleBadge
    
    local diRolePadding = Instance.new("UIPadding")
    diRolePadding.PaddingLeft = UDim.new(0, 8)
    diRolePadding.PaddingRight = UDim.new(0, 10)
    diRolePadding.Parent = diRoleBadge
end

local diRoleDot = Instance.new("Frame")
diRoleDot.Name = "RoleDot"
diRoleDot.LayoutOrder = 1
diRoleDot.Size = UDim2.new(0, 6, 0, 6)
diRoleDot.BackgroundColor3 = Color3.fromRGB(160, 180, 210)
diRoleDot.BorderSizePixel = 0
diRoleDot.Parent = diRoleBadge
Instance.new("UICorner", diRoleDot).CornerRadius = UDim.new(1, 0)

local diRoleText = Instance.new("TextLabel")
diRoleText.Name = "RoleText"
diRoleText.LayoutOrder = 2
diRoleText.AutomaticSize = Enum.AutomaticSize.X
diRoleText.Size = UDim2.new(0, 0, 1, 0)
diRoleText.BackgroundTransparency = 1
diRoleText.Font = Enum.Font.GothamBlack
diRoleText.TextSize = 9
diRoleText.TextColor3 = Color3.fromRGB(255, 255, 255)
diRoleText.Text = "🏛️ LOBBY"
diRoleText.Parent = diRoleBadge

-- Center: Dynamic Status / Event Text
local diStatusText = Instance.new("TextLabel")
diStatusText.Name = "StatusText"
diStatusText.Size = UDim2.new(1, -300, 1, 0)
diStatusText.Position = UDim2.new(0, 110, 0, 0)
diStatusText.BackgroundTransparency = 1
diStatusText.Font = Enum.Font.GothamBold
diStatusText.TextSize = 10
diStatusText.TextColor3 = Color3.fromRGB(230, 240, 255)
diStatusText.TextXAlignment = Enum.TextXAlignment.Center
diStatusText.TextTruncate = Enum.TextTruncate.AtEnd
diStatusText.Text = "Waiting for Round..."
diStatusText.Visible = (Config.IslandShowStatus ~= false)
diStatusText.Parent = DynamicIsland

-- Right: Telemetry Cluster (Round Timer, FPS, Ping, OS Time)
local diTelemetryCluster = Instance.new("Frame")
diTelemetryCluster.Name = "TelemetryCluster"
diTelemetryCluster.Size = UDim2.new(0, 0, 0, 24)
diTelemetryCluster.AnchorPoint = Vector2.new(1, 0.5)
diTelemetryCluster.Position = UDim2.new(1, -8, 0.5, 0)
diTelemetryCluster.AutomaticSize = Enum.AutomaticSize.X
diTelemetryCluster.BackgroundTransparency = 1
diTelemetryCluster.BorderSizePixel = 0
diTelemetryCluster.Parent = DynamicIsland

do
    local tcLayout = Instance.new("UIListLayout")
    tcLayout.FillDirection = Enum.FillDirection.Horizontal
    tcLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    tcLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tcLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tcLayout.Padding = UDim.new(0, 4)
    tcLayout.Parent = diTelemetryCluster
end

-- Round Timer Badge Pill
local diRoundBadge = Instance.new("Frame")
diRoundBadge.Name = "RoundBadge"
diRoundBadge.LayoutOrder = 1
diRoundBadge.AutomaticSize = Enum.AutomaticSize.X
diRoundBadge.Size = UDim2.new(0, 0, 0, 22)
diRoundBadge.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
diRoundBadge.BackgroundTransparency = 0.25
diRoundBadge.BorderSizePixel = 0
diRoundBadge.Visible = (Config.IslandShowRoundTimer ~= false)
diRoundBadge.Parent = diTelemetryCluster
Instance.new("UICorner", diRoundBadge).CornerRadius = UDim.new(1, 0)
do
    local roundStroke = Instance.new("UIStroke")
    roundStroke.Color = Color3.fromRGB(255, 255, 255)
    roundStroke.Thickness = 1
    roundStroke.Transparency = 0.88
    roundStroke.Parent = diRoundBadge
    local roundPad = Instance.new("UIPadding")
    roundPad.PaddingLeft = UDim.new(0, 8)
    roundPad.PaddingRight = UDim.new(0, 8)
    roundPad.Parent = diRoundBadge
end

local diRoundText = Instance.new("TextLabel")
diRoundText.AutomaticSize = Enum.AutomaticSize.X
diRoundText.Size = UDim2.new(0, 0, 1, 0)
diRoundText.BackgroundTransparency = 1
diRoundText.Font = Enum.Font.GothamBold
diRoundText.TextSize = 9
diRoundText.TextColor3 = Color3.fromRGB(130, 225, 255)
diRoundText.Text = "⏳ Lobby"
diRoundText.Parent = diRoundBadge

-- FPS Badge Pill
local diFpsBadge = Instance.new("Frame")
diFpsBadge.Name = "FpsBadge"
diFpsBadge.LayoutOrder = 2
diFpsBadge.AutomaticSize = Enum.AutomaticSize.X
diFpsBadge.Size = UDim2.new(0, 0, 0, 22)
diFpsBadge.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
diFpsBadge.BackgroundTransparency = 0.25
diFpsBadge.BorderSizePixel = 0
diFpsBadge.Visible = (Config.IslandShowFPS ~= false)
diFpsBadge.Parent = diTelemetryCluster
Instance.new("UICorner", diFpsBadge).CornerRadius = UDim.new(1, 0)
do
    local fpsStroke = Instance.new("UIStroke")
    fpsStroke.Color = Color3.fromRGB(255, 255, 255)
    fpsStroke.Thickness = 1
    fpsStroke.Transparency = 0.88
    fpsStroke.Parent = diFpsBadge
    local fpsPad = Instance.new("UIPadding")
    fpsPad.PaddingLeft = UDim.new(0, 7)
    fpsPad.PaddingRight = UDim.new(0, 7)
    fpsPad.Parent = diFpsBadge
end

local diFpsText = Instance.new("TextLabel")
diFpsText.AutomaticSize = Enum.AutomaticSize.X
diFpsText.Size = UDim2.new(0, 0, 1, 0)
diFpsText.BackgroundTransparency = 1
diFpsText.Font = Enum.Font.GothamBold
diFpsText.TextSize = 9
diFpsText.TextColor3 = Color3.fromRGB(50, 225, 125)
diFpsText.Text = "⚡ 60"
diFpsText.Parent = diFpsBadge

-- Ping Badge Pill
local diPingBadge = Instance.new("Frame")
diPingBadge.Name = "PingBadge"
diPingBadge.LayoutOrder = 3
diPingBadge.AutomaticSize = Enum.AutomaticSize.X
diPingBadge.Size = UDim2.new(0, 0, 0, 22)
diPingBadge.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
diPingBadge.BackgroundTransparency = 0.25
diPingBadge.BorderSizePixel = 0
diPingBadge.Visible = (Config.IslandShowPing ~= false)
diPingBadge.Parent = diTelemetryCluster
Instance.new("UICorner", diPingBadge).CornerRadius = UDim.new(1, 0)
do
    local pingStroke = Instance.new("UIStroke")
    pingStroke.Color = Color3.fromRGB(255, 255, 255)
    pingStroke.Thickness = 1
    pingStroke.Transparency = 0.88
    pingStroke.Parent = diPingBadge
    local pingPad = Instance.new("UIPadding")
    pingPad.PaddingLeft = UDim.new(0, 7)
    pingPad.PaddingRight = UDim.new(0, 7)
    pingPad.Parent = diPingBadge
end

local diPingText = Instance.new("TextLabel")
diPingText.AutomaticSize = Enum.AutomaticSize.X
diPingText.Size = UDim2.new(0, 0, 1, 0)
diPingText.BackgroundTransparency = 1
diPingText.Font = Enum.Font.GothamBold
diPingText.TextSize = 9
diPingText.TextColor3 = Color3.fromRGB(50, 225, 125)
diPingText.Text = "📶 0ms"
diPingText.Parent = diPingBadge

-- Time Badge Pill
local diTimeBadge = Instance.new("Frame")
diTimeBadge.Name = "TimeBadge"
diTimeBadge.LayoutOrder = 4
diTimeBadge.AutomaticSize = Enum.AutomaticSize.X
diTimeBadge.Size = UDim2.new(0, 0, 0, 22)
diTimeBadge.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
diTimeBadge.BackgroundTransparency = 0.25
diTimeBadge.BorderSizePixel = 0
diTimeBadge.Visible = (Config.IslandShowTime ~= false)
diTimeBadge.Parent = diTelemetryCluster
Instance.new("UICorner", diTimeBadge).CornerRadius = UDim.new(1, 0)
do
    local timeStroke = Instance.new("UIStroke")
    timeStroke.Color = Color3.fromRGB(255, 255, 255)
    timeStroke.Thickness = 1
    timeStroke.Transparency = 0.88
    timeStroke.Parent = diTimeBadge
    local timePad = Instance.new("UIPadding")
    timePad.PaddingLeft = UDim.new(0, 8)
    timePad.PaddingRight = UDim.new(0, 8)
    timePad.Parent = diTimeBadge
end

local diTimeText = Instance.new("TextLabel")
diTimeText.AutomaticSize = Enum.AutomaticSize.X
diTimeText.Size = UDim2.new(0, 0, 1, 0)
diTimeText.BackgroundTransparency = 1
diTimeText.Font = Enum.Font.GothamBold
diTimeText.TextSize = 9
diTimeText.TextXAlignment = Enum.TextXAlignment.Center
diTimeText.TextColor3 = Color3.fromRGB(150, 185, 235)
diTimeText.Text = "🕒 " .. os.date("%H:%M:%S")
diTimeText.Parent = diTimeBadge

local function applyIslandTheme(themeName)
    if not themeName then themeName = Config.UITheme or "Red" end
    Config.IslandTheme = themeName
    saveConfig()
    local col = (UIThemes and UIThemes[themeName] and UIThemes[themeName].Main)
        or IslandThemeColors[themeName]
        or IslandThemeColors.Red
    if diStroke then
        TweenService:Create(diStroke, TweenInfo.new(0.25), {Color = col}):Play()
    end
end

local isIslandHovered = false

_G.MM2_RevealDynamicIsland = function()
    if not ScreenGui or not DynamicIsland then return end
    if Config.DynamicIsland and not Config.Disable3DRender then
        local w = Config.IslandWidth or 430
        local y = Config.IslandYOffset or 12
        DynamicIsland.Visible = true
        DynamicIsland.Position = UDim2.new(0.5, -w / 2, 0, -55)
        DynamicIsland.BackgroundTransparency = 1
        TweenService:Create(DynamicIsland, TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -w / 2, 0, y),
            BackgroundTransparency = Config.IslandTransparency or 0.15
        }):Play()
    end
end

local function updateIslandGeometry()
    if not DynamicIsland then return end
    local s = Config.IslandTextSize or 10
    local badgeH = math.clamp(math.floor(22 + (s - 10) * 1.5), 20, 28)

    -- Toggle visibility
    if diRoundBadge then diRoundBadge.Visible = (Config.IslandShowRoundTimer ~= false) end
    if diTimeBadge then diTimeBadge.Visible = (Config.IslandShowTime ~= false) end
    if diFpsBadge then diFpsBadge.Visible = (Config.IslandShowFPS ~= false) end
    if diPingBadge then diPingBadge.Visible = (Config.IslandShowPing ~= false) end
    if diRoleBadge then diRoleBadge.Visible = (Config.IslandShowRole ~= false) end
    if diStatusText then diStatusText.Visible = (Config.IslandShowStatus ~= false) end

    -- Update badge heights
    if diRoleBadge then diRoleBadge.Size = UDim2.new(0, 0, 0, badgeH + 2) end
    if diRoundBadge then diRoundBadge.Size = UDim2.new(0, 0, 0, badgeH) end
    if diFpsBadge then diFpsBadge.Size = UDim2.new(0, 0, 0, badgeH) end
    if diPingBadge then diPingBadge.Size = UDim2.new(0, 0, 0, badgeH) end
    if diTimeBadge then diTimeBadge.Size = UDim2.new(0, 0, 0, badgeH) end
    if diTelemetryCluster then diTelemetryCluster.Size = UDim2.new(0, 0, 0, badgeH) end

    local roleW = (Config.IslandShowRole ~= false and diRoleBadge and diRoleBadge.Visible and math.max(diRoleBadge.AbsoluteSize.X, 85)) or 0
    local clusterW = (diTelemetryCluster and diTelemetryCluster.Visible and math.max(diTelemetryCluster.AbsoluteSize.X, 120)) or 0

    local leftPad = (roleW > 0 and (roleW + 16)) or 12
    local rightPad = (clusterW > 0 and (clusterW + 16)) or 12

    local minRequiredWidth = leftPad + rightPad + 130
    local baseW = math.max(Config.IslandWidth or 460, minRequiredWidth)
    local effectiveWidth = isIslandHovered and (baseW + 24) or baseW
    local effectiveHeight = math.max(Config.IslandHeight or 34, badgeH + 10) + (isIslandHovered and 4 or 0)
    local y = (Config.IslandYOffset or 12) - (isIslandHovered and 1 or 0)

    local targetSize = UDim2.new(0, effectiveWidth, 0, effectiveHeight)
    local targetPos = UDim2.new(0.5, -effectiveWidth / 2, 0, y)
    local targetTransp = isIslandHovered and math.clamp((Config.IslandTransparency or 0.15) - 0.05, 0, 1) or (Config.IslandTransparency or 0.15)

    if animate then
        if islandTween then pcall(function() islandTween:Cancel() end) end
        local easeStyle = Enum.EasingStyle.Quart
        local easeDur = 0.32
        islandTween = TweenService:Create(DynamicIsland, TweenInfo.new(easeDur, easeStyle, Enum.EasingDirection.Out), {
            Size = targetSize,
            Position = targetPos,
            BackgroundTransparency = targetTransp
        })
        islandTween:Play()
        if diStroke then
            local col = (UIThemes and UIThemes[Config.UITheme] and UIThemes[Config.UITheme].Main)
                or IslandThemeColors[Config.IslandTheme] or IslandThemeColors.Red
            TweenService:Create(diStroke, TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Color = col,
                Thickness = isIslandHovered and 1.8 or 1.2,
                Transparency = isIslandHovered and 0.08 or 0.35
            }):Play()
        end
        local sheen = DynamicIsland:FindFirstChild("TopSheen")
        if sheen then
            TweenService:Create(sheen, TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundTransparency = isIslandHovered and 0.45 or 0.72
            }):Play()
        end
        if diStatusText then
            TweenService:Create(diStatusText, TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, leftPad, 0, 0),
                Size = UDim2.new(1, -(leftPad + rightPad), 1, 0),
                TextSize = isIslandHovered and math.min(18, s + 1) or math.min(18, s + 1)
            }):Play()
        end
    else
        DynamicIsland.Size = targetSize
        DynamicIsland.Position = targetPos
        DynamicIsland.BackgroundTransparency = targetTransp
        if diStroke then
            local col = (UIThemes and UIThemes[Config.UITheme] and UIThemes[Config.UITheme].Main)
                or IslandThemeColors[Config.IslandTheme] or IslandThemeColors.Red
            diStroke.Color = col
            diStroke.Thickness = isIslandHovered and 2.2 or 1.3
            diStroke.Transparency = isIslandHovered and 0.05 or 0.35
        end
        local sheen = DynamicIsland:FindFirstChild("TopSheen")
        if sheen then
            sheen.BackgroundTransparency = isIslandHovered and 0.35 or 0.72
        end
        if diStatusText then
            diStatusText.Position = UDim2.new(0, leftPad, 0, 0)
            diStatusText.Size = UDim2.new(1, -(leftPad + rightPad), 1, 0)
            diStatusText.TextSize = isIslandHovered and math.min(18, s + 2) or math.min(18, s + 1)
        end
    end

    if PreRevealBanner then
        PreRevealBanner.Position = UDim2.new(0.5, -180, 0, y + effectiveHeight + 8)
    end
end

local function applyIslandTextSize(size)
    Config.IslandTextSize = math.clamp(tonumber(size) or 10, 8, 16)
    local s = Config.IslandTextSize
    if diRoleText then diRoleText.TextSize = s end
    if diStatusText then diStatusText.TextSize = math.min(18, s + 1) end
    if diRoundText then diRoundText.TextSize = s end
    if diFpsText then diFpsText.TextSize = s end
    if diPingText then diPingText.TextSize = s end
    if diTimeText then diTimeText.TextSize = s end

    updateIslandGeometry(true)
    saveConfig()
end

-- Interactive Hover expansion
DynamicIsland.Active = true
safeHover(DynamicIsland, function()
    if not Config.IslandHoverExpand then return end
    isIslandHovered = true
    updateIslandGeometry(true)
end, function()
    isIslandHovered = false
    updateIslandGeometry(true)
end)

-- Bouncy hover animations for individual badges
do
    local islandBadges = {diRoleBadge, diRoundBadge, diFpsBadge, diPingBadge, diTimeBadge}
    for _, b in ipairs(islandBadges) do
        if b then
            b.Active = true
            local sc = b:FindFirstChildOfClass("UIScale")
            if not sc then
                sc = Instance.new("UIScale")
                sc.Scale = 1.0
                sc.Parent = b
            end
            local origBg = b.BackgroundColor3
            local origTransp = b.BackgroundTransparency
            local st = b:FindFirstChildOfClass("UIStroke")

            safeHover(b, function()
                TweenService:Create(sc, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Scale = 1.05}):Play()
                TweenService:Create(b, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Color3.fromRGB(36, 46, 68),
                    BackgroundTransparency = math.clamp(origTransp - 0.15, 0, 1)
                }):Play()
                if st then
                    TweenService:Create(st, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        Transparency = 0.2,
                        Thickness = 1.4
                    }):Play()
                end
            end, function()
                TweenService:Create(sc, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Scale = 1.0}):Play()
                TweenService:Create(b, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    BackgroundColor3 = origBg,
                    BackgroundTransparency = origTransp
                }):Play()
                if st then
                    TweenService:Create(st, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        Transparency = 0.88,
                        Thickness = 1.0
                    }):Play()
                end
            end)
        end
    end
end

-- Dynamic relayout on badge size changes
if diRoleBadge then
    diRoleBadge:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if diStatusText and DynamicIsland then
            local roleW = (Config.IslandShowRole ~= false and diRoleBadge.Visible and diRoleBadge.AbsoluteSize.X) or 0
            local clusterW = (diTelemetryCluster and diTelemetryCluster.Visible and diTelemetryCluster.AbsoluteSize.X) or 0
            local leftPad = (roleW > 0 and (roleW + 16)) or 12
            local rightPad = (clusterW > 0 and (clusterW + 16)) or 12
            diStatusText.Position = UDim2.new(0, leftPad, 0, 0)
            diStatusText.Size = UDim2.new(1, -(leftPad + rightPad), 1, 0)
        end
    end)
end
if diTelemetryCluster then
    diTelemetryCluster:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if diStatusText and DynamicIsland then
            local roleW = (Config.IslandShowRole ~= false and diRoleBadge and diRoleBadge.Visible and diRoleBadge.AbsoluteSize.X) or 0
            local clusterW = (diTelemetryCluster.Visible and diTelemetryCluster.AbsoluteSize.X) or 0
            local leftPad = (roleW > 0 and (roleW + 16)) or 12
            local rightPad = (clusterW > 0 and (clusterW + 16)) or 12
            diStatusText.Position = UDim2.new(0, leftPad, 0, 0)
            diStatusText.Size = UDim2.new(1, -(leftPad + rightPad), 1, 0)
        end
    end)
end

-- Click on Dynamic Island to open / toggle GUI smoothly without squishing
DynamicIsland.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
        if isMobile and not Config.MobileIslandClickToggle then
            return
        end
        if diStroke then
            local col = (UIThemes and UIThemes[Config.UITheme] and UIThemes[Config.UITheme].Main)
                or IslandThemeColors[Config.IslandTheme] or IslandThemeColors.Red
            TweenService:Create(diStroke, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Color = col,
                Thickness = 2.4,
                Transparency = 0
            }):Play()
            task.delay(0.18, function()
                if diStroke then
                    TweenService:Create(diStroke, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        Thickness = isIslandHovered and 1.8 or 1.2,
                        Transparency = isIslandHovered and 0.08 or 0.35
                    }):Play()
                end
            end)
        end
        if toggleMenu then
            toggleMenu()
        end
    end
end)

do
    local function updateIslandInteractivity()
        local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
        local islandClickEnabled = (not isMobile) or (Config.MobileIslandClickToggle == true)
        if DynamicIsland then
            DynamicIsland.Active = islandClickEnabled
        end
    end
    _G.MM2_UpdateIslandInteractivity = updateIslandInteractivity
    pcall(updateIslandInteractivity)
end

pcall(function()
    applyIslandTextSize(Config.IslandTextSize or 10)
    if Config.IslandSyncTheme ~= false then
        applyIslandTheme(Config.UITheme or "Red")
    else
        applyIslandTheme(Config.IslandTheme or "Red")
    end
end)

-- ====================================================================
-- ⚡ DISABLE 3D RENDER ENGINE (Low GPU / 20 FPS AFK Dashboard)
-- ====================================================================
do
    local disable3DScreen = Instance.new("ScreenGui")
    disable3DScreen.Name = "MM2_Disable3D_Screen"
    disable3DScreen.ResetOnSpawn = false
    disable3DScreen.DisplayOrder = 2147483647
    disable3DScreen.IgnoreGuiInset = true
    disable3DScreen.Enabled = false
    disable3DScreen.Parent = container

    -- Fullscreen black/obsidian background covering entire screen
    local bg = Instance.new("Frame")
    bg.Name = "BlackoutBackground"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.Position = UDim2.new(0, 0, 0, 0)
    bg.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
    bg.BorderSizePixel = 0
    bg.Active = true
    bg.Parent = disable3DScreen

    local bgGradient = Instance.new("UIGradient")
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(12, 16, 24)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(6, 8, 12)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(10, 14, 20)),
    })
    bgGradient.Rotation = 45
    bgGradient.Parent = bg

    -- Center Dashboard Card (Fullscreen Responsive HUD with Large Text)
    local card = Instance.new("Frame")
    card.Name = "StatsDashboardCard"
    card.Size = UDim2.new(0.98, 0, 0.96, 0)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.new(0.5, 0, 0.5, 0)
    card.BackgroundColor3 = Color3.fromRGB(13, 16, 25)
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.Parent = bg
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(0, 220, 170)
    cardStroke.Thickness = 2
    cardStroke.Transparency = 0.2
    cardStroke.Parent = card

    -- Header inside Card (Prominent Large Modern Typography)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 88)
    header.BackgroundColor3 = Color3.fromRGB(18, 23, 36)
    header.BorderSizePixel = 0
    header.Parent = card
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -24, 0, 42)
    titleLbl.Position = UDim2.new(0, 18, 0, 8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 26
    titleLbl.TextColor3 = Color3.fromRGB(0, 240, 180)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = "⚡ 3D RENDER ВЫКЛЮЧЕН (VORTEX PRIME • AFK DASHBOARD)"
    titleLbl.Parent = header

    local subLbl = Instance.new("TextLabel")
    subLbl.Size = UDim2.new(1, -24, 0, 26)
    subLbl.Position = UDim2.new(0, 18, 0, 52)
    subLbl.BackgroundTransparency = 1
    subLbl.Font = Enum.Font.GothamMedium
    subLbl.TextSize = 15
    subLbl.TextColor3 = Color3.fromRGB(160, 175, 205)
    subLbl.TextXAlignment = Enum.TextXAlignment.Left
    subLbl.Text = "Энергосбережение активно • 3D выгружен (20 FPS) • Нажмите [F7] для возврата"
    subLbl.Parent = header

    -- Live Stats Grid Container
    local statsContainer = Instance.new("ScrollingFrame")
    statsContainer.Size = UDim2.new(1, -32, 1, -170)
    statsContainer.Position = UDim2.new(0, 16, 0, 98)
    statsContainer.BackgroundTransparency = 1
    statsContainer.BorderSizePixel = 0
    statsContainer.ScrollBarThickness = 5
    statsContainer.ScrollBarImageColor3 = Color3.fromRGB(0, 220, 170)
    statsContainer.Parent = card

    local statsLayout = Instance.new("UIListLayout")
    statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    statsLayout.Padding = UDim.new(0, 8)
    statsLayout.Parent = statsContainer

    statsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        statsContainer.CanvasSize = UDim2.new(0, 0, 0, statsLayout.AbsoluteContentSize.Y + 16)
    end)

    local function createStatRow(order, icon, title, initialVal, valColor)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 0, 44)
        row.BackgroundColor3 = Color3.fromRGB(20, 25, 38)
        row.BorderSizePixel = 0
        row.LayoutOrder = order
        row.Parent = statsContainer
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local rowStroke = Instance.new("UIStroke")
        rowStroke.Color = Color3.fromRGB(40, 50, 72)
        rowStroke.Thickness = 1
        rowStroke.Transparency = 0.5
        rowStroke.Parent = row

        local iconAndTitle = Instance.new("TextLabel")
        iconAndTitle.Size = UDim2.new(0.55, -10, 1, 0)
        iconAndTitle.Position = UDim2.new(0, 16, 0, 0)
        iconAndTitle.BackgroundTransparency = 1
        iconAndTitle.Font = Enum.Font.GothamBold
        iconAndTitle.TextSize = 16
        iconAndTitle.TextColor3 = Color3.fromRGB(200, 215, 240)
        iconAndTitle.TextXAlignment = Enum.TextXAlignment.Left
        iconAndTitle.Text = icon .. " " .. title
        iconAndTitle.Parent = row

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0.45, -16, 1, 0)
        valLbl.Position = UDim2.new(0.55, 0, 0, 0)
        valLbl.BackgroundTransparency = 1
        valLbl.Font = Enum.Font.GothamBlack
        valLbl.TextSize = 18
        valLbl.TextColor3 = valColor or Color3.fromRGB(255, 255, 255)
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Text = initialVal
        valLbl.Parent = row

        return valLbl
    end

    local statFarm = createStatRow(1, "🌾", "Статус фарма:", "Ожидание...", Color3.fromRGB(255, 215, 60))
    local statMap = createStatRow(2, "🗺️", "Текущая карта:", "Ожидание карты...", Color3.fromRGB(100, 200, 255))
    local statRound = createStatRow(3, "⏱️", "Время раунда:", "--:--", Color3.fromRGB(220, 230, 255))
    local statMurderer = createStatRow(4, "💀", "Убийца (Murderer):", "Неизвестен", Color3.fromRGB(255, 75, 95))
    local statSheriff = createStatRow(5, "🛡️", "Шериф (Sheriff):", "Неизвестен", Color3.fromRGB(75, 160, 255))
    local statGun = createStatRow(6, "⭐", "Пистолет на полу:", "Нет", Color3.fromRGB(255, 210, 50))
    local statBag = createStatRow(7, "💰", "Мешок монет (раунд):", "0 / 40", Color3.fromRGB(255, 225, 75))
    local statBalance = createStatRow(8, "🪙", "Баланс монет аккаунта:", "0", Color3.fromRGB(255, 220, 70))
    local statServerCoins = createStatRow(9, "🌐", "За сессию на этом сервере:", "0", Color3.fromRGB(80, 235, 140))
    local statAllTimeCoins = createStatRow(10, "💎", "За всё время (All-Time):", "0", Color3.fromRGB(0, 240, 210))
    local statActiveCoins = createStatRow(11, "🗺️", "Монет на карте:", "0", Color3.fromRGB(255, 185, 75))
    local statPerf = createStatRow(12, "⚡", "Производительность:", "20 FPS | 0 ms", Color3.fromRGB(0, 230, 190))

    -- Bottom Actions Row
    local btnRow = Instance.new("Frame")
    btnRow.Size = UDim2.new(1, -32, 0, 56)
    btnRow.Position = UDim2.new(0, 16, 1, -66)
    btnRow.BackgroundTransparency = 1
    btnRow.Parent = card

    local resumeBtn = Instance.new("TextButton")
    resumeBtn.Size = UDim2.new(0.68, -8, 1, 0)
    resumeBtn.Position = UDim2.new(0, 0, 0, 0)
    resumeBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 130)
    resumeBtn.BorderSizePixel = 0
    resumeBtn.Font = Enum.Font.GothamBlack
    resumeBtn.TextSize = 17
    resumeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resumeBtn.Text = "🚀 ВКЛЮЧИТЬ 3D RENDER (F7)"
    resumeBtn.AutoButtonColor = false
    resumeBtn.Parent = btnRow
    Instance.new("UICorner", resumeBtn).CornerRadius = UDim.new(0, 10)

    local resetStatsBtn = Instance.new("TextButton")
    resetStatsBtn.Size = UDim2.new(0.32, -8, 1, 0)
    resetStatsBtn.Position = UDim2.new(0.68, 8, 0, 0)
    resetStatsBtn.BackgroundColor3 = Color3.fromRGB(190, 45, 65)
    resetStatsBtn.BorderSizePixel = 0
    resetStatsBtn.Font = Enum.Font.GothamBold
    resetStatsBtn.TextSize = 14
    resetStatsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetStatsBtn.Text = "🗑️ СБРОСИТЬ СТАТУ"
    resetStatsBtn.AutoButtonColor = false
    resetStatsBtn.Parent = btnRow
    Instance.new("UICorner", resetStatsBtn).CornerRadius = UDim.new(0, 10)

    safeHover(resumeBtn, function()
        TweenService:Create(resumeBtn, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(0, 210, 160)}):Play()
    end, function()
        TweenService:Create(resumeBtn, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(0, 170, 130)}):Play()
    end)
    resumeBtn.MouseButton1Click:Connect(function()
        if _G.MM2_Set3DRenderEnabled then
            _G.MM2_Set3DRenderEnabled(true)
        end
    end)

    safeHover(resetStatsBtn, function()
        TweenService:Create(resetStatsBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(225, 60, 80)}):Play()
    end, function()
        TweenService:Create(resetStatsBtn, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(190, 45, 65)}):Play()
    end)
    resetStatsBtn.MouseButton1Click:Connect(function()
        if _G.MM2_ResetStats then
            _G.MM2_ResetStats()
        end
    end)

    local savedVolume = nil
    local savedQuality = nil
    local savedShadows = nil
    local savedTerrainDeco = nil
    local savedPostEffects = {}
    local savedCameraType = nil
    local savedCameraCFrame = nil
    local savedCameraSubject = nil
    local cameraLockConnection = nil

    -- Controller function (Modern Roblox & Multi-Executor 3D Engine Disabler)
    _G.MM2_Set3DRenderEnabled = function(enabled)
        Config.Disable3DRender = not enabled
        saveConfig()

        if not enabled then
            disable3DScreen.Enabled = true
            if DynamicIsland then DynamicIsland.Visible = false end

            -- 1. Mute Roblox master volume
            pcall(function()
                local ugs = UserSettings():GetService("UserGameSettings")
                if savedVolume == nil then
                    savedVolume = ugs.MasterVolume
                end
                ugs.MasterVolume = 0
            end)

            -- 2. Lower graphics quality to minimal level 1
            pcall(function()
                local rend = settings().Rendering
                if savedQuality == nil then
                    savedQuality = rend.QualityLevel
                end
                rend.QualityLevel = 1
            end)

            -- 3. Disable heavy lighting shadows
            pcall(function()
                if savedShadows == nil then
                    savedShadows = Lighting.GlobalShadows
                end
                Lighting.GlobalShadows = false
            end)

            -- 4. Disable terrain decorations
            pcall(function()
                if workspace:FindFirstChildOfClass("Terrain") then
                    if savedTerrainDeco == nil then
                        savedTerrainDeco = workspace.Terrain.Decoration
                    end
                    workspace.Terrain.Decoration = false
                end
            end)

            -- 5. Disable post-processing effects
            pcall(function()
                for _, effect in ipairs(Lighting:GetChildren()) do
                    if effect:IsA("PostEffect") and effect.Enabled then
                        savedPostEffects[effect] = true
                        effect.Enabled = false
                    end
                end
            end)

            -- 6. Modern Frustum Culling & Void Isolation (Culls 100% world geometry, 0% GPU load across all Roblox versions)
            pcall(function()
                local cam = workspace.CurrentCamera
                if cam then
                    if savedCameraType == nil then savedCameraType = cam.CameraType end
                    if savedCameraCFrame == nil then savedCameraCFrame = cam.CFrame end
                    if savedCameraSubject == nil then savedCameraSubject = cam.CameraSubject end
                    cam.CameraType = Enum.CameraType.Scriptable
                    cam.CFrame = CFrame.new(0, 500000, 0)
                end
            end)
            if cameraLockConnection then
                pcall(function() cameraLockConnection:Disconnect() end)
                cameraLockConnection = nil
            end
            cameraLockConnection = RunService.RenderStepped:Connect(function()
                if Config.Disable3DRender then
                    local cam = workspace.CurrentCamera
                    if cam then
                        cam.CameraType = Enum.CameraType.Scriptable
                        cam.CFrame = CFrame.new(0, 500000, 0)
                    end
                end
            end)

            -- 7. Modern Roblox Executor 3D Render Disabler
            pcall(function()
                if set3drendering then
                    set3drendering(false)
                elseif set_3d_rendering then
                    set_3d_rendering(false)
                elseif set3drenderingenabled then
                    set3drenderingenabled(false)
                end
            end)
            pcall(function()
                local rs = (cloneref and cloneref(RunService)) or RunService
                rs:Set3dRenderingEnabled(false)
            end)

            -- 8. Cap FPS to 20 for extreme power saving
            pcall(function()
                if setfpscap then setfpscap(20) end
            end)
        else
            disable3DScreen.Enabled = false
            if DynamicIsland then DynamicIsland.Visible = (Config.DynamicIsland == true) end

            -- Disconnect void camera lock and restore camera
            if cameraLockConnection then
                pcall(function() cameraLockConnection:Disconnect() end)
                cameraLockConnection = nil
            end
            pcall(function()
                local cam = workspace.CurrentCamera
                if cam then
                    if savedCameraType ~= nil then cam.CameraType = savedCameraType savedCameraType = nil else cam.CameraType = Enum.CameraType.Custom end
                    if savedCameraSubject ~= nil then cam.CameraSubject = savedCameraSubject savedCameraSubject = nil end
                    if savedCameraCFrame ~= nil then cam.CFrame = savedCameraCFrame savedCameraCFrame = nil end
                end
            end)

            -- 1. Restore Roblox master volume
            pcall(function()
                local ugs = UserSettings():GetService("UserGameSettings")
                if savedVolume ~= nil then
                    ugs.MasterVolume = savedVolume
                    savedVolume = nil
                end
            end)

            -- 2. Restore graphics quality
            pcall(function()
                local rend = settings().Rendering
                if savedQuality ~= nil then
                    rend.QualityLevel = savedQuality
                    savedQuality = nil
                end
            end)

            -- 3. Restore lighting shadows
            pcall(function()
                if savedShadows ~= nil then
                    Lighting.GlobalShadows = savedShadows
                    savedShadows = nil
                end
            end)

            -- 4. Restore terrain decorations
            pcall(function()
                if workspace:FindFirstChildOfClass("Terrain") and savedTerrainDeco ~= nil then
                    workspace.Terrain.Decoration = savedTerrainDeco
                    savedTerrainDeco = nil
                end
            end)

            -- 5. Restore post-processing effects
            pcall(function()
                for effect, _ in pairs(savedPostEffects) do
                    if effect and effect.Parent then
                        effect.Enabled = true
                    end
                end
                savedPostEffects = {}
            end)

            -- 6. Modern Roblox Executor 3D Render Restorer
            pcall(function()
                if set3drendering then
                    set3drendering(true)
                elseif set_3d_rendering then
                    set_3d_rendering(true)
                elseif set3drenderingenabled then
                    set3drenderingenabled(true)
                end
            end)
            pcall(function()
                local rs = (cloneref and cloneref(RunService)) or RunService
                rs:Set3dRenderingEnabled(true)
            end)

            -- 7. Restore FPS cap
            pcall(function()
                if setfpscap then setfpscap(0) end
            end)
        end
    end

    -- Initial load trigger
    if Config.Disable3DRender then
        task.delay(0.6, function()
            if Config.Disable3DRender and _G.MM2_Set3DRenderEnabled then
                _G.MM2_Set3DRenderEnabled(false)
            end
        end)
    end

    -- Live Dashboard Update Loop
    task.spawn(function()
        while _G.MM2_Hub_Running and (_G.MM2_Hub_InstanceID == InstanceID) do
            if disable3DScreen and disable3DScreen.Enabled then
                pcall(function()
                    -- 1. Farm Status
                    statFarm.Text = CurrentFarmStatus or "Ожидание..."

                    -- 2. Map
                    local map = CachedMap or (getCurrentMap and getCurrentMap())
                    statMap.Text = map and map.Name or "Ожидание карты..."

                    -- 3. Round Timer
                    local timerStr = getRoundTimerDirect and getRoundTimerDirect()
                    statRound.Text = (timerStr and timerStr ~= "") and timerStr or (isPlayerInLobby(LocalPlayer) and "В лобби" or "Идёт раунд")

                    -- 4. Murderer
                    local murd = CachedMurderer
                    if murd and murd.Parent then
                        local mHum = murd.Character and murd.Character:FindFirstChildOfClass("Humanoid")
                        if mHum and mHum.Health <= 0 then
                            statMurderer.Text = murd.Name .. " 💀 (МЁРТВ)"
                            statMurderer.TextColor3 = Color3.fromRGB(150, 150, 150)
                        else
                            statMurderer.Text = murd.Name .. " 🔪"
                            statMurderer.TextColor3 = Color3.fromRGB(255, 75, 95)
                        end
                    else
                        statMurderer.Text = "Не обнаружен"
                        statMurderer.TextColor3 = Color3.fromRGB(180, 180, 180)
                    end

                    -- 5. Sheriff
                    local sh = CachedSheriff
                    if sh and sh.Parent then
                        local sHum = sh.Character and sh.Character:FindFirstChildOfClass("Humanoid")
                        if sHum and sHum.Health <= 0 then
                            statSheriff.Text = sh.Name .. " 💀 (МЁРТВ)"
                            statSheriff.TextColor3 = Color3.fromRGB(150, 150, 150)
                        else
                            statSheriff.Text = sh.Name .. " 🛡️"
                            statSheriff.TextColor3 = Color3.fromRGB(75, 160, 255)
                        end
                    else
                        statSheriff.Text = "Нет шерифа"
                        statSheriff.TextColor3 = Color3.fromRGB(180, 180, 180)
                    end

                    -- 6. Gun Drop
                    local gd = getGunDrop and getGunDrop()
                    if gd then
                        statGun.Text = "⚠️ НА КАРТЕ! (Подберите)"
                        statGun.TextColor3 = Color3.fromRGB(255, 215, 0)
                    else
                        statGun.Text = "В руках / Не выпал"
                        statGun.TextColor3 = Color3.fromRGB(150, 160, 180)
                    end

                    -- 7. Bag
                    local bagCoins, isFull, bagName, bagMax = getMM2CoinBagInfo()
                    local isCandy = (bagName == "Candy")
                    local maxLimit = bagMax or (CoinTracker and CoinTracker.Max) or Config.MaxCoins or 50
                    local rCoins = (bagCoins and bagCoins > 0) and bagCoins or (CoinsCollectedThisRound or 0)
                    statBag.Text = string.format("%s %d / %d %s", isCandy and "🍬" or "🪙", rCoins, maxLimit, isFull and "🛑 (FULL)" or "")

                    -- 8. Account Coin / Candy Balance
                    local cBal = getLocalPlayerCoinBalance()
                    local hBal = getLocalPlayerCandyBalance and getLocalPlayerCandyBalance() or 0
                    if hBal > 0 or isCandy then
                        statBalance.Text = string.format("🪙 %d | 🍬 %d", cBal, hBal)
                    else
                        statBalance.Text = tostring(cBal)
                    end

                    -- 9. Server & All-Time Session Coins
                    local sCoins = (TotalCoinsSession and TotalCoinsSession > 0 and TotalCoinsSession)
                        or (_G.MM2_Stats and _G.MM2_Stats.ServerCoins and _G.MM2_Stats.ServerCoins > 0 and _G.MM2_Stats.ServerCoins)
                        or 0
                    local aCoins = (_G.MM2_Stats and _G.MM2_Stats.AllTimeCoins) or 0
                    statServerCoins.Text = tostring(sCoins)
                    statAllTimeCoins.Text = tostring(aCoins)

                    -- 9. Active Coins
                    local activeCoins = getActiveCoins and getActiveCoins() or {}
                    statActiveCoins.Text = string.format("%d шт.", #activeCoins)

                    -- 10. Perf
                    local ping = getDirectPing and getDirectPing() or 0
                    statPerf.Text = string.format("20 FPS | %d ms Ping", ping)
                end)
            end
            task.wait(0.35)
        end
    end)
end

-- ====================================================================
-- 🔔 SMART EVENT NOTIFICATION BANNER
-- ====================================================================
local NotificationCard = Instance.new("Frame")
NotificationCard.Name = "NotificationCard"
NotificationCard.Size = UDim2.new(0, 390, 0, 56)
NotificationCard.Position = UDim2.new(0.5, -195, 0, -80)
NotificationCard.BackgroundColor3 = Color3.fromRGB(15, 17, 26)
NotificationCard.BorderSizePixel = 0
NotificationCard.ClipsDescendants = true
NotificationCard.Visible = false
NotificationCard.Parent = ScreenGui
Instance.new("UICorner", NotificationCard).CornerRadius = UDim.new(0, 10)

local notifStroke = Instance.new("UIStroke")
notifStroke.Color = Color3.fromRGB(255, 205, 35)
notifStroke.Thickness = 1.6
notifStroke.Transparency = 0.15
notifStroke.Parent = NotificationCard

local notifIconBg = Instance.new("Frame")
notifIconBg.Size = UDim2.new(0, 40, 0, 40)
notifIconBg.Position = UDim2.new(0, 8, 0.5, -20)
notifIconBg.BackgroundColor3 = Color3.fromRGB(24, 28, 42)
notifIconBg.BorderSizePixel = 0
notifIconBg.Parent = NotificationCard
Instance.new("UICorner", notifIconBg).CornerRadius = UDim.new(0, 8)

local notifIcon = Instance.new("TextLabel")
notifIcon.Size = UDim2.new(1, 0, 1, 0)
notifIcon.BackgroundTransparency = 1
notifIcon.Font = Enum.Font.GothamBlack
notifIcon.TextSize = 22
notifIcon.Text = "⭐"
notifIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
notifIcon.Parent = notifIconBg

local notifTitle = Instance.new("TextLabel")
notifTitle.Size = UDim2.new(1, -62, 0, 20)
notifTitle.Position = UDim2.new(0, 56, 0, 7)
notifTitle.BackgroundTransparency = 1
notifTitle.Font = Enum.Font.GothamBlack
notifTitle.TextSize = 12
notifTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
notifTitle.TextXAlignment = Enum.TextXAlignment.Left
notifTitle.Text = "ОПОВЕЩЕНИЕ"
notifTitle.Parent = NotificationCard

local notifDesc = Instance.new("TextLabel")
notifDesc.Size = UDim2.new(1, -62, 0, 20)
notifDesc.Position = UDim2.new(0, 56, 0, 26)
notifDesc.BackgroundTransparency = 1
notifDesc.Font = Enum.Font.GothamBold
notifDesc.TextSize = 10
notifDesc.TextColor3 = Color3.fromRGB(225, 235, 250)
notifDesc.TextXAlignment = Enum.TextXAlignment.Left
notifDesc.TextTruncate = Enum.TextTruncate.AtEnd
notifDesc.Text = "Описание события..."
notifDesc.Parent = NotificationCard

local notifProgressBar = Instance.new("Frame")
notifProgressBar.Size = UDim2.new(1, 0, 0, 3)
notifProgressBar.Position = UDim2.new(0, 0, 1, -3)
notifProgressBar.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
notifProgressBar.BorderSizePixel = 0
notifProgressBar.Parent = NotificationCard

local activeNotifId = 0
showNotification = function(title, desc, color, icon, duration)
    if not Config.EventNotifications then return end
    duration = duration or 4.5
    color = color or Color3.fromRGB(45, 140, 255)
    icon = icon or "🔔"

    activeNotifId = activeNotifId + 1
    local currentId = activeNotifId

    notifTitle.Text = title
    notifTitle.TextColor3 = color
    notifDesc.Text = desc
    notifIcon.Text = icon
    notifStroke.Color = color
    notifProgressBar.BackgroundColor3 = color

    if Config.NotificationSounds ~= false then
        pcall(function()
            local snd = Instance.new("Sound")
            snd.SoundId = "rbxassetid://4590662766"
            snd.Volume = 0.6
            snd.Parent = game:GetService("SoundService")
            snd:Play()
            game:GetService("Debris"):AddItem(snd, 3)
        end)
    end

    if DynamicIsland and DynamicIsland.Visible and diStatusText then
        diStatusText.Text = icon .. " " .. title
        if Config.IslandFlashAlerts ~= false and diStroke then
            TweenService:Create(diStroke, TweenInfo.new(0.2), {Color = color}):Play()
            task.delay(1.5, function()
                if DynamicIsland and diStroke then
                    local thColor = IslandThemeColors[Config.IslandTheme] or Color3.fromRGB(45, 140, 255)
                    TweenService:Create(diStroke, TweenInfo.new(0.4), {Color = thColor}):Play()
                end
            end)
        end
    end

    NotificationCard.Visible = true
    local targetY = (Config.IslandYOffset or 12) + (Config.IslandHeight or 32) + 10
    NotificationCard.Position = UDim2.new(0.5, -195, 0, targetY - 24)

    TweenService:Create(NotificationCard, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -195, 0, targetY)
    }):Play()

    notifProgressBar.Size = UDim2.new(1, 0, 0, 3)
    TweenService:Create(notifProgressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 3)
    }):Play()

    task.spawn(function()
        task.wait(duration)
        if activeNotifId == currentId then
            local hideTween = TweenService:Create(NotificationCard, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, -195, 0, -80)
            })
            hideTween:Play()
            hideTween.Completed:Wait()
            if activeNotifId == currentId then
                NotificationCard.Visible = false
            end
        end
    end)
end


-- ====================================================================
-- 🎨 UI ACCENT THEMES (Point 3)
-- ====================================================================
local UIThemes = {
    ["Red"] = { Main = Color3.fromRGB(235, 50, 75), Accent = Color3.fromRGB(255, 90, 115), Name = "Ruby Red" },
    ["Blue"] = { Main = Color3.fromRGB(45, 140, 255), Accent = Color3.fromRGB(80, 175, 255), Name = "Cyber Blue" },
    ["Purple"] = { Main = Color3.fromRGB(165, 60, 245), Accent = Color3.fromRGB(195, 100, 255), Name = "Neon Violet" },
    ["Green"] = { Main = Color3.fromRGB(45, 215, 105), Accent = Color3.fromRGB(75, 235, 135), Name = "Emerald Green" },
    ["Gold"] = { Main = Color3.fromRGB(255, 205, 35), Accent = Color3.fromRGB(255, 225, 75), Name = "Cyber Gold" },
    ["Sunset"] = { Main = Color3.fromRGB(255, 95, 45), Accent = Color3.fromRGB(255, 135, 85), Name = "Sunset Coral" },
    ["Silver"] = { Main = Color3.fromRGB(160, 175, 195), Accent = Color3.fromRGB(200, 215, 235), Name = "Stealth Silver" },
    ["Custom"] = { Main = Color3.fromRGB(255, 45, 85), Accent = Color3.fromRGB(255, 90, 130), Name = "Custom Theme" },
}

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, math.clamp(tonumber(Config.UIRootWidth) or 550, 420, 950), 0, math.clamp(tonumber(Config.UIRootHeight) or 420, 320, 720))
MainFrame.Position = UDim2.new(
    tonumber(Config.UIRootScaleX) or 0.5,
    tonumber(Config.UIRootPosX) or (-(math.clamp(tonumber(Config.UIRootWidth) or 550, 420, 950) / 2)),
    tonumber(Config.UIRootScaleY) or 0.5,
    tonumber(Config.UIRootPosY) or (-(math.clamp(tonumber(Config.UIRootHeight) or 420, 320, 720) / 2))
)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
MainFrame.BackgroundTransparency = Config.UIGlassTransparency or 0.12
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local currentTheme = UIThemes[Config.UITheme] or UIThemes["Red"]

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = currentTheme.Main
MainStroke.Thickness = 1.6
MainStroke.Transparency = 0.25
MainStroke.Parent = MainFrame

do
    local MainGradient = Instance.new("UIGradient")
    MainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 28, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 14, 22))
    })
    MainGradient.Rotation = 65
    MainGradient.Parent = MainFrame
end

-- Central Menu Toggle Handler
if not MainFrame:FindFirstChildOfClass("UIScale") then
    local ms = Instance.new("UIScale")
    ms.Scale = 1.0
    ms.Parent = MainFrame
end

local isMenuAnimating = false
toggleMenu = function()
    if not MainFrame or isMenuAnimating then return end
    isMenuAnimating = true
    local targetW = math.clamp(tonumber(Config.UIRootWidth) or 550, 420, 950)
    local targetH = math.clamp(tonumber(Config.UIRootHeight) or 420, 320, 720)
    local targetScaleX = tonumber(Config.UIRootScaleX) or 0.5
    local targetScaleY = tonumber(Config.UIRootScaleY) or 0.5
    local targetPosX = tonumber(Config.UIRootPosX) or -targetW / 2
    local targetPosY = tonumber(Config.UIRootPosY) or -targetH / 2

    MainFrame.Size = UDim2.new(0, targetW, 0, targetH)
    MainFrame.Position = UDim2.new(targetScaleX, targetPosX, targetScaleY, targetPosY)

    local menuScale = MainFrame:FindFirstChildOfClass("UIScale")
    if not menuScale then
        menuScale = Instance.new("UIScale")
        menuScale.Scale = 1.0
        menuScale.Parent = MainFrame
    end

    if MainFrame.Visible then
        local t = TweenService:Create(menuScale, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
            Scale = 0.92
        })
        t:Play()
        t.Completed:Wait()
        MainFrame.Visible = false
        menuScale.Scale = 1.0
    else
        menuScale.Scale = 0.92
        MainFrame.Visible = true
        local t = TweenService:Create(menuScale, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Scale = 1.0
        })
        t:Play()
        t.Completed:Wait()
    end
    isMenuAnimating = false
end

do
    local isDragging, dragStart, startPos = false, nil, nil
    local isResizing = false
    local resizeStartMouse = nil
    local resizeStartSize = nil

    -- Bottom-Right Corner Resize Grip (◢)
    local ResizeGrip = Instance.new("TextButton")
    ResizeGrip.Name = "ResizeGrip"
    ResizeGrip.Size = UDim2.new(0, 24, 0, 24)
    ResizeGrip.Position = UDim2.new(1, -24, 1, -24)
    ResizeGrip.BackgroundTransparency = 1
    ResizeGrip.Font = Enum.Font.GothamBold
    ResizeGrip.TextSize = 13
    ResizeGrip.TextColor3 = Color3.fromRGB(150, 175, 215)
    ResizeGrip.Text = "◢"
    ResizeGrip.ZIndex = 25
    ResizeGrip.AutoButtonColor = false
    ResizeGrip.Parent = MainFrame

    ResizeGrip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isResizing = true
            resizeStartMouse = input.Position
            resizeStartSize = MainFrame.AbsoluteSize
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isResizing = false
                    Config.UIRootWidth = MainFrame.AbsoluteSize.X
                    Config.UIRootHeight = MainFrame.AbsoluteSize.Y
                    saveConfig()
                end
            end)
        end
    end)

    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isResizing or _G.MM2_IsDraggingSlider then return end
            local mousePos = input.Position
            local headerAbsPos = (Header and Header.AbsolutePosition) or MainFrame.AbsolutePosition
            local headerAbsSize = (Header and Header.AbsoluteSize) or Vector2.new(MainFrame.AbsoluteSize.X, 42)
            local isInHeader = (mousePos.Y >= headerAbsPos.Y and mousePos.Y <= headerAbsPos.Y + headerAbsSize.Y + 4)
            if not isInHeader then return end

            isDragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                    Config.UIRootPosX = MainFrame.Position.X.Offset
                    Config.UIRootPosY = MainFrame.Position.Y.Offset
                    Config.UIRootScaleX = MainFrame.Position.X.Scale
                    Config.UIRootScaleY = MainFrame.Position.Y.Scale
                    saveConfig()
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStartMouse
            local newW = math.clamp(resizeStartSize.X + delta.X, 420, 950)
            local newH = math.clamp(resizeStartSize.Y + delta.Y, 320, 720)
            MainFrame.Size = UDim2.new(0, newW, 0, newH)
        elseif isDragging and not _G.MM2_IsDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

do
    -- ====================================================================
    -- 📱 MOBILE FLOATING BUTTON & RESPONSIVE TOUCH SYSTEM
    -- ====================================================================
    local isMobileDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    if isMobileDevice then
        Config.MobileFloatingButton = true
        Config.MobileAutoScaling = true
    end

    local mobileBtn = Instance.new("TextButton")
    mobileBtn.Name = "MM2_Mobile_Toggle_Button"
    local btnSize = tonumber(Config.MobileButtonSize) or 46
    mobileBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
    mobileBtn.Position = UDim2.new(0, tonumber(Config.MobileButtonPosX) or 20, 0, tonumber(Config.MobileButtonPosY) or 140)
    mobileBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
    mobileBtn.BackgroundTransparency = Config.MobileButtonTransparency or 0.15
    mobileBtn.BorderSizePixel = 0
    mobileBtn.Text = ""
    mobileBtn.AutoButtonColor = false
    mobileBtn.ZIndex = 50
    mobileBtn.Visible = Config.MobileFloatingButton ~= false
    mobileBtn.Parent = ScreenGui
    Instance.new("UICorner", mobileBtn).CornerRadius = UDim.new(1, 0)

    local mStroke = Instance.new("UIStroke")
    mStroke.Color = currentTheme.Main
    mStroke.Thickness = 1.8
    mStroke.Transparency = 0.2
    mStroke.Parent = mobileBtn

    local mGradient = Instance.new("UIGradient")
    mGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 36, 52)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 16, 24))
    })
    mGradient.Rotation = 45
    mGradient.Parent = mobileBtn

    local mIcon = Instance.new("ImageLabel")
    mIcon.Name = "Icon"
    mIcon.Size = UDim2.new(0.68, 0, 0.68, 0)
    mIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    mIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    mIcon.BackgroundTransparency = 1
    mIcon.ZIndex = 51

    local hLogo = nil
    if type(getcustomasset) == "function" and isfile and isfile("vortex_logo_square.png") then
        hLogo = getcustomasset("vortex_logo_square.png")
    elseif Config.HubLogoImage and #Config.HubLogoImage > 5 then
        hLogo = Config.HubLogoImage
    end

    if hLogo then
        mIcon.Image = hLogo
        Instance.new("UICorner", mIcon).CornerRadius = UDim.new(1, 0)
    else
        mIcon.Visible = false
        local mText = Instance.new("TextLabel")
        mText.Size = UDim2.new(1, 0, 1, 0)
        mText.BackgroundTransparency = 1
        mText.Font = Enum.Font.GothamBlack
        mText.TextSize = 20
        mText.TextColor3 = currentTheme.Main
        mText.Text = "⚡"
        mText.ZIndex = 51
        mText.Parent = mobileBtn
    end
    mIcon.Parent = mobileBtn

    local isDraggingBtn = false
    local touchStartPos = nil
    local touchStartTime = 0
    local btnStartPos = nil

    mobileBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingBtn = false
            touchStartPos = input.Position
            touchStartTime = tick()
            btnStartPos = mobileBtn.Position
            TweenService:Create(mobileBtn, TweenInfo.new(0.12), {Size = UDim2.new(0, btnSize - 4, 0, btnSize - 4)}):Play()
        end
    end)

    mobileBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local curSize = tonumber(Config.MobileButtonSize) or 46
            TweenService:Create(mobileBtn, TweenInfo.new(0.15, Enum.EasingStyle.Back), {Size = UDim2.new(0, curSize, 0, curSize)}):Play()
            if touchStartPos then
                local dist = (input.Position - touchStartPos).Magnitude
                if dist < 14 and (tick() - touchStartTime) < 0.6 then
                    toggleMenu()
                end
            end
            if isDraggingBtn then
                isDraggingBtn = false
                Config.MobileButtonPosX = mobileBtn.Position.X.Offset
                Config.MobileButtonPosY = mobileBtn.Position.Y.Offset
                saveConfig()
            end
            touchStartPos = nil
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and touchStartPos then
            local delta = input.Position - touchStartPos
            if delta.Magnitude > 8 then
                isDraggingBtn = true
            end
            if isDraggingBtn then
                local vp = Camera and Camera.ViewportSize or Vector2.new(800, 600)
                local curSize = tonumber(Config.MobileButtonSize) or 46
                local newX = math.clamp(btnStartPos.X.Offset + delta.X, 4, vp.X - curSize - 4)
                local newY = math.clamp(btnStartPos.Y.Offset + delta.Y, 4, vp.Y - curSize - 4)
                mobileBtn.Position = UDim2.new(0, newX, 0, newY)
            end
        end
    end)

    _G.MM2_UpdateMobileButton = function(visible)
        if visible == nil then visible = Config.MobileFloatingButton end
        mobileBtn.Visible = (visible ~= false)
        local curSize = tonumber(Config.MobileButtonSize) or 46
        mobileBtn.Size = UDim2.new(0, curSize, 0, curSize)
        mobileBtn.BackgroundTransparency = Config.MobileButtonTransparency or 0.15
        mStroke.Color = currentTheme.Main
    end

    _G.MM2_ResetMobileButtonPos = function()
        Config.MobileButtonPosX = 20
        Config.MobileButtonPosY = 140
        mobileBtn.Position = UDim2.new(0, 20, 0, 140)
        saveConfig()
    end

    -- 📱 Responsive Mobile Auto-Scaling Engine
    local function applyMobileScaling()
        if not MainFrame or not Camera then return end
        local ms = MainFrame:FindFirstChildOfClass("UIScale")
        if not ms then return end

        local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

        if not Config.MobileAutoScaling and Config.MobileUIScalePct then
            ms.Scale = math.clamp((tonumber(Config.MobileUIScalePct) or 65) / 100, 0.40, 1.0)
            return
        end

        local vp = Camera.ViewportSize
        if vp.X <= 0 or vp.Y <= 0 then return end

        local targetH = tonumber(Config.UIRootHeight) or 420
        local targetW = tonumber(Config.UIRootWidth) or 550

        if isMobile then
            -- Comfortable mobile scale: menu won't fill the entire screen vertically
            local scaleY = (vp.Y * 0.72) / targetH
            local scaleX = (vp.X * 0.70) / targetW
            local finalScale = math.clamp(math.min(scaleX, scaleY), 0.45, 0.78)
            if Config.MobileUIScalePct then
                finalScale = math.clamp((tonumber(Config.MobileUIScalePct) or 65) / 100, 0.40, 1.0)
            else
                Config.MobileUIScalePct = math.floor(finalScale * 100)
            end
            ms.Scale = finalScale
        else
            local scaleY = (vp.Y - 24) / targetH
            local scaleX = (vp.X - 24) / targetW
            local finalScale = math.clamp(math.min(scaleX, scaleY), 0.55, 1.0)
            ms.Scale = finalScale
        end
    end

    _G.MM2_UpdateMobileScaling = applyMobileScaling
    if Camera then
        Camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyMobileScaling)
    end
    task.delay(0.5, applyMobileScaling)

    -- 🎮 Mobile Action HUD Buttons (Independently Draggable with Icon + Text)
    local hudButtons = {}

    local function createDraggableActionBtn(name, iconText, labelText, borderCol, defaultX, defaultY, configKeyX, configKeyY, configEnableKey, cb)
        local btn = Instance.new("TextButton")
        btn.Name = name
        local curW = tonumber(Config.MobileHudBtnWidth) or 84
        local curH = tonumber(Config.MobileHudBtnHeight) or 36
        btn.Size = UDim2.new(0, curW, 0, curH)

        local posX = tonumber(Config[configKeyX]) or defaultX
        local posY = tonumber(Config[configKeyY]) or defaultY
        btn.Position = UDim2.new(1, posX, 1, posY)
        btn.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
        local trans = (tonumber(Config.MobileHudTransparencyPct) or 20) / 100
        btn.BackgroundTransparency = trans
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 45
        local isEnabled = (Config[configEnableKey] ~= false) and (Config.MobileActionHUD ~= false)
        local shouldShow = isEnabled and (UserInputService.TouchEnabled or Config.ShowMobileHUDOnPC == true)
        btn.Visible = shouldShow
        btn.Parent = ScreenGui
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local st = Instance.new("UIStroke")
        st.Color = borderCol
        st.Thickness = 1.6
        st.Transparency = 0.2
        st.Parent = btn

        local grad = Instance.new("UIGradient")
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, borderCol),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 15, 22))
        })
        grad.Rotation = 45
        grad.Parent = btn

        local contentLbl = Instance.new("TextLabel")
        contentLbl.Name = "Label"
        contentLbl.Size = UDim2.new(1, -6, 1, 0)
        contentLbl.Position = UDim2.new(0, 3, 0, 0)
        contentLbl.BackgroundTransparency = 1
        contentLbl.Font = Enum.Font.GothamBold
        contentLbl.TextSize = 10
        contentLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        contentLbl.TextXAlignment = Enum.TextXAlignment.Center
        contentLbl.Text = iconText .. " " .. labelText
        contentLbl.ZIndex = 46
        contentLbl.Parent = btn

        local isDragging = false
        local touchStart = nil
        local touchStartTime = 0
        local startPos = nil

        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = false
                touchStart = input.Position
                touchStartTime = tick()
                startPos = btn.Position
                local w = tonumber(Config.MobileHudBtnWidth) or 84
                local h = tonumber(Config.MobileHudBtnHeight) or 36
                TweenService:Create(btn, TweenInfo.new(0.1), {Size = UDim2.new(0, w - 4, 0, h - 3)}):Play()
            end
        end)

        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local w = tonumber(Config.MobileHudBtnWidth) or 84
                local h = tonumber(Config.MobileHudBtnHeight) or 36
                TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Size = UDim2.new(0, w, 0, h)}):Play()
                if touchStart then
                    local dist = (input.Position - touchStart).Magnitude
                    local dur = tick() - touchStartTime
                    if dist < 10 and dur < 0.45 then
                        pcall(cb)
                    end
                end
                if isDragging then
                    isDragging = false
                    local vp = Camera and Camera.ViewportSize or Vector2.new(800, 600)
                    local absX = btn.AbsolutePosition.X
                    local absY = btn.AbsolutePosition.Y
                    local offX = absX - vp.X
                    local offY = absY - vp.Y
                    Config[configKeyX] = math.floor(offX)
                    Config[configKeyY] = math.floor(offY)
                    saveConfig()
                end
                touchStart = nil
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and touchStart then
                if Config.MobileLockButtons then return end
                local delta = input.Position - touchStart
                if delta.Magnitude > 7 then
                    isDragging = true
                end
                if isDragging then
                    local vp = Camera and Camera.ViewportSize or Vector2.new(800, 600)
                    local w = tonumber(Config.MobileHudBtnWidth) or 84
                    local h = tonumber(Config.MobileHudBtnHeight) or 36
                    local newX = math.clamp(startPos.X.Offset + delta.X, -vp.X + 4, -w - 4)
                    local newY = math.clamp(startPos.Y.Offset + delta.Y, -vp.Y + 4, -h - 4)
                    btn.Position = UDim2.new(1, newX, 1, newY)
                end
            end
        end)

        hudButtons[name] = {
            btn = btn,
            configEnableKey = configEnableKey,
            configKeyX = configKeyX,
            configKeyY = configKeyY,
            defaultX = defaultX,
            defaultY = defaultY
        }
        return btn
    end

    local shootHudBtn = createDraggableActionBtn("ShootBtn", "🔫", "ВЫСТРЕЛ", Color3.fromRGB(45, 160, 255), -105, -190, "MobileShootPosX", "MobileShootPosY", "MobileShootBtnEnabled", function()
        if _G.MM2_PerformInstantShoot then
            _G.MM2_PerformInstantShoot()
        elseif _G.MM2_ShootMurdererDirectly then
            _G.MM2_ShootMurdererDirectly()
        end
    end)

    local knifeHudBtn = createDraggableActionBtn("KnifeBtn", "🗡️", "НОЖ", Color3.fromRGB(255, 55, 75), -105, -145, "MobileKnifePosX", "MobileKnifePosY", "MobileKnifeBtnEnabled", function()
        if _G.MM2_PerformKnifeReachStrike then
            _G.MM2_PerformKnifeReachStrike()
        end
    end)

    local farmHudBtn = createDraggableActionBtn("FarmBtn", "🪙", "ФАРМ", Color3.fromRGB(255, 190, 40), -105, -100, "MobileFarmPosX", "MobileFarmPosY", "MobileFarmBtnEnabled", function()
        Config.CoinAutoFarm = not Config.CoinAutoFarm
        saveConfig()
        if showNotification then
            showNotification("🪙 AUTO-FARM", Config.CoinAutoFarm and "Фарм включен!" or "Фарм выключен!", Config.CoinAutoFarm and Color3.fromRGB(60, 220, 100) or Color3.fromRGB(240, 70, 70), "🪙", 2.0)
        end
    end)

    _G.MM2_UpdateMobileActionHUD = function()
        local isOverallEnabled = (Config.MobileActionHUD ~= false)
        local curW = tonumber(Config.MobileHudBtnWidth) or 84
        local curH = tonumber(Config.MobileHudBtnHeight) or 36
        local trans = (tonumber(Config.MobileHudTransparencyPct) or 20) / 100

        for bName, bData in pairs(hudButtons) do
            local bObj = bData.btn
            local isBtnEnabled = (Config[bData.configEnableKey] ~= false) and isOverallEnabled
            bObj.Visible = isBtnEnabled and (UserInputService.TouchEnabled or Config.ShowMobileHUDOnPC == true)
            bObj.Size = UDim2.new(0, curW, 0, curH)
            bObj.BackgroundTransparency = trans
        end
    end

    _G.MM2_ResetActionHudPos = function()
        for bName, bData in pairs(hudButtons) do
            Config[bData.configKeyX] = bData.defaultX
            Config[bData.configKeyY] = bData.defaultY
            bData.btn.Position = UDim2.new(1, bData.defaultX, 1, bData.defaultY)
        end
        saveConfig()
    end
end

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
Header.BorderSizePixel = 0
Header.Parent = MainFrame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(0, 160, 1, 0)
HeaderTitle.Position = UDim2.new(0, 14, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Font = Enum.Font.GothamBlack
HeaderTitle.TextSize = 13
HeaderTitle.TextColor3 = currentTheme.Main
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Text = "⚡ VORTEX PRIME"
HeaderTitle.Parent = Header

local HeaderTag = Instance.new("TextLabel")
HeaderTag.Size = UDim2.new(0, 85, 0, 20)
HeaderTag.Position = UDim2.new(0, 165, 0.5, -10)

do
    local hLogo = nil
    if type(getcustomasset) == "function" and isfile and isfile("vortex_logo_square.png") then
        hLogo = getcustomasset("vortex_logo_square.png")
    elseif Config.HubLogoImage and #Config.HubLogoImage > 5 then
        hLogo = Config.HubLogoImage
    end
    if hLogo then
        local hIcon = Instance.new("ImageLabel")
        hIcon.Name = "HeaderLogo"
        hIcon.Size = UDim2.new(0, 22, 0, 22)
        hIcon.Position = UDim2.new(0, 10, 0.5, -11)
        hIcon.BackgroundTransparency = 1
        hIcon.Image = hLogo
        hIcon.ZIndex = 2
        hIcon.Parent = Header
        Instance.new("UICorner", hIcon).CornerRadius = UDim.new(0, 5)
        HeaderTitle.Position = UDim2.new(0, 38, 0, 0)
        HeaderTag.Position = UDim2.new(0, 190, 0.5, -10)
    end
end
HeaderTag.BackgroundColor3 = Color3.fromRGB(28, 33, 46)
HeaderTag.Font = Enum.Font.GothamBold
HeaderTag.TextSize = 9
HeaderTag.TextColor3 = currentTheme.Accent
HeaderTag.Text = "MM2 • BETA"
HeaderTag.Parent = Header
Instance.new("UICorner", HeaderTag).CornerRadius = UDim.new(0, 5)

do
    local function initHeaderExecTag()
        local curExecutor = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Executor"
    local curPlatform = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) and "[Mobile]" or "[PC]"
    local hExec = Instance.new("TextLabel")
    hExec.Name = "HeaderExecTag"
    hExec.Size = UDim2.new(0, 115, 0, 18)
    hExec.Position = UDim2.new(0, 260, 0.5, -9)
    hExec.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
    hExec.BackgroundTransparency = 0.35
    hExec.Font = Enum.Font.GothamMedium
    hExec.TextSize = 8
    hExec.TextColor3 = Color3.fromRGB(150, 180, 220)
    hExec.Text = "⚡ " .. tostring(curExecutor) .. " " .. curPlatform
    hExec.TextXAlignment = Enum.TextXAlignment.Center
    hExec.TextTruncate = Enum.TextTruncate.AtEnd
    hExec.Parent = Header
    Instance.new("UICorner", hExec).CornerRadius = UDim.new(0, 4)

    local strk = Instance.new("UIStroke")
    strk.Color = Color3.fromRGB(45, 55, 80)
    strk.Thickness = 1
    strk.Transparency = 0.5
    strk.Parent = hExec
    end
    initHeaderExecTag()
end

do
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 26, 0, 26)
    MinBtn.Position = UDim2.new(1, -62, 0.5, -13)
    MinBtn.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
    MinBtn.Font = Enum.Font.GothamBlack
    MinBtn.TextSize = 13
    MinBtn.TextColor3 = Color3.fromRGB(220, 230, 245)
    MinBtn.Text = "-"
    MinBtn.AutoButtonColor = false
    MinBtn.Parent = Header
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)
    
    MinBtn.MouseButton1Click:Connect(toggleMenu)
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 26, 0, 26)
    CloseBtn.Position = UDim2.new(1, -32, 0.5, -13)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
    CloseBtn.Font = Enum.Font.GothamBlack
    CloseBtn.TextSize = 11
    CloseBtn.TextColor3 = Color3.fromRGB(255, 75, 95)
    CloseBtn.Text = "✕"
    CloseBtn.AutoButtonColor = false
    CloseBtn.Parent = Header
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
    
    CloseBtn.MouseButton1Click:Connect(function()
        _G.MM2_Hub_Cleanup()
    end)
end

local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, -20, 0, 26)
StatusBar.Position = UDim2.new(0, 10, 0, 42)
StatusBar.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
StatusBar.BorderSizePixel = 0
StatusBar.Parent = MainFrame
Instance.new("UICorner", StatusBar).CornerRadius = UDim.new(0, 6)

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -12, 1, 0)
StatusText.Position = UDim2.new(0, 6, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.Font = Enum.Font.GothamBold
StatusText.TextSize = 9
StatusText.TextColor3 = Color3.fromRGB(230, 235, 245)
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Text = "🗺️ Map: Scanning... | 💀 Murderer: None | 🛡️ Sheriff: None"
StatusText.Parent = StatusBar

-- 📱 Content Container (Full Width, Point 5)
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Size = UDim2.new(1, -20, 1, -126)
ContentContainer.Position = UDim2.new(0, 10, 0, 72)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

-- 🔘 Navigation Tab Bar (Dynamic Position: Top, Bottom, Left, Right)
local TabBar = Instance.new("ScrollingFrame")
TabBar.Name = "NavTabBar"
TabBar.Size = UDim2.new(1, -20, 0, 42)
TabBar.Position = UDim2.new(0, 10, 1, -48)
TabBar.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
TabBar.BorderSizePixel = 0
TabBar.ScrollBarThickness = 0
TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
TabBar.CanvasPosition = Vector2.new(0, 0)
TabBar.Parent = MainFrame
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 9)

local TabBarPadding = Instance.new("UIPadding")
TabBarPadding.PaddingLeft = UDim.new(0, 8)
TabBarPadding.PaddingRight = UDim.new(0, 8)
TabBarPadding.PaddingTop = UDim.new(0, 5)
TabBarPadding.PaddingBottom = UDim.new(0, 5)
TabBarPadding.Parent = TabBar

do
    local TabBarStroke = Instance.new("UIStroke")
    TabBarStroke.Color = Color3.fromRGB(45, 55, 78)
    TabBarStroke.Thickness = 1.2
    TabBarStroke.Transparency = 0.25
    TabBarStroke.Parent = TabBar
    
    local TabBarGradient = Instance.new("UIGradient")
    TabBarGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 200, 240))
    })
    TabBarGradient.Rotation = 45
    TabBarGradient.Parent = TabBar
end

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabListLayout.Padding = UDim.new(0, 6)
TabListLayout.Parent = TabBar

local Tabs = {}
local TabButtons = {}

_G.MM2_CurrentTabPosition = Config.TabPosition or "Bottom"

_G.MM2_ApplyTabPosition = function(pos)
    _G.MM2_CurrentTabPosition = pos or "Bottom"
    Config.TabPosition = _G.MM2_CurrentTabPosition
    saveConfig()

    local isHoriz = (_G.MM2_CurrentTabPosition == "Top" or _G.MM2_CurrentTabPosition == "Bottom")
    TabListLayout.FillDirection = isHoriz and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
    TabListLayout.HorizontalAlignment = isHoriz and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center
    TabListLayout.VerticalAlignment = isHoriz and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top
    TabBar.AutomaticCanvasSize = isHoriz and Enum.AutomaticSize.X or Enum.AutomaticSize.Y
    TabBar.CanvasPosition = Vector2.new(0, 0)

    for _, b in pairs(TabButtons) do
        if isHoriz then
            b.AutomaticSize = Enum.AutomaticSize.X
            TweenService:Create(b, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 0, 0, 32)}):Play()
        else
            b.AutomaticSize = Enum.AutomaticSize.None
            TweenService:Create(b, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, -12, 0, 34)}):Play()
        end
    end

    if _G.MM2_CurrentTabPosition == "Bottom" then
        TweenService:Create(TabBar, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -20, 0, 42),
            Position = UDim2.new(0, 10, 1, -48)
        }):Play()
        TweenService:Create(ContentContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 10, 0, 72),
            Size = UDim2.new(1, -20, 1, -126)
        }):Play()
    elseif _G.MM2_CurrentTabPosition == "Top" then
        TweenService:Create(TabBar, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -20, 0, 42),
            Position = UDim2.new(0, 10, 0, 72)
        }):Play()
        TweenService:Create(ContentContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 10, 0, 120),
            Size = UDim2.new(1, -20, 1, -126)
        }):Play()
    elseif _G.MM2_CurrentTabPosition == "Left" then
        TweenService:Create(TabBar, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 120, 1, -80),
            Position = UDim2.new(0, 10, 0, 72)
        }):Play()
        TweenService:Create(ContentContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 136, 0, 72),
            Size = UDim2.new(1, -146, 1, -80)
        }):Play()
    elseif _G.MM2_CurrentTabPosition == "Right" then
        TweenService:Create(TabBar, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 120, 1, -80),
            Position = UDim2.new(1, -130, 0, 72)
        }):Play()
        TweenService:Create(ContentContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 10, 0, 72),
            Size = UDim2.new(1, -146, 1, -80)
        }):Play()
    end
end

local function applyUITheme(themeKey)
    local theme = UIThemes[themeKey] or UIThemes["Red"]
    Config.UITheme = themeKey
    Config.IslandTheme = themeKey
    saveConfig()
    applyIslandTheme(themeKey)

    if MainStroke then MainStroke.Color = theme.Main end
    if HeaderTitle then HeaderTitle.TextColor3 = theme.Main end
    if HeaderTag then HeaderTag.TextColor3 = theme.Accent end

    for tName, tBtn in pairs(TabButtons) do
        if Tabs[tName] and Tabs[tName].Visible then
            TweenService:Create(tBtn, TweenInfo.new(0.2), {BackgroundColor3 = theme.Main, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            local strk = tBtn:FindFirstChildOfClass("UIStroke")
            if strk then strk.Color = theme.Accent end
        end
    end
end

local function applyCustomColor(r, g, b)
    Config.CustomColorR = math.clamp(tonumber(r) or 255, 0, 255)
    Config.CustomColorG = math.clamp(tonumber(g) or 45, 0, 255)
    Config.CustomColorB = math.clamp(tonumber(b) or 85, 0, 255)
    local mainCol = Color3.fromRGB(Config.CustomColorR, Config.CustomColorG, Config.CustomColorB)
    local accCol = Color3.fromRGB(
        math.min(255, Config.CustomColorR + 35),
        math.min(255, Config.CustomColorG + 35),
        math.min(255, Config.CustomColorB + 35)
    )
    UIThemes["Custom"] = { Main = mainCol, Accent = accCol, Name = "Custom Theme" }
    IslandThemeColors["Custom"] = mainCol
    Config.UITheme = "Custom"
    Config.IslandTheme = "Custom"
    applyUITheme("Custom")
    saveConfig()
end

local function createTab(name, icon)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.Position = UDim2.new(0, 0, 0, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = currentTheme.Main
    page.Visible = false
    page.Parent = ContentContainer

    local pageList = Instance.new("UIListLayout")
    pageList.Padding = UDim.new(0, 6)
    pageList.SortOrder = Enum.SortOrder.LayoutOrder
    pageList.Parent = page
    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingRight = UDim.new(0, 8)
    pagePad.PaddingBottom = UDim.new(0, 10)
    pagePad.Parent = page

    pageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pageList.AbsoluteContentSize.Y + 20)
    end)

    local btn = Instance.new("TextButton")
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.Size = UDim2.new(0, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = Color3.fromRGB(170, 185, 210)
    btn.Text = icon .. " " .. name
    btn.AutoButtonColor = false
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    local btnPad = Instance.new("UIPadding")
    btnPad.PaddingLeft = UDim.new(0, 10)
    btnPad.PaddingRight = UDim.new(0, 10)
    btnPad.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(40, 48, 68)
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.5
    btnStroke.Parent = btn

    Tabs[name] = page
    TabButtons[name] = btn

    btn.MouseEnter:Connect(function()
        if Tabs[name].Visible then return end
        TweenService:Create(btn, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(34, 40, 58), TextColor3 = Color3.fromRGB(240, 248, 255)}):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Color = Color3.fromRGB(75, 95, 140), Transparency = 0.2}):Play()
    end)
    btn.MouseLeave:Connect(function()
        if Tabs[name].Visible then return end
        TweenService:Create(btn, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(24, 28, 40), TextColor3 = Color3.fromRGB(170, 185, 210)}):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Color = Color3.fromRGB(40, 48, 68), Transparency = 0.5}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        if Tabs._ActiveTab == name then return end
        local prevTabName = Tabs._ActiveTab
        Tabs._ActiveTab = name

        local curTh = UIThemes[Config.UITheme] or UIThemes["Red"]

        if Config.UISounds ~= false then
            task.spawn(function()
                pcall(function()
                    local ss = game:GetService("SoundService")
                    local s = ss:FindFirstChild("MM2_TabClickSound")
                    if not s then
                        s = Instance.new("Sound")
                        s.Name = "MM2_TabClickSound"
                        s.SoundId = "rbxassetid://6895079853"
                        s.Volume = 0.35
                        s.Parent = ss
                    end
                    s:Play()
                end)
            end)
        end

        -- Deactivate previous tab smoothly
        if prevTabName and Tabs[prevTabName] then
            local prevPage = Tabs[prevTabName]
            local prevBtn = TabButtons[prevTabName]
            local prevStroke = prevBtn and prevBtn:FindFirstChildOfClass("UIStroke")
            prevPage.Visible = false
            if prevBtn then
                TweenService:Create(prevBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(24, 28, 40), TextColor3 = Color3.fromRGB(170, 185, 210)}):Play()
            end
            if prevStroke then
                TweenService:Create(prevStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Color = Color3.fromRGB(40, 48, 68), Transparency = 0.5}):Play()
            end
        end

        -- Activate new tab (Static position = Zero UI layout recalculation freezes)
        page.Position = UDim2.new(0, 0, 0, 0)
        page.Visible = true

        TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundColor3 = curTh.Main, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        if btnStroke then
            TweenService:Create(btnStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Color = curTh.Accent, Transparency = 0}):Play()
        end
    end)
    return page
end

local TabVisuals = createTab("Visuals", "👁️")
local TabCombat = createTab("Combat", "🎯")
local TabFling = createTab("Troll", "🎭")
_G.TabSpectate = createTab("Spectate", "👀")
local TabFarm = createTab("Farm", "🪙")
local TabMisc = createTab("Move", "🏃")
local TabIsland = createTab("Island", "🏝️")
local TabPersonalize = createTab("Themes", "🎨")
local TabSettings = createTab("Settings", "⚙️")
_G.TabConfigs = createTab("Configs", "📁")
_G.TabMobile = createTab("Mobile", "📱")

do
    local isMobilePlatform = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    if TabButtons["Mobile"] then
        TabButtons["Mobile"].Visible = (isMobilePlatform == true) or (Config.ShowMobileTabOnPC == true)
    end
end

Tabs._ActiveTab = "Visuals"
TabButtons["Visuals"].BackgroundColor3 = currentTheme.Main
TabButtons["Visuals"].TextColor3 = Color3.fromRGB(255, 255, 255)
if TabButtons["Visuals"]:FindFirstChildOfClass("UIStroke") then
    TabButtons["Visuals"]:FindFirstChildOfClass("UIStroke").Color = currentTheme.Accent
    TabButtons["Visuals"]:FindFirstChildOfClass("UIStroke").Transparency = 0
end
TabVisuals.Visible = true
_G.MM2_ApplyTabPosition(Config.TabPosition or "Bottom")

local function createToggle(parent, title, configKey, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 36)
    card.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    card.BorderSizePixel = 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(36, 44, 62)
    cardStroke.Thickness = 1
    cardStroke.Transparency = 0.4
    cardStroke.Parent = card

    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(26, 32, 46)}):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(60, 75, 105), Transparency = 0.1}):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(20, 24, 34)}):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(36, 44, 62), Transparency = 0.4}):Play()
    end)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(230, 240, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = title
    lbl.Parent = card

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 20)
    btn.Position = UDim2.new(1, -50, 0.5, -10)
    local curTh = UIThemes[Config.UITheme] or UIThemes["Red"]
    btn.BackgroundColor3 = Config[configKey] and curTh.Main or Color3.fromRGB(34, 38, 52)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = card
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = Config[configKey] and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = btn
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    btn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        local on = Config[configKey]
        saveConfig()

        local th = UIThemes[Config.UITheme] or UIThemes["Red"]
        local targetBg = on and th.Main or Color3.fromRGB(34, 38, 52)
        local targetKnob = on and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        TweenService:Create(btn, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundColor3 = targetBg}):Play()
        TweenService:Create(knob, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = targetKnob}):Play()
        if callback then callback(on) end
    end)

    local function updateToggleVisual(on)
        local th = UIThemes[Config.UITheme] or UIThemes["Red"]
        local targetBg = on and th.Main or Color3.fromRGB(34, 38, 52)
        local targetKnob = on and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        btn.BackgroundColor3 = targetBg
        knob.Position = targetKnob
    end

    if not _G.MM2_UIUpdaters then _G.MM2_UIUpdaters = {} end
    if not _G.MM2_UIUpdaters[configKey] then _G.MM2_UIUpdaters[configKey] = {} end
    table.insert(_G.MM2_UIUpdaters[configKey], function()
        updateToggleVisual(Config[configKey])
        if callback then pcall(callback, Config[configKey]) end
    end)

    return card
end

local function createSlider(parent, title, min, max, configKey, formatStr, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 52)
    card.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    card.BorderSizePixel = 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(36, 44, 62)
    cardStroke.Thickness = 1
    cardStroke.Transparency = 0.4
    cardStroke.Parent = card

    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(26, 32, 46)}):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(60, 75, 105), Transparency = 0.1}):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(20, 24, 34)}):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(36, 44, 62), Transparency = 0.4}):Play()
    end)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.62, 0, 0, 22)
    lbl.Position = UDim2.new(0, 12, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(230, 240, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = title
    lbl.Parent = card

    local valBadge = Instance.new("Frame")
    valBadge.Size = UDim2.new(0, 74, 0, 18)
    valBadge.Position = UDim2.new(1, -84, 0, 6)
    valBadge.BackgroundColor3 = Color3.fromRGB(30, 36, 50)
    valBadge.BorderSizePixel = 0
    valBadge.Parent = card
    Instance.new("UICorner", valBadge).CornerRadius = UDim.new(0, 5)

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(1, 0, 1, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamBlack
    valLbl.TextSize = 9
    valLbl.TextColor3 = Color3.fromRGB(255, 75, 95)

    local function formatVal(v)
        if v == nil then v = min end
        if not formatStr then return tostring(v) end
        local num = tonumber(v)
        if num then
            local ok, res = pcall(string.format, formatStr, num)
            if ok then return res end
        end
        local ok, res = pcall(string.format, formatStr, tostring(v))
        if ok then return res end
        return tostring(v)
    end

    valLbl.Text = formatVal(Config[configKey])
    valLbl.Parent = valBadge

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -24, 0, 8)
    bar.Position = UDim2.new(0, 12, 0, 32)
    bar.BackgroundColor3 = Color3.fromRGB(34, 40, 56)
    bar.BorderSizePixel = 0
    bar.Parent = card
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    local curVal = Config[configKey] ~= nil and Config[configKey] or min
    local range = max - min
    local initRatio = (range > 0) and math.clamp((curVal - min) / range, 0, 1) or 0
    fill.Size = UDim2.new(initRatio, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(235, 50, 75)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local isDraggingSlider = false
    local function updateValue(input)
        local barWidth = bar.AbsoluteSize.X
        if barWidth <= 0 then return end
        local posX = math.clamp(input.Position.X - bar.AbsolutePosition.X, 0, barWidth)
        local pct = posX / barWidth
        local val = min + (range > 0 and (range * pct) or 0)
        if range > 10 then
            val = math.floor(val + 0.5)
        else
            val = math.floor(val * 10 + 0.5) / 10
        end
        val = math.clamp(val, math.min(min, max), math.max(min, max))
        Config[configKey] = val
        saveConfig()
        TweenService:Create(fill, TweenInfo.new(0.06), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
        valLbl.Text = formatVal(val)
        if callback then pcall(callback, val) end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingSlider = true
            _G.MM2_IsDraggingSlider = true
            updateValue(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingSlider = false
            _G.MM2_IsDraggingSlider = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateValue(input)
        end
    end)

    local function updateSliderVisual(curV)
        local r = max - min
        local ratio = (r > 0) and math.clamp((curV - min) / r, 0, 1) or 0
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        valLbl.Text = formatVal(curV)
    end

    if not _G.MM2_UIUpdaters then _G.MM2_UIUpdaters = {} end
    if not _G.MM2_UIUpdaters[configKey] then _G.MM2_UIUpdaters[configKey] = {} end
    table.insert(_G.MM2_UIUpdaters[configKey], function()
        local curV = Config[configKey] ~= nil and Config[configKey] or min
        updateSliderVisual(curV)
        if callback then pcall(callback, curV) end
    end)

    return card
end

_G.MM2_RefreshAllUI = function()
    if _G.MM2_UIUpdaters then
        for _, list in pairs(_G.MM2_UIUpdaters) do
            if type(list) == "table" then
                for _, fn in ipairs(list) do
                    pcall(fn)
                end
            elseif type(list) == "function" then
                pcall(list)
            end
        end
    end
end

local function createButton(parent, title, accentColor, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = accentColor or Color3.fromRGB(235, 50, 75)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = title
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(255, 255, 255)
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.75
    btnStroke.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundTransparency = 0.15}):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.18), {Transparency = 0.3}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundTransparency = 0}):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.18), {Transparency = 0.75}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, -4, 0, 32)}):Play()
        task.delay(0.08, function()
            if btn and btn.Parent then
                TweenService:Create(btn, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 34)}):Play()
            end
        end)
        if callback then callback() end
    end)
    return btn
end

local function createSectionHeader(parent, text)
    local headerFrame = Instance.new("Frame")
    headerFrame.Size = UDim2.new(1, 0, 0, 24)
    headerFrame.BackgroundTransparency = 1
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = parent

    local headerLbl = Instance.new("TextLabel")
    headerLbl.Size = UDim2.new(1, 0, 1, 0)
    headerLbl.BackgroundTransparency = 1
    headerLbl.Font = Enum.Font.GothamBlack
    headerLbl.TextSize = 10
    headerLbl.TextColor3 = Color3.fromRGB(130, 155, 195)
    headerLbl.TextXAlignment = Enum.TextXAlignment.Left
    headerLbl.Text = text
    headerLbl.Parent = headerFrame
    return headerFrame
end

local function createKeybindButton(parent, title, configKey, allowedKeys)
    local keys = allowedKeys or {"RightShift", "Insert", "F4", "RightAlt", "E", "Q", "X", "C", "Z", "F", "None"}
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 36)
    card.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    card.BorderSizePixel = 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.65, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(230, 240, 255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = title
    lbl.Parent = card

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 95, 0, 24)
    btn.Position = UDim2.new(1, -105, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(32, 38, 54)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.TextColor3 = Color3.fromRGB(255, 215, 80)
    btn.Text = "[ " .. tostring(Config[configKey] or "None") .. " ]"
    btn.AutoButtonColor = false
    btn.Parent = card
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        local current = Config[configKey] or "None"
        local idx = 1
        for i, k in ipairs(keys) do
            if k == current then idx = i; break end
        end
        local nextIdx = (idx % #keys) + 1
        Config[configKey] = keys[nextIdx]
        saveConfig()
        btn.Text = "[ " .. tostring(Config[configKey]) .. " ]"
        showNotification("⌨️ KEYBIND CHANGED", string.format("%s set to [%s]", title, Config[configKey]), Color3.fromRGB(255, 215, 80), "⌨️", 2.5)
    end)
    return card
end

-- ====================================================================
-- 🌐 AUTONOMOUS TELEPORT, RE-INJECT & MM2 SERVER HOP ENGINE (NO AUTOEXEC)
-- ====================================================================
local serverHop, rejoinServer, rejoinSameServer, setupQueueOnTeleport, armQueueOnTeleport
do
    local TeleportService = game:GetService("TeleportService")
    local GuiService = game:GetService("GuiService")
    local CoreGui = game:GetService("CoreGui")
    local VISITED_SERVERS_FILE = "MM2_Visited_Servers.json"
    local SERVER_CACHE_FILE = "MM2_Server_Cache.json"

    -- [[ 1. ROBUST VISITED SERVERS AND SERVER CACHE ENGINE ]]
    local function getVisitedServers()
        if type(_G.MM2_VisitedServers) ~= "table" then
            _G.MM2_VisitedServers = {}
        end
        pcall(function()
            if readfile and isfile and isfile(VISITED_SERVERS_FILE) then
                local data = HttpService:JSONDecode(readfile(VISITED_SERVERS_FILE))
                if type(data) == "table" then
                    local now = os.time()
                    for k, v in pairs(data) do
                        -- Prune servers visited more than 30 minutes (1800s) ago
                        if type(v) == "number" and (now - v) < 1800 then
                            _G.MM2_VisitedServers[k] = v
                        end
                    end
                end
            end
        end)
        return _G.MM2_VisitedServers
    end

    local function addVisitedServer(jobId)
        if not jobId or jobId == "" then return end
        local visited = getVisitedServers()
        visited[jobId] = os.time()
        pcall(function()
            if writefile then
                writefile(VISITED_SERVERS_FILE, HttpService:JSONEncode(visited))
            end
        end)
    end

    local function getCachedServers()
        local list = {}
        pcall(function()
            if readfile and isfile and isfile(SERVER_CACHE_FILE) then
                local data = HttpService:JSONDecode(readfile(SERVER_CACHE_FILE))
                if type(data) == "table" then
                    list = data
                end
            end
        end)
        return list
    end

    local function updateCachedServers(newIds)
        if type(newIds) ~= "table" or #newIds == 0 then return end
        pcall(function()
            local existing = getCachedServers()
            local map = {}
            for _, id in ipairs(existing) do
                if type(id) == "string" and #id > 10 then map[id] = true end
            end
            for _, id in ipairs(newIds) do
                if type(id) == "string" and #id > 10 then map[id] = true end
            end
            local merged = {}
            for id in pairs(map) do
                table.insert(merged, id)
                if #merged >= 200 then break end
            end
            if writefile then
                writefile(SERVER_CACHE_FILE, HttpService:JSONEncode(merged))
            end
        end)
    end

    -- [[ 2. AUTONOMOUS IN-SCRIPT AUTO-REINJECT (NO AUTOEXEC FOLDER NEEDED) ]]
    function armQueueOnTeleport()
        if Config.AutoQueueOnTeleport == false then return end
        local queueFunc = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        if not queueFunc then return end

        pcall(function()
            local delaySecs = math.clamp(tonumber(Config.TeleportInjectDelay) or 4.0, 2.0, 15.0)
            local injectPayload = string.format([=[
                -- MM2 AUTONOMOUS RE-INJECTOR (POTASSIUM / REAL HUB)
                task.spawn(function()
                    repeat task.wait(0.2) until game:IsLoaded()
                    local Players = game:GetService("Players")
                    local lp = Players.LocalPlayer or Players.PlayerAdded:Wait()
                    local waited = 0
                    while not lp and waited < 30 do
                        task.wait(0.2)
                        waited = waited + 0.2
                        lp = Players.LocalPlayer
                    end
                    if not lp then return end

                    -- Verify MM2 game place
                    local mm2Places = { [142823291] = true, [335132778] = true, [335132309] = true }
                    if not mm2Places[game.PlaceId] and game.GameId ~= 66654135 then
                        return
                    end

                    -- Wait for player interface & character
                    pcall(function() lp:WaitForChild("PlayerGui", 25) end)
                    local char = lp.Character or lp.CharacterAdded:Wait()
                    pcall(function() char:WaitForChild("HumanoidRootPart", 25) end)
                    task.wait(%.1f)

                    if _G.MM2_Hub_Running then return end

                    local candidates = {
                        "MM2_Potassium_Hub.lua",
                        "Vortex_Prime_MM2.lua",
                        "Scripts/MM2_Potassium_Hub.lua",
                        "Scripts/Vortex_Prime_MM2.lua"
                    }

                    for _, fname in ipairs(candidates) do
                        if isfile and isfile(fname) and readfile then
                            local content = readfile(fname)
                            if content and #content > 500 then
                                local fn, err = loadstring(content)
                                if fn then
                                    print("[AutoInject] Successfully reinjected " .. fname)
                                    task.spawn(fn)
                                    return
                                else
                                    warn("[AutoInject] Compile error in " .. fname .. ": " .. tostring(err))
                                end
                            end
                        end
                    end
                    warn("[AutoInject] Could not find hub script in workspace.")
                end)
            ]=], delaySecs)
            queueFunc(injectPayload)
        end)
    end
    setupQueueOnTeleport = armQueueOnTeleport

    -- Hook player teleport event so ANY teleport (even user/game initiated) auto-arms queue
    pcall(function()
        LocalPlayer.OnTeleport:Connect(function(state)
            armQueueOnTeleport()
        end)
    end)
    -- Proactively arm immediately on script execution
    armQueueOnTeleport()

    -- [[ 3. BULLETPROOF SERVER FINDER & HOP ENGINE (NEVER SAME SERVER) ]]
    local isHopping = false
    local function findTargetServer(curPlace)
        local currentJob = game.JobId
        addVisitedServer(currentJob)
        local visited = getVisitedServers()
        local minPlayers = tonumber(Config.MinServerPlayers) or 2

        -- Attempt 1: Fetch fresh servers from Roblox Public Games API with sortOrder=Asc
        local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        local body = nil
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", curPlace)
        
        pcall(function()
            if req then
                local res = req({
                    Url = url,
                    Method = "GET",
                    Headers = {
                        ["User-Agent"] = "Roblox/WinInet",
                        ["Accept"] = "application/json"
                    }
                })
                if res and res.Body and (res.StatusCode == 200 or not res.StatusCode) then
                    body = res.Body
                end
            elseif game.HttpGet then
                body = game:HttpGet(url)
            end
        end)

        local foundCandidates = {}
        local fallbackCandidates = {}
        local allExtractedIds = {}

        if body and #body > 50 then
            pcall(function()
                local json = HttpService:JSONDecode(body)
                if json and json.data and type(json.data) == "table" then
                    for _, s in ipairs(json.data) do
                        if type(s) == "table" and s.id and s.playing and s.maxPlayers then
                            local sId = tostring(s.id)
                            local playing = tonumber(s.playing) or 0
                            local maxPlr = tonumber(s.maxPlayers) or 12
                            local rawPing = tonumber(s.ping)
                            local fps = tonumber(s.fps) or 60.0
                            table.insert(allExtractedIds, sId)

                            -- Strictly ensure NOT current server, NOT visited, and HAS free slots
                            if sId ~= currentJob and not visited[sId] and playing < maxPlr then
                                local candidate = {
                                    id = sId,
                                    ping = (rawPing and rawPing > 0) and rawPing or 99999,
                                    hasRealPing = (rawPing ~= nil and rawPing > 0),
                                    fps = fps,
                                    playing = playing,
                                    maxPlayers = maxPlr
                                }
                                if playing >= minPlayers and playing <= (maxPlr - 1) then
                                    table.insert(foundCandidates, candidate)
                                elseif playing >= 1 then
                                    table.insert(fallbackCandidates, candidate)
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- Cache all extracted server IDs for offline / 429 rate limit fallback
        if #allExtractedIds > 0 then
            updateCachedServers(allExtractedIds)
        end

        -- Lowest Ping First Comparator
        local function sortServersByPing(list)
            table.sort(list, function(a, b)
                if a.hasRealPing ~= b.hasRealPing then
                    return a.hasRealPing
                end
                if a.ping ~= b.ping then
                    return a.ping < b.ping
                end
                if math.abs(a.fps - b.fps) > 0.5 then
                    return a.fps > b.fps
                end
                return a.playing > b.playing
            end)
        end

        -- If servers found, pick the fastest one by ping!
        if #foundCandidates > 0 then
            sortServersByPing(foundCandidates)
            local best = foundCandidates[1]
            return best.id, best.ping, best.playing, best.maxPlayers, best.hasRealPing
        elseif #fallbackCandidates > 0 then
            sortServersByPing(fallbackCandidates)
            local best = fallbackCandidates[1]
            return best.id, best.ping, best.playing, best.maxPlayers, best.hasRealPing
        end

        -- Attempt 2: Use persistent cached server pool from previous successful scans
        local cached = getCachedServers()
        local cachedValid = {}
        for _, id in ipairs(cached) do
            if id ~= currentJob and not visited[id] then
                table.insert(cachedValid, id)
            end
        end
        if #cachedValid > 0 then
            return cachedValid[math.random(1, #cachedValid)], nil, nil, nil, false
        end

        -- Attempt 3: If all known servers have been visited, reset visited history (except current server)
        _G.MM2_VisitedServers = { [currentJob] = os.time() }
        pcall(function()
            if writefile then
                writefile(VISITED_SERVERS_FILE, HttpService:JSONEncode(_G.MM2_VisitedServers))
            end
        end)
        for _, id in ipairs(cached) do
            if id ~= currentJob then
                table.insert(cachedValid, id)
            end
        end
        if #cachedValid > 0 then
            return cachedValid[math.random(1, #cachedValid)], nil, nil, nil, false
        end

        return nil
    end

    function serverHop()
        if isHopping then return false, "Already hopping" end
        local curPlace = game.PlaceId
        if curPlace ~= 142823291 and curPlace ~= 335132778 then
            showNotification("⚠️ SERVER HOP ERROR", "Server hop is restricted to MM2 places only!", Color3.fromRGB(255, 60, 60), "❌", 4)
            return false, "Restricted to MM2"
        end

        isHopping = true
        showNotification("⚡ ПОИСК БЫСТРОГО СЕРВЕРА", "Поиск сервера с минимальным пингом...", Color3.fromRGB(60, 160, 255), "⚡", 4)
        armQueueOnTeleport()
        pcall(saveConfig)
        if _G.MM2_SaveAllTimeStats then pcall(_G.MM2_SaveAllTimeStats) end

        task.spawn(function()
            local targetServer, targetPing, targetPlayers, targetMax, hasRealPing = findTargetServer(curPlace)
            if targetServer and targetServer ~= game.JobId then
                addVisitedServer(targetServer)
                local pingInfo = (hasRealPing and targetPing and targetPing > 0 and targetPing < 9000)
                    and string.format(" • Пинг: %d ms", targetPing)
                    or ""
                local playersInfo = (targetPlayers and targetMax)
                    and string.format(" • Игроков: %d/%d", targetPlayers, targetMax)
                    or ""
                showNotification("🚀 БЫСТРЫЙ СЕРВЕР", string.format("Подключение к лучшему серверу%s%s...", pingInfo, playersInfo), Color3.fromRGB(50, 220, 120), "⚡", 4)
                task.wait(0.5)
                local ok, err = pcall(function()
                    TeleportService:TeleportToPlaceInstance(curPlace, targetServer, LocalPlayer)
                end)
                if not ok then
                    warn("[ServerHop] TeleportToPlaceInstance failed:", err)
                    task.wait(2)
                    isHopping = false
                end
            else
                -- Guaranteed fresh server hop fallback (never returns to current JobId):
                -- If in main place, jump to Trading Lounge or vice-versa to cleanly cycle matchmaking
                local altPlace = (curPlace == 142823291) and 335132778 or 142823291
                showNotification("🔄 MM2 HOP ALTERNATE", "Переход через альтернативный MM2 хаб...", Color3.fromRGB(255, 180, 50), "🌐", 4)
                task.wait(0.5)
                pcall(function()
                    TeleportService:Teleport(altPlace, LocalPlayer)
                end)
                task.wait(5)
                isHopping = false
            end
        end)
        return true
    end

    -- Rejoin server alias: smart rejoin finds a NEW server
    rejoinServer = serverHop

    -- Explicit function if player specifically wants the EXACT same JobId
    function rejoinSameServer()
        local curPlace = game.PlaceId
        if curPlace ~= 142823291 and curPlace ~= 335132778 then return end
        showNotification("🔁 REJOINING SAME", "Reconnecting to same MM2 server...", Color3.fromRGB(80, 200, 255), "🔁", 4)
        armQueueOnTeleport()
        TeleportService:TeleportToPlaceInstance(curPlace, game.JobId, LocalPlayer)
    end

    -- If a teleport fails (e.g. server became full during handshake), automatically retry to next server
    pcall(function()
        TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
            warn("[Teleport] TeleportInitFailed: " .. tostring(errorMessage) .. " (Code: " .. tostring(teleportResult) .. ")")
            isHopping = false
            task.wait(2)
            showNotification("⚠️ ОШИБКА ПОДКЛЮЧЕНИЯ", "Сервер заполнился! Поиск другого сервера...", Color3.fromRGB(255, 120, 50), "⚠️", 4)
            serverHop()
        end)
    end)

    -- [[ 4. AUTO-RECONNECT ON KICK (NEVER SAME SERVER) ]]
    local isReconnecting = false
    local lastReconnectAttempt = 0
    local scriptStartTime = os.clock()

    local function handleAutoReconnect(reason)
        if isReconnecting then return end
        if Config.AutoReconnectOnKick == false and Config.AutoReconnect == false then return end
        if (os.clock() - scriptStartTime) < 10 then return end
        if (os.clock() - lastReconnectAttempt) < 15 then return end

        local curPlace = game.PlaceId
        if curPlace ~= 142823291 and curPlace ~= 335132778 then return end

        isReconnecting = true
        lastReconnectAttempt = os.clock()
        armQueueOnTeleport()

        local delaySecs = math.clamp(tonumber(Config.AutoReconnectDelay) or 6.0, 3.0, 30.0)
        task.spawn(function()
            if showNotification then
                showNotification("🔁 АВТО-ПЕРЕЗАХОД В MM2", string.format("Обнаружен кик/дисконнект (%s)! Поиск нового сервера через %.0f сек...", tostring(reason or "Disconnect"), delaySecs), Color3.fromRGB(255, 60, 60), "⚠️", 5)
            end
            task.wait(delaySecs)
            serverHop()
            task.wait(10)
            isReconnecting = false
        end)
    end

    pcall(function()
        GuiService.ErrorMessageChanged:Connect(function()
            local msg = GuiService:GetErrorMessage()
            if msg and #msg > 0 and msg ~= "" then
                handleAutoReconnect("GuiService: " .. tostring(msg))
            end
        end)
    end)

    pcall(function()
        local robloxPrompt = CoreGui:WaitForChild("RobloxPromptGui", 5)
        local promptOverlay = robloxPrompt and robloxPrompt:WaitForChild("promptOverlay", 5)
        if promptOverlay then
            promptOverlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" then
                    task.wait(0.2)
                    if child:IsA("GuiObject") and child.Visible then
                        handleAutoReconnect("ErrorPrompt")
                    end
                end
            end)
        end
    end)

    -- [[ 5. AUTONOMOUS LOW PLAYER COUNT SERVER HOP ]]
    local isAutoHoppingLow = false
    local function checkLowPlayerCount()
        if Config.AutoServerHopLowPlayers == false or isAutoHoppingLow then return end
        if (os.clock() - scriptStartTime) < 25 then return end
        local plrs = Players:GetPlayers()
        local count = #plrs
        local threshold = tonumber(Config.MinServerPlayers) or 3
        if count >= 1 and count <= threshold then
            isAutoHoppingLow = true
            task.spawn(function()
                if showNotification then
                    showNotification("🌐 МАЛО ИГРОКОВ", string.format("На сервере осталось %d чел.! Поиск нового активного сервера MM2...", count), Color3.fromRGB(255, 175, 45), "🌐", 4)
                end
                task.wait(2.5)
                local currentCount = #Players:GetPlayers()
                if currentCount <= threshold then
                    serverHop()
                else
                    isAutoHoppingLow = false
                end
            end)
        end
    end

    Players.PlayerRemoving:Connect(function()
        task.delay(1.5, checkLowPlayerCount)
    end)

    task.spawn(function()
        while _G.MM2_Hub_Running and (_G.MM2_Hub_InstanceID == InstanceID) do
            task.wait(6)
            checkLowPlayerCount()
        end
    end)

    -- [[ 6. AUTONOMOUS BROKEN / FROZEN SERVER DETECTOR & AUTO-HOP ]]
    local isAutoHoppingBroken = false
    local lobbyWaitStartTime = os.clock()
    _G.MM2_LobbyWaitStartTime = lobbyWaitStartTime

    local function checkBrokenServer()
        if Config.AutoHopBrokenServer == false or isAutoHoppingBroken or isHopping then
            return
        end
        if (os.clock() - scriptStartTime) < 20 then
            return
        end

        local roundActive = isRoundActive and isRoundActive()
        local inLobby = isPlayerInLobby and isPlayerInLobby(LocalPlayer)
        local curMap = CachedMap or (getCurrentMap and getCurrentMap())

        if roundActive or (curMap ~= nil and not inLobby) then
            lobbyWaitStartTime = os.clock()
            _G.MM2_LobbyWaitStartTime = lobbyWaitStartTime
            return
        end

        local waitedDuration = os.clock() - lobbyWaitStartTime
        local timeout = tonumber(Config.BrokenServerTimeout) or 65

        if waitedDuration >= timeout then
            isAutoHoppingBroken = true
            task.spawn(function()
                if showNotification then
                    showNotification("⚠️ ЗАВИСШИЙ СЕРВЕР ОБНАРУЖЕН!", string.format("Катка не начинается уже %d сек. (баг MM2). Ищем живой рабочий сервер...", math.floor(waitedDuration)), Color3.fromRGB(255, 75, 75), "🔄", 6)
                end
                if flashDynamicIslandAlert then
                    flashDynamicIslandAlert("⚠️ ЗАВИСШИЙ СЕРВЕР • HOPPING", Color3.fromRGB(255, 75, 75), 4)
                end
                task.wait(2.5)
                local stillWaiting = not (isRoundActive and isRoundActive())
                if stillWaiting then
                    serverHop()
                else
                    isAutoHoppingBroken = false
                    lobbyWaitStartTime = os.clock()
                    _G.MM2_LobbyWaitStartTime = lobbyWaitStartTime
                end
            end)
        end
    end

    task.spawn(function()
        while _G.MM2_Hub_Running and (_G.MM2_Hub_InstanceID == InstanceID) do
            task.wait(3)
            checkBrokenServer()
        end
    end)
end

local function resetConfig()
    local defaults = {
        ShootOnRightClick = true,
        MurdererESP = true,
        SheriffESP = true,
        HeroESP = true,
        InnocentESP = true,
        LobbyESP = true,
        GunDropESP = true,
        CoinESP = true,
        Tracers = true,
        TracerOrigin = "Bottom",
        OffscreenRadar = true,
        EventNotifications = true,
        NotificationSounds = true,
        DynamicIsland = true,
        IslandShowTime = true,
        IslandShowRole = true,
        IslandShowStatus = true,
        IslandHoverExpand = true,
        IslandFlashAlerts = true,
        IslandWidth = 310,
        IslandHeight = 32,
        IslandYOffset = 12,
        IslandTransparency = 0.15,
        IslandTransparencyPct = 15,
        IslandTheme = "Red",
        IslandSyncTheme = true,
        IslandTextSize = 10,
        SilentAim = true,
        SilentAimVisuals = true,
        SilentAimWeaponOnly = true,
        SilentAimWallBang = true,
        WallBangAllMap = true,
        WallPenetrationOffset = 0.35,
        AutoShot = false,
        AutoShotDelay = 0.8,
        WallBang = false,
        WallCheck = true,
        PredictionBulletSpeed = 320,
        PredictMovement = true,
        PredictionPingCompensation = true,
        PredictionPingMultiplier = 1.15,
        MurdererAlert = true,
        AlertDistance = 35,
        KnifeAura = false,
        KnifeReachEnabled = true,
        KnifeReachKeybind = "F",
        KnifeAutoEquip = true,
        KnifeReachHighlight = true,
        KnifeReachBlink = true,
        KnifeReachMaxDist = 2500,
        KnifeThrowEnabled = true,
        KnifeThrowKeybind = "E",
        KnifeThrowOnLeftClick = true,
        KnifeThrowOnRightClick = true,
        AntiFling = true,
        TrapESP = true,
        HitmarkerEnabled = true,
        HitmarkerVisual = true,
        HitmarkerSound = true,
        HitmarkerStyle = "Classic X",
        HitmarkerColor = "Crimson",
        HitmarkerSize = 28,
        HitmarkerDuration = 0.25,
        HitmarkerSoundPreset = "Neverlose",
        HitmarkerCustomSoundFile = "Hitsounds/sounds/neverlose.mp3",
        HitmarkerVolume = 80,
        HitmarkerKillEffect = true,
        HitmarkerKillSoundPreset = "Kill 1 (Echo)",
        HitmarkerKillVolume = 90,
        CoinCinematicCamera = true,
        CoinTargetHighlight = true,
        Disable3DRender = false,
        KnifeSpin = false,
        FakeDead = false,
        FlingActive = false,
        FlingMethod = "BodyVelocity",
        FlingPower = 10,
        FlingDuration = 1.5,
        FlingReturnToOldPos = true,
        FlingPriority = "Murderer",
        AutoGrabGun = true,
        CoinAutoFarm = false,
        CoinFarmMethod = "Tween",
        CoinTeleportCooldown = 0.05,
        CoinAura = true,
        CoinAuraRadius = 7.0,
        KnifeAura = false,
        KnifeAuraRadius = 24,
        KnifeAuraShowRadius = true,
        KnifeAuraWallCheck = false,
        CoinFarmDelay = 0.05,
        CoinTweenSpeed = 26,
        CoinFarmYOffset = -2.5,
        CoinFarmProne = true,
        CoinFarmUnderground = true,
        CoinAutoRespawn = true,
        CoinUndergroundPlatform = true,
        CoinLobbyHide = true,
        CoinPostAction = "KillAll_Or_Shoot",
        CoinAntiVoid = true,
        MaxCoins = 40,
        SpeedHack = false,
        WalkSpeed = 24,
        InfiniteJump = false,
        Noclip = false,
        AntiAFK = true,
        TabPosition = "Bottom",
        Fly = false,
        FlySpeed = 32,
        Fullbright = false,
        UITheme = "Red",
        UIGlassTransparency = 0.12,
        UIGlassTransparencyPct = 12,
        ShowWelcome = true,
        UISounds = true,
        AutoLoadConfig = true,
        AutoQueueOnTeleport = true,
        AutoReconnect = true,
        AutoServerHopLowPlayers = true,
        MinServerPlayers = 3,
        AutoHopBrokenServer = true,
        BrokenServerTimeout = 65,
        MenuKeybind = "RightShift",
        SilentAimKeybind = "None",
        ShootOnLeftClick = false,
        ShootOnRightClick = false,
        AutoShotKeybind = "None",
        InstantShootKeybind = "E",
    }
    for k, v in pairs(defaults) do
        Config[k] = v
    end
    saveConfig()
    applyUITheme(Config.UITheme)
    if _G.MM2_RefreshAllUI then _G.MM2_RefreshAllUI() end
    showNotification("♻️ RESET CONFIG", "Settings reset to default values!", Color3.fromRGB(255, 180, 50), "♻️", 3)
end

-- ====================================================================
-- 👋 WELCOME MODAL SPLASH CARD (Point 5)
-- ====================================================================
-- ⚡ CINEMATIC SPLASH INTRO & WELCOME MODAL
-- ====================================================================
local showWelcomeModal
do
    local function resolveHubLogo()
        if Config.HubLogoImage and type(Config.HubLogoImage) == "string" and #Config.HubLogoImage > 5 then
            return Config.HubLogoImage
        end
        if type(getcustomasset) == "function" and isfile then
            if isfile("vortex_logo_square.png") then
                return getcustomasset("vortex_logo_square.png")
            elseif isfile("vortex_logo.png") then
                return getcustomasset("vortex_logo.png")
            end
        end
        return nil
    end
    _G.MM2_ResolveHubLogo = resolveHubLogo

    local function showSplashIntro(onComplete)
        if not ScreenGui then
            if onComplete then onComplete() end
            return
        end
        local old = ScreenGui:FindFirstChild("MM2_SplashIntro")
        if old then pcall(function() old:Destroy() end) end

        local curTh = (UIThemes and UIThemes[Config.UITheme]) or { Main = Color3.fromRGB(235, 50, 75), Accent = Color3.fromRGB(255, 90, 115) }

        local splash = Instance.new("Frame")
        splash.Name = "MM2_SplashIntro"
        splash.Size = UDim2.new(0, 450, 0, 230)
        splash.Position = UDim2.new(0.5, -225, 0.5, -115)
        splash.BackgroundColor3 = Color3.fromRGB(11, 14, 22)
        splash.BackgroundTransparency = 1
        splash.BorderSizePixel = 0
        splash.ClipsDescendants = true
        splash.ZIndex = 60
        splash.Parent = ScreenGui
        Instance.new("UICorner", splash).CornerRadius = UDim.new(0, 16)

        local splashStroke = Instance.new("UIStroke")
        splashStroke.Color = curTh.Main
        splashStroke.Thickness = 2
        splashStroke.Transparency = 1
        splashStroke.Parent = splash

        local splashGrad = Instance.new("UIGradient")
        splashGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 23, 35)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 10, 15)),
        })
        splashGrad.Rotation = 90
        splashGrad.Parent = splash

        local topSheen = Instance.new("Frame")
        topSheen.Size = UDim2.new(1, -28, 0, 1)
        topSheen.Position = UDim2.new(0, 14, 0, 1)
        topSheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        topSheen.BackgroundTransparency = 1
        topSheen.BorderSizePixel = 0
        topSheen.ZIndex = 61
        topSheen.Parent = splash
        Instance.new("UICorner", topSheen).CornerRadius = UDim.new(1, 0)
        local sheenGrad = Instance.new("UIGradient")
        sheenGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.3, 0.4),
            NumberSequenceKeypoint.new(0.7, 0.4),
            NumberSequenceKeypoint.new(1, 1),
        })
        sheenGrad.Parent = topSheen

        local resolvedLogo = resolveHubLogo()

        local logoContainer = Instance.new("Frame")
        logoContainer.Name = "LogoContainer"
        logoContainer.Size = UDim2.new(0, 0, 0, 0)
        logoContainer.Position = UDim2.new(0.5, 0, 0, 44)
        logoContainer.BackgroundColor3 = Color3.fromRGB(16, 20, 32)
        logoContainer.BackgroundTransparency = 1
        logoContainer.BorderSizePixel = 0
        logoContainer.ZIndex = 62
        logoContainer.Parent = splash
        Instance.new("UICorner", logoContainer).CornerRadius = UDim.new(0, 12)

        local logoStroke = Instance.new("UIStroke")
        logoStroke.Color = curTh.Main
        logoStroke.Thickness = 2
        logoStroke.Transparency = 1
        logoStroke.Parent = logoContainer

        local logoContent
        if resolvedLogo then
            logoContent = Instance.new("ImageLabel")
            logoContent.Size = UDim2.new(1, 0, 1, 0)
            logoContent.Position = UDim2.new(0, 0, 0, 0)
            logoContent.BackgroundTransparency = 1
            logoContent.Image = resolvedLogo
            logoContent.ImageTransparency = 1
            logoContent.ZIndex = 63
            logoContent.Parent = logoContainer
            Instance.new("UICorner", logoContent).CornerRadius = UDim.new(0, 12)
        else
            logoContent = Instance.new("TextLabel")
            logoContent.Size = UDim2.new(1, 0, 1, 0)
            logoContent.Position = UDim2.new(0, 0, 0, 0)
            logoContent.BackgroundTransparency = 1
            logoContent.Font = Enum.Font.GothamBlack
            logoContent.TextSize = 34
            logoContent.TextColor3 = curTh.Accent
            logoContent.Text = "⚡"
            logoContent.TextTransparency = 1
            logoContent.ZIndex = 63
            logoContent.Parent = logoContainer
        end

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, 0, 0, 24)
        titleLabel.Position = UDim2.new(0, 0, 0, 96)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Enum.Font.GothamBlack
        titleLabel.TextSize = 18
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.Text = "⚡ VORTEX PRIME MM2"
        titleLabel.TextTransparency = 1
        titleLabel.ZIndex = 62
        titleLabel.Parent = splash

        local versionBadge = Instance.new("TextLabel")
        versionBadge.Size = UDim2.new(1, 0, 0, 16)
        versionBadge.Position = UDim2.new(0, 0, 0, 118)
        versionBadge.BackgroundTransparency = 1
        versionBadge.Font = Enum.Font.GothamBold
        versionBadge.TextSize = 10
        versionBadge.TextColor3 = curTh.Accent
        versionBadge.Text = "MURDER MYSTERY 2  •  PREMIUM EDITION  [v4.2 BETA]"
        versionBadge.TextTransparency = 1
        versionBadge.ZIndex = 62
        versionBadge.Parent = splash

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Size = UDim2.new(1, -40, 0, 18)
        statusLabel.Position = UDim2.new(0, 20, 0, 142)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Font = Enum.Font.GothamMedium
        statusLabel.TextSize = 11
        statusLabel.TextColor3 = Color3.fromRGB(170, 185, 215)
        statusLabel.Text = "🛡️ Initializing Quantum Bypass & Binds..."
        statusLabel.TextTransparency = 1
        statusLabel.ZIndex = 62
        statusLabel.Parent = splash

        local progressTrack = Instance.new("Frame")
        progressTrack.Size = UDim2.new(0, 320, 0, 5)
        progressTrack.Position = UDim2.new(0.5, -160, 0, 168)
        progressTrack.BackgroundColor3 = Color3.fromRGB(20, 25, 38)
        progressTrack.BackgroundTransparency = 1
        progressTrack.BorderSizePixel = 0
        progressTrack.ZIndex = 62
        progressTrack.Parent = splash
        Instance.new("UICorner", progressTrack).CornerRadius = UDim.new(1, 0)

        local progressFill = Instance.new("Frame")
        progressFill.Size = UDim2.new(0, 0, 1, 0)
        progressFill.BackgroundColor3 = curTh.Main
        progressFill.BorderSizePixel = 0
        progressFill.ZIndex = 63
        progressFill.Parent = progressTrack
        Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

        task.spawn(function()
            -- Stage 1: Card fade in
            TweenService:Create(splash, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.05
            }):Play()
            TweenService:Create(splashStroke, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Transparency = 0.25
            }):Play()
            TweenService:Create(topSheen, TweenInfo.new(0.45), {
                BackgroundTransparency = 0.75
            }):Play()

            -- Stage 2: Logo badge spring up
            task.wait(0.12)
            TweenService:Create(logoContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 66, 0, 66),
                Position = UDim2.new(0.5, -33, 0, 14),
                BackgroundTransparency = 0
            }):Play()
            TweenService:Create(logoStroke, TweenInfo.new(0.4), {
                Transparency = 0.2
            }):Play()
            if logoContent:IsA("ImageLabel") then
                TweenService:Create(logoContent, TweenInfo.new(0.4), { ImageTransparency = 0 }):Play()
            else
                TweenService:Create(logoContent, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
            end

            -- Stage 3: Title and Version fade in & slide up
            task.wait(0.18)
            TweenService:Create(titleLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 86),
                TextTransparency = 0
            }):Play()
            TweenService:Create(versionBadge, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 110),
                TextTransparency = 0
            }):Play()

            -- Stage 4: Status text and progress bar appearance
            task.wait(0.16)
            TweenService:Create(statusLabel, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()
            TweenService:Create(progressTrack, TweenInfo.new(0.35), { BackgroundTransparency = 0 }):Play()

            -- Stage 5: Progress Bar filling & Status text steps
            TweenService:Create(progressFill, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = UDim2.new(0.45, 0, 1, 0)
            }):Play()

            task.wait(0.45)
            statusLabel.Text = "⚡ Loading Modules: Silent Aim, Hitboxes, Smart ESP..."
            TweenService:Create(progressFill, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = UDim2.new(0.85, 0, 1, 0)
            }):Play()

            task.wait(0.48)
            statusLabel.Text = "✨ System Initialized • Welcome Back!"
            TweenService:Create(progressFill, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 1, 0)
            }):Play()

            task.wait(0.45)

            -- Stage 6: Smooth Exit / Outro Fade
            TweenService:Create(splash, TweenInfo.new(0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 400, 0, 200),
                Position = UDim2.new(0.5, -200, 0.5, -130),
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(splashStroke, TweenInfo.new(0.28), { Transparency = 1 }):Play()
            TweenService:Create(logoContainer, TweenInfo.new(0.28), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(logoStroke, TweenInfo.new(0.28), { Transparency = 1 }):Play()
            if logoContent:IsA("ImageLabel") then
                TweenService:Create(logoContent, TweenInfo.new(0.28), { ImageTransparency = 1 }):Play()
            else
                TweenService:Create(logoContent, TweenInfo.new(0.28), { TextTransparency = 1 }):Play()
            end
            TweenService:Create(titleLabel, TweenInfo.new(0.28), { TextTransparency = 1 }):Play()
            TweenService:Create(versionBadge, TweenInfo.new(0.28), { TextTransparency = 1 }):Play()
            TweenService:Create(statusLabel, TweenInfo.new(0.28), { TextTransparency = 1 }):Play()
            TweenService:Create(progressTrack, TweenInfo.new(0.28), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(progressFill, TweenInfo.new(0.28), { BackgroundTransparency = 1 }):Play()

            task.wait(0.38)
            pcall(function() splash:Destroy() end)

            if onComplete then
                onComplete()
            end
        end)
    end
    _G.MM2_ShowSplashIntro = showSplashIntro

    showWelcomeModal = function()
        if not ScreenGui then return end
        local old = ScreenGui:FindFirstChild("MM2_WelcomeModal")
        if old then pcall(function() old:Destroy() end) end

        local welcome = Instance.new("Frame")
        welcome.Name = "MM2_WelcomeModal"
        welcome.Size = UDim2.new(0, 440, 0, 280)
        welcome.Position = UDim2.new(0.5, -220, 0.5, -140)
        welcome.BackgroundColor3 = Color3.fromRGB(13, 16, 24)
        welcome.BackgroundTransparency = 0.05
        welcome.BorderSizePixel = 0
        welcome.ClipsDescendants = true
        welcome.ZIndex = 50
        welcome.Parent = ScreenGui
        Instance.new("UICorner", welcome).CornerRadius = UDim.new(0, 14)

        local curTh = (UIThemes and UIThemes[Config.UITheme]) or { Main = Color3.fromRGB(235, 50, 75), Accent = Color3.fromRGB(255, 90, 115) }
        local stroke = Instance.new("UIStroke")
        stroke.Color = curTh.Main
        stroke.Thickness = 1.8
        stroke.Transparency = 0.2
        stroke.Parent = welcome

        local glowBar = Instance.new("Frame")
        glowBar.Size = UDim2.new(1, 0, 0, 4)
        glowBar.Position = UDim2.new(0, 0, 0, 0)
        glowBar.BackgroundColor3 = curTh.Accent
        glowBar.BorderSizePixel = 0
        glowBar.ZIndex = 51
        glowBar.Parent = welcome

        local resolvedLogo = resolveHubLogo()
        local iconLabel
        if resolvedLogo then
            iconLabel = Instance.new("ImageLabel")
            iconLabel.Size = UDim2.new(0, 42, 0, 42)
            iconLabel.Position = UDim2.new(0, 22, 0, 18)
            iconLabel.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
            iconLabel.BackgroundTransparency = 0.15
            iconLabel.BorderSizePixel = 0
            iconLabel.Image = resolvedLogo
            iconLabel.ZIndex = 52
            iconLabel.Parent = welcome
            Instance.new("UICorner", iconLabel).CornerRadius = UDim.new(0, 10)
            local iconStroke = Instance.new("UIStroke")
            iconStroke.Color = curTh.Main
            iconStroke.Thickness = 1.4
            iconStroke.Transparency = 0.25
            iconStroke.Parent = iconLabel
        else
            iconLabel = Instance.new("TextLabel")
            iconLabel.Size = UDim2.new(0, 40, 0, 40)
            iconLabel.Position = UDim2.new(0, 24, 0, 20)
            iconLabel.BackgroundTransparency = 1
            iconLabel.Font = Enum.Font.GothamBold
            iconLabel.TextSize = 32
            iconLabel.Text = "👋"
            iconLabel.ZIndex = 51
            iconLabel.Parent = welcome
        end

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -90, 0, 26)
        title.Position = UDim2.new(0, 72, 0, 16)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 18
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = "⚡ VORTEX PRIME MM2"
        title.ZIndex = 51
        title.Parent = welcome

        local subtitle = Instance.new("TextLabel")
        subtitle.Size = UDim2.new(1, -90, 0, 18)
        subtitle.Position = UDim2.new(0, 72, 0, 40)
        subtitle.BackgroundTransparency = 1
        subtitle.Font = Enum.Font.GothamBold
        subtitle.TextSize = 11
        subtitle.TextColor3 = curTh.Main
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.Text = "Release [BETA] • Все функции активны и оптимизированы"
        subtitle.ZIndex = 51
        subtitle.Parent = welcome

        local greetCard = Instance.new("Frame")
        greetCard.Size = UDim2.new(1, -40, 0, 95)
        greetCard.Position = UDim2.new(0, 20, 0, 72)
        greetCard.BackgroundColor3 = Color3.fromRGB(18, 22, 33)
        greetCard.BorderSizePixel = 0
        greetCard.ZIndex = 51
        greetCard.Parent = welcome
        Instance.new("UICorner", greetCard).CornerRadius = UDim.new(0, 9)

        local info1 = Instance.new("TextLabel")
        info1.Size = UDim2.new(1, -20, 0, 22)
        info1.Position = UDim2.new(0, 10, 0, 6)
        info1.BackgroundTransparency = 1
        info1.Font = Enum.Font.GothamBold
        info1.TextSize = 12
        info1.TextColor3 = Color3.fromRGB(240, 245, 255)
        info1.TextXAlignment = Enum.TextXAlignment.Left
        info1.Text = string.format("👋 Привет, %s! (@%s)", LocalPlayer.DisplayName, LocalPlayer.Name)
        info1.ZIndex = 52
        info1.Parent = greetCard

        local info2 = Instance.new("TextLabel")
        info2.Size = UDim2.new(1, -20, 0, 36)
        info2.Position = UDim2.new(0, 10, 0, 28)
        info2.BackgroundTransparency = 1
        info2.Font = Enum.Font.Gotham
        info2.TextSize = 10
        info2.TextColor3 = Color3.fromRGB(160, 175, 200)
        info2.TextXAlignment = Enum.TextXAlignment.Left
        info2.TextWrapped = true
        info2.Text = "• Скрипт находится в стадии BETA (постоянные обновления и оптимизация)\n• Нажмите [" .. tostring(Config.MenuKeybind) .. "] для открытия меню\n• Сохранение и загрузка конфигов во вкладке Settings"
        info2.ZIndex = 52
        info2.Parent = greetCard

        local info3 = Instance.new("TextLabel")
        info3.Size = UDim2.new(1, -20, 0, 18)
        info3.Position = UDim2.new(0, 10, 0, 70)
        info3.BackgroundTransparency = 1
        info3.Font = Enum.Font.GothamBold
        info3.TextSize = 10
        info3.TextColor3 = curTh.Accent
        info3.TextXAlignment = Enum.TextXAlignment.Left
        info3.Text = string.format("🎮 MM2 Place ID: %d • Раунд активен!", game.PlaceId)
        info3.ZIndex = 52
        info3.Parent = greetCard

        -- DISMISS FUNCTION DECLARED BEFORE ANY BUTTON CONNECTIONS
        local dismissed = false
        local function dismiss()
            if dismissed then return end
            dismissed = true
            TweenService:Create(welcome, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, -220, 0.5, -170),
                BackgroundTransparency = 1
            }):Play()
            task.delay(0.32, function()
                pcall(function() welcome:Destroy() end)
            end)
            task.delay(0.1, function()
                if _G.MM2_RevealDynamicIsland then
                    _G.MM2_RevealDynamicIsland()
                end
            end)
        end

        local dontShowFrame = Instance.new("Frame")
        dontShowFrame.Name = "DontShowFrame"
        dontShowFrame.Size = UDim2.new(1, -40, 0, 22)
        dontShowFrame.Position = UDim2.new(0, 20, 0, 175)
        dontShowFrame.BackgroundTransparency = 1
        dontShowFrame.ZIndex = 52
        dontShowFrame.Parent = welcome

        local dontShowBox = Instance.new("TextButton")
        dontShowBox.Size = UDim2.new(0, 18, 0, 18)
        dontShowBox.Position = UDim2.new(0, 0, 0, 2)
        dontShowBox.BackgroundColor3 = (Config.ShowWelcome == false) and curTh.Main or Color3.fromRGB(24, 30, 44)
        dontShowBox.BorderSizePixel = 0
        dontShowBox.Font = Enum.Font.GothamBold
        dontShowBox.TextSize = 12
        dontShowBox.TextColor3 = (Config.ShowWelcome == false) and Color3.fromRGB(255, 255, 255) or curTh.Accent
        dontShowBox.Text = (Config.ShowWelcome == false) and "✔" or ""
        dontShowBox.AutoButtonColor = false
        dontShowBox.ZIndex = 53
        dontShowBox.Parent = dontShowFrame
        Instance.new("UICorner", dontShowBox).CornerRadius = UDim.new(0, 4)
        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = curTh.Main
        boxStroke.Thickness = 1.2
        boxStroke.Transparency = 0.3
        boxStroke.Parent = dontShowBox

        local dontShowLabel = Instance.new("TextLabel")
        dontShowLabel.Size = UDim2.new(1, -26, 1, 0)
        dontShowLabel.Position = UDim2.new(0, 26, 0, 0)
        dontShowLabel.BackgroundTransparency = 1
        dontShowLabel.Font = Enum.Font.GothamMedium
        dontShowLabel.TextSize = 10
        dontShowLabel.TextColor3 = Color3.fromRGB(180, 195, 220)
        dontShowLabel.TextXAlignment = Enum.TextXAlignment.Left
        dontShowLabel.Text = "Больше не показывать при входе"
        dontShowLabel.ZIndex = 53
        dontShowLabel.Parent = dontShowFrame

        local function updateCheckVisual()
            local isSuppressed = (Config.ShowWelcome == false)
            dontShowBox.Text = isSuppressed and "✔" or ""
            if isSuppressed then
                dontShowBox.BackgroundColor3 = curTh.Main
                dontShowBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                dontShowBox.BackgroundColor3 = Color3.fromRGB(24, 30, 44)
                dontShowBox.TextColor3 = curTh.Accent
            end
        end

        local function toggleDontShow()
            if Config.ShowWelcome == false then
                Config.ShowWelcome = true
            else
                Config.ShowWelcome = false
            end
            updateCheckVisual()
            saveConfig()
        end

        dontShowBox.MouseButton1Click:Connect(toggleDontShow)

        -- Clickable overlay covering the whole row for easy clicking
        local dontShowHitbox = Instance.new("TextButton")
        dontShowHitbox.Size = UDim2.new(1, 0, 1, 0)
        dontShowHitbox.BackgroundTransparency = 1
        dontShowHitbox.Text = ""
        dontShowHitbox.ZIndex = 54
        dontShowHitbox.Parent = dontShowFrame
        dontShowHitbox.MouseButton1Click:Connect(toggleDontShow)

        local skipBtn = Instance.new("TextButton")
        skipBtn.Size = UDim2.new(0.48, -25, 0, 36)
        skipBtn.Position = UDim2.new(0, 20, 0, 206)
        skipBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
        skipBtn.BorderSizePixel = 0
        skipBtn.Font = Enum.Font.GothamBold
        skipBtn.TextSize = 11
        skipBtn.TextColor3 = Color3.fromRGB(220, 230, 245)
        skipBtn.Text = "🚫 НЕ ПОКАЗЫВАТЬ"
        skipBtn.AutoButtonColor = false
        skipBtn.ZIndex = 52
        skipBtn.Parent = welcome
        Instance.new("UICorner", skipBtn).CornerRadius = UDim.new(0, 8)
        local skipStroke = Instance.new("UIStroke")
        skipStroke.Color = Color3.fromRGB(60, 70, 95)
        skipStroke.Thickness = 1
        skipStroke.Transparency = 0.5
        skipStroke.Parent = skipBtn

        skipBtn.MouseButton1Click:Connect(function()
            Config.ShowWelcome = false
            saveConfig()
            dismiss()
        end)

        local launchBtn = Instance.new("TextButton")
        launchBtn.Size = UDim2.new(0.52, -25, 0, 36)
        launchBtn.Position = UDim2.new(0.48, 5, 0, 206)
        launchBtn.BackgroundColor3 = curTh.Main
        launchBtn.BorderSizePixel = 0
        launchBtn.Font = Enum.Font.GothamBold
        launchBtn.TextSize = 11
        launchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        launchBtn.Text = "🚀 ОТКРЫТЬ HUB"
        launchBtn.AutoButtonColor = false
        launchBtn.ZIndex = 52
        launchBtn.Parent = welcome
        Instance.new("UICorner", launchBtn).CornerRadius = UDim.new(0, 8)

        launchBtn.MouseButton1Click:Connect(function()
            dismiss()
            if not MainFrame.Visible and toggleMenu then
                toggleMenu()
            end
        end)

        local closeXBtn = Instance.new("TextButton")
        closeXBtn.Size = UDim2.new(0, 26, 0, 26)
        closeXBtn.Position = UDim2.new(1, -38, 0, 14)
        closeXBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
        closeXBtn.BorderSizePixel = 0
        closeXBtn.Font = Enum.Font.GothamBold
        closeXBtn.TextSize = 13
        closeXBtn.TextColor3 = Color3.fromRGB(190, 205, 230)
        closeXBtn.Text = "✕"
        closeXBtn.AutoButtonColor = false
        closeXBtn.ZIndex = 53
        closeXBtn.Parent = welcome
        Instance.new("UICorner", closeXBtn).CornerRadius = UDim.new(0, 6)

        closeXBtn.MouseEnter:Connect(function()
            TweenService:Create(closeXBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(220, 50, 70), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end)
        closeXBtn.MouseLeave:Connect(function()
            TweenService:Create(closeXBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(28, 34, 48), TextColor3 = Color3.fromRGB(190, 205, 230)}):Play()
        end)
        closeXBtn.MouseButton1Click:Connect(function()
            dismiss()
        end)

        welcome.Size = UDim2.new(0, 390, 0, 250)
        welcome.Position = UDim2.new(0.5, -195, 0.5, -125)
        TweenService:Create(welcome, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 440, 0, 280),
            Position = UDim2.new(0.5, -220, 0.5, -140)
        }):Play()
    end
    _G.MM2_ShowWelcomeModal = showWelcomeModal
end

-- ====================================================================
-- POPULATE TABS
-- ====================================================================

-- 👁️ Visuals Tab (Sub-Tabs: ESP, Nametags, World)
do
    local VisualsSubNav = Instance.new("Frame")
    VisualsSubNav.Size = UDim2.new(1, 0, 0, 32)
    VisualsSubNav.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
    VisualsSubNav.BorderSizePixel = 0
    VisualsSubNav.Parent = TabVisuals
    Instance.new("UICorner", VisualsSubNav).CornerRadius = UDim.new(0, 8)

    local vsList = Instance.new("UIListLayout")
    vsList.FillDirection = Enum.FillDirection.Horizontal
    vsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    vsList.VerticalAlignment = Enum.VerticalAlignment.Center
    vsList.Padding = UDim.new(0, 6)
    vsList.Parent = VisualsSubNav

    local VisualsSubPages = {}
    local VisualsSubBtns = {}

    local function createVisualSubPage(key, label)
        local page = Instance.new("Frame")
        page.Name = "VisualsSub_" .. key
        page.Size = UDim2.new(1, 0, 0, 0)
        page.BackgroundTransparency = 1
        page.AutomaticSize = Enum.AutomaticSize.Y
        page.BorderSizePixel = 0
        page.Visible = false
        page.Parent = TabVisuals

        local pList = Instance.new("UIListLayout")
        pList.Padding = UDim.new(0, 6)
        pList.SortOrder = Enum.SortOrder.LayoutOrder
        pList.Parent = page

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 160, 0, 26)
        btn.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.TextColor3 = Color3.fromRGB(170, 185, 210)
        btn.Text = label
        btn.AutoButtonColor = false
        btn.Parent = VisualsSubNav
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        VisualsSubPages[key] = page
        VisualsSubBtns[key] = btn

        btn.MouseButton1Click:Connect(function()
            local curTh = UIThemes[Config.UITheme] or UIThemes["Red"]
            for pKey, pFrame in pairs(VisualsSubPages) do
                local b = VisualsSubBtns[pKey]
                if pKey == key then
                    pFrame.Visible = true
                    TweenService:Create(b, TweenInfo.new(0.18), {BackgroundColor3 = curTh.Main, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                else
                    pFrame.Visible = false
                    TweenService:Create(b, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(24, 28, 40), TextColor3 = Color3.fromRGB(170, 185, 210)}):Play()
                end
            end
        end)

        return page
    end

    local SubVisualsESP = createVisualSubPage("ESP", "👁️ ESP")
    local SubVisualsNametags = createVisualSubPage("Nametags", "🏷️ Nametags")
    local SubVisualsWorld = createVisualSubPage("World", "🌍 World")

    SubVisualsESP.Visible = true
    local initTh = UIThemes[Config.UITheme] or UIThemes["Red"]
    VisualsSubBtns["ESP"].BackgroundColor3 = initTh.Main
    VisualsSubBtns["ESP"].TextColor3 = Color3.fromRGB(255, 255, 255)

    -- 1. Sub-Tab: ESP
    createSectionHeader(SubVisualsESP, "👥 ИГРОКИ (PLAYER ESP & CHAMS)")
    createToggle(SubVisualsESP, "💀 Murderer ESP & Chams", "MurdererESP")
    createToggle(SubVisualsESP, "🛡️ Sheriff ESP", "SheriffESP")
    createToggle(SubVisualsESP, "⭐ Hero ESP & Highlight", "HeroESP")
    createToggle(SubVisualsESP, "👥 Innocents ESP", "InnocentESP")
    createToggle(SubVisualsESP, "🧟 Zombie ESP", "ZombieESP")
    createToggle(SubVisualsESP, "🏃 Survivor ESP", "SurvivorESP")
    createToggle(SubVisualsESP, "🏛️ Lobby ESP (Серые игроки в лобби)", "LobbyESP")

    createSectionHeader(SubVisualsESP, "⭐ ПРЕДМЕТЫ И ЛУТ (ITEMS & TRAPS ESP)")
    createToggle(SubVisualsESP, "⭐ Dropped Gun ESP", "GunDropESP")
    createToggle(SubVisualsESP, "🪙 Coins ESP (Active Badges)", "CoinESP")
    createToggle(SubVisualsESP, "🪤 Traps ESP (Ловушки мардера)", "TrapESP")

    createSectionHeader(SubVisualsESP, "⚡ РАДАР И ЛИНИИ (TRACERS & RADAR)")
    createToggle(SubVisualsESP, "⚡ Visual Tracers", "Tracers")
    createToggle(SubVisualsESP, "🎯 Off-Screen Radar Arrow", "OffscreenRadar")

    -- 2. Sub-Tab: Nametags
    createSectionHeader(SubVisualsNametags, "🏷️ НАСТРОЙКИ ТЕГОВ ИГРОКОВ (NAMETAGS)")
    createToggle(SubVisualsNametags, "🖼️ Аватарка игрока (Headshot Thumbnail)", "ESPShowAvatar")
    createToggle(SubVisualsNametags, "👤 Никнейм игрока (Display Name)", "ESPShowNames")
    createToggle(SubVisualsNametags, "🎭 Роль игрока (Murderer/Sheriff/Hero)", "ESPShowRole")
    createToggle(SubVisualsNametags, "🗡️ Иконка активного оружия (Held Weapon)", "ESPShowWeapon")
    createToggle(SubVisualsNametags, "📶 Отображать пинг (Player Ping ms)", "ESPShowPing")
    createToggle(SubVisualsNametags, "📏 Дистанция до цели (Distance studs)", "ESPShowDistance")
    createSlider(SubVisualsNametags, "🔤 Размер текста тегов", 8, 18, "ESPTextSize", "%d px")

    -- 3. Sub-Tab: World (Visuals, Lighting, Camera, Performance & Emotes)
    createSectionHeader(SubVisualsWorld, "✨ ЭФФЕКТЫ И ВИЗУАЛЫ (WORLD VISUALS)")
    createToggle(SubVisualsWorld, "⭕ Jump Circles (Ударные кольца при прыжке)", "JumpCircles")
    createToggle(SubVisualsWorld, "💫 Motion Trail (Неоновый шлейф за персонажем)", "MotionTrail", function(on)
        if _G.MM2_UpdateMotionTrail then _G.MM2_UpdateMotionTrail(on) end
    end)
    createToggle(SubVisualsWorld, "🔮 Self Aura Glow (Неоновое свечение персонажа)", "SelfAuraGlow", function(on)
        if _G.MM2_UpdateSelfGlow then _G.MM2_UpdateSelfGlow(on) end
    end)
    createSlider(SubVisualsWorld, "👁️ Угол обзора (Camera FOV)", 70, 120, "CameraFOV", "%d°", function(v)
        Config.CameraFOV = v
        if Camera then Camera.FieldOfView = v end
        saveConfig()
    end)

    createSectionHeader(SubVisualsWorld, "🔫 ТРАССЕРЫ ПУЛЬ И ОРУЖИЯ (WEAPON TRACERS)")
    createToggle(SubVisualsWorld, "⚡ Bullet Tracers (Лазерные трассеры пуль)", "BulletTracers")
    createToggle(SubVisualsWorld, "💥 Bullet Impact Rings (Кольца попаданий пуль)", "BulletImpactRings")
    createToggle(SubVisualsWorld, "🗡️ Knife Throw Trails (Неоновый шлейф броска ножа)", "KnifeThrowTracers")

    local tracerColorPresets = {"Electric Cyan", "Neon Crimson", "Plasma Purple", "Golden Spark", "Emerald Green", "Rainbow Chroma"}
    local curColorIdx = 1
    for i, c in ipairs(tracerColorPresets) do
        if c == Config.BulletTracerColor then curColorIdx = i; break end
    end
    local colorBtn
    colorBtn = createButton(SubVisualsWorld, "🎨 Цвет трассера: " .. (Config.BulletTracerColor or "Electric Cyan"), Color3.fromRGB(36, 44, 62), function()
        curColorIdx = (curColorIdx % #tracerColorPresets) + 1
        local newColor = tracerColorPresets[curColorIdx]
        Config.BulletTracerColor = newColor
        colorBtn.Text = "🎨 Цвет трассера: " .. newColor
        saveConfig()
        if showNotification then
            showNotification("🎨 ЦВЕТ ТРАССЕРА", "Выбран пресет: " .. newColor, Color3.fromRGB(60, 200, 255), "🎨", 2)
        end
    end)

    createSlider(SubVisualsWorld, "📏 Толщина луча трассера", 1, 10, "BulletTracerThicknessInt", "%d0% studs", function(v)
        Config.BulletTracerThickness = v / 10
        saveConfig()
    end)
    createSlider(SubVisualsWorld, "⏳ Длительность трассера", 1, 5, "BulletTracerLifetime", "%d сек", function(v)
        Config.BulletTracerLifetime = v
        saveConfig()
    end)

    createButton(SubVisualsWorld, "🎯 Тестовый выстрел трассера (Test Fire)", Color3.fromRGB(45, 140, 255), function()
        if _G.MM2_SpawnBulletTracer then
            local cam = workspace.CurrentCamera
            local root = getLocalRoot()
            local startPos = root and (root.Position + Vector3.new(0, 1.2, 0)) or (cam and cam.CFrame.Position or Vector3.zero)
            local lookDir = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
            local endPos = startPos + (lookDir * 75)
            _G.MM2_SpawnBulletTracer(startPos, endPos)
            if _G.MM2_TriggerHitPulse then _G.MM2_TriggerHitPulse() end
            if showNotification then
                showNotification("⚡ BULLET TRACER", "Тестовый лазерный трассер выпущен!", Color3.fromRGB(0, 230, 255), "🔫", 2.0)
            end
        end
    end)

    -- 🎯 Section: Custom Screen Crosshair
    createSectionHeader(SubVisualsWorld, "🎯 КАСТОМНЫЙ ПРИЦЕЛ (CUSTOM CROSSHAIR)")
    createToggle(SubVisualsWorld, "🎯 Custom Crosshair (Прицел по центру)", "CustomCrosshair", function(on)
        if _G.MM2_UpdateCrosshair then _G.MM2_UpdateCrosshair(on) end
    end)
    local crosshairStyles = {"Classic Cross", "Dot", "Circle", "Circle Dot", "Chevron", "Heart"}
    local curCrossStyleIdx = 1
    for i, s in ipairs(crosshairStyles) do
        if s == Config.CrosshairStyle then curCrossStyleIdx = i; break end
    end
    local crossStyleBtn
    crossStyleBtn = createButton(SubVisualsWorld, "📐 Стиль прицела: " .. (Config.CrosshairStyle or "Classic Cross"), Color3.fromRGB(36, 44, 62), function()
        curCrossStyleIdx = (curCrossStyleIdx % #crosshairStyles) + 1
        local newStyle = crosshairStyles[curCrossStyleIdx]
        Config.CrosshairStyle = newStyle
        crossStyleBtn.Text = "📐 Стиль прицела: " .. newStyle
        saveConfig()
        if _G.MM2_UpdateCrosshairStyle then _G.MM2_UpdateCrosshairStyle(newStyle) end
    end)

    local crosshairColors = {"Electric Cyan", "Neon Crimson", "Chroma RGB", "Toxic Green", "Pure White", "Golden Spark"}
    local curCrossColIdx = 1
    for i, c in ipairs(crosshairColors) do
        if c == Config.CrosshairColor then curCrossColIdx = i; break end
    end
    local crossColBtn
    crossColBtn = createButton(SubVisualsWorld, "🎨 Цвет прицела: " .. (Config.CrosshairColor or "Electric Cyan"), Color3.fromRGB(36, 44, 62), function()
        curCrossColIdx = (curCrossColIdx % #crosshairColors) + 1
        local newCol = crosshairColors[curCrossColIdx]
        Config.CrosshairColor = newCol
        crossColBtn.Text = "🎨 Цвет прицела: " .. newCol
        saveConfig()
        if _G.MM2_UpdateCrosshairColor then _G.MM2_UpdateCrosshairColor(newCol) end
    end)

    createSlider(SubVisualsWorld, "📏 Размер прицела", 6, 24, "CrosshairSize", "%d px", function(v)
        Config.CrosshairSize = v
        saveConfig()
        if _G.MM2_UpdateCrosshairSize then _G.MM2_UpdateCrosshairSize(v) end
    end)

    -- 🌈 Section: Shaders & Post-Processing
    createSectionHeader(SubVisualsWorld, "🌈 ПОСТ-ОБРАБОТКА И ШЕЙДЕРЫ (SHADERS & POST-FX)")
    createToggle(SubVisualsWorld, "✨ Glow Bloom (Неоновое свечение мира)", "GlowBloom", function(on)
        if _G.MM2_UpdateBloom then _G.MM2_UpdateBloom(on) end
    end)

    local ccPresets = {"None", "Vibrant Anime", "Cyberpunk Pink", "Matrix Green", "Cinematic Noir", "Cold Frost"}
    local curCCIdx = 1
    for i, p in ipairs(ccPresets) do
        if p == Config.ColorCorrectionPreset then curCCIdx = i; break end
    end
    local ccBtn
    ccBtn = createButton(SubVisualsWorld, "🎨 Цветокоррекция: " .. (Config.ColorCorrectionPreset or "None"), Color3.fromRGB(36, 44, 62), function()
        curCCIdx = (curCCIdx % #ccPresets) + 1
        local newPreset = ccPresets[curCCIdx]
        Config.ColorCorrectionPreset = newPreset
        ccBtn.Text = "🎨 Цветокоррекция: " .. newPreset
        saveConfig()
        if _G.MM2_UpdateColorCorrection then _G.MM2_UpdateColorCorrection(newPreset) end
    end)

    createToggle(SubVisualsWorld, "🔍 Depth of Field (Кинематографичный фокус)", "DepthOfField", function(on)
        if _G.MM2_UpdateDepthOfField then _G.MM2_UpdateDepthOfField(on) end
    end)
    createToggle(SubVisualsWorld, "☀️ Volumetric Sun Rays (Лучи солнца)", "SunRaysFX", function(on)
        if _G.MM2_UpdateSunRays then _G.MM2_UpdateSunRays(on) end
    end)
    createToggle(SubVisualsWorld, "🩸 Damage Vignette (Пульс при получении урона)", "DamageVignette", function(on)
        if _G.MM2_UpdateDamageVignette then _G.MM2_UpdateDamageVignette(on) end
    end)

    -- 🌌 Section: Custom Skybox
    createSectionHeader(SubVisualsWorld, "🌌 КАСТОМНЫЙ СКАЙБОКС (CUSTOM SKYBOX)")
    local skyPresets = {"Default", "Purple Nebula", "Galaxy Space", "Anime Sunset", "Dark Cyber Void", "Blood Moon"}
    local curSkyIdx = 1
    for i, s in ipairs(skyPresets) do
        if s == Config.CustomSkybox then curSkyIdx = i; break end
    end
    local skyBtn
    skyBtn = createButton(SubVisualsWorld, "🌌 Скайбокс мира: " .. (Config.CustomSkybox or "Default"), Color3.fromRGB(36, 44, 62), function()
        curSkyIdx = (curSkyIdx % #skyPresets) + 1
        local newSky = skyPresets[curSkyIdx]
        Config.CustomSkybox = newSky
        skyBtn.Text = "🌌 Скайбокс мира: " .. newSky
        saveConfig()
        if _G.MM2_UpdateSkybox then _G.MM2_UpdateSkybox(newSky) end
    end)

    -- ✨ Section: Player Auras & FX
    createSectionHeader(SubVisualsWorld, "✨ АУРЫ И ЭФФЕКТЫ ПЕРСОНАЖА (PLAYER AURAS)")
    createToggle(SubVisualsWorld, "👣 Footstep Ripples (Неоновые кольца шагов)", "FootstepRipples", function(on)
        if _G.MM2_UpdateFootstepRipples then _G.MM2_UpdateFootstepRipples(on) end
    end)
    createToggle(SubVisualsWorld, "💥 Landing Shockwave (Ударная волна приземления)", "LandingShockwave")
    createToggle(SubVisualsWorld, "😇 Angel Halo (Неоновый парящий нимб)", "HaloAura", function(on)
        if _G.MM2_UpdateHaloAura then _G.MM2_UpdateHaloAura(on) end
    end)
    createToggle(SubVisualsWorld, "👟 Feet Ribbon Trails (Шлейфы из ног при беге)", "FeetTrails", function(on)
        if _G.MM2_UpdateFeetTrails then _G.MM2_UpdateFeetTrails(on) end
    end)
    createToggle(SubVisualsWorld, "🌈 Chroma Skin (Переливающийся RGB скин)", "ChromaSkin", function(on)
        if _G.MM2_UpdateChromaSkin then _G.MM2_UpdateChromaSkin(on) end
    end)
    createToggle(SubVisualsWorld, "🪽 Neon Back Wings (Светящиеся неоновые крылья)", "BackWingsVisual", function(on)
        if _G.MM2_UpdateBackWings then _G.MM2_UpdateBackWings(on) end
    end)
    createToggle(SubVisualsWorld, "👀 Laser Eyes (Лазерный взор из глаз)", "LaserEyes", function(on)
        if _G.MM2_UpdateLaserEyes then _G.MM2_UpdateLaserEyes(on) end
    end)

    -- 🔥 Section: Combat & Weapon Visuals
    createSectionHeader(SubVisualsWorld, "🔥 БОЕВЫЕ И ОРУЖЕЙНЫЕ ВИЗУАЛЫ (WEAPON & COMBAT FX)")
    createToggle(SubVisualsWorld, "💥 Hitmarker Screen Pulse (Вспышка экрана при хите)", "HitmarkerScreenPulse")
    createToggle(SubVisualsWorld, "🔥 Weapon Chroma Flame (Неоновое пламя на оружии)", "WeaponChromaFlame", function(on)
        if _G.MM2_UpdateWeaponFlame then _G.MM2_UpdateWeaponFlame(on) end
    end)
    createToggle(SubVisualsWorld, "👻 Death Soul Ascend (Взлетающая душа при смерти)", "DeathSoulEffect")
    createToggle(SubVisualsWorld, "🪙 Coin Collect Pulse (Золотая волна при сборе)", "CoinCollectPulse")
    createToggle(SubVisualsWorld, "🗡️ Giant Weapon Visual (Увеличенное оружие в руках)", "BigWeaponVisual", function(on)
        if _G.MM2_UpdateBigWeapon then _G.MM2_UpdateBigWeapon(on) end
    end)

    -- 🎥 Section: Dynamic Camera
    createSectionHeader(SubVisualsWorld, "🎥 ДИНАМИЧЕСКАЯ КАМЕРА (DYNAMIC CAMERA FX)")
    createToggle(SubVisualsWorld, "📹 Shoulder Cam (Тактическая камера от плеча)", "ShoulderCamera", function(on)
        if _G.MM2_UpdateShoulderCamera then _G.MM2_UpdateShoulderCamera(on) end
    end)
    createToggle(SubVisualsWorld, "🏎️ Dynamic Sprint FOV (Динамический FOV при беге)", "DynamicSprintFOV")

    createSectionHeader(SubVisualsWorld, "💡 ОСВЕЩЕНИЕ И АТМОСФЕРА (LIGHTING)")
    local function updateFullbright(on)
        if on then
            Lighting.Ambient = Color3.fromRGB(200, 200, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 1e6
            Lighting.GlobalShadows = false
        else
            Lighting.Ambient = OriginalLighting.Ambient
            Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
            Lighting.Brightness = OriginalLighting.Brightness
            Lighting.ClockTime = OriginalLighting.ClockTime
            Lighting.FogEnd = (Config.NoFog and 1e6) or OriginalLighting.FogEnd
            Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        end
    end
    createToggle(SubVisualsWorld, "💡 Fullbright / Vision (Всегда светло)", "Fullbright", updateFullbright)
    createToggle(SubVisualsWorld, "🌫️ No Fog (Убрать туман карты)", "NoFog", function(on)
        Config.NoFog = on
        saveConfig()
        if on then
            Lighting.FogEnd = 1e6
        else
            Lighting.FogEnd = OriginalLighting.FogEnd
        end
    end)

    local ambiencePresets = {"Default", "Cyberpunk", "Sunset", "Matrix", "Winter Frost"}
    local curAmbIdx = 1
    for i, a in ipairs(ambiencePresets) do
        if a == Config.WorldAmbiencePreset then curAmbIdx = i; break end
    end
    local ambBtn
    ambBtn = createButton(SubVisualsWorld, "🌌 Пресет атмосферы: " .. (Config.WorldAmbiencePreset or "Default"), Color3.fromRGB(36, 44, 62), function()
        curAmbIdx = (curAmbIdx % #ambiencePresets) + 1
        local newPreset = ambiencePresets[curAmbIdx]
        Config.WorldAmbiencePreset = newPreset
        ambBtn.Text = "🌌 Пресет атмосферы: " .. newPreset
        saveConfig()
        if _G.MM2_ApplyAmbiencePreset then _G.MM2_ApplyAmbiencePreset(newPreset) end
    end)

    createButton(SubVisualsWorld, "☀️ Дневное освещение (Day Time)", Color3.fromRGB(50, 75, 110), function()
        Lighting.ClockTime = 14
    end)
    createButton(SubVisualsWorld, "🌙 Ночное освещение (Night Time)", Color3.fromRGB(35, 45, 75), function()
        Lighting.ClockTime = 0
    end)
    createButton(SubVisualsWorld, "🌅 Закат (Sunset Time)", Color3.fromRGB(90, 50, 70), function()
        Lighting.ClockTime = 17.8
    end)

    createSectionHeader(SubVisualsWorld, "📷 КАМЕРА И ОБЗОР (CAMERA NOCLIP & ZOOM)")
    createToggle(SubVisualsWorld, "📷 Third-Person Camera Noclip (Сквозь стены)", "CameraNoclip")
    createSlider(SubVisualsWorld, "🔍 Макс. дистанция зума", 15, 2000, "CameraMaxZoom", "%d studs", function(v)
        Config.CameraMaxZoom = v
        if LocalPlayer then
            LocalPlayer.CameraMaxZoomDistance = v
        end
        saveConfig()
    end)
    createButton(SubVisualsWorld, "🔭 Максимальный обзор карты (2000 studs)", Color3.fromRGB(45, 140, 255), function()
        Config.CameraMaxZoom = 2000
        Config.CameraNoclip = true
        if LocalPlayer then
            LocalPlayer.CameraMaxZoomDistance = 2000
        end
        saveConfig()
        showNotification("📷 CAMERA ZOOM", "Установлен максимальный зум 2000 studs (Сквозь стены)", Color3.fromRGB(45, 140, 255), "🔭", 2.5)
    end)
    createButton(SubVisualsWorld, "🔄 Сброс обзора (15 studs Default)", Color3.fromRGB(60, 75, 105), function()
        Config.CameraMaxZoom = 15
        if LocalPlayer then
            LocalPlayer.CameraMaxZoomDistance = 15
        end
        saveConfig()
        showNotification("📷 CAMERA ZOOM", "Сброшено на стандартную дистанцию MM2 (15 studs)", Color3.fromRGB(150, 165, 195), "🔄", 2.5)
    end)
    createToggle(SubVisualsWorld, "🎥 Кинематографичная камера при сборе", "CoinCinematicCamera")
    createToggle(SubVisualsWorld, "✨ Подсветка целевой монеты (Highlight)", "CoinTargetHighlight")

    createSectionHeader(SubVisualsWorld, "📐 РАСТЯГ ЭКРАНА (STRETCHED RESOLUTION)")
    createToggle(SubVisualsWorld, "📐 Включить растяг экрана (Stretched Res)", "StretchedRes", function(on)
        Config.StretchedRes = on
        saveConfig()
        if _G.MM2_UpdateStretchedResolution then _G.MM2_UpdateStretchedResolution() end
        if showNotification then
            showNotification("📐 РАСТЯГ ЭКРАНА", on and ("Включен режим: " .. (Config.StretchPreset or "4:3")) or "Отключен (16:9 Standard)", on and Color3.fromRGB(45, 180, 255) or Color3.fromRGB(200, 70, 70), "📐", 2.5)
        end
    end)

    local stretchPresets = {"4:3 (CS:GO Wide)", "5:4 (Ultra Wide)", "16:10 (Comfort Wide)", "1:1 (Square Pro)", "Custom (Свой фактор)"}
    local curStretchIdx = 1
    for i, p in ipairs(stretchPresets) do
        if p == Config.StretchPreset or p:sub(1, 3) == tostring(Config.StretchPreset):sub(1, 3) then curStretchIdx = i; break end
    end
    local stretchBtn
    stretchBtn = createButton(SubVisualsWorld, "🖥️ Пресет: " .. (Config.StretchPreset or "4:3 (CS:GO Wide)"), Color3.fromRGB(36, 44, 62), function()
        curStretchIdx = (curStretchIdx % #stretchPresets) + 1
        local newPreset = stretchPresets[curStretchIdx]
        Config.StretchPreset = newPreset
        stretchBtn.Text = "🖥️ Пресет: " .. newPreset
        saveConfig()
        if _G.MM2_UpdateStretchedResolution then _G.MM2_UpdateStretchedResolution() end
        if showNotification then
            showNotification("📐 ПРЕСЕТ РАСТЯГА", "Выбран пресет: " .. newPreset, Color3.fromRGB(60, 200, 255), "🖥️", 2)
        end
    end)

    createToggle(SubVisualsWorld, "📐 Авто-подгон под монитор (Auto-Aspect)", "StretchAutoAspect", function(on)
        Config.StretchAutoAspect = on
        saveConfig()
        if _G.MM2_UpdateStretchedResolution then _G.MM2_UpdateStretchedResolution() end
    end)

    createSlider(SubVisualsWorld, "↔️ Фактор растяга (Stretch Factor / Custom)", 30, 150, "StretchFactorPercent", "%d%%", function(v)
        Config.StretchFactorPercent = v
        Config.StretchFactor = v / 100
        saveConfig()
        if _G.MM2_UpdateStretchedResolution then _G.MM2_UpdateStretchedResolution() end
    end)

    createSlider(SubVisualsWorld, "🧍 Множитель ширины моделей (Model Width)", 50, 200, "StretchModelWidthPercent", "%d%%", function(v)
        Config.StretchModelWidthPercent = v
        Config.StretchModelWidth = v / 100
        saveConfig()
        if _G.MM2_UpdateStretchedResolution then _G.MM2_UpdateStretchedResolution() end
    end)

    createToggle(SubVisualsWorld, "🎬 Чёрные полосы (Black Bars / Letterbox)", "StretchBlackBars", function(on)
        Config.StretchBlackBars = on
        saveConfig()
        if _G.MM2_UpdateStretchedResolution then _G.MM2_UpdateStretchedResolution() end
        if showNotification then
            showNotification("🎬 BLACK BARS", on and "Режим чёрных полос (4:3 Black Bars) включен" or "Режим полного растяга (Full Stretched) включен", Color3.fromRGB(180, 200, 255), "🎬", 2.5)
        end
    end)

    createButton(SubVisualsWorld, "⚡ Турнирный 4:3 Стритч (1440x1080 Mode)", Color3.fromRGB(45, 120, 210), function()
        Config.StretchedRes = true
        Config.StretchPreset = "4:3 (CS:GO Wide)"
        curStretchIdx = 1
        stretchBtn.Text = "🖥️ Пресет: 4:3 (CS:GO Wide)"
        Config.StretchAutoAspect = true
        Config.StretchFactorPercent = 75
        Config.StretchFactor = 0.75
        Config.StretchModelWidthPercent = 100
        Config.StretchModelWidth = 1.0
        Config.StretchBlackBars = false
        saveConfig()
        if _G.MM2_UpdateStretchedResolution then _G.MM2_UpdateStretchedResolution() end
        if showNotification then
            showNotification("📐 БЫСТРЫЙ РАСТЯГ", "Активирован турнирный 4:3 Stretched (1440x1080)!", Color3.fromRGB(45, 200, 255), "⚡", 3)
        end
    end)

    createButton(SubVisualsWorld, "🔄 Сброс растяга (16:9 Default)", Color3.fromRGB(60, 75, 105), function()
        Config.StretchedRes = false
        Config.StretchPreset = "4:3 (CS:GO Wide)"
        curStretchIdx = 1
        stretchBtn.Text = "🖥️ Пресет: 4:3 (CS:GO Wide)"
        Config.StretchFactorPercent = 100
        Config.StretchFactor = 1.0
        Config.StretchModelWidthPercent = 100
        Config.StretchModelWidth = 1.0
        Config.StretchBlackBars = false
        saveConfig()
        if _G.MM2_UpdateStretchedResolution then _G.MM2_UpdateStretchedResolution() end
        if showNotification then
            showNotification("📐 СБРОС РАСТЯГА", "Возвращено стандартное соотношение 16:9", Color3.fromRGB(150, 165, 195), "🔄", 2.5)
        end
    end)

    createSectionHeader(SubVisualsWorld, "⚡ ОПТИМИЗАЦИЯ И ПРОИЗВОДИТЕЛЬНОСТЬ (FPS BOOST)")
    createToggle(SubVisualsWorld, "⚡ FPS Booster (Удаление теней, декоров и лагов)", "FPSBooster", function(on)
        if _G.MM2_ApplyFPSBooster then _G.MM2_ApplyFPSBooster(on) end
    end)
    createToggle(SubVisualsWorld, "🖥️ Disable 3D Render [F7]", "Disable3DRender", function(enabled)
        if _G.MM2_Set3DRenderEnabled then
            _G.MM2_Set3DRenderEnabled(not enabled)
        end
    end)

    createSectionHeader(SubVisualsWorld, "🎭 ЭМОЦИИ И ВЕСЕЛЬЕ (EMOTES & FUN)")
    createToggle(SubVisualsWorld, "🗡️ Knife Spin / Inspect (Бесконечное кручение ножа)", "KnifeSpin")
    createToggle(SubVisualsWorld, "💀 Fake Dead / Ragdoll (Притвориться мёртвым)", "FakeDead", function(on)
        if _G.MM2_SetFakeDead then _G.MM2_SetFakeDead(on) end
    end)
    createButton(SubVisualsWorld, "🥷 Emote: Ninja", Color3.fromRGB(50, 70, 95), function() if _G.MM2_PlayEmote then _G.MM2_PlayEmote("ninja") end end)
    createButton(SubVisualsWorld, "🤙 Emote: Dab", Color3.fromRGB(50, 70, 95), function() if _G.MM2_PlayEmote then _G.MM2_PlayEmote("dab") end end)
    createButton(SubVisualsWorld, "🕺 Emote: Floss", Color3.fromRGB(50, 70, 95), function() if _G.MM2_PlayEmote then _G.MM2_PlayEmote("floss") end end)
    createButton(SubVisualsWorld, "🧘 Emote: Zen", Color3.fromRGB(50, 70, 95), function() if _G.MM2_PlayEmote then _G.MM2_PlayEmote("zen") end end)
    createButton(SubVisualsWorld, "🪑 Emote: Sit", Color3.fromRGB(50, 70, 95), function() if _G.MM2_PlayEmote then _G.MM2_PlayEmote("sit") end end)
    createButton(SubVisualsWorld, "🧟 Emote: Zombie", Color3.fromRGB(50, 70, 95), function() if _G.MM2_PlayEmote then _G.MM2_PlayEmote("zombie") end end)
    createButton(SubVisualsWorld, "🙏 Emote: Pray", Color3.fromRGB(50, 70, 95), function() if _G.MM2_PlayEmote then _G.MM2_PlayEmote("pray") end end)
    createButton(SubVisualsWorld, "⏹️ Остановить эмоцию (Stop Emote)", Color3.fromRGB(180, 50, 50), function() if _G.MM2_StopEmote then _G.MM2_StopEmote() end end)
end



-- 🎯 Combat Tab (Sub-Tabs: Aim Settings, WallBang Mode, Auto-Shot)
local CombatSubNav = Instance.new("Frame")
CombatSubNav.Size = UDim2.new(1, 0, 0, 32)
CombatSubNav.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
CombatSubNav.BorderSizePixel = 0
CombatSubNav.Parent = TabCombat
Instance.new("UICorner", CombatSubNav).CornerRadius = UDim.new(0, 8)

do
    local csList = Instance.new("UIListLayout")
    csList.FillDirection = Enum.FillDirection.Horizontal
    csList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    csList.VerticalAlignment = Enum.VerticalAlignment.Center
    csList.Padding = UDim.new(0, 6)
    csList.Parent = CombatSubNav
end

local CombatSubPages = {}
local CombatSubBtns = {}

local function createCombatSubPage(key, label)
    local page = Instance.new("Frame")
    page.Name = "CombatSub_" .. key
    page.Size = UDim2.new(1, 0, 0, 0)
    page.BackgroundTransparency = 1
    page.AutomaticSize = Enum.AutomaticSize.Y
    page.BorderSizePixel = 0
    page.Visible = false
    page.Parent = TabCombat

    local pList = Instance.new("UIListLayout")
    pList.Padding = UDim.new(0, 6)
    pList.SortOrder = Enum.SortOrder.LayoutOrder
    pList.Parent = page

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 164, 0, 26)
    btn.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = Color3.fromRGB(170, 185, 210)
    btn.Text = label
    btn.AutoButtonColor = false
    btn.Parent = CombatSubNav
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    CombatSubPages[key] = page
    CombatSubBtns[key] = btn

    btn.MouseButton1Click:Connect(function()
        local curTh = UIThemes[Config.UITheme] or UIThemes["Red"]
        for pKey, pFrame in pairs(CombatSubPages) do
            local b = CombatSubBtns[pKey]
            if pKey == key then
                pFrame.Visible = true
                TweenService:Create(b, TweenInfo.new(0.18), {BackgroundColor3 = curTh.Main, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            else
                pFrame.Visible = false
                TweenService:Create(b, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(24, 28, 40), TextColor3 = Color3.fromRGB(170, 185, 210)}):Play()
            end
        end
    end)
    return page
end

local SubCombatSheriff = createCombatSubPage("Sheriff", "🛡️ Sheriff")
local SubCombatMurderer = createCombatSubPage("Murderer", "💀 Murderer")
local SubCombatInnocent = createCombatSubPage("Innocent", "👥 Innocent")

SubCombatSheriff.Visible = true
CombatSubBtns["Sheriff"].BackgroundColor3 = currentTheme.Main
CombatSubBtns["Sheriff"].TextColor3 = Color3.fromRGB(255, 255, 255)

-- ====================================================================
-- 🛡️ SUB-TAB 1: SHERIFF / HERO
-- ====================================================================
createSectionHeader(SubCombatSheriff, "🎯 НАСТРОЙКИ SILENT AIM ШЕРИФА")
createToggle(SubCombatSheriff, "🎯 Sheriff / Gun Silent Aim", "SilentAim")
createToggle(SubCombatSheriff, "🏷️ Silent Aim Target ESP & Reticle", "SilentAimVisuals")
createToggle(SubCombatSheriff, "🔫 Только когда револьвер в руках", "SilentAimWeaponOnly")
createToggle(SubCombatSheriff, "🔮 Упреждение движения (Movement Prediction)", "PredictMovement")
createSlider(SubCombatSheriff, "Скорость пули для упреждения", 150, 600, "PredictionBulletSpeed", "%d sps")
createToggle(SubCombatSheriff, "📶 Учет сетевого пинга (Ping Compensation)", "PredictionPingCompensation")
createSlider(SubCombatSheriff, "🎛️ Множитель пинга (Ping Multiplier)", 0.5, 2.0, "PredictionPingMultiplier", "%.2fx")

createSectionHeader(SubCombatSheriff, "🧱 ПРОСТРЕЛ ЧЕРЕЗ СТЕНЫ (WALLBANG)")
createToggle(SubCombatSheriff, "🧱 Silent Aim WallBang (Прострел сквозь стены)", "SilentAimWallBang")
createToggle(SubCombatSheriff, "🌐 Full-Map Penetration (Чистый прострел без ТП)", "WallBangAllMap")
createSlider(SubCombatSheriff, "Смещение прострела", 0.1, 1.0, "WallPenetrationOffset", "%.2f studs")
createToggle(SubCombatSheriff, "🛡️ Wall Check (Проверка прямой видимости)", "WallCheck")
createToggle(SubCombatSheriff, "💥 WallBang Bypass (Всегда активен)", "WallBang")

createSectionHeader(SubCombatSheriff, "💥 ВЫСТРЕЛ И АВТО-СТРЕЛЬБА (SHOOT CONTROLS)")
createToggle(SubCombatSheriff, "💥 Auto-Shoot Murderer (Авто-выстрел в мардера)", "AutoShot")
createSlider(SubCombatSheriff, "Задержка авто-выстрела", 0.3, 2.0, "AutoShotDelay", "%.1fs")
createKeybindButton(SubCombatSheriff, "⌨️ Бинд выстрела (Instant Shoot)", "InstantShootKeybind", {"E", "Q", "F", "X", "C", "Z", "V", "R", "None"})
createButton(SubCombatSheriff, "💥 Instant Shoot Murderer (Сделать выстрел сейчас)", Color3.fromRGB(235, 50, 75), function()
    local res, msg = shootMurderer(true)
    if res then
        StatusText.Text = "💥 Shot fired at Murderer!"
    else
        StatusText.Text = "⚠️ " .. tostring(msg or "Need Gun equipped & active Murderer!")
    end
end)


-- ====================================================================
-- 💀 SUB-TAB 2: MURDERER
-- ====================================================================
createSectionHeader(SubCombatMurderer, "🔪 РЕЖИМ МАРДЕРА (MURDERER SUITE)")
createToggle(SubCombatMurderer, "🔪 Knife Aura (Авто-удар ножом в радиусе)", "KnifeAura")
createSlider(SubCombatMurderer, "📏 Радиус Knife Aura (10-45 studs)", 10, 45, "KnifeAuraRadius", "%d studs")
createToggle(SubCombatMurderer, "⭕ 3D Показ радиуса поражения (Круг на полу)", "KnifeAuraShowRadius")
createToggle(SubCombatMurderer, "🧱 Проверка прямой видимости (Wall Check)", "KnifeAuraWallCheck")

createSectionHeader(SubCombatMurderer, "🗡️ ДАЛЬНИЙ УДАР НОЖОМ (LONG-RANGE STRIKE)")
createToggle(SubCombatMurderer, "🗡️ Включить дальний удар по курсору", "KnifeReachEnabled")
createKeybindButton(SubCombatMurderer, "⌨️ Бинд удара по цели", "KnifeReachKeybind", {"F", "E", "Q", "X", "C", "Z", "V", "R", "None"})
createToggle(SubCombatMurderer, "⚡ Авто-экипировка ножа при ударе", "KnifeAutoEquip")
createToggle(SubCombatMurderer, "🎯 Подсветка цели под курсором", "KnifeReachHighlight")
do
    if Config.KnifeTargetHUDMode == nil then Config.KnifeTargetHUDMode = "Above" end
    local hudModes = {"Above", "Below", "Side", "IslandOnly"}
    local hudModeLabels = {
        ["Above"] = "🏷️ Позиция метки: Сверху над NameTag",
        ["Below"] = "👣 Позиция метки: Снизу под ногами",
        ["Side"] = "👉 Позиция метки: Сбоку от игрока",
        ["IslandOnly"] = "🏝️ Позиция метки: Только Dynamic Island"
    }
    local hudBtn = nil
    hudBtn = createButton(SubCombatMurderer, hudModeLabels[Config.KnifeTargetHUDMode] or hudModeLabels["Above"], Color3.fromRGB(32, 40, 56), function()
        local curIdx = 1
        for i, m in ipairs(hudModes) do
            if m == Config.KnifeTargetHUDMode then curIdx = i break end
        end
        curIdx = (curIdx % #hudModes) + 1
        Config.KnifeTargetHUDMode = hudModes[curIdx]
        saveConfig()
        hudBtn.Text = hudModeLabels[Config.KnifeTargetHUDMode] or hudModeLabels["Above"]
        showNotification("🎯 ПОЗИЦИЯ МЕТКИ", "Выбрано: " .. (hudModeLabels[Config.KnifeTargetHUDMode] or ""), Color3.fromRGB(80, 200, 255), "🎯", 2)
    end)
end
createToggle(SubCombatMurderer, "🌀 Микро-блинк (100% регистрация сервером)", "KnifeReachBlink")
createButton(SubCombatMurderer, "🗡️ Ударить выделенную цель сейчас", Color3.fromRGB(255, 45, 60), function()
    local ok, err = performLongRangeKnifeStrike()
    if not ok and err then
        StatusText.Text = "⚠️ " .. tostring(err)
    end
end)

createSectionHeader(SubCombatMurderer, "🎯 БРОСОК НОЖА & SILENT AIM (KNIFE THROW)")
createToggle(SubCombatMurderer, "🎯 Включить бросок ножа с Silent Aim", "KnifeThrowEnabled")
createKeybindButton(SubCombatMurderer, "⌨️ Бинд броска ножа (Silent Aim)", "KnifeThrowKeybind", {"E", "Q", "T", "R", "F", "None"})
createButton(SubCombatMurderer, "🎯 Мгновенный бросок в цель", Color3.fromRGB(255, 65, 80), function()
    local ok, err = throwKnifeAtTarget(true)
    if not ok and err then
        StatusText.Text = "⚠️ " .. tostring(err)
    end
end)

createSectionHeader(SubCombatMurderer, "💀 МАССОВОЕ УНИЧТОЖЕНИЕ (KILL ALL)")
createButton(SubCombatMurderer, "💀 Убить всех сейчас (Kill All)", Color3.fromRGB(255, 35, 50), function()
    if _G.MM2_PerformKillAll then
        local ok, err = _G.MM2_PerformKillAll()
        if ok then
            StatusText.Text = "💀 Успешно: Все цели устранены!"
            showNotification("💀 KILL ALL", "Все цели на карте устранены!", Color3.fromRGB(255, 45, 60), "💀", 3.5)
        else
            StatusText.Text = "⚠️ " .. tostring(err)
            showNotification("⚠️ ОШИБКА", tostring(err), Color3.fromRGB(240, 160, 30), "⚠️", 3)
        end
    else
        StatusText.Text = "⚠️ Функция Kill All не инициализирована"
    end
end)
createToggle(SubCombatMurderer, "⚡ Авто-убийство после начала раунда (Auto Kill All)", "AutoKillAllOnRoundStart")

-- ====================================================================
-- 👥 SUB-TAB 3: INNOCENT
-- ====================================================================
createSectionHeader(SubCombatInnocent, "⭐ ПОДБОР ОРУЖИЯ (GUN DROP)")
createToggle(SubCombatInnocent, "⚡ Auto-Grab Gun (Авто-подбор выпавшего оружия)", "AutoGrabGun")
createButton(SubCombatInnocent, "⭐ Instant Grab Gun (Подобрать сейчас)", Color3.fromRGB(240, 160, 30), function()
    local ok = grabGun()
    if ok then
        StatusText.Text = "⭐ Grabbed Dropped Gun Successfully!"
    else
        StatusText.Text = "⚠️ GunDrop not found in workspace"
    end
end)
createButton(SubCombatInnocent, "📍 Телепорт к выпавшему пистолету", Color3.fromRGB(45, 140, 255), function()
    local gun = getGunDrop()
    local root = getLocalRoot()
    if gun and root then root.CFrame = gun.CFrame + Vector3.new(0, 2, 0) end
end)

createSectionHeader(SubCombatInnocent, "⚠️ ОПОВЕЩЕНИЕ ОБ ОПАСНОСТИ")
createToggle(SubCombatInnocent, "⚠️ Murderer Proximity Alert (Тревога при приближении)", "MurdererAlert")
createSlider(SubCombatInnocent, "Дистанция тревоги (Studs)", 15, 80, "AlertDistance", "%d studs")
createButton(SubCombatInnocent, "🎲 Сканировать шансы мардера в лобби", Color3.fromRGB(140, 60, 220), function()
    local RS = game:GetService("ReplicatedStorage")
    local getChance = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Extras") and RS.Remotes.Extras:FindFirstChild("GetChance")
    if not getChance then
        StatusText.Text = "⚠️ GetChance Remote not found"
        return
    end

    StatusText.Text = "🎲 Scanning player chances..."
    task.spawn(function()
        local highestChance = -1
        local highestPlr = nil
        for _, plr in ipairs(Players:GetPlayers()) do
            pcall(function()
                local ch = getChance:InvokeServer(plr)
                if type(ch) == "number" and ch > highestChance then
                    highestChance = ch
                    highestPlr = plr
                end
            end)
        end
        if highestPlr then
            StatusText.Text = string.format("🎲 Highest Chance: %s (%d%%)", highestPlr.Name, highestChance)
        else
            StatusText.Text = "⚠️ Could not scan chances"
        end
    end)
end)

createSectionHeader(SubCombatInnocent, "🪤 ЛОВУШКИ МАРДЕРА (TRAP ESP & DISARM)")
createToggle(SubCombatInnocent, "⚠️ Trap ESP & Highlights", "TrapESP")
createToggle(SubCombatInnocent, "🛡️ Auto Disarm Traps (При приближении)", "AutoDisarmTraps")
createButton(SubCombatInnocent, "🪤 Обезвредить все ловушки на карте", Color3.fromRGB(220, 80, 50), function()
    if _G.MM2_DisarmAllTraps then _G.MM2_DisarmAllTraps() end
end)

-- ====================================================================
-- 🌪️ FLING ENGINE & TARGET RADAR TAB
-- ====================================================================
do
    local SelectedFlingTargets = {}
local FlingCardReferences = {}
local isFlingRunning = false
local flingCurrentMethodIndex = 1
local flingMethodList = {
    "BodyVelocity", "FlingNEW", "BodyThrust", "BodyForce", "VectorForce",
    "LinearVelocity", "ExplodeFling", "RocketFling", "TorqueFling",
    "ImpulseFling1", "ImpulseFling2", "AlignPositionFling", "PhysicsRepFling", "NaNFling"
}

if Config.FlingPower == nil then Config.FlingPower = 10 end
if Config.FlingDuration == nil then Config.FlingDuration = 1.5 end
if Config.FlingReturnToOldPos == nil then Config.FlingReturnToOldPos = true end
if Config.FlingMethod == nil then Config.FlingMethod = "BodyVelocity" end

for idx, name in ipairs(flingMethodList) do
    if name == Config.FlingMethod then
        flingCurrentMethodIndex = idx
        break
    end
end

local FlingPhysicsMethods = {
    ["BodyVelocity"] = function(rootPart, power, dir)
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = dir * (power or 10) * 100
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = rootPart
        return bv
    end,
    ["BodyThrust"] = function(rootPart, power, dir)
        local p = power or 10
        local mult = p * 2000000
        local bt = Instance.new("BodyThrust")
        bt.Name = "MM2_FlingThrust"
        bt.Force = Vector3.new(mult, mult * 1.5, mult)
        bt.Location = Vector3.new(2.5, 2.5, 2.5)
        bt.Parent = rootPart
        local bav = Instance.new("BodyAngularVelocity")
        bav.Name = "MM2_FlingSpin"
        bav.AngularVelocity = Vector3.new(99999, 99999, 99999)
        bav.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bav.P = 1e5
        bav.Parent = rootPart
        return {bt, bav}
    end,
    ["BodyForce"] = function(rootPart, power, dir)
        local bf = Instance.new("BodyForce")
        bf.Force = dir * (power or 10) * 500
        bf.Parent = rootPart
        return bf
    end,
    ["VectorForce"] = function(rootPart, power, dir)
        local vf = Instance.new("VectorForce")
        vf.Force = dir * (power or 10) * 500
        vf.Parent = rootPart
        return vf
    end,
    ["LinearVelocity"] = function(rootPart, power, dir)
        local lv = Instance.new("LinearVelocity")
        lv.Velocity = dir * (power or 10) * 100
        lv.MaxForce = 9e9
        lv.Parent = rootPart
        return lv
    end,
    ["ExplodeFling"] = function(rootPart, power, dir)
        local bf = Instance.new("BodyForce")
        bf.Force = dir * (power or 10) * 999999
        bf.Parent = rootPart

        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(
            math.random(-1000, 1000),
            math.random(500, 1500),
            math.random(-1000, 1000)
        )
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = rootPart

        Debris:AddItem(bf, 0.3)
        Debris:AddItem(bv, 0.3)
        return {bf, bv}
    end,
    ["NaNFling"] = function(rootPart, power, dir)
        local nan_value = 0 / 0
        local nan_vector = Vector3.new(nan_value, nan_value, nan_value)
        local hum = rootPart.Parent and rootPart.Parent:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end
        rootPart.AssemblyLinearVelocity = nan_vector
        rootPart.AssemblyAngularVelocity = nan_vector
        return nil
    end,
    ["PhysicsRepFling"] = function(rootPart, power, dir)
        rootPart.Velocity = Vector3.new(9e9, 9e9, 9e9)
        rootPart.RotVelocity = Vector3.new(9e9, 9e9, 9e9)
        return nil
    end,
    ["FlingNEW"] = function(rootPart, power, dir)
        local bodies = {}
        pcall(function()
            if sethiddenproperty then
                sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
            end
        end)
        for i = 1, 30 do
            local bv = Instance.new("BodyVelocity")
            bv.Parent = rootPart
            local nan = 0 / 0
            bv.Velocity = Vector3.new(nan, nan, nan)
            bv.MaxForce = Vector3.new(9e30, 9e30, 9e30)
            table.insert(bodies, bv)
            Debris:AddItem(bv, 0.05 + (i * 0.001))
        end
        return bodies
    end,
    ["RocketFling"] = function(rootPart, power, dir)
        local rp = Instance.new("RocketPropulsion")
        rp.Parent = rootPart

        local targetPart = Instance.new("Part")
        targetPart.Position = rootPart.Position + dir * 100
        targetPart.Anchored = true
        targetPart.CanCollide = false
        targetPart.Parent = workspace
        rp.Target = targetPart

        rp.MaxThrust = (power or 10) * 1000
        rp.ThrustP = 1e5
        rp.ThrustD = math.huge
        rp:Fire()

        Debris:AddItem(rp, 0.5)
        Debris:AddItem(targetPart, 0.5)
        return rp
    end,
    ["TorqueFling"] = function(rootPart, power, dir)
        local torque = Instance.new("Torque")
        torque.Parent = rootPart
        torque.Torque = Vector3.new((power or 10) * 10000, (power or 10) * 10000, (power or 10) * 10000)
        Debris:AddItem(torque, 0.5)
        return torque
    end,
    ["ImpulseFling1"] = function(rootPart, power, dir)
        local bodies = {}
        for i = 1, 25 do
            local bv = Instance.new("BodyVelocity")
            bv.Parent = rootPart
            bv.Velocity = Vector3.new(9e9, 9e9, 9e9)
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            table.insert(bodies, bv)
            Debris:AddItem(bv, 0.05)
        end
        return bodies
    end,
    ["ImpulseFling2"] = function(rootPart, power, dir)
        local bodies = {}
        for i = 1, 20 do
            local bv = Instance.new("BodyVelocity")
            bv.Parent = rootPart
            bv.Velocity = dir * (power or 10) * 9e9
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            table.insert(bodies, bv)
            Debris:AddItem(bv, 0.05 + (i * 0.001))
        end
        for i = 1, 10 do
            local bf = Instance.new("BodyForce")
            bf.Parent = rootPart
            bf.Force = dir * (power or 10) * 9e9
            table.insert(bodies, bf)
            Debris:AddItem(bf, 0.1 + (i * 0.01))
        end
        return bodies
    end,
    ["AlignPositionFling"] = function(rootPart, power, dir)
        local align = Instance.new("AlignPosition")
        align.Parent = rootPart
        local att = Instance.new("Attachment", rootPart)
        align.Attachment0 = att

        local targetPart = Instance.new("Part")
        targetPart.Position = rootPart.Position + dir * 100
        targetPart.Anchored = true
        targetPart.CanCollide = false
        targetPart.Parent = workspace

        local att2 = Instance.new("Attachment", targetPart)
        align.Attachment1 = att2
        align.RigidityEnabled = false
        align.MaxForce = (power or 10) * 10000

        Debris:AddItem(align, 0.5)
        Debris:AddItem(targetPart, 0.5)
        return align
    end,
}

local function hasNoCollisionTarget(character)
    if not character then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        if hrp.CanCollide == false or hrp.Massless == true or hrp.Anchored == true then
            return true
        end
    end
    return false
end

local function executeSingleFling(targetPlayer, singleShot, customDuration)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = (hum and hum.RootPart) or (char and char:FindFirstChild("HumanoidRootPart"))
    if not char or not hum or not root or hum.Health <= 0 then return false end

    local tChar = targetPlayer and targetPlayer.Character
    if not tChar then return false end
    local tHum = tChar:FindFirstChildOfClass("Humanoid")
    local tRoot = tHum and (tHum.RootPart or tChar:FindFirstChild("HumanoidRootPart"))
    local tHead = tChar:FindFirstChild("Head")
    local targetBasePart = tRoot or tHead or tChar:FindFirstChildWhichIsA("BasePart")

    if not targetBasePart then
        showNotification("⚠️ FLING ERROR", targetPlayer.Name .. " не имеет физических частей!", Color3.fromRGB(255, 100, 100), "❌", 2)
        return false
    end

    local function isTargetAirborneFar(tPart, tH)
        if not tPart or not tPart.Parent then return false end
        local pos = tPart.Position
        local vel = tPart.Velocity
        local velMag = vel.Magnitude
        local inLobby = pos.Y > 420

        if inLobby then
            if pos.Y > 550 or pos.Y < 460 then return true end
        else
            if pos.Y > 125 or pos.Y < -25 then return true end
        end

        if velMag > 130 then
            return true
        end

        local rayParams = RaycastParams.new()
        rayParams.FilterType = (Enum.RaycastFilterType and Enum.RaycastFilterType.Exclude) or Enum.RaycastFilterType.Blacklist
        local filterList = {}
        if LocalPlayer.Character then table.insert(filterList, LocalPlayer.Character) end
        if tPart.Parent then table.insert(filterList, tPart.Parent) end
        rayParams.FilterDescendantsInstances = filterList

        local hit = workspace:Raycast(pos, Vector3.new(0, -50, 0), rayParams)
        if not hit and (pos.Y > 70 or velMag > 55) then
            return true
        end
        return false
    end

    -- Pre-fling check: If target is already flying far in the air or falling into void, don't teleport to them
    if (Config.FlingAirVoidCheck ~= false) and isTargetAirborneFar(targetBasePart, tHum) then
        if flingStatusTextLabel then
            flingStatusTextLabel.Text = string.format("⏳ Ожидание: %s в воздухе, ждём падения в пустоту...", targetPlayer.DisplayName or targetPlayer.Name)
            flingStatusTextLabel.TextColor3 = Color3.fromRGB(255, 185, 60)
        end
        local waitStart = tick()
        while (tick() - waitStart < 3.8) do
            task.wait(0.12)
            if not targetPlayer or not targetPlayer.Parent or not targetPlayer.Character then break end
            local curHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
            local curPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart") or targetPlayer.Character:FindFirstChild("Head")
            if not curHum or curHum.Health <= 0 then break end
            if curPart and (curPart.Position.Y < -50 or (curPart.Position.Y < 350 and isPlayerInLobby(targetPlayer))) then
                break
            end
            if curPart and not isTargetAirborneFar(curPart, curHum) then
                targetBasePart = curPart
                break
            end
        end

        local curHum = targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not curHum or curHum.Health <= 0 then
            return true
        end
        local curPart = targetPlayer and targetPlayer.Character and (targetPlayer.Character:FindFirstChild("HumanoidRootPart") or targetPlayer.Character:FindFirstChild("Head"))
        if curPart and (curPart.Position.Y < -50 or (curPart.Position.Y < 350 and isPlayerInLobby(targetPlayer))) then
            return true
        end
    end

    _G.MM2_FlingingActive = true
    _G.MM2_FlingCollisionBypass = true
    root.Anchored = false
    hum.PlatformStand = false
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = true end
    end

    -- Save position before flinging
    local savedOldPos = root.CFrame
    local origFPDH = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = 0 / 0

    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(root, "PhysicsRepRootPart", targetBasePart)
            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
        end
    end)

    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    hum.PlatformStand = false

    -- Clear any anti-gravity or prior body movers from character before flinging
    for _, v in ipairs(root:GetChildren()) do
        if v.Name == "FarmAntiGrav" or v:IsA("BodyVelocity") or v:IsA("BodyThrust") or v:IsA("BodyForce") or v:IsA("BodyAngularVelocity") then
            pcall(function() v:Destroy() end)
        end
    end

    local methodKey = Config.FlingMethod or "BodyThrust"
    local methodFunc = FlingPhysicsMethods[methodKey] or FlingPhysicsMethods["BodyThrust"]
    local dir = Vector3.new(0, 1, 0)
    local power = Config.FlingPower or 10
    local body = nil
    pcall(function()
        body = methodFunc(root, power, dir)
    end)

    local function FPos(basePart, posOffset, ang)
        if not root or not root.Parent or not basePart or not basePart.Parent then return end
        root.Anchored = false
        hum.PlatformStand = false
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
        local targetCf = CFrame.new(basePart.Position) * posOffset * ang
        root.CFrame = targetCf
        char:SetPrimaryPartCFrame(targetCf)
        root.AssemblyLinearVelocity = Vector3.new(0, 10000, 0)
        root.AssemblyAngularVelocity = Vector3.new(50000, 50000, 50000)
        root.Velocity = Vector3.new(0, 10000, 0)
        root.RotVelocity = Vector3.new(50000, 50000, 50000)
    end

    local startTime = tick()
    local maxDuration = tonumber(customDuration) or tonumber(Config.FlingDuration) or 2.5
    local angle = 0

    local function isFlingTargetDead()
        if not targetPlayer or not targetPlayer.Parent then return true end
        if not targetBasePart or not targetBasePart.Parent then return true end
        if not tHum or tHum.Health <= 0 then return true end
        if isPlayerDead(targetPlayer) then return true end
        if targetBasePart.Position.Y < -50 then return true end
        if isRoundActive() and isPlayerInLobby(targetPlayer) then return true end
        if (targetPlayer == CachedMurderer or detectPlayerRole(targetPlayer) == "Murderer") then
            if _G.MM2_MurdererEliminatedThisRound or isMurdererDead() then
                return true
            end
        end
        return false
    end

    repeat
        if not root or isFlingTargetDead() then
            if targetPlayer == CachedMurderer or detectPlayerRole(targetPlayer) == "Murderer" then
                _G.MM2_MurdererEliminatedThisRound = true
            end
            break
        end
        if not singleShot and not isFlingRunning then break end

        -- User Request: Stop chasing if target got flung high into the air or is falling into void
        if (Config.FlingAirVoidCheck ~= false) and (tick() - startTime > 0.12) and isTargetAirborneFar(targetBasePart, tHum) then
            break
        end

        local velMag = targetBasePart.Velocity.Magnitude
        local moveDir = tHum.MoveDirection
        local speed = tHum.WalkSpeed or 16

        if velMag < 50 then
            angle = angle + 100
            local ang = CFrame.Angles(math.rad(angle), 0, 0)
            local posOffset = CFrame.new(0, 1.5, 0) + moveDir * (velMag / 1.25)
            local negOffset = CFrame.new(0, -1.5, 0) + moveDir * (velMag / 1.25)

            -- 💥 High-impact multi-angle collision sequence including direct center-of-mass contact
            FPos(targetBasePart, CFrame.new(0, 0, 0), ang)
            task.wait()
            if isFlingTargetDead() then break end
            FPos(targetBasePart, posOffset, ang)
            task.wait()
            if isFlingTargetDead() then break end
            FPos(targetBasePart, CFrame.new(0, 0.5, 0) + moveDir, ang)
            task.wait()
            if isFlingTargetDead() then break end
            FPos(targetBasePart, negOffset, ang)
            task.wait()
            if isFlingTargetDead() then break end
            FPos(targetBasePart, CFrame.new(0, -0.5, 0) + moveDir, ang)
            task.wait()
        else
            local high = CFrame.Angles(math.rad(90), 0, 0)
            local zero = CFrame.new()

            FPos(targetBasePart, CFrame.new(0, 0, 0), high)
            task.wait()
            if isFlingTargetDead() then break end
            FPos(targetBasePart, CFrame.new(0, 1.5, speed), high)
            task.wait()
            if isFlingTargetDead() then break end
            FPos(targetBasePart, CFrame.new(0, -1.5, -speed), zero)
            task.wait()
            if isFlingTargetDead() then break end
            FPos(targetBasePart, CFrame.new(0, 0, 0), zero)
            task.wait()
        end
    until (tick() - startTime >= maxDuration) or (not singleShot and not isFlingRunning) or isFlingTargetDead()

    -- If target was launched far into the air/sky, wait safely on ground for them to fall into the void or die
    if (Config.FlingAirVoidCheck ~= false) and targetBasePart and targetBasePart.Parent and isTargetAirborneFar(targetBasePart, tHum) and not isFlingTargetDead() then
        if flingStatusTextLabel then
            flingStatusTextLabel.Text = string.format("🌪️ Цель %s запущена! Ожидание падения в пустоту...", targetPlayer.DisplayName or targetPlayer.Name)
            flingStatusTextLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
        end
        local waitVoidStart = tick()
        while (tick() - waitVoidStart < 3.5) do
            task.wait(0.12)
            if isFlingTargetDead() then break end
        end
    end

    if type(body) == "table" then
        for _, obj in ipairs(body) do
            if obj and obj.Destroy then pcall(function() obj:Destroy() end) end
        end
    elseif body and body.Destroy then
        pcall(function() body:Destroy() end)
    end
    cleanCharacterPhysics(char)
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    hum.PlatformStand = false
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)

    if Config.FlingReturnToOldPos and savedOldPos then
        local returnStart = tick()
        repeat
            root.CFrame = savedOldPos * CFrame.new(0, 0.5, 0)
            char:SetPrimaryPartCFrame(savedOldPos * CFrame.new(0, 0.5, 0))
            pcall(function() hum:ChangeState("GettingUp") end)
            for _, p in ipairs(char:GetChildren()) do
                if p:IsA("BasePart") then
                    p.Velocity = Vector3.zero
                    p.RotVelocity = Vector3.zero
                end
            end
            task.wait()
        until (root.Position - savedOldPos.Position).Magnitude < 20 or (tick() - returnStart > 1.2)
    end

    if isFlingTargetDead() then
        if targetPlayer == CachedMurderer or detectPlayerRole(targetPlayer) == "Murderer" then
            _G.MM2_MurdererEliminatedThisRound = true
        end
        if SelectedFlingTargets and targetPlayer then
            SelectedFlingTargets[targetPlayer.Name] = nil
        end
        if flingStatusTextLabel then
            flingStatusTextLabel.Text = string.format("🎯 Цель %s устранена!", targetPlayer.DisplayName or targetPlayer.Name)
            flingStatusTextLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
        end
    end

    workspace.FallenPartsDestroyHeight = origFPDH
    _G.MM2_FlingingActive = false
    _G.MM2_FlingCollisionBypass = false
    return true
end
_G.MM2_ExecuteSingleFling = executeSingleFling

local flingStatusTextLabel = nil
local updateFlingPlayerListCards = nil

local function updateFlingUIStatus()
    local selectedCount = 0
    for _ in pairs(SelectedFlingTargets) do selectedCount = selectedCount + 1 end
    if flingStatusTextLabel then
        if isFlingRunning then
            flingStatusTextLabel.Text = string.format("🌪️ АТАКА АКТИВНА: флинг %d целей...", selectedCount)
            flingStatusTextLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
        else
            flingStatusTextLabel.Text = string.format("🎯 Выбрано целей: %d / %d", selectedCount, math.max(0, #Players:GetPlayers() - 1))
            flingStatusTextLabel.TextColor3 = Color3.fromRGB(180, 205, 235)
        end
    end
end

local function stopMultiFling()
    if not isFlingRunning then return end
    isFlingRunning = false
    Config.FlingActive = false
    saveConfig()
    cleanCharacterPhysics(LocalPlayer.Character)
    updateFlingUIStatus()
    showNotification("🛑 FLING СТОП", "Multi-Fling успешно остановлен", Color3.fromRGB(255, 80, 80), "🛑", 2.5)
end

local function startMultiFling()
    if isFlingRunning then return end
    local validCount = 0
    for _ in pairs(SelectedFlingTargets) do validCount = validCount + 1 end
    if validCount == 0 then
        showNotification("⚠️ FLING", "Сначала выберите хотя бы одного игрока в списке!", Color3.fromRGB(255, 180, 50), "⚠️", 3)
        return
    end

    isFlingRunning = true
    Config.FlingActive = true
    saveConfig()
    updateFlingUIStatus()
    showNotification("🌪️ FLING СТАРТ", string.format("Запуск атаки на %d целей (%s)", validCount, Config.FlingMethod or "BodyVelocity"), Color3.fromRGB(50, 230, 100), "🌪️", 3)

    task.spawn(function()
        while isFlingRunning and _G.MM2_Hub_Running and (_G.MM2_Hub_InstanceID == InstanceID) do
            local queue = {}
            for name, plr in pairs(SelectedFlingTargets) do
                if plr and plr.Parent and plr.Character and plr ~= LocalPlayer then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    local isDead = (hum and hum.Health <= 0) or isPlayerDead(plr)
                    if (plr == CachedMurderer or detectPlayerRole(plr) == "Murderer") and (isMurdererDead() or _G.MM2_MurdererEliminatedThisRound) then
                        isDead = true
                    end
                    if not isDead then
                        table.insert(queue, plr)
                    else
                        SelectedFlingTargets[name] = nil
                    end
                else
                    SelectedFlingTargets[name] = nil
                end
            end

            if #queue == 0 then
                task.wait(0.5)
            else
                -- Sort by MM2 Priority: Murderer > Sheriff > Hero > Innocents
                table.sort(queue, function(a, b)
                    local roleA = detectPlayerRole(a)
                    local roleB = detectPlayerRole(b)
                    local prioA = (roleA == "Murderer" and 3) or (roleA == "Sheriff" and 2) or (roleA == "Hero" and 2) or 1
                    local prioB = (roleB == "Murderer" and 3) or (roleB == "Sheriff" and 2) or (roleB == "Hero" and 2) or 1
                    return prioA > prioB
                end)

                for _, target in ipairs(queue) do
                    if not isFlingRunning then break end
                    local targetDead = not target or not target.Parent or isPlayerDead(target)
                    if (target == CachedMurderer or detectPlayerRole(target) == "Murderer") and (isMurdererDead() or _G.MM2_MurdererEliminatedThisRound) then
                        targetDead = true
                    end
                    if targetDead then
                        SelectedFlingTargets[target and target.Name] = nil
                    else
                        executeSingleFling(target, false)
                        task.wait(0.12)
                        if not target or not target.Parent or isPlayerDead(target) or ((target == CachedMurderer or detectPlayerRole(target) == "Murderer") and (isMurdererDead() or _G.MM2_MurdererEliminatedThisRound)) then
                            SelectedFlingTargets[target and target.Name] = nil
                        end
                    end
                end
            end
            task.wait(0.3)
        end
        stopMultiFling()
    end)
end

--    -- ==========================================
    -- 🎭 TROLL SUB-NAVIGATION (FLING vs VOTE DUPE)
    -- ==========================================
    local TrollSubNav = Instance.new("Frame")
    TrollSubNav.Size = UDim2.new(1, 0, 0, 32)
    TrollSubNav.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
    TrollSubNav.BorderSizePixel = 0
    TrollSubNav.Parent = TabFling
    Instance.new("UICorner", TrollSubNav).CornerRadius = UDim.new(0, 8)
    do
        local tsList = Instance.new("UIListLayout")
        tsList.FillDirection = Enum.FillDirection.Horizontal
        tsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        tsList.VerticalAlignment = Enum.VerticalAlignment.Center
        tsList.Padding = UDim.new(0, 8)
        tsList.Parent = TrollSubNav
    end

    local SubTrollFling = Instance.new("Frame")
    SubTrollFling.Name = "SubTroll_Fling"
    SubTrollFling.Size = UDim2.new(1, 0, 0, 0)
    SubTrollFling.BackgroundTransparency = 1
    SubTrollFling.AutomaticSize = Enum.AutomaticSize.Y
    SubTrollFling.BorderSizePixel = 0
    SubTrollFling.Visible = true
    SubTrollFling.Parent = TabFling
    do
        local pList = Instance.new("UIListLayout")
        pList.Padding = UDim.new(0, 6)
        pList.SortOrder = Enum.SortOrder.LayoutOrder
        pList.Parent = SubTrollFling
    end

    local SubTrollVoteDupe = Instance.new("Frame")
    SubTrollVoteDupe.Name = "SubTroll_VoteDupe"
    SubTrollVoteDupe.Size = UDim2.new(1, 0, 0, 0)
    SubTrollVoteDupe.BackgroundTransparency = 1
    SubTrollVoteDupe.AutomaticSize = Enum.AutomaticSize.Y
    SubTrollVoteDupe.BorderSizePixel = 0
    SubTrollVoteDupe.Visible = false
    SubTrollVoteDupe.Parent = TabFling
    do
        local pList = Instance.new("UIListLayout")
        pList.Padding = UDim.new(0, 6)
        pList.SortOrder = Enum.SortOrder.LayoutOrder
        pList.Parent = SubTrollVoteDupe
    end

    local btnFlingTab = Instance.new("TextButton")
    btnFlingTab.Size = UDim2.new(0.48, -4, 0, 26)
    btnFlingTab.BackgroundColor3 = (UIThemes[Config.UITheme] or UIThemes["Red"]).Main
    btnFlingTab.Font = Enum.Font.GothamBold
    btnFlingTab.TextSize = 10
    btnFlingTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnFlingTab.Text = "🌪️ Fling Engine"
    btnFlingTab.AutoButtonColor = false
    btnFlingTab.Parent = TrollSubNav
    Instance.new("UICorner", btnFlingTab).CornerRadius = UDim.new(0, 6)

    local btnVoteDupeTab = Instance.new("TextButton")
    btnVoteDupeTab.Size = UDim2.new(0.48, -4, 0, 26)
    btnVoteDupeTab.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
    btnVoteDupeTab.Font = Enum.Font.GothamBold
    btnVoteDupeTab.TextSize = 10
    btnVoteDupeTab.TextColor3 = Color3.fromRGB(170, 185, 210)
    btnVoteDupeTab.Text = "🗳️ Vote Dupe"
    btnVoteDupeTab.AutoButtonColor = false
    btnVoteDupeTab.Parent = TrollSubNav
    Instance.new("UICorner", btnVoteDupeTab).CornerRadius = UDim.new(0, 6)

    btnFlingTab.MouseButton1Click:Connect(function()
        local curTh = UIThemes[Config.UITheme] or UIThemes["Red"]
        SubTrollFling.Visible = true
        SubTrollVoteDupe.Visible = false
        TweenService:Create(btnFlingTab, TweenInfo.new(0.18), {BackgroundColor3 = curTh.Main, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        TweenService:Create(btnVoteDupeTab, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(24, 28, 40), TextColor3 = Color3.fromRGB(170, 185, 210)}):Play()
    end)

    btnVoteDupeTab.MouseButton1Click:Connect(function()
        local curTh = UIThemes[Config.UITheme] or UIThemes["Red"]
        SubTrollFling.Visible = false
        SubTrollVoteDupe.Visible = true
        TweenService:Create(btnVoteDupeTab, TweenInfo.new(0.18), {BackgroundColor3 = curTh.Main, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        TweenService:Create(btnFlingTab, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(24, 28, 40), TextColor3 = Color3.fromRGB(170, 185, 210)}):Play()
    end)

    -- ==========================================
    -- 🎨 SUB-TAB: FLING ENGINE COMPONENTS
    -- ==========================================
    createSectionHeader(SubTrollFling, "🌪️ УПРАВЛЕНИЕ МУЛЬТИ-ФЛИНГОМ")

    -- Status Card
    local fStatusCard = Instance.new("Frame")
    fStatusCard.Size = UDim2.new(1, 0, 0, 36)
    fStatusCard.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
    fStatusCard.BorderSizePixel = 0
    fStatusCard.Parent = SubTrollFling
    Instance.new("UICorner", fStatusCard).CornerRadius = UDim.new(0, 8)
    do
        local fscStroke = Instance.new("UIStroke", fStatusCard)
        fscStroke.Color = Color3.fromRGB(45, 55, 75)
        fscStroke.Thickness = 1
        fscStroke.Transparency = 0.4
    end

    flingStatusTextLabel = Instance.new("TextLabel")
    flingStatusTextLabel.Size = UDim2.new(1, -20, 1, 0)
    flingStatusTextLabel.Position = UDim2.new(0, 10, 0, 0)
    flingStatusTextLabel.BackgroundTransparency = 1
    flingStatusTextLabel.Font = Enum.Font.GothamBold
    flingStatusTextLabel.TextSize = 10
    flingStatusTextLabel.TextColor3 = Color3.fromRGB(180, 205, 235)
    flingStatusTextLabel.TextXAlignment = Enum.TextXAlignment.Left
    flingStatusTextLabel.Text = "🎯 Выберите игроков из списка ниже для запуска флинга"
    flingStatusTextLabel.Parent = fStatusCard

    -- Start / Stop Action Buttons
    createButton(SubTrollFling, "🚀 НАЧАТЬ FLING (START)", Color3.fromRGB(35, 175, 80), function()
        startMultiFling()
    end)

    createButton(SubTrollFling, "🛑 ОСТАНОВИТЬ FLING (STOP)", Color3.fromRGB(220, 45, 55), function()
        stopMultiFling()
    end)

    -- Method Selector Button
    local methodSelectorBtn = nil
    methodSelectorBtn = createButton(SubTrollFling, "⚙️ Метод: " .. (Config.FlingMethod or "BodyVelocity"), Color3.fromRGB(34, 44, 64), function()
        flingCurrentMethodIndex = (flingCurrentMethodIndex % #flingMethodList) + 1
        Config.FlingMethod = flingMethodList[flingCurrentMethodIndex]
        saveConfig()
        methodSelectorBtn.Text = "⚙️ Метод: " .. Config.FlingMethod
        showNotification("🌪️ МЕТОД ФЛИНГА", "Выбран режим физики: " .. Config.FlingMethod, Color3.fromRGB(80, 200, 255), "⚙️", 2.5)
    end)

    -- Power and Duration Sliders
    createSlider(SubTrollFling, "⚡ Сила импульса (Power)", 1, 50, "FlingPower", "%dx")

    Config.FlingDurationScaled = math.floor((Config.FlingDuration or 1.5) * 10)
    createSlider(SubTrollFling, "⏱️ Длительность на цель", 5, 40, "FlingDurationScaled", "%.1f сек", function(v)
        Config.FlingDuration = v / 10
        saveConfig()
    end)

    createToggle(SubTrollFling, "🔁 Возврат на исходную позицию (Anti-Void)", "FlingReturnToOldPos")
    createToggle(SubTrollFling, "🌌 Void Check (Не тепаться в воздух / ждать пустоту)", "FlingAirVoidCheck")

    -- Quick Filters Header
    createSectionHeader(SubTrollFling, "🎯 БЫСТРЫЕ ФИЛЬТРЫ И ВЫБОР РОЛЕЙ")

    -- Filter Buttons Container (Grid)
    local filterGridCard = Instance.new("Frame")
    filterGridCard.Size = UDim2.new(1, 0, 0, 72)
    filterGridCard.BackgroundTransparency = 1
    filterGridCard.Parent = SubTrollFling

    do
        local fgLayout = Instance.new("UIGridLayout", filterGridCard)
        fgLayout.CellSize = UDim2.new(0.485, -2, 0, 32)
        fgLayout.CellPadding = UDim2.new(0.03, 0, 0, 6)
    end

    local function makeQuickFilterBtn(text, color, cb)
        local b = Instance.new("TextButton")
        b.BackgroundColor3 = color
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Text = text
        b.AutoButtonColor = false
        b.Parent = filterGridCard
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local bStroke = Instance.new("UIStroke", b)
        bStroke.Color = Color3.fromRGB(255, 255, 255)
        bStroke.Thickness = 1
        bStroke.Transparency = 0.8
        b.MouseButton1Click:Connect(cb)
        return b
    end

    makeQuickFilterBtn("💀 Только Murderer", Color3.fromRGB(180, 30, 45), function()
        table.clear(SelectedFlingTargets)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and detectPlayerRole(plr) == "Murderer" then
                SelectedFlingTargets[plr.Name] = plr
            end
        end
        if updateFlingPlayerListCards then updateFlingPlayerListCards() end
        updateFlingUIStatus()
        showNotification("🎯 ФИЛЬТР", "Выбран только Murderer", Color3.fromRGB(255, 50, 70), "💀", 2)
    end)

    makeQuickFilterBtn("🛡️ Только Sheriff / Hero", Color3.fromRGB(30, 90, 180), function()
        table.clear(SelectedFlingTargets)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local r = detectPlayerRole(plr)
                if r == "Sheriff" or r == "Hero" then
                    SelectedFlingTargets[plr.Name] = plr
                end
            end
        end
        if updateFlingPlayerListCards then updateFlingPlayerListCards() end
        updateFlingUIStatus()
        showNotification("🎯 ФИЛЬТР", "Выбраны Sheriff & Hero", Color3.fromRGB(45, 140, 255), "🛡️", 2)
    end)

    makeQuickFilterBtn("👥 Все Innocents", Color3.fromRGB(35, 135, 65), function()
        table.clear(SelectedFlingTargets)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and detectPlayerRole(plr) == "Innocent" then
                SelectedFlingTargets[plr.Name] = plr
            end
        end
        if updateFlingPlayerListCards then updateFlingPlayerListCards() end
        updateFlingUIStatus()
        showNotification("🎯 ФИЛЬТР", "Выбраны все мирные игроки", Color3.fromRGB(40, 200, 90), "👥", 2)
    end)

    makeQuickFilterBtn("✅ Выбрать всех", Color3.fromRGB(55, 65, 90), function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                SelectedFlingTargets[plr.Name] = plr
            end
        end
        if updateFlingPlayerListCards then updateFlingPlayerListCards() end
        updateFlingUIStatus()
        showNotification("🎯 ФИЛЬТР", "Выбраны ВСЕ игроки на сервере", Color3.fromRGB(100, 220, 255), "✅", 2)
    end)

    createButton(SubTrollFling, "❌ Снять выбор со всех игроков", Color3.fromRGB(40, 48, 66), function()
        table.clear(SelectedFlingTargets)
        if updateFlingPlayerListCards then updateFlingPlayerListCards() end
        updateFlingUIStatus()
        showNotification("🎯 ФИЛЬТР", "Выбор целей очищен", Color3.fromRGB(150, 165, 185), "❌", 2)
    end)

    -- Live Players Radar Section
    createSectionHeader(SubTrollFling, "👥 СПИСОК ИГРОКОВ (ЖИВОЙ РАДАР & РОЛИ)")

    local PlayerCardsListContainer = Instance.new("Frame")
    PlayerCardsListContainer.Size = UDim2.new(1, 0, 0, 0)
    PlayerCardsListContainer.AutomaticSize = Enum.AutomaticSize.Y
    PlayerCardsListContainer.BackgroundTransparency = 1
    PlayerCardsListContainer.Parent = SubTrollFling

do
    local pclLayout = Instance.new("UIListLayout", PlayerCardsListContainer)
    pclLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pclLayout.Padding = UDim.new(0, 6)
end

updateFlingPlayerListCards = function()
    if not PlayerCardsListContainer or not PlayerCardsListContainer.Parent then return end

    local currentPlayers = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            currentPlayers[plr.Name] = plr
        end
    end

    -- Remove cards of players that left
    for name, ref in pairs(FlingCardReferences) do
        if not currentPlayers[name] then
            if ref.Card and ref.Card.Parent then ref.Card:Destroy() end
            FlingCardReferences[name] = nil
            SelectedFlingTargets[name] = nil
        end
    end

    local myRoot = getLocalRoot()
    local myPos = myRoot and myRoot.Position or Vector3.zero

    -- Update or create cards
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local ref = FlingCardReferences[plr.Name]
            local role = detectPlayerRole(plr)
            local dist = 0
            local hasChar = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if hasChar and myRoot then
                dist = math.floor((plr.Character.HumanoidRootPart.Position - myPos).Magnitude)
            end
            local isGhost = hasNoCollisionTarget(plr.Character)
            local isSelected = (SelectedFlingTargets[plr.Name] ~= nil)

            local roleColor = Color3.fromRGB(120, 140, 160)
            local roleIcon = "👥"
            if role == "Murderer" then
                roleColor = Color3.fromRGB(235, 45, 65)
                roleIcon = "💀"
            elseif role == "Zombie" then
                roleColor = Color3.fromRGB(80, 220, 80)
                roleIcon = "🧟"
            elseif role == "Survivor" then
                roleColor = Color3.fromRGB(40, 180, 255)
                roleIcon = "🛡️"
            elseif role == "Sheriff" then
                roleColor = Color3.fromRGB(45, 130, 255)
                roleIcon = "🛡️"
            elseif role == "Hero" then
                roleColor = Color3.fromRGB(255, 205, 40)
                roleIcon = "⭐"
            elseif role == "Innocent" then
                roleColor = Color3.fromRGB(45, 195, 95)
                roleIcon = "👥"
            elseif role == "Lobby" then
                roleColor = Color3.fromRGB(115, 130, 150)
                roleIcon = "🛋️"
            end

            if not ref or not ref.Card or not ref.Card.Parent then
                local card = Instance.new("Frame")
                card.Size = UDim2.new(1, 0, 0, 52)
                card.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
                card.BorderSizePixel = 0
                card.Parent = PlayerCardsListContainer
                Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

                local cStroke = Instance.new("UIStroke", card)
                cStroke.Color = Color3.fromRGB(36, 44, 62)
                cStroke.Thickness = 1
                cStroke.Transparency = 0.4

                -- Avatar Headshot
                local avatarImg = Instance.new("ImageLabel")
                avatarImg.Size = UDim2.new(0, 36, 0, 36)
                avatarImg.Position = UDim2.new(0, 8, 0.5, -18)
                avatarImg.BackgroundColor3 = Color3.fromRGB(26, 32, 46)
                avatarImg.BorderSizePixel = 0
                avatarImg.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", plr.UserId)
                avatarImg.Parent = card
                Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

                -- Display Name & Username
                local nameLbl = Instance.new("TextLabel")
                nameLbl.Size = UDim2.new(0, 120, 0, 16)
                nameLbl.Position = UDim2.new(0, 52, 0, 8)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Font = Enum.Font.GothamBold
                nameLbl.TextSize = 10
                nameLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                nameLbl.Text = plr.DisplayName
                nameLbl.Parent = card

                local userLbl = Instance.new("TextLabel")
                userLbl.Size = UDim2.new(0, 120, 0, 14)
                userLbl.Position = UDim2.new(0, 52, 0, 26)
                userLbl.BackgroundTransparency = 1
                userLbl.Font = Enum.Font.Gotham
                userLbl.TextSize = 8
                userLbl.TextColor3 = Color3.fromRGB(140, 155, 180)
                userLbl.TextXAlignment = Enum.TextXAlignment.Left
                userLbl.TextTruncate = Enum.TextTruncate.AtEnd
                userLbl.Text = "@" .. plr.Name
                userLbl.Parent = card

                -- Role Badge
                local roleBadge = Instance.new("Frame")
                roleBadge.Size = UDim2.new(0, 70, 0, 18)
                roleBadge.Position = UDim2.new(0, 176, 0, 8)
                roleBadge.BackgroundColor3 = roleColor
                roleBadge.BorderSizePixel = 0
                roleBadge.Parent = card
                Instance.new("UICorner", roleBadge).CornerRadius = UDim.new(0, 4)

                local roleLbl = Instance.new("TextLabel")
                roleLbl.Size = UDim2.new(1, 0, 1, 0)
                roleLbl.BackgroundTransparency = 1
                roleLbl.Font = Enum.Font.GothamBold
                roleLbl.TextSize = 8
                roleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                roleLbl.Text = roleIcon .. " " .. role
                roleLbl.Parent = roleBadge

                -- Distance & Ghost Indicator Label
                local telemetryLbl = Instance.new("TextLabel")
                telemetryLbl.Size = UDim2.new(0, 100, 0, 14)
                telemetryLbl.Position = UDim2.new(0, 176, 0, 28)
                telemetryLbl.BackgroundTransparency = 1
                telemetryLbl.Font = Enum.Font.GothamMedium
                telemetryLbl.TextSize = 8
                telemetryLbl.TextColor3 = isGhost and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(150, 170, 195)
                telemetryLbl.TextXAlignment = Enum.TextXAlignment.Left
                telemetryLbl.Text = string.format("📏 %dm • %s", dist, isGhost and "👻 Ghost" or "🟢 Col")
                telemetryLbl.Parent = card

                -- Quick Single Fling Button [🌪️]
                local flingBtn = Instance.new("TextButton")
                flingBtn.Size = UDim2.new(0, 30, 0, 30)
                flingBtn.Position = UDim2.new(1, -74, 0.5, -15)
                flingBtn.BackgroundColor3 = Color3.fromRGB(36, 44, 62)
                flingBtn.Text = "🌪️"
                flingBtn.TextSize = 14
                flingBtn.AutoButtonColor = false
                flingBtn.Parent = card
                Instance.new("UICorner", flingBtn).CornerRadius = UDim.new(0, 6)

                flingBtn.MouseButton1Click:Connect(function()
                    showNotification("🌪️ FLING", "Запуск одиночного флинга: " .. plr.Name, Color3.fromRGB(80, 220, 255), "🌪️", 2)
                    task.spawn(function()
                        executeSingleFling(plr, true)
                    end)
                end)

                -- Checkbox Toggle Button [✓]
                local checkBtn = Instance.new("TextButton")
                checkBtn.Size = UDim2.new(0, 30, 0, 30)
                checkBtn.Position = UDim2.new(1, -38, 0.5, -15)
                checkBtn.BackgroundColor3 = isSelected and Color3.fromRGB(35, 175, 80) or Color3.fromRGB(30, 36, 50)
                checkBtn.Text = isSelected and "✓" or ""
                checkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                checkBtn.Font = Enum.Font.GothamBold
                checkBtn.TextSize = 14
                checkBtn.AutoButtonColor = false
                checkBtn.Parent = card
                Instance.new("UICorner", checkBtn).CornerRadius = UDim.new(0, 6)
                local checkStroke = Instance.new("UIStroke", checkBtn)
                checkStroke.Color = isSelected and Color3.fromRGB(80, 255, 130) or Color3.fromRGB(50, 60, 85)
                checkStroke.Thickness = 1

                checkBtn.MouseButton1Click:Connect(function()
                    if SelectedFlingTargets[plr.Name] then
                        SelectedFlingTargets[plr.Name] = nil
                        checkBtn.BackgroundColor3 = Color3.fromRGB(30, 36, 50)
                        checkBtn.Text = ""
                        checkStroke.Color = Color3.fromRGB(50, 60, 85)
                    else
                        SelectedFlingTargets[plr.Name] = plr
                        checkBtn.BackgroundColor3 = Color3.fromRGB(35, 175, 80)
                        checkBtn.Text = "✓"
                        checkStroke.Color = Color3.fromRGB(80, 255, 130)
                    end
                    updateFlingUIStatus()
                end)

                FlingCardReferences[plr.Name] = {
                    Card = card,
                    RoleBadge = roleBadge,
                    RoleLbl = roleLbl,
                    TelemetryLbl = telemetryLbl,
                    CheckBtn = checkBtn,
                    CheckStroke = checkStroke
                }
            else
                -- Live update existing card
                ref.RoleBadge.BackgroundColor3 = roleColor
                ref.RoleLbl.Text = roleIcon .. " " .. role
                ref.TelemetryLbl.Text = string.format("📏 %dm • %s", dist, isGhost and "👻 Ghost" or "🟢 Col")
                ref.TelemetryLbl.TextColor3 = isGhost and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(150, 170, 195)
                ref.CheckBtn.BackgroundColor3 = isSelected and Color3.fromRGB(35, 175, 80) or Color3.fromRGB(30, 36, 50)
                ref.CheckBtn.Text = isSelected and "✓" or ""
                ref.CheckStroke.Color = isSelected and Color3.fromRGB(80, 255, 130) or Color3.fromRGB(50, 60, 85)
            end
        end
    end
end

-- Refresh on player events & live telemetry loop
Players.PlayerAdded:Connect(function(plr)
    task.wait(1)
    if updateFlingPlayerListCards then updateFlingPlayerListCards() end
    updateFlingUIStatus()
end)

Players.PlayerRemoving:Connect(function(plr)
    if SelectedFlingTargets[plr.Name] then
        SelectedFlingTargets[plr.Name] = nil
    end
    if updateFlingPlayerListCards then updateFlingPlayerListCards() end
    updateFlingUIStatus()
end)

task.spawn(function()
    while _G.MM2_Hub_Running and (_G.MM2_Hub_InstanceID == InstanceID) do
        task.wait(0.8)
        pcall(function()
            if TabFling and TabFling.Visible and updateFlingPlayerListCards then
                updateFlingPlayerListCards()
            end
        end)
    end
end)

task.delay(0.5, function()
    pcall(function()
        if updateFlingPlayerListCards then updateFlingPlayerListCards() end
        updateFlingUIStatus()
    end)
end)

    -- ==========================================
    -- 🗳️ SUB-TAB: VOTE DUPE
    -- ==========================================
    ;(function()
    createSectionHeader(SubTrollVoteDupe, "🗳️ ДЮП ГОЛОСОВАНИЙ ЗА КАРТЫ (VOTE DUPE)")

    local voteDupeCount = 0
    local voteDupeCards = {}
    local voteDupeStatusLbl = nil

    -- Vote Dupe Status Card
    local vdStatusCard = Instance.new("Frame")
    vdStatusCard.Size = UDim2.new(1, 0, 0, 42)
    vdStatusCard.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
    vdStatusCard.BorderSizePixel = 0
    vdStatusCard.Parent = SubTrollVoteDupe
    Instance.new("UICorner", vdStatusCard).CornerRadius = UDim.new(0, 8)
    do
        local vscStroke = Instance.new("UIStroke", vdStatusCard)
        vscStroke.Color = Color3.fromRGB(45, 55, 75)
        vscStroke.Thickness = 1
        vscStroke.Transparency = 0.4
    end

    voteDupeStatusLbl = Instance.new("TextLabel")
    voteDupeStatusLbl.Size = UDim2.new(1, -20, 1, 0)
    voteDupeStatusLbl.Position = UDim2.new(0, 10, 0, 0)
    voteDupeStatusLbl.BackgroundTransparency = 1
    voteDupeStatusLbl.Font = Enum.Font.GothamMedium
    voteDupeStatusLbl.TextSize = 9
    voteDupeStatusLbl.TextColor3 = Color3.fromRGB(180, 205, 235)
    voteDupeStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
    voteDupeStatusLbl.TextWrapped = true
    voteDupeStatusLbl.Text = "⏸️ Дюп выключен • Выберите карту из списка ниже"
    voteDupeStatusLbl.Parent = vdStatusCard

    -- Map Cards Header
    createSectionHeader(SubTrollVoteDupe, "🗺️ ДОСТУПНЫЕ КАРТЫ ДЛЯ ГОЛОСОВАНИЯ")

    local function getVotePadObj(slot)
        local lobby = workspace:FindFirstChild("RegularLobby") or workspace:FindFirstChild("Lobby")
        if lobby then
            local vpFolder = lobby:FindFirstChild("VotePads", true)
            if vpFolder then
                local p = vpFolder:FindFirstChild("VotePad" .. slot)
                if p then return p end
            end
            local p = lobby:FindFirstChild("VotePad" .. slot, true)
            if p then return p end
        end
        return workspace:FindFirstChild("VotePad" .. slot, true)
    end

    local function fetchMapSlotInfo(slot)
        local info = {
            MapName = "Ожидание карты...",
            VotesText = "Голосов: 0",
            Image = "",
            PadExists = false
        }
        local padObj = getVotePadObj(slot)
        if padObj then
            info.PadExists = true
            local vGui = padObj:FindFirstChild("VoteInfoGui")
            if vGui and vGui:FindFirstChild("Container") then
                local mn = vGui.Container:FindFirstChild("MapName")
                local vt = vGui.Container:FindFirstChild("Votes")
                if mn and mn.Text ~= "" then info.MapName = mn.Text end
                if vt and vt.Text ~= "" then info.VotesText = vt.Text end
            end
            local mGui = padObj:FindFirstChild("MapInfoGui")
            if mGui then
                local mi = mGui:FindFirstChild("MapIcon") or mGui:FindFirstChildWhichIsA("ImageLabel", true)
                if mi and mi.Image ~= "" then info.Image = mi.Image end
            end
        end

        local lobby = workspace:FindFirstChild("RegularLobby") or workspace:FindFirstChild("Lobby")
        if (info.MapName == "Ожидание карты..." or info.Image == "") and lobby and lobby:FindFirstChild("VoteIcons", true) then
            local vIcons = lobby:FindFirstChild("VoteIcons", true)
            local vp = vIcons:FindFirstChild("VotePad" .. slot)
            if vp then
                local mi = vp:FindFirstChild("MapInfo")
                if mi and mi:FindFirstChild("Surface") and mi.Surface:FindFirstChild("Frame") then
                    local f = mi.Surface.Frame
                    if f:FindFirstChild("MapName") and f.MapName.Text ~= "" then
                        info.MapName = f.MapName.Text
                    end
                    if f:FindFirstChild("Votes") and f.Votes.Text ~= "" then
                        info.VotesText = f.Votes.Text
                    end
                end
                local s = vp:FindFirstChild("Surface")
                local bg = s and s:FindFirstChild("Background")
                if bg and bg.Image ~= "" and info.Image == "" then
                    info.Image = bg.Image
                end
            end
        end

        return info
    end

    local function getVotePadParts(slot)
        local padObj = getVotePadObj(slot)
        if not padObj then return nil, nil end
        local pad = padObj:FindFirstChild("Pad")
        local lobby = workspace:FindFirstChild("RegularLobby") or workspace:FindFirstChild("Lobby")
        local vPads = lobby and lobby:FindFirstChild("VotePads", true)
        local detector = vPads and vPads:FindFirstChild("Detector" .. slot)
        return pad, detector
    end

    local updateVoteDupeCardVisuals

    local function createMapOptionCard(slot)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 56)
        card.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
        card.BorderSizePixel = 0
        card.Parent = SubTrollVoteDupe
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

        local stroke = Instance.new("UIStroke", card)
        stroke.Thickness = 1.2
        stroke.Color = Color3.fromRGB(45, 55, 75)
        stroke.Transparency = 0.5

        -- Image container
        local imgFrame = Instance.new("Frame")
        imgFrame.Size = UDim2.new(0, 44, 0, 44)
        imgFrame.Position = UDim2.new(0, 6, 0.5, -22)
        imgFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
        imgFrame.BorderSizePixel = 0
        imgFrame.Parent = card
        Instance.new("UICorner", imgFrame).CornerRadius = UDim.new(0, 6)

        local mapImg = Instance.new("ImageLabel")
        mapImg.Size = UDim2.new(1, 0, 1, 0)
        mapImg.BackgroundTransparency = 1
        mapImg.ScaleType = Enum.ScaleType.Crop
        mapImg.Image = ""
        mapImg.Parent = imgFrame
        Instance.new("UICorner", mapImg).CornerRadius = UDim.new(0, 6)

        local slotBadge = Instance.new("TextLabel")
        slotBadge.Size = UDim2.new(0, 18, 0, 14)
        slotBadge.Position = UDim2.new(0, 2, 0, 2)
        slotBadge.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        slotBadge.BackgroundTransparency = 0.35
        slotBadge.Font = Enum.Font.GothamBold
        slotBadge.TextSize = 8
        slotBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
        slotBadge.Text = "#" .. slot
        slotBadge.Parent = imgFrame
        Instance.new("UICorner", slotBadge).CornerRadius = UDim.new(0, 3)

        -- Map Name
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -165, 0, 18)
        nameLbl.Position = UDim2.new(0, 58, 0, 8)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 10
        nameLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Text = "Карта #" .. slot
        nameLbl.Parent = card

        -- Votes Label
        local votesLbl = Instance.new("TextLabel")
        votesLbl.Size = UDim2.new(1, -165, 0, 14)
        votesLbl.Position = UDim2.new(0, 58, 0, 28)
        votesLbl.BackgroundTransparency = 1
        votesLbl.Font = Enum.Font.GothamMedium
        votesLbl.TextSize = 9
        votesLbl.TextColor3 = Color3.fromRGB(100, 215, 255)
        votesLbl.TextXAlignment = Enum.TextXAlignment.Left
        votesLbl.Text = "📊 Голосов: 0"
        votesLbl.Parent = card

        -- Select Button
        local selectBtn = Instance.new("TextButton")
        selectBtn.Size = UDim2.new(0, 96, 0, 32)
        selectBtn.Position = UDim2.new(1, -102, 0.5, -16)
        selectBtn.BackgroundColor3 = Color3.fromRGB(30, 38, 54)
        selectBtn.Font = Enum.Font.GothamBold
        selectBtn.TextSize = 10
        selectBtn.TextColor3 = Color3.fromRGB(180, 195, 220)
        selectBtn.Text = "ВЫБРАТЬ"
        selectBtn.AutoButtonColor = false
        selectBtn.Parent = card
        Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 6)

        local function onSelected()
            Config.VoteDupeSelectedSlot = slot
            saveConfig()
            if updateVoteDupeCardVisuals then updateVoteDupeCardVisuals() end
            local info = fetchMapSlotInfo(slot)
            showNotification("🗳️ VOTE DUPE", string.format("Выбрана Карта #%d: %s", slot, info.MapName), Color3.fromRGB(80, 200, 255), "🗳️", 2.5)
        end

        selectBtn.MouseButton1Click:Connect(onSelected)

        -- Card background click also selects
        local clickCatcher = Instance.new("TextButton")
        clickCatcher.Size = UDim2.new(1, -104, 1, 0)
        clickCatcher.BackgroundTransparency = 1
        clickCatcher.Text = ""
        clickCatcher.Parent = card
        clickCatcher.MouseButton1Click:Connect(onSelected)

        voteDupeCards[slot] = {
            Card = card,
            Stroke = stroke,
            MapImg = mapImg,
            NameLbl = nameLbl,
            VotesLbl = votesLbl,
            SelectBtn = selectBtn
        }
    end

    createMapOptionCard(1)
    createMapOptionCard(2)
    createMapOptionCard(3)

    local function isVotingActive()
        if isRoundActive() then return false end
        local validPadsCount = 0
        for slot = 1, 3 do
            local padObj = getVotePadObj(slot)
            if padObj then
                local vGui = padObj:FindFirstChild("VoteInfoGui")
                local isGuiEnabled = vGui and (vGui.Enabled == true)
                local mapName = ""
                if vGui and vGui:FindFirstChild("Container") and vGui.Container:FindFirstChild("MapName") then
                    mapName = vGui.Container.MapName.Text or ""
                end

                if isGuiEnabled and mapName ~= "" and mapName ~= "Ожидание карты..." and mapName ~= "MAP NAME" then
                    validPadsCount = validPadsCount + 1
                end
            end
        end

        return validPadsCount > 0
    end

    updateVoteDupeCardVisuals = function()
        local curTh = UIThemes[Config.UITheme] or UIThemes["Red"]
        local chosenSlot = Config.VoteDupeSelectedSlot or 1
        for slot = 1, 3 do
            local refs = voteDupeCards[slot]
            if refs then
                local isChosen = (slot == chosenSlot)
                local info = fetchMapSlotInfo(slot)
                refs.NameLbl.Text = info.MapName
                refs.VotesLbl.Text = "📊 " .. info.VotesText
                if info.Image ~= "" then
                    refs.MapImg.Image = info.Image
                end

                if isChosen then
                    refs.Stroke.Color = curTh.Main
                    refs.Stroke.Transparency = 0
                    refs.Stroke.Thickness = 1.6
                    refs.SelectBtn.BackgroundColor3 = Color3.fromRGB(35, 175, 80)
                    refs.SelectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    refs.SelectBtn.Text = "✓ ВЫБРАНО"
                else
                    refs.Stroke.Color = Color3.fromRGB(45, 55, 75)
                    refs.Stroke.Transparency = 0.5
                    refs.Stroke.Thickness = 1.0
                    refs.SelectBtn.BackgroundColor3 = Color3.fromRGB(30, 38, 54)
                    refs.SelectBtn.TextColor3 = Color3.fromRGB(180, 195, 220)
                    refs.SelectBtn.Text = "ВЫБРАТЬ"
                end
            end
        end

        if voteDupeStatusLbl then
            local info = fetchMapSlotInfo(chosenSlot)
            local voting = isVotingActive()
            if Config.VoteDupeActive then
                if not voting then
                    if isRoundActive() then
                        local rSecs = _G.MM2_GetRoundTimerSeconds and _G.MM2_GetRoundTimerSeconds() or -1
                        local tStr = (rSecs > 0) and string.format(" (⏳ %d сек)", rSecs) or ""
                        voteDupeStatusLbl.Text = string.format("⏸️ Дюп на паузе • Идет раунд%s • Ожидание лобби", tStr)
                        voteDupeStatusLbl.TextColor3 = Color3.fromRGB(255, 175, 55)
                    else
                        voteDupeStatusLbl.Text = "⏸️ Дюп на паузе • Голосование окончено или карты недоступны"
                        voteDupeStatusLbl.TextColor3 = Color3.fromRGB(255, 175, 55)
                    end
                else
                    voteDupeStatusLbl.Text = string.format("⚡ АКТИВЕН ДЮП • Карта #%d (%s) • Дюпнуто: %d голосов", chosenSlot, info.MapName, voteDupeCount)
                    voteDupeStatusLbl.TextColor3 = Color3.fromRGB(80, 255, 140)
                end
            else
                if not voting then
                    voteDupeStatusLbl.Text = string.format("⏸️ Дюп выключен • Голосование не идет • Выбрана: #%d (%s)", chosenSlot, info.MapName)
                    voteDupeStatusLbl.TextColor3 = Color3.fromRGB(150, 170, 195)
                else
                    voteDupeStatusLbl.Text = string.format("⏸️ Дюп выключен • Выбрана: Карта #%d (%s) • Сделано: %d", chosenSlot, info.MapName, voteDupeCount)
                    voteDupeStatusLbl.TextColor3 = Color3.fromRGB(180, 205, 235)
                end
            end
        end
    end

    local function stepVoteAction(slot)
        slot = slot or Config.VoteDupeSelectedSlot or 1
        if isRoundActive() then
            return false, "Голосование недоступно (идет раунд)"
        end
        local pad, detector = getVotePadParts(slot)
        local root = getLocalRoot()
        local char = LocalPlayer.Character
        if not char or not root then return false, "Нет персонажа" end
        if not pad then return false, "Плитка голосования не найдена в лобби" end

        -- Position upright standing directly on top of the pad (avoid sideways rotation)
        root.CFrame = CFrame.new(pad.Position + Vector3.new(0, 3.0, 0))
        root.Anchored = false
        root.AssemblyLinearVelocity = Vector3.new(0, -2.0, 0)
        root.AssemblyAngularVelocity = Vector3.zero

        -- Trigger touch on Pad with all character limbs (Root, Torso, Legs)
        for _, limb in ipairs(char:GetChildren()) do
            if limb:IsA("BasePart") and typeof(firetouchinterest) == "function" then
                pcall(function()
                    firetouchinterest(limb, pad, 0)
                    firetouchinterest(pad, limb, 0)
                    if detector then
                        firetouchinterest(limb, detector, 0)
                        firetouchinterest(detector, limb, 0)
                    end
                end)
            end
        end
        task.wait(0.06)
        for _, limb in ipairs(char:GetChildren()) do
            if limb:IsA("BasePart") and typeof(firetouchinterest) == "function" then
                pcall(function()
                    firetouchinterest(limb, pad, 1)
                    firetouchinterest(pad, limb, 1)
                    if detector then
                        firetouchinterest(limb, detector, 1)
                        firetouchinterest(detector, limb, 1)
                    end
                end)
            end
        end
        return true
    end

    local function fastResetCharacter()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() hum.Health = 0 end)
        end
        if char then
            pcall(function() char:BreakJoints() end)
        end
    end

    -- Controls Header
    createSectionHeader(SubTrollVoteDupe, "⚡ УПРАВЛЕНИЕ И АВТОМАТИЗАЦИЯ ДЮПА")

    createToggle(SubTrollVoteDupe, "⚡ Авто-дюп голосов (Auto Vote Dupe)", "VoteDupeActive", function(enabled)
        if enabled then
            showNotification("🗳️ VOTE DUPE", "Авто-дюп запущен! Вставание на плитку + быстрый сброс...", Color3.fromRGB(80, 255, 140), "⚡", 3)
        else
            showNotification("🗳️ VOTE DUPE", "Авто-дюп остановлен.", Color3.fromRGB(255, 90, 90), "🛑", 2)
        end
        if updateVoteDupeCardVisuals then updateVoteDupeCardVisuals() end
    end)

    createButton(SubTrollVoteDupe, "📍 Проголосовать 1 раз за выбранную карту", Color3.fromRGB(45, 140, 255), function()
        local ok, err = stepVoteAction(Config.VoteDupeSelectedSlot or 1)
        if ok then
            voteDupeCount = voteDupeCount + 1
            if updateVoteDupeCardVisuals then updateVoteDupeCardVisuals() end
            showNotification("🗳️ ГОЛОС", "Голос успешно отдан за карту #" .. tostring(Config.VoteDupeSelectedSlot or 1), Color3.fromRGB(80, 200, 255), "✓", 2)
        else
            showNotification("⚠️ ОШИБКА", tostring(err), Color3.fromRGB(255, 90, 90), "⚠️", 2)
        end
    end)

    createButton(SubTrollVoteDupe, "💀 Мгновенный сброс персонажа (Fast Reset)", Color3.fromRGB(220, 45, 55), function()
        fastResetCharacter()
        showNotification("💀 RESET", "Персонаж сброшен для нового голоса", Color3.fromRGB(255, 100, 100), "💀", 1.5)
    end)

    if Config.VoteDupeDelay == nil then Config.VoteDupeDelay = 0.35 end
    Config.VoteDupeDelayScaled = math.floor(Config.VoteDupeDelay * 10)
    createSlider(SubTrollVoteDupe, "⏱️ Задержка перед сбросом", 1, 15, "VoteDupeDelayScaled", "%.1f сек", function(v)
        Config.VoteDupeDelay = v / 10
        saveConfig()
    end)

    createToggle(SubTrollVoteDupe, "⚡ Авто-ТП к плитке сразу после респавна", "VoteDupeFastTeleport")

    createButton(SubTrollVoteDupe, "🔄 Обновить список карт и голоса", Color3.fromRGB(36, 44, 64), function()
        if updateVoteDupeCardVisuals then updateVoteDupeCardVisuals() end
        showNotification("🔄 ОБНОВЛЕНО", "Данные голосования обновлены", Color3.fromRGB(100, 220, 255), "🔄", 1.5)
    end)

    -- Auto Vote Dupe Loop
    task.spawn(function()
        while _G.MM2_Hub_Running and (_G.MM2_Hub_InstanceID == InstanceID) do
            task.wait(0.15)
            if Config.VoteDupeActive then
                if isPlayerInLobby(LocalPlayer) then
                    if not isVotingActive() then
                        task.wait(0.6)
                        if updateVoteDupeCardVisuals then updateVoteDupeCardVisuals() end
                    else
                        local char = LocalPlayer.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        local root = char and char:FindFirstChild("HumanoidRootPart")

                        if char and hum and hum.Health > 0 and root then
                            local ok = stepVoteAction(Config.VoteDupeSelectedSlot or 1)
                            if ok then
                                voteDupeCount = voteDupeCount + 1
                                if updateVoteDupeCardVisuals then updateVoteDupeCardVisuals() end
                                task.wait(Config.VoteDupeDelay or 0.35)
                                if Config.VoteDupeActive and isVotingActive() and hum and hum.Health > 0 then
                                    fastResetCharacter()
                                    task.wait(0.6)
                                end
                            else
                                task.wait(0.5)
                            end
                        end
                    end
                else
                    task.wait(1.5)
                end
            end
        end
    end)

    -- Teleport immediately upon respawn if Auto Vote Dupe is active
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        if Config.VoteDupeActive and (Config.VoteDupeFastTeleport ~= false) and isPlayerInLobby(LocalPlayer) and isVotingActive() then
            task.spawn(function()
                local tRoot = newChar:WaitForChild("HumanoidRootPart", 5)
                if tRoot and Config.VoteDupeActive and isVotingActive() then
                    task.wait(0.1)
                    stepVoteAction(Config.VoteDupeSelectedSlot or 1)
                end
            end)
        end
    end)

    -- Live UI update loop for vote info & map changes
    task.spawn(function()
        while _G.MM2_Hub_Running and (_G.MM2_Hub_InstanceID == InstanceID) do
            task.wait(1.0)
            pcall(function()
                if TabFling and TabFling.Visible and SubTrollVoteDupe and SubTrollVoteDupe.Visible then
                    if updateVoteDupeCardVisuals then updateVoteDupeCardVisuals() end
                end
            end)
        end
    end)

    task.delay(0.6, function()
        pcall(function()
            if updateVoteDupeCardVisuals then updateVoteDupeCardVisuals() end
        end)
    end)
    end)()
end -- end Fling Engine & Tab

-- ====================================================================
-- 👀 SPECTATE TAB & 3RD PERSON ENGINE
-- ====================================================================
do
    local spectatingPlayer = nil
    local SpectateCardReferences = {}
    local spectateStatusLbl = nil

    local function stopSpectating(silent)
        spectatingPlayer = nil
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            Camera.CameraType = Enum.CameraType.Custom
            Camera.CameraSubject = hum
        end
        if spectateStatusLbl then
            spectateStatusLbl.Text = "👤 Наблюдение: Вы (Сам за собой)"
            spectateStatusLbl.TextColor3 = Color3.fromRGB(150, 220, 255)
        end
        if not silent and showNotification then
            showNotification("👀 НАБЛЮДЕНИЕ ВЫКЛЮЧЕНО", "Камера возвращена на вашего персонажа.", Color3.fromRGB(100, 200, 255), "👤", 2.5)
        end
        if _G.MM2_UpdateSpectateCards then _G.MM2_UpdateSpectateCards() end
    end

    local function spectatePlayer(plr)
        if not plr or plr == LocalPlayer then
            stopSpectating()
            return
        end
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health <= 0 then
            if showNotification then
                showNotification("👀 ОШИБКА НАБЛЮДЕНИЯ", string.format("%s погиб или персонаж не найден!", plr.DisplayName or plr.Name), Color3.fromRGB(255, 90, 90), "⚠️", 3)
            end
            return
        end

        spectatingPlayer = plr
        Camera.CameraType = Enum.CameraType.Custom
        Camera.CameraSubject = hum

        local role = detectPlayerRole(plr)
        local roleColor = Color3.fromRGB(100, 220, 140)
        if role == "Murderer" then roleColor = Color3.fromRGB(255, 60, 70)
        elseif role == "Sheriff" then roleColor = Color3.fromRGB(60, 150, 255)
        elseif role == "Hero" then roleColor = Color3.fromRGB(255, 215, 40)
        elseif role == "Lobby" then roleColor = Color3.fromRGB(140, 160, 185)
        end

        if spectateStatusLbl then
            spectateStatusLbl.Text = string.format("👀 Наблюдение: %s (%s)", plr.DisplayName, role)
            spectateStatusLbl.TextColor3 = roleColor
        end

        if showNotification then
            showNotification("👀 НАБЛЮДЕНИЕ (3-Е ЛИЦО)", string.format("Камера переключена на: %s [%s]", plr.DisplayName, role), roleColor, "👀", 3)
        end

        if _G.MM2_UpdateSpectateCards then _G.MM2_UpdateSpectateCards() end
    end

    -- Spectate Status Card
    createSectionHeader(_G.TabSpectate, "👁️ НАБЛЮДЕНИЕ ОТ 3-ГО ЛИЦА (SPECTATE)")

    local statusCard = Instance.new("Frame")
    statusCard.Size = UDim2.new(1, 0, 0, 48)
    statusCard.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
    statusCard.BorderSizePixel = 0
    statusCard.Parent = _G.TabSpectate
    Instance.new("UICorner", statusCard).CornerRadius = UDim.new(0, 8)
    local scStroke = Instance.new("UIStroke", statusCard)
    scStroke.Color = Color3.fromRGB(45, 55, 75)
    scStroke.Thickness = 1
    scStroke.Transparency = 0.4

    spectateStatusLbl = Instance.new("TextLabel")
    spectateStatusLbl.Size = UDim2.new(1, -16, 1, 0)
    spectateStatusLbl.Position = UDim2.new(0, 12, 0, 0)
    spectateStatusLbl.BackgroundTransparency = 1
    spectateStatusLbl.Font = Enum.Font.GothamBold
    spectateStatusLbl.TextSize = 11
    spectateStatusLbl.TextColor3 = Color3.fromRGB(150, 220, 255)
    spectateStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
    spectateStatusLbl.Text = "👤 Наблюдение: Вы (Сам за собой)"
    spectateStatusLbl.Parent = statusCard

    -- Quick Actions (Stop / Murderer / Sheriff / Hero / Random)
    createSectionHeader(_G.TabSpectate, "⚡ БЫСТРЫЕ ДЕЙСТВИЯ")

    local specGridCard = Instance.new("Frame")
    specGridCard.Size = UDim2.new(1, 0, 0, 72)
    specGridCard.BackgroundTransparency = 1
    specGridCard.Parent = _G.TabSpectate

    local sgLayout = Instance.new("UIGridLayout", specGridCard)
    sgLayout.CellSize = UDim2.new(0.485, -2, 0, 32)
    sgLayout.CellPadding = UDim2.new(0.03, 0, 0, 6)

    local function makeSpecFilterBtn(text, color, cb)
        local b = Instance.new("TextButton")
        b.BackgroundColor3 = color
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Text = text
        b.AutoButtonColor = false
        b.Parent = specGridCard
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local bs = Instance.new("UIStroke", b)
        bs.Color = Color3.fromRGB(255, 255, 255)
        bs.Thickness = 1
        bs.Transparency = 0.8
        b.MouseButton1Click:Connect(cb)
    end

    makeSpecFilterBtn("🔄 Вернуть камеру себе", Color3.fromRGB(35, 45, 65), function()
        stopSpectating()
    end)

    makeSpecFilterBtn("💀 Мардер (Murderer)", Color3.fromRGB(190, 40, 50), function()
        local murd = CachedMurderer
        if not murd or not murd.Character or detectPlayerRole(murd) ~= "Murderer" then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and detectPlayerRole(p) == "Murderer" then murd = p break end
            end
        end
        if murd then spectatePlayer(murd) else
            if showNotification then showNotification("👀 SPECTATE", "Мардер ещё не обнаружен или погиб!", Color3.fromRGB(255, 90, 90), "💀", 2.5) end
        end
    end)

    makeSpecFilterBtn("🛡️ Шериф (Sheriff)", Color3.fromRGB(40, 110, 210), function()
        local sher = CachedSheriff
        if not sher or not sher.Character or detectPlayerRole(sher) ~= "Sheriff" then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and detectPlayerRole(p) == "Sheriff" then sher = p break end
            end
        end
        if sher then spectatePlayer(sher) else
            if showNotification then showNotification("👀 SPECTATE", "Шериф ещё не обнаружен или погиб!", Color3.fromRGB(255, 90, 90), "🛡️", 2.5) end
        end
    end)

    makeSpecFilterBtn("🎲 Случайный игрок", Color3.fromRGB(140, 70, 210), function()
        local pool = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChildOfClass("Humanoid") and p.Character.Humanoid.Health > 0 then
                table.insert(pool, p)
            end
        end
        if #pool > 0 then
            spectatePlayer(pool[math.random(1, #pool)])
        end
    end)

    -- Live Player List Cards (Matching TabFling Radar style)
    createSectionHeader(_G.TabSpectate, "👥 СПИСОК ИГРОКОВ (ВЫБЕРИТЕ ДЛЯ НАБЛЮДЕНИЯ)")

    local SpecCardsListContainer = Instance.new("Frame")
    SpecCardsListContainer.Size = UDim2.new(1, 0, 0, 0)
    SpecCardsListContainer.AutomaticSize = Enum.AutomaticSize.Y
    SpecCardsListContainer.BackgroundTransparency = 1
    SpecCardsListContainer.Parent = _G.TabSpectate

    local scLayout = Instance.new("UIListLayout", SpecCardsListContainer)
    scLayout.SortOrder = Enum.SortOrder.LayoutOrder
    scLayout.Padding = UDim.new(0, 6)

    _G.MM2_UpdateSpectateCards = function()
        if not SpecCardsListContainer or not SpecCardsListContainer.Parent then return end

        local currentPlayers = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then currentPlayers[plr.Name] = plr end
        end

        for name, ref in pairs(SpectateCardReferences) do
            if not currentPlayers[name] then
                if ref.Card and ref.Card.Parent then ref.Card:Destroy() end
                SpectateCardReferences[name] = nil
            end
        end

        local myRoot = getLocalRoot()
        local myPos = myRoot and myRoot.Position or Vector3.zero

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local ref = SpectateCardReferences[plr.Name]
                local role = detectPlayerRole(plr)
                local dist = 0
                local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                local pRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                local inLobby = (role == "Lobby") or isPlayerInLobby(plr)
                local isDead = isPlayerDead(plr) or (not hum) or (hum.Health <= 0)
                local statusText = "🟢 В игре"
                if inLobby then
                    statusText = "🛋️ В лобби"
                elseif isDead then
                    statusText = "💀 Мёртв"
                end
                if pRoot and myRoot then
                    dist = math.floor((pRoot.Position - myPos).Magnitude)
                end
                local isCurrentlySpectated = (spectatingPlayer == plr)

                local roleColor = Color3.fromRGB(120, 140, 160)
                local roleIcon = "👥"
                if role == "Murderer" then roleColor = Color3.fromRGB(235, 45, 65) roleIcon = "💀"
                elseif role == "Zombie" then roleColor = Color3.fromRGB(80, 220, 80) roleIcon = "🧟"
                elseif role == "Survivor" then roleColor = Color3.fromRGB(40, 180, 255) roleIcon = "🛡️"
                elseif role == "Sheriff" then roleColor = Color3.fromRGB(45, 130, 255) roleIcon = "🛡️"
                elseif role == "Hero" then roleColor = Color3.fromRGB(255, 205, 40) roleIcon = "⭐"
                elseif role == "Innocent" then roleColor = Color3.fromRGB(45, 195, 95) roleIcon = "👥"
                elseif role == "Lobby" then roleColor = Color3.fromRGB(115, 130, 150) roleIcon = "🛋️"
                end

                if not ref or not ref.Card or not ref.Card.Parent then
                    local card = Instance.new("Frame")
                    card.Size = UDim2.new(1, 0, 0, 52)
                    card.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
                    card.BorderSizePixel = 0
                    card.Parent = SpecCardsListContainer
                    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

                    local cStroke = Instance.new("UIStroke", card)
                    cStroke.Color = Color3.fromRGB(36, 44, 62)
                    cStroke.Thickness = 1
                    cStroke.Transparency = 0.4

                    -- Avatar Headshot
                    local avatarImg = Instance.new("ImageLabel")
                    avatarImg.Size = UDim2.new(0, 36, 0, 36)
                    avatarImg.Position = UDim2.new(0, 8, 0.5, -18)
                    avatarImg.BackgroundColor3 = Color3.fromRGB(26, 32, 46)
                    avatarImg.BorderSizePixel = 0
                    avatarImg.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", plr.UserId)
                    avatarImg.Parent = card
                    Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

                    -- Display Name & Username
                    local nameLbl = Instance.new("TextLabel")
                    nameLbl.Size = UDim2.new(0, 120, 0, 16)
                    nameLbl.Position = UDim2.new(0, 52, 0, 8)
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.Font = Enum.Font.GothamBold
                    nameLbl.TextSize = 10
                    nameLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
                    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    nameLbl.Text = plr.DisplayName
                    nameLbl.Parent = card

                    local userLbl = Instance.new("TextLabel")
                    userLbl.Size = UDim2.new(0, 120, 0, 14)
                    userLbl.Position = UDim2.new(0, 52, 0, 26)
                    userLbl.BackgroundTransparency = 1
                    userLbl.Font = Enum.Font.Gotham
                    userLbl.TextSize = 8
                    userLbl.TextColor3 = Color3.fromRGB(140, 155, 180)
                    userLbl.TextXAlignment = Enum.TextXAlignment.Left
                    userLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    userLbl.Text = "@" .. plr.Name
                    userLbl.Parent = card

                    -- Role Badge
                    local roleBadge = Instance.new("Frame")
                    roleBadge.Size = UDim2.new(0, 70, 0, 18)
                    roleBadge.Position = UDim2.new(0, 176, 0, 8)
                    roleBadge.BackgroundColor3 = roleColor
                    roleBadge.BorderSizePixel = 0
                    roleBadge.Parent = card
                    Instance.new("UICorner", roleBadge).CornerRadius = UDim.new(0, 4)

                    local roleLbl = Instance.new("TextLabel")
                    roleLbl.Size = UDim2.new(1, 0, 1, 0)
                    roleLbl.BackgroundTransparency = 1
                    roleLbl.Font = Enum.Font.GothamBold
                    roleLbl.TextSize = 8
                    roleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                    roleLbl.Text = roleIcon .. " " .. role
                    roleLbl.Parent = roleBadge

                    -- Telemetry / Status label
                    local teleLbl = Instance.new("TextLabel")
                    teleLbl.Size = UDim2.new(0, 100, 0, 14)
                    teleLbl.Position = UDim2.new(0, 176, 0, 28)
                    teleLbl.BackgroundTransparency = 1
                    teleLbl.Font = Enum.Font.GothamMedium
                    teleLbl.TextSize = 8
                    teleLbl.TextColor3 = Color3.fromRGB(160, 180, 200)
                    teleLbl.TextXAlignment = Enum.TextXAlignment.Left
                    teleLbl.Text = string.format("📏 %dm • %s", dist, statusText)
                    teleLbl.Parent = card

                    -- Spectate Action Button
                    local specBtn = Instance.new("TextButton")
                    specBtn.Size = UDim2.new(0, 80, 0, 28)
                    specBtn.Position = UDim2.new(1, -90, 0.5, -14)
                    specBtn.BackgroundColor3 = isCurrentlySpectated and Color3.fromRGB(45, 180, 100) or Color3.fromRGB(34, 42, 60)
                    specBtn.Font = Enum.Font.GothamBold
                    specBtn.TextSize = 9
                    specBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    specBtn.Text = isCurrentlySpectated and "✅ Смотрю" or "👀 Смотреть"
                    specBtn.AutoButtonColor = false
                    specBtn.Parent = card
                    Instance.new("UICorner", specBtn).CornerRadius = UDim.new(0, 6)

                    specBtn.MouseButton1Click:Connect(function()
                        if spectatingPlayer == plr then
                            stopSpectating()
                        else
                            spectatePlayer(plr)
                        end
                    end)

                    SpectateCardReferences[plr.Name] = {
                        Card = card,
                        Stroke = cStroke,
                        RoleBadge = roleBadge,
                        RoleLbl = roleLbl,
                        TeleLbl = teleLbl,
                        SpecBtn = specBtn
                    }
                else
                    ref.RoleBadge.BackgroundColor3 = roleColor
                    ref.RoleLbl.Text = roleIcon .. " " .. role
                    ref.TeleLbl.Text = string.format("📏 %dm • %s", dist, statusText)
                    if isCurrentlySpectated then
                        ref.Stroke.Color = Color3.fromRGB(50, 220, 120)
                        ref.Stroke.Thickness = 1.8
                        ref.Stroke.Transparency = 0
                        ref.SpecBtn.BackgroundColor3 = Color3.fromRGB(45, 180, 100)
                        ref.SpecBtn.Text = "✅ Смотрю"
                    else
                        ref.Stroke.Color = Color3.fromRGB(36, 44, 62)
                        ref.Stroke.Thickness = 1
                        ref.Stroke.Transparency = 0.4
                        ref.SpecBtn.BackgroundColor3 = Color3.fromRGB(34, 42, 60)
                        ref.SpecBtn.Text = "👀 Смотреть"
                    end
                end
            end
        end
    end

    -- Camera Watchdog: if spectated player dies or leaves, smoothly return camera to LocalPlayer
    RunService.RenderStepped:Connect(function()
        if spectatingPlayer then
            local char = spectatingPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not spectatingPlayer.Parent or not char or not hum or hum.Health <= 0 then
                stopSpectating(true)
                if showNotification then
                    showNotification("👀 ИГРОК ВЫБЫЛ", "Наблюдаемый игрок погиб или покинул сервер. Камера возвращена.", Color3.fromRGB(255, 180, 45), "🔄", 3)
                end
            elseif Camera.CameraSubject ~= hum then
                Camera.CameraType = Enum.CameraType.Custom
                Camera.CameraSubject = hum
            end
        end
    end)

    task.spawn(function()
        while _G.MM2_Hub_Running and (_G.MM2_Hub_InstanceID == InstanceID) do
            task.wait(1.0)
            pcall(function()
                if _G.TabSpectate and _G.TabSpectate.Visible and _G.MM2_UpdateSpectateCards then
                    _G.MM2_UpdateSpectateCards()
                end
            end)
        end
    end)
end

-- 🏝️ Dynamic Island Tab
createSectionHeader(TabIsland, "🏝️ ОСНОВНЫЕ НАСТРОЙКИ DYNAMIC ISLAND")
createToggle(TabIsland, "🏝️ Включить Dynamic Island", "DynamicIsland", function(on)
    if DynamicIsland then DynamicIsland.Visible = on and not Config.Disable3DRender end
end)
createToggle(TabIsland, "⚡ Показывать счётчик FPS", "IslandShowFPS", function(on)
    if diFpsBadge then diFpsBadge.Visible = on end
end)
createToggle(TabIsland, "📶 Показывать пинг сервера", "IslandShowPing", function(on)
    if diPingBadge then diPingBadge.Visible = on end
end)
createToggle(TabIsland, "⏳ Показывать таймер раунда", "IslandShowRoundTimer", function(on)
    if diRoundBadge then diRoundBadge.Visible = on end
end)
createToggle(TabIsland, "🕒 Показывать время ОС", "IslandShowTime", function(on)
    if diTimeBadge then diTimeBadge.Visible = on end
end)
createToggle(TabIsland, "🏷️ Показывать значок роли", "IslandShowRole", function(on)
    if diRoleBadge then diRoleBadge.Visible = on end
end)
createToggle(TabIsland, "📢 Показывать статус и события", "IslandShowStatus", function(on)
    if diStatusText then diStatusText.Visible = on end
end)
createToggle(TabIsland, "✨ Анимация расширения при наведении", "IslandHoverExpand")
createToggle(TabIsland, "⚡ Вспышка цвета при событиях", "IslandFlashAlerts")
createToggle(TabIsland, "📱 Открывать меню кликом на Dynamic Island на телефонах", "MobileIslandClickToggle", function(on)
    Config.MobileIslandClickToggle = on
    saveConfig()
    if _G.MM2_UpdateIslandInteractivity then
        _G.MM2_UpdateIslandInteractivity()
    end
end)

createSectionHeader(TabIsland, "📐 РАЗМЕР И ПОЗИЦИЯ ОСТРОВКА")
createSlider(TabIsland, "Ширина островка", 320, 800, "IslandWidth", "%d px", function(v)
    updateIslandGeometry()
end)
createSlider(TabIsland, "Высота островка", 26, 48, "IslandHeight", "%d px", function(v)
    updateIslandGeometry()
end)
createSlider(TabIsland, "Отступ сверху Y", 4, 60, "IslandYOffset", "%d px", function(v)
    updateIslandGeometry()
end)
createSlider(TabIsland, "Прозрачность стекла", 0, 80, "IslandTransparencyPct", "%d%%", function(v)
    Config.IslandTransparency = v / 100
    if DynamicIsland then DynamicIsland.BackgroundTransparency = Config.IslandTransparency end
end)
createSlider(TabIsland, "🔤 Размер текста островка", 8, 16, "IslandTextSize", "%d pt", function(v)
    applyIslandTextSize(v)
end)
createSectionHeader(TabIsland, "🎨 ТЕМА DYNAMIC ISLAND")
createButton(TabIsland, "💡 Тема островка привязана к GUI (Настроить во вкладке Themes 🎨)", Color3.fromRGB(34, 40, 58), function()
    if Tabs["Themes"] then
        for tName, tPage in pairs(Tabs) do tPage.Visible = (tName == "Themes") end
        for tName, tBtn in pairs(TabButtons) do
            local sel = (tName == "Themes")
            local curTh = UIThemes[Config.UITheme] or UIThemes["Red"]
            tBtn.BackgroundColor3 = sel and curTh.Main or Color3.fromRGB(24, 28, 40)
            tBtn.TextColor3 = sel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 175, 200)
        end
    end
end)

-- 🪙 Dedicated Coin Auto-Farm Tab
do
    createSectionHeader(TabFarm, "📊 СТАТИСТИКА АВТО-ФАРМА")

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 98)
    card.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
    card.BorderSizePixel = 0
    card.Parent = TabFarm
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color = Color3.fromRGB(45, 55, 75)
    cardStroke.Thickness = 1
    cardStroke.Transparency = 0.4

    local grid = Instance.new("UIGridLayout", card)
    grid.CellSize = UDim2.new(0.48, -4, 0, 26)
    grid.CellPadding = UDim2.new(0.04, 0, 0, 4)
    local pad = Instance.new("UIPadding", card)
    pad.PaddingTop = UDim.new(0, 5)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)

    local rLbl = Instance.new("TextLabel")
    rLbl.BackgroundTransparency = 1
    rLbl.Font = Enum.Font.GothamBold
    rLbl.TextSize = 10
    rLbl.TextColor3 = Color3.fromRGB(255, 215, 60)
    rLbl.TextXAlignment = Enum.TextXAlignment.Left
    rLbl.Text = "🪙 В раунде: 0 / 40"
    rLbl.Parent = card

    local bLbl = Instance.new("TextLabel")
    bLbl.BackgroundTransparency = 1
    bLbl.Font = Enum.Font.GothamBold
    bLbl.TextSize = 10
    bLbl.TextColor3 = Color3.fromRGB(255, 230, 90)
    bLbl.TextXAlignment = Enum.TextXAlignment.Left
    bLbl.Text = "💎 Баланс: 0 монет"
    bLbl.Parent = card

    local tLbl = Instance.new("TextLabel")
    tLbl.BackgroundTransparency = 1
    tLbl.Font = Enum.Font.GothamBold
    tLbl.TextSize = 10
    tLbl.TextColor3 = Color3.fromRGB(100, 225, 140)
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Text = "💰 За сессию: 0"
    tLbl.Parent = card

    local mLbl = Instance.new("TextLabel")
    mLbl.BackgroundTransparency = 1
    mLbl.Font = Enum.Font.GothamBold
    mLbl.TextSize = 10
    mLbl.TextColor3 = Color3.fromRGB(130, 205, 255)
    mLbl.TextXAlignment = Enum.TextXAlignment.Left
    mLbl.Text = "🗺️ На карте: 0"
    mLbl.Parent = card

    local sLbl = Instance.new("TextLabel")
    sLbl.BackgroundTransparency = 1
    sLbl.Font = Enum.Font.GothamBold
    sLbl.TextSize = 10
    sLbl.TextColor3 = Color3.fromRGB(255, 175, 75)
    sLbl.TextXAlignment = Enum.TextXAlignment.Left
    sLbl.Text = "⚡ Статус: Ожидание"
    sLbl.Parent = card

    task.spawn(function()
        while _G.MM2_Hub_Running and (_G.MM2_Hub_InstanceID == InstanceID) do
            task.wait(0.4)
            if card and card.Parent then
                pcall(function()
                    local bagCoins, isFull, bagName, bagMax = getMM2CoinBagInfo()
                    local isCandy = (bagName == "Candy")
                    local maxLimit = bagMax or (CoinTracker and CoinTracker.Max) or Config.MaxCoins or 50
                    local roundCoins = (isPlayerInLobby(LocalPlayer) or not isRoundActive()) and 0 or ((bagCoins and bagCoins > 0) and bagCoins or (CoinsCollectedThisRound or 0))
                    if isCandy then
                        rLbl.Text = string.format("🍬 В раунде: %d / %d", roundCoins, maxLimit)
                    else
                        rLbl.Text = string.format("🪙 В раунде: %d / %d", roundCoins, maxLimit)
                    end
                    local curBal = getLocalPlayerCoinBalance()
                    local curCandy = getLocalPlayerCandyBalance and getLocalPlayerCandyBalance() or 0
                    if curCandy > 0 or isCandy then
                        bLbl.Text = string.format("💎 Монеты: %d | 🍬 Конфеты: %d", curBal, curCandy)
                    else
                        bLbl.Text = string.format("💎 Баланс: %d монет", curBal)
                    end
                    local sCoins = TotalCoinsSession or (_G.MM2_Stats and _G.MM2_Stats.ServerCoins) or 0
                    local aCoins = (_G.MM2_Stats and _G.MM2_Stats.AllTimeCoins) or 0
                    local currIcon = isCandy and "🍬" or "🪙"
                    tLbl.Text = string.format("%s За сессию: %d | 💎 Всё время: %d", currIcon, sCoins, aCoins)
                    local activeCoins = getActiveCoins and getActiveCoins() or {}
                    mLbl.Text = string.format("🗺️ На карте: %d", #activeCoins)
                    sLbl.Text = "⚡ Статус: " .. (CurrentFarmStatus or "Ожидание")
                end)
            end
        end
    end)

    createButton(TabFarm, "🗑️ Сбросить статистику монет (Сервер + Всё время)", Color3.fromRGB(180, 45, 60), function()
        if _G.MM2_ResetStats then _G.MM2_ResetStats() end
    end)

    createToggle(TabFarm, "🪙 Включить Coin Auto-Farm", "CoinAutoFarm", function(on)
        if on then
            _G.MM2_LocalPlayerDiedThisRound = false
            _G.MM2_RoundLimitReached = false
            _G.MM2_MurdererEliminatedThisRound = false

            -- If in lobby and auto-hide is enabled, immediately hide under lobby!
            if isPlayerInLobby(LocalPlayer) then
                if Config.CoinLobbyHide and _G.MM2_TeleportUnderLobby then
                    _G.MM2_TeleportUnderLobby()
                    if showNotification then
                        showNotification("🙈 ЛОББИ СКРЫТНОСТЬ", "Вы телепортированы под лобби на платформу!", Color3.fromRGB(60, 200, 255), "🏗️", 2.5)
                    end
                end
            else
                -- If inside match arena and underground mode is enabled, immediately hide under map!
                if (Config.CoinUndergroundPlatform or Config.CoinFarmUnderground) and _G.MM2_HideSafelyUnderground then
                    _G.MM2_HideSafelyUnderground("Начало фарма • Уход под карту 🛡️")
                end
            end

            if _G.MM2_StartCoinFarm then
                _G.MM2_StartCoinFarm()
            else
                _G.MM2_CoinBlacklist = {}
                CachedCoinContainer = nil
                CurrentFarmStatus = "Запуск фарма..."
            end
            if showNotification then
                showNotification("🪙 COIN AUTO-FARM", "Авто-фарм и функции скрытности АКТИВИРОВАНЫ!", Color3.fromRGB(50, 220, 100), "🚀", 2.5)
            end
        else
            if _G.MM2_StopCoinFarm then
                _G.MM2_StopCoinFarm()
            end
            -- If in lobby, immediately return player to the lobby spawn floor!
            if isPlayerInLobby(LocalPlayer) and _G.MM2_ReturnToLobbyFloor then
                _G.MM2_ReturnToLobbyFloor()
            end
            if showNotification then
                showNotification("🛑 COIN AUTO-FARM", "Авто-фарм и функции скрытности ВЫКЛЮЧЕНЫ. Физика восстановлена!", Color3.fromRGB(255, 75, 75), "🛑", 2.5)
            end
        end
    end)

    local mBtn = nil
    mBtn = createButton(TabFarm, (Config.CoinFarmMethod == "Teleport") and "⚡ Режим: TELEPORT (Мгновенный с КД)" or "🚀 Режим: TWEEN (Настоящий полёт)", Color3.fromRGB(32, 38, 54), function()
        if Config.CoinFarmMethod == "Teleport" then
            Config.CoinFarmMethod = "Tween"
            mBtn.Text = "🚀 Режим: TWEEN (Настоящий полёт)"
            showNotification("🪙 РЕЖИМ ФАРМА", "Включен настоящий физический Tween (с репликацией)", Color3.fromRGB(45, 140, 255), "🚀", 2.5)
        else
            Config.CoinFarmMethod = "Teleport"
            mBtn.Text = "⚡ Режим: TELEPORT (Мгновенный с КД)"
            showNotification("🪙 РЕЖИМ ФАРМА", "Включен мгновенный телепорт с задержкой (КД)", Color3.fromRGB(255, 205, 30), "⚡", 2.5)
        end
        saveConfig()
    end)

    createSlider(TabFarm, "⚡ Задержка телепорта (Cooldown)", 1, 20, "CoinTeleportCooldownScaled", "%.2f сек", function(v)
        Config.CoinTeleportCooldown = math.clamp(v / 20, 0.02, 1.5)
        saveConfig()
    end)
    createSlider(TabFarm, "🚀 Фиксированная скорость (Tween Speed)", 10, 100, "CoinTweenSpeed", "%d studs/s")

    createSectionHeader(TabFarm, "🧲 COIN & CANDY AURA (МАГНИТ 2–7 STUDS)")
    createToggle(TabFarm, "🧲 Coin & Candy Aura (Авто-сбор монет и конфет)", "CoinAura")
    createSlider(TabFarm, "Радиус Aura (2–7 studs)", 2, 7, "CoinAuraRadius", "%d studs", function(v)
        Config.CoinAuraRadius = math.clamp(v, 2, 7)
        saveConfig()
    end)

    createSectionHeader(TabFarm, "⛏️ НАСТРОЙКИ СКРЫТНОСТИ И БЕЗОПАСНОСТИ")
    createToggle(TabFarm, "🛡️ Фарм строго под землёй (Анти-Мардер)", "CoinFarmUnderground", function(enabled)
        if enabled then
            showNotification("🛡️ SAFE UNDERGROUND", "Фарм строго под землёй включен! Мардер не достанет ножом.", Color3.fromRGB(80, 255, 140), "🛡️", 2.5)
        end
    end)
    createSlider(TabFarm, "📏 Смещение по высоте (Y Offset)", -10, 5, "CoinFarmYOffset", "%.1f studs")
    createToggle(TabFarm, "🚨 Уклонение от Мардера (Пропуск опасных монет)", "CoinFarmAvoidMurderer")
    createToggle(TabFarm, "🛌 Фармить лёжа (Prone Mode)", "CoinFarmProne")
    createToggle(TabFarm, "🙈 Прятаться под лобби в ожидании раунда", "CoinLobbyHide", function(enabled)
        if enabled then
            if isPlayerInLobby(LocalPlayer) and _G.MM2_TeleportUnderLobby then
                _G.MM2_TeleportUnderLobby()
            end
        else
            if isPlayerInLobby(LocalPlayer) and _G.MM2_ReturnToLobbyFloor then
                _G.MM2_ReturnToLobbyFloor()
            end
        end
    end)
    createToggle(TabFarm, "🏃 Смена сервера если мало игроков (<= 3)", "AutoServerHopLowPlayers")
    createToggle(TabFarm, "⚠️ Авто-смена зависшего сервера (Зависшая катка)", "AutoHopBrokenServer")
    createSlider(TabFarm, "⏱️ Макс. ожидание катки в лобби", 30, 120, "BrokenServerTimeout", "%d сек")
    createButton(TabFarm, "🔄 Сменить сервер прямо сейчас (Server Hop)", Color3.fromRGB(45, 140, 255), function()
        if serverHop then serverHop() end
    end)

    local postActionBtn = nil
    local function getPostActionTitle()
        if Config.CoinPostAction == "Afk" then
            return "🎯 Действие после лимита: 🛡️ AFK (Под картой)"
        elseif Config.CoinPostAction == "KillAll_Or_Shoot" then
            return "🎯 Действие после лимита: ⚔️ Kill All / Shoot / Fling"
        else
            return "🎯 Действие после лимита: 💀 Reset (Респавн)"
        end
    end
    postActionBtn = createButton(TabFarm, getPostActionTitle(), Color3.fromRGB(36, 44, 62), function()
        if Config.CoinPostAction == "Reset" then
            Config.CoinPostAction = "Afk"
        elseif Config.CoinPostAction == "Afk" then
            Config.CoinPostAction = "KillAll_Or_Shoot"
        else
            Config.CoinPostAction = "Reset"
        end
        postActionBtn.Text = getPostActionTitle()
        saveConfig()
        showNotification("🎯 ДЕЙСТВИЕ ПОСЛЕ ЛИМИТА", getPostActionTitle(), Color3.fromRGB(255, 205, 30), "💰", 3)
    end)
    createSlider(TabFarm, "Лимит монет для действия", 10, 50, "MaxCoins", "%d монет")

    createSectionHeader(TabFarm, "⭐ PRESTIGE (АВТО-ПРЕСТИЖ)")
    createToggle(TabFarm, "⭐ Auto-Prestige (Авто-престиж при уровне 100)", "AutoPrestige")
    createButton(TabFarm, "⭐ Выполнить Prestige прямо сейчас", Color3.fromRGB(255, 205, 30), function()
        if _G.MM2_PerformPrestigeNow then _G.MM2_PerformPrestigeNow() end
    end)

    createSectionHeader(TabFarm, "🎃 ХЭЛЛОУИН ПАСС (AUTO BUY TIER 600 CANDIES)")
    createToggle(TabFarm, "🎃 Авто-покупка пропуска за 600 конфет (Auto Skip Tier)", "AutoBuyPassTiers", function(on)
        Config.AutoBuyPassTiers = on
        saveConfig()
        if on and _G.MM2_BuyBattlePassTiers then
            _G.MM2_BuyBattlePassTiers(1)
        end
        if showNotification then
            showNotification("🎃 BATTLE PASS", on and "Авто-покупка уровней за 600 конфет включена!" or "Авто-покупка выключена", on and Color3.fromRGB(255, 170, 40) or Color3.fromRGB(200, 70, 70), "🎃", 3)
        end
    end)
    createToggle(TabFarm, "🎁 Auto Claim Pass (Авто-забор наград Пасса)", "AutoClaimPass")
    createButton(TabFarm, "🛒 Купить 1 уровень Пасса сейчас (600 конфет)", Color3.fromRGB(255, 140, 30), function()
        if _G.MM2_BuyBattlePassTiers then
            local bought, reason = _G.MM2_BuyBattlePassTiers(1)
            if bought and bought > 0 then
                showNotification("🎃 BATTLE PASS", "Уровень успешно куплен за 600 конфет!", Color3.fromRGB(60, 220, 100), "🎉", 4)
            elseif reason == "max_tier" then
                showNotification("🎃 BATTLE PASS", "Пасс уже прокачан на максимум (30/30)!", Color3.fromRGB(255, 200, 50), "⭐", 3)
            elseif reason == "not_enough_candies" then
                local cur = _G.MM2_GetCandyBalance and _G.MM2_GetCandyBalance() or 0
                showNotification("🎃 BATTLE PASS", string.format("Недостаточно конфет! У вас: %d / 600", cur), Color3.fromRGB(255, 90, 90), "⚠️", 3.5)
            end
        end
    end)
    createButton(TabFarm, "🚀 Купить ВСЕ доступные уровни Пасса", Color3.fromRGB(210, 100, 25), function()
        if _G.MM2_BuyBattlePassTiers then
            local cur = _G.MM2_GetCandyBalance and _G.MM2_GetCandyBalance() or 0
            local maxAffordable = math.floor(cur / 600)
            if maxAffordable <= 0 then
                showNotification("🎃 BATTLE PASS", string.format("Недостаточно конфет! У вас: %d / 600", cur), Color3.fromRGB(255, 90, 90), "⚠️", 3.5)
                return
            end
            local bought, reason = _G.MM2_BuyBattlePassTiers(maxAffordable)
            if bought and bought > 0 then
                showNotification("🎃 BATTLE PASS", string.format("Успешно куплено %d уровней Пасса!", bought), Color3.fromRGB(60, 220, 100), "🎉", 4)
            end
        end
    end)
    createButton(TabFarm, "🎁 Забрать открытые награды прямо сейчас", Color3.fromRGB(255, 170, 40), function()
        if _G.MM2_ClaimBattlePassRewards then
            local count = _G.MM2_ClaimBattlePassRewards(true)
            if count and count > 0 then
                showNotification("🎁 AUTO PASS", string.format("Забрано %d наград Battle Pass!", count), Color3.fromRGB(60, 220, 100), "🎉", 4)
            else
                showNotification("🎁 AUTO PASS", "Все открытые награды Пасса уже забраны!", Color3.fromRGB(180, 190, 210), "ℹ️", 3)
            end
        end
    end)
end

createSectionHeader(TabFarm, "🏗️ БЕЗОПАСНАЯ ПОДЗЕМНАЯ ПЛАТФОРМА")
createToggle(TabFarm, "🏗️ Спавн на платформе (-40 studs под ареной)", "CoinUndergroundPlatform")
createButton(TabFarm, "📍 Телепорт на подземную платформу", Color3.fromRGB(45, 140, 255), function()
    local root = getLocalRoot()
    if not root then return end
    hideSafelyUnderground()
    if showNotification then
        showNotification("🛡️ ПОД КАРТУ", "Вы телепортированы на защитную подземную платформу!", Color3.fromRGB(80, 255, 140), "🏗️", 2.5)
    end
end)

createSectionHeader(TabFarm, "🛡️ ЗАЩИТА ОТ ПАДЕНИЯ (ANTI-VOID)")
createToggle(TabFarm, "🛡️ Anti-Void (Защита от бездны)", "CoinAntiVoid")
createButton(TabFarm, "♻️ Ручной респавн персонажа", Color3.fromRGB(235, 75, 75), function()
    local char = LocalPlayer.Character
    if char then
        pcall(function() char:BreakJoints() end)
    end
end)

-- 🏃 Movement & Misc Tab
createSectionHeader(TabMisc, "🛡️ ЗАЩИТА И ПЕРЕДВИЖЕНИЕ")
createToggle(TabMisc, "🛡️ Anti-Fling (Ghost Mode)", "AntiFling")

local function applySpeed(val)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = Config.SpeedHack and val or 16 end
end

createToggle(TabMisc, "⚡ WalkSpeed Boost", "SpeedHack", function(on) applySpeed(Config.WalkSpeed) end)
createSlider(TabMisc, "WalkSpeed Value", 16, 60, "WalkSpeed", "%d studs/s", function(val)
    if Config.SpeedHack then applySpeed(val) end
end)
createToggle(TabMisc, "🦘 Infinite Jump", "InfiniteJump")
createToggle(TabMisc, "👻 Noclip (Walk through walls)", "Noclip")
createToggle(TabMisc, "🕊️ Fly Mode (WASD + Space/Shift)", "Fly")
createSlider(TabMisc, "Fly Speed", 15, 60, "FlySpeed", "%d studs/s")

createToggle(TabMisc, "🛡️ Anti-AFK (Защита от кика за простой)", "AntiAFK")

createSectionHeader(TabMisc, "📍 ТЕЛЕПОРТАЦИЯ")
createButton(TabMisc, "🏛️ Teleport to Lobby", Color3.fromRGB(70, 80, 105), function()
    if Config.CoinLobbyHide and _G.MM2_TeleportUnderLobby then
        _G.MM2_TeleportUnderLobby()
    else
        local lobby = workspace:FindFirstChild("RegularLobby") or workspace:FindFirstChild("Lobby")
        local root = getLocalRoot()
        if lobby and root then
            local spawnPart = lobby:FindFirstChildWhichIsA("SpawnLocation", true) or lobby:FindFirstChildWhichIsA("BasePart", true)
            if spawnPart then root.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0) end
        end
    end
end)

createButton(TabMisc, "🗺️ Teleport to Map Spawns", Color3.fromRGB(70, 80, 105), function()
    local map = getCurrentMap()
    local root = getLocalRoot()
    if map and root then
        local spawns = map:FindFirstChild("Spawns")
        local spawnPart = spawns and spawns:FindFirstChildWhichIsA("BasePart") or map:FindFirstChildWhichIsA("BasePart")
        if spawnPart then root.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0) end
    end
end)

-- 🎨 PERSONALIZATION & THEMES TAB
createSectionHeader(TabPersonalize, "🎨 ТЕМЫ ОФОРМЛЕНИЯ HUB")
createButton(TabPersonalize, "🔴 Ruby Red (Default Crimson)", Color3.fromRGB(235, 50, 75), function()
    applyUITheme("Red")
    showNotification("🎨 THEME APPLIED", "Switched to Ruby Red theme!", Color3.fromRGB(235, 50, 75), "🔴", 2.5)
end)
createButton(TabPersonalize, "🔵 Cyber Blue (Neon Cyan)", Color3.fromRGB(45, 140, 255), function()
    applyUITheme("Blue")
    showNotification("🎨 THEME APPLIED", "Switched to Cyber Blue theme!", Color3.fromRGB(45, 140, 255), "🔵", 2.5)
end)
createButton(TabPersonalize, "🟣 Neon Violet (Royal Amethyst)", Color3.fromRGB(165, 60, 245), function()
    applyUITheme("Purple")
    showNotification("🎨 THEME APPLIED", "Switched to Neon Violet theme!", Color3.fromRGB(165, 60, 245), "🟣", 2.5)
end)
createButton(TabPersonalize, "🟢 Emerald Green (Matrix Jade)", Color3.fromRGB(45, 215, 105), function()
    applyUITheme("Green")
    showNotification("🎨 THEME APPLIED", "Switched to Emerald Green theme!", Color3.fromRGB(45, 215, 105), "🟢", 2.5)
end)
createButton(TabPersonalize, "🟡 Cyber Gold (Solar Flare)", Color3.fromRGB(255, 205, 35), function()
    applyUITheme("Gold")
    showNotification("🎨 THEME APPLIED", "Switched to Cyber Gold theme!", Color3.fromRGB(255, 205, 35), "🟡", 2.5)
end)
createButton(TabPersonalize, "🌅 Sunset Orange (Vibrant Coral)", Color3.fromRGB(255, 95, 45), function()
    applyUITheme("Sunset")
    showNotification("🎨 THEME APPLIED", "Switched to Sunset Orange theme!", Color3.fromRGB(255, 95, 45), "🌅", 2.5)
end)
createButton(TabPersonalize, "⚪ Stealth Silver (Minimal Monolith)", Color3.fromRGB(160, 175, 195), function()
    applyUITheme("Silver")
    showNotification("🎨 THEME APPLIED", "Switched to Stealth Silver theme!", Color3.fromRGB(160, 175, 195), "⚪", 2.5)
end)

createSectionHeader(TabPersonalize, "🌈 ВЫБОР СВОЕГО ЦВЕТА (CUSTOM COLOR)")
createSlider(TabPersonalize, "Красный (Red R)", 0, 255, "CustomColorR", "%d", function(r)
    applyCustomColor(r, Config.CustomColorG or 45, Config.CustomColorB or 85)
end)
createSlider(TabPersonalize, "Зелёный (Green G)", 0, 255, "CustomColorG", "%d", function(g)
    applyCustomColor(Config.CustomColorR or 255, g, Config.CustomColorB or 85)
end)
createSlider(TabPersonalize, "Синий (Blue B)", 0, 255, "CustomColorB", "%d", function(b)
    applyCustomColor(Config.CustomColorR or 255, Config.CustomColorG or 45, b)
end)
createButton(TabPersonalize, "✨ Применить кастомный цвет (Apply)", Color3.fromRGB(255, 55, 110), function()
    applyCustomColor(Config.CustomColorR or 255, Config.CustomColorG or 45, Config.CustomColorB or 85)
    showNotification("🎨 CUSTOM COLOR", string.format("Кастомный цвет RGB (%d, %d, %d) активирован!", Config.CustomColorR or 255, Config.CustomColorG or 45, Config.CustomColorB or 85), Color3.fromRGB(Config.CustomColorR or 255, Config.CustomColorG or 45, Config.CustomColorB or 85), "🌈", 3)
end)

createSectionHeader(TabPersonalize, "✨ НАСТРОЙКИ ИНТЕРФЕЙСА")
createSlider(TabPersonalize, "UI Glass Transparency", 0, 60, "UIGlassTransparencyPct", "%d%%", function(val)
    Config.UIGlassTransparency = val / 100
    if MainFrame then
        MainFrame.BackgroundTransparency = Config.UIGlassTransparency
    end
end)

createToggle(TabPersonalize, "🔊 UI Click Sound Effects", "UISounds")
createToggle(TabPersonalize, "👋 Show Welcome Screen on Launch", "ShowWelcome")
createButton(TabPersonalize, "🎬 Preview Intro Splash Animation", Color3.fromRGB(60, 80, 120), function()
    if _G.MM2_ShowSplashIntro then
        _G.MM2_ShowSplashIntro(function()
            if showWelcomeModal then showWelcomeModal() end
        end)
    end
end)
createButton(TabPersonalize, "👋 Preview Welcome Screen Only", Color3.fromRGB(70, 90, 130), function()
    if showWelcomeModal then
        showWelcomeModal()
    end
end)

createSectionHeader(TabPersonalize, "📁 РАСПОЛОЖЕНИЕ ВКЛАДОК (TAB POSITION)")
_G.MM2_GetTabPosLabel = function(p)
    if p == "Top" then return "⬆️ Сверху"
    elseif p == "Left" then return "⬅️ Слева"
    elseif p == "Right" then return "➡️ Справа"
    else return "⬇️ Снизу" end
end
_G.MM2_TabButtonsList = {}

do
    local b1 = createButton(TabPersonalize, "📁 Положение табов: " .. _G.MM2_GetTabPosLabel(Config.TabPosition), Color3.fromRGB(36, 44, 64), function()
        local cur = Config.TabPosition or "Bottom"
        local nextPos = "Bottom"
        if cur == "Bottom" then nextPos = "Top"
        elseif cur == "Top" then nextPos = "Left"
        elseif cur == "Left" then nextPos = "Right"
        elseif cur == "Right" then nextPos = "Bottom" end
        _G.MM2_ApplyTabPosition(nextPos)
        for _, btn in ipairs(_G.MM2_TabButtonsList) do
            btn.Text = "📁 Положение табов: " .. _G.MM2_GetTabPosLabel(nextPos)
        end
        if showNotification then
            showNotification("📁 ТАБЫ ПЕРЕМЕЩЕНЫ", "Новое расположение: " .. _G.MM2_GetTabPosLabel(nextPos), Color3.fromRGB(60, 200, 255), "📁", 2.5)
        end
    end)
    table.insert(_G.MM2_TabButtonsList, b1)
end

-- ⚙️ CONFIGS, KEYBINDS, NOTIFICATIONS & SERVER HOP TAB
createSectionHeader(TabSettings, "📁 ИНТЕРФЕЙС И РАСПОЛОЖЕНИЕ ТАБОВ")
do
    local b2 = createButton(TabSettings, "📁 Положение табов: " .. _G.MM2_GetTabPosLabel(Config.TabPosition), Color3.fromRGB(36, 44, 64), function()
        local cur = Config.TabPosition or "Bottom"
        local nextPos = "Bottom"
        if cur == "Bottom" then nextPos = "Top"
        elseif cur == "Top" then nextPos = "Left"
        elseif cur == "Left" then nextPos = "Right"
        elseif cur == "Right" then nextPos = "Bottom" end
        _G.MM2_ApplyTabPosition(nextPos)
        for _, btn in ipairs(_G.MM2_TabButtonsList) do
            btn.Text = "📁 Положение табов: " .. _G.MM2_GetTabPosLabel(nextPos)
        end
        if showNotification then
            showNotification("📁 ТАБЫ ПЕРЕМЕЩЕНЫ", "Новое расположение: " .. _G.MM2_GetTabPosLabel(nextPos), Color3.fromRGB(60, 200, 255), "📁", 2.5)
        end
    end)
    table.insert(_G.MM2_TabButtonsList, b2)
end
createToggle(TabSettings, "🛡️ Anti-AFK (Защита от 20-мин отключения)", "AntiAFK")
createToggle(TabSettings, "🔁 Авто-перезаход при кике (Reconnect MM2)", "AutoReconnectOnKick")
createToggle(TabSettings, "⚠️ Авто-смена зависшего сервера (Зависшая катка)", "AutoHopBrokenServer")
createSlider(TabSettings, "⏱️ Макс. ожидание катки в лобби", 30, 120, "BrokenServerTimeout", "%d сек")
createToggle(TabSettings, "🌐 Auto-Hop при 2-3 игроках (Pure Lua)", "AutoServerHopLowPlayers")
createToggle(TabSettings, "⚡ Disable 3D Render (Энергосбережение & 20 FPS) [F7]", "Disable3DRender", function(enabled)
    if _G.MM2_Set3DRenderEnabled then
        _G.MM2_Set3DRenderEnabled(not enabled)
    end
end)

createSectionHeader(TabSettings, "📁 УПРАВЛЕНИЕ КОНФИГУРАЦИЕЙ")
createToggle(TabSettings, "🔄 Auto-Load Config on Launch", "AutoLoadConfig")
createToggle(TabSettings, "💾 Auto-Save Config (Периодическое автосохранение)", "AutoSaveConfig")
createButton(TabSettings, "💾 Save Current Configuration", Color3.fromRGB(45, 140, 255), function()
    saveConfig()
    showNotification("💾 CONFIG SAVED", "Settings written to MM2_Hub_Config.json", Color3.fromRGB(50, 180, 255), "💾", 3)
end)
createButton(TabSettings, "📂 Reload Saved Configuration", Color3.fromRGB(60, 175, 120), function()
    if loadConfig() then
        applyUITheme(Config.UITheme)
        if MainFrame then MainFrame.BackgroundTransparency = Config.UIGlassTransparency or 0.12 end
        showNotification("📂 CONFIG LOADED", "Successfully restored configuration!", Color3.fromRGB(60, 200, 120), "📂", 3)
    else
        showNotification("⚠️ LOAD FAILED", "No config file found on device.", Color3.fromRGB(255, 180, 50), "⚠️", 3)
    end
end)
createButton(TabSettings, "♻️ Reset to Factory Defaults", Color3.fromRGB(235, 75, 75), function()
    resetConfig()
end)

createSectionHeader(TabSettings, "📱 МОБИЛЬНЫЕ УСТРОЙСТВА (MOBILE SUPPORT)")
createToggle(TabSettings, "🔘 Плавающая кнопка меню (Mobile Toggle Button)", "MobileFloatingButton", function(on)
    Config.MobileFloatingButton = on
    saveConfig()
    if _G.MM2_UpdateMobileButton then _G.MM2_UpdateMobileButton(on) end
end)
createToggle(TabSettings, "📱 Авто-масштаб под экран телефона (Auto-Scale)", "MobileAutoScaling", function(on)
    Config.MobileAutoScaling = on
    saveConfig()
    if _G.MM2_UpdateMobileScaling then _G.MM2_UpdateMobileScaling() end
end)
createToggle(TabSettings, "🎮 Мобильные кнопки действий (Action HUD)", "MobileActionHUD", function(on)
    Config.MobileActionHUD = on
    saveConfig()
    if _G.MM2_UpdateMobileActionHUD then _G.MM2_UpdateMobileActionHUD(on) end
end)
createSlider(TabSettings, "📏 Размер плавающей кнопки", 36, 68, "MobileButtonSize", "%d px", function(v)
    Config.MobileButtonSize = v
    saveConfig()
    if _G.MM2_UpdateMobileButton then _G.MM2_UpdateMobileButton(true) end
end)
createSlider(TabSettings, "👁️ Прозрачность плавающей кнопки", 0, 80, "MobileButtonTransparencyPct", "%d%%", function(v)
    Config.MobileButtonTransparencyPct = v
    Config.MobileButtonTransparency = v / 100
    saveConfig()
    if _G.MM2_UpdateMobileButton then _G.MM2_UpdateMobileButton(true) end
end)
createButton(TabSettings, "🔄 Сбросить позицию кнопки меню", Color3.fromRGB(45, 120, 200), function()
    Config.MobileButtonPosX = 20
    Config.MobileButtonPosY = 140
    saveConfig()
    if _G.MM2_ResetMobileButtonPos then _G.MM2_ResetMobileButtonPos() end
    if showNotification then
        showNotification("📱 МОБИЛЬНАЯ КНОПКА", "Позиция сброшена на стандартную (20, 140)", Color3.fromRGB(45, 180, 255), "🔄", 2)
    end
end)

createSectionHeader(TabSettings, "⌨️ НАЗНАЧЕНИЕ КЛАВИШ (БИНДЫ)")
createKeybindButton(TabSettings, "📋 Toggle Hub Menu GUI", "MenuKeybind", {"RightShift", "Insert", "F4", "RightAlt"})
createKeybindButton(TabSettings, "🎯 Toggle Silent Aim", "SilentAimKeybind", {"None", "Z", "X", "C", "Q", "F"})
createKeybindButton(TabSettings, "💥 Toggle Auto-Shoot Murderer", "AutoShotKeybind", {"None", "Q", "Z", "X", "C", "F"})
createKeybindButton(TabSettings, "💥 Instant Shoot Murderer", "InstantShootKeybind", {"E", "Q", "F", "X", "C", "Z", "V", "R", "None"})
createKeybindButton(TabSettings, "🗡️ Murderer Long-Range Strike", "KnifeReachKeybind", {"F", "E", "Q", "X", "C", "Z", "V", "R", "None"})
createKeybindButton(TabSettings, "🎯 Murderer Knife Throw", "KnifeThrowKeybind", {"E", "Q", "T", "R", "F", "None"})

createSectionHeader(TabSettings, "🔔 ОПОВЕЩЕНИЯ И УВЕДОМЛЕНИЯ")
createToggle(TabSettings, "🔔 Smart Event Notifications", "EventNotifications")
createToggle(TabSettings, "🔊 Sound Chimes for Notifications", "NotificationSounds")
createButton(TabSettings, "⭐ Тест: Оповещение выпадения пистолета", Color3.fromRGB(240, 160, 30), function()
    showNotification("⚠️ РЕВОЛЬВЕР ВЫПАЛ!", "Шериф погиб! Пистолет лежит на карте — подберите его!", Color3.fromRGB(255, 215, 0), "⭐", 5)
end)
createButton(TabSettings, "💀 Тест: Оповещение мардера", Color3.fromRGB(255, 60, 80), function()
    showNotification("💀 МАРДЕР ОБНАРУЖЕН!", "Опасность! Мардер достал оружие!", Color3.fromRGB(255, 45, 60), "💀", 5)
end)

createSectionHeader(TabSettings, "🌐 MM2 SERVER HOP & AUTO-RECONNECT")
createToggle(TabSettings, "🔄 Auto-Reinject Script on Teleport / Hop", "AutoQueueOnTeleport")
createSlider(TabSettings, "⏳ Задержка авто-инжекта после ТП", 2, 15, "TeleportInjectDelay", "%d сек", function(v)
    Config.TeleportInjectDelay = v
    saveConfig()
end)
createToggle(TabSettings, "🛡️ Auto-Reconnect on Kick / Disconnect", "AutoReconnectOnKick")
createSlider(TabSettings, "⏱️ Задержка перед авто-перезаходом", 3, 30, "AutoReconnectDelay", "%d сек", function(v)
    Config.AutoReconnectDelay = v
    saveConfig()
end)
createToggle(TabSettings, "🏃 Auto-Hop if Low Players (<= 3 чел)", "AutoServerHopLowPlayers")
createSlider(TabSettings, "👥 Мин. игроков для авто-хопа", 1, 6, "MinServerPlayers", "%d чел")
createButton(TabSettings, "⚡ Найти быстрый сервер по пингу (Server Hop)", Color3.fromRGB(45, 140, 255), function()
    serverHop()
end)
createButton(TabSettings, "🔄 Умный перезаход на НОВЫЙ сервер (Smart Rejoin)", Color3.fromRGB(50, 190, 120), function()
    rejoinServer()
end)
createButton(TabSettings, "🔁 Перезаход на ТОТ ЖЕ сервер (Exact Same Server)", Color3.fromRGB(80, 100, 145), function()
    rejoinSameServer()
end)

createSectionHeader(TabSettings, "🛑 ВЫГРУЗКА СКРИПТА (UNLOAD)")
createButton(TabSettings, "🚪 Полный Unload скрипта (Удалить все ESP, UI и хуки)", Color3.fromRGB(235, 50, 65), function()
    if _G.MM2_Hub_Cleanup then
        _G.MM2_Hub_Cleanup()
    end
end)

-- ====================================================================
-- 📱 TAB: MOBILE & TOUCH SETTINGS
-- ====================================================================
do
    local function initMobileTab()
        local parentTab = _G.TabMobile

        -- 📱 SECTION 1: WINDOW SCALE & SIZE
        createSectionHeader(parentTab, "📱 РАЗМЕР ОКНА (UI SCALE)")
        createSlider(parentTab, "🔍 Масштаб меню (UI Scale)", 40, 100, "MobileUIScalePct", "%d%%", function(val)
            Config.MobileUIScalePct = val
            saveConfig()
            if _G.MM2_UpdateMobileScaling then
                _G.MM2_UpdateMobileScaling()
            end
        end)

        createToggle(parentTab, "📐 Авто-адаптация под экран (Auto-Scale)", "MobileAutoScaling", function(on)
            Config.MobileAutoScaling = on
            saveConfig()
            if _G.MM2_UpdateMobileScaling then
                _G.MM2_UpdateMobileScaling()
            end
        end)

        createButton(parentTab, "🔄 Сбросить масштаб меню к 65%", Color3.fromRGB(45, 120, 220), function()
            Config.MobileUIScalePct = 65
            saveConfig()
            if _G.MM2_UpdateMobileScaling then
                _G.MM2_UpdateMobileScaling()
            end
            showNotification("📱 UI SCALE", "Масштаб меню сброшен на 65%!", Color3.fromRGB(60, 200, 255), "📱", 2.5)
        end)

        -- 🔘 SECTION 2: FLOATING MENU BUTTON
        createSectionHeader(parentTab, "🔘 КНОПКА ОТКРЫТИЯ МЕНЮ (FLOATING TOGGLE)")
        createToggle(parentTab, "🔘 Показывать плавающую кнопку меню", "MobileFloatingButton", function(on)
            Config.MobileFloatingButton = on
            saveConfig()
            if _G.MM2_UpdateMobileButton then
                _G.MM2_UpdateMobileButton(on)
            end
        end)

        createSlider(parentTab, "Размер кнопки меню", 34, 68, "MobileButtonSize", "%d px", function(val)
            Config.MobileButtonSize = val
            saveConfig()
            if _G.MM2_UpdateMobileButton then
                _G.MM2_UpdateMobileButton()
            end
        end)

        createSlider(parentTab, "Прозрачность кнопки меню", 0, 80, "MobileButtonTransparencyPct", "%d%%", function(val)
            Config.MobileButtonTransparencyPct = val
            Config.MobileButtonTransparency = val / 100
            saveConfig()
            if _G.MM2_UpdateMobileButton then
                _G.MM2_UpdateMobileButton()
            end
        end)

        createButton(parentTab, "🔄 Сбросить позицию кнопки меню", Color3.fromRGB(50, 65, 90), function()
            if _G.MM2_ResetMobileButtonPos then
                _G.MM2_ResetMobileButtonPos()
            end
            showNotification("🔘 MOBILE BUTTON", "Позиция кнопки меню сброшена!", Color3.fromRGB(60, 200, 255), "🔘", 2.0)
        end)

        createToggle(parentTab, "🏝️ Открывать меню по нажатию на Dynamic Island", "MobileIslandClickToggle", function(on)
            Config.MobileIslandClickToggle = on
            saveConfig()
            if _G.MM2_UpdateIslandInteractivity then
                _G.MM2_UpdateIslandInteractivity()
            end
        end)

        -- 🎮 SECTION 3: ACTION HUD (DRAGGABLE BUTTONS WITH TEXT)
        createSectionHeader(parentTab, "🎮 НАЭКРАННЫЕ КНОПКИ (ACTION HUD)")
        createToggle(parentTab, "🎮 Включить экранные кнопки (Action HUD)", "MobileActionHUD", function(on)
            Config.MobileActionHUD = on
            saveConfig()
            if _G.MM2_UpdateMobileActionHUD then
                _G.MM2_UpdateMobileActionHUD()
            end
        end)

        createToggle(parentTab, "🔒 Зафиксировать кнопки (Защита от сдвига)", "MobileLockButtons", function(on)
            Config.MobileLockButtons = on
            saveConfig()
            showNotification("🔒 HUD LOCK", on and "Кнопки зафиксированы!" or "Кнопки можно перетаскивать!", on and Color3.fromRGB(240, 180, 50) or Color3.fromRGB(60, 220, 120), "🔒", 2.0)
        end)

        createToggle(parentTab, "Кнопка '🔫 ВЫСТРЕЛ' (Shoot)", "MobileShootBtnEnabled", function(on)
            Config.MobileShootBtnEnabled = on
            saveConfig()
            if _G.MM2_UpdateMobileActionHUD then _G.MM2_UpdateMobileActionHUD() end
        end)

        createToggle(parentTab, "Кнопка '🗡️ НОЖ' (Knife Aura)", "MobileKnifeBtnEnabled", function(on)
            Config.MobileKnifeBtnEnabled = on
            saveConfig()
            if _G.MM2_UpdateMobileActionHUD then _G.MM2_UpdateMobileActionHUD() end
        end)

        createToggle(parentTab, "Кнопка '🪙 ФАРМ' (Toggle Farm)", "MobileFarmBtnEnabled", function(on)
            Config.MobileFarmBtnEnabled = on
            saveConfig()
            if _G.MM2_UpdateMobileActionHUD then _G.MM2_UpdateMobileActionHUD() end
        end)

        createSlider(parentTab, "Ширина кнопок HUD", 65, 125, "MobileHudBtnWidth", "%d px", function(val)
            Config.MobileHudBtnWidth = val
            saveConfig()
            if _G.MM2_UpdateMobileActionHUD then _G.MM2_UpdateMobileActionHUD() end
        end)

        createSlider(parentTab, "Высота кнопок HUD", 26, 48, "MobileHudBtnHeight", "%d px", function(val)
            Config.MobileHudBtnHeight = val
            saveConfig()
            if _G.MM2_UpdateMobileActionHUD then _G.MM2_UpdateMobileActionHUD() end
        end)

        createSlider(parentTab, "Прозрачность кнопок HUD", 0, 80, "MobileHudTransparencyPct", "%d%%", function(val)
            Config.MobileHudTransparencyPct = val
            Config.MobileHudTransparency = val / 100
            saveConfig()
            if _G.MM2_UpdateMobileActionHUD then _G.MM2_UpdateMobileActionHUD() end
        end)

        createButton(parentTab, "🔄 Сбросить позиции кнопок HUD", Color3.fromRGB(215, 60, 75), function()
            if _G.MM2_ResetActionHudPos then
                _G.MM2_ResetActionHudPos()
            end
            showNotification("🎮 ACTION HUD", "Позиции экранных кнопок сброшены!", Color3.fromRGB(60, 200, 255), "🎮", 2.0)
        end)
    end
    initMobileTab()
end

-- ====================================================================
-- 📁 TAB: CONFIG MANAGER (PRESETS, CUSTOM PROFILES & CLOUD/CLIPBOARD)
-- ====================================================================
do
    local function initConfigsTab()
        local parentTab = _G.TabConfigs
    local C = {}
    C.selectedConfig = ""
    C.INDEX_FILE = "MM2_Configs_List.json"

    -- ⚡ SECTION 1: ONE-CLICK QUICK PRESETS
    createSectionHeader(parentTab, "⚡ БЫСТРЫЕ ПРЕСЕТЫ (ONE-CLICK PRESETS)")

    local function applyPreset(presetType)
        if presetType == "Rage" then
            Config.SilentAim = true
            Config.SilentAimWallBang = true
            Config.WallBangAllMap = true
            Config.WallCheck = false
            Config.AutoShot = true
            Config.AutoShotDelay = 0.4
            Config.InstantShootKeybind = "E"
            Config.KnifeAura = true
            Config.KnifeAuraRadius = 40
            Config.KnifeAuraShowRadius = true
            Config.KnifeAuraWallCheck = false
            Config.KnifeReachEnabled = true
            Config.KnifeThrowEnabled = true
            Config.CoinAura = true
            Config.CoinAuraRadius = 4.2
            Config.SpeedHack = true
            Config.WalkSpeed = 26
            Config.MurdererESP = true
            Config.SheriffESP = true
            Config.InnocentESP = true
            saveConfig()
            if _G.MM2_RefreshAllUI then _G.MM2_RefreshAllUI() end
            showNotification("⚡ RAGE PRESET", "Full Rage Config loaded! Dominate the lobby.", Color3.fromRGB(255, 50, 70), "⚡", 3.5)
        elseif presetType == "Legit" then
            Config.SilentAim = true
            Config.SilentAimWallBang = false
            Config.WallBangAllMap = false
            Config.WallCheck = true
            Config.AutoShot = false
            Config.KnifeAura = true
            Config.KnifeAuraRadius = 14
            Config.KnifeAuraShowRadius = false
            Config.KnifeAuraWallCheck = true
            Config.KnifeReachEnabled = false
            Config.KnifeThrowEnabled = false
            Config.SpeedHack = false
            Config.WalkSpeed = 16
            Config.MurdererESP = true
            Config.SheriffESP = true
            Config.InnocentESP = false
            saveConfig()
            if _G.MM2_RefreshAllUI then _G.MM2_RefreshAllUI() end
            showNotification("🛡️ LEGIT PRESET", "Closet / Legit Config loaded! Safe for high-level accounts.", Color3.fromRGB(50, 220, 120), "🛡️", 3.5)
        elseif presetType == "SafeFarm" then
            Config.AutoCoinFarm = true
            Config.CoinFarmMode = "Cluster"
            Config.CoinTweenSpeed = 24
            Config.CoinAutoRespawn = true
            Config.CoinAntiVoid = true
            Config.CoinAura = true
            Config.CoinAuraRadius = 4.2
            Config.AntiAFK = true
            Config.AutoReconnect = true
            Config.AutoReconnectOnKick = true
            Config.AutoServerHopLowPlayers = true
            Config.Disable3DRender = true
            if _G.MM2_Set3DRenderEnabled then _G.MM2_Set3DRenderEnabled(false) end
            Config.SilentAim = false
            Config.AutoShot = false
            Config.KnifeAura = false
            saveConfig()
            if _G.MM2_RefreshAllUI then _G.MM2_RefreshAllUI() end
            showNotification("💰 SAFE FARM PRESET", "Zero-kick AFK Farm configured! 3D Render disabled.", Color3.fromRGB(255, 215, 0), "💰", 3.5)
        elseif presetType == "Default" then
            resetConfig()
        end
    end

    createButton(parentTab, "⚡ Rage MM2 (Silent Aim, Max Knife Aura & Speed)", Color3.fromRGB(255, 55, 75), function()
        applyPreset("Rage")
    end)

    createButton(parentTab, "🛡️ Legit / Closeting (Safe ESP, Wall Check & Aura 14s)", Color3.fromRGB(45, 180, 110), function()
        applyPreset("Legit")
    end)

    createButton(parentTab, "💰 Safe AFK Auto-Farm (Tween, Anti-AFK & Low 3D)", Color3.fromRGB(240, 175, 30), function()
        applyPreset("SafeFarm")
    end)

    createButton(parentTab, "🔄 Reset to Default Configuration", Color3.fromRGB(90, 105, 140), function()
        applyPreset("Default")
    end)

    -- 💾 SECTION 2: ADVANCED CONFIG MANAGER (SPLIT SIDEBAR & CONFIRMATION MODALS)
    createSectionHeader(parentTab, "💾 МЕНЕДЖЕР ПРОФИЛЕЙ (CONFIG MANAGER)")
    createToggle(parentTab, "🔄 Auto-Load Config on Hub Launch", "AutoLoadConfig")

    -- Modal confirmation window overlay attached to MainFrame
    local function showConfirmModal(opts)
        if not MainFrame then return end
        local old = MainFrame:FindFirstChild("ConfirmModalOverlay")
        if old then old:Destroy() end

        local overlay = Instance.new("TextButton")
        overlay.Name = "ConfirmModalOverlay"
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.Position = UDim2.new(0, 0, 0, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
        overlay.BackgroundTransparency = 0.35
        overlay.Text = ""
        overlay.AutoButtonColor = false
        overlay.ZIndex = 250
        overlay.Parent = MainFrame
        Instance.new("UICorner", overlay).CornerRadius = UDim.new(0, 10)

        local modal = Instance.new("Frame")
        modal.Name = "ModalWindow"
        modal.Size = UDim2.new(0, 340, 0, 175)
        modal.Position = UDim2.new(0.5, -170, 0.5, -87)
        modal.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
        modal.BorderSizePixel = 0
        modal.ZIndex = 251
        modal.Parent = overlay
        Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 10)

        local modalStroke = Instance.new("UIStroke")
        modalStroke.Color = opts.confirmColor or currentTheme.Main or Color3.fromRGB(60, 120, 240)
        modalStroke.Thickness = 1.5
        modalStroke.Transparency = 0.25
        modalStroke.Parent = modal

        local topBar = Instance.new("Frame")
        topBar.Size = UDim2.new(1, 0, 0, 32)
        topBar.BackgroundColor3 = Color3.fromRGB(24, 30, 44)
        topBar.BorderSizePixel = 0
        topBar.ZIndex = 252
        topBar.Parent = modal
        Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)

        local barFlat = Instance.new("Frame")
        barFlat.Size = UDim2.new(1, 0, 0, 8)
        barFlat.Position = UDim2.new(0, 0, 1, -8)
        barFlat.BackgroundColor3 = Color3.fromRGB(24, 30, 44)
        barFlat.BorderSizePixel = 0
        barFlat.ZIndex = 252
        barFlat.Parent = topBar

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -34, 1, 0)
        titleLbl.Position = UDim2.new(0, 12, 0, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 11
        titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Text = opts.title or "⚠️ Подтверждение"
        titleLbl.ZIndex = 253
        titleLbl.Parent = topBar

        local xClose = Instance.new("TextButton")
        xClose.Size = UDim2.new(0, 24, 0, 24)
        xClose.Position = UDim2.new(1, -28, 0.5, -12)
        xClose.BackgroundTransparency = 1
        xClose.Font = Enum.Font.GothamBold
        xClose.TextSize = 12
        xClose.TextColor3 = Color3.fromRGB(180, 195, 220)
        xClose.Text = "✕"
        xClose.ZIndex = 254
        xClose.Parent = topBar
        xClose.MouseButton1Click:Connect(function()
            overlay:Destroy()
        end)

        local msgLbl = Instance.new("TextLabel")
        msgLbl.Size = UDim2.new(1, -30, 0, 60)
        msgLbl.Position = UDim2.new(0, 15, 0, 40)
        msgLbl.BackgroundTransparency = 1
        msgLbl.Font = Enum.Font.GothamMedium
        msgLbl.TextSize = 11
        msgLbl.TextColor3 = Color3.fromRGB(230, 238, 250)
        msgLbl.TextWrapped = true
        msgLbl.TextYAlignment = Enum.TextYAlignment.Center
        msgLbl.Text = opts.desc or "Вы уверены, что хотите выполнить это действие?"
        msgLbl.ZIndex = 253
        msgLbl.Parent = modal

        local btnBox = Instance.new("Frame")
        btnBox.Size = UDim2.new(1, -28, 0, 34)
        btnBox.Position = UDim2.new(0, 14, 1, -46)
        btnBox.BackgroundTransparency = 1
        btnBox.ZIndex = 253
        btnBox.Parent = modal

        local cancelBtn = Instance.new("TextButton")
        cancelBtn.Size = UDim2.new(0.48, -4, 1, 0)
        cancelBtn.Position = UDim2.new(0, 0, 0, 0)
        cancelBtn.BackgroundColor3 = Color3.fromRGB(48, 56, 75)
        cancelBtn.Font = Enum.Font.GothamBold
        cancelBtn.TextSize = 10
        cancelBtn.TextColor3 = Color3.fromRGB(220, 230, 245)
        cancelBtn.Text = "✖ Отмена"
        cancelBtn.AutoButtonColor = true
        cancelBtn.ZIndex = 254
        cancelBtn.Parent = btnBox
        Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 6)
        cancelBtn.MouseButton1Click:Connect(function()
            overlay:Destroy()
        end)

        local confirmBtn = Instance.new("TextButton")
        confirmBtn.Size = UDim2.new(0.52, -4, 1, 0)
        confirmBtn.Position = UDim2.new(0.48, 8, 0, 0)
        confirmBtn.BackgroundColor3 = opts.confirmColor or Color3.fromRGB(45, 140, 255)
        confirmBtn.Font = Enum.Font.GothamBold
        confirmBtn.TextSize = 10
        confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        confirmBtn.Text = opts.confirmText or "✔ Подтвердить"
        confirmBtn.AutoButtonColor = true
        confirmBtn.ZIndex = 254
        confirmBtn.Parent = btnBox
        Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 6)
        confirmBtn.MouseButton1Click:Connect(function()
            overlay:Destroy()
            if opts.onConfirm then
                pcall(opts.onConfirm)
            end
        end)
    end

    local function getSavedList()
        local list = {}
        local seen = {}
        pcall(function()
            if isfile and isfile(C.INDEX_FILE) and readfile then
                local data = HttpService:JSONDecode(readfile(C.INDEX_FILE))
                if type(data) == "table" then
                    for _, n in ipairs(data) do
                        if type(n) == "string" and n ~= "" and not seen[n] then
                            seen[n] = true
                            table.insert(list, n)
                        end
                    end
                end
            end
        end)
        pcall(function()
            if listfiles then
                local files = listfiles("") or listfiles(".")
                for _, f in ipairs(files) do
                    local fn = tostring(f):match("MM2_Config_(.+)%.json$")
                    if fn and not seen[fn] then
                        seen[fn] = true
                        table.insert(list, fn)
                    end
                end
            end
        end)
        return list
    end

    local function saveList(list)
        pcall(function()
            if writefile then
                writefile(C.INDEX_FILE, HttpService:JSONEncode(list))
            end
        end)
    end

    local function saveConfigToFile(cfgName)
        local fileName = "MM2_Config_" .. cfgName .. ".json"
        local saved = false
        pcall(function()
            if writefile then
                writefile(fileName, HttpService:JSONEncode(Config))
                saved = true
            end
        end)
        if saved then
            local list = getSavedList()
            local exists = false
            for _, n in ipairs(list) do
                if n == cfgName then exists = true; break end
            end
            if not exists then
                table.insert(list, cfgName)
                saveList(list)
            end
        end
        return saved
    end

    -- Split View Container (Left = Configs Sidebar, Right = Controls & 4 Buttons)
    C.splitFrame = Instance.new("Frame")
    C.splitFrame.Size = UDim2.new(1, 0, 0, 245)
    C.splitFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 26)
    C.splitFrame.BackgroundTransparency = 0.25
    C.splitFrame.BorderSizePixel = 0
    C.splitFrame.Parent = parentTab
    Instance.new("UICorner", C.splitFrame).CornerRadius = UDim.new(0, 8)

    local splitStroke = Instance.new("UIStroke")
    splitStroke.Color = Color3.fromRGB(36, 44, 62)
    splitStroke.Thickness = 1
    splitStroke.Transparency = 0.35
    splitStroke.Parent = C.splitFrame

    -- Left Column: Configs Sidebar
    C.leftFrame = Instance.new("Frame")
    C.leftFrame.Size = UDim2.new(0.42, 0, 1, -12)
    C.leftFrame.Position = UDim2.new(0, 6, 0, 6)
    C.leftFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
    C.leftFrame.BorderSizePixel = 0
    C.leftFrame.Parent = C.splitFrame
    Instance.new("UICorner", C.leftFrame).CornerRadius = UDim.new(0, 7)

    local leftStroke = Instance.new("UIStroke")
    leftStroke.Color = Color3.fromRGB(34, 42, 60)
    leftStroke.Thickness = 1
    leftStroke.Transparency = 0.4
    leftStroke.Parent = C.leftFrame

    local leftTopBar = Instance.new("Frame")
    leftTopBar.Size = UDim2.new(1, 0, 0, 28)
    leftTopBar.BackgroundTransparency = 1
    leftTopBar.Parent = C.leftFrame

    local leftTitle = Instance.new("TextLabel")
    leftTitle.Size = UDim2.new(1, -30, 1, 0)
    leftTitle.Position = UDim2.new(0, 8, 0, 0)
    leftTitle.BackgroundTransparency = 1
    leftTitle.Font = Enum.Font.GothamBold
    leftTitle.TextSize = 10
    leftTitle.TextColor3 = Color3.fromRGB(195, 210, 240)
    leftTitle.TextXAlignment = Enum.TextXAlignment.Left
    leftTitle.Text = "📁 СПИСОК КОНФИГОВ"
    leftTitle.Parent = leftTopBar

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0, 20, 0, 20)
    refreshBtn.Position = UDim2.new(1, -24, 0.5, -10)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(28, 36, 52)
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 10
    refreshBtn.TextColor3 = Color3.fromRGB(200, 220, 255)
    refreshBtn.Text = "🔄"
    refreshBtn.AutoButtonColor = true
    refreshBtn.Parent = leftTopBar
    Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 5)

    C.listScroll = Instance.new("ScrollingFrame")
    C.listScroll.Size = UDim2.new(1, -8, 1, -34)
    C.listScroll.Position = UDim2.new(0, 4, 0, 30)
    C.listScroll.BackgroundTransparency = 1
    C.listScroll.BorderSizePixel = 0
    C.listScroll.ScrollBarThickness = 3
    C.listScroll.ScrollBarImageColor3 = currentTheme.Main or Color3.fromRGB(60, 140, 255)
    C.listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    C.listScroll.Parent = C.leftFrame

    C.listLayout = Instance.new("UIListLayout")
    C.listLayout.Padding = UDim.new(0, 4)
    C.listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    C.listLayout.Parent = C.listScroll

    C.listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        C.listScroll.CanvasSize = UDim2.new(0, 0, 0, C.listLayout.AbsoluteContentSize.Y + 4)
    end)

    -- Right Column: Controls, Input & 4 Buttons
    C.rightFrame = Instance.new("Frame")
    C.rightFrame.Size = UDim2.new(0.58, -12, 1, -12)
    C.rightFrame.Position = UDim2.new(0.42, 6, 0, 6)
    C.rightFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
    C.rightFrame.BorderSizePixel = 0
    C.rightFrame.Parent = C.splitFrame
    Instance.new("UICorner", C.rightFrame).CornerRadius = UDim.new(0, 7)

    local rightStroke = Instance.new("UIStroke")
    rightStroke.Color = Color3.fromRGB(34, 42, 60)
    rightStroke.Thickness = 1
    rightStroke.Transparency = 0.4
    rightStroke.Parent = C.rightFrame

    C.statusLabel = Instance.new("TextLabel")
    C.statusLabel.Size = UDim2.new(1, -16, 0, 22)
    C.statusLabel.Position = UDim2.new(0, 8, 0, 6)
    C.statusLabel.BackgroundTransparency = 1
    C.statusLabel.Font = Enum.Font.GothamBold
    C.statusLabel.TextSize = 10
    C.statusLabel.TextColor3 = currentTheme.Main or Color3.fromRGB(70, 160, 255)
    C.statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    C.statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
    C.statusLabel.Text = "⚙️ ВЫБРАН: (не выбран)"
    C.statusLabel.Parent = C.rightFrame

    local function updateStatus()
        if C.selectedConfig and C.selectedConfig ~= "" then
            C.statusLabel.Text = "⚙️ ВЫБРАН: " .. C.selectedConfig
            C.statusLabel.TextColor3 = currentTheme.Main or Color3.fromRGB(70, 160, 255)
        else
            C.statusLabel.Text = "⚙️ ВЫБРАН: (не выбран)"
            C.statusLabel.TextColor3 = Color3.fromRGB(140, 160, 195)
        end
    end

    local inputCard = Instance.new("Frame")
    inputCard.Size = UDim2.new(1, -16, 0, 32)
    inputCard.Position = UDim2.new(0, 8, 0, 30)
    inputCard.BackgroundColor3 = Color3.fromRGB(24, 30, 44)
    inputCard.BorderSizePixel = 0
    inputCard.Parent = C.rightFrame
    Instance.new("UICorner", inputCard).CornerRadius = UDim.new(0, 6)

    local inputCardStroke = Instance.new("UIStroke")
    inputCardStroke.Color = Color3.fromRGB(48, 60, 88)
    inputCardStroke.Thickness = 1
    inputCardStroke.Transparency = 0.35
    inputCardStroke.Parent = inputCard

    local inputIcon = Instance.new("TextLabel")
    inputIcon.Size = UDim2.new(0, 24, 1, 0)
    inputIcon.Position = UDim2.new(0, 4, 0, 0)
    inputIcon.BackgroundTransparency = 1
    inputIcon.Font = Enum.Font.GothamBold
    inputIcon.TextSize = 11
    inputIcon.Text = "✏️"
    inputIcon.Parent = inputCard

    C.inputTextBox = Instance.new("TextBox")
    C.inputTextBox.Size = UDim2.new(1, -32, 1, 0)
    C.inputTextBox.Position = UDim2.new(0, 28, 0, 0)
    C.inputTextBox.BackgroundTransparency = 1
    C.inputTextBox.Font = Enum.Font.GothamMedium
    C.inputTextBox.TextSize = 10
    C.inputTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    C.inputTextBox.PlaceholderText = "Введите имя конфига..."
    C.inputTextBox.PlaceholderColor3 = Color3.fromRGB(120, 135, 165)
    C.inputTextBox.Text = "MyConfig"
    C.inputTextBox.ClearTextOnFocus = false
    C.inputTextBox.Parent = inputCard

    -- Action Buttons Grid (2x2) stored in C table
    C.buttonsGrid = Instance.new("Frame")
    C.buttonsGrid.Size = UDim2.new(1, -16, 1, -74)
    C.buttonsGrid.Position = UDim2.new(0, 8, 0, 66)
    C.buttonsGrid.BackgroundTransparency = 1
    C.buttonsGrid.Parent = C.rightFrame

    -- Button 1: ➕ Создать
    C.btnCreate = Instance.new("TextButton")
    C.btnCreate.Size = UDim2.new(0.485, 0, 0.45, 0)
    C.btnCreate.Position = UDim2.new(0, 0, 0, 0)
    C.btnCreate.BackgroundColor3 = Color3.fromRGB(30, 120, 235)
    C.btnCreate.Font = Enum.Font.GothamBold
    C.btnCreate.TextSize = 10
    C.btnCreate.TextColor3 = Color3.fromRGB(255, 255, 255)
    C.btnCreate.Text = "➕ Создать"
    C.btnCreate.AutoButtonColor = true
    C.btnCreate.Parent = C.buttonsGrid
    Instance.new("UICorner", C.btnCreate).CornerRadius = UDim.new(0, 6)

    -- Button 2: 💾 Сохранить
    C.btnSave = Instance.new("TextButton")
    C.btnSave.Size = UDim2.new(0.485, 0, 0.45, 0)
    C.btnSave.Position = UDim2.new(0.515, 0, 0, 0)
    C.btnSave.BackgroundColor3 = Color3.fromRGB(20, 155, 105)
    C.btnSave.Font = Enum.Font.GothamBold
    C.btnSave.TextSize = 10
    C.btnSave.TextColor3 = Color3.fromRGB(255, 255, 255)
    C.btnSave.Text = "💾 Сохранить"
    C.btnSave.AutoButtonColor = true
    C.btnSave.Parent = C.buttonsGrid
    Instance.new("UICorner", C.btnSave).CornerRadius = UDim.new(0, 6)

    -- Button 3: 📂 Загрузить
    C.btnLoad = Instance.new("TextButton")
    C.btnLoad.Size = UDim2.new(0.485, 0, 0.45, 0)
    C.btnLoad.Position = UDim2.new(0, 0, 0.52, 0)
    C.btnLoad.BackgroundColor3 = Color3.fromRGB(115, 80, 215)
    C.btnLoad.Font = Enum.Font.GothamBold
    C.btnLoad.TextSize = 10
    C.btnLoad.TextColor3 = Color3.fromRGB(255, 255, 255)
    C.btnLoad.Text = "📂 Загрузить"
    C.btnLoad.AutoButtonColor = true
    C.btnLoad.Parent = C.buttonsGrid
    Instance.new("UICorner", C.btnLoad).CornerRadius = UDim.new(0, 6)

    -- Button 4: 🗑️ Удалить
    C.btnDelete = Instance.new("TextButton")
    C.btnDelete.Size = UDim2.new(0.485, 0, 0.45, 0)
    C.btnDelete.Position = UDim2.new(0.515, 0, 0.52, 0)
    C.btnDelete.BackgroundColor3 = Color3.fromRGB(215, 45, 65)
    C.btnDelete.Font = Enum.Font.GothamBold
    C.btnDelete.TextSize = 10
    C.btnDelete.TextColor3 = Color3.fromRGB(255, 255, 255)
    C.btnDelete.Text = "🗑️ Удалить"
    C.btnDelete.AutoButtonColor = true
    C.btnDelete.Parent = C.buttonsGrid
    Instance.new("UICorner", C.btnDelete).CornerRadius = UDim.new(0, 6)

    local function renderSavedConfigs()
        for _, ch in ipairs(C.listScroll:GetChildren()) do
            if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
                ch:Destroy()
            end
        end
        local list = getSavedList()
        if #list == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 40)
            empty.BackgroundTransparency = 1
            empty.Font = Enum.Font.GothamMedium
            empty.TextSize = 9
            empty.TextColor3 = Color3.fromRGB(130, 150, 185)
            empty.TextWrapped = true
            empty.Text = "Нет сохранённых конфигов.\nНажмите '➕ Создать'!"
            empty.Parent = C.listScroll
            return
        end

        for _, cfgName in ipairs(list) do
            local isSel = (cfgName == C.selectedConfig)
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, -4, 0, 28)
            item.BackgroundColor3 = isSel and Color3.fromRGB(35, 52, 82) or Color3.fromRGB(22, 27, 38)
            item.BorderSizePixel = 0
            item.Text = ""
            item.AutoButtonColor = true
            item.Parent = C.listScroll
            Instance.new("UICorner", item).CornerRadius = UDim.new(0, 6)

            local itemStroke = Instance.new("UIStroke")
            itemStroke.Color = isSel and (currentTheme.Main or Color3.fromRGB(60, 140, 255)) or Color3.fromRGB(36, 44, 62)
            itemStroke.Thickness = isSel and 1.2 or 1
            itemStroke.Transparency = isSel and 0.1 or 0.5
            itemStroke.Parent = item

            local iconLbl = Instance.new("TextLabel")
            iconLbl.Size = UDim2.new(0, 20, 1, 0)
            iconLbl.Position = UDim2.new(0, 6, 0, 0)
            iconLbl.BackgroundTransparency = 1
            iconLbl.Font = Enum.Font.GothamBold
            iconLbl.TextSize = 10
            iconLbl.TextColor3 = isSel and Color3.fromRGB(255, 220, 100) or Color3.fromRGB(160, 180, 210)
            iconLbl.Text = isSel and "⭐" or "📁"
            iconLbl.Parent = item

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -30, 1, 0)
            nameLbl.Position = UDim2.new(0, 28, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = isSel and Enum.Font.GothamBold or Enum.Font.GothamMedium
            nameLbl.TextSize = 10
            nameLbl.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(205, 215, 235)
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.Text = cfgName
            nameLbl.Parent = item

            item.MouseButton1Click:Connect(function()
                C.selectedConfig = cfgName
                C.inputTextBox.Text = cfgName
                updateStatus()
                renderSavedConfigs()
            end)
        end
    end

    refreshBtn.MouseButton1Click:Connect(function()
        renderSavedConfigs()
        showNotification("🔄 СПИСОК ОБНОВЛЁН", "Список сохранённых конфигов обновлён!", Color3.fromRGB(60, 180, 255), "🔄", 2)
    end)

    -- Button Logic: ➕ Создать
    C.btnCreate.MouseButton1Click:Connect(function()
        local raw = C.inputTextBox.Text or "MyConfig"
        local clean = raw:gsub("[^%w_%-]", "")
        if clean == "" then clean = "MyConfig" end

        local list = getSavedList()
        local exists = false
        for _, n in ipairs(list) do
            if n:lower() == clean:lower() then exists = true; clean = n; break end
        end

        if exists then
            showConfirmModal({
                title = "⚠️ КОНФИГ УЖЕ СУЩЕСТВУЕТ",
                desc = "Конфиг '" .. clean .. "' уже существует!\nВы хотите перезаписать его текущими настройками?",
                confirmText = "💾 Перезаписать",
                confirmColor = Color3.fromRGB(230, 140, 30),
                onConfirm = function()
                    local ok = saveConfigToFile(clean)
                    if ok then
                        C.selectedConfig = clean
                        C.inputTextBox.Text = clean
                        renderSavedConfigs()
                        updateStatus()
                        showNotification("💾 КОНФИГ ПЕРЕЗАПИСАН", "Конфиг '" .. clean .. "' успешно сохранён!", Color3.fromRGB(50, 180, 255), "💾", 3)
                    else
                        showNotification("⚠️ ОШИБКА", "Не удалось перезаписать конфиг.", Color3.fromRGB(255, 80, 80), "⚠️", 3)
                    end
                end
            })
        else
            local ok = saveConfigToFile(clean)
            if ok then
                C.selectedConfig = clean
                C.inputTextBox.Text = clean
                renderSavedConfigs()
                updateStatus()
                showNotification("➕ КОНФИГ СОЗДАН", "Новый конфиг '" .. clean .. "' успешно создан!", Color3.fromRGB(60, 220, 120), "➕", 3)
            else
                showNotification("⚠️ ОШИБКА", "Не удалось создать конфиг.", Color3.fromRGB(255, 80, 80), "⚠️", 3)
            end
        end
    end)

    -- Button Logic: 💾 Сохранить (с подтверждением перезаписи)
    C.btnSave.MouseButton1Click:Connect(function()
        local raw = (C.selectedConfig and C.selectedConfig ~= "") and C.selectedConfig or C.inputTextBox.Text
        local clean = (raw or "MyConfig"):gsub("[^%w_%-]", "")
        if clean == "" then clean = "MyConfig" end

        showConfirmModal({
            title = "💾 ПОДТВЕРЖДЕНИЕ СОХРАНЕНИЯ",
            desc = "Перезаписать конфиг '" .. clean .. "'\nтекущими настройками чита?",
            confirmText = "💾 Да, сохранить",
            confirmColor = Color3.fromRGB(20, 155, 105),
            onConfirm = function()
                local ok = saveConfigToFile(clean)
                if ok then
                    C.selectedConfig = clean
                    C.inputTextBox.Text = clean
                    renderSavedConfigs()
                    updateStatus()
                    showNotification("💾 КОНФИГ СОХРАНЁН", "Настройки сохранены в профиль '" .. clean .. "'!", Color3.fromRGB(0, 220, 150), "💾", 3)
                else
                    showNotification("⚠️ ОШИБКА", "Не удалось сохранить конфиг.", Color3.fromRGB(255, 80, 80), "⚠️", 3)
                end
            end
        })
    end)

    -- Button Logic: 📂 Загрузить
    C.btnLoad.MouseButton1Click:Connect(function()
        local raw = (C.selectedConfig and C.selectedConfig ~= "") and C.selectedConfig or C.inputTextBox.Text
        local clean = (raw or ""):gsub("[^%w_%-]", "")
        if clean == "" then
            showNotification("⚠️ ВНИМАНИЕ", "Выберите или введите имя конфига для загрузки!", Color3.fromRGB(255, 180, 50), "⚠️", 3)
            return
        end

        local fileName = "MM2_Config_" .. clean .. ".json"
        local ok = false
        pcall(function()
            if isfile and isfile(fileName) and readfile then
                local decoded = HttpService:JSONDecode(readfile(fileName))
                if type(decoded) == "table" then
                    for k, v in pairs(decoded) do
                        if Config[k] ~= nil then Config[k] = v end
                    end
                    ok = true
                end
            end
        end)
        if ok then
            saveConfig()
            applyUITheme(Config.UITheme)
            if MainFrame then MainFrame.BackgroundTransparency = Config.UIGlassTransparency or 0.12 end
            if _G.MM2_RefreshAllUI then _G.MM2_RefreshAllUI() end
            C.selectedConfig = clean
            C.inputTextBox.Text = clean
            renderSavedConfigs()
            updateStatus()
            showNotification("📂 КОНФИГ ЗАГРУЖЕН", "Конфиг '" .. clean .. "' успешно применён!", Color3.fromRGB(60, 220, 120), "📂", 3)
        else
            showNotification("⚠️ ОШИБКА", "Файл '" .. fileName .. "' не найден или повреждён.", Color3.fromRGB(255, 90, 90), "⚠️", 3)
        end
    end)

    -- Button Logic: 🗑️ Удалить (с подтверждением)
    C.btnDelete.MouseButton1Click:Connect(function()
        local raw = (C.selectedConfig and C.selectedConfig ~= "") and C.selectedConfig or C.inputTextBox.Text
        local clean = (raw or ""):gsub("[^%w_%-]", "")
        if clean == "" then
            showNotification("⚠️ ВНИМАНИЕ", "Выберите конфиг для удаления!", Color3.fromRGB(255, 180, 50), "⚠️", 3)
            return
        end

        showConfirmModal({
            title = "🗑️ ПОДТВЕРЖДЕНИЕ УДАЛЕНИЯ",
            desc = "Вы действительно хотите удалить конфиг '" .. clean .. "'?\nЭто действие нельзя отменить!",
            confirmText = "🗑️ Удалить навсегда",
            confirmColor = Color3.fromRGB(215, 45, 65),
            onConfirm = function()
                local fileName = "MM2_Config_" .. clean .. ".json"
                pcall(function()
                    if delfile and isfile and isfile(fileName) then
                        delfile(fileName)
                    end
                end)
                local curList = getSavedList()
                local newList = {}
                for _, n in ipairs(curList) do
                    if n ~= clean then table.insert(newList, n) end
                end
                saveList(newList)
                if C.selectedConfig == clean then
                    C.selectedConfig = newList[1] or ""
                    C.inputTextBox.Text = C.selectedConfig
                end
                renderSavedConfigs()
                updateStatus()
                showNotification("🗑️ КОНФИГ УДАЛЁН", "Конфиг '" .. clean .. "' успешно удалён.", Color3.fromRGB(240, 90, 90), "🗑️", 3)
            end
        })
    end)

    -- 📋 SECTION 3: CLIPBOARD SHARING
    createSectionHeader(parentTab, "📋 ИМПОРТ И ЭКСПОРТ (CLIPBOARD SHARING)")
    createButton(parentTab, "📤 Скопировать конфиг в буфер обмена (Export)", Color3.fromRGB(130, 90, 230), function()
        local ok = false
        pcall(function()
            if setclipboard then
                setclipboard(HttpService:JSONEncode(Config))
                ok = true
            end
        end)
        if ok then
            showNotification("📋 COPIED TO CLIPBOARD", "Configuration JSON copied! Share it anywhere.", Color3.fromRGB(150, 110, 255), "📋", 3.5)
        else
            showNotification("⚠️ EXPORT FAILED", "setclipboard is not supported on this executor.", Color3.fromRGB(255, 90, 90), "⚠️", 3)
        end
    end)

    createButton(parentTab, "📥 Импортировать конфиг из буфера обмена (Import)", Color3.fromRGB(100, 150, 240), function()
        local ok = false
        pcall(function()
            if getclipboard then
                local str = getclipboard()
                if str and str ~= "" then
                    local data = HttpService:JSONDecode(str)
                    if type(data) == "table" then
                        for k, v in pairs(data) do
                            if Config[k] ~= nil then Config[k] = v end
                        end
                        ok = true
                    end
                end
            end
        end)
        if ok then
            saveConfig()
            applyUITheme(Config.UITheme)
            if MainFrame then MainFrame.BackgroundTransparency = Config.UIGlassTransparency or 0.12 end
            if _G.MM2_RefreshAllUI then _G.MM2_RefreshAllUI() end
            showNotification("📥 IMPORT SUCCESSFUL", "Config loaded from clipboard!", Color3.fromRGB(60, 220, 120), "📥", 3.5)
        else
            showNotification("⚠️ IMPORT FAILED", "Clipboard does not contain valid config JSON.", Color3.fromRGB(255, 90, 90), "⚠️", 3)
        end
    end)

    -- Initial state setup
    local initialList = getSavedList()
    if #initialList > 0 and C.selectedConfig == "" then
        C.selectedConfig = initialList[1]
        C.inputTextBox.Text = C.selectedConfig
    end
        renderSavedConfigs()
        updateStatus()
    end
    initConfigsTab()
end

-- Keybind Handling
addConn(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    -- Check Menu Keybind
    local menuKey = Enum.KeyCode[Config.MenuKeybind] or Enum.KeyCode.RightShift
    if input.KeyCode == menuKey or input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.F4 or input.KeyCode == Enum.KeyCode.RightAlt then
        if toggleMenu then
            toggleMenu()
        end
    end

    -- Check Silent Aim Keybind
    if Config.SilentAimKeybind and Config.SilentAimKeybind ~= "None" then
        local saKey = Enum.KeyCode[Config.SilentAimKeybind]
        if saKey and input.KeyCode == saKey then
            Config.SilentAim = not Config.SilentAim
            saveConfig()
            showNotification("🎯 SILENT AIM", "Silent Aim is now: " .. (Config.SilentAim and "ENABLED" or "DISABLED"), Config.SilentAim and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(220, 50, 50), "🎯", 2.5)
        end
    end

    -- Check Auto-Shot Keybind
    if Config.AutoShotKeybind and Config.AutoShotKeybind ~= "None" then
        local asKey = Enum.KeyCode[Config.AutoShotKeybind]
        if asKey and input.KeyCode == asKey then
            Config.AutoShot = not Config.AutoShot
            saveConfig()
            showNotification("💥 AUTO-SHOT", "Auto-Shot is now: " .. (Config.AutoShot and "ENABLED" or "DISABLED"), Config.AutoShot and Color3.fromRGB(50, 220, 100) or Color3.fromRGB(220, 50, 50), "💥", 2.5)
        end
    end

    -- Check Instant Shoot Keybind (Manual Silent Aim Shot at Murderer on Keybind E)
    if Config.InstantShootKeybind and Config.InstantShootKeybind ~= "None" then
        local shootKey = Enum.KeyCode[Config.InstantShootKeybind]
        if shootKey and input.KeyCode == shootKey then
            local myRole = detectPlayerRole(LocalPlayer)
            if myRole ~= "Murderer" then
                task.spawn(function()
                    local ok, err = shootMurderer(true)
                    if not ok and err then
                        showNotification("⚠️ SHOOT FAILED", tostring(err), Color3.fromRGB(255, 180, 50), "⚠️", 2)
                    end
                end)
            end
        end
    end

    -- Check Knife Reach Keybind (Murderer Long-Range Strike)
    if Config.KnifeReachEnabled ~= false and Config.KnifeReachKeybind and Config.KnifeReachKeybind ~= "None" then
        local reachKey = Enum.KeyCode[Config.KnifeReachKeybind]
        if reachKey and input.KeyCode == reachKey then
            task.spawn(function()
                performLongRangeKnifeStrike()
            end)
        end
    end

    -- Check Knife Throw Keybind (Murderer Silent Aim Knife Throw)
    if Config.KnifeThrowEnabled ~= false and Config.KnifeThrowKeybind and Config.KnifeThrowKeybind ~= "None" then
        local throwKey = Enum.KeyCode[Config.KnifeThrowKeybind]
        if throwKey and input.KeyCode == throwKey then
            task.spawn(function()
                local ok, err = throwKnifeAtTarget(true)
                if not ok and err and StatusText then
                    StatusText.Text = "⚠️ " .. tostring(err)
                end
            end)
        end
    end

    -- Check Disable 3D Render Keybind (F7)
    if input.KeyCode == Enum.KeyCode.F7 then
        local newState = not Config.Disable3DRender
        if _G.MM2_Set3DRenderEnabled then
            _G.MM2_Set3DRenderEnabled(not newState)
        end
        if showNotification then
            showNotification("⚡ 3D RENDER", newState and "3D Рендеринг ОТКЛЮЧЕН (20 FPS)" or "3D Рендеринг ВКЛЮЧЕН", newState and Color3.fromRGB(255, 180, 50) or Color3.fromRGB(50, 220, 100), "⚡", 2.5)
        end
    end
end))

-- ====================================================================
-- 📷 THIRD-PERSON CAMERA NOCLIP & EXTENDED ZOOM ENGINE
-- ====================================================================
do
    local popperHooked = false
    local function tryHookPopper()
        if popperHooked then return true end
        local ok, res = pcall(function()
            local ps = LocalPlayer:FindFirstChild("PlayerScripts")
            local pm = ps and ps:FindFirstChild("PlayerModule")
            local cm = pm and pm:FindFirstChild("CameraModule")
            local zc = cm and cm:FindFirstChild("ZoomController")
            local popper = zc and zc:FindFirstChild("Popper")
            if popper and hookfunction then
                local popperFn = require(popper)
                if type(popperFn) == "function" then
                    local oldPopper
                    oldPopper = hookfunction(popperFn, function(focus, targetZoomRadius, ...)
                        if Config.CameraNoclip then
                            return targetZoomRadius
                        end
                        return oldPopper(focus, targetZoomRadius, ...)
                    end)
                    popperHooked = true
                    return true
                end
            end
            return false
        end)
        return ok and res
    end

    tryHookPopper()
    if not popperHooked then
        task.spawn(function()
            for _ = 1, 20 do
                task.wait(0.5)
                if tryHookPopper() then break end
            end
        end)
    end

    addConn(RunService.RenderStepped:Connect(function()
        if Config.CameraMaxZoom and Config.CameraMaxZoom > 15 then
            if LocalPlayer.CameraMaxZoomDistance ~= Config.CameraMaxZoom then
                LocalPlayer.CameraMaxZoomDistance = Config.CameraMaxZoom
            end
            if LocalPlayer.CameraMinZoomDistance and LocalPlayer.CameraMinZoomDistance > Config.CameraMaxZoom then
                LocalPlayer.CameraMinZoomDistance = 0.5
            end
        end
    end))
end

-- Movement Loops
addConn(UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

-- Stepped Loop: Noclip, SpeedHack, and Non-Intrusive Ghost Anti-Fling (Optimized)
addConn(RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    if _G.MM2_FlingingActive or _G.MM2_FlingCollisionBypass then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    elseif (Config.Noclip or isFarmingCoin or (Config.CoinAutoFarm and not isPlayerInLobby(LocalPlayer))) then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    if Config.SpeedHack and char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= Config.WalkSpeed then
            hum.WalkSpeed = Config.WalkSpeed
        end
    end

    -- Anti-Fling Engine (Safe Ghost Anti-Fling: Protects LocalPlayer without breaking victim collisions)
    if Config.AntiFling and not _G.MM2_FlingingActive and not isFlingRunning then
        if char then
            local myHrp = char:FindFirstChild("HumanoidRootPart")
            if myHrp and myHrp:IsA("BasePart") then
                -- Keep local player protected against fling impulses
                if myHrp.AssemblyLinearVelocity.Magnitude > 150 then
                    myHrp.AssemblyLinearVelocity = Vector3.zero
                end
                if myHrp.AssemblyAngularVelocity.Magnitude > 150 then
                    myHrp.AssemblyAngularVelocity = Vector3.zero
                end
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            end
        end
    end
end))

-- Anti-Fling Dynamic Part Listener (Safe No-Op to preserve victim hitbox physics)
addConn(workspace.DescendantAdded:Connect(function(part)
    -- Intentionally keep victim parts intact for weapon hit and touch registration
end))

-- 🛡️ ANTI-AFK ENGINE (Safe Idled hook + periodic VirtualUser heartbeat)
pcall(function()
    local vu = game:GetService("VirtualUser")
    addConn(LocalPlayer.Idled:Connect(function()
        if Config.AntiAFK ~= false then
            pcall(function()
                vu:CaptureController()
                vu:ClickButton2(Vector2.zero)
            end)
            if flashDynamicIslandAlert then
                flashDynamicIslandAlert("🛡️ Anti-AFK: Активность подтверждена", Color3.fromRGB(50, 220, 120), 2)
            end
        end
    end))
end)

task.spawn(function()
    local vu = game:GetService("VirtualUser")
    while _G.MM2_Hub_Running and (_G.MM2_Hub_InstanceID == InstanceID) do
        task.wait(240)
        if Config.AntiAFK ~= false then
            pcall(function()
                vu:CaptureController()
                vu:ClickButton2(Vector2.zero)
            end)
        end
    end
end)



-- Fly Engine
local flyBodyVel, flyBodyGyro = nil, nil
local function cleanupFly()
    if flyBodyVel then pcall(function() flyBodyVel:Destroy() end); flyBodyVel = nil end
    if flyBodyGyro then pcall(function() flyBodyGyro:Destroy() end); flyBodyGyro = nil end
end

addConn(RunService.RenderStepped:Connect(function()
    if Config.Fly and LocalPlayer.Character then
        local root = getLocalRoot()
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if root and hum then
            if not flyBodyVel or flyBodyVel.Parent ~= root then
                cleanupFly()
                flyBodyVel = Instance.new("BodyVelocity")
                flyBodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                flyBodyVel.Parent = root

                flyBodyGyro = Instance.new("BodyGyro")
                flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
                flyBodyGyro.CFrame = root.CFrame
                flyBodyGyro.Parent = root
            end

            local camCf = Camera.CFrame
            local moveDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

            flyBodyVel.Velocity = moveDir * Config.FlySpeed
            flyBodyGyro.CFrame = camCf
        end
    else
        cleanupFly()
    end
end))

-- Helper: Real-time Player Replication Ping (ms)
_G.MM2_GetPlayerPingMs = function(plr, char)
    if not plr then return 0 end
    if plr == LocalPlayer then
        local p = 0
        pcall(function() p = LocalPlayer:GetNetworkPing() * 1000 end)
        if p > 0 then return math.floor(p) end
        return 45
    end
    if char and char:FindFirstChild("HumanoidRootPart") then
        local root = char.HumanoidRootPart
        local age = 0
        pcall(function() age = root.ReceiveAge end)
        if age and age > 0 and age < 2 then
            return math.floor(age * 1000)
        end
    end
    local p = 0
    pcall(function() p = plr:GetNetworkPing() * 1000 end)
    if p > 0 then return math.floor(p) end
    return 50
end

-- ESP Card Generator (Compact & Simple Card with Avatar, Weapon Badge & Ping)
local function createOrUpdateCard(key, adornee, title, subText, accentColor, playerObj)
    local esp = ActiveESP[key]
    local hasAvatar = (playerObj ~= nil and playerObj.UserId ~= nil)
    if not esp then
        local bb = Instance.new("BillboardGui")
        bb.Name = "MM2_ESP_" .. key
        bb.Adornee = adornee
        bb.Size = hasAvatar and UDim2.new(0, 156, 0, 34) or UDim2.new(0, 130, 0, 32)
        bb.StudsOffset = Vector3.new(0, 3.4, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = 1000
        bb.Parent = container

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
        frame.BackgroundTransparency = 0.15
        frame.BorderSizePixel = 0
        frame.Parent = bb
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

        local stroke = Instance.new("UIStroke")
        stroke.Color = accentColor
        stroke.Thickness = 1.2
        stroke.Transparency = 0.2
        stroke.Parent = frame

        local av = Instance.new("ImageLabel")
        av.Name = "Avatar"
        av.Size = UDim2.new(0, 24, 0, 24)
        av.Position = UDim2.new(0, 5, 0.5, -12)
        av.BackgroundTransparency = 1
        av.BorderSizePixel = 0
        av.Visible = hasAvatar
        av.Parent = frame
        Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)
        local avSt = Instance.new("UIStroke")
        avSt.Color = accentColor
        avSt.Thickness = 1
        avSt.Transparency = 0.35
        avSt.Parent = av
        if hasAvatar then
            av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(playerObj.UserId) .. "&w=100&h=100"
        end

        local hLbl = Instance.new("TextLabel")
        hLbl.Size = hasAvatar and UDim2.new(1, -38, 0, 14) or UDim2.new(1, -12, 0, 14)
        hLbl.Position = hasAvatar and UDim2.new(0, 34, 0, 3) or UDim2.new(0, 6, 0, 3)
        hLbl.BackgroundTransparency = 1
        hLbl.Font = Enum.Font.GothamBold
        hLbl.TextSize = 11
        hLbl.TextColor3 = Color3.fromRGB(245, 250, 255)
        hLbl.Text = title
        hLbl.TextXAlignment = Enum.TextXAlignment.Left
        hLbl.TextTruncate = Enum.TextTruncate.AtEnd
        hLbl.Parent = frame

        local sLbl = Instance.new("TextLabel")
        sLbl.Size = hasAvatar and UDim2.new(1, -38, 0, 13) or UDim2.new(1, -12, 0, 13)
        sLbl.Position = hasAvatar and UDim2.new(0, 34, 0, 17) or UDim2.new(0, 6, 0, 17)
        sLbl.BackgroundTransparency = 1
        sLbl.Font = Enum.Font.GothamMedium
        sLbl.TextSize = 9
        sLbl.TextColor3 = accentColor
        sLbl.Text = subText
        sLbl.TextXAlignment = Enum.TextXAlignment.Left
        sLbl.TextTruncate = Enum.TextTruncate.AtEnd
        sLbl.Parent = frame

        ActiveESP[key] = {
            Billboard = bb,
            Stroke = stroke,
            Header = hLbl,
            Sub = sLbl,
            Avatar = av,
            AvatarStroke = avSt,
            Adornee = adornee
        }
    else
        esp.Billboard.Adornee = adornee
        esp.Stroke.Color = accentColor
        esp.Header.Text = title
        esp.Header.TextSize = Config.ESPTextSize or 11
        esp.Sub.Text = subText
        esp.Sub.TextColor3 = accentColor
        esp.Sub.TextSize = math.max(7, (Config.ESPTextSize or 11) - 2)
        local hasAvatar = (Config.ESPShowAvatar ~= false) and (playerObj ~= nil and playerObj:IsA("Player"))
        if esp.Avatar then
            if hasAvatar then
                esp.Avatar.Visible = true
                local thumbUrl = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(playerObj.UserId) .. "&w=100&h=100"
                if esp.Avatar.Image ~= thumbUrl then
                    esp.Avatar.Image = thumbUrl
                end
                if esp.AvatarStroke then
                    esp.AvatarStroke.Color = accentColor
                end
                esp.Header.Position = UDim2.new(0, 34, 0, 3)
                esp.Header.Size = UDim2.new(1, -38, 0, 14)
                esp.Sub.Position = UDim2.new(0, 34, 0, 17)
                esp.Sub.Size = UDim2.new(1, -38, 0, 13)
                esp.Billboard.Size = UDim2.new(0, 156, 0, 34)
            else
                esp.Avatar.Visible = false
                esp.Header.Position = UDim2.new(0, 6, 0, 3)
                esp.Header.Size = UDim2.new(1, -12, 0, 14)
                esp.Sub.Position = UDim2.new(0, 6, 0, 17)
                esp.Sub.Size = UDim2.new(1, -12, 0, 13)
                esp.Billboard.Size = UDim2.new(0, 130, 0, 32)
            end
        end
        esp.Billboard.Enabled = true
    end
end

local function createOrUpdateHighlight(key, charModel, accentColor)
    if not charModel or not charModel.Parent then return end

    -- STRICT SAFETY: Never highlight the Map, Workspace, or Lobby models!
    if charModel == workspace or (CachedMap and charModel == CachedMap) or charModel.Name == "RegularLobby" or charModel.Name == "Terrain" then
        return
    end
    if charModel:IsA("Model") and #charModel:GetDescendants() > 40 and not Players:GetPlayerFromCharacter(charModel) then
        return
    end

    local esp = ActiveESP[key]
    if not esp then
        esp = {}
        ActiveESP[key] = esp
    end

    local hl = esp.Highlight
    -- If highlight exists but was orphaned or attached to wrong parent
    if hl and (hl.Parent ~= charModel or hl.Adornee ~= charModel) then
        pcall(function() hl:Destroy() end)
        hl = nil
        esp.Highlight = nil
    end

    if not hl or not hl.Parent then
        hl = Instance.new("Highlight")
        hl.Name = "MM2_HL_" .. key
        hl.Adornee = charModel
        hl.FillColor = accentColor
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.55
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        -- Parent directly to charModel so it dies with character and NEVER covers the screen
        hl.Parent = charModel
        esp.Highlight = hl
    else
        hl.Adornee = charModel
        hl.FillColor = accentColor
        hl.Enabled = true
    end
end

-- Lightweight Coin ESP Manager (Auto-Purges at round end)
local function updateCoinESP(activeCoins, myPos)
    local used = {}
    local roundActive = isRoundActive()
    if Config.CoinESP and roundActive then
        local _, _, bagName = getMM2CoinBagInfo()
        local coinIcon = (bagName == "Candy") and "🍬" or "🪙"
        local coinColor = (bagName == "Candy") and Color3.fromRGB(255, 130, 240) or Color3.fromRGB(255, 215, 60)
        for i, coin in ipairs(activeCoins) do
            local key = "COIN_" .. i
            used[key] = true
            local dist = math.floor((coin.Position - myPos).Magnitude)

            local esp = ActiveCoinESP[key]
            if not esp then
                local bb = Instance.new("BillboardGui")
                bb.Name = "MM2_CoinESP_" .. i
                bb.Adornee = coin
                bb.Size = UDim2.new(0, 52, 0, 20)
                bb.AlwaysOnTop = true
                bb.MaxDistance = 450
                bb.Parent = container

                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 1, 0)
                frame.BackgroundColor3 = Color3.fromRGB(24, 20, 8)
                frame.BackgroundTransparency = 0.25
                frame.BorderSizePixel = 0
                frame.Parent = bb
                Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)

                local stroke = Instance.new("UIStroke")
                stroke.Color = coinColor
                stroke.Thickness = 1.2
                stroke.Parent = frame

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 9
                lbl.TextColor3 = coinColor
                lbl.Text = string.format("%s %dm", coinIcon, dist)
                lbl.Parent = frame

                ActiveCoinESP[key] = { Billboard = bb, Label = lbl, Adornee = coin }
            else
                esp.Billboard.Adornee = coin
                esp.Label.Text = string.format("%s %dm", coinIcon, dist)
                esp.Billboard.Enabled = true
            end
        end
    end

    for k, esp in pairs(ActiveCoinESP) do
        if not used[k] then
            if not roundActive then
                if esp.Billboard then pcall(function() esp.Billboard:Destroy() end) end
                ActiveCoinESP[k] = nil
            else
                esp.Billboard.Enabled = false
            end
        end
    end
end

-- ====================================================================
-- 🔔 SMART EVENT NOTIFICATION STATE TRACKERS
-- ====================================================================
local LastMapState = nil
local LastHeroPlayer = nil
local MurdererAnnounced = false
local SheriffAnnounced = false
local GunDropAnnounced = false
local MurdererDeadAnnounced = false

-- Throttled Scan Loop
task.spawn(function()
    while _G.MM2_Hub_Running and (_G.MM2_Hub_InstanceID == InstanceID) do
        task.wait(0.35)

        local myRoot = getLocalRoot()
        local myPos = myRoot and myRoot.Position or Vector3.zero

        local activeMap = getCurrentMap()
        CachedMap = activeMap
        local gunDrop = getGunDrop()
        CachedGunDrop = gunDrop

        local foundMurd = nil
        local foundSher = nil
        local foundHero = nil

        for _, plr in ipairs(Players:GetPlayers()) do
            local role = detectPlayerRole(plr)
            if role == "Murderer" and plr ~= LocalPlayer then
                foundMurd = plr
            elseif role == "Sheriff" and plr ~= LocalPlayer then
                foundSher = plr
            elseif role == "Hero" and plr ~= LocalPlayer then
                foundHero = plr
            end
        end

        -- 2. Authoritative check from CurrentRoundClient.PlayerData (available millisecond 0)
        if (not foundMurd or not foundSher) and CurrentRoundClient and CurrentRoundClient.PlayerData then
            for pName, pData in pairs(CurrentRoundClient.PlayerData) do
                if type(pData) == "table" and pData.Role then
                    local p = Players:FindFirstChild(pName)
                    if p and p ~= LocalPlayer then
                        if pData.Role == "Murderer" and not foundMurd then
                            foundMurd = p
                        elseif pData.Role == "Sheriff" and not foundSher then
                            foundSher = p
                        end
                    end
                end
            end
        end

        if not foundSher and foundHero then
            foundSher = foundHero
        end

        -- 3. Sticky persistence during round: never wipe murderer to nil while map is active
        if activeMap then
            if foundMurd then
                CachedMurderer = foundMurd
            elseif CachedMurderer and CachedMurderer.Parent == Players and MurdererAnnounced and (activeMap == LastMapState) then
                foundMurd = CachedMurderer
            else
                CachedMurderer = nil
            end

            if foundSher then
                CachedSheriff = foundSher
            elseif CachedSheriff and CachedSheriff.Parent == Players and SheriffAnnounced and (activeMap == LastMapState) then
                foundSher = CachedSheriff
            else
                CachedSheriff = nil
            end
        else
            CachedMurderer = nil
            CachedSheriff = nil
        end

        -- 🔔 Round State & Event Tracking (Detect brand new map or round transition)
        local roundActive = isRoundActive()
        if activeMap and (activeMap ~= LastMapState or (roundActive and not LastMapState)) then
            LastMapState = activeMap
            CachedMap = activeMap
            CachedMurderer = nil
            CachedSheriff = nil
            CachedHero = nil
            CachedGunDrop = nil
            MurdererAnnounced = false
            SheriffAnnounced = false
            GunDropAnnounced = false
            MurdererDeadAnnounced = false
            LastHeroPlayer = nil
            _G.MM2_MurdererEliminatedThisRound = false
            _G.MM2_LocalPlayerDiedThisRound = false
            _G.MM2_FlingingActive = false
            _G.MM2_FlingCollisionBypass = false
            hasExecutedPostActionThisRound = false
            _G.MM2_HasExecutedPostActionThisRound = false
            _G.MM2_IsExecutingPostAction = false
            _G.MM2_LocalPlayerRole = nil
            if _G.MM2_ResetRoundCoinState then _G.MM2_ResetRoundCoinState() end
            if Config.CoinAutoFarm then
                CurrentFarmStatus = "Ожидание спавна монет ⏳"
            end
            if Config.EventNotifications then
                if _G.MM2_IsInfectionRound and _G.MM2_IsInfectionRound() then
                    showNotification("☣️ РЕЖИМ INFECTION!", string.format("Карта: %s • Зомби против Выживших!", activeMap.Name), Color3.fromRGB(80, 220, 80), "☣️", 5)
                else
                    showNotification("🗺️ РАУНД НАЧАЛСЯ!", string.format("Карта: %s • Роли распределяются!", activeMap.Name), Color3.fromRGB(0, 210, 255), "🎮", 4.5)
                end
            end
        elseif not activeMap and LastMapState then
            LastMapState = nil
            CachedMap = nil
            CachedMurderer = nil
            CachedSheriff = nil
            CachedHero = nil
            CachedGunDrop = nil
            MurdererAnnounced = false
            SheriffAnnounced = false
            GunDropAnnounced = false
            MurdererDeadAnnounced = false
            _G.MM2_MurdererEliminatedThisRound = false
            _G.MM2_LocalPlayerDiedThisRound = false
            _G.MM2_FlingingActive = false
            _G.MM2_FlingCollisionBypass = false
            hasExecutedPostActionThisRound = false
            _G.MM2_HasExecutedPostActionThisRound = false
            _G.MM2_IsExecutingPostAction = false
            _G.MM2_LocalPlayerRole = nil
            if Config.EventNotifications then
                showNotification("🏛️ ВОЗВРАТ В ЛОББИ", "Раунд завершен! Все игроки вернулись в лобби.", Color3.fromRGB(160, 170, 195), "⏳", 4)
            end
        end

        -- Authoritative Murderer Death Detection for Farm Auto-Stop (Only if murderer was actually announced this round!)
        local mKilledNow = roundActive and MurdererAnnounced and isMurdererDead()
        if mKilledNow then
            if not _G.MM2_MurdererEliminatedThisRound then
                _G.MM2_MurdererEliminatedThisRound = true
                if _G.MM2_OnMurdererEliminated then _G.MM2_OnMurdererEliminated() end
            end
        else
            _G.MM2_MurdererEliminatedThisRound = false
        end

        -- Authoritative LocalPlayer Death Detection for Farm Auto-Stop
        local meKilledNow = roundActive and not isPlayerInLobby(LocalPlayer) and isPlayerDead(LocalPlayer) and (LocalPlayer:GetAttribute("Alive") ~= true)
        if meKilledNow and not _G.MM2_LocalPlayerDiedThisRound then
            _G.MM2_LocalPlayerDiedThisRound = true
            if _G.MM2_StopCoinFarm then _G.MM2_StopCoinFarm() end
            CurrentFarmStatus = "Вы погибли • Ожидание нового раунда ⏳"
        end

        if Config.EventNotifications then
            -- 2. Murderer Revealed
            if activeMap and isRoundActive() and foundMurd and not MurdererAnnounced then
                MurdererAnnounced = true
                if foundMurd == LocalPlayer then
                    showNotification("💀 ВЫ МАРДЕР!", "Ликвидируйте всех невинных и шерифа!", Color3.fromRGB(255, 45, 60), "🔪", 5)
                else
                    showNotification("💀 МАРДЕР ОБНАРУЖЕН!", string.format("%s — МАРДЕР! Будьте осторожны!", foundMurd.DisplayName or foundMurd.Name), Color3.fromRGB(255, 45, 60), "💀", 5)
                end
            end

            -- 3. Sheriff Revealed
            if activeMap and isRoundActive() and foundSher and not SheriffAnnounced and (not foundHero or foundSher ~= foundHero) then
                SheriffAnnounced = true
                if foundSher == LocalPlayer then
                    showNotification("🛡️ ВЫ ШЕРИФ!", "У вас револьвер! Защитите невинных!", Color3.fromRGB(45, 140, 255), "🎯", 5)
                else
                    showNotification("🛡️ ШЕРИФ ОБНАРУЖЕН!", string.format("%s — Шериф с оружием!", foundSher.DisplayName or foundSher.Name), Color3.fromRGB(45, 140, 255), "🛡️", 5)
                end
            end

            -- 4. Gun Dropped (Шериф погиб, револьвер упал)
            if activeMap and isRoundActive() and gunDrop and not GunDropAnnounced then
                GunDropAnnounced = true
                showNotification("⚠️ РЕВОЛЬВЕР ВЫПАЛ!", "Шериф погиб! Пистолет лежит на карте — подберите его!", Color3.fromRGB(255, 215, 0), "⭐", 5.5)
            elseif activeMap and not gunDrop and GunDropAnnounced then
                GunDropAnnounced = false
            end

            -- 5. Murderer Killed Notification
            if activeMap and isRoundActive() and CachedMurderer and MurdererAnnounced and not MurdererDeadAnnounced and mKilledNow then
                MurdererDeadAnnounced = true
                showNotification("🎉 МАРДЕР УНИЧТОЖЕН!", "Мардер ликвидирован! Победа невинных!", Color3.fromRGB(45, 225, 105), "🏆", 5.5)
            end

            -- 6. Hero Picked Up Gun (Новый Герой)
            -- Срабатывает ТОЛЬКО если мардер ЖИВ, револьвер ДЕЙСТВИТЕЛЬНО выпадал, и герой жив на карте!
            if activeMap and not MurdererDeadAnnounced and not mKilledNow and (GunDropAnnounced or GunHasDropped) then
                if foundHero and foundHero ~= LastHeroPlayer and isPlayerAlive(foundHero) and not isPlayerInLobby(foundHero) then
                    LastHeroPlayer = foundHero
                    if foundHero == LocalPlayer then
                        showNotification("🔫 ВЫ ПОДОБРАЛИ ПИСТОЛЕТ!", "Теперь вы ГЕРОЙ! Уничтожьте мардера!", Color3.fromRGB(255, 205, 30), "⭐", 5.5)
                    else
                        showNotification("⭐ НОВЫЙ ГЕРОЙ!", string.format("%s подобрал револьвер!", foundHero.DisplayName or foundHero.Name), Color3.fromRGB(255, 205, 30), "⭐", 5)
                    end
                end
            end
        end

        local isInf = _G.MM2_IsInfectionRound and _G.MM2_IsInfectionRound()
        local myRole = detectPlayerRole(LocalPlayer)
        local mapStr = activeMap and activeMap.Name or "In Lobby"

        if not activeMap or mapStr == "In Lobby" then
            StatusText.Text = "🗺️ В лобби | Ожидание раунда..."
        elseif isInf then
            local zCount = 0
            local sCount = 0
            for _, p in ipairs(Players:GetPlayers()) do
                if not isPlayerInLobby(p) and not isPlayerDead(p) then
                    local r = detectPlayerRole(p)
                    if r == "Zombie" then
                        zCount = zCount + 1
                    elseif r == "Survivor" then
                        sCount = sCount + 1
                    end
                end
            end
            StatusText.Text = string.format("🗺️ Map: %s [☣️ Infection] | 🧟 Zombies: %d | 🛡️ Survivors: %d", mapStr, zCount, sCount)
        else
            local murdStr = foundMurd and ("💀 " .. foundMurd.Name) or (myRole == "Murderer" and "💀 YOU" or "💀 None")
            local sherStr = foundSher and (((foundHero and foundSher == foundHero) and "⭐ " or "🛡️ ") .. foundSher.Name) or (myRole == "Sheriff" and "🛡️ YOU" or (myRole == "Hero" and "⭐ YOU" or (gunDrop and "⭐ GUN DROPPED!" or "🛡️ None")))
            StatusText.Text = string.format("🗺️ Map: %s | %s | %s", mapStr, murdStr, sherStr)
        end

        -- 🏝️ Update Dynamic Island
        if DynamicIsland and DynamicIsland.Visible then
            if not isRoundActive() then
                diRoleText.Text = "🏛️ LOBBY"
                diRoleText.TextColor3 = Color3.fromRGB(180, 195, 220)
                if diRoleDot then diRoleDot.BackgroundColor3 = Color3.fromRGB(160, 180, 210) end
                diStroke.Color = IslandThemeColors[Config.IslandTheme] or Color3.fromRGB(80, 100, 140)
                diStatusText.Text = "Ожидание раунда..."
            else
                if isInf then
                    if myRole == "Zombie" then
                        diRoleText.Text = "🧟 ZOMBIE"
                        diRoleText.TextColor3 = Color3.fromRGB(80, 220, 80)
                        if diRoleDot then diRoleDot.BackgroundColor3 = Color3.fromRGB(80, 220, 80) end
                        diStroke.Color = Color3.fromRGB(60, 200, 70)
                        diStatusText.Text = "Infect Survivors ⏱️"
                    else
                        diRoleText.Text = "🛡️ SURVIVOR"
                        diRoleText.TextColor3 = Color3.fromRGB(40, 180, 255)
                        if diRoleDot then diRoleDot.BackgroundColor3 = Color3.fromRGB(40, 180, 255) end
                        diStroke.Color = Color3.fromRGB(40, 180, 255)
                        diStatusText.Text = "Survive the Outbreak ⏱️"
                    end
                elseif myRole == "Murderer" then
                    diRoleText.Text = "💀 MURDERER"
                    diRoleText.TextColor3 = Color3.fromRGB(255, 60, 75)
                    if diRoleDot then diRoleDot.BackgroundColor3 = Color3.fromRGB(255, 50, 65) end
                    diStroke.Color = Color3.fromRGB(255, 45, 65)
                    local targetStr = foundSher and ("🛡️ " .. foundSher.Name) or (gunDrop and "⭐ Gun Dropped" or "Eliminate All")
                    diStatusText.Text = targetStr
                elseif myRole == "Sheriff" or myRole == "Hero" then
                    local roleTitle = (myRole == "Hero") and "⭐ HERO" or "🛡️ SHERIFF"
                    local roleCol = (myRole == "Hero") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(50, 150, 255)
                    diRoleText.Text = roleTitle
                    diRoleText.TextColor3 = roleCol
                    if diRoleDot then diRoleDot.BackgroundColor3 = roleCol end
                    diStroke.Color = roleCol
                    diStatusText.Text = foundMurd and ("💀 " .. foundMurd.Name .. (Config.AutoShot and " [AUTO]" or "")) or "Protect Innocents"
                else
                    if gunDrop then
                        diRoleText.Text = "⭐ GUN DROP"
                        diRoleText.TextColor3 = Color3.fromRGB(255, 215, 0)
                        if diRoleDot then diRoleDot.BackgroundColor3 = Color3.fromRGB(255, 215, 0) end
                        diStroke.Color = Color3.fromRGB(255, 200, 30)
                        diStatusText.Text = "⭐ Gun on Ground! Press Grab!"
                    else
                        diRoleText.Text = "👥 INNOCENT"
                        diRoleText.TextColor3 = Color3.fromRGB(50, 220, 100)
                        if diRoleDot then diRoleDot.BackgroundColor3 = Color3.fromRGB(50, 220, 100) end
                        diStroke.Color = Color3.fromRGB(50, 200, 90)
                        diStatusText.Text = foundMurd and ("💀 " .. foundMurd.Name) or "Survive Round"
                    end
                end
            end
        end

        local shouldGrabGun = Config.AutoGrabGun and not Config.CoinAutoFarm
        if shouldGrabGun and gunDrop and (not isPlayerMurderer(LocalPlayer)) and (myRole ~= "Murderer") and (myRole ~= "Zombie") and (myRole ~= "Lobby") and isRoundActive() and not isPlayerInLobby(LocalPlayer) and not _G.MM2_LocalPlayerDiedThisRound and not isPlayerDead(LocalPlayer) and isLocalPlayerPlayingInRound() then
            pcall(grabGun)
        end

        if Config.KnifeAura and myRole == "Murderer" and LocalPlayer.Character and not isPlayerInLobby(LocalPlayer) then
            local knife = LocalPlayer.Character:FindFirstChild("Knife")
            if not knife and Config.KnifeAutoEquip ~= false then
                knife = ensureKnifeEquipped()
            end
            local events = knife and knife:FindFirstChild("Events")
            local handle = knife and knife:FindFirstChild("Handle")
            if knife and events then
                local stabEv = events:FindFirstChild("KnifeStabbed")
                local touchEv = events:FindFirstChild("HandleTouched")
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character and not isPlayerInLobby(plr) then
                        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                        local root = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Head")
                        if hum and hum.Health > 0 and root then
                            local dist = (root.Position - myPos).Magnitude
                            local auraRad = math.clamp(Config.KnifeAuraRadius or 24, 10, 50)
                            if dist <= auraRad then
                                local canHit = true
                                if Config.KnifeAuraWallCheck and not hasLineOfSight(myPos, root.Position, plr.Character) then
                                    canHit = false
                                end
                                if canHit then
                                    pcall(function()
                                    pcall(function() knife:Activate() end)
                                    if touchEv then
                                        touchEv:FireServer(root)
                                        local head = plr.Character:FindFirstChild("Head")
                                        if head then touchEv:FireServer(head) end
                                    end
                                    if stabEv then
                                        stabEv:FireServer("Slash")
                                        stabEv:FireServer()
                                    end
                                    if firetouchinterest and handle then
                                        firetouchinterest(handle, root, 0)
                                        task.wait()
                                        firetouchinterest(handle, root, 1)
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end
        end

        if Config.MurdererAlert and foundMurd and foundMurd.Character and foundMurd.Character:FindFirstChild("HumanoidRootPart") then
            local mDist = math.floor((foundMurd.Character.HumanoidRootPart.Position - myPos).Magnitude)
            if mDist <= Config.AlertDistance then
                StatusText.Text = string.format("⚠️ WARNING: MURDERER %s IS %d STUDS AWAY! ⚠️", foundMurd.Name, mDist)
            end
        end

        local activeKeys = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local char = plr.Character
                local root = char.HumanoidRootPart
                local dist = math.floor((root.Position - myPos).Magnitude)
                local role = detectPlayerRole(plr)

                local show = false
                local roleColor = Color3.fromRGB(150, 150, 160)
                local roleTag = "Lobby"
                local roleIcon = "👥"

                -- Check if player is in Lobby or round is inactive
                local inLobby = isPlayerInLobby(plr)

                if not isRoundActive() or inLobby or role == "Lobby" then
                    if Config.LobbyESP ~= false then
                        show = true
                        roleColor = Color3.fromRGB(150, 150, 160) -- Neutral Grey for Lobby
                        roleTag = "Lobby"
                        roleIcon = "👥"
                    end
                else
                    if role == "Murderer" and Config.MurdererESP ~= false then
                        show = true
                        roleColor = Color3.fromRGB(255, 45, 60)
                        roleTag = "Murderer"
                        roleIcon = "💀"
                    elseif role == "Zombie" and (Config.MurdererESP ~= false or Config.InnocentESP ~= false) then
                        show = true
                        roleColor = Color3.fromRGB(80, 220, 80)
                        roleTag = "Zombie"
                        roleIcon = "🧟"
                    elseif role == "Survivor" and Config.InnocentESP ~= false then
                        show = true
                        roleColor = Color3.fromRGB(40, 180, 255)
                        roleTag = "Survivor"
                        roleIcon = "🛡️"
                    elseif role == "Sheriff" and Config.SheriffESP ~= false then
                        show = true
                        roleColor = Color3.fromRGB(45, 140, 255)
                        roleTag = "Sheriff"
                        roleIcon = "🛡️"
                    elseif role == "Hero" and (Config.HeroESP ~= false or Config.SheriffESP ~= false) then
                        show = true
                        roleColor = Color3.fromRGB(255, 215, 0) -- Brilliant Gold for Hero
                        roleTag = "Hero"
                        roleIcon = "⭐"
                    elseif role == "Innocent" and Config.InnocentESP ~= false then
                        show = true
                        roleColor = Color3.fromRGB(50, 220, 100)
                        roleTag = "Innocent"
                        roleIcon = "👥"
                    end
                end

                local key = "PLR_" .. plr.Name
                if show then
                    activeKeys[key] = true
                    local ping = (_G.MM2_GetPlayerPingMs and _G.MM2_GetPlayerPingMs(plr, char)) or 50
                    local title = (Config.ESPShowNames ~= false) and (plr.DisplayName or plr.Name) or roleTag

                    -- Held Weapon Visual Badge
                    local holding = ""
                    if Config.ESPShowWeapon ~= false then
                        for _, it in ipairs(char:GetChildren()) do
                            if it:IsA("Tool") then
                                local n = it.Name:lower()
                                if n:find("knife") then
                                    holding = " 🔪"
                                elseif n:find("gun") or n:find("revolver") then
                                    holding = " 🔫"
                                end
                            end
                        end
                    end

                    local parts = {}
                    if Config.ESPShowRole ~= false then
                        table.insert(parts, roleIcon .. " " .. roleTag .. holding)
                    elseif holding ~= "" then
                        table.insert(parts, holding)
                    end
                    if Config.ESPShowPing ~= false then
                        table.insert(parts, string.format("%dms", ping))
                    end
                    if Config.ESPShowDistance ~= false then
                        table.insert(parts, string.format("%dm", dist))
                    end
                    local subInfo = table.concat(parts, " • ")
                    if subInfo == "" then subInfo = " " end

                    createOrUpdateCard(key, root, title, subInfo, roleColor, plr)
                    createOrUpdateHighlight(key, char, roleColor)
                end
            end
        end

        if Config.GunDropESP and gunDrop then
            local key = "GUN_DROP"
            activeKeys[key] = true
            local dist = math.floor((gunDrop.Position - myPos).Magnitude)
            createOrUpdateCard(key, gunDrop, "⭐ Dropped Gun", string.format("%dm", dist), Color3.fromRGB(255, 215, 0), nil)
            createOrUpdateHighlight(key, gunDrop, Color3.fromRGB(255, 215, 0))
        end

        for k, v in pairs(ActiveESP) do
            if not activeKeys[k] then
                if v.Billboard then v.Billboard.Enabled = false end
                if v.Highlight then
                    v.Highlight.Enabled = false
                    v.Highlight.Adornee = nil
                    pcall(function() v.Highlight:Destroy() end)
                    v.Highlight = nil
                end
            end
        end

        if Config.CoinESP and isRoundActive() then
            local activeCoins = getActiveCoins()
            updateCoinESP(activeCoins, myPos)
        else
            updateCoinESP({}, myPos)
        end
    end
end)

-- ====================================================================
-- 💥 AUTO-SHOOT MURDERER BACKGROUND TASK
-- ====================================================================
task.spawn(function()
    local lastShotAttemptTime = 0
    while _G.MM2_Hub_Running and (_G.MM2_Hub_InstanceID == InstanceID) do
        task.wait(math.clamp(tonumber(Config.AutoShotDelay) or 0.6, 0.2, 3.0))
        if Config.AutoShot == true and isRoundActive() and not isPlayerInLobby(LocalPlayer) and not isPlayerDead(LocalPlayer) then
            local myRole = detectPlayerRole(LocalPlayer)
            if myRole ~= "Murderer" then
                local gun, isEquipped = _G.MM2_GetLocalGunTool and _G.MM2_GetLocalGunTool()
                if not gun then
                    local gDrop = getGunDrop()
                    if gDrop and not isPlayerMurderer(LocalPlayer) then
                        pcall(grabGun)
                        task.wait(0.2)
                        gun, isEquipped = _G.MM2_GetLocalGunTool and _G.MM2_GetLocalGunTool()
                    end
                end

                if gun then
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if gun.Parent ~= char and hum then
                        hum:EquipTool(gun)
                        local waited = 0
                        while gun.Parent ~= char and waited < 0.25 do
                            task.wait(0.03)
                            waited = waited + 0.03
                        end
                    end

                    -- Dynamically resolve live Murderer
                    local target = CachedMurderer
                    if not target or not target.Character or detectPlayerRole(target) ~= "Murderer" or isPlayerDead(target) then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character and detectPlayerRole(p) == "Murderer" and not isPlayerDead(p) then
                                target = p
                                CachedMurderer = p
                                break
                            end
                        end
                    end

                    if target and target.Character and not isPlayerDead(target) and not isPlayerInLobby(target) then
                        local mHum = target.Character:FindFirstChildOfClass("Humanoid")
                        local mRoot = target.Character:FindFirstChild("HumanoidRootPart")
                        if mHum and mHum.Health > 0 and mRoot then
                            pcall(function()
                                local ok, msg = shootMurderer(false)
                                if ok and StatusText then
                                    StatusText.Text = "💥 Auto-Shot Fired at " .. target.Name .. "!"
                                end
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- ====================================================================
-- 🪙 NEW ADVANCED AUTO FARM ENGINE: TWEEN, PRONE, UNDERGROUND & ANTI-VOID
-- ====================================================================
task.spawn(function()
    local UndergroundPlatform = nil
    local LastWasInLobby = true
    local isFarmingCoin = false
    local activeCoinTween = nil
    local activeFarmBv = nil
    local activeFarmNoclipConn = nil
    local farmSessionId = 0

    local function getLobbyPlatformPosition()
        local lobby = workspace:FindFirstChild("RegularLobby") or workspace:FindFirstChild("Lobby")
        local spawns = lobby and (lobby:FindFirstChild("Spawns") or lobby:FindFirstChild("Spawn"))
        if spawns then
            local sum = Vector3.zero
            local count = 0
            for _, child in ipairs(spawns:GetChildren()) do
                if child:IsA("BasePart") then
                    sum = sum + child.Position
                    count = count + 1
                end
            end
            if count > 0 then
                local avg = sum / count
                return Vector3.new(avg.X, avg.Y - 58, avg.Z)
            end
            local anyPart = spawns:FindFirstChildWhichIsA("BasePart", true)
            if anyPart then
                return Vector3.new(anyPart.Position.X, anyPart.Position.Y - 58, anyPart.Position.Z)
            end
        end
        return Vector3.new(547, 400, 37.4)
    end
    _G.MM2_GetLobbyPlatformPosition = getLobbyPlatformPosition

    local function cleanupUndergroundPlatform()
        if UndergroundPlatform then
            pcall(function() UndergroundPlatform:Destroy() end)
            UndergroundPlatform = nil
        end
    end

    _G.MM2_StartCoinFarm = function()
        farmSessionId = farmSessionId + 1
        isFarmingCoin = false
        _G.MM2_CoinBlacklist = {}
        CachedCoinContainer = nil
        _G.MM2_TargetCoin = nil
        _G.MM2_RoundLimitReached = false
        _G.MM2_MurdererEliminatedThisRound = false
        _G.MM2_LocalPlayerDiedThisRound = false
        local inLobby = isPlayerInLobby(LocalPlayer)
        local roundActive = isRoundActive()
        if inLobby and not roundActive then
            local rSecs = _G.MM2_GetRoundTimerSeconds and _G.MM2_GetRoundTimerSeconds() or -1
            if rSecs > 0 then
                CurrentFarmStatus = string.format("В лобби (Ожидание раунда • ⏳ %d сек)", rSecs)
            else
                CurrentFarmStatus = "В лобби (Ожидание раунда)"
            end
        else
            CurrentFarmStatus = "Ожидание спавна монет ⏳"
        end
    end

    _G.MM2_StopCoinFarm = function()
        farmSessionId = farmSessionId + 1
        isFarmingCoin = false
        CurrentFarmStatus = "Выключен"
        _G.MM2_RoundLimitReached = false
        _G.MM2_MurdererEliminatedThisRound = false
        if activeCoinTween then
            pcall(function() activeCoinTween:Cancel() end)
            activeCoinTween = nil
        end
        if activeFarmBv and activeFarmBv.Parent then
            pcall(function() activeFarmBv:Destroy() end)
        end
        activeFarmBv = nil

        if activeFarmNoclipConn then
            pcall(function() activeFarmNoclipConn:Disconnect() end)
            activeFarmNoclipConn = nil
        end

        if _G.MM2_SetTargetCoinHighlight then
            _G.MM2_SetTargetCoinHighlight(nil)
        end
        _G.MM2_TargetCoin = nil
        _G.MM2_CoinBlacklist = {}
        CachedCoinContainer = nil

        cleanupUndergroundPlatform()

        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.Anchored = false
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero

                -- Restore upright orientation so player is not stuck prone/ragdolled:
                local _, yRot, _ = root.CFrame:ToOrientation()
                root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yRot, 0)

                local inLobby = isPlayerInLobby(LocalPlayer)
                if inLobby then
                    if root.Position.Y < 430 then
                        local lobby = workspace:FindFirstChild("RegularLobby") or workspace:FindFirstChild("Lobby")
                        local spawns = lobby and (lobby:FindFirstChild("Spawns") or lobby:FindFirstChild("Spawn"))
                        local sp = (spawns and spawns:FindFirstChildWhichIsA("BasePart", true)) or (lobby and lobby:FindFirstChildWhichIsA("BasePart", true))
                        if sp then
                            root.CFrame = sp.CFrame + Vector3.new(0, 3.5, 0)
                        else
                            root.CFrame = CFrame.new(547, 462, 37)
                        end
                    end
                else
                    local map = CachedMap or (getCurrentMap and getCurrentMap())
                    local spawns = map and map:FindFirstChild("Spawns")
                    local sp = (spawns and spawns:FindFirstChildWhichIsA("BasePart")) or (map and map:FindFirstChildWhichIsA("BasePart"))
                    if sp and root.Position.Y < (sp.Position.Y - 15) then
                        root.CFrame = sp.CFrame + Vector3.new(0, 3.5, 0)
                    end
                end
            end
            if hum then
                hum.PlatformStand = false
                hum.Sit = false
                pcall(function()
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end)
            end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end

        local cam = workspace.CurrentCamera
        if cam and cam.CameraType ~= Enum.CameraType.Custom then
            cam.CameraType = Enum.CameraType.Custom
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then cam.CameraSubject = hum end
        end
    end

    _G.MM2_StopCoinFarmLoop = function()
        farmSessionId = farmSessionId + 1
        isFarmingCoin = false
        if activeCoinTween then pcall(function() activeCoinTween:Cancel() end) activeCoinTween = nil end
        if activeFarmBv and activeFarmBv.Parent then pcall(function() activeFarmBv:Destroy() end) activeFarmBv = nil end
        if activeFarmNoclipConn then pcall(function() activeFarmNoclipConn:Disconnect() end) activeFarmNoclipConn = nil end
        if _G.MM2_SetTargetCoinHighlight then _G.MM2_SetTargetCoinHighlight(nil) end
        _G.MM2_TargetCoin = nil
    end

    _G.MM2_OnMurdererEliminated = function()
        _G.MM2_MurdererEliminatedThisRound = true
        CurrentFarmStatus = "Мардер убит • Ожидание нового раунда ⏳"
        if _G.MM2_StopCoinFarmLoop then
            _G.MM2_StopCoinFarmLoop()
        end
        if not isPlayerInLobby(LocalPlayer) and _G.MM2_HideSafelyUnderground then
            _G.MM2_HideSafelyUnderground("Мардер убит • Ожидание нового раунда ⏳")
        end
    end

    local function getOrCreateUndergroundPlatform(basePos)
        local part = UndergroundPlatform
        if not (part and part.Parent) then
            part = workspace:FindFirstChild("MM2_UndergroundPlatform")
        end
        if not part then
            part = Instance.new("Part")
            part.Name = "MM2_UndergroundPlatform"
            part.Material = Enum.Material.SmoothPlastic
            part.Color = Color3.fromRGB(16, 20, 30)
            part.Transparency = 0.35
            part.Parent = workspace
        end
        part.Size = Vector3.new(250, 6, 250)
        part.Position = basePos - Vector3.new(0, 3, 0)
        part.Anchored = true
        part.CanCollide = true
        UndergroundPlatform = part
        return part
    end
    _G.MM2_GetOrCreateUndergroundPlatform = getOrCreateUndergroundPlatform

    local function teleportUnderLobby()
        if not (Config.CoinAutoFarm or _G.MM2_ManualLobbyHideRequest) then return false end
        local char = LocalPlayer.Character
        local root = getLocalRoot()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not root then return false end
        if hum and hum.Health <= 0 then return false end

        local targetPos = getLobbyPlatformPosition()
        getOrCreateUndergroundPlatform(targetPos)

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        local platCf = CFrame.new(targetPos + Vector3.new(0, 4.5, 0))
        if Config.CoinFarmProne and hum then
            hum.PlatformStand = true
            platCf = platCf * CFrame.Angles(math.rad(-90), 0, 0)
        end

        root.CFrame = platCf
        root.Anchored = true
        return true
    end
    _G.MM2_TeleportUnderLobby = teleportUnderLobby

    local function returnToLobbyFloor()
        local char = LocalPlayer.Character
        local root = getLocalRoot()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not root then return end
        cleanupUndergroundPlatform()
        root.Anchored = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        local _, yRot, _ = root.CFrame:ToOrientation()
        root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yRot, 0)
        if hum then
            hum.PlatformStand = false
            hum.Sit = false
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
        cleanCharacterPhysics(char)
        local lobby = workspace:FindFirstChild("RegularLobby") or workspace:FindFirstChild("Lobby")
        local spawns = lobby and (lobby:FindFirstChild("Spawns") or lobby:FindFirstChild("Spawn"))
        local spawnPart = (spawns and spawns:FindFirstChildWhichIsA("BasePart", true)) or (lobby and lobby:FindFirstChildWhichIsA("BasePart", true))
        if spawnPart then
            root.CFrame = spawnPart.CFrame + Vector3.new(0, 4, 0)
        else
            root.CFrame = CFrame.new(547, 462, 37)
        end
    end
    _G.MM2_ReturnToLobbyFloor = returnToLobbyFloor

    LocalPlayer.CharacterAdded:Connect(function(newChar)
        if not (Config.CoinAutoFarm and Config.CoinLobbyHide) then return end
        task.spawn(function()
            local root = newChar:WaitForChild("HumanoidRootPart", 5)
            local hum = newChar:WaitForChild("Humanoid", 5)
            if not root or not hum then return end
            task.wait(0.25)
            if Config.CoinAutoFarm and Config.CoinLobbyHide and isPlayerInLobby(LocalPlayer) and root.Position.Y > 430 then
                teleportUnderLobby()
            end
        end)
    end)

do
    local activeTargetHighlight = nil
    _G.MM2_SetTargetCoinHighlight = function(coin)
        if activeTargetHighlight then
            pcall(function() activeTargetHighlight:Destroy() end)
            activeTargetHighlight = nil
        end
        if coin and coin.Parent and Config.CoinTargetHighlight ~= false then
            pcall(function()
                local adornee = (coin:FindFirstChild("CoinVisual") and coin.CoinVisual:IsA("BasePart") and coin.CoinVisual) or (coin:IsA("BasePart") and coin)
                if adornee then
                    local hl = Instance.new("Highlight")
                    hl.Name = "MM2_TargetCoin_HL"
                    hl.FillColor = Color3.fromRGB(255, 220, 45)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.25
                    hl.OutlineTransparency = 0.05
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Adornee = adornee
                    hl.Parent = adornee
                    activeTargetHighlight = hl
                end
            end)
        end
    end
end

-- ====================================================================
-- ⚔️ POST-40 COINS AUTOMATION: KILL ALL / ELIMINATE MURDERER
-- ====================================================================
local function hideSafelyUnderground(customStatus)
    if not (Config.CoinAutoFarm or _G.MM2_ManualUndergroundRequest) then return end
    local char = LocalPlayer.Character
    local root = getLocalRoot()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not root then return end

    local inLobby = isPlayerInLobby(LocalPlayer)
    local targetPlatformPos
    if inLobby then
        targetPlatformPos = getLobbyPlatformPosition()
    else
        local map = CachedMap or (getCurrentMap and getCurrentMap())
        local spawns = map and map:FindFirstChild("Spawns")
        local refPart = (spawns and spawns:FindFirstChildWhichIsA("BasePart")) or (map and map:FindFirstChildWhichIsA("BasePart"))
        local basePos = refPart and refPart.Position or root.Position
        targetPlatformPos = Vector3.new(basePos.X, basePos.Y - 45, basePos.Z)
    end

    getOrCreateUndergroundPlatform(targetPlatformPos)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    local platCf = CFrame.new(targetPlatformPos + Vector3.new(0, 4.5, 0))
    if Config.CoinFarmProne and hum then
        hum.PlatformStand = true
        platCf = platCf * CFrame.Angles(math.rad(-90), 0, 0)
    end
    root.CFrame = platCf
    root.Anchored = true
    if customStatus then
        CurrentFarmStatus = customStatus
    elseif _G.MM2_MurdererEliminatedThisRound then
        CurrentFarmStatus = "Мардер убит • Ожидание нового раунда ⏳"
    elseif _G.MM2_RoundLimitReached then
        CurrentFarmStatus = "Лимит монет • Скрыт под картой 🛡️"
    end
end
_G.MM2_HideSafelyUnderground = hideSafelyUnderground

local function performKillAll()
    local char = LocalPlayer.Character
    local root = getLocalRoot()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not root or not hum or hum.Health <= 0 then return false, "Нет персонажа" end

    -- Destroy farm anti-gravity body mover and restore physics
    if activeFarmBv and activeFarmBv.Parent then
        pcall(function() activeFarmBv:Destroy() end)
        activeFarmBv = nil
    end
    if activeFarmNoclipConn then
        pcall(function() activeFarmNoclipConn:Disconnect() end)
        activeFarmNoclipConn = nil
    end
    hum.PlatformStand = false
    root.Anchored = false
    cleanCharacterPhysics(char)

    local knife = ensureKnifeEquipped()
    if not knife then
        local bp = LocalPlayer:FindFirstChild("Backpack")
        knife = (char and (char:FindFirstChild("Knife") or char:FindFirstChild("knife"))) or
                (bp and (bp:FindFirstChild("Knife") or bp:FindFirstChild("knife")))
        if knife then
            hum:EquipTool(knife)
            task.wait(0.1)
        end
    end
    if not knife then return false, "Не удалось экипировать нож" end

    local handle = knife:FindFirstChild("Handle")
    local events = knife:FindFirstChild("Events")
    local touchEv = events and events:FindFirstChild("HandleTouched")
    local stabEv = events and events:FindFirstChild("KnifeStabbed")

    local maxRounds = 3
    for roundNum = 1, maxRounds do
        local aliveVictims = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not isPlayerInLobby(p) then
                local pHum = p.Character:FindFirstChildOfClass("Humanoid")
                local pRoot = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Head")
                if pHum and pHum.Health > 0 and pRoot then
                    table.insert(aliveVictims, p)
                end
            end
        end

        if #aliveVictims == 0 then
            break
        end

        for _, victim in ipairs(aliveVictims) do
            if not char or not root or hum.Health <= 0 then break end
            local vChar = victim.Character
            local vHum = vChar and vChar:FindFirstChildOfClass("Humanoid")
            local vRoot = vChar and (vChar:FindFirstChild("HumanoidRootPart") or vChar:FindFirstChild("Head") or vChar:FindFirstChild("UpperTorso"))
            if vHum and vHum.Health > 0 and vRoot then
                if knife.Parent ~= char then
                    hum:EquipTool(knife)
                    task.wait(0.04)
                end

                root.Anchored = false
                hum.PlatformStand = false
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = CFrame.lookAt(vRoot.Position + Vector3.new(0, 0.5, 0), vRoot.Position)

                pcall(function() knife:Activate() end)
                if stabEv then
                    pcall(function() stabEv:FireServer("Slash") end)
                    pcall(function() stabEv:FireServer() end)
                end
                if touchEv then
                    pcall(function() touchEv:FireServer(vRoot) end)
                    local vHead = vChar:FindFirstChild("Head")
                    if vHead then pcall(function() touchEv:FireServer(vHead) end) end
                end
                if firetouchinterest and handle then
                    pcall(function()
                        firetouchinterest(handle, vRoot, 0)
                        firetouchinterest(handle, vRoot, 1)
                    end)
                end

                local startK = os.clock()
                while (os.clock() - startK < 0.16) and vHum and vHum.Health > 0 do
                    if firetouchinterest and handle and vRoot then
                        pcall(function()
                            firetouchinterest(handle, vRoot, 0)
                            firetouchinterest(handle, vRoot, 1)
                        end)
                    end
                    task.wait(0.03)
                end
            end
        end
        task.wait(0.08)
    end

    hideSafelyUnderground("Игроки ликвидированы • Ожидание нового раунда ⏳")
    return true
end
_G.MM2_PerformKillAll = performKillAll

_G.MM2_GetLocalGunTool = function()
    local char = LocalPlayer.Character
    if char then
        local g = char:FindFirstChild("Gun") or char:FindFirstChild("gun")
        if g and g:IsA("Tool") then return g, true end
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and (t:FindFirstChild("Shoot") or t:FindFirstChild("shoot") or t:FindFirstChild("GunServer") or t:FindFirstChild("GunClient") or t.Name:lower():find("gun") or t.Name:lower():find("revolver")) then
                return t, true
            end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local g = bp:FindFirstChild("Gun") or bp:FindFirstChild("gun")
        if g and g:IsA("Tool") then return g, false end
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and (t:FindFirstChild("Shoot") or t:FindFirstChild("shoot") or t:FindFirstChild("GunServer") or t:FindFirstChild("GunClient") or t.Name:lower():find("gun") or t.Name:lower():find("revolver")) then
                return t, false
            end
        end
    end
    return nil, false
end

local function playerHasGun()
    local gun = _G.MM2_GetLocalGunTool and _G.MM2_GetLocalGunTool()
    if gun then return true end
    local myRole = detectPlayerRole(LocalPlayer)
    if myRole == "Sheriff" or myRole == "Hero" then return true end
    return false
end

local function performSheriffEliminateMurderer()
    if not isRoundActive() or isPlayerInLobby(LocalPlayer) or _G.MM2_LocalPlayerDiedThisRound or isPlayerDead(LocalPlayer) or not isLocalPlayerPlayingInRound() then
        return false, "In Lobby or Dead"
    end
    local char = LocalPlayer.Character
    local root = getLocalRoot()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not root or not hum or hum.Health <= 0 then return false end

    -- Destroy farm anti-gravity body mover and restore physics
    if activeFarmBv and activeFarmBv.Parent then
        pcall(function() activeFarmBv:Destroy() end)
        activeFarmBv = nil
    end
    if activeFarmNoclipConn then
        pcall(function() activeFarmNoclipConn:Disconnect() end)
        activeFarmNoclipConn = nil
    end
    hum.PlatformStand = false
    root.Anchored = false
    cleanCharacterPhysics(char)
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)

    local murd = CachedMurderer
    if not murd or not murd.Character or detectPlayerRole(murd) ~= "Murderer" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and detectPlayerRole(p) == "Murderer" then
                murd = p
                CachedMurderer = p
                break
            end
        end
    end

    if not murd or not murd.Character then return false, "Murderer not found" end
    local mHum = murd.Character:FindFirstChildOfClass("Humanoid")
    local mRoot = murd.Character:FindFirstChild("HumanoidRootPart")
    if not mHum or mHum.Health <= 0 or not mRoot then return false end

    local function findBestShootingVantage(targetRoot)
        if not targetRoot or not targetRoot.Parent then return nil end
        local tPos = targetRoot.Position
        local targetChar = targetRoot.Parent
        local curPos = root.Position

        local forward = targetRoot.CFrame.LookVector
        local right = targetRoot.CFrame.RightVector

        local candidates = {
            tPos - (forward * 7.5) + Vector3.new(0, 1.8, 0),
            tPos - (forward * 6.0) + (right * 3.5) + Vector3.new(0, 1.8, 0),
            tPos - (forward * 6.0) - (right * 3.5) + Vector3.new(0, 1.8, 0),
            tPos + (right * 7.5) + Vector3.new(0, 1.8, 0),
            tPos - (right * 7.5) + Vector3.new(0, 1.8, 0),
            tPos + (forward * 7.5) + Vector3.new(0, 1.8, 0),
            tPos + Vector3.new(0, 6.0, 0),
        }

        local bestPos = nil
        local bestDist = math.huge
        for _, cand in ipairs(candidates) do
            if hasLineOfSight(cand, tPos + Vector3.new(0, 1.0, 0), targetChar) then
                local d = (cand - curPos).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestPos = cand
                end
            end
        end

        return bestPos or (tPos - (forward * 7.5) + Vector3.new(0, 2.0, 0))
    end

    local attempts = 0
    -- Infinite Auto-Shoot loop: NEVER ceases after 5 or 10 attempts! Continuously shoots until Murderer is ELIMINATED!
    while isRoundActive() and not isPlayerInLobby(LocalPlayer) and not _G.MM2_LocalPlayerDiedThisRound and not isPlayerDead(LocalPlayer) and isLocalPlayerPlayingInRound() and not _G.MM2_MurdererEliminatedThisRound do
        -- 1. Refresh character references
        char = LocalPlayer.Character
        root = getLocalRoot()
        hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not root or not hum or hum.Health <= 0 then break end

        -- 2. Dynamically refresh murderer target on EVERY attempt
        if not murd or not murd.Character or not murd.Parent or isPlayerDead(murd) or detectPlayerRole(murd) ~= "Murderer" then
            murd = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and detectPlayerRole(p) == "Murderer" and not isPlayerDead(p) then
                    murd = p
                    CachedMurderer = p
                    break
                end
            end
        end

        if not murd or not murd.Character then
            if isMurdererDead() or _G.MM2_MurdererEliminatedThisRound then
                _G.MM2_MurdererEliminatedThisRound = true
                if _G.MM2_OnMurdererEliminated then _G.MM2_OnMurdererEliminated() end
                if showNotification then
                    showNotification("🎯 МАРДЕР ЛИКВИДИРОВАН!", "Шериф успешно ликвидировал мардера! Ожидание нового раунда...", Color3.fromRGB(50, 220, 100), "⭐", 4)
                end
                hideSafelyUnderground("Мардер убит • Ожидание нового раунда ⏳")
                return true
            end
            task.wait(0.4)
        else
            mHum = murd.Character:FindFirstChildOfClass("Humanoid")
            mRoot = murd.Character:FindFirstChild("HumanoidRootPart")
            if not mHum or mHum.Health <= 0 or not mRoot then
                _G.MM2_MurdererEliminatedThisRound = true
                if _G.MM2_OnMurdererEliminated then _G.MM2_OnMurdererEliminated() end
                hideSafelyUnderground("Мардер убит • Ожидание нового раунда ⏳")
                return true
            end

            attempts = attempts + 1

            -- 3. Ensure Gun is retrieved and equipped
            local gun, isEquipped = _G.MM2_GetLocalGunTool and _G.MM2_GetLocalGunTool()
            if not gun then
                local gDrop = getGunDrop()
                if gDrop and not isPlayerMurderer(LocalPlayer) then
                    pcall(grabGun)
                    task.wait(0.25)
                    gun, isEquipped = _G.MM2_GetLocalGunTool and _G.MM2_GetLocalGunTool()
                else
                    task.wait(0.5)
                end
            end

            -- Ensure physics and posture are un-proned and unanchored on EVERY shot
            hum.PlatformStand = false
            root.Anchored = false
            cleanCharacterPhysics(char)
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)

            if gun and gun.Parent ~= char and hum then
                hum:EquipTool(gun)
                local waited = 0
                while gun.Parent ~= char and waited < 0.25 do
                    task.wait(0.03)
                    waited = waited + 0.03
                end
            end

            -- 4. Position character or use WallBang for guaranteed shot
            if mRoot and mRoot.Parent then
                root.Anchored = false
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero

                local isWallBang = (Config.SilentAimWallBang or Config.WallBang or Config.WallBangAllMap or true)
                if not isWallBang then
                    local vantagePos = findBestShootingVantage(mRoot)
                    local mPos = mRoot.Position
                    root.CFrame = CFrame.lookAt(vantagePos, mPos + Vector3.new(0, 1.0, 0))
                    task.wait(0.05)
                end

                -- 5. Execute authoritative shot (WallBang pierces all obstacles directly from safe spot)
                CurrentFarmStatus = string.format("Выстрел в мардера 🎯 [Выстрел #%d]", attempts)
                shootMurderer(true)
                task.wait(0.25)
            end

            -- 6. Check if Murderer was eliminated
            if not murd or not murd.Character or not mHum or mHum.Health <= 0 or isMurdererDead() then
                _G.MM2_MurdererEliminatedThisRound = true
                if _G.MM2_OnMurdererEliminated then _G.MM2_OnMurdererEliminated() end
                if showNotification then
                    showNotification("🎯 МАРДЕР ЛИКВИДИРОВАН!", string.format("Мардер уничтожен выстрелом шерифа! (Всего выстрелов: %d)", attempts), Color3.fromRGB(50, 220, 100), "⭐", 4)
                end
                hideSafelyUnderground("Мардер убит • Ожидание нового раунда ⏳")
                return true
            end

            -- 7. Gun reload cooldown: wait 1.25s then IMMEDIATELY SHOOT AGAIN!
            if showNotification and (attempts == 1 or attempts % 3 == 0) then
                showNotification("🔫 AUTO-SHOOT", string.format("Авто-выстрел в мардера #%d • Перезарядка...", attempts), Color3.fromRGB(45, 140, 255), "🎯", 1.4)
            end
            task.wait(1.25)
        end
    end

    if _G.MM2_MurdererEliminatedThisRound or isMurdererDead() then
        hideSafelyUnderground("Мардер убит • Ожидание нового раунда ⏳")
        return true
    end

    hideSafelyUnderground()
    return false
end
_G.MM2_PerformSheriffEliminateMurderer = performSheriffEliminateMurderer

local function performFlingMurderer()
    local char = LocalPlayer.Character
    local root = getLocalRoot()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not root or not hum or hum.Health <= 0 then return false end

    -- USER REQUEST: If player now has gun, DO NOT FLING! Immediately shoot the murderer instead!
    if playerHasGun() then
        if showNotification then
            showNotification("🎯 ПИСТОЛЕТ В РУКАХ!", "Обнаружен револьвер! Переключение с флинга на выстрел в мардера...", Color3.fromRGB(45, 140, 255), "🎯", 3.5)
        end
        return performSheriffEliminateMurderer()
    end

    local murd = CachedMurderer
    if not murd or not murd.Character or detectPlayerRole(murd) ~= "Murderer" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and detectPlayerRole(p) == "Murderer" then
                murd = p
                CachedMurderer = p
                break
            end
        end
    end

    if not murd or not murd.Character then
        if CurrentRoundClient and CurrentRoundClient.PlayerData then
            for pName, pData in pairs(CurrentRoundClient.PlayerData) do
                if pData.Role == "Murderer" then
                    local p = Players:FindFirstChild(pName)
                    if p and p.Character then
                        murd = p
                        CachedMurderer = p
                        break
                    end
                end
            end
        end
    end

    if not murd or not murd.Character then return false, "Murderer not found" end
    local mHum = murd.Character:FindFirstChildOfClass("Humanoid")
    local mRoot = murd.Character:FindFirstChild("HumanoidRootPart")
    if not mHum or mHum.Health <= 0 or not mRoot then return false end

    local map = CachedMap or getCurrentMap()
    if isFarmingCoin then
        local spawns = map and map:FindFirstChild("Spawns")
        local refPart = (spawns and spawns:FindFirstChildWhichIsA("BasePart")) or (map and map:FindFirstChildWhichIsA("BasePart"))
        local safePlatformPos = refPart and Vector3.new(refPart.Position.X, refPart.Position.Y - 40, refPart.Position.Z) or Vector3.new(0, -35, 0)
        getOrCreateUndergroundPlatform(safePlatformPos)
    end

    -- Free up physics and destroy farm anti-gravity body velocity so fling works with full force
    if activeFarmBv and activeFarmBv.Parent then
        pcall(function() activeFarmBv:Destroy() end)
        activeFarmBv = nil
    end

    -- Disconnect farm noclip immediately so character becomes fully physical for collision transfer
    if activeFarmNoclipConn then
        pcall(function() activeFarmNoclipConn:Disconnect() end)
        activeFarmNoclipConn = nil
    end

    _G.MM2_FlingingActive = true
    _G.MM2_FlingCollisionBypass = true
    root.Anchored = false
    hum.PlatformStand = false
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = true end
    end

    local attempts = 0
    local maxAttempts = 25

    local function isMurdDeadCheck(targetPlr)
        if _G.MM2_MurdererEliminatedThisRound or isMurdererDead() then return true end
        if not targetPlr or not targetPlr.Parent or isPlayerDead(targetPlr) then return true end
        local tChar = targetPlr.Character
        if not tChar or not tChar.Parent then return true end
        local tHum = tChar:FindFirstChildOfClass("Humanoid")
        local tRoot = tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Head")
        if not tHum or tHum.Health <= 0 then return true end
        if tRoot and tRoot.Position.Y < -50 then return true end
        if isRoundActive() and isPlayerInLobby(targetPlr) then return true end
        return false
    end

    while isRoundActive() and not isPlayerInLobby(LocalPlayer) and not _G.MM2_LocalPlayerDiedThisRound and not isPlayerDead(LocalPlayer) and isLocalPlayerPlayingInRound() and attempts < maxAttempts do
        -- 0. INSTANT TERMINATION: If murderer is already dead or eliminated, stop IMMEDIATELY!
        if isMurdDeadCheck(murd) then
            _G.MM2_MurdererEliminatedThisRound = true
            _G.MM2_FlingingActive = false
            _G.MM2_FlingCollisionBypass = false
            cleanCharacterPhysics(char)
            hum.PlatformStand = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            if _G.MM2_OnMurdererEliminated then _G.MM2_OnMurdererEliminated() end
            if showNotification then
                showNotification("🎉 МАРДЕР УСТРАНЁН!", "Мардер ликвидирован! Цикл флинга остановлен.", Color3.fromRGB(50, 220, 100), "⭐", 3.5)
            end
            if isFarmingCoin then
                hideSafelyUnderground("Мардер убит • Ожидание нового раунда ⏳")
            end
            return true
        end

        -- 1. Refresh murderer reference dynamically on each attempt
        if not murd or not murd.Character or detectPlayerRole(murd) ~= "Murderer" or isMurdDeadCheck(murd) then
            murd = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and detectPlayerRole(p) == "Murderer" and not isMurdDeadCheck(p) then
                    murd = p
                    CachedMurderer = p
                    break
                end
            end
            if not murd and CurrentRoundClient and CurrentRoundClient.PlayerData then
                for pName, pData in pairs(CurrentRoundClient.PlayerData) do
                    if type(pData) == "table" and pData.Role == "Murderer" and pData.Dead ~= true and pData.Killed ~= true then
                        local p = Players:FindFirstChild(pName)
                        if p and p.Character and not isMurdDeadCheck(p) then
                            murd = p
                            CachedMurderer = p
                            break
                        end
                    end
                end
            end
        end

        -- If murderer could not be found or all murderers are dead: TERMINATE IMMEDIATELY!
        if not murd or isMurdDeadCheck(murd) then
            _G.MM2_MurdererEliminatedThisRound = true
            _G.MM2_FlingingActive = false
            _G.MM2_FlingCollisionBypass = false
            cleanCharacterPhysics(char)
            hum.PlatformStand = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            if _G.MM2_OnMurdererEliminated then _G.MM2_OnMurdererEliminated() end
            if showNotification then
                showNotification("🎉 МАРДЕР УСТРАНЁН!", "Мардер мёртв или покинул сервер! Цикл флинга остановлен.", Color3.fromRGB(50, 220, 100), "⭐", 3.5)
            end
            if isFarmingCoin then
                hideSafelyUnderground("Мардер убит • Ожидание нового раунда ⏳")
            end
            return true
        end

        attempts = attempts + 1

        -- Mid-fling gun detection: if player acquired gun, immediately abort fling and shoot!
        if playerHasGun() then
            if showNotification then
                showNotification("🎯 ПИСТОЛЕТ ПОЛУЧЕН!", "Подобран револьвер! Переключаемся на выстрел в мардера...", Color3.fromRGB(45, 140, 255), "🎯", 3.5)
            end
            _G.MM2_FlingingActive = false
            _G.MM2_FlingCollisionBypass = false
            cleanCharacterPhysics(char)
            hum.PlatformStand = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            return performSheriffEliminateMurderer()
        end

        -- If gun dropped on the ground, grab it!
        local gunDrop = getGunDrop()
        if gunDrop and not playerHasGun() and not isPlayerMurderer(LocalPlayer) then
            pcall(grabGun)
            task.wait(0.2)
            if playerHasGun() then
                _G.MM2_FlingingActive = false
                _G.MM2_FlingCollisionBypass = false
                cleanCharacterPhysics(char)
                hum.PlatformStand = false
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                return performSheriffEliminateMurderer()
            end
        end

        CurrentFarmStatus = string.format("Флинг мардера 🌪️ [Попытка %d]", attempts)
        if showNotification then
            showNotification("🌪️ ФЛИНГ МАРДЕРА", string.format("Атака на мардера %s (Попытка #%d)...", murd.DisplayName or murd.Name, attempts), Color3.fromRGB(255, 120, 40), "🌪️", 2.0)
        end

        _G.MM2_FlingingActive = true
        _G.MM2_FlingCollisionBypass = true
        root.Anchored = false
        hum.PlatformStand = false
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end

        -- Extended high-energy fling attack
        local flingFn = _G.MM2_ExecuteSingleFling or executeSingleFling
        if flingFn then flingFn(murd, true, 3.5) end
        task.wait(0.15)

        -- Check if murderer died or got launched into void during or after this fling attempt
        if isMurdDeadCheck(murd) then
            _G.MM2_MurdererEliminatedThisRound = true
            _G.MM2_FlingingActive = false
            _G.MM2_FlingCollisionBypass = false
            cleanCharacterPhysics(char)
            hum.PlatformStand = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            if _G.MM2_OnMurdererEliminated then _G.MM2_OnMurdererEliminated() end
            if showNotification then
                showNotification("🎉 МАРДЕР УСТРАНЁН!", "Мардер ликвидирован! Остановка цикла флинга.", Color3.fromRGB(50, 220, 100), "⭐", 4)
            end
            if isFarmingCoin then
                hideSafelyUnderground("Мардер убит • Ожидание нового раунда ⏳")
            end
            return true
        end

        -- If murderer is STILL alive: brief recovery breather then re-attack!
        CurrentFarmStatus = string.format("Мардер жив • Повторный флинг [Попытка %d] ⏳", attempts)
        if showNotification and (attempts % 2 == 0) then
            showNotification("🔄 ПОВТОРНЫЙ ФЛИНГ", string.format("Мардер не сброшен! Запуск повторной атаки #%d...", attempts + 1), Color3.fromRGB(255, 160, 40), "🌪️", 2.0)
        end
        cleanCharacterPhysics(char)
        task.wait(0.5)
    end

    -- Cleanup fling state & restore posture cleanly
    _G.MM2_FlingingActive = false
    _G.MM2_FlingCollisionBypass = false
    cleanCharacterPhysics(char)
    hum.PlatformStand = false
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    if isFarmingCoin then
        hideSafelyUnderground(_G.MM2_MurdererEliminatedThisRound and "Мардер убит • Ожидание нового раунда ⏳" or nil)
    end
    return _G.MM2_MurdererEliminatedThisRound == true
end
_G.MM2_PerformFlingMurderer = performFlingMurderer

local function executePostBagFullAction(triggerReason)
    if not isRoundActive() or isPlayerInLobby(LocalPlayer) or _G.MM2_LocalPlayerDiedThisRound or isPlayerDead(LocalPlayer) or not isLocalPlayerPlayingInRound() then
        return
    end
    -- STRICT GUARD: Never execute post-action (reset, AFK, kill all) unless coin bag is ACTUALLY full!
    if not isCoinBagFull() then
        return
    end

    -- If post action already executed this round, maintain underground safety and exit
    if hasExecutedPostActionThisRound or _G.MM2_HasExecutedPostActionThisRound then
        if Config.CoinPostAction == "Afk" or Config.CoinPostAction == "KillAll_Or_Shoot" then
            hideSafelyUnderground("Лимит монет • Скрыт под картой 🛡️")
        end
        return
    end
    local char = LocalPlayer.Character
    local root = getLocalRoot()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not root or not hum or hum.Health <= 0 then return end

    if _G.MM2_IsExecutingPostAction then return end

    local curCoins, _, bagName, maxCap = getMM2CoinBagInfo()
    local bagDispMax = maxCap or 50
    local bagDispCur = curCoins or CoinsCollectedThisRound or 0
    local bagTitle = (bagName and tostring(bagName) ~= "") and tostring(bagName) or "Мешок"
    local isCandy = (bagTitle == "Candy") or (CoinTracker and CoinTracker.Bag == "Candy")
    local actionHeader = (triggerReason == "AllCoinsCollected") and (isCandy and "🍬 ВСЕ КОНФЕТЫ СОБРАНЫ!" or "🪙 ВСЕ МОНЕТЫ СОБРАНЫ!") or (isCandy and "🍬 МЕШОК КОНФЕТ ПОЛОН!" or "💰 МЕШОК ПОЛОН!")
    local statusPrefix = (triggerReason == "AllCoinsCollected") and "Все конфеты собраны" or string.format("Лимит (%s)", bagTitle)

    -- INFECTION MODE GUARD:
    -- In Infection mode, 1 zombie constantly respawns! KillAll, shoot and fling are impossible/counter-productive.
    -- Survivors win ONLY when the round timer expires. Therefore, safely hide underground and await the timer!
    if _G.MM2_IsInfectionRound and _G.MM2_IsInfectionRound() then
        CurrentFarmStatus = "Режим Infection • Ожидание конца раунда по таймеру ⏱️"
        if not hasExecutedPostActionThisRound then
            hasExecutedPostActionThisRound = true
            _G.MM2_HasExecutedPostActionThisRound = true
            if showNotification then
                showNotification("☣️ РЕЖИМ INFECTION", "Мешок полон! Зомби бесконечно возрождаются — ожидание таймера под картой ⏱️", Color3.fromRGB(80, 220, 80), "☣️", 5)
            end
        end
        hideSafelyUnderground("Режим Infection • Ожидание конца раунда по таймеру ⏱️")
        return
    end

    if Config.CoinPostAction == "Reset" then
        CurrentFarmStatus = string.format("%s • Ресет 💀", statusPrefix)
        if not hasExecutedPostActionThisRound then
            hasExecutedPostActionThisRound = true
            _G.MM2_HasExecutedPostActionThisRound = true
            if showNotification then
                showNotification(actionHeader, "Фарм завершен! Ресет персонажа...", Color3.fromRGB(255, 205, 30), "💀", 3)
            end
            task.spawn(function()
                task.wait(0.2)
                pcall(function() char:BreakJoints() end)
            end)
        end
    elseif Config.CoinPostAction == "Afk" then
        CurrentFarmStatus = string.format("%s • AFK под картой 🛡️", statusPrefix)
        if not hasExecutedPostActionThisRound then
            hasExecutedPostActionThisRound = true
            _G.MM2_HasExecutedPostActionThisRound = true
            if showNotification then
                showNotification(actionHeader, "Режим AFK: Ожидание конца раунда под картой.", Color3.fromRGB(50, 220, 100), "🛡️", 4)
            end
        end
        hideSafelyUnderground(CurrentFarmStatus)
    elseif Config.CoinPostAction == "KillAll_Or_Shoot" then
        local isMurd = isPlayerMurderer(LocalPlayer) or (_G.MM2_LocalPlayerRole == "Murderer") or (detectPlayerRole(LocalPlayer) == "Murderer")
        if isMurd then
            _G.MM2_LocalPlayerRole = "Murderer"
            CurrentFarmStatus = string.format("%s • Kill All ⚔️", statusPrefix)
            hasExecutedPostActionThisRound = true
            _G.MM2_HasExecutedPostActionThisRound = true
            _G.MM2_IsExecutingPostAction = true
            if showNotification then
                showNotification(actionHeader, "Вы Мардер! Запуск ликвидации всех игроков...", Color3.fromRGB(255, 45, 60), "⚔️", 4)
            end
            task.spawn(function()
                local success = performKillAll()
                _G.MM2_IsExecutingPostAction = false
                hideSafelyUnderground("Игроки ликвидированы • Ожидание нового раунда ⏳")
            end)
            return -- STRICT RETURN: Murderer NEVER touches the gun branch below!
        end

        -- NON-MURDERER (Innocent / Sheriff) BRANCH
        hasExecutedPostActionThisRound = true
        _G.MM2_HasExecutedPostActionThisRound = true
        _G.MM2_IsExecutingPostAction = true
        task.spawn(function()
            local hasGun = playerHasGun()
            local gunDrop = getGunDrop()
            if not hasGun and gunDrop then
                pcall(grabGun)
                task.wait(0.25)
                hasGun = playerHasGun()
            end

            if hasGun then
                CurrentFarmStatus = string.format("%s • Выстрел в мардера 🎯", statusPrefix)
                if showNotification then
                    showNotification(actionHeader, "Пистолет в руках! Устранение мардера выстрелом...", Color3.fromRGB(45, 140, 255), "🎯", 4)
                end
                local success = performSheriffEliminateMurderer()
                _G.MM2_IsExecutingPostAction = false
                if _G.MM2_MurdererEliminatedThisRound or success then
                    hasExecutedPostActionThisRound = true
                    _G.MM2_HasExecutedPostActionThisRound = true
                    hideSafelyUnderground("Мардер устранен • Ожидание нового раунда ⏳")
                else
                    -- Keep active to retry immediately until murderer is eliminated!
                    hasExecutedPostActionThisRound = false
                    _G.MM2_HasExecutedPostActionThisRound = false
                end
            else
                CurrentFarmStatus = string.format("%s • Флинг мардера 🌪️", statusPrefix)
                if showNotification then
                    showNotification(actionHeader, "Пистолета нет! Физический флинг мардера...", Color3.fromRGB(255, 120, 40), "🌪️", 4)
                end
                local success = performFlingMurderer()
                _G.MM2_IsExecutingPostAction = false
                if _G.MM2_MurdererEliminatedThisRound or success then
                    hasExecutedPostActionThisRound = true
                    _G.MM2_HasExecutedPostActionThisRound = true
                    hideSafelyUnderground("Мардер сброшен • Ожидание нового раунда ⏳")
                else
                    hasExecutedPostActionThisRound = false
                    _G.MM2_HasExecutedPostActionThisRound = false
                end
            end
        end)
        return
    end
end
_G.MM2_ExecutePostBagFullAction = executePostBagFullAction

local lastAntiVoidNotifyTime = 0
local function handleAntiVoid()
    if not Config.CoinAntiVoid then return end
    -- Never interrupt smooth active tween flight
    if isFarmingCoin and activeCoinTween and activeCoinTween.PlaybackState == Enum.PlaybackState.Playing then
        local root = getLocalRoot()
        if root and root.Position.Y > -400 then return end
    end

    local root = getLocalRoot()
    if not root then return end
    local pos = root.Position

    local inLobby = isPlayerInLobby(LocalPlayer)
    if inLobby then
        if pos.Y < 350 then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            if Config.CoinAutoFarm and Config.CoinLobbyHide then
                teleportUnderLobby()
            else
                local lobby = workspace:FindFirstChild("RegularLobby") or workspace:FindFirstChild("Lobby")
                local spawns = lobby and (lobby:FindFirstChild("Spawns") or lobby:FindFirstChild("Spawn"))
                local spawnPart = (spawns and spawns:FindFirstChildWhichIsA("BasePart", true)) or (lobby and lobby:FindFirstChildWhichIsA("BasePart", true))
                if spawnPart then
                    root.CFrame = spawnPart.CFrame + Vector3.new(0, 4, 0)
                else
                    root.CFrame = CFrame.new(547, 462, 37)
                end
                root.Anchored = false
            end
            if (os.clock() - lastAntiVoidNotifyTime) > 4.0 then
                lastAntiVoidNotifyTime = os.clock()
                if showNotification then
                    showNotification("🛡️ ANTI-VOID", "Спасен от падения в лобби!", Color3.fromRGB(60, 200, 255), "🛡️", 2)
                end
            end
        end
    else
        -- Match Anti-Void: Only trigger on genuine void drops below underground platform
        local curMap = CachedMap or (getCurrentMap and getCurrentMap())
        local mapBaseY = 250
        if curMap then
            local sp = curMap:FindFirstChild("Spawns") or curMap:FindFirstChild("Base")
            local bp = (sp and sp:FindFirstChildWhichIsA("BasePart", true)) or curMap:FindFirstChildWhichIsA("BasePart", true)
            if bp then mapBaseY = bp.Position.Y end
        end

        local voidThreshold = mapBaseY - 120
        if UndergroundPlatform and UndergroundPlatform.Parent then
            voidThreshold = math.min(voidThreshold, UndergroundPlatform.Position.Y - 50)
        end

        if pos.Y < voidThreshold then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            if Config.CoinAutoFarm and Config.CoinUndergroundPlatform and UndergroundPlatform and UndergroundPlatform.Parent then
                local targetCf = UndergroundPlatform.CFrame + Vector3.new(0, 4.5, 0)
                if Config.CoinFarmProne then targetCf = targetCf * CFrame.Angles(math.rad(-90), 0, 0) end
                root.CFrame = targetCf
                root.Anchored = true
            else
                local spawns = curMap and curMap:FindFirstChild("Spawns")
                local sp = spawns and spawns:FindFirstChildWhichIsA("BasePart", true)
                if sp then
                    root.CFrame = sp.CFrame + Vector3.new(0, 5, 0)
                end
                root.Anchored = false
            end
            if (os.clock() - lastAntiVoidNotifyTime) > 4.0 then
                lastAntiVoidNotifyTime = os.clock()
                if showNotification then
                    showNotification("🛡️ ANTI-VOID", "Спасен от падения в бездну карты!", Color3.fromRGB(60, 200, 255), "🛡️", 2)
                end
            end
        end
    end
end

local function handleArenaSpawn()
    if not Config.CoinAutoFarm then return end
    if _G.MM2_LocalPlayerDiedThisRound then return end
    if isFarmingCoin then return end
    if _G.MM2_FlingingActive or isFlingRunning then return end
    local char = LocalPlayer.Character
    local root = getLocalRoot()
    if not char or not root then return end
    if root.AssemblyLinearVelocity.Magnitude > 60 then return end

    local inLobby = isPlayerInLobby(LocalPlayer)
    local isAlive = isLocalPlayerAlive and isLocalPlayerAlive()

    if inLobby then
        LastWasInLobby = true
        if Config.CoinLobbyHide and root.Position.Y > 430 then
            teleportUnderLobby()
            if showNotification then
                showNotification("🙈 ЛОББИ СКРЫТНОСТЬ", "Вы телепортированы под лобби на платформу!", Color3.fromRGB(60, 200, 255), "🏗️", 2.5)
            end
        end
    else
        -- Arena Match Spawn Handling (When transitioning from lobby to arena, or alive on arena surface)
        if LastWasInLobby or (isAlive and not _G.MM2_RoundLimitReached and not _G.MM2_MurdererEliminatedThisRound) then
            local map = CachedMap or (getCurrentMap and getCurrentMap())
            local spawns = map and (map:FindFirstChild("Spawns") or map:FindFirstChild("Spawn"))
            local refPart = (spawns and spawns:FindFirstChildWhichIsA("BasePart")) or (map and map:FindFirstChildWhichIsA("BasePart"))
            local surfaceY = refPart and refPart.Position.Y or root.Position.Y
            if root.Position.Y > surfaceY - 20 then
                LastWasInLobby = false
                hideSafelyUnderground("Начало раунда • Уход под карту 🛡️")
            else
                LastWasInLobby = false
            end
        end
    end
end

    while _G.MM2_Hub_Running and (_G.MM2_Hub_InstanceID == InstanceID) do
        task.wait(0.06)

        -- 1. Anti-Void Check
        pcall(handleAntiVoid)

        -- 2. Arena / Lobby Spawn Detection (Platform 40 studs below)
        pcall(handleArenaSpawn)

        -- 3. Coin & Candy Aura / Magnet Engine (Автоматический вакуум монет и конфет в радиусе 2-7 studs)
        if Config.CoinAutoFarm and Config.CoinAura and firetouchinterest then
            local root = getLocalRoot()
            local inLobby = isPlayerInLobby(LocalPlayer)
            local isAlive = isLocalPlayerAlive and isLocalPlayerAlive()
            if root and not inLobby and isAlive then
                local myPos = root.Position
                local coins = getActiveCoins()
                local auraRadius = math.clamp(Config.CoinAuraRadius or 6.0, 2, 7.0)
                local char = LocalPlayer.Character
                local head = char and char:FindFirstChild("Head")

                for _, coin in ipairs(coins) do
                    local serverPart = getCoinServerPart and getCoinServerPart(coin) or coin
                    if serverPart and serverPart:IsA("BasePart") and serverPart.Parent then
                        local hasTT = serverPart:FindFirstChildWhichIsA("TouchTransmitter") ~= nil
                        local isDead = (serverPart:GetAttribute("Collected") == true)
                            or (serverPart:GetAttribute("Delete") == true)
                            or not hasTT
                        if not isDead then
                            local cPos = serverPart.Position
                            local dist = (cPos - myPos).Magnitude
                            if dist <= auraRadius then
                                pcall(function()
                                    firetouchinterest(root, serverPart, 0)
                                    firetouchinterest(serverPart, root, 0)
                                    if head then
                                        firetouchinterest(head, serverPart, 0)
                                        firetouchinterest(serverPart, head, 0)
                                    end
                                    task.spawn(function()
                                        task.wait(0.035)
                                        pcall(function()
                                            firetouchinterest(root, serverPart, 1)
                                            firetouchinterest(serverPart, root, 1)
                                            if head then
                                                firetouchinterest(head, serverPart, 1)
                                                firetouchinterest(serverPart, head, 1)
                                            end
                                        end)
                                    end)
                                end)
                            end
                        end
                    end
                end
            end
        end

        -- 4. Full Real-Tween & Teleport Auto-Farm Engine (Zero-Delay, Continuous Prone)
        if Config.CoinAutoFarm then
            local roundActive = isRoundActive()
            local inLobby = isPlayerInLobby(LocalPlayer)
            local rSecs = _G.MM2_GetRoundTimerSeconds and _G.MM2_GetRoundTimerSeconds() or -1
            local isPlaying = isLocalPlayerPlayingInRound()

            -- CASE 1: Round is NOT active (Intermission, map voting, waiting in lobby)
            if not roundActive then
                _G.MM2_LocalPlayerDiedThisRound = false
                _G.MM2_RoundLimitReached = false
                _G.MM2_MurdererEliminatedThisRound = false
                hasExecutedPostActionThisRound = false
                pcall(function()
                    LocalPlayer:SetAttribute("BagFull", false)
                    LocalPlayer:SetAttribute("CoinBagFull", false)
                end)
                CoinsCollectedThisRound = 0
                if CoinTracker then
                    CoinTracker.LastProcessedAmt = 0
                    CoinTracker.Amount = 0
                end
                if CurrentRoundClient and CurrentRoundClient.PlayerData and CurrentRoundClient.PlayerData[LocalPlayer.Name] then
                    CurrentRoundClient.PlayerData[LocalPlayer.Name].Dead = false
                    CurrentRoundClient.PlayerData[LocalPlayer.Name].Killed = false
                end
                if isFarmingCoin then
                    farmSessionId = farmSessionId + 1
                    isFarmingCoin = false
                    if _G.MM2_SetTargetCoinHighlight then _G.MM2_SetTargetCoinHighlight(nil) end
                    _G.MM2_TargetCoin = nil
                    if activeCoinTween then
                        pcall(function() activeCoinTween:Cancel() end)
                        activeCoinTween = nil
                    end
                    if activeFarmBv then
                        pcall(function() activeFarmBv:Destroy() end)
                        activeFarmBv = nil
                    end
                    if activeFarmNoclipConn then
                        pcall(function() activeFarmNoclipConn:Disconnect() end)
                        activeFarmNoclipConn = nil
                    end
                    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    local root = getLocalRoot()
                    if root then
                        if not (Config.CoinLobbyHide and inLobby and root.Position.Y < 430) then
                            root.Anchored = false
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.AssemblyAngularVelocity = Vector3.zero
                            local _, yRot, _ = root.CFrame:ToOrientation()
                            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yRot, 0)
                            if hum then
                                hum.PlatformStand = false
                                hum.Sit = false
                                pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                            end
                            cleanCharacterPhysics(LocalPlayer.Character)
                        end
                    end
                end

                if Config.CoinLobbyHide and inLobby then
                    local root = getLocalRoot()
                    if root and root.Position.Y > 430 then
                        teleportUnderLobby()
                    end
                end

                if rSecs > 0 then
                    CurrentFarmStatus = string.format("В лобби (Ожидание раунда • ⏳ %d сек)", rSecs)
                else
                    CurrentFarmStatus = "Ожидание голосования за карту 🗳️"
                end

            -- CASE 2: Match is active on server, but LocalPlayer is NOT playing (in lobby, dead, or spectator)
            elseif not isPlaying then
                if isFarmingCoin then
                    farmSessionId = farmSessionId + 1
                    isFarmingCoin = false
                    if activeCoinTween then pcall(function() activeCoinTween:Cancel() end) activeCoinTween = nil end
                    if activeFarmBv and activeFarmBv.Parent then pcall(function() activeFarmBv:Destroy() end) activeFarmBv = nil end
                    if activeFarmNoclipConn then pcall(function() activeFarmNoclipConn:Disconnect() end) activeFarmNoclipConn = nil end
                    if _G.MM2_SetTargetCoinHighlight then _G.MM2_SetTargetCoinHighlight(nil) end
                    _G.MM2_TargetCoin = nil
                    cleanCharacterPhysics(LocalPlayer.Character)
                end

                if Config.CoinLobbyHide and inLobby then
                    local root = getLocalRoot()
                    if root and root.Position.Y > 430 then
                        teleportUnderLobby()
                    end
                end

                if _G.MM2_LocalPlayerDiedThisRound and (LocalPlayer:GetAttribute("Alive") ~= true) then
                    if inLobby then
                        CurrentFarmStatus = "Вы погибли • Ожидание в лобби ⏳"
                    else
                        CurrentFarmStatus = "Вы погибли • Ожидание конца раунда ⏳"
                    end
                elseif inLobby then
                    local waited = math.floor(os.clock() - (_G.MM2_LobbyWaitStartTime or os.clock()))
                    if waited >= 40 then
                        CurrentFarmStatus = string.format("В лобби • Ожидание катки: %dс (Возможно завис?) ⏳", waited)
                    elseif rSecs > 0 then
                        CurrentFarmStatus = string.format("В лобби • Ожидание след. раунда (⏳ %d сек)", rSecs)
                    else
                        CurrentFarmStatus = "В лобби • Ожидание след. раунда ⏳"
                    end
                else
                    CurrentFarmStatus = "Ожидание вступления в игру ⏳"
                end

            -- CASE 3: LocalPlayer IS playing, but coin bag is full!
            elseif isCoinBagFull() then
                if isFarmingCoin then
                    farmSessionId = farmSessionId + 1
                    isFarmingCoin = false
                    if activeCoinTween then pcall(function() activeCoinTween:Cancel() end) activeCoinTween = nil end
                    if activeFarmBv and activeFarmBv.Parent then pcall(function() activeFarmBv:Destroy() end) activeFarmBv = nil end
                    if activeFarmNoclipConn then pcall(function() activeFarmNoclipConn:Disconnect() end) activeFarmNoclipConn = nil end
                    if _G.MM2_SetTargetCoinHighlight then _G.MM2_SetTargetCoinHighlight(nil) end
                    _G.MM2_TargetCoin = nil
                end
                executePostBagFullAction()

            -- CASE 4: LocalPlayer IS playing, but Murderer is dead/eliminated
            elseif not (_G.MM2_IsInfectionRound and _G.MM2_IsInfectionRound()) and MurdererAnnounced and isMurdererDead() then
                _G.MM2_MurdererEliminatedThisRound = true
                if isFarmingCoin then
                    farmSessionId = farmSessionId + 1
                    isFarmingCoin = false
                    if activeCoinTween then pcall(function() activeCoinTween:Cancel() end) activeCoinTween = nil end
                    if activeFarmBv and activeFarmBv.Parent then pcall(function() activeFarmBv:Destroy() end) activeFarmBv = nil end
                    if activeFarmNoclipConn then pcall(function() activeFarmNoclipConn:Disconnect() end) activeFarmNoclipConn = nil end
                    if _G.MM2_SetTargetCoinHighlight then _G.MM2_SetTargetCoinHighlight(nil) end
                    _G.MM2_TargetCoin = nil
                end
                CurrentFarmStatus = "Мардер убит • Ожидание нового раунда ⏳"
                if Config.CoinUndergroundPlatform then
                    hideSafelyUnderground("Мардер убит • Ожидание нового раунда ⏳")
                end

            -- CASE 4B: LocalPlayer IS Murderer and victims are eliminated or post-action executed!
            elseif (isPlayerMurderer(LocalPlayer) or (_G.MM2_LocalPlayerRole == "Murderer") or (detectPlayerRole(LocalPlayer) == "Murderer")) and (hasExecutedPostActionThisRound or _G.MM2_HasExecutedPostActionThisRound or (getAliveInnocentsCount and getAliveInnocentsCount() == 0)) then
                if isFarmingCoin then
                    farmSessionId = farmSessionId + 1
                    isFarmingCoin = false
                    if activeCoinTween then pcall(function() activeCoinTween:Cancel() end) activeCoinTween = nil end
                    if activeFarmBv and activeFarmBv.Parent then pcall(function() activeFarmBv:Destroy() end) activeFarmBv = nil end
                    if activeFarmNoclipConn then pcall(function() activeFarmNoclipConn:Disconnect() end) activeFarmNoclipConn = nil end
                    if _G.MM2_SetTargetCoinHighlight then _G.MM2_SetTargetCoinHighlight(nil) end
                    _G.MM2_TargetCoin = nil
                end
                CurrentFarmStatus = "Все игроки ликвидированы • Ожидание нового раунда ⏳"
                if Config.CoinUndergroundPlatform or Config.CoinFarmUnderground then
                    hideSafelyUnderground("Все игроки ликвидированы • Ожидание нового раунда ⏳")
                end

            -- CASE 5: LocalPlayer IS playing inside the match arena! Start or continue farming!
            else
                local isLocalMurd = isPlayerMurderer(LocalPlayer) or (_G.MM2_LocalPlayerRole == "Murderer") or (detectPlayerRole(LocalPlayer) == "Murderer")
                local murdFinished = isLocalMurd and (hasExecutedPostActionThisRound or _G.MM2_HasExecutedPostActionThisRound or (getAliveInnocentsCount and getAliveInnocentsCount() == 0))

                -- Auto-recover if murderer was not announced or is actually alive!
                if _G.MM2_MurdererEliminatedThisRound and (not MurdererAnnounced or (CachedMurderer and not isPlayerDead(CachedMurderer))) then
                    _G.MM2_MurdererEliminatedThisRound = false
                end

                local shouldStartFarming = not isFarmingCoin and not _G.MM2_LocalPlayerDiedThisRound and not isCoinBagFull() and not _G.MM2_MurdererEliminatedThisRound and not murdFinished
                if shouldStartFarming then
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local root = getLocalRoot()

                    if root and hum and hum.Health > 0 then
                        isFarmingCoin = true
                        farmSessionId = farmSessionId + 1
                        local thisSession = farmSessionId
                        _G.MM2_CoinBlacklist = {}
                        CachedCoinContainer = nil
                        CurrentFarmStatus = "Ожидание спавна монет ⏳"

                        -- If underground mode is on, immediately place player on safe underground platform
                        if Config.CoinUndergroundPlatform or Config.CoinFarmUnderground then
                            hideSafelyUnderground("Ожидание спавна монет ⏳")
                        end

                        task.spawn(function()
                            local farmStartTime = os.clock()
                            local noCoinTicks = 0
                            if Config.CoinFarmProne then
                                hum.PlatformStand = true
                            end

                            if activeFarmBv and activeFarmBv.Parent then
                                pcall(function() activeFarmBv:Destroy() end)
                            end
                            local farmBv = Instance.new("BodyVelocity")
                            farmBv.Name = "FarmAntiGrav"
                            farmBv.Velocity = Vector3.zero
                            farmBv.MaxForce = Vector3.new(0, 5e4, 0)
                            farmBv.Parent = root
                            activeFarmBv = farmBv

                            if activeFarmNoclipConn then
                                pcall(function() activeFarmNoclipConn:Disconnect() end)
                                activeFarmNoclipConn = nil
                            end
                            activeFarmNoclipConn = RunService.Stepped:Connect(function()
                                if thisSession ~= farmSessionId then return end
                                if not char then return end
                                if _G.MM2_FlingingActive or _G.MM2_FlingCollisionBypass then
                                    for _, p in ipairs(char:GetDescendants()) do
                                        if p:IsA("BasePart") then p.CanCollide = true end
                                    end
                                    return
                                end
                                for _, p in ipairs(char:GetDescendants()) do
                                    if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                                end
                            end)

                            local function collectTargetCoin(targetCoin)
                                if not targetCoin or not targetCoin.Parent or not root or not root.Parent then return false end
                                if isWeaponOrForbiddenItem and isWeaponOrForbiddenItem(targetCoin) then return false end
                                local serverCoinPart = (getCoinServerPart and getCoinServerPart(targetCoin)) or (targetCoin.Name == "Coin_Server" and targetCoin)
                                    or (targetCoin:IsA("BasePart") and targetCoin:FindFirstChildWhichIsA("TouchTransmitter") and targetCoin)
                                    or (targetCoin:IsA("BasePart") and targetCoin)
                                if not serverCoinPart then return false end

                                -- If coin is already dead on server, don't waste time trying to touch it
                                if (serverCoinPart:GetAttribute("Collected") == true)
                                    or (serverCoinPart:GetAttribute("Delete") == true) then
                                    _G.MM2_CoinBlacklist[targetCoin] = os.clock() + 4.0
                                    return false
                                end

                                -- Check if bag is already full
                                if isCoinBagFull() then
                                    _G.MM2_RoundLimitReached = true
                                    return false
                                end

                                -- 1. Position character at coin with user's configured Y offset
                                local yOff = tonumber(Config.CoinFarmYOffset) or -2.5
                                if Config.CoinFarmUnderground and yOff > -0.5 then
                                    yOff = -2.5
                                end
                                local targetY = serverCoinPart.Position.Y + yOff
                                if math.abs(root.Position.Y - targetY) > 0.5 then
                                    root.CFrame = CFrame.new(root.Position.X, targetY, root.Position.Z) * (root.CFrame - root.Position)
                                end
                                root.Anchored = false
                                if activeFarmBv and activeFarmBv.Parent then
                                    activeFarmBv.Velocity = Vector3.zero
                                    activeFarmBv.MaxForce = Vector3.new(0, 5e4, 0)
                                end
                                root.AssemblyLinearVelocity = Vector3.zero
                                root.AssemblyAngularVelocity = Vector3.zero
                                if hum then
                                    if Config.CoinFarmProne then
                                        hum.PlatformStand = true
                                    else
                                        hum.PlatformStand = false
                                    end
                                end

                                local curBagBefore = 0
                                pcall(function()
                                    local b = getMM2CoinBagInfo()
                                    curBagBefore = b or 0
                                end)
                                local preBagCount = (CoinTracker and CoinTracker.Amount) or 0
                                local startTime = os.clock()
                                local collected = false
                                local head = char:FindFirstChild("Head")

                                -- Clean single-target touch pulse (TouchBegin 0)
                                if firetouchinterest then
                                    pcall(function()
                                        firetouchinterest(root, serverCoinPart, 0)
                                        if head then firetouchinterest(head, serverCoinPart, 0) end
                                    end)
                                end

                                -- Adaptive verification loop based on ping (350ms to 700ms) to ensure server roundtrip succeeds
                                local ping = (_G.MM2_GetPlayerPingMs and _G.MM2_GetPlayerPingMs(LocalPlayer)) or 60
                                local maxCollectWait = math.clamp((ping / 1000) * 2.5, 0.35, 0.7)

                                while (os.clock() - startTime < maxCollectWait) do
                                    if not targetCoin.Parent
                                        or not serverCoinPart.Parent
                                        or (serverCoinPart:GetAttribute("Collected") == true)
                                        or (serverCoinPart:GetAttribute("Delete") == true)
                                        or (serverCoinPart:IsA("BasePart") and serverCoinPart:FindFirstChildWhichIsA("TouchTransmitter") == nil)
                                        or ((CoinTracker and CoinTracker.Amount or 0) > preBagCount) then
                                        collected = true
                                        break
                                    end

                                    local curBag, isFull = getMM2CoinBagInfo()
                                    if isFull or (curBag and curBag > curBagBefore) then
                                        collected = true
                                        break
                                    end

                                    task.wait(0.015)
                                end

                                -- Cleanly release touch interests (TouchEnd 1)
                                if firetouchinterest then
                                    task.spawn(function()
                                        pcall(function()
                                            firetouchinterest(root, serverCoinPart, 1)
                                            if head then firetouchinterest(head, serverCoinPart, 1) end
                                        end)
                                    end)
                                end

                                root.AssemblyLinearVelocity = Vector3.zero
                                root.AssemblyAngularVelocity = Vector3.zero

                                if collected then
                                    if _G.MM2_CoinFailCounts then _G.MM2_CoinFailCounts[targetCoin] = nil end
                                    -- Brief pause so server collection debounce resets cleanly
                                    task.wait(0.04)
                                else
                                    _G.MM2_CoinFailCounts = _G.MM2_CoinFailCounts or {}
                                    local fails = (_G.MM2_CoinFailCounts[targetCoin] or 0) + 1
                                    _G.MM2_CoinFailCounts[targetCoin] = fails
                                    if fails >= 2 then
                                        _G.MM2_CoinBlacklist[targetCoin] = os.clock() + 6.0
                                    else
                                        _G.MM2_CoinBlacklist[targetCoin] = os.clock() + 3.0
                                    end
                                end

                                return collected
                            end

                            while Config.CoinAutoFarm and (thisSession == farmSessionId) and isLocalPlayerPlayingInRound() and hum.Health > 0 and root and root.Parent do
                                -- STOP FARM IF ROUND HAS ENDED
                                if not isRoundActive() then
                                    CurrentFarmStatus = "Раунд завершен • Ожидание нового раунда ⏳"
                                    if Config.CoinUndergroundPlatform or Config.CoinFarmUnderground then
                                        hideSafelyUnderground("Раунд завершен • Ожидание нового раунда ⏳")
                                    end
                                    break
                                end

                                -- STOP FARM IF LOCAL PLAYER DIED OR NOT IN ROUND
                                if hum.Health <= 0 or (LocalPlayer:GetAttribute("Alive") == false) then
                                    _G.MM2_LocalPlayerDiedThisRound = true
                                    CurrentFarmStatus = "Вы погибли • Ожидание нового раунда ⏳"
                                    break
                                elseif not isLocalPlayerPlayingInRound() or isPlayerInLobby(LocalPlayer) then
                                    break
                                end

                                -- STOP FARM IF MURDERER IS DEAD / ELIMINATED
                                if not (_G.MM2_IsInfectionRound and _G.MM2_IsInfectionRound()) and MurdererAnnounced and isMurdererDead() then
                                    _G.MM2_MurdererEliminatedThisRound = true
                                    CurrentFarmStatus = "Мардер убит • Ожидание нового раунда ⏳"
                                    if Config.CoinUndergroundPlatform then
                                        hideSafelyUnderground("Мардер убит • Ожидание нового раунда ⏳")
                                    end
                                    break
                                end

                                -- STOP FARM IF LOCAL PLAYER IS MURDERER AND ALL TARGETS DEAD OR POST-ACTION EXECUTED
                                local isLocalMurd = isPlayerMurderer(LocalPlayer) or (_G.MM2_LocalPlayerRole == "Murderer") or (detectPlayerRole(LocalPlayer) == "Murderer")
                                if isLocalMurd then
                                    if hasExecutedPostActionThisRound or _G.MM2_HasExecutedPostActionThisRound or (getAliveInnocentsCount and getAliveInnocentsCount() == 0) then
                                        CurrentFarmStatus = "Все игроки ликвидированы • Ожидание нового раунда ⏳"
                                        if Config.CoinUndergroundPlatform or Config.CoinFarmUnderground then
                                            hideSafelyUnderground("Все игроки ликвидированы • Ожидание нового раунда ⏳")
                                        end
                                        break
                                    end
                                end

                                if Config.CoinFarmProne then
                                    hum.PlatformStand = true
                                end

                                -- Check bag status purely via attribute/isCoinBagFull
                                if isCoinBagFull() then
                                    executePostBagFullAction()
                                    break
                                end

                                -- Clean up old blacklist entries
                                if not _G.MM2_CoinBlacklist then _G.MM2_CoinBlacklist = {} end
                                local now = os.clock()
                                for c, t in pairs(_G.MM2_CoinBlacklist) do
                                    if (now > t) or not c.Parent then
                                        _G.MM2_CoinBlacklist[c] = nil
                                    end
                                end



                                if thisSession ~= farmSessionId then break end

                                -- If player returned to lobby, died, or round ended, cleanly break farm loop
                                if not isLocalPlayerPlayingInRound() then
                                    break
                                end

                                -- Fly/teleport to the closest coin
                                local coins = getActiveCoins()
                                local myPos = root.Position
                                local nearestCoin = nil
                                local nearestDist = math.huge
                                local nearestCoinPos = nil

                                for _, coin in ipairs(coins) do
                                    if coin:IsA("BasePart") and coin.Parent and not (isWeaponOrForbiddenItem and isWeaponOrForbiddenItem(coin)) then
                                        local blTime = _G.MM2_CoinBlacklist[coin]
                                        if not (blTime and (now < blTime)) then
                                            local cPos = (coin:FindFirstChild("CoinVisual") and coin.CoinVisual:IsA("BasePart") and coin.CoinVisual.Position) or coin.Position
                                            
                                            -- Safety check: avoid coins near active murderer
                                            local dangerous = false
                                            if Config.CoinFarmAvoidMurderer and CachedMurderer and CachedMurderer.Character then
                                                local mRoot = CachedMurderer.Character:FindFirstChild("HumanoidRootPart")
                                                if mRoot and not isPlayerDead(CachedMurderer) and not isPlayerInLobby(CachedMurderer) then
                                                    local distXZ = (Vector2.new(cPos.X, cPos.Z) - Vector2.new(mRoot.Position.X, mRoot.Position.Z)).Magnitude
                                                    if distXZ < 22 then
                                                        dangerous = true
                                                    end
                                                end
                                            end

                                            if not dangerous then
                                                local dist2D = (Vector2.new(cPos.X, cPos.Z) - Vector2.new(myPos.X, myPos.Z)).Magnitude
                                                local dist = dist2D + math.abs(cPos.Y - myPos.Y) * 0.5
                                                if dist < nearestDist then
                                                    nearestDist = dist
                                                    nearestCoin = coin
                                                    nearestCoinPos = cPos
                                                end
                                            end
                                        end
                                    end
                                end

                                if not nearestCoin then
                                    noCoinTicks = (noCoinTicks or 0) + 1
                                    CurrentFarmStatus = "Ожидание спавна монет ⏳"
                                    if Config.CoinUndergroundPlatform or Config.CoinFarmUnderground then
                                        hideSafelyUnderground("Ожидание спавна монет ⏳")
                                    else
                                        root.AssemblyLinearVelocity = Vector3.zero
                                        root.AssemblyAngularVelocity = Vector3.zero
                                    end
                                    task.wait(0.25)
                                else
                                    noCoinTicks = 0
                                    local coinPos = nearestCoinPos or (nearestCoin:FindFirstChild("CoinVisual") and nearestCoin.CoinVisual:IsA("BasePart") and nearestCoin.CoinVisual.Position) or nearestCoin.Position
                                    local isTeleport = (Config.CoinFarmMethod == "Teleport")
                                    local yOff = tonumber(Config.CoinFarmYOffset) or -2.5
                                    if Config.CoinFarmUnderground and yOff > -0.5 then
                                        yOff = -2.5
                                    end
                                    local approachPos = Vector3.new(coinPos.X, coinPos.Y + yOff, coinPos.Z)

                                    -- Smooth forward orientation
                                    local curPos = root.Position
                                    local moveDir = (coinPos - curPos)
                                    local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z)
                                    local targetCf
                                    if flatDir.Magnitude > 0.4 then
                                        targetCf = CFrame.lookAt(approachPos, approachPos + flatDir)
                                    else
                                        targetCf = CFrame.new(approachPos)
                                    end
                                    if Config.CoinFarmProne then
                                        hum.PlatformStand = true
                                        targetCf = targetCf * CFrame.Angles(math.rad(-90), 0, 0)
                                    else
                                        hum.PlatformStand = false
                                    end

                                    local dist = (approachPos - root.Position).Magnitude

                                    CurrentFarmStatus = "Плавный полёт к монете 🚀"
                                    _G.MM2_TargetCoin = nearestCoin
                                    if _G.MM2_SetTargetCoinHighlight then _G.MM2_SetTargetCoinHighlight(nearestCoin) end

                                    -- Physical state: unanchored, steady humanoid
                                    root.Anchored = false
                                    hum.AutoRotate = false
                                    if Config.CoinFarmProne then
                                        hum.PlatformStand = true
                                    end

                                    local speed = tonumber(Config.CoinTweenSpeed) or 26
                                    if speed < 5 then speed = 26 end
                                    if speed > 35 then speed = 35 end

                                    local startPos = root.Position
                                    local diff = (approachPos - startPos)
                                    local totalDist = diff.Magnitude
                                    local coinTakenByOther = false

                                    if isTeleport then
                                        -- TELEPORT METHOD: Instant step with safety and cooldown
                                        root.CFrame = targetCf
                                        root.AssemblyLinearVelocity = Vector3.zero
                                        root.AssemblyAngularVelocity = Vector3.zero
                                        task.wait(math.clamp(tonumber(Config.CoinTeleportCooldown) or 0.05, 0.02, 1.0))
                                    else
                                        -- TWEEN METHOD: Strict fixed speed (totalDist / speed) with linear easing
                                        local dur = math.max(totalDist / speed, 0.02)
                                        local twInfo = TweenInfo.new(dur, Enum.EasingStyle.Linear)
                                        local tw = TweenService:Create(root, twInfo, {CFrame = targetCf})
                                        activeCoinTween = tw
                                        tw:Play()

                                        -- Ensure BodyVelocity does not fight the tween
                                        if activeFarmBv and activeFarmBv.Parent then
                                            activeFarmBv.MaxForce = Vector3.zero
                                        end

                                        local startT = os.clock()
                                        local moveDir = (totalDist > 0.05) and diff.Unit or Vector3.zero
                                        local vel = moveDir * speed

                                        while tw.PlaybackState == Enum.PlaybackState.Playing and (os.clock() - startT < dur + 0.08) do
                                            RunService.Heartbeat:Wait()

                                            if (thisSession ~= farmSessionId) or not Config.CoinAutoFarm or not isLocalPlayerPlayingInRound() or hum.Health <= 0 then
                                                pcall(function() tw:Cancel() end)
                                                activeCoinTween = nil
                                                break
                                            end

                                            -- Physical velocity continuously replicating to server physics
                                            root.AssemblyLinearVelocity = vel
                                            root.AssemblyAngularVelocity = Vector3.zero

                                            -- Proactive touch sweep near arrival (<= 3.5 studs)
                                            local curDist = (approachPos - root.Position).Magnitude
                                            if curDist <= 3.5 and firetouchinterest then
                                                pcall(function()
                                                    local sp = (getCoinServerPart and getCoinServerPart(nearestCoin)) or nearestCoin
                                                    if sp and sp:IsA("BasePart") then
                                                        firetouchinterest(root, sp, 0)
                                                    end
                                                end)
                                            end

                                            -- Dynamic retargeting: check if coin was collected/destroyed while in flight
                                            local isCoinValid = nearestCoin and nearestCoin.Parent
                                            if isCoinValid then
                                                if (nearestCoin:GetAttribute("Collected") == true)
                                                    or (nearestCoin:GetAttribute("Delete") == true) then
                                                    isCoinValid = false
                                                else
                                                    local cv = nearestCoin:FindFirstChild("CoinVisual")
                                                    if cv and cv:IsA("BasePart") then
                                                        if (cv:GetAttribute("Collected") == true) or (cv:GetAttribute("Delete") == true) or (cv.Transparency >= 0.85) then
                                                            isCoinValid = false
                                                        end
                                                    end
                                                end
                                            end

                                            if not isCoinValid then
                                                coinTakenByOther = true
                                                pcall(function() tw:Cancel() end)
                                                activeCoinTween = nil
                                                if nearestCoin then _G.MM2_CoinBlacklist[nearestCoin] = os.clock() + 1.5 end
                                                break
                                            end

                                            if isCoinBagFull() then
                                                pcall(function() tw:Cancel() end)
                                                activeCoinTween = nil
                                                break
                                            end
                                        end
                                        if activeCoinTween == tw then activeCoinTween = nil end
                                    end

                                    if thisSession ~= farmSessionId then break end

                                    -- Stabilize at coin position
                                    root.AssemblyLinearVelocity = Vector3.zero
                                    root.AssemblyAngularVelocity = Vector3.zero
                                    root.Anchored = false
                                    if activeFarmBv and activeFarmBv.Parent then
                                        activeFarmBv.Velocity = Vector3.zero
                                        activeFarmBv.MaxForce = Vector3.new(0, 5e4, 0)
                                    end

                                    if _G.MM2_SetTargetCoinHighlight then _G.MM2_SetTargetCoinHighlight(nil) end
                                    _G.MM2_TargetCoin = nil

                                    -- Collect target coin if still valid
                                    if not coinTakenByOther and nearestCoin and nearestCoin.Parent and not isCoinBagFull() then
                                        collectTargetCoin(nearestCoin)
                                    end

                                    task.wait(0.01)
                                end
                            end

                            -- Cleanup on exit
                            if thisSession == farmSessionId then
                                if _G.MM2_SetTargetCoinHighlight then _G.MM2_SetTargetCoinHighlight(nil) end
                                _G.MM2_TargetCoin = nil
                                if activeCoinTween then pcall(function() activeCoinTween:Cancel() end) activeCoinTween = nil end
                                if farmBv and farmBv.Parent then pcall(function() farmBv:Destroy() end) end
                                if activeFarmBv == farmBv then activeFarmBv = nil end
                                if activeFarmNoclipConn then pcall(function() activeFarmNoclipConn:Disconnect() end) activeFarmNoclipConn = nil end
                                isFarmingCoin = false
                                cleanCharacterPhysics(char)
                                if hum then
                                    hum.AutoRotate = true
                                    hum.PlatformStand = false
                                    hum.Sit = false
                                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
                                end
                                if root then
                                    root.Anchored = false
                                    root.AssemblyLinearVelocity = Vector3.zero
                                    root.AssemblyAngularVelocity = Vector3.zero
                                    local _, yRot, _ = root.CFrame:ToOrientation()
                                    root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yRot, 0)
                                end
                            end
                        end)
                    end
                end
            end
        else
            if isFarmingCoin or activeCoinTween or activeFarmBv or UndergroundPlatform then
                if _G.MM2_StopCoinFarm then
                    _G.MM2_StopCoinFarm()
                end
            end
            CurrentFarmStatus = "Фарм выключен"
        end
    end
end)

task.spawn(function()
    if not (ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Gameplay")) then return end
    local gp = ReplicatedStorage.Remotes.Gameplay
    local isPreRevealing = false
    local function triggerInstantPreReveal()
        CoinsCollectedThisRound = 0
        if isPreRevealing then return end
        isPreRevealing = true

        task.spawn(function()
            for step = 1, 15 do
                local foundMurd = nil
                local foundSher = nil

                if CurrentRoundClient and CurrentRoundClient.PlayerData then
                    for pName, pData in pairs(CurrentRoundClient.PlayerData) do
                        if type(pData) == "table" and pData.Role then
                            local p = Players:FindFirstChild(pName)
                            if p then
                                if pData.Role == "Murderer" then foundMurd = p end
                                if pData.Role == "Sheriff" then foundSher = p end
                            end
                        end
                    end
                end

                if (not foundMurd or not foundSher) and step <= 2 and gp:FindFirstChild("GetCurrentPlayerData") then
                    pcall(function()
                        local d = gp.GetCurrentPlayerData:InvokeServer()
                        if type(d) == "table" then
                            for pName, pData in pairs(d) do
                                if type(pData) == "table" and pData.Role then
                                    local p = Players:FindFirstChild(pName)
                                    if p then
                                        if pData.Role == "Murderer" then foundMurd = p end
                                        if pData.Role == "Sheriff" then foundSher = p end
                                    end
                                end
                            end
                        end
                    end)
                end

                if not foundMurd or not foundSher then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        local r = detectPlayerRole(plr)
                        if r == "Murderer" and not foundMurd then foundMurd = plr end
                        if r == "Sheriff" and not foundSher then foundSher = plr end
                    end
                end

                if foundMurd or foundSher then
                    CachedMurderer = foundMurd
                    CachedSheriff = foundSher
                    if Config.EventNotifications then
                        if foundMurd and not MurdererAnnounced then
                            MurdererAnnounced = true
                            if foundMurd == LocalPlayer then
                                showNotification("💀 ВЫ МАРДЕР!", "Ликвидируйте всех невинных и шерифа!", Color3.fromRGB(255, 45, 60), "🔪", 5)
                            else
                                showNotification("💀 МАРДЕР ОБНАРУЖЕН!", string.format("%s — МАРДЕР! Будьте осторожны!", foundMurd.DisplayName or foundMurd.Name), Color3.fromRGB(255, 45, 60), "💀", 5)
                            end
                        end
                        if foundSher and not SheriffAnnounced then
                            SheriffAnnounced = true
                            if foundSher == LocalPlayer then
                                showNotification("🛡️ ВЫ ШЕРИФ!", "У вас револьвер! Защитите невинных!", Color3.fromRGB(45, 140, 255), "🎯", 5)
                            else
                                showNotification("🛡️ ШЕРИФ ОБНАРУЖЕН!", string.format("%s — Шериф с оружием!", foundSher.DisplayName or foundSher.Name), Color3.fromRGB(45, 140, 255), "🛡️", 5)
                            end
                        end
                    end
                    StatusText.Text = string.format("⚡ РОЛИ: 💀 %s | 🛡️ %s", foundMurd and foundMurd.Name or "None", foundSher and foundSher.Name or "None")
                    break
                end
                task.wait(0.1)
            end
            task.wait(3.5)
            isPreRevealing = false
        end)
    end

    RoundActive = false
    _G.MM2_RoundActive = false
    local RoundStartTime = 0
    local RoundDuration = 180

    local function onRoundStarted(duration, pData)
        RoundActive = true
        _G.MM2_RoundActive = true
        RoundStartTime = os.clock()
        RoundDuration = (type(duration) == "number" and duration > 0) and duration or 180

        CachedMurderer = nil
        CachedSheriff = nil
        CachedHero = nil
        CachedGunDrop = nil
        MurdererAnnounced = false
        SheriffAnnounced = false
        GunDropAnnounced = false
        MurdererDeadAnnounced = false
        LastHeroPlayer = nil
        _G.MM2_MurdererEliminatedThisRound = false
        _G.MM2_LocalPlayerDiedThisRound = false
        _G.MM2_FlingingActive = false
        _G.MM2_FlingCollisionBypass = false
        hasExecutedPostActionThisRound = false
        _G.MM2_HasExecutedPostActionThisRound = false
        _G.MM2_IsExecutingPostAction = false
        _G.MM2_LocalPlayerRole = nil

        if _G.MM2_ResetRoundCoinState then _G.MM2_ResetRoundCoinState() end
        if CurrentRoundClient and CurrentRoundClient.PlayerData and CurrentRoundClient.PlayerData[LocalPlayer.Name] then
            CurrentRoundClient.PlayerData[LocalPlayer.Name].Dead = false
            CurrentRoundClient.PlayerData[LocalPlayer.Name].Killed = false
        end
        if Config.CoinAutoFarm then
            CurrentFarmStatus = "Ожидание спавна монет ⏳"
        end

        if Config.AutoKillAllOnRoundStart then
            task.spawn(function()
                local waited = 0
                while waited < 6 and RoundActive do
                    task.wait(0.4)
                    waited = waited + 0.4
                    local myRole = detectPlayerRole(LocalPlayer)
                    local char = LocalPlayer.Character
                    local knife = (char and (char:FindFirstChild("Knife") or char:FindFirstChild("knife"))) or
                                  (LocalPlayer:FindFirstChild("Backpack") and (LocalPlayer.Backpack:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("knife")))
                    if myRole == "Murderer" or knife then
                        task.wait(0.5)
                        if _G.MM2_PerformKillAll then
                            _G.MM2_PerformKillAll()
                        end
                        break
                    end
                end
            end)
        end
    end

    local function onRoundEnded()
        RoundActive = false
        _G.MM2_RoundActive = false
        GunHasDropped = false
        LastHeroPlayer = nil
        CachedGunDrop = nil
        GunDropAnnounced = false
        RoundStartTime = 0

        CachedMurderer = nil
        CachedSheriff = nil
        CachedHero = nil
        MurdererAnnounced = false
        SheriffAnnounced = false
        MurdererDeadAnnounced = false
        _G.MM2_MurdererEliminatedThisRound = false
        _G.MM2_LocalPlayerDiedThisRound = false
        _G.MM2_FlingingActive = false
        _G.MM2_FlingCollisionBypass = false
        hasExecutedPostActionThisRound = false
        _G.MM2_HasExecutedPostActionThisRound = false
        _G.MM2_IsExecutingPostAction = false
        _G.MM2_LocalPlayerRole = nil

        if _G.MM2_ResetRoundCoinState then _G.MM2_ResetRoundCoinState() end
        if CurrentRoundClient and CurrentRoundClient.PlayerData and CurrentRoundClient.PlayerData[LocalPlayer.Name] then
            CurrentRoundClient.PlayerData[LocalPlayer.Name].Dead = false
            CurrentRoundClient.PlayerData[LocalPlayer.Name].Killed = false
        end
        if _G.MM2_SetTargetCoinHighlight then _G.MM2_SetTargetCoinHighlight(nil) end

        -- Clear all Coin ESP immediately at round end!
        for _, v in pairs(ActiveCoinESP) do
            if v.Billboard then pcall(function() v.Billboard:Destroy() end) end
        end
        table.clear(ActiveCoinESP)

        -- Stop active farming tween and flight
        if activeCoinTween then
            pcall(function() activeCoinTween:Cancel() end)
            activeCoinTween = nil
        end
        if activeFarmBv and activeFarmBv.Parent then
            pcall(function() activeFarmBv:Destroy() end)
            activeFarmBv = nil
        end
        if activeFarmNoclipConn then
            pcall(function() activeFarmNoclipConn:Disconnect() end)
            activeFarmNoclipConn = nil
        end
        isFarmingCoin = false

        if Config.CoinAutoFarm and Config.CoinLobbyHide then
            task.spawn(function()
                task.wait(0.5)
                if Config.CoinAutoFarm and Config.CoinLobbyHide and _G.MM2_TeleportUnderLobby and isPlayerInLobby(LocalPlayer) then
                    _G.MM2_TeleportUnderLobby()
                end
            end)
        end

        CurrentFarmStatus = "Ожидание голосования за карту 🗳️"
    end

    local rtp = workspace:FindFirstChild("RoundTimerPart")
    if rtp then
        local lastRtpTime = 0
        local function checkRtp()
            local t = rtp:GetAttribute("Time")
            if type(t) == "number" then
                if t > 0 and (not RoundActive or t > (lastRtpTime + 20)) then
                    onRoundStarted(t)
                    triggerInstantPreReveal()
                elseif t <= 0 and RoundActive then
                    onRoundEnded()
                end
                lastRtpTime = t
            end
        end
        addConn(rtp:GetAttributeChangedSignal("Time"):Connect(checkRtp))
        checkRtp()
    end

    if gp:FindFirstChild("RoundStart") then
        addConn(gp.RoundStart.OnClientEvent:Connect(function(duration, pData)
            onRoundStarted(duration, pData)
            triggerInstantPreReveal()
        end))
    end
    if gp:FindFirstChild("RoundEndFade") then
        addConn(gp.RoundEndFade.OnClientEvent:Connect(onRoundEnded))
    end
    if gp:FindFirstChild("VictoryScreen") then
        addConn(gp.VictoryScreen.OnClientEvent:Connect(onRoundEnded))
    end
    if gp:FindFirstChild("GameOver") then
        addConn(gp.GameOver.OnClientEvent:Connect(onRoundEnded))
    end
    if gp:FindFirstChild("RoleSelect") then
        addConn(gp.RoleSelect.OnClientEvent:Connect(triggerInstantPreReveal))
    end
    if gp:FindFirstChild("PlayerDataChanged") then
        addConn(gp.PlayerDataChanged.OnClientEvent:Connect(function(newTable)
            if type(newTable) == "table" and CurrentRoundClient then
                CurrentRoundClient.PlayerData = newTable
                if newTable[LocalPlayer.Name] then
                    local myData = newTable[LocalPlayer.Name]
                    if isRoundActive() and (myData.Dead == true or myData.Killed == true) then
                        _G.MM2_LocalPlayerDiedThisRound = true
                        pcall(function() LocalPlayer:SetAttribute("Alive", false) end)
                    elseif isRoundActive() and myData.Dead == false and myData.Killed == false then
                        _G.MM2_LocalPlayerDiedThisRound = false
                        pcall(function() LocalPlayer:SetAttribute("Alive", true) end)
                    end
                end
            end
            triggerInstantPreReveal()
        end))
    end
    if gp:FindFirstChild("ShowRoleSelectNew") then
        addConn(gp.ShowRoleSelectNew.OnClientEvent:Connect(triggerInstantPreReveal))
    end
    if CurrentRoundClient and CurrentRoundClient.PlayerDataChanged then
        addConn(CurrentRoundClient.PlayerDataChanged.Event:Connect(function()
            if CurrentRoundClient.PlayerData and CurrentRoundClient.PlayerData[LocalPlayer.Name] then
                local myData = CurrentRoundClient.PlayerData[LocalPlayer.Name]
                if isRoundActive() and (myData.Dead == true or myData.Killed == true) then
                    _G.MM2_LocalPlayerDiedThisRound = true
                    pcall(function() LocalPlayer:SetAttribute("Alive", false) end)
                elseif isRoundActive() and myData.Dead == false and myData.Killed == false then
                    _G.MM2_LocalPlayerDiedThisRound = false
                    pcall(function() LocalPlayer:SetAttribute("Alive", true) end)
                end
            end
            triggerInstantPreReveal()
        end))
    end
    if gp:FindFirstChild("CoinsStarted") then
        addConn(gp.CoinsStarted.OnClientEvent:Connect(function(bags)
            if _G.MM2_ResetRoundCoinState then _G.MM2_ResetRoundCoinState() end
        end))
    end

    -- Hook LocalPlayer death during active round
    local function setupLocalDeathListener(c)
        if not c then return end
        local h = c:WaitForChild("Humanoid", 3)
        if h then
            addConn(h.Died:Connect(function()
                if isRoundActive() then
                    _G.MM2_LocalPlayerDiedThisRound = true
                    pcall(function() LocalPlayer:SetAttribute("Alive", false) end)
                    if _G.MM2_StopCoinFarm then _G.MM2_StopCoinFarm() end
                    CurrentFarmStatus = "Вы погибли • Ожидание нового раунда ⏳"
                end
            end))
        end
    end
    if LocalPlayer.Character then setupLocalDeathListener(LocalPlayer.Character) end
    addConn(LocalPlayer.CharacterAdded:Connect(function(newChar)
        setupLocalDeathListener(newChar)
        if LocalPlayer:GetAttribute("Alive") == true then
            _G.MM2_LocalPlayerDiedThisRound = false
        end
    end))

    -- Synchronize and react to official MM2 Alive attribute changes
    addConn(LocalPlayer:GetAttributeChangedSignal("Alive"):Connect(function()
        local isAlive = (LocalPlayer:GetAttribute("Alive") == true)
        if isAlive then
            -- Authoritative: Whenever server marks player as Alive, immediately clear died states!
            _G.MM2_LocalPlayerDiedThisRound = false
            _G.MM2_RoundLimitReached = false
            _G.MM2_MurdererEliminatedThisRound = false
            hasExecutedPostActionThisRound = false
            CoinsCollectedThisRound = 0
            CoinTracker.LastProcessedAmt = 0
            CoinTracker.Amount = 0
            pcall(function()
                LocalPlayer:SetAttribute("BagFull", false)
                LocalPlayer:SetAttribute("CoinBagFull", false)
            end)
            task.spawn(function()
                task.wait(0.35)
                if Config.CoinAutoFarm and (LocalPlayer:GetAttribute("Alive") == true) and isRoundActive() and not isPlayerInLobby(LocalPlayer) and Config.CoinUndergroundPlatform and Config.CoinFarmUnderground then
                    pcall(function()
                        if hideSafelyUnderground then
                            hideSafelyUnderground("Начало раунда • Уход под карту 🛡️")
                        end
                    end)
                end
            end)
        else
            if isRoundActive() and not isPlayerInLobby(LocalPlayer) then
                _G.MM2_LocalPlayerDiedThisRound = true
            end
            _G.MM2_RoundLimitReached = false
            hasExecutedPostActionThisRound = false
            CoinsCollectedThisRound = 0
            CoinTracker.LastProcessedAmt = 0
            CoinTracker.Amount = 0
            pcall(function()
                LocalPlayer:SetAttribute("BagFull", false)
                LocalPlayer:SetAttribute("CoinBagFull", false)
            end)
            if isFarmingCoin then
                farmSessionId = farmSessionId + 1
                isFarmingCoin = false
            end
        end
    end))

    -- 🪙 Direct Listener to Official MM2 Coin GUI (Detect BagFull state without fake coin polls)
    task.spawn(function()
        local function setupCoinGuiHooks()
            local p = LocalPlayer
            local pg = p and p:FindFirstChild("PlayerGui")
            local mg = pg and pg:FindFirstChild("MainGUI")
            local gm = mg and mg:FindFirstChild("Game")
            local cb = gm and gm:FindFirstChild("CoinBags")
            local container = cb and cb:FindFirstChild("Container")
            if container then
                for _, bag in ipairs(container:GetChildren()) do
                    if bag:IsA("Frame") and bag.Visible then
                        local fullLbl = bag:FindFirstChild("Full", true)
                        local fullIcon = bag:FindFirstChild("FullBagIcon", true)
                        if (fullLbl and fullLbl.Visible == true) or (fullIcon and fullIcon.Visible == true) then
                            LocalPlayer:SetAttribute("BagFull", true)
                            LocalPlayer:SetAttribute("CoinBagFull", true)
                            _G.MM2_RoundLimitReached = true
                        end
                        if fullLbl and fullLbl:IsA("GuiObject") then
                            addConn(fullLbl:GetPropertyChangedSignal("Visible"):Connect(function()
                                if bag.Visible and fullLbl.Visible == true then
                                    LocalPlayer:SetAttribute("BagFull", true)
                                    LocalPlayer:SetAttribute("CoinBagFull", true)
                                    _G.MM2_RoundLimitReached = true
                                elseif fullLbl.Visible == false then
                                    LocalPlayer:SetAttribute("BagFull", false)
                                    LocalPlayer:SetAttribute("CoinBagFull", false)
                                    _G.MM2_RoundLimitReached = false
                                end
                            end))
                        end
                    end
                end
            end
        end
        pcall(setupCoinGuiHooks)
        if LocalPlayer:FindFirstChild("PlayerGui") then
            addConn(LocalPlayer.PlayerGui.DescendantAdded:Connect(function(desc)
                if desc.Name == "Full" or desc.Name == "FullBagIcon" then
                    pcall(setupCoinGuiHooks)
                end
            end))
        end
    end)
end)

-- ====================================================================
-- ⚡ 2D DRAWING & SILENT AIM VISUALS RENDER LOOP
-- ====================================================================
local IslandTelemetryData = {
    frameCount = 0,
    lastTime = os.clock(),
    fps = 60,
    ping = 0
}

addConn(RunService.RenderStepped:Connect(function()
    -- 0. Dynamic Island Telemetry & Clock (Optimized 4Hz string updates for FPS/Ping, real-time clock & round timer)
    local nowClock = os.clock()
    if DynamicIsland and DynamicIsland.Visible then
        if nowClock - (IslandTelemetryData.lastClock or 0) >= 0.25 then
            IslandTelemetryData.lastClock = nowClock
            if diTimeText and (Config.IslandShowTime ~= false) then
                local curTimeStr = "🕒 " .. os.date("%H:%M:%S")
                if diTimeText.Text ~= curTimeStr then
                    diTimeText.Text = curTimeStr
                end
            end

            -- Round Timer telemetry update (authoritative sync with workspace.RoundTimerPart)
            if diRoundText and (Config.IslandShowRoundTimer ~= false) then
                local rtp = workspace:FindFirstChild("RoundTimerPart")
                local rtpTime = rtp and rtp:GetAttribute("Time")

                if rtpTime and type(rtpTime) == "number" and rtpTime >= 0 then
                    local remaining = math.floor(rtpTime)
                    local mins = math.floor(remaining / 60)
                    local secs = remaining % 60
                    diRoundText.Text = string.format("⏳ %02d:%02d", mins, secs)
                    if remaining <= 30 then
                        diRoundText.TextColor3 = Color3.fromRGB(255, 65, 75)
                    elseif remaining <= 60 then
                        diRoundText.TextColor3 = Color3.fromRGB(255, 205, 45)
                    else
                        diRoundText.TextColor3 = Color3.fromRGB(130, 225, 255)
                    end
                else
                    if isRoundActive() then
                        diRoundText.Text = "⏳ In Game"
                        diRoundText.TextColor3 = Color3.fromRGB(130, 225, 255)
                    else
                        diRoundText.Text = "⏳ Lobby"
                        diRoundText.TextColor3 = Color3.fromRGB(160, 180, 210)
                    end
                end
            end
        end

        IslandTelemetryData.frameCount = IslandTelemetryData.frameCount + 1
        local nowClock = os.clock()
        if nowClock - IslandTelemetryData.lastTime >= 1.0 then
            local deltaClock = nowClock - IslandTelemetryData.lastTime
            IslandTelemetryData.fps = math.clamp(math.floor((IslandTelemetryData.frameCount / deltaClock) + 0.5), 1, 999)
            IslandTelemetryData.frameCount = 0
            IslandTelemetryData.lastTime = nowClock

            pcall(function()
                local stats = game:GetService("Stats")
                local net = stats:FindFirstChild("Network")
                local sStats = net and net:FindFirstChild("ServerStatsItem")
                local pingItem = sStats and sStats:FindFirstChild("Data Ping")
                if pingItem then
                    IslandTelemetryData.ping = math.clamp(math.floor(pingItem:GetValue()), 0, 9999)
                end
            end)

            if diFpsText then
                diFpsText.Text = string.format("⚡ %d", IslandTelemetryData.fps)
                if IslandTelemetryData.fps >= 50 then
                    diFpsText.TextColor3 = Color3.fromRGB(50, 225, 125)
                elseif IslandTelemetryData.fps >= 30 then
                    diFpsText.TextColor3 = Color3.fromRGB(255, 205, 45)
                else
                    diFpsText.TextColor3 = Color3.fromRGB(255, 70, 75)
                end
            end

            if diPingText then
                diPingText.Text = string.format("📶 %dms", IslandTelemetryData.ping)
                if IslandTelemetryData.ping <= 85 then
                    diPingText.TextColor3 = Color3.fromRGB(50, 225, 125)
                elseif IslandTelemetryData.ping <= 160 then
                    diPingText.TextColor3 = Color3.fromRGB(255, 205, 45)
                else
                    diPingText.TextColor3 = Color3.fromRGB(255, 70, 75)
                end
            end
        end
    end

    local myRoot = getLocalRoot()
    local myPos = myRoot and myRoot.Position or Vector3.zero
    local viewport = Camera.ViewportSize
    local origin = Vector2.new(viewport.X / 2, viewport.Y - 10)
    if nowClock - (IslandTelemetryData.lastRoleTime or 0) >= 0.2 then
        IslandTelemetryData.lastRoleTime = nowClock
        IslandTelemetryData.cachedMyRole = _G.MM2_LocalPlayerRole or (detectPlayerRole and detectPlayerRole(LocalPlayer)) or "None"
    end
    local myRole = IslandTelemetryData.cachedMyRole or "None" 

    -- 1. Murderer Tracer (Strictly ignore LocalPlayer, dead, and lobby)
    if Config.Tracers and CachedMurderer and CachedMurderer ~= LocalPlayer and CachedMurderer.Character and CachedMurderer.Character:FindFirstChild("HumanoidRootPart") and not isPlayerInLobby(CachedMurderer) and not isPlayerDead(CachedMurderer) then
        local mRoot = CachedMurderer.Character.HumanoidRootPart
        local screenPos, onScreen = Camera:WorldToViewportPoint(mRoot.Position)

        if onScreen then
            MurdererTracer.Visible = true
            MurdererTracer.From = origin
            MurdererTracer.To = Vector2.new(screenPos.X, screenPos.Y)
        else
            MurdererTracer.Visible = false
        end
    else
        MurdererTracer.Visible = false
    end

    -- 2. Sheriff Tracer (Strictly ignore LocalPlayer, dead, and lobby)
    if Config.Tracers and CachedSheriff and CachedSheriff ~= LocalPlayer and CachedSheriff.Character and CachedSheriff.Character:FindFirstChild("HumanoidRootPart") and not isPlayerInLobby(CachedSheriff) and not isPlayerDead(CachedSheriff) then
        local sRoot = CachedSheriff.Character.HumanoidRootPart
        local screenPos, onScreen = Camera:WorldToViewportPoint(sRoot.Position)

        if onScreen then
            SheriffTracer.Visible = true
            SheriffTracer.From = origin
            SheriffTracer.To = Vector2.new(screenPos.X, screenPos.Y)
        else
            SheriffTracer.Visible = false
        end
    else
        SheriffTracer.Visible = false
    end

    -- 3. Dynamic Off-Screen Radar Arrows for Murderer AND Sheriff
    local function updateOffscreenArrow(arrowObj, textObj, targetPlr, targetColor, targetIcon, radiusScale)
        if not (Config.OffscreenRadar and targetPlr and targetPlr ~= LocalPlayer and targetPlr.Character) then
            arrowObj.Visible = false
            textObj.Visible = false
            return
        end

        if isPlayerInLobby(targetPlr) or isPlayerDead(targetPlr) then
            arrowObj.Visible = false
            textObj.Visible = false
            return
        end

        local tRoot = targetPlr.Character:FindFirstChild("HumanoidRootPart") or targetPlr.Character:FindFirstChild("Head")
        if not tRoot then
            arrowObj.Visible = false
            textObj.Visible = false
            return
        end

        local proj, onScreen = Camera:WorldToViewportPoint(tRoot.Position)
        if onScreen then
            arrowObj.Visible = false
            textObj.Visible = false
            return
        end

        local center = viewport / 2
        local dir
        if proj.Z < 0 then
            dir = Vector2.new(center.X - proj.X, center.Y - proj.Y)
        else
            dir = Vector2.new(proj.X - center.X, proj.Y - center.Y)
        end

        if dir.Magnitude < 0.001 then
            dir = Vector2.new(0, 1)
        else
            dir = dir.Unit
        end

        local radius = math.min(center.X, center.Y) * (radiusScale or 0.72)
        local arrowPos = center + dir * radius

        local arrowLength = 20
        local arrowWidth = 12
        local tip = arrowPos + dir * (arrowLength * 0.5)
        local base = arrowPos - dir * (arrowLength * 0.5)
        local perp = Vector2.new(-dir.Y, dir.X) * (arrowWidth * 0.5)

        arrowObj.PointA = tip
        arrowObj.PointB = base + perp
        arrowObj.PointC = base - perp
        arrowObj.Color = targetColor
        arrowObj.Visible = true

        local dist = math.floor((tRoot.Position - myPos).Magnitude)
        textObj.Position = arrowPos - dir * 26 - Vector2.new(0, 7)
        textObj.Text = string.format("%s %dm", targetIcon, dist)
        textObj.Color = targetColor
        textObj.Visible = true
    end

    if Config.OffscreenRadar then
        -- Стрелка на Мардера (Красная 💀)
        updateOffscreenArrow(MurdererArrow, MurdererArrowText, CachedMurderer, Color3.fromRGB(255, 45, 60), "💀", 0.72)
        -- Стрелка на Шерифа (Синяя 🛡️)
        updateOffscreenArrow(SheriffArrow, SheriffArrowText, CachedSheriff, Color3.fromRGB(45, 140, 255), "🛡️", 0.64)
    else
        MurdererArrow.Visible = false
        MurdererArrowText.Visible = false
        SheriffArrow.Visible = false
        SheriffArrowText.Visible = false
    end

    -- 4. Silent Aim Target ESP & Nametag
    local canShowSilentAimVisuals = Config.SilentAim and Config.SilentAimVisuals
    if canShowSilentAimVisuals and Config.SilentAimWeaponOnly then
        if not hasWeaponInHand() then
            canShowSilentAimVisuals = false
        end
    end

    if canShowSilentAimVisuals then
        local target = getSilentAimTarget()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local tRoot = target.Character.HumanoidRootPart
            local tHead = target.Character:FindFirstChild("Head") or tRoot
            local dist = math.floor((tRoot.Position - myPos).Magnitude)

            -- Update 3D Nametag (cleanly elevated with distance compensation)
            SilentAimBillboard.Adornee = tHead
            local sYOff = 3.6 + math.max(2.4, dist * 0.15)
            SilentAimBillboard.StudsOffset = Vector3.new(0, sYOff, 0)
            if SAB_Frame:FindFirstChild("Avatar") and target.UserId then
                local thumb = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(target.UserId) .. "&w=100&h=100"
                if SAB_Frame.Avatar.Image ~= thumb then
                    SAB_Frame.Avatar.Image = thumb
                end
            end
            SAB_Title.Text = target.DisplayName or target.Name
            local actionStatus = (myRole == "Murderer") and "Throw" or "Shoot"
            local tPing = (_G.MM2_GetPlayerPingMs and _G.MM2_GetPlayerPingMs(target, target.Character)) or 50
            SAB_Sub.Text = string.format("🎯 %s • %dms • %dm", actionStatus, tPing, dist)
            SilentAimBillboard.Enabled = true

            -- 2D Screen Lock Reticle
            local screenPos, onScreen = Camera:WorldToViewportPoint(tHead.Position)
            if onScreen then
                SilentAimCircle.Position = Vector2.new(screenPos.X, screenPos.Y)
                SilentAimCircle.Visible = true

                SilentAimLockText.Position = Vector2.new(screenPos.X, screenPos.Y - 26)
                SilentAimLockText.Text = string.format("[ 🎯 LOCKED: %s ]", target.Name:upper())
                SilentAimLockText.Visible = true
            else
                SilentAimCircle.Visible = false
                SilentAimLockText.Visible = false
            end
        else
            SilentAimBillboard.Enabled = false
            SilentAimCircle.Visible = false
            SilentAimLockText.Visible = false
        end
    else
        SilentAimBillboard.Enabled = false
        SilentAimCircle.Visible = false
        SilentAimLockText.Visible = false
    end

    -- 5. Murderer Long-Range Strike: Cursor Hover Target Highlight & Billboard
    if myRole == "Murderer" and Config.KnifeReachHighlight ~= false and not isPlayerInLobby(LocalPlayer) then
        local hovered = getHoveredVictim()
        if hovered and hovered.Character and hovered.Character:FindFirstChild("HumanoidRootPart") then
            local hRoot = hovered.Character.HumanoidRootPart
            local hHead = hovered.Character:FindFirstChild("Head") or hRoot
            local hDist = math.floor((hRoot.Position - myPos).Magnitude)

            KnifeHoverHighlight.Adornee = hovered.Character
            KnifeHoverHighlight.Enabled = true

            local targetMode = Config.KnifeTargetHUDMode or "Above"
            if targetMode == "IslandOnly" then
                KnifeLockBillboard.Enabled = false
            elseif targetMode == "Below" then
                KnifeLockBillboard.Adornee = hRoot
                local yOff = -2.8 - math.max(0.6, hDist * 0.08)
                KnifeLockBillboard.StudsOffset = Vector3.new(0, yOff, 0)
                KLB_Title.Text = string.format("🗡️ TARGET: %s", hovered.Name:upper())
                KLB_Sub.Text = string.format("%dm • Press [%s] to Strike", hDist, Config.KnifeReachKeybind or "F")
                KnifeLockBillboard.Enabled = true
            elseif targetMode == "Side" then
                KnifeLockBillboard.Adornee = hHead
                local xOff = math.max(3.2, hDist * 0.12)
                KnifeLockBillboard.StudsOffset = Vector3.new(xOff, 3.4, 0)
                KLB_Title.Text = string.format("🗡️ TARGET: %s", hovered.Name:upper())
                KLB_Sub.Text = string.format("%dm • Press [%s] to Strike", hDist, Config.KnifeReachKeybind or "F")
                KnifeLockBillboard.Enabled = true
            else -- "Above" (Default: distance-compensated elevation so it NEVER obscures the NameTag!)
                KnifeLockBillboard.Adornee = hHead
                local yOff = 3.6 + math.max(2.6, hDist * 0.16)
                KnifeLockBillboard.StudsOffset = Vector3.new(0, yOff, 0)
                KLB_Title.Text = string.format("🗡️ TARGET: %s", hovered.Name:upper())
                KLB_Sub.Text = string.format("%dm • Press [%s] to Strike", hDist, Config.KnifeReachKeybind or "F")
                KnifeLockBillboard.Enabled = true
            end

            if diStatusText and Config.IslandShowStatus ~= false then
                diStatusText.Text = string.format("🗡️ Lock: %s (%dm) [%s]", hovered.Name, hDist, Config.KnifeReachKeybind or "F")
                diStatusText.TextColor3 = Color3.fromRGB(255, 95, 115)
            end
        else
            KnifeHoverHighlight.Enabled = false
            KnifeLockBillboard.Enabled = false
        end
    else
        KnifeHoverHighlight.Enabled = false
        KnifeLockBillboard.Enabled = false
    end

    -- 6. Knife Aura 3D Radius Circle on Ground
    if _G.MM2_KnifeAuraCircle then
        if Config.KnifeAura and (Config.KnifeAuraShowRadius ~= false) and (myRole == "Murderer") and myRoot and not isPlayerInLobby(LocalPlayer) then
            _G.MM2_KnifeAuraCircle.Adornee = myRoot
            _G.MM2_KnifeAuraCircle.Radius = Config.KnifeAuraRadius or 24
            _G.MM2_KnifeAuraCircle.Visible = true
        else
            _G.MM2_KnifeAuraCircle.Visible = false
        end
    end
end))

-- ====================================================================
-- 🌟 MASTER SUITE: HITMARKER, TRAP ESP & DISARM, AUTO-PRESTIGE,
--    CINEMATIC COIN CAMERA, AND MM2 EMOTES & FUN
-- ====================================================================
;(function()
    -- Hitmarker & Death effects completely removed per user request
    _G.MM2_TriggerLocalHitmarker = function() end
    _G.MM2_TriggerLocalKillEffect = function() end
    _G.MM2_TriggerHitmarker = function() end
    _G.MM2_TestHitmarkerSound = function() end
    _G.MM2_TestKillEffect = function() end
end)()
;(function()
    -- ====================================================================
    -- 🌟 WORLD VISUALS & PERFORMANCE ENGINE (Jump Circles, Trail, Glow, FOV, Ambience & FPS Booster)
    -- ====================================================================
    -- 0. Bullet Tracers, Impact Rings & Knife Visuals
    local function getTracerColor()
        local cName = Config.BulletTracerColor or "Electric Cyan"
        if cName == "Electric Cyan" then
            return Color3.fromRGB(0, 230, 255)
        elseif cName == "Neon Crimson" then
            return Color3.fromRGB(255, 35, 65)
        elseif cName == "Plasma Purple" then
            return Color3.fromRGB(190, 60, 255)
        elseif cName == "Golden Spark" then
            return Color3.fromRGB(255, 215, 40)
        elseif cName == "Emerald Green" then
            return Color3.fromRGB(45, 255, 120)
        elseif cName == "Rainbow Chroma" then
            return Color3.fromHSV((tick() * 0.75) % 1, 0.9, 1)
        end
        local th = UIThemes[Config.UITheme] or UIThemes["Red"]
        return th.Accent or th.Main
    end

    local function spawnImpactRing(pos, normal, color)
        if Config.BulletImpactRings == false then return end
        if not pos then return end
        pcall(function()
            local ring = Instance.new("Part")
            ring.Name = "MM2_BulletImpactRing"
            ring.Anchored = true
            ring.CanCollide = false
            ring.CanTouch = false
            ring.CanQuery = false
            ring.CastShadow = false
            ring.Material = Enum.Material.Neon
            ring.Color = color or getTracerColor()
            ring.Transparency = 0.1
            ring.Size = Vector3.new(0.04, 0.6, 0.6)

            local lookDir = (normal and normal.Magnitude > 0.01) and normal.Unit or Vector3.new(0, 1, 0)
            ring.CFrame = CFrame.lookAt(pos, pos + lookDir) * CFrame.Angles(0, 0, math.rad(90))

            local mesh = Instance.new("SpecialMesh", ring)
            mesh.MeshType = Enum.MeshType.Cylinder

            ring.Parent = workspace.Terrain or workspace

            local tw = TweenService:Create(ring, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = Vector3.new(0.01, 4.5, 4.5),
                Transparency = 1
            })
            tw:Play()
            task.delay(0.38, function()
                pcall(function() ring:Destroy() end)
            end)
        end)
    end

    local function resolveVector3(val)
        if not val then return nil end
        if typeof(val) == "Vector3" then
            return val
        elseif typeof(val) == "CFrame" then
            return val.Position
        elseif typeof(val) == "Instance" then
            if val:IsA("Attachment") then
                return val.WorldPosition
            elseif val:IsA("BasePart") then
                return val.Position
            elseif val:IsA("Tool") or val:IsA("Model") then
                local att = val:FindFirstChild("GunRaycastAttachment", true)
                if att and att:IsA("Attachment") then return att.WorldPosition end
                local handle = val:FindFirstChild("Handle") or val:FindFirstChildWhichIsA("BasePart")
                if handle then return handle.Position end
            end
        end
        return nil
    end

    local function spawnBulletTracer(rawStart, rawEnd, customColor)
        if Config.BulletTracers == false then return end
        local startPos = resolveVector3(rawStart)
        local endPos = resolveVector3(rawEnd)
        if not startPos or not endPos then return end

        local dist = (endPos - startPos).Magnitude
        if dist < 0.6 then return end

        local color = customColor or getTracerColor()
        local thickness = math.clamp((tonumber(Config.BulletTracerThickness) or 0.3), 0.1, 1.5)
        local lifetime = math.clamp((tonumber(Config.BulletTracerLifetime) or 0.85), 0.2, 3.5)

        pcall(function()
            -- 1. High-Intensity 3D Neon Cylinder Core (Properly aligned along bullet trajectory)
            local laser = Instance.new("Part")
            laser.Name = "MM2_BulletTracer"
            laser.Anchored = true
            laser.CanCollide = false
            laser.CanTouch = false
            laser.CanQuery = false
            laser.CastShadow = false
            laser.Material = Enum.Material.Neon
            laser.Color = color
            laser.Transparency = 0.05
            laser.Size = Vector3.new(dist, thickness, thickness)
            laser.CFrame = CFrame.lookAt((startPos + endPos) / 2, endPos) * CFrame.Angles(0, math.rad(90), 0)

            local mesh = Instance.new("SpecialMesh", laser)
            mesh.MeshType = Enum.MeshType.Cylinder
            laser.Parent = workspace.Terrain or workspace

            -- 2. Vibrant Camera-Facing Glowing Beam between anchor points
            local p0 = Instance.new("Part")
            p0.Name = "MM2_LaserAnchor0"
            p0.Transparency = 1
            p0.Anchored = true
            p0.CanCollide = false
            p0.CanTouch = false
            p0.CanQuery = false
            p0.Size = Vector3.new(0.05, 0.05, 0.05)
            p0.CFrame = CFrame.new(startPos)
            p0.Parent = workspace.Terrain or workspace

            local a0 = Instance.new("Attachment", p0)

            local p1 = Instance.new("Part")
            p1.Name = "MM2_LaserAnchor1"
            p1.Transparency = 1
            p1.Anchored = true
            p1.CanCollide = false
            p1.CanTouch = false
            p1.CanQuery = false
            p1.Size = Vector3.new(0.05, 0.05, 0.05)
            p1.CFrame = CFrame.new(endPos)
            p1.Parent = workspace.Terrain or workspace

            local a1 = Instance.new("Attachment", p1)

            local beam = Instance.new("Beam")
            beam.Name = "LaserGlow"
            beam.Attachment0 = a0
            beam.Attachment1 = a1
            beam.FaceCamera = true
            beam.LightEmission = 1.0
            beam.LightInfluence = 0
            beam.Width0 = thickness * 2.2
            beam.Width1 = thickness * 2.2
            beam.Color = ColorSequence.new(color)
            beam.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.05),
                NumberSequenceKeypoint.new(0.85, 0.2),
                NumberSequenceKeypoint.new(1, 0.5)
            })
            beam.Parent = p0

            -- 3. Smooth fade out tween
            local tw1 = TweenService:Create(laser, TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Transparency = 1,
                Size = Vector3.new(dist, 0.01, 0.01)
            })
            local tw2 = TweenService:Create(beam, TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Width0 = 0,
                Width1 = 0
            })
            tw1:Play()
            tw2:Play()

            -- 4. Impact shockwave ring at bullet hit point
            local dir = (endPos - startPos).Unit
            spawnImpactRing(endPos, dir, color)

            task.delay(lifetime + 0.08, function()
                pcall(function() laser:Destroy() end)
                pcall(function() p0:Destroy() end)
                pcall(function() p1:Destroy() end)
            end)
        end)
    end
    _G.MM2_SpawnBulletTracer = spawnBulletTracer

    -- Multi-source Authoritative Gun Listeners (Captures all local and remote gunshots)
    task.spawn(function()
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local wsObj = rs:WaitForChild("ClientServices", 8) and rs.ClientServices:WaitForChild("WeaponService", 8)
            if wsObj then
                local weaponService = require(wsObj)
                if weaponService and weaponService.GunFired then
                    weaponService.GunFired.OnClientEvent:Connect(function(gunTool, startPos, endPos, hitInfo)
                        if Config.BulletTracers ~= false then
                            spawnBulletTracer(startPos, endPos)
                        end
                    end)
                end
            end
        end)
    end)

    task.spawn(function()
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local we = rs:WaitForChild("WeaponEvents", 8)
            local gb = we and we:WaitForChild("GunBeam", 5)
            if gb and gb:IsA("RemoteEvent") then
                gb.OnClientEvent:Connect(function(startPos, endPos, customColor)
                    if Config.BulletTracers ~= false then
                        spawnBulletTracer(startPos, endPos, customColor)
                    end
                end)
            end
        end)
    end)

    -- Local Tool Activated Listener (Instant 0ms tracers for manual mouse clicks)
    local function hookGunToolLocal(tool)
        if not tool or not tool:IsA("Tool") then return end
        local shootEvent = tool:FindFirstChild("Shoot") or tool:FindFirstChild("shoot") or tool:FindFirstChild("GunClient")
        if not shootEvent and not tool.Name:lower():find("gun") and not tool.Name:lower():find("revolver") then return end

        tool.Activated:Connect(function()
            if Config.BulletTracers ~= false then
                task.spawn(function()
                    task.wait(0.015)
                    local cam = workspace.CurrentCamera
                    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
                    local att = handle and handle:FindFirstChild("GunRaycastAttachment")
                    local sPos = att and att.WorldPosition or (handle and handle.Position) or (cam and cam.CFrame.Position)
                    if sPos and cam then
                        local mousePos = UserInputService:GetMouseLocation()
                        local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        local hit = workspace:Raycast(ray.Origin, ray.Direction * 400, rayParams)
                        local ePos = hit and hit.Position or (ray.Origin + ray.Direction * 300)
                        spawnBulletTracer(sPos, ePos)
                    end
                end)
            end
        end)
    end

    local function hookCharacterGuns(char)
        if not char then return end
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then hookGunToolLocal(child) end
        end
        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then hookGunToolLocal(child) end
        end)
    end

    if LocalPlayer.Character then hookCharacterGuns(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(hookCharacterGuns)

    -- Throwing Knife Visuals: Trajectory Trails and Impact Ring
    task.spawn(function()
        pcall(function()
            local cs = game:GetService("CollectionService")
            cs:GetInstanceAddedSignal("ThrowingKnife"):Connect(function(knife)
                if Config.KnifeThrowTracers == false then return end
                task.spawn(function()
                    pcall(function()
                        local blade = knife:WaitForChild("BladePosition", 2) or knife:WaitForChild("Handle", 2) or (knife:IsA("BasePart") and knife)
                        if not blade then return end

                        local a0 = Instance.new("Attachment", blade)
                        a0.Position = Vector3.new(0, 0.5, 0)
                        local a1 = Instance.new("Attachment", blade)
                        a1.Position = Vector3.new(0, -0.5, 0)

                        local trail = Instance.new("Trail")
                        trail.Attachment0 = a0
                        trail.Attachment1 = a1
                        trail.FaceCamera = true
                        trail.Lifetime = 0.45
                        trail.LightEmission = 0.95
                        trail.LightInfluence = 0
                        trail.Color = ColorSequence.new(Color3.fromRGB(255, 35, 65), Color3.fromRGB(255, 170, 40))
                        trail.Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.15),
                            NumberSequenceKeypoint.new(1, 1.0)
                        })
                        trail.WidthScale = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 1.0),
                            NumberSequenceKeypoint.new(1, 0.1)
                        })
                        trail.Parent = blade

                        local lastPos = blade.Position
                        local conn
                        conn = RunService.RenderStepped:Connect(function()
                            if blade and blade.Parent then
                                lastPos = blade.Position
                            else
                                if conn then conn:Disconnect() end
                                spawnImpactRing(lastPos, Vector3.new(0, 1, 0), Color3.fromRGB(255, 45, 60))
                            end
                        end)
                    end)
                end)
            end)
        end)
    end)

    -- 1. Jump Circles Effect
    local function spawnJumpCircle(pos, color)
        pcall(function()
            local part = Instance.new("Part")
            part.Name = "MM2_JumpCircle"
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part.Material = Enum.Material.Neon
            part.Color = color or Color3.fromRGB(255, 60, 80)
            part.Transparency = 0.2
            part.Size = Vector3.new(0.04, 1.0, 1.0)
            part.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))

            local mesh = Instance.new("SpecialMesh", part)
            mesh.MeshType = Enum.MeshType.Cylinder

            part.Parent = workspace.Terrain or workspace

            local tw = TweenService:Create(part, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = Vector3.new(0.01, 13.5, 13.5),
                Transparency = 1
            })
            tw:Play()
            task.delay(0.58, function()
                pcall(function() part:Destroy() end)
            end)
        end)
    end

    local function hookJump(char)
        if not char then return end
        local hum = char:WaitForChild("Humanoid", 3)
        local root = char:WaitForChild("HumanoidRootPart", 3)
        if not hum or not root then return end

        local lastJumpT = 0
        hum.StateChanged:Connect(function(oldState, newState)
            if newState == Enum.HumanoidStateType.Jumping and (Config.JumpCircles ~= false) and (os.clock() - lastJumpT > 0.22) then
                lastJumpT = os.clock()
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local ray = workspace:Raycast(root.Position, Vector3.new(0, -6.5, 0), rayParams)
                local groundPos = ray and ray.Position or (root.Position - Vector3.new(0, 2.8, 0))
                local curTh = UIThemes[Config.UITheme] or UIThemes["Red"]
                spawnJumpCircle(groundPos + Vector3.new(0, 0.05, 0), curTh.Accent or curTh.Main)
            end
        end)
    end

    if LocalPlayer.Character then task.spawn(hookJump, LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(hookJump)

    -- 2. Motion Trail Effect
    local activeMotionTrail = nil
    local activeTrailA0 = nil
    local activeTrailA1 = nil

    _G.MM2_UpdateMotionTrail = function(on)
        if activeMotionTrail then
            pcall(function() activeMotionTrail:Destroy() end)
            activeMotionTrail = nil
        end
        if activeTrailA0 then pcall(function() activeTrailA0:Destroy() end) activeTrailA0 = nil end
        if activeTrailA1 then pcall(function() activeTrailA1:Destroy() end) activeTrailA1 = nil end

        if not on then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local a0 = Instance.new("Attachment", root)
        a0.Name = "MM2_TrailA0"
        a0.Position = Vector3.new(0, 0.8, 0)

        local a1 = Instance.new("Attachment", root)
        a1.Name = "MM2_TrailA1"
        a1.Position = Vector3.new(0, -1.2, 0)

        local trail = Instance.new("Trail")
        trail.Name = "MM2_MotionTrail"
        trail.Attachment0 = a0
        trail.Attachment1 = a1
        trail.Lifetime = 0.38
        trail.MinLength = 0.08
        trail.FaceCamera = true

        local curTh = UIThemes[Config.UITheme] or UIThemes["Red"]
        local col = curTh.Accent or curTh.Main
        trail.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, col),
            ColorSequenceKeypoint.new(0.6, curTh.Main),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
        })
        trail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.25),
            NumberSequenceKeypoint.new(0.7, 0.6),
            NumberSequenceKeypoint.new(1, 1)
        })
        trail.Parent = root

        activeTrailA0 = a0
        activeTrailA1 = a1
        activeMotionTrail = trail
    end

    LocalPlayer.CharacterAdded:Connect(function()
        if Config.MotionTrail then
            task.wait(0.5)
            _G.MM2_UpdateMotionTrail(true)
        end
    end)

    -- 3. Self Aura Glow
    local activeSelfGlow = nil
    _G.MM2_UpdateSelfGlow = function(on)
        if activeSelfGlow then
            pcall(function() activeSelfGlow:Destroy() end)
            activeSelfGlow = nil
        end
        if not on then return end
        local char = LocalPlayer.Character
        if not char then return end

        local hl = Instance.new("Highlight")
        hl.Name = "MM2_SelfGlow"
        local curTh = UIThemes[Config.UITheme] or UIThemes["Red"]
        hl.FillColor = curTh.Main
        hl.OutlineColor = curTh.Accent or curTh.Main
        hl.FillTransparency = 0.65
        hl.OutlineTransparency = 0.15
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = char
        hl.Parent = char
        activeSelfGlow = hl
    end

    LocalPlayer.CharacterAdded:Connect(function()
        if Config.SelfAuraGlow then
            task.wait(0.5)
            _G.MM2_UpdateSelfGlow(true)
        end
    end)

    -- 4. Ambience Presets
    _G.MM2_ApplyAmbiencePreset = function(name)
        pcall(function()
            if name == "Cyberpunk" then
                Lighting.Ambient = Color3.fromRGB(130, 45, 175)
                Lighting.OutdoorAmbient = Color3.fromRGB(70, 20, 115)
                Lighting.Brightness = 2.2
                Lighting.ClockTime = 0
                Lighting.FogColor = Color3.fromRGB(90, 25, 130)
                Lighting.FogEnd = (Config.NoFog and 1e6) or 800
            elseif name == "Sunset" then
                Lighting.Ambient = Color3.fromRGB(255, 140, 70)
                Lighting.OutdoorAmbient = Color3.fromRGB(220, 110, 50)
                Lighting.Brightness = 2.5
                Lighting.ClockTime = 17.8
                Lighting.FogColor = Color3.fromRGB(255, 150, 80)
                Lighting.FogEnd = (Config.NoFog and 1e6) or 1200
            elseif name == "Matrix" then
                Lighting.Ambient = Color3.fromRGB(40, 180, 80)
                Lighting.OutdoorAmbient = Color3.fromRGB(20, 100, 40)
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogColor = Color3.fromRGB(30, 120, 50)
                Lighting.FogEnd = (Config.NoFog and 1e6) or 900
            elseif name == "Winter Frost" then
                Lighting.Ambient = Color3.fromRGB(150, 210, 255)
                Lighting.OutdoorAmbient = Color3.fromRGB(100, 170, 230)
                Lighting.Brightness = 2.4
                Lighting.ClockTime = 14
                Lighting.FogColor = Color3.fromRGB(180, 220, 255)
                Lighting.FogEnd = (Config.NoFog and 1e6) or 1000
            else -- "Default"
                Lighting.Ambient = OriginalLighting.Ambient
                Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
                Lighting.Brightness = OriginalLighting.Brightness
                Lighting.ClockTime = OriginalLighting.ClockTime
                Lighting.FogEnd = (Config.NoFog and 1e6) or OriginalLighting.FogEnd
                if OriginalLighting.FogColor then Lighting.FogColor = OriginalLighting.FogColor end
            end
        end)
    end

    -- 5. FPS Booster Engine
    _G.MM2_ApplyFPSBooster = function(on)
        pcall(function()
            if on then
                Lighting.GlobalShadows = false
                if workspace.Terrain then
                    workspace.Terrain.Decoration = false
                    workspace.Terrain.WaterWaveSize = 0
                end
                for _, e in ipairs(Lighting:GetChildren()) do
                    if e:IsA("PostEffect") and not e:IsA("ColorCorrectionEffect") then
                        e.Enabled = false
                    end
                end
            else
                Lighting.GlobalShadows = OriginalLighting.GlobalShadows
                if workspace.Terrain then
                    workspace.Terrain.Decoration = true
                end
                for _, e in ipairs(Lighting:GetChildren()) do
                    if e:IsA("PostEffect") then
                        e.Enabled = true
                    end
                end
            end
        end)
    end

    -- Initial triggers on script start
    task.delay(0.8, function()
        if Config.MotionTrail then _G.MM2_UpdateMotionTrail(true) end
        if Config.SelfAuraGlow then _G.MM2_UpdateSelfGlow(true) end
        if Config.CameraFOV and Config.CameraFOV ~= 70 and Camera then Camera.FieldOfView = Config.CameraFOV end
        if Config.NoFog then Lighting.FogEnd = 1e6 end
        if Config.WorldAmbiencePreset and Config.WorldAmbiencePreset ~= "Default" then _G.MM2_ApplyAmbiencePreset(Config.WorldAmbiencePreset) end
        if Config.FPSBooster then _G.MM2_ApplyFPSBooster(true) end
    end)
end)()

-- ====================================================================
-- 🌟 ULTIMATE VISUALS SUITE (24 ADVANCED VISUAL EFFECTS)
--    Crosshair, Shaders/Bloom, Color Correction, Depth of Field,
--    SunRays, Damage Vignette, Custom Skyboxes, Footstep Ripples,
--    Landing Shockwave, Angel Halo, Feet Ribbon Trails, Chroma Skin,
--    Neon Back Wings, Laser Eyes, Hitmarker Screen Pulse, Weapon Flame,
--    Death Soul Ascend, Coin Collect Pulse, Giant Weapon Visual,
--    Tactical Shoulder Camera, Dynamic Sprint FOV
-- ====================================================================
;(function()
    local VisualInstances = {}
    local function trackVisual(inst)
        if inst then table.insert(VisualInstances, inst) end
        return inst
    end

    -- ----------------------------------------------------------------
    -- 1. CUSTOM CROSSHAIR ENGINE
    -- ----------------------------------------------------------------
    local crosshairGui = nil
    local crosshairCenter = nil
    local crossElements = {}

    local function getCrosshairColor()
        local cName = Config.CrosshairColor or "Electric Cyan"
        if cName == "Neon Crimson" then
            return Color3.fromRGB(255, 45, 75)
        elseif cName == "Chroma RGB" then
            return Color3.fromHSV((tick() * 0.5) % 1, 0.9, 1)
        elseif cName == "Toxic Green" then
            return Color3.fromRGB(50, 255, 120)
        elseif cName == "Pure White" then
            return Color3.fromRGB(255, 255, 255)
        elseif cName == "Golden Spark" then
            return Color3.fromRGB(255, 215, 60)
        else
            return Color3.fromRGB(0, 240, 255)
        end
    end

    local function destroyCrosshair()
        if crosshairGui then
            pcall(function() crosshairGui:Destroy() end)
            crosshairGui = nil
            crosshairCenter = nil
            crossElements = {}
        end
    end

    local function buildCrosshair()
        destroyCrosshair()
        if not Config.CustomCrosshair then return end

        crosshairGui = Instance.new("ScreenGui")
        crosshairGui.Name = "MM2_CrosshairGui"
        crosshairGui.ResetOnSpawn = false
        crosshairGui.DisplayOrder = 999
        crosshairGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        crosshairGui.Parent = container

        crosshairCenter = Instance.new("Frame")
        crosshairCenter.Name = "CenterAnchor"
        crosshairCenter.AnchorPoint = Vector2.new(0.5, 0.5)
        crosshairCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
        crosshairCenter.Size = UDim2.new(0, 60, 0, 60)
        crosshairCenter.BackgroundTransparency = 1
        crosshairCenter.Parent = crosshairGui

        local style = Config.CrosshairStyle or "Classic Cross"
        local size = Config.CrosshairSize or 12
        local col = getCrosshairColor()

        if style == "Dot" then
            local dot = Instance.new("Frame")
            dot.Name = "Dot"
            dot.AnchorPoint = Vector2.new(0.5, 0.5)
            dot.Position = UDim2.new(0.5, 0, 0.5, 0)
            dot.Size = UDim2.new(0, math.max(4, math.floor(size * 0.45)), 0, math.max(4, math.floor(size * 0.45)))
            dot.BackgroundColor3 = col
            dot.BorderSizePixel = 0
            dot.Parent = crosshairCenter
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            local st = Instance.new("UIStroke", dot)
            st.Color = Color3.fromRGB(0, 0, 0)
            st.Thickness = 1
            table.insert(crossElements, dot)
        elseif style == "Circle" then
            local circle = Instance.new("Frame")
            circle.Name = "Circle"
            circle.AnchorPoint = Vector2.new(0.5, 0.5)
            circle.Position = UDim2.new(0.5, 0, 0.5, 0)
            circle.Size = UDim2.new(0, size * 2, 0, size * 2)
            circle.BackgroundTransparency = 1
            circle.Parent = crosshairCenter
            Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
            local st = Instance.new("UIStroke", circle)
            st.Color = col
            st.Thickness = 2
            table.insert(crossElements, st)
        elseif style == "Circle Dot" then
            local circle = Instance.new("Frame")
            circle.Name = "Circle"
            circle.AnchorPoint = Vector2.new(0.5, 0.5)
            circle.Position = UDim2.new(0.5, 0, 0.5, 0)
            circle.Size = UDim2.new(0, size * 2, 0, size * 2)
            circle.BackgroundTransparency = 1
            circle.Parent = crosshairCenter
            Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
            local st = Instance.new("UIStroke", circle)
            st.Color = col
            st.Thickness = 2
            table.insert(crossElements, st)

            local dot = Instance.new("Frame")
            dot.Name = "CenterDot"
            dot.AnchorPoint = Vector2.new(0.5, 0.5)
            dot.Position = UDim2.new(0.5, 0, 0.5, 0)
            dot.Size = UDim2.new(0, 4, 0, 4)
            dot.BackgroundColor3 = col
            dot.BorderSizePixel = 0
            dot.Parent = crosshairCenter
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            table.insert(crossElements, dot)
        elseif style == "Chevron" then
            local lbl = Instance.new("TextLabel")
            lbl.Name = "Chevron"
            lbl.AnchorPoint = Vector2.new(0.5, 0.5)
            lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
            lbl.Size = UDim2.new(0, 30, 0, 30)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBlack
            lbl.TextSize = math.clamp(size * 1.8, 14, 38)
            lbl.TextColor3 = col
            lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            lbl.TextStrokeTransparency = 0.3
            lbl.Text = "^"
            lbl.Parent = crosshairCenter
            table.insert(crossElements, lbl)
        elseif style == "Heart" then
            local lbl = Instance.new("TextLabel")
            lbl.Name = "Heart"
            lbl.AnchorPoint = Vector2.new(0.5, 0.5)
            lbl.Position = UDim2.new(0.5, 0, 0.5, 0)
            lbl.Size = UDim2.new(0, 30, 0, 30)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamBlack
            lbl.TextSize = math.clamp(size * 1.5, 12, 32)
            lbl.TextColor3 = col
            lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            lbl.TextStrokeTransparency = 0.4
            lbl.Text = "♥"
            lbl.Parent = crosshairCenter
            table.insert(crossElements, lbl)
        else -- "Classic Cross"
            local gap = math.max(3, math.floor(size * 0.4))
            local len = size
            local thick = 2

            -- Top
            local topBar = Instance.new("Frame")
            topBar.AnchorPoint = Vector2.new(0.5, 1)
            topBar.Position = UDim2.new(0.5, 0, 0.5, -gap)
            topBar.Size = UDim2.new(0, thick, 0, len)
            topBar.BackgroundColor3 = col
            topBar.BorderSizePixel = 0
            topBar.Parent = crosshairCenter
            table.insert(crossElements, topBar)

            -- Bottom
            local botBar = Instance.new("Frame")
            botBar.AnchorPoint = Vector2.new(0.5, 0)
            botBar.Position = UDim2.new(0.5, 0, 0.5, gap)
            botBar.Size = UDim2.new(0, thick, 0, len)
            botBar.BackgroundColor3 = col
            botBar.BorderSizePixel = 0
            botBar.Parent = crosshairCenter
            table.insert(crossElements, botBar)

            -- Left
            local leftBar = Instance.new("Frame")
            leftBar.AnchorPoint = Vector2.new(1, 0.5)
            leftBar.Position = UDim2.new(0.5, -gap, 0.5, 0)
            leftBar.Size = UDim2.new(0, len, 0, thick)
            leftBar.BackgroundColor3 = col
            leftBar.BorderSizePixel = 0
            leftBar.Parent = crosshairCenter
            table.insert(crossElements, leftBar)

            -- Right
            local rightBar = Instance.new("Frame")
            rightBar.AnchorPoint = Vector2.new(0, 0.5)
            rightBar.Position = UDim2.new(0.5, gap, 0.5, 0)
            rightBar.Size = UDim2.new(0, len, 0, thick)
            rightBar.BackgroundColor3 = col
            rightBar.BorderSizePixel = 0
            rightBar.Parent = crosshairCenter
            table.insert(crossElements, rightBar)
        end
    end

    _G.MM2_UpdateCrosshair = function(on)
        Config.CustomCrosshair = on
        saveConfig()
        if on then buildCrosshair() else destroyCrosshair() end
    end
    _G.MM2_UpdateCrosshairStyle = function(s)
        Config.CrosshairStyle = s
        saveConfig()
        if Config.CustomCrosshair then buildCrosshair() end
    end
    _G.MM2_UpdateCrosshairColor = function(c)
        Config.CrosshairColor = c
        saveConfig()
        if Config.CustomCrosshair then buildCrosshair() end
    end
    _G.MM2_UpdateCrosshairSize = function(s)
        Config.CrosshairSize = s
        saveConfig()
        if Config.CustomCrosshair then buildCrosshair() end
    end

    -- Chroma RGB update loop
    RunService.RenderStepped:Connect(function()
        if Config.CustomCrosshair and Config.CrosshairColor == "Chroma RGB" and #crossElements > 0 then
            local c = Color3.fromHSV((tick() * 0.5) % 1, 0.9, 1)
            for _, el in ipairs(crossElements) do
                if el:IsA("UIStroke") then
                    el.Color = c
                elseif el:IsA("Frame") then
                    el.BackgroundColor3 = c
                elseif el:IsA("TextLabel") then
                    el.TextColor3 = c
                end
            end
        end
    end)

    -- ----------------------------------------------------------------
    -- 2. GLOW BLOOM EFFECT
    -- ----------------------------------------------------------------
    local activeBloom = nil
    _G.MM2_UpdateBloom = function(on)
        pcall(function()
            if activeBloom then activeBloom:Destroy() activeBloom = nil end
            local existing = Lighting:FindFirstChild("MM2_GlowBloom")
            if existing then existing:Destroy() end

            if on then
                activeBloom = Instance.new("BloomEffect")
                activeBloom.Name = "MM2_GlowBloom"
                activeBloom.Intensity = 1.35
                activeBloom.Size = 24
                activeBloom.Threshold = 0.78
                activeBloom.Parent = Lighting
                trackVisual(activeBloom)
            end
        end)
    end

    -- ----------------------------------------------------------------
    -- 3. COLOR CORRECTION PRESETS
    -- ----------------------------------------------------------------
    local activeCC = nil
    _G.MM2_UpdateColorCorrection = function(preset)
        pcall(function()
            if activeCC then activeCC:Destroy() activeCC = nil end
            local existing = Lighting:FindFirstChild("MM2_PostColorCorrection")
            if existing then existing:Destroy() end

            if not preset or preset == "None" then return end

            activeCC = Instance.new("ColorCorrectionEffect")
            activeCC.Name = "MM2_PostColorCorrection"
            if preset == "Vibrant Anime" then
                activeCC.Saturation = 0.45
                activeCC.Contrast = 0.16
                activeCC.TintColor = Color3.fromRGB(255, 248, 255)
            elseif preset == "Cyberpunk Pink" then
                activeCC.Saturation = 0.4
                activeCC.Contrast = 0.22
                activeCC.TintColor = Color3.fromRGB(255, 190, 245)
            elseif preset == "Matrix Green" then
                activeCC.Saturation = -0.05
                activeCC.Contrast = 0.25
                activeCC.TintColor = Color3.fromRGB(175, 255, 195)
            elseif preset == "Cinematic Noir" then
                activeCC.Saturation = -1.0
                activeCC.Contrast = 0.35
                activeCC.TintColor = Color3.fromRGB(235, 235, 245)
            elseif preset == "Cold Frost" then
                activeCC.Saturation = 0.15
                activeCC.Contrast = 0.18
                activeCC.TintColor = Color3.fromRGB(190, 230, 255)
            end
            activeCC.Parent = Lighting
            trackVisual(activeCC)
        end)
    end

    -- ----------------------------------------------------------------
    -- 4. DEPTH OF FIELD
    -- ----------------------------------------------------------------
    local activeDOF = nil
    _G.MM2_UpdateDepthOfField = function(on)
        pcall(function()
            if activeDOF then activeDOF:Destroy() activeDOF = nil end
            local existing = Lighting:FindFirstChild("MM2_DepthOfField")
            if existing then existing:Destroy() end

            if on then
                activeDOF = Instance.new("DepthOfFieldEffect")
                activeDOF.Name = "MM2_DepthOfField"
                activeDOF.FarIntensity = 0.38
                activeDOF.FocusDistance = 15
                activeDOF.InFocusRadius = 22
                activeDOF.NearIntensity = 0
                activeDOF.Parent = Lighting
                trackVisual(activeDOF)
            end
        end)
    end

    -- ----------------------------------------------------------------
    -- 5. VOLUMETRIC SUN RAYS
    -- ----------------------------------------------------------------
    local activeSunRays = nil
    _G.MM2_UpdateSunRays = function(on)
        pcall(function()
            if activeSunRays then activeSunRays:Destroy() activeSunRays = nil end
            local existing = Lighting:FindFirstChild("MM2_SunRays")
            if existing then existing:Destroy() end

            if on then
                activeSunRays = Instance.new("SunRaysEffect")
                activeSunRays.Name = "MM2_SunRays"
                activeSunRays.Intensity = 0.28
                activeSunRays.Spread = 0.82
                activeSunRays.Parent = Lighting
                trackVisual(activeSunRays)
            end
        end)
    end

    -- ----------------------------------------------------------------
    -- 6. DAMAGE VIGNETTE & HIT PULSE
    -- ----------------------------------------------------------------
    local damageVignetteGui = nil
    local damageVignetteImg = nil
    local hitPulseFrame = nil

    local function setupScreenFXGui()
        if damageVignetteGui then return end
        damageVignetteGui = Instance.new("ScreenGui")
        damageVignetteGui.Name = "MM2_ScreenFXGui"
        damageVignetteGui.ResetOnSpawn = false
        damageVignetteGui.DisplayOrder = 990
        damageVignetteGui.Parent = container

        -- Red Damage Vignette
        damageVignetteImg = Instance.new("ImageLabel")
        damageVignetteImg.Name = "DamageVignette"
        damageVignetteImg.Size = UDim2.new(1, 0, 1, 0)
        damageVignetteImg.BackgroundTransparency = 1
        damageVignetteImg.Image = "rbxassetid://6015897843"
        damageVignetteImg.ImageColor3 = Color3.fromRGB(255, 30, 45)
        damageVignetteImg.ImageTransparency = 1
        damageVignetteImg.Parent = damageVignetteGui

        -- Hit Screen Pulse Frame
        hitPulseFrame = Instance.new("Frame")
        hitPulseFrame.Name = "HitPulseFrame"
        hitPulseFrame.Size = UDim2.new(1, 0, 1, 0)
        hitPulseFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        hitPulseFrame.BackgroundTransparency = 1
        hitPulseFrame.BorderSizePixel = 0
        hitPulseFrame.Parent = damageVignetteGui
    end

    _G.MM2_UpdateDamageVignette = function(on)
        Config.DamageVignette = on
        saveConfig()
        if on then setupScreenFXGui() end
    end

    _G.MM2_TriggerHitPulse = function()
        if Config.HitmarkerScreenPulse == false then return end
        setupScreenFXGui()
        pcall(function()
            hitPulseFrame.BackgroundColor3 = Color3.fromRGB(150, 230, 255)
            hitPulseFrame.BackgroundTransparency = 0.72
            TweenService:Create(hitPulseFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            }):Play()
        end)
    end

    -- Hook player health changes for Damage Vignette
    local function hookHealthForVignette(char)
        if not char then return end
        local hum = char:WaitForChild("Humanoid", 3)
        if not hum then return end
        local lastHealth = hum.Health
        hum.HealthChanged:Connect(function(newHp)
            if Config.DamageVignette and newHp < lastHealth and newHp > 0 then
                setupScreenFXGui()
                damageVignetteImg.ImageTransparency = 0.35
                TweenService:Create(damageVignetteImg, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    ImageTransparency = 1
                }):Play()
            end
            lastHealth = newHp
        end)
    end
    if LocalPlayer.Character then hookHealthForVignette(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(hookHealthForVignette)

    -- ----------------------------------------------------------------
    -- 7. CUSTOM SKYBOXES
    -- ----------------------------------------------------------------
    local SkyboxAssets = {
        ["Purple Nebula"] = {
            Bk = "rbxassetid://159454299", Dn = "rbxassetid://159454296",
            Ft = "rbxassetid://159454293", Lf = "rbxassetid://159454286",
            Rt = "rbxassetid://159454300", Up = "rbxassetid://159454288"
        },
        ["Galaxy Space"] = {
            Bk = "rbxassetid://159248188", Dn = "rbxassetid://159248183",
            Ft = "rbxassetid://159248187", Lf = "rbxassetid://159248173",
            Rt = "rbxassetid://159248192", Up = "rbxassetid://159248176"
        },
        ["Anime Sunset"] = {
            Bk = "rbxassetid://269748805", Dn = "rbxassetid://269748988",
            Ft = "rbxassetid://269748877", Lf = "rbxassetid://269748897",
            Rt = "rbxassetid://269748843", Up = "rbxassetid://269748918"
        },
        ["Dark Cyber Void"] = {
            Bk = "rbxassetid://257069747", Dn = "rbxassetid://257069759",
            Ft = "rbxassetid://257069772", Lf = "rbxassetid://257069796",
            Rt = "rbxassetid://257069814", Up = "rbxassetid://257069830"
        },
        ["Blood Moon"] = {
            Bk = "rbxassetid://460292850", Dn = "rbxassetid://460292882",
            Ft = "rbxassetid://460292928", Lf = "rbxassetid://460292965",
            Rt = "rbxassetid://460293006", Up = "rbxassetid://460293043"
        }
    }

    local activeCustomSky = nil
    _G.MM2_UpdateSkybox = function(name)
        pcall(function()
            if activeCustomSky then activeCustomSky:Destroy() activeCustomSky = nil end
            local existing = Lighting:FindFirstChild("MM2_CustomSky")
            if existing then existing:Destroy() end

            if not name or name == "Default" then
                for _, s in ipairs(Lighting:GetChildren()) do
                    if s:IsA("Sky") and s.Name ~= "MM2_CustomSky" then
                        s.Parent = Lighting
                    end
                end
                return
            end

            local data = SkyboxAssets[name]
            if data then
                activeCustomSky = Instance.new("Sky")
                activeCustomSky.Name = "MM2_CustomSky"
                activeCustomSky.SkyboxBk = data.Bk
                activeCustomSky.SkyboxDn = data.Dn
                activeCustomSky.SkyboxFt = data.Ft
                activeCustomSky.SkyboxLf = data.Lf
                activeCustomSky.SkyboxRt = data.Rt
                activeCustomSky.SkyboxUp = data.Up
                activeCustomSky.CelestialBodiesShown = true
                activeCustomSky.Parent = Lighting
                trackVisual(activeCustomSky)
            end
        end)
    end

    -- ----------------------------------------------------------------
    -- 8. FOOTSTEP RIPPLES
    -- ----------------------------------------------------------------
    local lastFootstepT = 0
    local footstepAlternator = 1
    local function spawnFootstepRipple(pos, color)
        pcall(function()
            local p = Instance.new("Part")
            p.Name = "MM2_FootstepRipple"
            p.Anchored = true
            p.CanCollide = false
            p.CanTouch = false
            p.CanQuery = false
            p.CastShadow = false
            p.Material = Enum.Material.Neon
            p.Color = color or Color3.fromRGB(0, 230, 255)
            p.Transparency = 0.25
            p.Size = Vector3.new(0.04, 0.7, 0.7)
            p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
            local mesh = Instance.new("SpecialMesh", p)
            mesh.MeshType = Enum.MeshType.Cylinder
            p.Parent = workspace.Terrain or workspace

            local tw = TweenService:Create(p, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = Vector3.new(0.01, 3.2, 3.2),
                Transparency = 1
            })
            tw:Play()
            task.delay(0.45, function() pcall(function() p:Destroy() end) end)
        end)
    end

    _G.MM2_UpdateFootstepRipples = function(on)
        Config.FootstepRipples = on
        saveConfig()
    end

    -- ----------------------------------------------------------------
    -- 9. LANDING SHOCKWAVE
    -- ----------------------------------------------------------------
    local function spawnLandingShockwave(pos, color)
        pcall(function()
            local p = Instance.new("Part")
            p.Name = "MM2_LandingShockwave"
            p.Anchored = true
            p.CanCollide = false
            p.CanTouch = false
            p.CanQuery = false
            p.CastShadow = false
            p.Material = Enum.Material.Neon
            p.Color = color or Color3.fromRGB(255, 120, 50)
            p.Transparency = 0.2
            p.Size = Vector3.new(0.04, 1.8, 1.8)
            p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
            local mesh = Instance.new("SpecialMesh", p)
            mesh.MeshType = Enum.MeshType.Cylinder
            p.Parent = workspace.Terrain or workspace

            local tw = TweenService:Create(p, TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = Vector3.new(0.01, 16.0, 16.0),
                Transparency = 1
            })
            tw:Play()
            task.delay(0.68, function() pcall(function() p:Destroy() end) end)
        end)
    end

    local function hookPlayerMovementVisuals(char)
        if not char then return end
        local hum = char:WaitForChild("Humanoid", 3)
        local root = char:WaitForChild("HumanoidRootPart", 3)
        if not hum or not root then return end

        local wasInAir = false
        hum.StateChanged:Connect(function(oldState, newState)
            if newState == Enum.HumanoidStateType.Freefall then
                wasInAir = true
            elseif (newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running) and wasInAir then
                wasInAir = false
                if Config.LandingShockwave ~= false then
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {char}
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    local ray = workspace:Raycast(root.Position, Vector3.new(0, -7.5, 0), rayParams)
                    local groundPos = ray and ray.Position or (root.Position - Vector3.new(0, 2.9, 0))
                    local curTh = (UIThemes and UIThemes[Config.UITheme]) or { Main = Color3.fromRGB(255, 60, 80), Accent = Color3.fromRGB(255, 140, 50) }
                    spawnLandingShockwave(groundPos + Vector3.new(0, 0.05, 0), curTh.Accent)
                end
            end
        end)
    end
    if LocalPlayer.Character then hookPlayerMovementVisuals(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(hookPlayerMovementVisuals)

    -- Footstep ripples loop
    RunService.Heartbeat:Connect(function()
        if not Config.FootstepRipples then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        if hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air then
            if os.clock() - lastFootstepT > 0.3 then
                lastFootstepT = os.clock()
                footstepAlternator = -footstepAlternator
                local footOffset = root.CFrame.RightVector * (footstepAlternator * 0.55)
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                local ray = workspace:Raycast(root.Position + footOffset, Vector3.new(0, -6.5, 0), rayParams)
                local groundPos = ray and ray.Position or (root.Position + footOffset - Vector3.new(0, 2.8, 0))
                local curTh = (UIThemes and UIThemes[Config.UITheme]) or { Main = Color3.fromRGB(0, 230, 255), Accent = Color3.fromRGB(60, 200, 255) }
                spawnFootstepRipple(groundPos + Vector3.new(0, 0.05, 0), curTh.Accent)
            end
        end
    end)

    -- ----------------------------------------------------------------
    -- 10. ANGEL HALO
    -- ----------------------------------------------------------------
    local activeHalo = nil
    local function destroyHalo()
        if activeHalo then
            pcall(function() activeHalo:Destroy() end)
            activeHalo = nil
        end
    end
    local function createHalo(char)
        destroyHalo()
        if not Config.HaloAura or not char then return end
        local head = char:WaitForChild("Head", 3)
        if not head then return end

        local halo = Instance.new("Part")
        halo.Name = "MM2_AngelHalo"
        halo.CanCollide = false
        halo.CanTouch = false
        halo.CanQuery = false
        halo.CastShadow = false
        halo.Material = Enum.Material.Neon
        local curTh = (UIThemes and UIThemes[Config.UITheme]) or { Accent = Color3.fromRGB(255, 215, 60) }
        halo.Color = curTh.Accent or Color3.fromRGB(255, 215, 60)
        halo.Size = Vector3.new(1.5, 0.12, 1.5)

        local mesh = Instance.new("SpecialMesh", halo)
        mesh.MeshType = Enum.MeshType.Cylinder

        halo.Parent = char
        activeHalo = halo
    end

    _G.MM2_UpdateHaloAura = function(on)
        Config.HaloAura = on
        saveConfig()
        if on then createHalo(LocalPlayer.Character) else destroyHalo() end
    end
    LocalPlayer.CharacterAdded:Connect(function(c)
        if Config.HaloAura then task.wait(0.5) createHalo(c) end
    end)

    -- Animate Halo position and spin
    RunService.RenderStepped:Connect(function()
        if activeHalo and activeHalo.Parent then
            local char = LocalPlayer.Character
            local head = char and char:FindFirstChild("Head")
            if head then
                local bob = math.sin(tick() * 3.5) * 0.12
                local spin = tick() * 70
                activeHalo.CFrame = CFrame.new(head.Position + Vector3.new(0, 1.6 + bob, 0)) * CFrame.Angles(math.rad(10), math.rad(spin), 0)
            end
        end
    end)

    -- ----------------------------------------------------------------
    -- 11. FEET RIBBON TRAILS
    -- ----------------------------------------------------------------
    local activeFeetTrails = {}
    local function destroyFeetTrails()
        for _, t in ipairs(activeFeetTrails) do
            pcall(function() t:Destroy() end)
        end
        activeFeetTrails = {}
    end
    local function createFeetTrails(char)
        destroyFeetTrails()
        if not Config.FeetTrails or not char then return end

        local feet = {}
        for _, n in ipairs({"LeftFoot", "RightFoot", "Left Leg", "Right Leg"}) do
            local p = char:FindFirstChild(n)
            if p and p:IsA("BasePart") then table.insert(feet, p) end
        end

        local curTh = (UIThemes and UIThemes[Config.UITheme]) or { Main = Color3.fromRGB(0, 240, 255), Accent = Color3.fromRGB(255, 90, 115) }
        for _, foot in ipairs(feet) do
            local a0 = Instance.new("Attachment", foot)
            a0.Position = Vector3.new(0, -0.4, 0)
            local a1 = Instance.new("Attachment", foot)
            a1.Position = Vector3.new(0, 0.4, 0)

            local trail = Instance.new("Trail")
            trail.Name = "MM2_FootTrail"
            trail.Attachment0 = a0
            trail.Attachment1 = a1
            trail.Lifetime = 0.35
            trail.FaceCamera = true
            trail.Color = ColorSequence.new(curTh.Main, curTh.Accent)
            trail.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.2),
                NumberSequenceKeypoint.new(1, 1)
            })
            trail.Parent = foot

            table.insert(activeFeetTrails, a0)
            table.insert(activeFeetTrails, a1)
            table.insert(activeFeetTrails, trail)
        end
    end

    _G.MM2_UpdateFeetTrails = function(on)
        Config.FeetTrails = on
        saveConfig()
        if on then createFeetTrails(LocalPlayer.Character) else destroyFeetTrails() end
    end
    LocalPlayer.CharacterAdded:Connect(function(c)
        if Config.FeetTrails then task.wait(0.5) createFeetTrails(c) end
    end)

    -- ----------------------------------------------------------------
    -- 12. CHROMA RAINBOW SKIN
    -- ----------------------------------------------------------------
    local chromaHighlight = nil
    local function destroyChromaSkin()
        if chromaHighlight then
            pcall(function() chromaHighlight:Destroy() end)
            chromaHighlight = nil
        end
    end
    local function setupChromaSkin(char)
        destroyChromaSkin()
        if not Config.ChromaSkin or not char then return end

        chromaHighlight = Instance.new("Highlight")
        chromaHighlight.Name = "MM2_ChromaHighlight"
        chromaHighlight.FillTransparency = 0.5
        chromaHighlight.OutlineTransparency = 0.1
        chromaHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        chromaHighlight.Adornee = char
        chromaHighlight.Parent = char
    end

    _G.MM2_UpdateChromaSkin = function(on)
        Config.ChromaSkin = on
        saveConfig()
        if on then setupChromaSkin(LocalPlayer.Character) else destroyChromaSkin() end
    end
    LocalPlayer.CharacterAdded:Connect(function(c)
        if Config.ChromaSkin then task.wait(0.5) setupChromaSkin(c) end
    end)

    RunService.RenderStepped:Connect(function()
        if Config.ChromaSkin and chromaHighlight and chromaHighlight.Parent then
            local c = Color3.fromHSV((tick() * 0.3) % 1, 0.85, 1)
            chromaHighlight.FillColor = c
            chromaHighlight.OutlineColor = c
        end
    end)

    -- ----------------------------------------------------------------
    -- 13. NEON BACK WINGS
    -- ----------------------------------------------------------------
    local activeWingsModel = nil
    local function destroyBackWings()
        if activeWingsModel then
            pcall(function() activeWingsModel:Destroy() end)
            activeWingsModel = nil
        end
    end
    local function createBackWings(char)
        destroyBackWings()
        if not Config.BackWingsVisual or not char then return end
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if not torso then return end

        local curTh = (UIThemes and UIThemes[Config.UITheme]) or { Main = Color3.fromRGB(0, 240, 255), Accent = Color3.fromRGB(60, 210, 255) }

        local model = Instance.new("Model")
        model.Name = "MM2_BackWings"

        -- Left Wing
        local leftWing = Instance.new("Part")
        leftWing.Name = "LeftWing"
        leftWing.Size = Vector3.new(2.4, 1.2, 0.08)
        leftWing.CanCollide = false
        leftWing.CanTouch = false
        leftWing.CanQuery = false
        leftWing.Material = Enum.Material.Neon
        leftWing.Color = curTh.Accent
        leftWing.Transparency = 0.3
        leftWing.Parent = model

        local weldL = Instance.new("WeldConstraint")
        weldL.Part0 = torso
        weldL.Part1 = leftWing
        weldL.Parent = leftWing
        leftWing.CFrame = torso.CFrame * CFrame.new(-1.2, 0.4, 0.65) * CFrame.Angles(0, math.rad(-25), math.rad(30))

        -- Right Wing
        local rightWing = Instance.new("Part")
        rightWing.Name = "RightWing"
        rightWing.Size = Vector3.new(2.4, 1.2, 0.08)
        rightWing.CanCollide = false
        rightWing.CanTouch = false
        rightWing.CanQuery = false
        rightWing.Material = Enum.Material.Neon
        rightWing.Color = curTh.Accent
        rightWing.Transparency = 0.3
        rightWing.Parent = model

        local weldR = Instance.new("WeldConstraint")
        weldR.Part0 = torso
        weldR.Part1 = rightWing
        weldR.Parent = rightWing
        rightWing.CFrame = torso.CFrame * CFrame.new(1.2, 0.4, 0.65) * CFrame.Angles(0, math.rad(25), math.rad(-30))

        model.Parent = char
        activeWingsModel = model
    end

    _G.MM2_UpdateBackWings = function(on)
        Config.BackWingsVisual = on
        saveConfig()
        if on then createBackWings(LocalPlayer.Character) else destroyBackWings() end
    end
    LocalPlayer.CharacterAdded:Connect(function(c)
        if Config.BackWingsVisual then task.wait(0.5) createBackWings(c) end
    end)

    -- ----------------------------------------------------------------
    -- 14. LASER EYES
    -- ----------------------------------------------------------------
    local activeLaserEyes = {}
    local function destroyLaserEyes()
        for _, obj in ipairs(activeLaserEyes) do
            pcall(function() obj:Destroy() end)
        end
        activeLaserEyes = {}
    end
    local function createLaserEyes(char)
        destroyLaserEyes()
        if not Config.LaserEyes or not char then return end
        local head = char:WaitForChild("Head", 3)
        if not head then return end

        local curTh = (UIThemes and UIThemes[Config.UITheme]) or { Main = Color3.fromRGB(255, 45, 60) }
        local laserCol = curTh.Main or Color3.fromRGB(255, 45, 60)

        for _, side in ipairs({-0.22, 0.22}) do
            local a0 = Instance.new("Attachment", head)
            a0.Position = Vector3.new(side, 0.15, -0.55)

            local a1 = Instance.new("Attachment", head)
            a1.Position = Vector3.new(side * 2.2, 0.15, -45)

            local beam = Instance.new("Beam")
            beam.Name = "EyeBeam"
            beam.Attachment0 = a0
            beam.Attachment1 = a1
            beam.Width0 = 0.14
            beam.Width1 = 0.04
            beam.FaceCamera = true
            beam.LightEmission = 1
            beam.LightInfluence = 0
            beam.Color = ColorSequence.new(laserCol)
            beam.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.1),
                NumberSequenceKeypoint.new(1, 0.8)
            })
            beam.Parent = head

            table.insert(activeLaserEyes, a0)
            table.insert(activeLaserEyes, a1)
            table.insert(activeLaserEyes, beam)
        end
    end

    _G.MM2_UpdateLaserEyes = function(on)
        Config.LaserEyes = on
        saveConfig()
        if on then createLaserEyes(LocalPlayer.Character) else destroyLaserEyes() end
    end
    LocalPlayer.CharacterAdded:Connect(function(c)
        if Config.LaserEyes then task.wait(0.5) createLaserEyes(c) end
    end)

    -- ----------------------------------------------------------------
    -- 15. WEAPON CHROMA FLAME
    -- ----------------------------------------------------------------
    local activeWeaponEmitter = nil
    local function destroyWeaponFlame()
        if activeWeaponEmitter then
            pcall(function() activeWeaponEmitter:Destroy() end)
            activeWeaponEmitter = nil
        end
    end
    local function attachWeaponFlame(tool)
        destroyWeaponFlame()
        if not Config.WeaponChromaFlame or not tool then return end
        local handle = tool:FindFirstChild("Handle") or tool:FindFirstChild("BladePosition") or tool:FindFirstChildWhichIsA("BasePart")
        if not handle then return end

        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "MM2_WeaponFlame"
        emitter.Rate = 22
        emitter.Lifetime = NumberRange.new(0.2, 0.42)
        emitter.Speed = NumberRange.new(1.8, 3.6)
        emitter.SpreadAngle = Vector2.new(15, 15)
        emitter.LightEmission = 1
        emitter.LightInfluence = 0
        local curTh = (UIThemes and UIThemes[Config.UITheme]) or { Main = Color3.fromRGB(255, 60, 80), Accent = Color3.fromRGB(255, 170, 40) }
        emitter.Color = ColorSequence.new(curTh.Main, curTh.Accent)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.35),
            NumberSequenceKeypoint.new(1, 0)
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 1)
        })
        emitter.Parent = handle
        activeWeaponEmitter = emitter
    end

    _G.MM2_UpdateWeaponFlame = function(on)
        Config.WeaponChromaFlame = on
        saveConfig()
        if on then
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then attachWeaponFlame(tool) end
        else
            destroyWeaponFlame()
        end
    end

    local function hookToolFlame(char)
        if not char then return end
        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") and Config.WeaponChromaFlame then
                task.wait(0.1)
                attachWeaponFlame(child)
            end
        end)
        char.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") and activeWeaponEmitter and activeWeaponEmitter:IsDescendantOf(child) then
                destroyWeaponFlame()
            end
        end)
    end
    if LocalPlayer.Character then hookToolFlame(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(hookToolFlame)

    -- ----------------------------------------------------------------
    -- 16. DEATH SOUL ASCEND EFFECT
    -- ----------------------------------------------------------------
    local function spawnDeathSoul(deathPos)
        pcall(function()
            local orb = Instance.new("Part")
            orb.Name = "MM2_DeathSoul"
            orb.Shape = Enum.PartType.Ball
            orb.Size = Vector3.new(1.2, 1.2, 1.2)
            orb.Material = Enum.Material.Neon
            orb.Color = Color3.fromRGB(180, 240, 255)
            orb.Transparency = 0.3
            orb.CanCollide = false
            orb.CanTouch = false
            orb.CanQuery = false
            orb.Anchored = true
            orb.CFrame = CFrame.new(deathPos)
            orb.Parent = workspace.Terrain or workspace

            local light = Instance.new("PointLight", orb)
            light.Color = Color3.fromRGB(180, 240, 255)
            light.Brightness = 2.5
            light.Range = 12

            local tw = TweenService:Create(orb, TweenInfo.new(2.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                CFrame = CFrame.new(deathPos + Vector3.new(0, 25, 0)),
                Size = Vector3.new(2.4, 2.4, 2.4),
                Transparency = 1
            })
            tw:Play()
            task.delay(2.5, function() pcall(function() orb:Destroy() end) end)
        end)
    end

    local function monitorPlayerDeath(plr)
        plr.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild("Humanoid", 4)
            local root = char:WaitForChild("HumanoidRootPart", 4)
            if not hum or not root then return end
            hum.Died:Connect(function()
                if Config.DeathSoulEffect ~= false then
                    spawnDeathSoul(root.Position)
                end
            end)
        end)
    end
    for _, p in ipairs(Players:GetPlayers()) do monitorPlayerDeath(p) end
    Players.PlayerAdded:Connect(monitorPlayerDeath)

    -- ----------------------------------------------------------------
    -- 17. COIN COLLECT PULSE
    -- ----------------------------------------------------------------
    local function spawnCoinCollectPulse(pos)
        pcall(function()
            local p = Instance.new("Part")
            p.Name = "MM2_CoinPulse"
            p.Anchored = true
            p.CanCollide = false
            p.CanTouch = false
            p.CanQuery = false
            p.CastShadow = false
            p.Material = Enum.Material.Neon
            p.Color = Color3.fromRGB(255, 215, 40)
            p.Transparency = 0.15
            p.Size = Vector3.new(0.04, 1.2, 1.2)
            p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
            local mesh = Instance.new("SpecialMesh", p)
            mesh.MeshType = Enum.MeshType.Cylinder
            p.Parent = workspace.Terrain or workspace

            local tw = TweenService:Create(p, TweenInfo.new(0.52, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = Vector3.new(0.01, 11.0, 11.0),
                Transparency = 1
            })
            tw:Play()
            task.delay(0.55, function() pcall(function() p:Destroy() end) end)
        end)
    end

    _G.MM2_TriggerCoinCollectPulse = function(customPos)
        if Config.CoinCollectPulse == false then return end
        local root = getLocalRoot()
        local pos = customPos or (root and (root.Position - Vector3.new(0, 2.5, 0)))
        if pos then spawnCoinCollectPulse(pos) end
    end

    -- ----------------------------------------------------------------
    -- 18. GIANT WEAPON VISUAL
    -- ----------------------------------------------------------------
    local function applyBigWeaponScale(tool, enable)
        if not tool then return end
        local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
        if not handle then return end
        local mesh = handle:FindFirstChildWhichIsA("SpecialMesh")
        if mesh then
            local origScale = mesh:GetAttribute("OrigScale")
            if not origScale then
                origScale = mesh.Scale
                mesh:SetAttribute("OrigScale", origScale)
            end
            if enable then
                mesh.Scale = origScale * 1.85
            else
                mesh.Scale = origScale
            end
        end
    end

    _G.MM2_UpdateBigWeapon = function(on)
        Config.BigWeaponVisual = on
        saveConfig()
        local char = LocalPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then applyBigWeaponScale(tool, on) end
    end

    local function hookBigWeapon(char)
        if not char then return end
        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") and Config.BigWeaponVisual then
                task.wait(0.1)
                applyBigWeaponScale(child, true)
            end
        end)
    end
    if LocalPlayer.Character then hookBigWeapon(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(hookBigWeapon)

    -- ----------------------------------------------------------------
    -- 19. TACTICAL SHOULDER CAMERA, DYNAMIC SPRINT FOV & STRETCHED RES
    -- ----------------------------------------------------------------
    _G.MM2_UpdateShoulderCamera = function(on)
        Config.ShoulderCamera = on
        saveConfig()
    end

    local blackBarsGui = nil
    local leftBar = nil
    local rightBar = nil
    local topBar = nil
    local bottomBar = nil

    local function getTargetAspect(preset)
        if not preset then return 4 / 3 end
        if preset:find("4:3") then
            return 4 / 3
        elseif preset:find("5:4") then
            return 5 / 4
        elseif preset:find("16:10") then
            return 16 / 10
        elseif preset:find("1:1") then
            return 1 / 1
        end
        return 4 / 3
    end

    local function ensureBlackBars()
        if not blackBarsGui or not blackBarsGui.Parent then
            local parentGui = container or (LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")) or game:GetService("CoreGui")
            blackBarsGui = Instance.new("ScreenGui")
            blackBarsGui.Name = "MM2_Stretched_BlackBars"
            blackBarsGui.ResetOnSpawn = false
            blackBarsGui.DisplayOrder = 10
            blackBarsGui.IgnoreGuiInset = true

            leftBar = Instance.new("Frame")
            leftBar.Name = "LeftBar"
            leftBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            leftBar.BorderSizePixel = 0
            leftBar.Parent = blackBarsGui

            rightBar = Instance.new("Frame")
            rightBar.Name = "RightBar"
            rightBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            rightBar.BorderSizePixel = 0
            rightBar.Parent = blackBarsGui

            topBar = Instance.new("Frame")
            topBar.Name = "TopBar"
            topBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            topBar.BorderSizePixel = 0
            topBar.Parent = blackBarsGui

            bottomBar = Instance.new("Frame")
            bottomBar.Name = "BottomBar"
            bottomBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            bottomBar.BorderSizePixel = 0
            bottomBar.Parent = blackBarsGui

            pcall(function()
                blackBarsGui.Parent = parentGui
            end)
            trackVisual(blackBarsGui)
        end
    end

    local function updateBlackBars(vpX, vpY, targetAspect)
        if not Config.StretchBlackBars or not Config.StretchedRes then
            if blackBarsGui then
                blackBarsGui.Enabled = false
            end
            return
        end

        ensureBlackBars()
        blackBarsGui.Enabled = true

        local currentAspect = vpX / math.max(1, vpY)
        if currentAspect > targetAspect then
            local targetW = vpY * targetAspect
            local barW = math.floor((vpX - targetW) / 2)
            leftBar.Visible = true
            leftBar.Position = UDim2.new(0, 0, 0, 0)
            leftBar.Size = UDim2.new(0, barW, 1, 0)

            rightBar.Visible = true
            rightBar.Position = UDim2.new(1, -barW, 0, 0)
            rightBar.Size = UDim2.new(0, barW, 1, 0)

            topBar.Visible = false
            bottomBar.Visible = false
        elseif currentAspect < targetAspect then
            local targetH = vpX / targetAspect
            local barH = math.floor((vpY - targetH) / 2)
            topBar.Visible = true
            topBar.Position = UDim2.new(0, 0, 0, 0)
            topBar.Size = UDim2.new(1, 0, 0, barH)

            bottomBar.Visible = true
            bottomBar.Position = UDim2.new(0, 0, 1, -barH)
            bottomBar.Size = UDim2.new(1, 0, 0, barH)

            leftBar.Visible = false
            rightBar.Visible = false
        else
            leftBar.Visible = false
            rightBar.Visible = false
            topBar.Visible = false
            bottomBar.Visible = false
        end
    end

    _G.MM2_UpdateStretchedResolution = function()
        if not Config.StretchedRes and blackBarsGui then
            blackBarsGui.Enabled = false
        end
    end

    RunService.RenderStepped:Connect(function(dt)
        -- Tactical Shoulder Camera
        if Config.ShoulderCamera and Camera and Camera.CameraType == Enum.CameraType.Custom then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                Camera.CFrame = Camera.CFrame * CFrame.new(1.75, 0.25, 0)
            end
        end

        -- Dynamic Sprint FOV
        if Config.DynamicSprintFOV and Camera then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local baseFOV = Config.CameraFOV or 70
            local targetFOV = baseFOV
            if hum and hum.MoveDirection.Magnitude > 0.1 and hum.WalkSpeed > 16 then
                targetFOV = baseFOV + 12
            end
            if math.abs(Camera.FieldOfView - targetFOV) > 0.1 then
                Camera.FieldOfView = Camera.FieldOfView + (targetFOV - Camera.FieldOfView) * math.clamp(dt * 8, 0.05, 0.3)
            end
        end

        -- Stretched Resolution Engine
        if Config.StretchedRes and Camera then
            local vp = Camera.ViewportSize
            if vp.X > 0 and vp.Y > 0 then
                local nativeAspect = vp.X / vp.Y
                local preset = Config.StretchPreset or "4:3 (CS:GO Wide)"
                local isCustom = preset:find("Custom") ~= nil

                local targetAspect = getTargetAspect(preset)
                local factor = 0.75

                if isCustom then
                    factor = Config.StretchFactor or ((Config.StretchFactorPercent or 75) / 100)
                elseif Config.StretchAutoAspect and targetAspect then
                    factor = targetAspect / nativeAspect
                else
                    factor = Config.StretchFactor or (targetAspect / 1.7778)
                end

                if factor < 0.25 then factor = 0.25 end
                if factor > 2.0 then factor = 2.0 end

                local modelMultiplier = Config.StretchModelWidth or ((Config.StretchModelWidthPercent or 100) / 100)
                if modelMultiplier < 0.2 then modelMultiplier = 0.2 end
                if modelMultiplier > 2.5 then modelMultiplier = 2.5 end

                local finalY = factor / modelMultiplier

                if Config.StretchBlackBars and not isCustom and targetAspect then
                    updateBlackBars(vp.X, vp.Y, targetAspect)
                    finalY = 1.0 / modelMultiplier
                else
                    if blackBarsGui and blackBarsGui.Enabled then
                        blackBarsGui.Enabled = false
                    end
                end

                Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, finalY, 0, 0, 0, 1)
            end
        else
            if blackBarsGui and blackBarsGui.Enabled then
                blackBarsGui.Enabled = false
            end
        end
    end)

    -- ----------------------------------------------------------------
    -- CLEANUP HOOK
    -- ----------------------------------------------------------------
    _G.MM2_CleanupVisuals = function()
        destroyCrosshair()
        destroyHalo()
        destroyFeetTrails()
        destroyChromaSkin()
        destroyBackWings()
        destroyLaserEyes()
        destroyWeaponFlame()
        if damageVignetteGui then pcall(function() damageVignetteGui:Destroy() end) damageVignetteGui = nil end
        if activeBloom then pcall(function() activeBloom:Destroy() end) activeBloom = nil end
        if activeCC then pcall(function() activeCC:Destroy() end) activeCC = nil end
        if activeDOF then pcall(function() activeDOF:Destroy() end) activeDOF = nil end
        if activeSunRays then pcall(function() activeSunRays:Destroy() end) activeSunRays = nil end
        if activeCustomSky then pcall(function() activeCustomSky:Destroy() end) activeCustomSky = nil end
        if blackBarsGui then pcall(function() blackBarsGui:Destroy() end) blackBarsGui = nil end
        for _, inst in ipairs(VisualInstances) do
            pcall(function() if inst and inst.Parent then inst:Destroy() end end)
        end
        VisualInstances = {}
    end

    -- Initial triggers on load
    task.delay(1.0, function()
        if Config.CustomCrosshair then buildCrosshair() end
        if Config.GlowBloom then _G.MM2_UpdateBloom(true) end
        if Config.ColorCorrectionPreset and Config.ColorCorrectionPreset ~= "None" then _G.MM2_UpdateColorCorrection(Config.ColorCorrectionPreset) end
        if Config.DepthOfField then _G.MM2_UpdateDepthOfField(true) end
        if Config.SunRaysFX then _G.MM2_UpdateSunRays(true) end
        if Config.CustomSkybox and Config.CustomSkybox ~= "Default" then _G.MM2_UpdateSkybox(Config.CustomSkybox) end
        if Config.DamageVignette then setupScreenFXGui() end
        if Config.HaloAura and LocalPlayer.Character then createHalo(LocalPlayer.Character) end
        if Config.FeetTrails and LocalPlayer.Character then createFeetTrails(LocalPlayer.Character) end
        if Config.ChromaSkin and LocalPlayer.Character then setupChromaSkin(LocalPlayer.Character) end
        if Config.BackWingsVisual and LocalPlayer.Character then createBackWings(LocalPlayer.Character) end
        if Config.LaserEyes and LocalPlayer.Character then createLaserEyes(LocalPlayer.Character) end
    end)
end)()

;(function()
    -- 2. TRAP ESP & DISARM
    local activeTrapVisuals = {}

    local function getActiveTraps()
        local traps = {}
        local curMap = CachedMap or (getCurrentMap and getCurrentMap())
        local searchRoots = {workspace}
        if curMap then table.insert(searchRoots, curMap) end

        for _, rootObj in ipairs(searchRoots) do
            for _, obj in ipairs(rootObj:GetChildren()) do
                if obj:IsA("Model") or obj:IsA("BasePart") then
                    local n = obj.Name:lower()
                    if (n == "trap" or n == "beartrap" or string.find(n, "trap")) then
                        local primary = (obj:IsA("BasePart") and obj) or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                        if primary and not primary:IsDescendantOf(LocalPlayer.Character or workspace) then
                            table.insert(traps, {Instance = obj, Part = primary})
                        end
                    end
                end
            end
        end
        return traps
    end

    local function disarmSingleTrap(trapObj, trapPart)
        pcall(function()
            if trapPart then
                trapPart.CanTouch = false
                trapPart.CanCollide = false
                trapPart.CFrame = CFrame.new(0, -9999, 0)
            end
            local trapSys = ReplicatedStorage:FindFirstChild("TrapSystem")
            if trapSys then
                local hitLocal = trapSys:FindFirstChild("TrapHitLocal")
                if hitLocal then hitLocal:FireServer(trapObj) end
                local notif = trapSys:FindFirstChild("TrapNotification")
                if notif then notif:FireServer(trapObj) end
            end
        end)
    end

    _G.MM2_DisarmAllTraps = function()
        local traps = getActiveTraps()
        local count = 0
        for _, t in ipairs(traps) do
            disarmSingleTrap(t.Instance, t.Part)
            count = count + 1
        end
        if showNotification then
            showNotification("🛡️ ЛОВУШКИ ОБЕЗВРЕЖЕНЫ", string.format("Обезврежено ловушек: %d", count), Color3.fromRGB(50, 220, 100), "🪤", 3)
        end
        if flashDynamicIslandAlert then
            flashDynamicIslandAlert("🪤 ALL TRAPS DISARMED (" .. count .. ")", Color3.fromRGB(50, 220, 100), 2.5)
        end
    end

    -- Trap ESP & Auto-Disarm Loop
    task.spawn(function()
        while _G.MM2_Hub_Running and (_G.MM2_Hub_InstanceID == InstanceID) do
            task.wait(0.5)
            local traps = getActiveTraps()
            local root = getLocalRoot()
            local myPos = root and root.Position or Vector3.zero

            if Config.TrapESP then
                local seen = {}
                for _, t in ipairs(traps) do
                    local inst = t.Instance
                    local part = t.Part
                    seen[inst] = true

                    if not activeTrapVisuals[inst] then
                        local hl = Instance.new("Highlight")
                        hl.Name = "TrapHL"
                        hl.FillColor = Color3.fromRGB(255, 60, 40)
                        hl.OutlineColor = Color3.fromRGB(255, 230, 60)
                        hl.FillTransparency = 0.35
                        hl.OutlineTransparency = 0
                        hl.Adornee = inst
                        hl.Parent = container

                        local bb = Instance.new("BillboardGui")
                        bb.Name = "TrapBB"
                        bb.Size = UDim2.new(0, 130, 0, 36)
                        bb.StudsOffset = Vector3.new(0, 2.2, 0)
                        bb.AlwaysOnTop = true
                        bb.Adornee = part
                        bb.Parent = container

                        local txt = Instance.new("TextLabel")
                        txt.Size = UDim2.new(1, 0, 1, 0)
                        txt.BackgroundTransparency = 1
                        txt.Font = Enum.Font.GothamBlack
                        txt.TextSize = 11
                        txt.TextColor3 = Color3.fromRGB(255, 80, 60)
                        txt.TextStrokeTransparency = 0.2
                        txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        txt.Text = "⚠️ TRAP"
                        txt.Parent = bb

                        activeTrapVisuals[inst] = {Highlight = hl, Billboard = bb, Label = txt, Part = part}
                    else
                        local data = activeTrapVisuals[inst]
                        local dist = math.floor((part.Position - myPos).Magnitude)
                        data.Label.Text = string.format("⚠️ TRAP [%dm]", dist)
                    end

                    -- Auto Disarm check
                    if Config.AutoDisarmTraps and root then
                        local dist = (part.Position - myPos).Magnitude
                        if dist <= 16 then
                            disarmSingleTrap(inst, part)
                            if flashDynamicIslandAlert then
                                flashDynamicIslandAlert("🛡️ TRAP AUTO-DISARMED!", Color3.fromRGB(50, 220, 100), 2)
                            end
                        end
                    end
                end

                for inst, data in pairs(activeTrapVisuals) do
                    if not seen[inst] or not inst.Parent then
                        pcall(function() data.Highlight:Destroy() end)
                        pcall(function() data.Billboard:Destroy() end)
                        activeTrapVisuals[inst] = nil
                    end
                end
            else
                for inst, data in pairs(activeTrapVisuals) do
                    pcall(function() data.Highlight:Destroy() end)
                    pcall(function() data.Billboard:Destroy() end)
                    activeTrapVisuals[inst] = nil
                end
            end
        end
    end)

end)()

;(function()
    -- 3. AUTO-PRESTIGE SYSTEM
    local function getPlayerLevelDirect()
        local lvl = nil
        pcall(function()
            local mainGui = LocalPlayer.PlayerGui:FindFirstChild("MainGUI")
            local gameGui = mainGui and mainGui:FindFirstChild("Game")
            local lvlGui = gameGui and gameGui:FindFirstChild("Level")
            local lvlText = lvlGui and lvlGui:FindFirstChild("LevelText")
            if lvlText and lvlText.Text then
                lvl = tonumber(lvlText.Text)
            end
        end)
        if not lvl then
            pcall(function()
                local rf = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Extras") and ReplicatedStorage.Remotes.Extras:FindFirstChild("GetPlayerLevel")
                if rf then lvl = tonumber(rf:InvokeServer()) end
            end)
        end
        return lvl
    end

    _G.MM2_PerformPrestigeNow = function()
        local lvl = getPlayerLevelDirect()
        pcall(function()
            local presRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Inventory") and ReplicatedStorage.Remotes.Inventory:FindFirstChild("Prestige")
            if presRemote then presRemote:FireServer() end
        end)
        pcall(function()
            local pframe = LocalPlayer.PlayerGui.MainGUI.Game:FindFirstChild("Prestige")
            local acc = pframe and pframe:FindFirstChild("Accept")
            if acc and firesignal then firesignal(acc.MouseButton1Click) end
        end)
        if showNotification then
            showNotification("⭐ PRESTIGE", "Запрос на Престиж отправлен серверу!", Color3.fromRGB(255, 215, 0), "⭐", 4)
        end
        if flashDynamicIslandAlert then
            flashDynamicIslandAlert("⭐ PRESTIGE TRIGGERED!", Color3.fromRGB(255, 215, 0), 3)
        end
    end

    -- 🎁 AUTO CLAIM BATTLE PASS REWARDS
    _G.MM2_ClaimBattlePassRewards = function(isManual)
        local totalClaimed = 0
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local eventTitle = nil
            pcall(function()
                local eventInfoService = require(rs.SharedServices.EventInfoService):WaitForInitializedAsync()
                local mainEvent = eventInfoService and eventInfoService:GetMainEvent()
                if mainEvent and mainEvent.Title then
                    eventTitle = mainEvent.Title
                end
            end)
            local remotes = rs:FindFirstChild("Remotes")
            local events = remotes and remotes:FindFirstChild("Events")
            local eventRemotes = nil
            if events then
                if eventTitle and events:FindFirstChild(eventTitle .. "Remotes") then
                    eventRemotes = events:FindFirstChild(eventTitle .. "Remotes")
                else
                    for _, ch in ipairs(events:GetChildren()) do
                        if ch.Name:find("Remotes") and ch:FindFirstChild("ClaimBattlePassReward") then
                            eventRemotes = ch
                            if not eventTitle then
                                eventTitle = ch.Name:gsub("Remotes", "")
                            end
                            break
                        end
                    end
                end
            end
            if not eventRemotes or not eventTitle then return end

            local claimRemote = eventRemotes:FindFirstChild("ClaimBattlePassReward")
            if not claimRemote then return end

            local profileData = nil
            pcall(function()
                profileData = require(rs.Modules.ProfileData)
            end)
            local pData = profileData and profileData[eventTitle]
            if not pData then return end

            local currentTier = pData.CurrentTier or 0
            local claimed = pData.ClaimedRewards or {}

            local totalTiers = 30
            pcall(function()
                local eventInfoService = require(rs.SharedServices.EventInfoService):WaitForInitializedAsync()
                local mainEvent = eventInfoService and eventInfoService:GetMainEvent()
                if mainEvent and mainEvent.EventStartInfo and mainEvent.EventStartInfo.BattlePass then
                    totalTiers = mainEvent.EventStartInfo.BattlePass.TotalTiers or 30
                end
            end)

            local claimedTiers = {}
            for tier = 1, currentTier do
                local tierStr = tostring(tier)
                if (tier ~= totalTiers) and (claimed[tierStr] ~= true) then
                    pcall(function()
                        claimRemote:FireServer(tierStr)
                    end)
                    table.insert(claimedTiers, tier)
                    task.wait(0.12)
                end
            end

            totalClaimed = #claimedTiers
            if totalClaimed > 0 then
                task.delay(0.35, function()
                    pcall(function()
                        local lp = game.Players.LocalPlayer
                        local cp = lp and lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("CrossPlatform")
                        local newItemGui = cp and cp:FindFirstChild("NewItem")
                        local medium = newItemGui and newItemGui:FindFirstChild("Medium")
                        if medium and medium.Visible then
                            local container = medium:FindFirstChild("Container")
                            local claimBtn = container and container:FindFirstChild("Claim")
                            if claimBtn and claimBtn:IsA("GuiButton") then
                                if getconnections then
                                    for _, c in ipairs(getconnections(claimBtn.Activated)) do
                                        pcall(function() c:Fire() end)
                                    end
                                end
                            end
                            medium.Visible = false
                            local lighting = game:GetService("Lighting")
                            local blur = lighting:FindFirstChild("NewItemBlur")
                            if blur then blur.Enabled = false end
                        end
                    end)
                end)

                if showNotification then
                    local tierListStr = table.concat(claimedTiers, ", ")
                    showNotification("🎁 AUTO PASS", string.format("Забраны награды за Tier: %s!", tierListStr), Color3.fromRGB(255, 180, 50), "🎁", 4.5)
                end
                if flashDynamicIslandAlert then
                    flashDynamicIslandAlert(string.format("🎁 PASS CLAIMED (x%d)", totalClaimed), Color3.fromRGB(255, 180, 50), 3)
                end
            end
        end)
        return totalClaimed
    end

    -- 🎃 AUTO BUY BATTLE PASS TIERS (600 Candies / Skip Tier)
    _G.MM2_BuyBattlePassTiers = function(numTiers)
        numTiers = numTiers or 1
        local bought = 0
        local reason = nil
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local eventTitle = nil
            local tierCost = 600
            local totalTiers = 30
            local currName = "Candies2026"

            -- 1. Resolve event info from EventInfoService
            pcall(function()
                local eis = rs:FindFirstChild("SharedServices") and rs.SharedServices:FindFirstChild("EventInfoService")
                if eis then
                    local eventInfoService = require(eis)
                    local mainEvent = eventInfoService and eventInfoService:GetMainEvent()
                    if mainEvent then
                        eventTitle = mainEvent.Title or "Halloween2026"
                        if mainEvent.EventStartInfo then
                            currName = mainEvent.EventStartInfo.CurrencyName or currName
                            if mainEvent.EventStartInfo.BattlePass then
                                tierCost = mainEvent.EventStartInfo.BattlePass.TierCost or tierCost
                                totalTiers = mainEvent.EventStartInfo.BattlePass.TotalTiers or totalTiers
                            end
                        end
                    end
                end
            end)

            -- 2. Resolve ProfileData and Candy Balance
            local profileData = nil
            pcall(function()
                local m = rs:FindFirstChild("Modules") and rs.Modules:FindFirstChild("ProfileData")
                if m then profileData = require(m) end
            end)

            local pData = nil
            if profileData then
                if eventTitle and profileData[eventTitle] then
                    pData = profileData[eventTitle]
                else
                    for k, v in pairs(profileData) do
                        if type(v) == "table" and v.CurrentTier ~= nil then
                            pData = v
                            eventTitle = k
                            break
                        end
                    end
                end
            end

            local currentTier = (pData and pData.CurrentTier) or 0
            if currentTier >= totalTiers then
                -- Check final reward claim
                pcall(function()
                    local evRemotes = rs:FindFirstChild("Remotes") and rs.Remotes:FindFirstChild("Events")
                    local hr = evRemotes and evRemotes:FindFirstChild(eventTitle .. "Remotes")
                    local finalRemote = hr and hr:FindFirstChild("BuyBattlePassFinalReward")
                    if finalRemote then finalRemote:FireServer() end
                end)
                reason = "max_tier"
                return
            end

            -- 3. Calculate owned candies dynamically
            local ownedCandies = 0
            if profileData and profileData.Materials and profileData.Materials.Owned then
                if currName and profileData.Materials.Owned[currName] then
                    ownedCandies = profileData.Materials.Owned[currName]
                end
                if ownedCandies == 0 then
                    for mat, count in pairs(profileData.Materials.Owned) do
                        if type(count) == "number" and tostring(mat):lower():find("cand") then
                            ownedCandies = math.max(ownedCandies, count)
                        end
                    end
                end
            end
            if ownedCandies == 0 and _G.MM2_GetCandyBalance then
                ownedCandies = _G.MM2_GetCandyBalance() or 0
            end

            local affordableTiers = math.floor(ownedCandies / tierCost)
            local remainingTiers = totalTiers - currentTier
            local toBuy = math.min(numTiers, affordableTiers, remainingTiers)

            if toBuy <= 0 then
                reason = "not_enough_candies"
                return
            end

            -- 4. Locate Buy Remote (Direct Server Call)
            local buyRemote = nil
            pcall(function()
                local remotes = rs:FindFirstChild("Remotes")
                local events = remotes and remotes:FindFirstChild("Events")
                if events then
                    if eventTitle and events:FindFirstChild(eventTitle .. "Remotes") then
                        buyRemote = events[eventTitle .. "Remotes"]:FindFirstChild("BuyBattlePassTiers")
                    end
                    if not buyRemote then
                        for _, ch in ipairs(events:GetChildren()) do
                            if ch.Name:find("Remotes") and ch:FindFirstChild("BuyBattlePassTiers") then
                                buyRemote = ch:FindFirstChild("BuyBattlePassTiers")
                                break
                            end
                        end
                    end
                end
                if not buyRemote and remotes then
                    buyRemote = remotes:FindFirstChild("BuyBattlePassTiers", true)
                end
            end)

            if buyRemote then
                pcall(function()
                    if buyRemote:IsA("RemoteFunction") then
                        buyRemote:InvokeServer(toBuy)
                    else
                        buyRemote:FireServer(toBuy)
                    end
                end)
            end

            -- 5. UI Button Click Simulation (Supports Xeno, Solara & VIM)
            pcall(function()
                local lp = game:GetService("Players").LocalPlayer
                local cp = lp and lp:FindFirstChild("PlayerGui") and lp.PlayerGui:FindFirstChild("CrossPlatform")
                local eventGui = cp and (cp:FindFirstChild(eventTitle or "Halloween2026") or cp:FindFirstChild("Halloween2026", true))
                local main = eventGui and eventGui:FindFirstChild("MainEvent") and eventGui.MainEvent:FindFirstChild("Main")
                local bp = main and main:FindFirstChild("BattlePass")
                local buyTiers = bp and bp:FindFirstChild("BuyTiers")
                local tokenBuy = buyTiers and buyTiers:FindFirstChild("TokenBuy")
                local buyBtn = tokenBuy and tokenBuy:FindFirstChild("Container") and tokenBuy.Container:FindFirstChild("BuyButton")
                local btn = buyBtn and buyBtn:FindFirstChild("Button")
                if btn then
                    if getconnections then
                        for _, c in ipairs(getconnections(btn.MouseButton1Down)) do pcall(function() c:Fire() end) end
                        task.wait(0.04)
                        for _, c in ipairs(getconnections(btn.MouseButton1Up)) do pcall(function() c:Fire() end) end
                    elseif firesignal then
                        pcall(function() firesignal(btn.MouseButton1Down) end)
                        pcall(function() firesignal(btn.MouseButton1Up) end)
                    else
                        pcall(function()
                            local vim = game:GetService("VirtualInputManager")
                            local absPos = btn.AbsolutePosition
                            local absSize = btn.AbsoluteSize
                            vim:SendMouseButtonEvent(absPos.X + absSize.X / 2, absPos.Y + absSize.Y / 2, 0, true, game, 1)
                            task.wait(0.04)
                            vim:SendMouseButtonEvent(absPos.X + absSize.X / 2, absPos.Y + absSize.Y / 2, 0, false, game, 1)
                        end)
                    end
                end
            end)

            bought = toBuy
            if pData then
                pData.CurrentTier = pData.CurrentTier + toBuy
            end

            if showNotification then
                showNotification("🎃 BATTLE PASS", string.format("Куплен уровень Пасса (+%d) за %d конфет!", toBuy, toBuy * tierCost), Color3.fromRGB(255, 170, 40), "🎃", 4.5)
            end
            if flashDynamicIslandAlert then
                flashDynamicIslandAlert(string.format("🎃 PASS TIER BOUGHT (+%d)", toBuy), Color3.fromRGB(255, 170, 40), 3.5)
            end

            -- 6. Automatically claim newly unlocked rewards
            task.delay(0.5, function()
                if _G.MM2_ClaimBattlePassRewards then
                    _G.MM2_ClaimBattlePassRewards(false)
                end
            end)
        end)
        return bought, reason
    end

    -- Real-time BindableEvent connection to ProfileDataChanged
    pcall(function()
        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        local inv = remotes and remotes:FindFirstChild("Inventory")
        local pdc = inv and inv:FindFirstChild("ProfileDataChanged")
        if pdc and pdc:IsA("BindableEvent") then
            pdc.Event:Connect(function()
                if Config.AutoBuyPassTiers then
                    task.delay(0.3, function()
                        if _G.MM2_BuyBattlePassTiers then
                            _G.MM2_BuyBattlePassTiers(1)
                        end
                    end)
                end
                if Config.AutoClaimPass ~= false then
                    task.delay(0.8, function()
                        if _G.MM2_ClaimBattlePassRewards then
                            _G.MM2_ClaimBattlePassRewards(false)
                        end
                    end)
                end
            end)
        end
    end)

    task.spawn(function()
        local lastPassClaimCheck = 0
        local lastPassBuyCheck = 0
        while _G.MM2_Hub_Running and (_G.MM2_Hub_InstanceID == InstanceID) do
            task.wait(3.5)
            if Config.AutoPrestige then
                local lvl = getPlayerLevelDirect()
                if lvl and lvl >= 100 then
                    _G.MM2_PerformPrestigeNow()
                    task.wait(5)
                end
            end
            local now = os.clock()
            if Config.AutoBuyPassTiers and (now - lastPassBuyCheck > 8) then
                lastPassBuyCheck = now
                if _G.MM2_BuyBattlePassTiers then
                    _G.MM2_BuyBattlePassTiers(1)
                end
            end
            if Config.AutoClaimPass ~= false and (now - lastPassClaimCheck > 12) then
                lastPassClaimCheck = now
                if _G.MM2_ClaimBattlePassRewards then
                    _G.MM2_ClaimBattlePassRewards(false)
                end
            end
        end
    end)

end)()

;(function()
    -- 4. CINEMATIC COIN CAMERA (Smooth top-down tracking towards active farm coin)
    RunService:BindToRenderStep("MM2_CinematicCoinCam", Enum.RenderPriority.Camera.Value + 1, function()
        if Config.CoinCinematicCamera and Config.CoinAutoFarm and _G.MM2_TargetCoin and _G.MM2_TargetCoin.Parent and not isPlayerInLobby(LocalPlayer) then
            local cam = workspace.CurrentCamera
            if cam then
                local cPart = (_G.MM2_TargetCoin:FindFirstChild("CoinVisual") and _G.MM2_TargetCoin.CoinVisual:IsA("BasePart") and _G.MM2_TargetCoin.CoinVisual) or (_G.MM2_TargetCoin:IsA("BasePart") and _G.MM2_TargetCoin)
                if cPart then
                    local cPos = cPart.Position
                    local desiredCamPos = cPos + Vector3.new(0, 9.0, 3.5)
                    local targetCamCf = CFrame.lookAt(desiredCamPos, cPos)
                    cam.CFrame = cam.CFrame:Lerp(targetCamCf, 0.12)
                end
            end
        end
    end)

end)()

;(function()
    -- 5. MM2 EMOTES UNLOCKER & FUN (Knife Spin, Fake Dead, Free Emotes)
    local activeEmoteTrack = nil
    local EmoteCatalog = {
        ninja = {id = "rbxassetid://2431864798", loop = true, name = "Ninja"},
        dab = {id = "rbxassetid://2445521505", loop = false, name = "Dab"},
        floss = {id = "rbxassetid://2452938820", loop = true, name = "Floss"},
        zen = {id = "rbxassetid://2431812646", loop = true, name = "Zen"},
        sit = {id = "rbxassetid://2431845940", loop = true, name = "Sit"},
        zombie = {id = "rbxassetid://2513692312", loop = true, name = "Zombie"},
        pray = {id = "rbxassetid://342939766", loop = true, name = "Pray"},
    }

    _G.MM2_PlayEmote = function(key)
        local data = EmoteCatalog[key]
        if not data then return end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        if activeEmoteTrack then
            pcall(function() activeEmoteTrack:Stop() end)
            activeEmoteTrack = nil
        end

        local anim = Instance.new("Animation")
        anim.AnimationId = data.id
        local track = hum:LoadAnimation(anim)
        track.Looped = (data.loop == true)
        track:Play()
        activeEmoteTrack = track

        if showNotification then
            showNotification("🎭 MM2 EMOTE", "Воспроизведение эмоции: " .. data.name, Color3.fromRGB(150, 100, 255), "🎭", 2.5)
        end
        if flashDynamicIslandAlert then
            flashDynamicIslandAlert("🎭 EMOTE: " .. data.name:upper(), Color3.fromRGB(150, 100, 255), 2)
        end
    end

    _G.MM2_StopEmote = function()
        if activeEmoteTrack then
            pcall(function() activeEmoteTrack:Stop() end)
            activeEmoteTrack = nil
        end
    end

    -- Auto-cancel emote when moving
    RunService.Heartbeat:Connect(function()
        if activeEmoteTrack and activeEmoteTrack.IsPlaying then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.MoveDirection.Magnitude > 0.1 then
                activeEmoteTrack:Stop()
                activeEmoteTrack = nil
            end
        end
    end)

    -- Fake Dead / Ragdoll
    _G.MM2_SetFakeDead = function(enabled)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end

        if enabled then
            hum.PlatformStand = true
            root.CFrame = root.CFrame * CFrame.Angles(math.rad(-90), 0, math.rad(math.random(0, 360)))
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
            if flashDynamicIslandAlert then
                flashDynamicIslandAlert("💀 FAKE DEAD ACTIVE", Color3.fromRGB(255, 60, 60), 2)
            end
        else
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
            if flashDynamicIslandAlert then
                flashDynamicIslandAlert("🏃 GOT BACK UP", Color3.fromRGB(50, 220, 100), 2)
            end
        end
    end

    -- Knife Spin / Inspect Loop
    local knifeSpinAngle = 0
    RunService.RenderStepped:Connect(function(dt)
        if not Config.KnifeSpin then return end
        local char = LocalPlayer.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return end
        local isKnife = tool.Name == "Knife" or string.find(tool.Name:lower(), "knife") or tool:FindFirstChild("Handle")
        if not isKnife then return end

        local origGrip = tool:GetAttribute("OrigGrip")
        if not origGrip then
            tool:SetAttribute("OrigGrip", tool.Grip)
            origGrip = tool.Grip
        end

        knifeSpinAngle = (knifeSpinAngle + dt * 480) % 360
        local wobble = math.sin(math.rad(knifeSpinAngle * 2)) * 0.15
        tool.Grip = origGrip * CFrame.Angles(math.rad(knifeSpinAngle), wobble, 0)
    end)
end)()

-- Cinematic Startup Sequence (Splash Intro -> Welcome Modal -> Dynamic Island)
task.spawn(function()
    task.wait(0.35)
    pcall(function()
        if Config.ShowWelcome ~= false then
            if _G.MM2_ShowSplashIntro then
                _G.MM2_ShowSplashIntro(function()
                    if showWelcomeModal then
                        showWelcomeModal()
                    end
                end)
            elseif showWelcomeModal then
                showWelcomeModal()
            end
        else
            if _G.MM2_RevealDynamicIsland then
                _G.MM2_RevealDynamicIsland()
            end
        end
    end)
end)

print("[VORTEX PRIME MM2 • BETA] Successfully Loaded! Dynamic Island, Smart Cluster Farm, Spectate & 3D Render active.")
_G.MM2_Hub_Initializing = nil
