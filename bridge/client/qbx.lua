local QBXBridge = {}
QBXBridge.__index = QBXBridge

function QBXBridge:Init()
    if GetResourceState('qbx_core') ~= 'started' then
        return false
    end
    return true
end

function QBXBridge:GetPlayerData()
    return exports.qbx_core:GetPlayerData()
end

function QBXBridge:IsPlayerDead()
    if GetResourceState('qbx_medical') == 'started' then
        local isDead = exports.qbx_medical:IsDead()
        local isLaststand = exports.qbx_medical:IsLaststand()
        return isDead or isLaststand
    end
    local playerPed = PlayerPedId()
    if IsEntityDead(playerPed) then
        return true
    end
    local playerData = self:GetPlayerData()
    if playerData and playerData.metadata and (playerData.metadata['isdead'] or playerData.metadata['inlaststand']) then
        return true
    end
    if playerData and playerData.job and playerData.job.name == 'ambulance' then
        return false
    end
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.isDead then
        return true
    end
    if GetEntityHealth(playerPed) <= 0 then
        return true
    end
    return false
end

function QBXBridge:GetJob()
    local playerData = self:GetPlayerData()
    return playerData and playerData.job or nil
end

function QBXBridge:HasJob(jobName)
    local job = self:GetJob()
    return job and job.name == jobName
end

function QBXBridge:GetMoney(moneyType)
    local playerData = self:GetPlayerData()
    moneyType = moneyType or 'cash'
    return playerData and playerData.money and playerData.money[moneyType] or 0
end

function QBXBridge:HasMoney(amount, moneyType)
    return self:GetMoney(moneyType) >= amount
end

function QBXBridge:RevivePlayer()
    TriggerEvent('qbx_medical:client:playerRevived')
    Wait(100)
    local playerPed = PlayerPedId()
    ClearPedTasksImmediately(playerPed)
    if GetEntityHealth(playerPed) < 200 then
        SetEntityHealth(playerPed, 200)
    end
    ClearPedBloodDamage(playerPed)
    SetPlayerInvincible(PlayerId(), false)
    SetEntityInvincible(playerPed, false)
    if IsPedRagdoll(playerPed) then
        SetPedToRagdoll(playerPed, 1, 1, 0, false, false, false)
    end
end

function QBXBridge:GetFramework()
    return 'qbx'
end

return QBXBridge