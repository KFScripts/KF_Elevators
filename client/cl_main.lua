if Config.Framework == "esx" then
    FrameworkObject = exports['es_extended']:getSharedObject()
elseif Config.Framework == "qbcore" then
    FrameworkObject = exports['qb-core']:GetCoreObject()
end

local PlayerLoaded = false
local CurrentFloor = nil
local NearElevator = false

AddEventHandler('onClientResourceStart', function(resname)
    if GetCurrentResourceName() == resname then
        if Config.Framework == "esx" then
            while not FrameworkObject.IsPlayerLoaded() do
                Wait(500)
            end
            PlayerLoaded = true
        elseif Config.Framework == "qbcore" then
            while not FrameworkObject.Functions.GetPlayerData().job do
                Wait(500)
            end
            PlayerLoaded = true
        else
            PlayerLoaded = true
        end
    end
end)


Citizen.CreateThread(function()
    while true do
        local delay = 1000
        if PlayerLoaded then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local markerFound = false
            
            for building, elevators in pairs(Config.Elevators) do
                for i, elevator in ipairs(elevators) do
                    local coords = vector3(elevator.coords.x, elevator.coords.y, elevator.coords.z)
                    local distance = #(playerCoords - coords)
                    
                    if distance < Config.Marker.DrawDistance then
                        markerFound = true
                        DrawMarker(
                            Config.Marker.Type,
                            coords.x, coords.y, coords.z + 0.5,
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            Config.Marker.Scale.x, Config.Marker.Scale.y, Config.Marker.Scale.z,
                            Config.Marker.Color.r, Config.Marker.Color.g, Config.Marker.Color.b, Config.Marker.Color.a,
                            false, true, 2, false, nil, nil, false
                        )
                        if distance < Config.Marker.InteractDistance then
                            NearElevator = true
                            DrawText3D(coords.x, coords.y, coords.z + 1.0, "[E] - Elevator")
                            
                            if IsControlJustPressed(0, 38) then -- E Key
                                SendNUIMessage({
                                    type = "open",
                                    place = building,
                                    floors = Config.Elevators[building],
                                    colors = Config.Colors
                                })
                                SetNuiFocus(true, true)
                                RequestAnimDict("anim@mp_player_intmenu@key_fob@")
                                while not HasAnimDictLoaded("anim@mp_player_intmenu@key_fob@") do
                                    Wait(0)
                                end
                                TaskPlayAnim(PlayerPedId(), "anim@mp_player_intmenu@key_fob@", "fob_click", 8.0, 8.0, -1, 0, 0, 0, 0, 0)
                            end
                        end
                    end
                end
            end
            
            if markerFound then
                delay = 0
            end
        end
        Wait(delay)
    end
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
    SendNUIMessage({
        type = "close"
    })
end)

RegisterNUICallback('selectFloor', function(data, cb)
    cb('ok')
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "close"
    })
    DoScreenFadeOut(200)
    TriggerServerEvent('KF_Elevators:selectFloor', data.floor, data.building)
    Citizen.Wait(300)
    DoScreenFadeIn(200)
    ClearPedTasksImmediately(PlayerPedId())
end)
