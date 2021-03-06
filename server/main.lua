local QBCore = exports['qb-core']:GetCoreObject()

local function ResetCheckpointStateTimer(point)
    local time = Config.ReloadTime
    SetTimeout(time, function()
        Config.Checkpoints[point]["opened"] = false
        TriggerClientEvent('qb-weldingbar:client:SetBusyState', -1, point, false)
    end)
end

QBCore.Functions.CreateCallback('qb-weldingbar:server:GetCheckpointsConfig', function(source, cb)
    cb(Config.Checkpoints)
end)

QBCore.Functions.CreateCallback('qb-weldingbar:server:HasItems', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local gastube = Player.Functions.GetItemByName("tubautogen")
    local weldingtool = Player.Functions.GetItemByName("aparatsudura")
    if gastube ~= nil and weldingtool ~= nil then
        cb(true)
    else
        cb(false)
    end
end)

RegisterNetEvent('qb-weldingbar:server:SetBusyState', function(point, bool)
    Config.Checkpoints[point]["opened"] = bool
    TriggerClientEvent('qb-weldingbar:client:SetBusyState', -1, point, bool)
end)

RegisterNetEvent('qb-weldingbar:server:RemoveItem', function(point)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local itemInfo2 = QBCore.Shared.Items["tubautogen"]
    Player.Functions.RemoveItem('tubautogen', 1)
    TriggerClientEvent('inventory:client:ItemBox', src, itemInfo2, "remove")
end)

RegisterNetEvent('qb-weldingbar:server:searchCheckpoint', function(point)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local itemInfo = QBCore.Shared.Items["ironore"]
    Player.Functions.AddItem("ironore", 1)
    TriggerClientEvent('inventory:client:ItemBox', src, itemInfo, "add")
    Config.Checkpoints[point]["opened"] = true
    TriggerClientEvent('qb-weldingbar:client:SetBusyState', -1, point, true)
    ResetCheckpointStateTimer(point)
end)
