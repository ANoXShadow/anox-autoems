local QBXBridge = {}
QBXBridge.__index = QBXBridge

function QBXBridge:Init()
    if GetResourceState('qbx_core') ~= 'started' then
        return false
    end
    return true
end

function QBXBridge:GetPlayer(playerId)
    return exports.qbx_core:GetPlayer(playerId)
end

function QBXBridge:GetPlayerFromIdentifier(identifier)
    return exports.qbx_core:GetPlayerByCitizenId(identifier)
end

function QBXBridge:GetPlayerJob(playerId)
    local Player = self:GetPlayer(playerId)
    if not Player then return nil end
    return Player.PlayerData.job
end

function QBXBridge:GetOnlinePlayersWithJob(jobName)
    local players = {}
    local allPlayers = exports.qbx_core:GetQBPlayers()
    for _, Player in pairs(allPlayers) do
        if Player.PlayerData.job and Player.PlayerData.job.name == jobName then
            table.insert(players, Player.PlayerData.source)
        end
    end
    return players
end

function QBXBridge:RemoveMoney(playerId, amount, moneyType)
    local Player = self:GetPlayer(playerId)
    if not Player then return false end
    moneyType = moneyType or 'cash'
    return Player.Functions.RemoveMoney(moneyType, amount)
end

function QBXBridge:GetMoney(playerId, moneyType)
    local Player = self:GetPlayer(playerId)
    if not Player then return 0 end
    moneyType = moneyType or 'cash'
    return Player.PlayerData.money[moneyType] or 0
end

function QBXBridge:HasMoney(playerId, amount, moneyType)
    return self:GetMoney(playerId, moneyType) >= amount
end

function QBXBridge:GetFramework()
    return 'qbx'
end

return QBXBridge