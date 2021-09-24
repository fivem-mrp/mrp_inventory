MRP_CLIENT = nil;

inInventory = false
hotbarOpen = false

local inventoryTest = {}
local currentWeapon = nil
local CurrentWeaponData = {}
local currentOtherInventory = nil
local Drops = {}
local CurrentDrop = 0
local DropsNear = {}

local Containers = {}

local CurrentVehicle = nil
local CurrentGlovebox = nil
local CurrentStash = nil
local CurrentContainer = nil
local isCrafting = false
local isHotbar = false
local showTrunkPos = false
local craftingDoneCallback = nil
local pickupsnowballDoneCallback = nil
local combineDoneCallback = nil

Citizen.CreateThread(function() 
    while MRP_CLIENT == nil do
        TriggerEvent("mrp:getSharedObject", function(obj) MRP_CLIENT = obj end)    
        Citizen.Wait(200)
    end
end)

RegisterNetEvent('mrp:spawn')
AddEventHandler('mrp:spawn', function(characterToUse, spawnIdx)
    if characterToUse ~= nil then
        MRP_CLIENT.setPlayerMetadata('isInvBusy', false)
    end
end)

RegisterNetEvent('mrp:inventory:client:CheckOpenState')
AddEventHandler('mrp:inventory:client:CheckOpenState', function(type, id, label)
    local name = MRPShared.SplitStr(label, "-")[2]
    if type == "stash" then
        if name ~= CurrentStash or CurrentStash == nil then
            TriggerServerEvent('mrp:inventory:server:SetIsOpenState', false, type, id)
        end
    elseif type == "trunk" then
        if name ~= CurrentVehicle or CurrentVehicle == nil then
            TriggerServerEvent('mrp:inventory:server:SetIsOpenState', false, type, id)
        end
    elseif type == "glovebox" then
        if name ~= CurrentGlovebox or CurrentGlovebox == nil then
            TriggerServerEvent('mrp:inventory:server:SetIsOpenState', false, type, id)
        end
    end
end)

RegisterNetEvent('weapons:client:SetCurrentWeapon')
AddEventHandler('weapons:client:SetCurrentWeapon', function(data, bool)
    if data ~= false then
        CurrentWeaponData = data
    else
        CurrentWeaponData = {}
    end
end)

function GetClosestVending()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local object = nil
    for _, machine in pairs(Config.VendingObjects) do
        local ClosestObject = GetClosestObjectOfType(pos.x, pos.y, pos.z, 0.75, GetHashKey(machine), 0, 0, 0)
        if ClosestObject ~= 0 and ClosestObject ~= nil then
            if object == nil then
                object = ClosestObject
            end
        end
    end
    return object
end

function DrawText3Ds(x, y, z, text)
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

RegisterNetEvent('randPickupAnim')
AddEventHandler('randPickupAnim', function()
    while not HasAnimDictLoaded("pickup_object") do RequestAnimDict("pickup_object") Wait(100) end
    TaskPlayAnim(PlayerPedId(),'pickup_object', 'putdown_low',5.0, 1.5, 1.0, 48, 0.0, 0, 0, 0)
    Wait(800)
    ClearPedTasks(PlayerPedId())
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(7)
        if showTrunkPos and not inInventory then
            local vehicle = exports["mrp_core"].GetClosestVehicle()
            if vehicle ~= 0 and vehicle ~= nil then
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                local vehpos = GetEntityCoords(vehicle)
                if #(pos - vehpos) < 5.0 and not IsPedInAnyVehicle(ped) then
                    local drawpos = GetOffsetFromEntityInWorldCoords(vehicle, 0, -2.5, 0)
                    if (IsBackEngine(GetEntityModel(vehicle))) then
                        drawpos = GetOffsetFromEntityInWorldCoords(vehicle, 0, 2.5, 0)
                    end
                    MRP_CLIENT.drawText3D(drawpos.x, drawpos.y, drawpos.z, "Trunk")
                    if #(pos - drawpos) < 2.0 and not IsPedInAnyVehicle(ped) then
                        CurrentVehicle = MRPShared.Trim(GetVehicleNumberPlateText(vehicle))
                        showTrunkPos = false
                    end
                else
                    showTrunkPos = false
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(7)
        if not inInventory then
            EnableControlAction(1, 19, true) --enable ATL key
            local containers = exports["mrp_core"].EnumerateObjects()
            if containers ~= 0 and containers ~= nil then
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                if not IsPedInAnyVehicle(ped) then
                    local foundAtLeastOneContainer = false
                    for k, container in pairs(containers) do
                        local hash = GetEntityModel(container)
                        local contpos = GetEntityCoords(container)
                        if Config.worldContainers[hash] ~= nil and #(pos - contpos) < 2.0 then
                            CurrentContainer = Config.worldContainers[hash]
                            --CurrentContainer['id'] = CurrentContainer.name .. container
                            --TODO this sometimes scuffs TEST
                            local netId = ObjToNet(container)
                            if not NetworkGetEntityIsNetworked(container) then
                                NetworkRegisterEntityAsNetworked(container)
                                netId = ObjToNet(container)
                                SetNetworkIdCanMigrate(netId, false)
                                NetworkUseHighPrecisionBlending(netId, false)
                                SetNetworkIdExistsOnAllMachines(netId, true)
                            end
                            
                            CurrentContainer['id'] = CurrentContainer.name .. netId
                            
                            foundAtLeastOneContainer = true
                        end
                    end
                    if not foundAtLeastOneContainer then
                        CurrentContainer = nil
                    end
                else
                    CurrentContainer = nil
                end
            end
        else
            DisableControlAction(1, 19, true) --disable ATL key
        end
    end
end)

RegisterCommand('closeinv', function()
    closeInventory()
end, false)

RegisterCommand('inventory', function()
    if not isCrafting then
        if not MRP_CLIENT.getPlayerMetadata()['isDead'] and not MRP_CLIENT.getPlayerMetadata()['isLastStand'] and not MRP_CLIENT.getPlayerMetadata()['isCuffed'] and not IsPauseMenuActive() then
            local ped = PlayerPedId()
            local curVeh = nil
            if IsPedInAnyVehicle(ped) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                CurrentGlovebox = MRPShared.Trim(GetVehicleNumberPlateText(vehicle))
                curVeh = vehicle
                CurrentVehicle = nil
            else
                local vehicle = exports["mrp_core"].GetClosestVehicle()
                if vehicle ~= 0 and vehicle ~= nil then
                    local pos = GetEntityCoords(ped)
                    local trunkpos = GetOffsetFromEntityInWorldCoords(vehicle, 0, -2.5, 0)
                    if (IsBackEngine(GetEntityModel(vehicle))) then
                        trunkpos = GetOffsetFromEntityInWorldCoords(vehicle, 0, 2.5, 0)
                    end
                    if #(pos - trunkpos) < 2.0 and not IsPedInAnyVehicle(ped) then
                        if GetVehicleDoorLockStatus(vehicle) < 2 then
                            CurrentVehicle = MRPShared.Trim(GetVehicleNumberPlateText(vehicle))
                            curVeh = vehicle
                            CurrentGlovebox = nil
                        else
                            TriggerEvent('chat:addMessage', {
                                template = '<div class="chat-message nonemergency">{0}</div>',
                                args = {"Vehicle is locked"}
                            })
                            goto continue
                        end
                    else
                        CurrentVehicle = nil
                    end
                else
                    CurrentVehicle = nil
                end
            end

            if CurrentVehicle ~= nil then
                local maxweight = 0
                local slots = 0
                local vehClass = GetVehicleClass(curVeh)
                if vehClass == 0 then
                    maxweight = 38000
                    slots = 30
                elseif vehClass == 1 then
                    maxweight = 50000
                    slots = 40
                elseif vehClass == 2 then
                    maxweight = 75000
                    slots = 50
                elseif vehClass == 3 then
                    maxweight = 42000
                    slots = 35
                elseif vehClass == 4 then
                    maxweight = 38000
                    slots = 30
                elseif vehClass == 5 then
                    maxweight = 30000
                    slots = 25
                elseif vehClass == 6 then
                    maxweight = 30000
                    slots = 25
                elseif vehClass == 7 then
                    maxweight = 30000
                    slots = 25
                elseif vehClass == 8 then
                    maxweight = 15000
                    slots = 15
                elseif vehClass == 9 then
                    maxweight = 60000
                    slots = 35
                elseif vehClass == 12 then
                    maxweight = 120000
                    slots = 35
                else
                    maxweight = 60000
                    slots = 35
                end
                local other = {
                    maxweight = maxweight,
                    slots = slots,
                }
                
                if vehClass == 13 then
                    --bicycles don't have trunk
                    if CurrentContainer ~= nil then
                        TriggerServerEvent("mrp:inventory:server:OpenInventory", "container", CurrentContainer)
                    elseif CurrentDrop ~= 0 then
                        TriggerServerEvent("mrp:inventory:server:OpenInventory", "drop", CurrentDrop)
                    else
                        TriggerServerEvent("mrp:inventory:server:OpenInventory")
                    end
                else
                    TriggerServerEvent("mrp:inventory:server:OpenInventory", "trunk", CurrentVehicle, other)
                    OpenTrunk()
                end
            elseif CurrentGlovebox ~= nil then
                TriggerServerEvent("mrp:inventory:server:OpenInventory", "glovebox", CurrentGlovebox)
            elseif CurrentContainer ~= nil then
                TriggerServerEvent("mrp:inventory:server:OpenInventory", "container", CurrentContainer)
            elseif CurrentDrop ~= 0 then
                TriggerServerEvent("mrp:inventory:server:OpenInventory", "drop", CurrentDrop)
            else
                TriggerServerEvent("mrp:inventory:server:OpenInventory")
            end
        end
        
        ::continue::
    end
end)

RegisterKeyMapping('inventory', 'Open Inventory', 'keyboard', 'g')

RegisterCommand('hotbar', function()
    isHotbar = not isHotbar
    ToggleHotbar(isHotbar)
end)
RegisterKeyMapping('hotbar', 'Toggles keybind slots', 'keyboard', 'h')

for i=1, 6 do 
    RegisterCommand('slot' .. i,function()
        if not MRP_CLIENT.getPlayerMetadata()['isDead'] and not MRP_CLIENT.getPlayerMetadata()['isLastStand'] and not MRP_CLIENT.getPlayerMetadata()['isCuffed'] and not IsPauseMenuActive() then
            if i == 6 then 
                i = MaxInventorySlots
            end
            TriggerServerEvent("mrp:inventory:server:UseItemSlot", i)
        end
    end)
    RegisterKeyMapping('slot' .. i, 'Uses the item in slot ' .. i, 'keyboard', i)
end

RegisterNetEvent('mrp:inventory:client:ItemBox')
AddEventHandler('mrp:inventory:client:ItemBox', function(itemData, type)
    SendNUIMessage({
        action = "itemBox",
        item = itemData,
        type = type
    })
end)

RegisterNetEvent('mrp:inventory:client:requiredItems')
AddEventHandler('mrp:inventory:client:requiredItems', function(items, bool)
    local itemTable = {}
    if bool then
        for k, v in pairs(items) do
            table.insert(itemTable, {
                item = items[k].name,
                label = MRPShared.Items(items[k].name)["label"],
                image = items[k].image,
            })
        end
    end
    
    SendNUIMessage({
        action = "requiredItem",
        items = itemTable,
        toggle = bool
    })
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if DropsNear ~= nil then
            for k, v in pairs(DropsNear) do
                if DropsNear[k] ~= nil then
                    DrawMarker(2, v.coords.x, v.coords.y, v.coords.z - 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.1, 255, 255, 255, 155, false, false, false, false, false, false, false)
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        if Drops ~= nil and next(Drops) ~= nil then
            local pos = GetEntityCoords(PlayerPedId(), true)
            for k, v in pairs(Drops) do
                if Drops[k] ~= nil then
                    local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                    if dist < 7.5 then
                        DropsNear[k] = v
                        if dist < 2 then
                            CurrentDrop = k
                        else
                            CurrentDrop = nil
                        end
                    else
                        DropsNear[k] = nil
                    end
                end
            end
        else
            DropsNear = {}
        end
        Citizen.Wait(500)
    end
end)

RegisterNetEvent('mrp:inventory:server:RobPlayer')
AddEventHandler('mrp:inventory:server:RobPlayer', function(TargetId)
    SendNUIMessage({
        action = "RobMoney",
        TargetId = TargetId,
    })
end)

RegisterNUICallback('RobMoney', function(data, cb)
    TriggerServerEvent("police:server:RobPlayer", data.TargetId)
end)

RegisterNUICallback('Notify', function(data, cb)
    TriggerEvent('chat:addMessage', {
        template = '<div class="chat-message nonemergency">{0}</div>',
        args = {data.message}
    })
end)

RegisterNetEvent("mrp:inventory:client:OpenInventory")
AddEventHandler("mrp:inventory:client:OpenInventory", function(PlayerAmmo, inventory, other)
    if not IsEntityDead(PlayerPedId()) then
        MRP_CLIENT.setPlayerMetadata("inMenu", true)
        TriggerEvent('randPickupAnim')
        Wait(300) -- Lets inv fully fade out before opening again
        ToggleHotbar(false)
        TriggerEvent('randPickupAnim')
        SetNuiFocus(true, true)
        if other ~= nil then
            currentOtherInventory = other.name
        end
        SendNUIMessage({
            action = "open",
            inventory = inventory,
            slots = MaxInventorySlots,
            other = other,
            maxweight = Config.MaxWeight,
            Ammo = PlayerAmmo,
            maxammo = Config.MaximumAmmoValues,
        })
        inInventory = true
    end
end)

function GetClosestPlayer()
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local closestDistance = -1
    local closestPlayer = -1
    for key, value in pairs(exports.mrp_core:EnumeratePeds()) do
        local playerHandle = NetworkGetPlayerIndexFromPed(value)
        if NetworkIsPlayerActive(playerHandle) then
            local targetCoords = GetEntityCoords(value)
            
            local dist = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, targetCoords.x, targetCoords.y, targetCoords.z)
            if closestDistance == -1 or dist < closestDistance then
                closestPlayer = value
                closestDistance = dist
            end
        end
	end

	return closestPlayer, closestDistance
end

RegisterNUICallback("GiveItem", function(data, cb)
    local player, distance = GetClosestPlayer()
    if player ~= -1 and distance < 2.5 then
        local playerPed = PlayerPedId(player)
        local playerId = GetPlayerServerId(player)
        local plyCoords = GetEntityCoords(playerPed)
        local pos = GetEntityCoords(PlayerPedId())
        local dist = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, plyCoords.x, plyCoords.y, plyCoords.z, true)
        if dist < 2.5 then
            SetCurrentPedWeapon(PlayerPedId(),'WEAPON_UNARMED',true)
            TriggerServerEvent("mrp:inventory:server:GiveItem", playerId, data.inventory, data.item, data.amount)
            print(data.amount)
        else
            TriggerEvent('chat:addMessage', {
                template = '<div class="chat-message nonemergency">{0}</div>',
                args = {"No one nearby!"}
            })
        end
    else
        TriggerEvent('chat:addMessage', {
            template = '<div class="chat-message nonemergency">{0}</div>',
            args = {"No one nearby!"}
        })
    end
end)

RegisterNetEvent("mrp:inventory:client:ShowTrunkPos")
AddEventHandler("mrp:inventory:client:ShowTrunkPos", function()
    showTrunkPos = true
end)

RegisterNetEvent("mrp:inventory:client:UpdatePlayerInventory")
AddEventHandler("mrp:inventory:client:UpdatePlayerInventory", function(isError)
    local player = MRP_CLIENT.GetPlayerData()
    MRP_CLIENT.TriggerServerCallback('mrp:inventory:server:getInventory', {{owner = player._id}}, function(inventory)
        local items = nil
        if inventory ~= nil then
            items = inventory.items
        end
        
        SendNUIMessage({
            action = "update",
            inventory = items,
            maxweight = Config.MaxWeight,
            slots = MaxInventorySlots,
            error = isError,
        })
    end)
end)

RegisterNUICallback('crafting_done', function(data, cb)
    if craftingDoneCallback ~= nil then
        craftingDoneCallback()
        craftingDoneCallback = nil
    end
end)

RegisterNetEvent("mrp:inventory:client:CraftItems")
AddEventHandler("mrp:inventory:client:CraftItems", function(itemName, itemCosts, amount, toSlot, points)
    local ped = PlayerPedId()
    SendNUIMessage({
        action = "close",
    })
    isCrafting = true
    
    LoadAnimDict('mini@repair')
    TaskPlayAnim(ped, 'mini@repair', 'fixing_a_player', 3.0, 3.0, -1, 16, 1, true, true, true)
    
    TriggerEvent('mrp:startTimer', {
        timer = (math.random(2000, 5000) * amount),
        timerAction = 'https://mrp_inventory/crafting_done'
    })
    
    craftingDoneCallback = function()
        StopAnimTask(ped, "mini@repair", "fixing_a_player", 1.0)
        TriggerServerEvent("mrp:inventory:server:CraftItems", itemName, itemCosts, amount, toSlot, points)
        TriggerEvent('mrp:inventory:client:ItemBox', MRPShared.Items(itemName), 'add')
        isCrafting = false
    end
end)

RegisterNetEvent('mrp:inventory:client:CraftAttachment')
AddEventHandler('mrp:inventory:client:CraftAttachment', function(itemName, itemCosts, amount, toSlot, points)
    local ped = PlayerPedId()
    SendNUIMessage({
        action = "close",
    })
    isCrafting = true
    
    LoadAnimDict('mini@repair')
    TaskPlayAnim(ped, 'mini@repair', 'fixing_a_player', 3.0, 3.0, -1, 16, 1, true, true, true)
    
    TriggerEvent('mrp:startTimer', {
        timer = (math.random(2000, 5000) * amount),
        timerAction = 'https://mrp_inventory/crafting_done'
    })
    
    craftingDoneCallback = function()
        StopAnimTask(ped, "mini@repair", "fixing_a_player", 1.0)
        TriggerServerEvent("mrp:inventory:server:CraftAttachment", itemName, itemCosts, amount, toSlot, points)
        TriggerEvent('mrp:inventory:client:ItemBox', MRPShared.Items(itemName), 'add')
        isCrafting = false
    end
end)

RegisterNUICallback('pickupsnowball_done', function(data, cb)
    if pickupsnowballDoneCallback ~= nil then
        pickupsnowballDoneCallback()
        pickupsnowballDoneCallback = nil
    end
end)

RegisterNetEvent("mrp:inventory:client:PickupSnowballs")
AddEventHandler("mrp:inventory:client:PickupSnowballs", function()
    local ped = PlayerPedId()
    LoadAnimDict('anim@mp_snowball')
    TaskPlayAnim(ped, 'anim@mp_snowball', 'pickup_snowball', 3.0, 3.0, -1, 0, 1, 0, 0, 0)
    
    TriggerEvent('mrp:startTimer', {
        timer = 1500,
        timerAction = 'https://mrp_inventory/pickupsnowball_done'
    })
    
    pickupsnowballDoneCallback = function()
        ClearPedTasks(ped)
        TriggerServerEvent('mrp:inventory:server:AddItem', "snowball", 1)
        TriggerEvent('mrp:inventory:client:ItemBox', MRPShared.Items("snowball"), "add")
    end
end)

AddEventHandler('mrp:inventory:client:hasItem', function(name, cb)
    MRP_CLIENT.TriggerServerCallback('mrp:inventory:server:hasItem', {name}, function(res)
        cb(res)
    end)
end)

AddEventHandler('mrp:inventory:client:useAmmo', function(data)
    if currentWeapon == nil then
        TriggerEvent('chat:addMessage', {
            template = '<div class="chat-message nonemergency">{0}</div>',
            args = {"You don't have a weapon equipped to use ammo"}
        })
        return;
    end
    
    if currentWeapon.ammotype ~= data.name then
        TriggerEvent('chat:addMessage', {
            template = '<div class="chat-message nonemergency">{0}</div>',
            args = {"Wrong type of ammo for your weapon"}
        })
        return;
    end
    
    local rounds = Config.AmmoRounds[data.name]
    if rounds == nil then
        TriggerEvent('chat:addMessage', {
            template = '<div class="chat-message nonemergency">{0}</div>',
            args = {"Unknown ammo type"}
        })
        return;
    end
    
    local ped = PlayerPedId()
    local ammo = GetAmmoInPedWeapon(ped, GetHashKey(currentWeapon.name));
    ammo = ammo + rounds
    
    SetPedAmmo(ped, GetHashKey(currentWeapon.name), ammo)
    
    currentWeapon.info.ammo = ammo
    
    --TriggerServerEvent('mrp:inventory:server:RemoveItem', data.name, 1, data.slot)
    data.persistent = false
    TriggerServerEvent('mrp:server:item:used', GetPlayerServerId(PlayerId()), data)
end)

RegisterNetEvent("mrp:inventory:client:UseSnowball")
AddEventHandler("mrp:inventory:client:UseSnowball", function(amount)
    local ped = PlayerPedId()
    GiveWeaponToPed(ped, GetHashKey("weapon_snowball"), amount, false, false)
    SetPedAmmo(ped, GetHashKey("weapon_snowball"), amount)
    SetCurrentPedWeapon(ped, GetHashKey("weapon_snowball"), true)
end)

RegisterNetEvent("mrp:inventory:client:UseWeapon")
AddEventHandler("mrp:inventory:client:UseWeapon", function(weaponData, shootbool)
    local ped = PlayerPedId()
    local weaponName = tostring(weaponData.name)
    if currentWeapon ~= nil and currentWeapon.name == weaponName then
        LoadAnimDict(Config.WeaponOutDict)
        TaskPlayAnim(ped, Config.WeaponOutDict, Config.WeaponHideAnim, 8.0, 2.0, 2000, 48, 2, 0, 0, 0)
        Citizen.Wait(1000)
        
        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
        TriggerEvent('weapons:client:SetCurrentWeapon', nil, shootbool)
        --update ammo
        local ammo = GetAmmoInPedWeapon(ped, GetHashKey(weaponName));
        if currentWeapon.info == nil or currentWeapon.info == "" then
            currentWeapon.info = { ammo = 0}
        end
        currentWeapon.info.ammo = ammo
        TriggerServerEvent('mrp:inventory:server:UpdateItem', currentWeapon)
        RemoveAllPedWeapons(ped, true)
        currentWeapon = nil
    elseif weaponName == "weapon_stickybomb" then
        GiveWeaponToPed(ped, GetHashKey(weaponName), ammo, false, false)
        SetPedAmmo(ped, GetHashKey(weaponName), 1)
        SetCurrentPedWeapon(ped, GetHashKey(weaponName), true)
        TriggerServerEvent('mrp:inventory:server:RemoveItem', weaponName, 1)
        TriggerEvent('weapons:client:SetCurrentWeapon', weaponData, shootbool)
        currentWeapon = weaponData
    elseif weaponName == "weapon_snowball" then
        GiveWeaponToPed(ped, GetHashKey(weaponName), ammo, false, false)
        SetPedAmmo(ped, GetHashKey(weaponName), 10)
        SetCurrentPedWeapon(ped, GetHashKey(weaponName), true)
        TriggerServerEvent('mrp:inventory:server:RemoveItem', weaponName, 1)
        TriggerEvent('weapons:client:SetCurrentWeapon', weaponData, shootbool)
        currentWeapon = weaponData
    else
        TriggerEvent('weapons:client:SetCurrentWeapon', weaponData, shootbool)
        local ammo = GetAmmoInPedWeapon(ped, GetHashKey(weaponName));
        if weaponData ~= nil and weaponData.info ~= nil and weaponData.info.ammo then
            ammo = weaponData.info.ammo
            ammo = tonumber(ammo)
        end
        
        if weaponName == "weapon_petrolcan" or weaponName == "weapon_fireextinguisher" then 
            ammo = 4000 
        end
        
        LoadAnimDict(Config.WeaponOutDict)
        TaskPlayAnim(ped, Config.WeaponOutDict, Config.WeaponOutAnim, 8.0, 2.0, 2000, 48, 2, 0, 0, 0)
        Citizen.Wait(1000)
        
        GiveWeaponToPed(ped, GetHashKey(weaponName), ammo, false, false)
        SetPedAmmo(ped, GetHashKey(weaponName), ammo)
        SetCurrentPedWeapon(ped, GetHashKey(weaponName), true)
        if weaponData.info.attachments ~= nil then
            for _, attachment in pairs(weaponData.info.attachments) do
                GiveWeaponComponentToPed(ped, GetHashKey(weaponName), GetHashKey(attachment.component))
            end
        end
        currentWeapon = weaponData
    end
end)

WeaponAttachments = {
    ["WEAPON_SNSPISTOL"] = {
        ["extendedclip"] = {
            component = "COMPONENT_SNSPISTOL_CLIP_02",
            label = "Extended Clip",
            item = "pistol_extendedclip",
        },
    },
    ["WEAPON_VINTAGEPISTOL"] = {
        ["suppressor"] = {
            component = "COMPONENT_AT_PI_SUPP",
            label = "Suppressor",
            item = "pistol_suppressor",
        },
        ["extendedclip"] = {
            component = "COMPONENT_VINTAGEPISTOL_CLIP_02",
            label = "Extended Clip",
            item = "pistol_extendedclip",
        },
    },
    ["WEAPON_MICROSMG"] = {
        ["suppressor"] = {
            component = "COMPONENT_AT_AR_SUPP_02",
            label = "Suppressor",
            item = "smg_suppressor",
        },
        ["extendedclip"] = {
            component = "COMPONENT_MICROSMG_CLIP_02",
            label = "Extended Clip",
            item = "smg_extendedclip",
        },
        ["flashlight"] = {
            component = "COMPONENT_AT_PI_FLSH",
            label = "Flashlight",
            item = "smg_flashlight",
        },
        ["scope"] = {
            component = "COMPONENT_AT_SCOPE_MACRO",
            label = "Scope",
            item = "smg_scope",
        },
    },
    ["WEAPON_MINISMG"] = {
        ["extendedclip"] = {
            component = "COMPONENT_MINISMG_CLIP_02",
            label = "Extended Clip",
            item = "smg_extendedclip",
        },
    },
    ["WEAPON_COMPACTRIFLE"] = {
        ["extendedclip"] = {
            component = "COMPONENT_COMPACTRIFLE_CLIP_02",
            label = "Extended Clip",
            item = "rifle_extendedclip",
        },
        ["drummag"] = {
            component = "COMPONENT_COMPACTRIFLE_CLIP_03",
            label = "Drum Mag",
            item = "rifle_drummag",
        },
    },
}

function FormatWeaponAttachments(itemdata)
    local attachments = {}
    itemdata.name = itemdata.name:upper()
    if itemdata.info.attachments ~= nil and next(itemdata.info.attachments) ~= nil then
        for k, v in pairs(itemdata.info.attachments) do
            if WeaponAttachments[itemdata.name] ~= nil then
                for key, value in pairs(WeaponAttachments[itemdata.name]) do
                    if value.component == v.component then
                        table.insert(attachments, {
                            attachment = key,
                            label = value.label
                        })
                    end
                end
            end
        end
    end
    return attachments
end

RegisterNUICallback('GetWeaponData', function(data, cb)
    local data = {
        WeaponData = MRPShared.Items(data.weapon),
        AttachmentData = FormatWeaponAttachments(data.ItemData)
    }
    cb(data)
end)

RegisterNUICallback('RemoveAttachment', function(data, cb)
    --TODO need to figure out weapons
    local ped = PlayerPedId()
    local WeaponData = MRP_SERVER.Items[data.WeaponData.name]
    local Attachment = WeaponAttachments[WeaponData.name:upper()][data.AttachmentData.attachment]
    
    QBCore.Functions.TriggerCallback('weapons:server:RemoveAttachment', function(NewAttachments)
        if NewAttachments ~= false then
            local Attachies = {}
            RemoveWeaponComponentFromPed(ped, GetHashKey(data.WeaponData.name), GetHashKey(Attachment.component))
            for k, v in pairs(NewAttachments) do
                for wep, pew in pairs(WeaponAttachments[WeaponData.name:upper()]) do
                    if v.component == pew.component then
                        table.insert(Attachies, {
                            attachment = pew.item,
                            label = pew.label,
                        })
                    end
                end
            end
            local DJATA = {
                Attachments = Attachies,
                WeaponData = WeaponData,
            }
            cb(DJATA)
        else
            RemoveWeaponComponentFromPed(ped, GetHashKey(data.WeaponData.name), GetHashKey(Attachment.component))
            cb({})
        end
    end, data.AttachmentData, data.WeaponData)
end)

RegisterNetEvent("mrp:inventory:client:CheckWeapon")
AddEventHandler("mrp:inventory:client:CheckWeapon", function(weaponName)
    local ped = PlayerPedId()
    if currentWeapon ~= nil and currentWeapon.name == weaponName then 
        TriggerEvent('weapons:ResetHolster')
        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
        --RemoveAllPedWeapons(ped, true)
        currentWeapon = nil
    end
end)

RegisterNetEvent("mrp:inventory:client:AddDropItem")
AddEventHandler("mrp:inventory:client:AddDropItem", function(dropId, player, coords)
    local forward = GetEntityForwardVector(GetPlayerPed(GetPlayerFromServerId(player)))
	local x, y, z = table.unpack(coords + forward * 0.5)
    Drops[dropId] = {
        id = dropId,
        coords = {
            x = x,
            y = y,
            z = z - 0.3,
        },
    }
end)

RegisterNetEvent("mrp:inventory:client:RemoveDropItem")
AddEventHandler("mrp:inventory:client:RemoveDropItem", function(dropId)
    Drops[dropId] = nil
end)

RegisterNetEvent("mrp:inventory:client:RemoveContainerItem")
AddEventHandler("mrp:inventory:client:RemoveContainerItem", function(container)
    Containers[container.id] = nil
end)

RegisterNetEvent("mrp:inventory:client:DropItemAnim")
AddEventHandler("mrp:inventory:client:DropItemAnim", function()
    local ped = PlayerPedId()
    SendNUIMessage({
        action = "close",
    })
    RequestAnimDict("pickup_object")
    while not HasAnimDictLoaded("pickup_object") do
        Citizen.Wait(7)
    end
    TaskPlayAnim(ped, "pickup_object" ,"pickup_low" ,8.0, -8.0, -1, 1, 0, false, false, false )
    Citizen.Wait(2000)
    ClearPedTasks(ped)
end)

RegisterNetEvent("mrp:inventory:client:SetCurrentStash")
AddEventHandler("mrp:inventory:client:SetCurrentStash", function(stash)
    CurrentStash = stash
end)

RegisterNUICallback('getCombineItem', function(data, cb)
    cb(MRPShared.Items(data.item))
end)

RegisterNUICallback("CloseInventory", function(data, cb)
    cb()
    MRP_CLIENT.setPlayerMetadata("inMenu", false)
    if currentOtherInventory == "none-inv" then
        CurrentDrop = 0
        CurrentVehicle = nil
        CurrentGlovebox = nil
        CurrentStash = nil
        CurrentContainer = nil
        SetNuiFocus(false, false)
        inInventory = false
        ClearPedTasks(PlayerPedId())
        return
    end
    if CurrentVehicle ~= nil then
        local vehicle = exports["mrp_core"].GetClosestVehicle()
        local vehClass = GetVehicleClass(vehicle)
        if vehClass == 13 then
            --bicycles don't have trunk
            if CurrentGlovebox ~= nil then
                TriggerServerEvent("mrp:inventory:server:SaveInventory", "glovebox", CurrentGlovebox)
                CurrentGlovebox = nil
            elseif CurrentStash ~= nil then
                TriggerServerEvent("mrp:inventory:server:SaveInventory", "stash", CurrentStash)
                CurrentStash = nil
            elseif CurrentContainer ~= nil then
                TriggerServerEvent("mrp:inventory:server:SaveInventory", "container", CurrentContainer)
                CurrentContainer = nil
            else
                TriggerServerEvent("mrp:inventory:server:SaveInventory", "drop", CurrentDrop)
                CurrentDrop = 0
            end
        else
            CloseTrunk()
            TriggerServerEvent("mrp:inventory:server:SaveInventory", "trunk", CurrentVehicle)
        end
        CurrentVehicle = nil
    elseif CurrentGlovebox ~= nil then
        TriggerServerEvent("mrp:inventory:server:SaveInventory", "glovebox", CurrentGlovebox)
        CurrentGlovebox = nil
    elseif CurrentStash ~= nil then
        TriggerServerEvent("mrp:inventory:server:SaveInventory", "stash", CurrentStash)
        CurrentStash = nil
    elseif CurrentContainer ~= nil then
        TriggerServerEvent("mrp:inventory:server:SaveInventory", "container", CurrentContainer)
        CurrentContainer = nil
    else
        TriggerServerEvent("mrp:inventory:server:SaveInventory", "drop", CurrentDrop)
        CurrentDrop = 0
    end
    SetNuiFocus(false, false)
    inInventory = false
end)
RegisterNUICallback("UseItem", function(data, cb)
    TriggerServerEvent("mrp:inventory:server:UseItem", data.inventory, data.item)
end)

RegisterNUICallback("combineItem", function(data)
    Citizen.Wait(150)
    TriggerServerEvent('mrp:inventory:server:combineItem', data.reward, data.fromItem, data.toItem)
    TriggerEvent('mrp:inventory:client:ItemBox', MRPShared.Items(data.reward), 'add')
end)

RegisterNUICallback('combine_done', function(data)
    if combineDoneCallback ~= nil then
        combineDoneCallback()
        combineDoneCallback = nil
    end
end)

RegisterNUICallback('combineWithAnim', function(data)
    local ped = PlayerPedId()
    local combineData = data.combineData
    local aDict = combineData.anim.dict
    local aLib = combineData.anim.lib
    local animText = combineData.anim.text
    local animTimeout = combineData.anim.timeOut
    
    LoadAnimDict(aDict)
    TaskPlayAnim(ped, aDict, aLib, 3.0, 3.0, -1, 16, 1, true, true, true)
    
    TriggerEvent('mrp:startTimer', {
        timer = animTimeout,
        timerAction = 'https://mrp_inventory/combine_done'
    })
    
    combineDoneCallback = function()
        StopAnimTask(ped, aDict, aLib, 1.0)
        TriggerServerEvent('mrp:inventory:server:combineItem', combineData.reward, data.requiredItem, data.usedItem)
        TriggerEvent('mrp:inventory:client:ItemBox', MRPShared.Items(combineData.reward), 'add')
    end
end)

RegisterNUICallback("SetInventoryData", function(data, cb)
    TriggerServerEvent("mrp:inventory:server:SetInventoryData", data.fromInventory, data.toInventory, data.fromSlot, data.toSlot, data.fromAmount, data.toAmount)
end)

RegisterNUICallback("PlayDropSound", function(data, cb)
    PlaySound(-1, "CLICK_BACK", "WEB_NAVIGATION_SOUNDS_PHONE", 0, 0, 1)
end)

RegisterNUICallback("PlayDropFail", function(data, cb)
    PlaySound(-1, "Place_Prop_Fail", "DLC_Dmod_Prop_Editor_Sounds", 0, 0, 1)
end)

function OpenTrunk()
    local vehicle = exports["mrp_core"].GetClosestVehicle()
    while (not HasAnimDictLoaded("amb@prop_human_bum_bin@idle_b")) do
        RequestAnimDict("amb@prop_human_bum_bin@idle_b")
        Citizen.Wait(100)
    end
    TaskPlayAnim(PlayerPedId(), "amb@prop_human_bum_bin@idle_b", "idle_d", 4.0, 4.0, -1, 50, 0, false, false, false)
    if (IsBackEngine(GetEntityModel(vehicle))) then
        SetVehicleDoorOpen(vehicle, 4, false, false)
    else
        SetVehicleDoorOpen(vehicle, 5, false, false)
    end
end

function CloseTrunk()
    local vehicle = exports["mrp_core"].GetClosestVehicle()
    while (not HasAnimDictLoaded("amb@prop_human_bum_bin@idle_b")) do
        RequestAnimDict("amb@prop_human_bum_bin@idle_b")
        Citizen.Wait(100)
    end
    TaskPlayAnim(PlayerPedId(), "amb@prop_human_bum_bin@idle_b", "exit", 4.0, 4.0, -1, 50, 0, false, false, false)
    if (IsBackEngine(GetEntityModel(vehicle))) then
        SetVehicleDoorShut(vehicle, 4, false)
    else
        SetVehicleDoorShut(vehicle, 5, false)
    end
end

function IsBackEngine(vehModel)
    for _, model in pairs(BackEngineVehicles) do
        if GetHashKey(model) == vehModel then
            return true
        end
    end
    return false
end

local function getItemBySlot(items, slot)
    local item = nil
    
    for k, v in pairs(items) do
        if v.slot == slot then
            item = v
        end
    end
    
    return item
end

function closeInventory()
    SendNUIMessage({
        action = "close",
    })
end

function ToggleHotbar(toggle)
    local player = MRP_CLIENT.GetPlayerData()
    MRP_CLIENT.TriggerServerCallback('mrp:inventory:server:getInventory', {{owner = player._id}}, function(inventory)
        local items = {}
        if inventory ~= nil then
            items = inventory.items
        end
        
        local HotbarItems = {
            [1] = getItemBySlot(items, 1),
            [2] = getItemBySlot(items, 2),
            [3] = getItemBySlot(items, 3),
            [4] = getItemBySlot(items, 4),
            [5] = getItemBySlot(items, 5),
            [41] = getItemBySlot(items, 41),
        } 
    
        if toggle then
            SendNUIMessage({
                action = "toggleHotbar",
                open = true,
                items = HotbarItems
            })
        else
            SendNUIMessage({
                action = "toggleHotbar",
                open = false,
            })
        end
    end)
end

function LoadAnimDict( dict )
    while ( not HasAnimDictLoaded( dict ) ) do
        RequestAnimDict( dict )
        Citizen.Wait( 5 )
    end
end

Citizen.CreateThread(function()
    local armed = false
    local shooting = false
    while true do
        Wait(1)     
        local ped = PlayerPedId()
        if not IsPedArmed(ped, 7) then
            if armed then
                --print('was armed')
                if currentWeapon ~= nil then
                    local ammo = GetAmmoInPedWeapon(ped, GetHashKey(currentWeapon.name));
                    if currentWeapon.info == nil or currentWeapon.info == "" then
                        currentWeapon.info = { ammo = 0}
                    end
                    currentWeapon.info.ammo = ammo
                    TriggerServerEvent('mrp:inventory:server:UpdateItem', currentWeapon)
                    currentWeapon = nil
                end
            end
            Wait(1000)
            armed = false
        else
            armed = true
            if IsPedShooting(ped) then
                shooting = true
            else
                --[[if shooting then
                    print('was shooting')
                end]]--
                shooting = false
            end
        end
    end
end)
