local Bridge = require('bridge.loader'):Load()
if not Bridge then return end
local activeEMSCalls = {}
local playerCooldowns = {}

    local function canPlayerCallEMS(source)
    local player = Bridge:GetPlayer(source)
    if not player then
        return false, _L('not_dead')
    end
    local isDead = lib.callback.await('anox-autoems:client:isPlayerDead', source)
    if not isDead then
        return false, _L('not_dead')
    end
    local job = Bridge:GetPlayerJob(source)
    if job then
        for _, blacklistedJob in ipairs(Config.BlacklistedJobs) do
            if job.name == blacklistedJob then
                return false, _L('blacklisted_job')
            end
        end
    end
    local emsCount = 0
    for _, jobName in ipairs({'ambulance', 'ems', 'doctor'}) do
        local onlineEMS = Bridge:GetOnlinePlayersWithJob(jobName)
        emsCount = emsCount + #onlineEMS
    end
    if emsCount >= Config.EMSCount then
        return false, _L('ems_available', emsCount)
    end
    if #activeEMSCalls >= Config.MaxActiveEMS then
        return false, _L('max_active')
    end
    local currentTime = GetGameTimer()
    if playerCooldowns[source] and currentTime < playerCooldowns[source] then
        local timeRemaining = math.ceil((playerCooldowns[source] - currentTime) / 1000)
        return false, _L('on_cooldown', timeRemaining)
    end
    if not Bridge:HasMoney(source, Config.Cost, 'cash') and not Bridge:HasMoney(source, Config.Cost, 'bank') then
        return false, _L('insufficient_funds', Config.Cost)
    end
    local locationData = lib.callback.await('anox-autoems:client:getPlayerLocation', source)
    if locationData.inBlacklisted then
        return false, _L('blacklisted_location')
    end
    return true, nil
end

local function processPayment(source)
    if Bridge:HasMoney(source, Config.Cost, 'cash') then
        Bridge:RemoveMoney(source, Config.Cost, 'cash')
        Bridge.Debug(string.format("Player %s paid $%s cash for Auto EMS", source, Config.Cost), 'info')
        return true
    elseif Bridge:HasMoney(source, Config.Cost, 'bank') then
        Bridge:RemoveMoney(source, Config.Cost, 'bank')
        Bridge.Debug(string.format("Player %s paid $%s bank for Auto EMS", source, Config.Cost), 'info')
        return true
    end
    return false
end

lib.callback.register('anox-autoems:server:canCallEMS', function(source)
    local canCall, reason = canPlayerCallEMS(source)
    if canCall then
        if processPayment(source) then
            activeEMSCalls[source] = {
                playerId = source,
                timestamp = GetGameTimer()
            }
            playerCooldowns[source] = GetGameTimer() + Config.CallCooldown
            Bridge.Notify(source, _L('auto_ems'), _L('ems_called'), 'success')
            Bridge.Debug(string.format("Player %s called Auto EMS successfully", source), 'success')
            return true, nil
        else
            return false, _L('insufficient_funds', Config.Cost)
        end
    end
    return false, reason
end)

RegisterNetEvent('anox-autoems:server:revivePlayer', function()
    local source = source
    if not activeEMSCalls[source] then
        Bridge.Debug(string.format("Player %s tried to revive without calling EMS", source), 'warning')
        return
    end
    TriggerClientEvent('anox-autoems:client:revivePlayer', source)
    activeEMSCalls[source] = nil
    Bridge.Debug(string.format("Player %s was revived by Auto EMS", source), 'success')
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    if activeEMSCalls[source] then
        activeEMSCalls[source] = nil
        Bridge.Debug(string.format("Cleaned up Auto EMS call for disconnected player %s", source), 'info')
    end
    if playerCooldowns[source] then
        playerCooldowns[source] = nil
    end
end)

CreateThread(function()
    while true do
        Wait(60000)
        local currentTime = GetGameTimer()
        for playerId, callData in pairs(activeEMSCalls) do
            if currentTime - callData.timestamp > 300000 then
                activeEMSCalls[playerId] = nil
                Bridge.Debug(string.format("Cleaned up expired Auto EMS call for player %s", playerId), 'info')
            end
        end
        for playerId, cooldownTime in pairs(playerCooldowns) do
            if currentTime > cooldownTime then
                playerCooldowns[playerId] = nil
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
    end
end)