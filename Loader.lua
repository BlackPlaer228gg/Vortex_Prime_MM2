--[[
    ====================================================================
    ⚡ VORTEX PRIME MM2 • SMART UNIVERSAL LOADER
    GitHub: https://github.com/BlackPlaer228gg/Vortex_Prime_MM2
    Author: BlackPlaer228gg
    Supports: 100% All Executors (Potassium, Real, Wave, Solara, Xeno 40% sUNC, Delta, etc.)
    ====================================================================
--]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- 1. Identify Executor & Capabilities
local executor = (identifyexecutor and identifyexecutor())
    or (getexecutorname and getexecutorname())
    or "Unknown"

local isMobile = game:GetService("UserInputService").TouchEnabled and not game:GetService("UserInputService").KeyboardEnabled
local deviceTag = isMobile and " [📱 Mobile]" or " [💻 PC]"

print(string.format("[VORTEX PRIME] Запуск на инжекторе: %s%s...", tostring(executor), deviceTag))

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "⚡ VORTEX PRIME MM2",
        Text = "Инжектор: " .. tostring(executor) .. deviceTag .. "\nЗагрузка скрипта с GitHub...",
        Duration = 3,
    })
end)

-- 2. Select Target Script
local baseURL = "https://raw.githubusercontent.com/BlackPlaer228gg/Vortex_Prime_MM2/main/"
local mainScript = (_G.Vortex_Force_Legacy == true) and "Vortex_Prime_Legacy.lua" or "Vortex_Prime_MM2.lua"
local mainURL = baseURL .. mainScript .. "?t=" .. tostring(os.time())

-- 3. Fetch & Execute Main Script
local success, source = pcall(function()
    return game:HttpGet(mainURL, true)
end)

if success and type(source) == "string" and #source > 500 then
    local executable, compileErr = loadstring(source)
    if executable then
        task.spawn(executable)
        print("[VORTEX PRIME] Скрипт успешно запущен!")
        return
    else
        warn("[VORTEX PRIME] Ошибка компиляции основного скрипта: " .. tostring(compileErr))
    end
end

-- Fallback to Legacy Build if main script failed or was blocked
warn("[VORTEX PRIME] Попытка загрузки резервной версии (Legacy Edition)...")
local fallbackURL = baseURL .. "Vortex_Prime_Legacy.lua?t=" .. tostring(os.time())
local fbSuccess, fbSource = pcall(function()
    return game:HttpGet(fallbackURL, true)
end)

if fbSuccess and type(fbSource) == "string" and #fbSource > 500 then
    local fbExecutable, fbErr = loadstring(fbSource)
    if fbExecutable then
        task.spawn(fbExecutable)
        print("[VORTEX PRIME] Резервная версия Legacy успешно запущена!")
        return
    else
        warn("[VORTEX PRIME] Ошибка компиляции Legacy версии: " .. tostring(fbErr))
    end
end

warn("[VORTEX PRIME] Не удалось загрузить скрипт с GitHub. Проверьте интернет-соединение или статус GitHub.")
