-- Variables

local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()
local Welding = false
local SucceededAttempts = 0
local NeededAttempts = 4

-- Functions

local function DrawText3Ds(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end


local function GetClosestPlayer()
    local closestPlayers = QBCore.Functions.GetPlayersFromCoords()
    local closestDistance = -1
    local closestPlayer = -1
    local coords = GetEntityCoords(PlayerPedId())

    for i=1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
	end
	return closestPlayer, closestDistance
end


local function PoliceCall()
    local chance = 20
    if math.random(1, 100) <= chance then
        local data = exports['cd_dispatch']:GetPlayerInfo()
        TriggerServerEvent('cd_dispatch:triggerEverything', exports['cd_dispatch']:GetPlayerInfo(), nil, "police", "Alerta furt otel", "Cineva  a raportat persoane care fura otel pe strada "..data.street_1, "Furt otel")    
    end
end

local function CutIron(point)
    local ped = PlayerPedId()
    local Skillbar = exports['qb-skillbar']:GetSkillbarObject()
    QBCore.Functions.TriggerCallback('qb-weldingbar:server:HasItems', function(result)
        if result then
            TriggerServerEvent('qb-weldingbar:server:RemoveItem', point)
                TriggerServerEvent('qb-weldingbar:server:SetBusyState', point, true)
                FreezeEntityPosition(ped, true)
                TriggerEvent('animations:client:EmoteCommandStart', {"weld"})
                PoliceCall()
                Welding = true
                        Skillbar.Start({
                            duration = math.random(7500, 15000),
                            pos = math.random(10, 30),
                            width = math.random(10, 20),
                        }, function()
                            if SucceededAttempts + 1 >= NeededAttempts then
                                Welding = false
                                ClearPedTasks(PlayerPedId())
                                TriggerServerEvent('qb-weldingbar:server:searchCheckpoint', point)
                                Config.Checkpoints[point]["opened"] = true
                                TriggerServerEvent('qb-weldingbar:server:SetBusyState', point, true)
                                SucceededAttempts = 0
                                FreezeEntityPosition(ped, false)
                                SetTimeout(500, function()
                                    Welding = false
                                end)
                            else
                                Skillbar.Repeat({
                                    duration = math.random(700, 1250),
                                    pos = math.random(10, 40),
                                    width = math.random(10, 13),
                                })
                                SucceededAttempts = SucceededAttempts + 1
                            end
                        end, function()
                            TriggerEvent('animations:client:EmoteCommandStart', {"c"})
                            Welding = false
                            ClearPedTasks(PlayerPedId())
                            TriggerServerEvent('qb-weldingbar:server:SetBusyState', point, false)
                            QBCore.Functions.Notify("Proces Anulat..", "error")
                            SucceededAttempts = 0
                            FreezeEntityPosition(ped, false)
                            SetTimeout(500, function()
                                Welding = false
                            end)
                        end)  
        else
            QBCore.Functions.Notify("Iti lipseste aparatul de sudura sau tuburile..", "error")
        end
    end)  
end



-- Events

RegisterNetEvent('qb-weldingbar:client:SetBusyState', function(point, bool)
    Config.Checkpoints[point]["opened"]= bool
end)


RegisterNetEvent('qb-weldingbar:client:StartWelding', function(point, bool)
    CutIron(point)
    PoliceCall()
    Config.Checkpoints[point]["opened"]= bool
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.Functions.TriggerCallback('qb-weldingbar:server:GetCheckpointsConfig', function(CheckpointsConfig)
        Config.Checkpoints = CheckpointsConfig
    end)
end)

-- Threads

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local check = true
        local sleep = 1500
        for k, v in pairs(Config.Checkpoints) do
            local player, distance = GetClosestPlayer()
            if distance > 1 or distance == -1 then
                check = true
            else
                check = false
            end
                if #(pos - Config.Checkpoints[k]["coords"]) < 1 then
                    sleep = 3
                    if not Config.Checkpoints[k]["opened"] then
                        DrawText3Ds(Config.Checkpoints[k]["coords"].x, Config.Checkpoints[k]["coords"].y, Config.Checkpoints[k]["coords"].z + 0.7, '~g~E~w~ - Taie Otel ')
                            if IsControlJustReleased(0, 38) and check then
                                    Config.Checkpoints[k]["opened"]= false
                                    CutIron(k)
                            elseif  IsControlJustReleased(0, 38) and not check then
                                QBCore.Functions.Notify('Cineva este prea aproape de tine..', 'error', 3500)
                            end
                    else
                        DrawText3Ds(Config.Checkpoints[k]["coords"].x, Config.Checkpoints[k]["coords"].y, Config.Checkpoints[k]["coords"].z + 0.7, 'Taiat')
                    end
                end
        end
        Citizen.Wait(sleep)
    end
end)

-- Exports
