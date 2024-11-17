local VORPcore = exports.vorp_core:GetCore()
local BackpackInInventory = false
local BackpackAttached = false
local GetBackpackModel = nil

if Config.Debug then
    Citizen.CreateThread(function()
        TriggerServerEvent('mms-backpack:server:CheckBackpack')
    end)
end

RegisterNetEvent('vorp:SelectedCharacter')
AddEventHandler('vorp:SelectedCharacter', function()
    Citizen.Wait(10000)
    TriggerServerEvent('mms-backpack:server:CheckBackpack')
end)

RegisterNetEvent('mms-backpack:client:HasBackpack')
AddEventHandler('mms-backpack:client:HasBackpack',function(BackpackModel)
    BackpackInInventory = true
    GetBackpackModel = BackpackModel
end)

RegisterNetEvent('mms-backpack:client:HasNoBackpack')
AddEventHandler('mms-backpack:client:HasNoBackpack',function()
    BackpackInInventory = false
end)

Citizen.CreateThread(function ()
   while true do
        Citizen.Wait(500)
        TriggerServerEvent('mms-backpack:server:CheckBackpack')
        if BackpackInInventory and not BackpackAttached and not IsPedOnMount(PlayerPedId()) then
            Backpack = CreateObject(GetHashKey(GetBackpackModel), GetEntityCoords(PlayerPedId()), true, true, true)
            local Spine = GetEntityBoneIndexByName(PlayerPedId(), 'CP_Back')
            if GetBackpackModel == Config.SmallModel then
                AttachEntityToEntity(Backpack, PlayerPedId(), Spine, -0.35, 0.0, 0.12, -70.0, 0.0, -90.0, true, true, false, true, 1, true)
            elseif GetBackpackModel == Config.BigModel then
                AttachEntityToEntity(Backpack, PlayerPedId(), Spine, -0.5, 0.0, 0.08, -80.0, 0.0, -90.0, true, true, false, true, 1, true)
            end
            BackpackAttached = true
        elseif not BackpackInInventory and BackpackAttached then
            BackpackAttached = false
            DetachEntity(Backpack, true, true)
            DeleteEntity(Backpack)
        end
        Citizen.Wait(500)
    end
end)

-- Snipped To Test Bones

--[[Citizen.CreateThread(function()
    for h,v in ipairs(Config.Positions) do
        Backpack = CreateObject(GetHashKey('p_ambpack01x'), GetEntityCoords(PlayerPedId()), true, true, true)
        local Spine = GetEntityBoneIndexByName(PlayerPedId(), v.BodyPart)
        AttachEntityToEntity(Backpack, PlayerPedId(), Spine, 0.0, -0.2, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        Citizen.Wait(5000)
        DetachEntity(Backpack, true, true)
        print(v.BodyPart)
    end
end)]]

--########################### LOAD MODEL ###########################
function LoadModel(model)
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(100)
    end
end


---- CleanUp on Resource Restart 

RegisterNetEvent('onResourceStop',function(resource)
    DetachEntity(Backpack, true, true)
end)
