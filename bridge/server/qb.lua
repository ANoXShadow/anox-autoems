local QBBridge = {}
QBBridge.__index = QBBridge
local QBCore = nil

function QBBridge:Init()
    QBCore = exports['qb-core']:GetCoreObject()
    if not QBCore then
        return false
    end
    return true
end

function QBBridge:GetPlayer(playerId)
    return QBCore.Functions.GetPlayer(playerId)
end

function QBBridge:GetPlayerFromIdentifier(identifier)
    return QBCore.Functions.GetPlayerByCitizenId(identifier)
end

function QBBridge:GetPlayerJob(playerId)
    local Player = self:GetPlayer(playerId)
    if not Player then return nil end
    return Player.PlayerData.job
end

function QBBridge:GetOnlinePlayersWithJob(jobName)
    local players = {}
    local Players = QBCore.Functions.GetQBPlayers()
    for _, Player in pairs(Players) do
        if Player.PlayerData.job and Player.PlayerData.job.name == jobName then
            table.insert(players, Player.PlayerData.source)
        end
    end
    return players
end

function QBBridge:RemoveMoney(playerId, amount, moneyType)
    local Player = self:GetPlayer(playerId)
    if not Player then return false end
    moneyType = moneyType or 'cash'
    Player.Functions.RemoveMoney(moneyType, amount)
    return true
end

function QBBridge:GetMoney(playerId, moneyType)
    local Player = self:GetPlayer(playerId)
    if not Player then return 0 end
    moneyType = moneyType or 'cash'
    return Player.PlayerData.money[moneyType] or 0
end

function QBBridge:HasMoney(playerId, amount, moneyType)
    return self:GetMoney(playerId, moneyType) >= amount
end

function QBBridge:GetFramework()
    return QBCore
end

return QBBridge