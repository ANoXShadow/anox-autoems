local Bridge = require('bridge.loader'):Load()
if not Bridge then return end
local activeEMS = {}
local lastCallTime = 0
local currentEMS = nil

local function isInBlacklistedLocation()
    local playerCoords = GetEntityCoords(cache.ped)
    for _, location in ipairs(Config.BlacklistedLocations) do
        local distance = #(playerCoords - location.coords)
        if distance <= location.radius then
            return true, location.name
        end
    end
    return false, nil
end

local function getSafeGroundPosition(coords)
    local groundZ = coords.z
    local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 100.0, false)
    if found then
        groundZ = z
    end
    local rayHandle = StartShapeTestRay(
        coords.x, coords.y, coords.z + 100.0,
        coords.x, coords.y, groundZ - 1.0,
        1, cache.ped, 4
    )
    local _, hit, _, _, _ = GetShapeTestResult(rayHandle)
    if hit then
        return vector3(coords.x, coords.y, groundZ)
    end
    return vector3(coords.x, coords.y, coords.z)
end

local function createEMSNpc(coords)
    local model = Config.EMSModels[math.random(#Config.EMSModels)]
    lib.requestModel(model)
    local npc = CreatePed(4, model, coords.x, coords.y, coords.z, 0.0, true, false)
    SetEntityAsMissionEntity(npc, true, true)
    SetPedFleeAttributes(npc, 0, false)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedCombatAttributes(npc, 46, true)
    SetPedRelationshipGroupHash(npc, GetHashKey("CIVFEMALE"))
    GiveWeaponToPed(npc, GetHashKey("WEAPON_UNARMED"), 0, false, true)
    return npc
end

local function getNPCSpawnLocation(playerCoords)
    local minDistance = 30.0
    local maxDistance = 50.0
    local attempts = 0
    local maxAttempts = 10
    while attempts < maxAttempts do
        local angle = math.random() * math.pi * 2
        local distance = math.random() * (maxDistance - minDistance) + minDistance
        local x = playerCoords.x + math.cos(angle) * distance
        local y = playerCoords.y + math.sin(angle) * distance
        local z = playerCoords.z
        local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 100.0, false)
        if found then
            z = groundZ
        end
        local testCoords = vector3(x, y, z)
        if not IsPositionOccupied(x, y, z, 2.0, false, true, true, false, false, 0, false) then
            return testCoords
        end
        attempts = attempts + 1
    end
    local angle = math.random() * math.pi * 2
    local distance = 40.0
    return vector3(
        playerCoords.x + math.cos(angle) * distance,
        playerCoords.y + math.sin(angle) * distance,
        playerCoords.z
    )
end

local function performRevive(npc, targetPed)
    lib.requestAnimDict(Config.ReviveAnimDict)
    local playerCoords = GetEntityCoords(targetPed)
    local playerHeading = GetEntityHeading(targetPed)
    SetEntityCoords(npc, playerCoords.x, playerCoords.y, playerCoords.z)
    SetEntityHeading(npc, playerHeading - 180.0)
    ClearPedTasks(npc)
    Wait(100)
    TaskPlayAnim(
        npc,
        Config.ReviveAnimDict,
        Config.ReviveAnimName,
        8.0, -8.0, -1, 1, 0, false, false, false
    )
    
    -- Store original camera settings
    local wasFirstPerson = GetFollowPedCamViewMode() == 4
    local originalCamMode = GetFollowPedCamViewMode()
    
    -- Force camera to third person and lock it
    SetFollowPedCamViewMode(1)
    
    local cameraControlsDisabled = true
    CreateThread(function()
        while cameraControlsDisabled do
            -- Disable all camera movement controls
            DisableControlAction(0, 1, true)   -- Camera X
            DisableControlAction(0, 2, true)   -- Camera Y
            DisableControlAction(0, 3, true)   -- Camera Zoom In
            DisableControlAction(0, 4, true)   -- Camera Zoom Out
            DisableControlAction(0, 5, true)   -- Camera Zoom In Secondary
            DisableControlAction(0, 14, true)  -- Camera Right
            DisableControlAction(0, 15, true)  -- Camera Left
            DisableControlAction(0, 16, true)  -- Camera Up
            DisableControlAction(0, 17, true)  -- Camera Down
            DisableControlAction(0, 37, true)  -- Camera Mode (V key)
            DisableControlAction(0, 44, true)  -- Camera Cover
            DisableControlAction(0, 0, true)   -- Camera Look Around
            DisableControlAction(0, 26, true)  -- Camera Look Behind
            
            -- Keep camera locked in position
            SetFollowPedCamViewMode(1)
            Wait(0)
        end
    end)
    
    local success = lib.progressBar({
        duration = Config.ReviveTime,
        label = _L('being_revived'),
        useWhileDead = true,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true,
            mouse = true
        },
    })
    
    cameraControlsDisabled = false
    
    -- Restore original camera mode if it was first person
    if wasFirstPerson then
        Wait(500)
        SetFollowPedCamViewMode(4)
    else
        SetFollowPedCamViewMode(originalCamMode)
    end
    
    ClearPedTasks(npc)
    return success
end

local function cleanupEMS(emsData)
    if not emsData then return end
    if DoesEntityExist(emsData.npc) then
        DeleteEntity(emsData.npc)
    end
    if DoesBlipExist(emsData.blip) then
        RemoveBlip(emsData.blip)
    end
    currentEMS = nil
end

local function teleportNPCToPlayer(npc, playerPed)
    local playerCoords = GetEntityCoords(playerPed)
    local offsetX = math.random(-3, 3)
    local offsetY = math.random(-3, 3)
    local teleportCoords = vector3(playerCoords.x + offsetX, playerCoords.y + offsetY, playerCoords.z)
    local safeCoords = getSafeGroundPosition(teleportCoords)
    NetworkFadeOutEntity(npc, false, false)
    Wait(500)
    SetEntityCoords(npc, safeCoords.x, safeCoords.y, safeCoords.z, false, false, false, false)
    SetEntityHeading(npc, GetEntityHeading(playerPed) + 180.0)
    NetworkFadeInEntity(npc, false)
    ClearPedTasks(npc)
    TaskTurnPedToFaceEntity(npc, playerPed, 1000)
    Bridge.Debug("NPC teleported to player location after failed attempts", 'info')
    Bridge.Notify(nil, _L('auto_ems'), _L('ems_teleported'), 'info')
end

local function dispatchEMS()
    Bridge.Debug("Dispatching EMS to player location", 'info')
    local playerCoords = GetEntityCoords(cache.ped)
    local safeCoords = getSafeGroundPosition(playerCoords)
    local spawnCoords = getNPCSpawnLocation(safeCoords)
    local npc = createEMSNpc(spawnCoords)
    local blip = AddBlipForEntity(npc)
    SetBlipSprite(blip, Config.EMSBlip.sprite)
    SetBlipColour(blip, Config.EMSBlip.color)
    SetBlipScale(blip, Config.EMSBlip.scale)
    SetBlipAsShortRange(blip, Config.EMSBlip.shortRange)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.EMSBlip.name)
    EndTextCommandSetBlipName(blip)
    currentEMS = {
        npc = npc,
        blip = blip,
        targetPlayer = cache.playerId
    }
    SetPedMoveRateOverride(npc, 10.0)
    TaskGoToEntity(npc, cache.ped, -1, 2.0, 4.0, 1073741824, 0)
    CreateThread(function()
        local arrived = false
        local timeout = GetGameTimer() + 120000
        local failedAttempts = 0
        local maxFailedAttempts = 3
        local lastPlayerCoords = playerCoords
        local stuckCheckTimer = GetGameTimer()
        local lastNpcCoords = GetEntityCoords(npc)
        while currentEMS and not arrived and GetGameTimer() < timeout do
            playerCoords = GetEntityCoords(cache.ped)
            local npcCoords = GetEntityCoords(npc)
            local distance = #(npcCoords - playerCoords)
            if GetGameTimer() - stuckCheckTimer > 5000 then
                local npcMovement = #(npcCoords - lastNpcCoords)
                if npcMovement < 2.0 and distance > 5.0 then
                    failedAttempts = failedAttempts + 1
                    Bridge.Debug(string.format("NPC appears stuck. Failed attempts: %d/%d", failedAttempts, maxFailedAttempts), 'warning')
                    if failedAttempts >= maxFailedAttempts then
                        teleportNPCToPlayer(npc, cache.ped)
                        arrived = true
                        Wait(1000)
                        if currentEMS then
                            local revived = performRevive(npc, cache.ped)
                            if revived then
                                TriggerServerEvent('anox-autoems:server:revivePlayer')
                                Bridge.Notify(nil, _L('auto_ems'), _L('revived'), 'success')
                                Wait(2000)
                                local angle = math.random() * math.pi * 2
                                local walkDistance = 30.0
                                local walkToCoords = vector3(
                                    npcCoords.x + math.cos(angle) * walkDistance,
                                    npcCoords.y + math.sin(angle) * walkDistance,
                                    npcCoords.z
                                )
                                TaskGoToCoordAnyMeans(npc, walkToCoords.x, walkToCoords.y, walkToCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
                                SetTimeout(Config.NPCDespawnTime, function()
                                    cleanupEMS(currentEMS)
                                end)
                            else
                                cleanupEMS(currentEMS)
                            end
                        end
                    else
                        ClearPedTasks(npc)
                        Wait(100)
                        TaskGoToEntity(npc, cache.ped, -1, 2.0, 4.0, 1073741824, 0)
                    end
                end
                lastNpcCoords = npcCoords
                stuckCheckTimer = GetGameTimer()
            end
            if distance < 3.0 and not arrived then
                arrived = true
                ClearPedTasks(npc)
                SetPedMoveRateOverride(npc, 1.0)
                TaskTurnPedToFaceEntity(npc, cache.ped, 1000)
                Wait(1000)
                Bridge.Notify(nil, _L('auto_ems'), _L('ems_arrived'), 'info')
                if currentEMS then
                    local revived = performRevive(npc, cache.ped)
                    if revived then
                        TriggerServerEvent('anox-autoems:server:revivePlayer')
                        Bridge.Notify(nil, _L('auto_ems'), _L('revived'), 'success')
                        Wait(2000)
                        local angle = math.random() * math.pi * 2
                        local walkDistance = 30.0
                        local walkToCoords = vector3(
                            npcCoords.x + math.cos(angle) * walkDistance,
                            npcCoords.y + math.sin(angle) * walkDistance,
                            npcCoords.z
                        )
                        TaskGoToCoordAnyMeans(npc, walkToCoords.x, walkToCoords.y, walkToCoords.z, 1.0, 0, 0, 786603, 0xbf800000)
                        SetTimeout(Config.NPCDespawnTime, function()
                            cleanupEMS(currentEMS)
                        end)
                    else
                        cleanupEMS(currentEMS)
                    end
                end
            else
                if distance > 20.0 or #(playerCoords - lastPlayerCoords) > 10.0 then
                    ClearPedTasks(npc)
                    TaskGoToEntity(npc, cache.ped, -1, 2.0, 4.0, 1073741824, 0)
                    lastPlayerCoords = playerCoords
                end
            end
            Wait(1000)
        end
        if not arrived and currentEMS then
            Bridge.Notify(nil, _L('auto_ems'), _L('ems_timeout'), 'error')
            cleanupEMS(currentEMS)
        end
    end)
end

RegisterCommand('autoems', function()
    local canCall, reason = lib.callback.await('anox-autoems:server:canCallEMS', false)
    if canCall then
        dispatchEMS()
    else
        Bridge.Notify(nil, _L('auto_ems'), reason, 'error')
    end
end, false)

lib.callback.register('anox-autoems:client:isPlayerDead', function()
    return Bridge:IsPlayerDead()
end)

lib.callback.register('anox-autoems:client:getPlayerLocation', function()
    local coords = GetEntityCoords(cache.ped)
    local inBlacklisted, locationName = isInBlacklistedLocation()
    return {
        coords = coords,
        inBlacklisted = inBlacklisted,
        locationName = locationName
    }
end)

RegisterNetEvent('anox-autoems:client:revivePlayer', function()
    Bridge:RevivePlayer()
end)

CreateThread(function()
    while true do
        if currentEMS then
            if not Bridge:IsPlayerDead() then
                Bridge.Debug("Player revived by other means, cleaning up Auto EMS", 'info')
                cleanupEMS(currentEMS)
            end
        end
        Wait(1000)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if currentEMS then
            cleanupEMS(currentEMS)
        end
    end
end)