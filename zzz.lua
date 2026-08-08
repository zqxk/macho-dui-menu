-- bypass
local function executeCode(resource, code)
    local setFullCode = [[
        local _rawEnv = _ENV
        _G.fn = function(setFunc, ...)
            local stateName = math.random(999999,999999999)..GetCurrentResourceName()..GetGameTimer()
            LocalPlayer.state:set(stateName, setFunc, false)
            return LocalPlayer.state[stateName](...)
        end

        local _autoEnv = setmetatable({}, {
            __index = function(_, k)
                local v = rawget(_rawEnv, k)
                if v == nil then v = _rawEnv[k] end
                if type(v) == "function" then
                    return function(...) return _G.fn(v, ...) end
                end
                return v
            end,
            __newindex = function(_, k, v)
                rawset(_rawEnv, k, v)
            end
        })
        local setFunc, _err = load(SET_CODE, " = (inject)", "t", _autoEnv)
        if setFunc then setFunc() end
    ]]

    local setCode = setFullCode:gsub("SET_CODE", string.format("[[\n%s\n]]", code))

    -- Anti-Cheat routing logic
    if GetResourceState('ReaperV4') == 'started' then
        MachoInjectResource2(2, resource, setCode)
    elseif GetResourceState('WaveShield') == 'started' then
        MachoInjectThread(0, resource, "t", code)
    else
        MachoInjectResource2(2, resource, setCode)
    end
end

------------------------------------------------------------
-- MachoMenu (@qxk) - Template Base
------------------------------------------------------------
local MenuSize = vec2(600, 400)
local MenuStartCoords = vec2(500, 500)
local TabsBarWidth = 135

local SectionsPadding = 10
local MachoPanelGap = 10

local SectionChildWidth = MenuSize.x - TabsBarWidth
local SectionChildHeight = MenuSize.y - (2 * SectionsPadding)

local TotalHeight = SectionChildHeight - MachoPanelGap
local ColumnWidth = (SectionChildWidth - (SectionsPadding * 3)) / 2

local leftX = TabsBarWidth + SectionsPadding
local topY  = SectionsPadding + MachoPanelGap
local rightX = leftX + ColumnWidth + SectionsPadding

------------------------------------------------------------
-- MENU SETUP
------------------------------------------------------------
local MenuWindow = MachoMenuTabbedWindow("xdlolidk", MenuStartCoords.x, MenuStartCoords.y, MenuSize.x, MenuSize.y, TabsBarWidth)
MachoMenuSetKeybind(MenuWindow, 0x14)
MachoMenuSetAccent(MenuWindow, 52, 137, 235)

local SelfTab     = MachoMenuAddTab(MenuWindow, "self")
local MiscTab     = MachoMenuAddTab(MenuWindow, "misc")
local idkxdlol    = MachoMenuAddTab(MenuWindow, "idkxdlol")
local TeleportTab = MachoMenuAddTab(MenuWindow, "teleport")
local OutfitsTab  = MachoMenuAddTab(MenuWindow, "outfits")
local VehicleTab  = MachoMenuAddTab(MenuWindow, "vehicle")

------------------------------------------------------------
-- SELF TAB
------------------------------------------------------------
do
    local S1 = MachoMenuGroup(SelfTab, "Self", leftX, topY, leftX + ColumnWidth, topY + TotalHeight)
    local S2 = MachoMenuGroup(SelfTab, "Misc", rightX, topY, rightX + ColumnWidth, topY + TotalHeight)

    MachoMenuButton(S1, "Revive", function()
        MachoInjectResource2(NewThreadNs, 'pug-paintball', [[TriggerEvent("Pug:client:PaintballReviveEvent")]])
        MachoMenuNotification("Self", "Revive Sent", {90, 255, 90})
    end)

    MachoMenuButton(S1, "Skin Menu", function()
        MachoInjectResource2(NewThreadNs, 'illenium-appearance', [[
        TriggerEvent("illenium-appearance:client:openClothingShop", true)
        ]])
    end)

    MachoMenuButton(S1, "Max Food & Drink", function()
    MachoInjectResource2(NewThreadNs, 'fivecode_camping', [[
        local fillAmount = 1000000
        TriggerEvent('esx_status:add', 'hunger', fillAmount)
        TriggerEvent('esx_status:add', 'thirst', fillAmount)
        TriggerEvent('esx_status:add', 'stress', -fillAmount)
        ]])
        MachoMenuNotification("ESX Status", "Hunger & Thirst Maxed", {50, 200, 50})
    end)
end

------------------------------------------------------------
-- MISC TAB (Split Left/Right)
------------------------------------------------------------
do
    -- Left Section (Drugs Harvester)
    local MiscLeft = MachoMenuGroup(MiscTab, "Drugs Harvester", leftX, topY, leftX + ColumnWidth, topY + TotalHeight)
    
    local DrugIDInput    = MachoMenuInputbox(MiscLeft, "Drug ID", "27")
    local LoopCountInput = MachoMenuInputbox(MiscLeft, "Loop Count", "10")
    local DelayInput     = MachoMenuInputbox(MiscLeft, "Delay (ms)", "50")

    -- One-time Burst Harvest Button
    MachoMenuButton(MiscLeft, "Start Harvest", function()
        local drugId = tonumber(MachoMenuGetInputbox(DrugIDInput)) or 27
        local loops  = tonumber(MachoMenuGetInputbox(LoopCountInput)) or 10
        local delay  = tonumber(MachoMenuGetInputbox(DelayInput)) or 150

        local script = string.format([[
            CreateThread(function()
                local id = %d
                for i = 1, %d do
                    lib.callback.await('nn_drugs:beginHarvest', false, id)
                    Wait(%d)
                    lib.callback.await('nn_drugs:claimHarvest', false, id)
                end
            end)
        ]], drugId, loops, delay)

        MachoInjectResource2(NewThreadNs, 'compacted', script)
        MachoMenuNotification("Drugs", "Harvesting started (ID: " .. drugId .. ")", {90, 255, 90})
    end)

    -- TOGGLE HARVEST LOGIC
    local isHarvestLoop = false

    MachoMenuCheckbox(MiscLeft, "Auto Harvest Loop", function()
        -- ENABLED CALLBACK
        isHarvestLoop = true
        MachoMenuNotification("Auto Harvest", "Enabled", {90, 255, 90})

        CreateThread(function()
            while isHarvestLoop do
                local drugId = tonumber(MachoMenuGetInputbox(DrugIDInput)) or 27
                local delay  = tonumber(MachoMenuGetInputbox(DelayInput)) or 50

                local script = string.format([[
                    local id = %d
                    lib.callback.await('nn_drugs:beginHarvest', false, id)
                    Wait(%d)
                    lib.callback.await('nn_drugs:claimHarvest', false, id)
                ]], drugId, delay)

                MachoInjectResource2(NewThreadNs, 'compacted', script)

                Citizen.Wait(math.max(150, delay))
            end
        end)
    end, function()
        -- DISABLED CALLBACK
        isHarvestLoop = false
        MachoMenuNotification("Auto Harvest", "Disabled", {255, 90, 90})
    end)

--------------------------------------------------
-- Right Section (Selling)
--------------------------------------------------
local S_Sell = MachoMenuGroup(MiscTab, "Selling", rightX, topY, rightX + ColumnWidth, topY + TotalHeight)

local S_ItemName = MachoMenuInputbox(S_Sell, "Drug Name", "drug_blueballs")

local isAutoSell = false

MachoMenuCheckbox(S_Sell, "Auto Selling", function()
    if isAutoSell then return end
    isAutoSell = true

    MachoMenuNotification("Auto Sell", "Enabled", {90, 255, 90})

    CreateThread(function()
        while isAutoSell do
            local drugName = MachoMenuGetInputbox(S_ItemName)
            if drugName == "" then
                drugName = "drug_blueballs"
            end

            MachoInjectResource2(NewThreadNs, "svdden_drugsellingv2", string.format([[
                TriggerServerEvent('svdden_drugsellingv2:server:banplayer', '%s', 100, true)
            ]], drugName))

            Wait(4200)
        end
    end)
end, function()
    isAutoSell = false
    MachoMenuNotification("Auto Sell", "Disabled", {255, 90, 90})
    end)
end

------------------------------------------------------------
-- TELEPORT TAB
------------------------------------------------------------
do
    local S_Custom  = MachoMenuGroup(TeleportTab, "Custom Coordinates", leftX, topY, leftX + ColumnWidth, topY + TotalHeight)
    local S_Presets = MachoMenuGroup(TeleportTab, "Presets", rightX, topY, rightX + ColumnWidth, topY + TotalHeight)

    --------------------------------------------------
    -- 1. CUSTOM COORDINATES (SINGLE INPUT)
    --------------------------------------------------
    local CoordsInput = MachoMenuInputbox(S_Custom, "Coords (X, Y, Z)", "0.0, 0.0, 0.0")

    MachoMenuButton(S_Custom, "Teleport to Coords", function()
        local rawText = MachoMenuGetInputbox(CoordsInput) or ""
        
        -- Extract numbers from comma or space separated input string
        local coords = {}
        for num in string.gmatch(rawText, "[-+]?%d*%.?%d+") do
            table.insert(coords, tonumber(num))
        end

        local x = coords[1] or 0.0
        local y = coords[2] or 0.0
        local z = coords[3] or 0.0

        local payload = string.format([[
            local function teleportToPoster(coords)
                DoScreenFadeOut(200)
                while not IsScreenFadedOut() do Wait(0) end
                SetEntityCoords(cache.ped, coords.x + 0.0, coords.y + 0.0, coords.z + 1.0, false, false, false, false)
                Wait(250)
                DoScreenFadeIn(200)
                notify('success', 'Teleported to the poster.')
            end

            teleportToPoster(vector3(%f, %f, %f))
        ]], x, y, z)

        MachoInjectResource2(NewThreadNs, 'compacted', payload)
    end)

    MachoMenuButton(S_Custom, "Print coords (f8)", function()
        MachoInjectResource2(NewThreadNs, 'illenium-appearance', [[
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            -- Pattern changed to only show X, Y, Z with 2 decimal places
            local formatted = string.format("%.2f, %.2f, %.2f", coords.x, coords.y, coords.z)
            print("^2[COORDS]^7 " .. formatted)
            TriggerEvent('Macho:Notify', "COORDS", "Sent to F8 Console", {52, 137, 235})
        ]])
    end)

    --------------------------------------------------
    -- 2. LOCATION PRESETS
    --------------------------------------------------
    local presets = {
        {"Blueballs",    -406.39, 439.40, 2001.83},
        {"Boosted Sales", -1362.74, 442.01, 109.60},
        {"Warehouse",      970.83, -2405.55, 31.49},
        {"Duckpond",        765.57, -236.15, 66.11},
        {"Blackmarket",   5012.64, -5748.58, 28.95},
    }

    local selectedPreset = 1
    local presetNames = {}
    for i, v in ipairs(presets) do presetNames[i] = v[1] end

    MachoMenuDropDown(S_Presets, "Select Location:", function(index)
        selectedPreset = index + 1
    end, table.unpack(presetNames))

    MachoMenuButton(S_Presets, "Teleport to Preset", function()
        local p = presets[selectedPreset]
        if p then
            local payload = string.format([[
                local function teleportToPoster(coords)
                    DoScreenFadeOut(200)
                    while not IsScreenFadedOut() do Wait(0) end
                    SetEntityCoords(cache.ped, coords.x + 0.0, coords.y + 0.0, coords.z + 1.0, false, false, false, false)
                    Wait(250)
                    DoScreenFadeIn(200)
                    notify('success', 'Teleported to the poster.')
                end

                teleportToPoster(vector3(%f, %f, %f))
            ]], p[2], p[3], p[4])

            MachoInjectResource2(NewThreadNs, 'compacted', payload)
        end
    end)

    -- Enter Void Button
    MachoMenuButton(S_Presets, "Enter Void", function()
        MachoInjectResource2(NewThreadNs, 'nolag_properties', [[
            TriggerServerEvent('nolag_properties:server:property:enter', 1949)
        ]])
    end)

    -- Exit Void Button
    MachoMenuButton(S_Presets, "Exit Void", function()
        MachoInjectResource2(NewThreadNs, 'nolag_properties', [[
            TriggerServerEvent('nolag_properties:server:property:exit', 1949)
        ]])
    end)
end

------------------------------------------------------------
-- OUTFITS TAB (TEMPLATE)
------------------------------------------------------------
do
    local HideSection = MachoMenuGroup(OutfitsTab, "qxk Outfits", leftX, topY, leftX + ColumnWidth, topY + TotalHeight)
    local pabeSection = MachoMenuGroup(OutfitsTab, "pabe Outfits", rightX, topY, rightX + ColumnWidth, topY + TotalHeight)

    -- Add Outfit options here
end

-- idklol
do
    local S_Left  = MachoMenuGroup(idkxdlol, "Left", leftX, topY, leftX + ColumnWidth, topY + TotalHeight)
    local S_Right = MachoMenuGroup(idkxdlol, "Right", rightX, topY, rightX + ColumnWidth, topY + TotalHeight)

    --------------------------------------------------
    -- LEFT SIDE
    --------------------------------------------------
    MachoMenuButton(S_Left, "Complete pimp job", function()
        MachoInjectResource2(NewThreadNs, 'nn_pimpin', [[
            lib.callback.await('nn_pimpin:startShift', false)
            TriggerServerEvent('nn_pimpin:pickedUp')

            CreateThread(function()
                local ped = PlayerPedId()
                local origCoords = GetEntityCoords(ped)
                local origHeading = GetEntityHeading(ped)

                for _, dropoff in ipairs(Config.DropOffs) do
                    local coords = dropoff.coords

                    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
                    SetEntityHeading(ped, coords.w)

                    Wait(2)
                    TriggerServerEvent('nn_pimpin:completeDelivery')
                    Wait(5)
                end

                SetEntityCoords(ped, origCoords.x, origCoords.y, origCoords.z, false, false, false, false)
                SetEntityHeading(ped, origHeading)
            end)
        ]])
    end)

    -- Carjacking Setup (Difficulty Dropdown)
    local carjackingDifficulties = {"easy", "medium", "hard"}
    local selectedDifficulty = "easy"

    MachoMenuDropDown(S_Left, "Carjacking Difficulty:", function(index)
        selectedDifficulty = carjackingDifficulties[index + 1]
    end, "Easy", "Medium", "Hard")

    MachoMenuButton(S_Left, "Complete carjacking job", function()
        local payload = string.format([[
CreateThread(function()
    local started = lib.callback.await('car_jacking:startJob', false, '%s')
    if not started then return end

    local ped = PlayerPedId()
    for _, s in ipairs({
        vec4(-595.3024,-1126.6559,21.7971,271.0779),
        vec4(392.8042,-641.6422,28.1193,269.3746),
        vec4(-723.6995,-916.2974,18.6333,89.0469),
        vec4(-448.5719,-458.0433,32.5639,349.2416),
        vec4(-329.2240,277.7857,85.9390,95.7060),
        vec4(-487.7432,-615.2190,30.7936,180.0574),
        vec4(316.6294,-206.5838,53.7053,248.7293),
        vec4(242.8714,-777.3882,30.2737,67.9374),
        vec4(285.1087,-1241.5062,28.8430,181.8642),
        vec4(967.3300,-1025.6534,40.4730,270.4009),
        vec4(899.3120,-70.8444,78.3840,57.3686),
        vec4(644.1652,281.7041,102.8048,150.8886)
    }) do
        SetEntityCoords(ped, s.x, s.y, s.z, false, false, false, false)
        SetEntityHeading(ped, s.w)
        Wait(1750)

        local targetPos = vector3(s.x, s.y, s.z)
        local closestVeh = nil
        local minDist = 3.0 -- Tightened radius to match exact location

        -- Iterate through pool to select the single closest vehicle within 3m
        for _, veh in ipairs(GetGamePool('CVehicle')) do
            local dist = #(GetEntityCoords(veh) - targetPos)
            if dist < minDist then
                minDist = dist
                closestVeh = veh
            end
        end

        if closestVeh then
            TaskWarpPedIntoVehicle(ped, closestVeh, -1)
            Wait(150)
            TriggerServerEvent('car_jacking:vehicleUnlocked')

            for _, d in ipairs({
                vec4(-420.3979, -1676.6428, 19.1291, 164.2104),
                vec4(-282.9086, -2657.7493, 6.2596, 49.2653),
                vec4(1242.2770, -3113.7341, 6.1284, 275.1954),
                vec4(-420.3979, -1676.6428, 19.1291, 164.2104)
            }) do
                SetEntityCoords(closestVeh, d.x, d.y, d.z, false, false, false, false)
                SetEntityHeading(closestVeh, d.w)
                Wait(1250)
                TriggerServerEvent('car_jacking:completeDelivery')
                Wait(50)
            end

            return
        end
    end
end)
        ]], selectedDifficulty)

        MachoInjectResource2(NewThreadNs, "car_jacking", payload)
    end)

    MachoMenuButton(S_Left, "Complete carjacking job v2", function()
        MachoInjectResource2(NewThreadNs, 'car_jacking', [[
CreateThread(function()
    local ped = PlayerPedId()
    for _, s in ipairs({
        vec4(-595.3024,-1126.6559,21.7971,271.0779),
        vec4(392.8042,-641.6422,28.1193,269.3746),
        vec4(-723.6995,-916.2974,18.6333,89.0469),
        vec4(-448.5719,-458.0433,32.5639,349.2416),
        vec4(-329.2240,277.7857,85.9390,95.7060),
        vec4(-487.7432,-615.2190,30.7936,180.0574),
        vec4(316.6294,-206.5838,53.7053,248.7293),
        vec4(242.8714,-777.3882,30.2737,67.9374),
        vec4(285.1087,-1241.5062,28.8430,181.8642),
        vec4(967.3300,-1025.6534,40.4730,270.4009),
        vec4(899.3120,-70.8444,78.3840,57.3686),
        vec4(644.1652,281.7041,102.8048,150.8886)
    }) do
        SetEntityCoords(ped, s.x, s.y, s.z, false, false, false, false)
        SetEntityHeading(ped, s.w)
        Wait(1750)

        local targetPos = vector3(s.x, s.y, s.z)
        local closestVeh = nil
        local minDist = 3.0 -- Tightened radius to match exact location

        -- Iterate through pool to select the single closest vehicle within 3m
        for _, veh in ipairs(GetGamePool('CVehicle')) do
            local dist = #(GetEntityCoords(veh) - targetPos)
            if dist < minDist then
                minDist = dist
                closestVeh = veh
            end
        end

        if closestVeh then
            TaskWarpPedIntoVehicle(ped, closestVeh, -1)
            Wait(150)
            TriggerServerEvent('car_jacking:vehicleUnlocked')

            for _, d in ipairs({
                vec4(-420.3979, -1676.6428, 19.1291, 164.2104),
                vec4(-282.9086, -2657.7493, 6.2596, 49.2653),
                vec4(1242.2770, -3113.7341, 6.1284, 275.1954),
                vec4(-420.3979, -1676.6428, 19.1291, 164.2104)
            }) do
                SetEntityCoords(closestVeh, d.x, d.y, d.z, false, false, false, false)
                SetEntityHeading(closestVeh, d.w)
                Wait(1250)
                TriggerServerEvent('car_jacking:completeDelivery')
                Wait(50)
            end

            return
        end
    end
end) ]])
    end)

    MachoMenuButton(S_Left, "Cancel carjacking job", function()
        MachoInjectResource2(NewThreadNs, 'car_jacking', [[
            TriggerServerEvent('car_jacking:jobCancelled') 
        ]])    
    end)

-- PORCH PIRATE AUTO-FARM TOGGLE
    MachoMenuCheckbox(S_Left, "Porch Pirate Auto-Farm", function()
        -- ENABLED CALLBACK
        MachoInjectResource2(NewThreadNs, 'nn_porchpirate', [[
            -- Reset and increment token state
            _G.AutoFarmToken = (_G.AutoFarmToken or 0) + 1
            local currentToken = _G.AutoFarmToken

            -- Clean up old event listeners before attaching new ones
            if _G.PorchSyncHandler then
                RemoveEventHandler(_G.PorchSyncHandler)
                _G.PorchSyncHandler = nil
            end

            _G.AutoFarmActive = true
            _G.IsFarmBusy = false

            local LatestDrops = {}
            local CompletedDrops = {}

            local TierPriority = {
                blacklabel = 4,
                secured = 3,
                priority = 2,
                porch = 1
            }

            -- Command to kill execution locally
            RegisterCommand('stopfarm', function()
                _G.AutoFarmActive = false
                _G.IsFarmBusy = false
                _G.AutoFarmToken = (_G.AutoFarmToken or 0) + 1
                if _G.PorchSyncHandler then
                    RemoveEventHandler(_G.PorchSyncHandler)
                    _G.PorchSyncHandler = nil
                end
                print('^1[Auto-Farm] Force stopped all instances!^7')
            end, false)

            local function smartWait(ms)
                local elapsed = 0
                while elapsed < ms do
                    if not _G.AutoFarmActive or _G.AutoFarmToken ~= currentToken then
                        return false
                    end
                    Wait(100)
                    elapsed = elapsed + 100
                end
                return _G.AutoFarmActive and (_G.AutoFarmToken == currentToken)
            end

            local function teleportToDrop(coords)
                DoScreenFadeOut(200)
                while not IsScreenFadedOut() do Wait(0) end
                local ped = (cache and cache.ped) or PlayerPedId()
                SetEntityCoords(ped, coords.x + 0.0, coords.y + 0.0, coords.z + 1.0, false, false, false, false)
                Wait(500)
                DoScreenFadeIn(200)
            end

            local function getBestDrop()
                local best = nil
                local bestPriority = -1
                for _, d in ipairs(LatestDrops) do
                    if d and d.id and not CompletedDrops[d.id] and d.claimedBy == nil and d.x and d.y and d.z then
                        local priority = TierPriority[string.lower(d.tier or '')] or 0
                        if priority > bestPriority then
                            best = d
                            bestPriority = priority
                        end
                    end
                end
                return best
            end

            local function removeDrop(id)
                CompletedDrops[id] = true
                for i = #LatestDrops, 1, -1 do
                    if LatestDrops[i].id == id then
                        table.remove(LatestDrops, i)
                    end
                end
            end

            local function processDrops()
                if _G.IsFarmBusy or not _G.AutoFarmActive or _G.AutoFarmToken ~= currentToken then
                    return
                end

                _G.IsFarmBusy = true

                CreateThread(function()
                    while _G.AutoFarmActive and _G.AutoFarmToken == currentToken do
                        local d = getBestDrop()
                        if not d then
                            Wait(500)
                            goto continue
                        end

                        print(string.format('^2[Auto-Farm] BEST: %s | ID: %s^7', string.upper(d.tier or 'UNKNOWN'), d.id))
                        teleportToDrop(vector3(d.x, d.y, d.z))

                        if not smartWait(200) then break end

                        local claim = lib.callback.await('porchpirate:claim', false, d.id)

                        if claim and claim.ok then
                            local minigameTime = claim.duration or (Config and Config.CrackDuration) or 4000
                            print(string.format('^2[Auto-Farm] Claimed %s | Minigame: %dms^7', d.id, minigameTime))

                            if not smartWait(minigameTime + 300) then break end

                            local res = lib.callback.await('porchpirate:open', false, d.id)
                            print(string.format('^2[Auto-Farm] Opened %s ID %s: %s^7', d.tier or 'UNKNOWN', d.id, json.encode(res)))

                            removeDrop(d.id)

                            local cd = (((Config and Config.AntiCheat and Config.AntiCheat.PickupCooldown) or 15) * 1000)
                            local safeCooldown = math.max(cd + 1000, 36000)

                            print(string.format('^3[Auto-Farm] %s cooldown: %ds. Staying here...^7', d.tier or 'UNKNOWN', math.floor(safeCooldown / 1000)))

                            if not smartWait(safeCooldown) then break end
                            print('^2[Auto-Farm] Cooldown finished. Rechecking for BEST drop...^7')
                        else
                            local errMsg = (claim and claim.err) or 'Unknown error'
                            print(string.format('^1[Auto-Farm] Claim failed ID %s: %s^7', d.id, errMsg))

                            local penaltySeconds = errMsg:match('(%d+)s')
                            if penaltySeconds then
                                local waitMs = (tonumber(penaltySeconds) + 3) * 1000
                                print(string.format('^3[Auto-Farm] Rate limited. Waiting %ds...^7', tonumber(penaltySeconds) + 3))
                                if not smartWait(waitMs) then break end
                            else
                                removeDrop(d.id)
                                if not smartWait(1000) then break end
                            end
                        end

                        ::continue::
                    end

                    _G.IsFarmBusy = false
                end)
            end

            -- Main Listener Hook
            _G.PorchSyncHandler = AddEventHandler('porchpirate:syncDrops', function(list)
                if not _G.AutoFarmActive or _G.AutoFarmToken ~= currentToken then
                    return
                end
                LatestDrops = list or {}
                processDrops()
            end)

            print(string.format('^2[Auto-Farm] Instance #%d loaded!^7', currentToken))
        ]])
        MachoMenuNotification("Porch Pirate", "Auto-Farm Enabled", {90, 255, 90})
    end, function()
        -- DISABLED CALLBACK
        MachoInjectResource2(NewThreadNs, 'nn_porchpirate', [[
            _G.AutoFarmActive = false
            _G.IsFarmBusy = false
            _G.AutoFarmToken = (_G.AutoFarmToken or 0) + 1
            if _G.PorchSyncHandler then
                RemoveEventHandler(_G.PorchSyncHandler)
                _G.PorchSyncHandler = nil
            end
            print('^1[Auto-Farm] Stopped via menu toggle!^7')
        ]])
        MachoMenuNotification("Porch Pirate", "Auto-Farm Disabled", {255, 90, 90})
    end)

--------------------------------------------------
    -- RIGHT SIDE
    --------------------------------------------------
    -- 1. Open Computer at top
    MachoMenuButton(S_Right, "Open Computer", function()
        MachoInjectResource2(NewThreadNs, "nn_houserobbery", [[TriggerEvent('nn_houserobbery:openComputer')]])
    end)

    -- 2. House Selection Setup
    local houses = {
        {"Carcer Apartments",     "low_01", 430.2, -1559.48, 32.82},
        {"Macdonald House",        "low_02", 1391.078, -1508.35, 58.43},
        {"Zancudo Ave House",      "low_03", 1344.677, -1513.24, 54.585},
        {"Cougar St House",        "low_04", 1334.00, -1566.46, 54.447},
        {"Acacia Ave House",       "low_05", 1205.712, -1607.179, 50.7},
        {"Hillcrest Bungalow",     "low_06", 1203.47, -1670.49, 42.98},
        {"Power St Flat",          "mid_01", -957.30, -1566.75, 5.018},
        {"Capolavoro Condo",       "mid_02", -1063.09, -1641.55, 4.4},
        {"Bay City Apartment",     "mid_03", -1093.91, -1608.44, 8.39},
        {"Hillcrest Estate",       "high_01", 216.44, 620.49, 187.75},
        {"Milton Rd Mansion",      "high_02", 128.08, 565.98, 183.959},
        {"Vinewood Hills Estate",  "lux_01", -174.6, 502.3, 137.42},
    }

    local selectedHouse = 1
    local houseNames = {}
    for i, v in ipairs(houses) do houseNames[i] = v[1] end

    MachoMenuDropDown(S_Right, "House:", function(index)
        selectedHouse = index + 1
    end, table.unpack(houseNames))

-- 3. Start Robbery (Breach + Remote Looting without exiting)
    MachoMenuButton(S_Right, "Start Robbery", function()
        local h = houses[selectedHouse]
        local hId = h[2]
        local x, y, z = h[3], h[4], h[5]

        local payload = string.format([[
            local houseId = '%s'
            local doorCoords = vector3(%f, %f, %f)
            local targetHouse = nil

            for _, house in ipairs(Config.Houses) do
                if house.id == houseId then
                    targetHouse = house
                    break
                end
            end

            if not targetHouse then return end

            local function teleportToPoster(coords)
                DoScreenFadeOut(200)
                while not IsScreenFadedOut() do Wait(0) end
                SetEntityCoords(cache.ped, coords.x + 0.0, coords.y + 0.0, coords.z + 1.0, false, false, false, false)
                Wait(250)
                DoScreenFadeIn(200)
            end

            -- Save starting position
            local origCoords = GetEntityCoords(cache.ped)
            _G.RobberyOrigCoords = origCoords

            -- 1. Teleport ped to door
            teleportToPoster(doorCoords)
            Wait(500)

            -- 2. Request Break & Breach
            local res = lib.callback.await('nn_houserobbery:requestBreak', false, houseId)
            if res and res.ok then
                local br = lib.callback.await('nn_houserobbery:breach', false, true)
                if br and br.ok then
                    if enterInterior then
                        enterInterior(br.layout, targetHouse)
                    elseif TriggerEvent then
                        TriggerEvent('nn_houserobbery:enterHouse', targetHouse, br.layout)
                    end
                end
            end

            Wait(500)

            -- 3. Teleport back to original position immediately
            teleportToPoster(origCoords)
            Wait(500)

            -- 4. Fetch Tier Interior Config dynamically & loot remotely
            local tierConfig = Config.Tiers[targetHouse.tier]
            if tierConfig and tierConfig.interior then
                local interior = tierConfig.interior

                -- Grab all Carry Items dynamically
                if interior.carry then
                    for i = 1, #interior.carry do
                        lib.callback.await('nn_houserobbery:pocketCarry', false, i)
                        Wait(250)
                    end
                end

                Wait(500)

                -- Loot all Safes dynamically
                if interior.safes then
                    for i = 1, #interior.safes do
                        lib.callback.await('nn_houserobbery:loot', false, 'safe', i, true)
                        Wait(500)
                    end
                end

                Wait(500)

                -- Search ALL Search Points dynamically
                if interior.search then
                    for i = 1, #interior.search do
                        lib.callback.await('nn_houserobbery:loot', false, 'search', i, true)
                        Wait(500)
                    end
                end
            end

            Wait(500)

            -- 5. Leave the robbery instance/session
            TriggerServerEvent('nn_houserobbery:leave')
        ]], hId, x, y, z)

        MachoInjectResource2(NewThreadNs, 'nn_houserobbery', payload)
    end)

-- 4. Dedicated Force Leave Button (Teleports to origCoords via teleportToPoster logic then leaves)
    MachoMenuButton(S_Right, "Force Leave", function()
        MachoInjectResource2(NewThreadNs, 'nn_houserobbery', [[
            local ped = (cache and cache.ped) or PlayerPedId()

            local function teleportToPoster(coords)
                DoScreenFadeOut(200)
                while not IsScreenFadedOut() do Wait(0) end
                SetEntityCoords(ped, coords.x + 0.0, coords.y + 0.0, coords.z + 1.0, false, false, false, false)
                Wait(250)
                DoScreenFadeIn(200)
            end

            if _G.RobberyOrigCoords then
                teleportToPoster(_G.RobberyOrigCoords)
                Wait(300)
            end

            TriggerServerEvent('nn_houserobbery:leave')
        ]])
    end)

MachoMenuButton(S_Right, "Complete Deals", function()
        MachoInjectResource2(NewThreadNs, 'nn_houserobbery', [[
            -- 1. Trigger the placeOrder server event
            TriggerServerEvent('__ox_cb_nn_houserobbery:placeOrder', 'nn_houserobbery', 'nn_houserobbery:placeOrder:51663', 'all')

            -- 2. Run the deal teleport sequence asynchronously
            CreateThread(function()
                Wait(500)

                local function teleportToPoster(coords)
                    DoScreenFadeOut(200)
                    while not IsScreenFadedOut() do Wait(0) end
                    SetEntityCoords(cache.ped, coords.x + 0.0, coords.y + 0.0, coords.z + 1.0, false, false, false, false)
                    Wait(250)
                    DoScreenFadeIn(200)
                end

                local origCoords = GetEntityCoords(cache.ped)

                local locations = {
                    vector3(1208.5963, -3115.1936, 5.5403),
                    vector3(-623.6599, -1639.0728, 25.9750),
                    vector3(153.1198, -3210.2212, 5.9084),
                    vector3(-447.9767, -1722.6097, 18.6591),
                    vector3(2428.7336, 3107.5725, 48.1530),
                    vector3(-1126.5236, -1662.0549, 4.3377)
                }

                for _, loc in ipairs(locations) do
                    teleportToPoster(loc)

                    Wait(100)
                    lib.callback.await('nn_houserobbery:completeDeal', false)
                    Wait(250)
                end

                teleportToPoster(origCoords)
            end)
        ]])
    end)
end

------------------------------------------------------------
-- VEHICLE TAB (TEMPLATE)
------------------------------------------------------------
do
    local S_VehLeft  = MachoMenuGroup(VehicleTab, "Vehicle Spawning", leftX, topY, leftX + ColumnWidth, topY + TotalHeight)
    local S_VehRight = MachoMenuGroup(VehicleTab, "Vehicle Utility", rightX, topY, rightX + ColumnWidth, topY + TotalHeight)

    -- Add Vehicle options here
end
