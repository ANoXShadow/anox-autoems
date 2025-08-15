local ESXBridge = {}
ESXBridge.__index = ESXBridge
local ESX = nil

function ESXBridge:Init()
    ESX = exports['es_extended']:getSharedObject()
    if not ESX then
        return false
    end
    return true
end

function ESXBridge:GetPlayerData()
    return ESX.GetPlayerData()
end

function ESXBridge:IsPlayerDead()
    local playerPed = PlayerPedId()
    if IsEntityDead(playerPed) then
        return true
    end
    local playerData = self:GetPlayerData()
    if playerData.metadata and playerData.metadata.dead then
        return true
    end
    if LocalPlayer and LocalPlayer.state.dead then
        return true
    end
    if isDead ~= nil then
        return isDead
    end
    return false
end

function ESXBridge:GetJob()
    local playerData = self:GetPlayerData()
    return playerData.job
end

function ESXBridge:HasJob(jobName)
    local job = self:GetJob()
    return job and job.name == jobName
end

function ESXBridge:GetMoney(moneyType)
    local playerData = self:GetPlayerData()
    moneyType = moneyType or 'cash'
    if moneyType == 'cash' then
        for _, account in ipairs(playerData.accounts or {}) do
            if account.name == 'money' then
                return account.money
            end
        end
    elseif moneyType == 'bank' then
        for _, account in ipairs(playerData.accounts or {}) do
            if account.name == 'bank' then
                return account.money
            end
        end
    end
    
    return 0
end

function ESXBridge:HasMoney(amount, moneyType)
    return self:GetMoney(moneyType) >= amount
end

function ESXBridge:RevivePlayer()
    TriggerEvent('esx_ambulancejob:revive')
end

function ESXBridge:GetFramework()
    return ESX
end

return ESXBridge