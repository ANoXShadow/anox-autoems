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

function QBBridge:GetPlayerData()
    return QBCore.Functions.GetPlayerData()
end

function QBBridge:IsPlayerDead()
    local playerPed = PlayerPedId()
    if IsEntityDead(playerPed) then
        return true
    end
    local playerData = self:GetPlayerData()
    if playerData.metadata and (playerData.metadata['isdead'] or playerData.metadata['inlaststand']) then
        return true
    end
    if PlayerJob and PlayerJob.name == 'ambulance' then
        return false
    end
    if isDead ~= nil then
        return isDead
    end
    if InLaststand ~= nil then
        return InLaststand
    end
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.isDead then
        return true
    end
    return false
end

function QBBridge:GetJob()
    local playerData = self:GetPlayerData()
    return playerData.job
end

function QBBridge:HasJob(jobName)
    local job = self:GetJob()
    return job and job.name == jobName
end

function QBBridge:GetMoney(moneyType)
    local playerData = self:GetPlayerData()
    moneyType = moneyType or 'cash'
    return playerData.money and playerData.money[moneyType] or 0
end

function QBBridge:HasMoney(amount, moneyType)
    return self:GetMoney(moneyType) >= amount
end

function QBBridge:RevivePlayer()
    TriggerEvent('hospital:client:Revive')
    local playerPed = PlayerPedId()
    if GetEntityHealth(playerPed) < 150 then
        SetEntityHealth(playerPed, 200)
    end
end

function QBBridge:GetFramework()
    return QBCore
end

return QBBridge