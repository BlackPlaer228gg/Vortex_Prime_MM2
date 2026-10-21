--[[
    ====================================================================
    ⚡ VORTEX PRIME MM2 • UNIVERSAL LOADER
    GitHub: https://github.com/BlackPlaer228gg/Vortex_Prime_MM2
    Author: BlackPlaer228gg
    ====================================================================
--]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- 1. Identify Platform & Executor
local executor = (identifyexecutor and identifyexecutor())
    or (getexecutorname and getexecutorname())
    or "Unknown"

local isMobile = game:GetService("UserInputService").TouchEnabled and not game:GetService("UserInputService").KeyboardEnabled
local deviceTag = isMobile and " [📱 Mobile]" or " [💻 PC]"

print(string.format("[VORTEX PRIME] Запуск на инжекторе: %s%s...", tostring(executor), deviceTag))

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "⚡ VORTEX PRIME MM2",
        Text = "Инжектор: " .. tostring(executor) .. deviceTag .. "\nЗагрузка скрипта...",
        Duration = 3,
    })
end)

-- 2. Fetch & Execute Main Script
local mainURL = "https://raw.githubusercontent.com/BlackPlaer228gg/Vortex_Prime_MM2/main/Vortex_Prime_MM2.lua?t=" .. tostring(os.time())

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

warn("[VORTEX PRIME] Не удалось загрузить скрипт с GitHub. Проверьте интернет-соединение.")
