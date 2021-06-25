MRP_SERVER = nil

TriggerEvent('mrp:getSharedObject', function(obj) MRP_SERVER = obj end)

Drops = {}
Trunks = {}
Gloveboxes = {}
Stashes = {}
ShopItems = {}

local function GetItemBySlot(ply, slot, cb)
    MRP_SERVER.read('inventory', {
        owner = ply._id
    }, function(inventory)
        local item = nil
        if inventory ~= nil and inventory.items ~= nil then
            for k, v in pairs(inventory.items) do
                if v.slot == slot then
                    item = v
                    break
                end
            end
        end
        cb(item)
    end)
end

local function GetItemByName(ply, name)
    local item = nil
    local p = promise.new()
    
    MRP_SERVER.read('inventory', {
        owner = ply._id
    }, function(inventory)
        if inventory ~= nil and inventory.items ~= nil then
            for k, v in pairs(inventory.items) do
                if v.name == name then
                    item = v
                    break
                end
            end
        end
        p:resolve(true)
    end)
    
    Citizen.Await(p)
    
    return item
end

local function findAvailableSlot(inventory)
    local foundSlot = 1
    if inventory == nil or inventory.items == nil then
        return 1
    end
    
    for i = 1, MaxInventorySlots, 1 do
        local found = false
        for k, v in pairs(inventory.items) do
            if v.slot == i then
                found = true
                break
            end
        end
        
        if not found then
            foundSlot = i
            break
        end
    end
    
    return foundSlot
end

local function AddItem(ply, name, quantity, slot, info)
    MRP_SERVER.read('inventory', {
        owner = ply._id
    }, function(inventory)
        if inventory == nil then
            inventory = {
                owner = ply._id,
                ammo = {0}
            }
        end
        
        local item = MRPShared.Items(name)
        
        if slot == nil or not slot then
            slot = findAvailableSlot(inventory)
        end
        
        local added = false
        local itemsCount = 0
        if inventory.items ~= nil then
            for k, v in pairs(inventory.items) do
                itemsCount = itemsCount + 1
                if v.name == name then
                    v.amount = v.amount + quantity
                    if slot then
                        v.slot = slot
                    end
                    added = true
                    break
                end
            end
        else
            inventory.items = {}
        end
        
        if not added then
            if quantity then
                item.amount = quantity
            end
            
            if info then
                item.info = info
            else
                item.info = ""
            end
            
            item.slot = slot
            
            table.insert(inventory.items, item)
        end
        
        MRP_SERVER.update('inventory', inventory, {owner = ply._id}, {upsert=true}, function(res)
            print('Inventory item added for ' .. ply.name .. ' ' .. ply.surname)
        end)
    end)
end

local function RemoveItem(ply, name, quantity, fromSlot)
    MRP_SERVER.read('inventory', {
        owner = ply._id
    }, function(inventory)
        if inventory == nil then
            inventory = {
                owner = ply._id,
                items = {}
            }
        else
            if inventory.items ~= nil then
                for k, v in pairs(inventory.items) do
                    if v.name == name and (fromSlot ~= nil and v.slot == fromSlot) then
                        v.amount = v.amount - quantity
                        if v.amount <= 0 then
                            table.remove(inventory.items, k)
                        end
                        break
                    end
                end
            end
        end
        
        MRP_SERVER.update('inventory', inventory, {owner = ply._id}, {upsert=true}, function(res)
            print('Inventory item removed for ' .. ply.name .. ' ' .. ply.surname)
        end)
    end)
end

RegisterServerEvent("inventory:server:LoadDrops")
AddEventHandler('inventory:server:LoadDrops', function()
	local src = source
	if next(Drops) ~= nil then
		TriggerClientEvent("inventory:client:AddDropItem", -1, dropId, source)
		TriggerClientEvent("inventory:client:AddDropItem", src, Drops)
	end
end)

RegisterServerEvent("inventory:server:addTrunkItems")
AddEventHandler('inventory:server:addTrunkItems', function(plate, items)
	Trunks[plate] = {}
	Trunks[plate].items = items
end)

RegisterServerEvent("inventory:server:combineItem")
AddEventHandler('inventory:server:combineItem', function(item, fromItem, toItem)
	local src = source
	local ply = MRP_SERVER.getSpawnedCharacter(src)
	AddItem(ply, item, 1)
	RemoveItem(ply, fromItem, 1)
	RemoveItem(ply, toItem, 1)
end)

RegisterServerEvent("inventory:server:CraftItems")
AddEventHandler('inventory:server:CraftItems', function(itemName, itemCosts, amount, toSlot, points)
	local src = source
	local Player = MRP_SERVER.getSpawnedCharacter(src)
	local amount = tonumber(amount)
	if itemName ~= nil and itemCosts ~= nil then
		for k, v in pairs(itemCosts) do
			RemoveItem(Player, k, (v*amount))
		end
		AddItem(Player, itemName, amount, toSlot)
		--Player.Functions.SetMetaData("craftingrep", Player.PlayerData.metadata["craftingrep"]+(points*amount))
        --TODO XP
		TriggerClientEvent("inventory:client:UpdatePlayerInventory", src, false)
	end
end)

RegisterServerEvent("inventory:server:AddItem")
AddEventHandler('inventory:server:AddItem', function(itemName, amount, slot, info)
	local src = source
	local Player = MRP_SERVER.getSpawnedCharacter(src)
	local amount = tonumber(amount)
	if itemName ~= nil then
		AddItem(Player, itemName, amount, toSlot)
		TriggerClientEvent("inventory:client:UpdatePlayerInventory", src, false)
	end
end)

RegisterServerEvent("inventory:server:RemoveItem")
AddEventHandler('inventory:server:RemoveItem', function(itemName, amount, slot, info)
	local src = source
	local Player = MRP_SERVER.getSpawnedCharacter(src)
	local amount = tonumber(amount)
	if itemName ~= nil then
		RemoveItem(Player, itemName, amount, toSlot)
		TriggerClientEvent("inventory:client:UpdatePlayerInventory", src, false)
	end
end)

RegisterServerEvent('inventory:server:CraftAttachment')
AddEventHandler('inventory:server:CraftAttachment', function(itemName, itemCosts, amount, toSlot, points)
	local src = source
	local Player = MRP_SERVER.getSpawnedCharacter(src)
	local amount = tonumber(amount)
	if itemName ~= nil and itemCosts ~= nil then
		for k, v in pairs(itemCosts) do
			RemoveItem(Player, k, (v*amount))
		end
		AddItem(Player, itemName, amount, toSlot)
		--Player.Functions.SetMetaData("attachmentcraftingrep", Player.PlayerData.metadata["attachmentcraftingrep"]+(points*amount))
        --TODO XP
		TriggerClientEvent("inventory:client:UpdatePlayerInventory", src, false)
	end
end)

RegisterServerEvent("inventory:server:SetIsOpenState")
AddEventHandler('inventory:server:SetIsOpenState', function(IsOpen, type, id)
	if not IsOpen then
		if type == "stash" then
			Stashes[id].isOpen = false
		elseif type == "trunk" then
			Trunks[id].isOpen = false
		elseif type == "glovebox" then
			Gloveboxes[id].isOpen = false
		end
	end
end)

RegisterServerEvent("inventory:server:OpenInventory")
AddEventHandler('inventory:server:OpenInventory', function(name, id, other)
	local src = source
	--local ply = Player(src)
	local Player = MRP_SERVER.getSpawnedCharacter(src)
	local PlayerAmmo = {}
	--if not ply.state.inv_busy then
        MRP_SERVER.read('inventory', {
            owner = Player._id
        }, function(inventory)
            local ammo = {0}
            if inventory ~= nil then
                ammo = inventory.ammo
            else
                inventory = {
                    items = {}
                }
            end
            
			if ammo[1] ~= nil then
				PlayerAmmo = ammo[1]
			end

			if name ~= nil and id ~= nil then
				local secondInv = {}
				if name == "stash" then
					if Stashes[id] ~= nil then
						if Stashes[id].isOpen then
							local Target = MRP_SERVER.getSpawnedCharacter(Stashes[id].isOpen)
							if Target ~= nil then
								TriggerClientEvent('inventory:client:CheckOpenState', Stashes[id].isOpen, name, id, Stashes[id].label)
							else
								Stashes[id].isOpen = false
							end
						end
					end
					local maxweight = 1000000
					local slots = 50
					if other ~= nil then 
						maxweight = other.maxweight ~= nil and other.maxweight or 1000000
						slots = other.slots ~= nil and other.slots or 50
					end
					secondInv.name = "stash-"..id
					secondInv.label = "Stash-"..id
					secondInv.maxweight = maxweight
					secondInv.inventory = {}
					secondInv.slots = slots
					if Stashes[id] ~= nil and Stashes[id].isOpen then
						secondInv.name = "none-inv"
						secondInv.label = "Stash-None"
						secondInv.maxweight = 1000000
						secondInv.inventory = {}
						secondInv.slots = 0
					else
						local stashItems = GetStashItems(id)
						if next(stashItems) ~= nil then
							secondInv.inventory = stashItems
							Stashes[id] = {}
							Stashes[id].items = stashItems
							Stashes[id].isOpen = src
							Stashes[id].label = secondInv.label
						else
							Stashes[id] = {}
							Stashes[id].items = {}
							Stashes[id].isOpen = src
							Stashes[id].label = secondInv.label
						end
					end
				elseif name == "trunk" then
					if Trunks[id] ~= nil then
						if Trunks[id].isOpen then
							local Target = MRP_SERVER.getSpawnedCharacter(Trunks[id].isOpen)
							if Target ~= nil then
								TriggerClientEvent('inventory:client:CheckOpenState', Trunks[id].isOpen, name, id, Trunks[id].label)
							else
								Trunks[id].isOpen = false
							end
						end
					end
					secondInv.name = "trunk-"..id
					secondInv.label = "Trunk-"..id
					secondInv.maxweight = other.maxweight ~= nil and other.maxweight or 60000
					secondInv.inventory = {}
					secondInv.slots = other.slots ~= nil and other.slots or 50
					--if (Trunks[id] ~= nil and Trunks[id].isOpen) or (SplitStr(id, "PLZI")[2] ~= nil and Player.PlayerData.job.name ~= "police") then
                    --TODO JOB
                    if (Trunks[id] ~= nil and Trunks[id].isOpen) or (MRPShared.SplitStr(id, "PLZI")[2] ~= nil) then
						secondInv.name = "none-inv"
						secondInv.label = "Trunk-None"
						secondInv.maxweight = other.maxweight ~= nil and other.maxweight or 60000
						secondInv.inventory = {}
						secondInv.slots = 0
					else
						if id ~= nil then 
							local ownedItems = GetOwnedVehicleItems(id)
							if IsVehicleOwned(src, id) and next(ownedItems) ~= nil then
								secondInv.inventory = ownedItems
								Trunks[id] = {}
								Trunks[id].items = ownedItems
								Trunks[id].isOpen = src
								Trunks[id].label = secondInv.label
							elseif Trunks[id] ~= nil and not Trunks[id].isOpen then
								secondInv.inventory = Trunks[id].items
								Trunks[id].isOpen = src
								Trunks[id].label = secondInv.label
							else
								Trunks[id] = {}
								Trunks[id].items = {}
								Trunks[id].isOpen = src
								Trunks[id].label = secondInv.label
							end
						end
					end
				elseif name == "glovebox" then
					if Gloveboxes[id] ~= nil then
						if Gloveboxes[id].isOpen then
							local Target = MRP_SERVER.getSpawnedCharacter(Gloveboxes[id].isOpen)
							if Target ~= nil then
								TriggerClientEvent('inventory:client:CheckOpenState', Gloveboxes[id].isOpen, name, id, Gloveboxes[id].label)
							else
								Gloveboxes[id].isOpen = false
							end
						end
					end
					secondInv.name = "glovebox-"..id
					secondInv.label = "Glovebox-"..id
					secondInv.maxweight = 10000
					secondInv.inventory = {}
					secondInv.slots = 5
					if Gloveboxes[id] ~= nil and Gloveboxes[id].isOpen then
						secondInv.name = "none-inv"
						secondInv.label = "Glovebox-None"
						secondInv.maxweight = 10000
						secondInv.inventory = {}
						secondInv.slots = 0
					else
						local ownedItems = GetOwnedVehicleGloveboxItems(id)
						if Gloveboxes[id] ~= nil and not Gloveboxes[id].isOpen then
							secondInv.inventory = Gloveboxes[id].items
							Gloveboxes[id].isOpen = src
							Gloveboxes[id].label = secondInv.label
						elseif IsVehicleOwned(src, id) and next(ownedItems) ~= nil then
							secondInv.inventory = ownedItems
							Gloveboxes[id] = {}
							Gloveboxes[id].items = ownedItems
							Gloveboxes[id].isOpen = src
							Gloveboxes[id].label = secondInv.label
						else
							Gloveboxes[id] = {}
							Gloveboxes[id].items = {}
							Gloveboxes[id].isOpen = src
							Gloveboxes[id].label = secondInv.label
						end
					end
				elseif name == "shop" then
					secondInv.name = "itemshop-"..id
					secondInv.label = other.label
					secondInv.maxweight = 900000
					secondInv.inventory = SetupShopItems(id, other.items)
					ShopItems[id] = {}
					ShopItems[id].items = other.items
					secondInv.slots = #other.items
				elseif name == "traphouse" then
					secondInv.name = "traphouse-"..id
					secondInv.label = other.label
					secondInv.maxweight = 900000
					secondInv.inventory = other.items
					secondInv.slots = other.slots
				elseif name == "crafting" then
					secondInv.name = "crafting"
					secondInv.label = other.label
					secondInv.maxweight = 900000
					secondInv.inventory = other.items
					secondInv.slots = #other.items
				elseif name == "attachment_crafting" then
					secondInv.name = "attachment_crafting"
					secondInv.label = other.label
					secondInv.maxweight = 0
					secondInv.inventory = other.items
					secondInv.slots = #other.items
				elseif name == "otherplayer" then
					local OtherPlayer = MRP_SERVER.getSpawnedCharacter(tonumber(id))
					if OtherPlayer ~= nil then
						secondInv.name = "otherplayer-"..id
						secondInv.label = "Player-"..id
						secondInv.maxweight = Config.MaxWeight
						secondInv.inventory = OtherPlayer.PlayerData.items --TODO
                        --TODO JOB
						--[[if Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty then
							secondInv.slots = QBCore.Config.Player.MaxInvSlots
						else]]--
							secondInv.slots = MaxInventorySlots - 1
						--end
						Citizen.Wait(250)
					end
				else
					if Drops[id] ~= nil and not Drops[id].isOpen then
						secondInv.name = id
						secondInv.label = "Ground-"..tostring(id)
						secondInv.maxweight = 500000
						secondInv.inventory = Drops[id].items
						secondInv.slots = 30
						Drops[id].isOpen = src
						Drops[id].label = secondInv.label
					else
						secondInv.name = "none-inv"
						secondInv.label = "ERROR"
						secondInv.maxweight = 0
						secondInv.inventory = {}
						secondInv.slots = 0
						--Drops[id].label = secondInv.label
					end
				end
				TriggerClientEvent("inventory:client:OpenInventory", src, PlayerAmmo, inventory.items, secondInv)
			else
				TriggerClientEvent("inventory:client:OpenInventory", src, PlayerAmmo, inventory.items)
			end
		end)
    --[[else
    	TriggerClientEvent('QBCore:Notify', src, 'Not Accessible', 'error')
    end ]]--	
end)

RegisterServerEvent("inventory:server:SaveInventory")
AddEventHandler('inventory:server:SaveInventory', function(type, id)
	if type == "trunk" then
		if (IsVehicleOwned(source, id)) then
			SaveOwnedVehicleItems(id, Trunks[id].items)
		else
			Trunks[id].isOpen = false
		end
	elseif type == "glovebox" then
		if (IsVehicleOwned(source, id)) then
			SaveOwnedGloveboxItems(id, Gloveboxes[id].items)
		else
			Gloveboxes[id].isOpen = false
		end
	elseif type == "stash" then
		SaveStashItems(id, Stashes[id].items)
	elseif type == "drop" then
		if Drops[id] ~= nil then
			Drops[id].isOpen = false
			if Drops[id].items == nil or next(Drops[id].items) == nil then
				Drops[id] = nil
				TriggerClientEvent("inventory:client:RemoveDropItem", -1, id)
			end
		end
	end
end)

RegisterServerEvent("inventory:server:getInventory")
AddEventHandler('inventory:server:getInventory', function(query, uuid)
    local src = source
    MRP_SERVER.read('inventory', query, function(inventory)
        TriggerClientEvent("inventory:server:getInventory:response", src, inventory, uuid)
    end)
end)

RegisterServerEvent("inventory:server:UseItemSlot")
AddEventHandler('inventory:server:UseItemSlot', function(slot)
	local src = source
	local Player = MRP_SERVER.getSpawnedCharacter(src)
	GetItemBySlot(Player, slot, function(itemData)
        if itemData ~= nil then
    		local itemInfo = MRPShared.Items(itemData.name)
    		if itemData.type == "weapon" then
    			if itemData.info.quality ~= nil then
    				if itemData.info.quality > 0 then
    					TriggerClientEvent("inventory:client:UseWeapon", src, itemData, true)
    				else
    					TriggerClientEvent("inventory:client:UseWeapon", src, itemData, false)
    				end
    			else
    				TriggerClientEvent("inventory:client:UseWeapon", src, itemData, true)
    			end
    			TriggerClientEvent('inventory:client:ItemBox', src, itemInfo, "use")
    		elseif itemData.useable then
    			TriggerClientEvent("QBCore:Client:UseItem", src, itemData)
    			TriggerClientEvent('inventory:client:ItemBox', src, itemInfo, "use")
    		end
    	end
    end)
end)

RegisterServerEvent("inventory:server:UseItem")
AddEventHandler('inventory:server:UseItem', function(inventory, item)
	local src = source
	local Player = MRP_SERVER.getSpawnedCharacter(src)
	if inventory == "player" or inventory == "hotbar" then
        GetItemBySlot(Player, item.slot, function(itemData)
            if itemData ~= nil then
                --TODO use items in MRP
    			TriggerClientEvent("QBCore:Client:UseItem", src, itemData)
    		end
        end)
	end
end)

RegisterServerEvent("inventory:server:SetInventoryData")
AddEventHandler('inventory:server:SetInventoryData', function(fromInventory, toInventory, fromSlot, toSlot, fromAmount, toAmount)
	local src = source
	local Player = MRP_SERVER.getSpawnedCharacter(src)
	local fromSlot = tonumber(fromSlot)
	local toSlot = tonumber(toSlot)

	if (fromInventory == "player" or fromInventory == "hotbar") and (MRPShared.SplitStr(toInventory, "-")[1] == "itemshop" or toInventory == "crafting") then
		return
	end

	if fromInventory == "player" or fromInventory == "hotbar" then
		GetItemBySlot(Player, fromSlot, function(fromItemData)
            local fromAmount = tonumber(fromAmount) ~= nil and tonumber(fromAmount) or fromItemData.amount
    		if fromItemData ~= nil and fromItemData.amount >= fromAmount then
    			if toInventory == "player" or toInventory == "hotbar" then
                    GetItemBySlot(Player, toSlot, function(toItemData)
                        RemoveItem(Player, fromItemData.name, fromAmount, fromSlot)
        				TriggerClientEvent("inventory:client:CheckWeapon", src, fromItemData.name)
        				--Player.PlayerData.items[toSlot] = fromItemData
        				if toItemData ~= nil then
        					--Player.PlayerData.items[fromSlot] = toItemData
        					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
        					if toItemData.name ~= fromItemData.name then
        						RemoveItem(Player, toItemData.name, toAmount, toSlot)
        						AddItem(Player, toItemData.name, toAmount, fromSlot, toItemData.info)
        					end
        				else
        					--Player.PlayerData.items[fromSlot] = nil
        				end
        				AddItem(Player, fromItemData.name, fromAmount, toSlot, fromItemData.info)
                    end)
    			elseif MRPShared.SplitStr(toInventory, "-")[1] == "otherplayer" then
    				local playerId = tonumber(MRPShared.SplitStr(toInventory, "-")[2])
    				local OtherPlayer = MRP_SERVER.getSpawnedCharacter(playerId)
                    GetItemBySlot(OtherPlayer, toSlot, function(toItemData)
                        RemoveItem(Player, fromItemData.name, fromAmount, fromSlot)
        				TriggerClientEvent("inventory:client:CheckWeapon", src, fromItemData.name)
        				--Player.PlayerData.items[toSlot] = fromItemData
        				if toItemData ~= nil then
        					--Player.PlayerData.items[fromSlot] = toItemData
        					local itemInfo = MRPShared.Items(toItemData.name:lower())
        					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
        					if toItemData.name ~= fromItemData.name then
        						RemoveItem(OtherPlayer, itemInfo["name"], toAmount, fromSlot)
        						AddItem(Player, toItemData.name, toAmount, fromSlot, toItemData.info)
                                --TODO robbing log
        						--TriggerEvent("qb-log:server:CreateLog", "robbing", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | *"..src.."*) swapped item; name: **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** with name: **" .. fromItemData.name .. "**, amount: **" .. fromAmount.. "** with player: **".. GetPlayerName(OtherPlayer.PlayerData.source) .. "** (citizenid: *"..OtherPlayer.PlayerData.citizenid.."* | id: *"..OtherPlayer.PlayerData.source.."*)")
        					end
        				else
        					local itemInfo = MRPShared.Items(fromItemData.name:lower())
                            --TODO robbing log
        					--TriggerEvent("qb-log:server:CreateLog", "robbing", "Dropped Item", "red", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | *"..src.."*) dropped new item; name: **"..itemInfo["name"].."**, amount: **" .. fromAmount .. "** to player: **".. GetPlayerName(OtherPlayer.PlayerData.source) .. "** (citizenid: *"..OtherPlayer.PlayerData.citizenid.."* | id: *"..OtherPlayer.PlayerData.source.."*)")
        				end
        				local itemInfo = MRPShared.Items(fromItemData.name:lower())
        				AddItem(OtherPlayer, itemInfo["name"], fromAmount, toSlot, fromItemData.info)
                    end)
    			elseif MRPShared.SplitStr(toInventory, "-")[1] == "trunk" then
    				local plate = MRPShared.SplitStr(toInventory, "-")[2]
    				local toItemData = Trunks[plate].items[toSlot]
    				RemoveItem(Player, fromItemData.name, fromAmount, fromSlot)
    				TriggerClientEvent("inventory:client:CheckWeapon", src, fromItemData.name)
    				--Player.PlayerData.items[toSlot] = fromItemData
    				if toItemData ~= nil then
    					--Player.PlayerData.items[fromSlot] = toItemData
    					local itemInfo = MRPShared.Items(toItemData.name:lower())
    					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
    					if toItemData.name ~= fromItemData.name then
    						RemoveFromTrunk(plate, fromSlot, itemInfo["name"], toAmount)
    						AddItem(Player, toItemData.name, toAmount, fromSlot, toItemData.info)
    						--TriggerEvent("qb-log:server:CreateLog", "trunk", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** with name: **" .. fromItemData.name .. "**, amount: **" .. fromAmount .. "** - plate: *" .. plate .. "*")
    					end
    				else
    					local itemInfo = MRPShared.Items(fromItemData.name:lower())
    					--TriggerEvent("qb-log:server:CreateLog", "trunk", "Dropped Item", "red", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) dropped new item; name: **"..itemInfo["name"].."**, amount: **" .. fromAmount .. "** - plate: *" .. plate .. "*")
    				end
    				local itemInfo = MRPShared.Items(fromItemData.name:lower())
    				AddToTrunk(plate, toSlot, fromSlot, itemInfo["name"], fromAmount, fromItemData.info)
    			elseif MRPShared.SplitStr(toInventory, "-")[1] == "glovebox" then
    				local plate = MRPShared.SplitStr(toInventory, "-")[2]
    				local toItemData = Gloveboxes[plate].items[toSlot]
    				RemoveItem(Player, fromItemData.name, fromAmount, fromSlot)
    				TriggerClientEvent("inventory:client:CheckWeapon", src, fromItemData.name)
    				--Player.PlayerData.items[toSlot] = fromItemData
    				if toItemData ~= nil then
    					--Player.PlayerData.items[fromSlot] = toItemData
    					local itemInfo = MRPShared.Items(toItemData.name:lower())
    					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
    					if toItemData.name ~= fromItemData.name then
    						RemoveFromGlovebox(plate, fromSlot, itemInfo["name"], toAmount)
    						AddItem(Player, toItemData.name, toAmount, fromSlot, toItemData.info)
    						--TriggerEvent("qb-log:server:CreateLog", "glovebox", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** with name: **" .. fromItemData.name .. "**, amount: **" .. fromAmount .. "** - plate: *" .. plate .. "*")
    					end
    				else
    					local itemInfo = MRPShared.Items(fromItemData.name:lower())
    					--TriggerEvent("qb-log:server:CreateLog", "glovebox", "Dropped Item", "red", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) dropped new item; name: **"..itemInfo["name"].."**, amount: **" .. fromAmount .. "** - plate: *" .. plate .. "*")
    				end
    				local itemInfo = MRPShared.Items(fromItemData.name:lower())
    				AddToGlovebox(plate, toSlot, fromSlot, itemInfo["name"], fromAmount, fromItemData.info)
    			elseif MRPShared.SplitStr(toInventory, "-")[1] == "stash" then
    				local stashId = MRPShared.SplitStr(toInventory, "-")[2]
    				local toItemData = Stashes[stashId].items[toSlot]
    				RemoveItem(Player, fromItemData.name, fromAmount, fromSlot)
    				TriggerClientEvent("inventory:client:CheckWeapon", src, fromItemData.name)
    				--Player.PlayerData.items[toSlot] = fromItemData
    				if toItemData ~= nil then
    					--Player.PlayerData.items[fromSlot] = toItemData
    					local itemInfo = MRPShared.Items(toItemData.name:lower())
    					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
    					if toItemData.name ~= fromItemData.name then
    						--RemoveFromStash(stashId, fromSlot, itemInfo["name"], toAmount)
    						RemoveFromStash(stashId, toSlot, itemInfo["name"], toAmount)
    						AddItem(Player, toItemData.name, toAmount, fromSlot, toItemData.info)
    						--TriggerEvent("qb-log:server:CreateLog", "stash", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** with name: **" .. fromItemData.name .. "**, amount: **" .. fromAmount .. "** - stash: *" .. stashId .. "*")
    					end
    				else
    					local itemInfo = MRPShared.Items(fromItemData.name:lower())
    					TriggerEvent("qb-log:server:CreateLog", "stash", "Dropped Item", "red", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) dropped new item; name: **"..itemInfo["name"].."**, amount: **" .. fromAmount .. "** - stash: *" .. stashId .. "*")
    				end
    				local itemInfo = MRPShared.Items(fromItemData.name:lower())
    				AddToStash(stashId, toSlot, fromSlot, itemInfo["name"], fromAmount, fromItemData.info)
    			--[[elseif MRPShared.SplitStr(toInventory, "-")[1] == "traphouse" then
    				-- Traphouse
    				local traphouseId = MRPShared.SplitStr(toInventory, "-")[2]
    				local toItemData = exports['qb-traphouse']:GetInventoryData(traphouseId, toSlot)
    				local IsItemValid = exports['qb-traphouse']:CanItemBeSaled(fromItemData.name:lower())
    				if IsItemValid then
    					Player.Functions.RemoveItem(fromItemData.name, fromAmount, fromSlot)
    					TriggerClientEvent("inventory:client:CheckWeapon", src, fromItemData.name)
    					if toItemData ~= nil then
    						local itemInfo = MRPShared.Items(toItemData.name:lower())
    						local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
    						if toItemData.name ~= fromItemData.name then
    							exports['qb-traphouse']:RemoveHouseItem(traphouseId, fromSlot, itemInfo["name"], toAmount)
    							Player.Functions.AddItem(toItemData.name, toAmount, fromSlot, toItemData.info)
    							TriggerEvent("qb-log:server:CreateLog", "traphouse", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** with name: **" .. fromItemData.name .. "**, amount: **" .. fromAmount .. "** - traphouse: *" .. traphouseId .. "*")
    						end
    					else
    						local itemInfo = MRPShared.Items(fromItemData.name:lower())
    						TriggerEvent("qb-log:server:CreateLog", "traphouse", "Dropped Item", "red", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) dropped new item; name: **"..itemInfo["name"].."**, amount: **" .. fromAmount .. "** - traphouse: *" .. traphouseId .. "*")
    					end
    					local itemInfo = MRPShared.Items(fromItemData.name:lower())
    					exports['qb-traphouse']:AddHouseItem(traphouseId, toSlot, itemInfo["name"], fromAmount, fromItemData.info, src)
    				else
    					TriggerClientEvent('QBCore:Notify', src, "You can\'t sell this item..", 'error')
    				end]]--
    			else
    				-- drop
    				toInventory = tonumber(toInventory)
    				if toInventory == nil or toInventory == 0 then
    					CreateNewDrop(src, fromSlot, toSlot, fromAmount)
    				else
    					local toItemData = Drops[toInventory].items[toSlot]
    					RemoveItem(Player, fromItemData.name, fromAmount, fromSlot)
    					TriggerClientEvent("inventory:client:CheckWeapon", src, fromItemData.name)
    					if toItemData ~= nil then
    						local itemInfo = MRPShared.Items(toItemData.name:lower())
    						local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
    						if toItemData.name ~= fromItemData.name then
    							AddItem(Player, toItemData.name, toAmount, fromSlot, toItemData.info)
    							RemoveFromDrop(toInventory, fromSlot, itemInfo["name"], toAmount)
    							--TriggerEvent("qb-log:server:CreateLog", "drop", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** with name: **" .. fromItemData.name .. "**, amount: **" .. fromAmount .. "** - dropid: *" .. toInventory .. "*")
    						end
    					else
    						local itemInfo = MRPShared.Items(fromItemData.name:lower())
    						--TriggerEvent("qb-log:server:CreateLog", "drop", "Dropped Item", "red", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) dropped new item; name: **"..itemInfo["name"].."**, amount: **" .. fromAmount .. "** - dropid: *" .. toInventory .. "*")
    					end
    					local itemInfo = MRPShared.Items(fromItemData.name:lower())
    					AddToDrop(toInventory, toSlot, itemInfo["name"], fromAmount, fromItemData.info)
    					--[[if itemInfo["name"] == "radio" then
    						TriggerClientEvent('qb-radio:onRadioDrop', src)
    					end]]--
    				end
    			end
    		else
                TriggerClientEvent('chat:addMessage', src, {
                    template = '<div class="chat-message nonemergency">{0}</div>',
                    args = {"You don't have this item!"}
                })
    		end
        end)
	elseif MRPShared.SplitStr(fromInventory, "-")[1] == "otherplayer" then
		local playerId = tonumber(MRPShared.SplitStr(fromInventory, "-")[2])
		local OtherPlayer = MRP_SERVER.getSpawnedCharacter(playerId)
        GetItemBySlot(OtherPlayer, fromSlot, function(fromItemData)
    		local fromAmount = tonumber(fromAmount) ~= nil and tonumber(fromAmount) or fromItemData.amount
    		if fromItemData ~= nil and fromItemData.amount >= fromAmount then
    			local itemInfo = MRPShared.Items(fromItemData.name:lower())
    			if toInventory == "player" or toInventory == "hotbar" then
                    GetItemBySlot(Player, toSlot, function(toItemData)
                        RemoveItem(OtherPlayer, itemInfo["name"], fromAmount, fromSlot)
        				TriggerClientEvent("inventory:client:CheckWeapon", OtherPlayer.PlayerData.source, fromItemData.name)
        				if toItemData ~= nil then
        					local itemInfo = MRPShared.Items(toItemData.name:lower())
        					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
        					if toItemData.name ~= fromItemData.name then
        						RemoveItem(Player, toItemData.name, toAmount, toSlot)
        						AddItem(OtherPlayer, itemInfo["name"], toAmount, fromSlot, toItemData.info)
        						--TriggerEvent("qb-log:server:CreateLog", "robbing", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** with item; **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** from player: **".. GetPlayerName(OtherPlayer.PlayerData.source) .. "** (citizenid: *"..OtherPlayer.PlayerData.citizenid.."* | *"..OtherPlayer.PlayerData.source.."*)")
        					end
        				--[[else
        					TriggerEvent("qb-log:server:CreateLog", "robbing", "Retrieved Item", "green", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) took item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount .. "** from player: **".. GetPlayerName(OtherPlayer.PlayerData.source) .. "** (citizenid: *"..OtherPlayer.PlayerData.citizenid.."* | *"..OtherPlayer.PlayerData.source.."*)")]]--
        				end
        				AddItem(Player, fromItemData.name, fromAmount, toSlot, fromItemData.info)
                    end)
    			else
    				local toItemData = OtherPlayer.PlayerData.items[toSlot]
    				RemoveItem(OtherPlayer, itemInfo["name"], fromAmount, fromSlot)
    				--Player.PlayerData.items[toSlot] = fromItemData
    				if toItemData ~= nil then
    					local itemInfo = MRPShared.Items(toItemData.name:lower())
    					--Player.PlayerData.items[fromSlot] = toItemData
    					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
    					if toItemData.name ~= fromItemData.name then
    						local itemInfo = MRPShared.Items(toItemData.name:lower())
    						RemoveItem(OtherPlayer, itemInfo["name"], toAmount, toSlot)
    						AddItem(OtherPlayer, itemInfo["name"], toAmount, fromSlot, toItemData.info)
    					end
    				else
    					--Player.PlayerData.items[fromSlot] = nil
    				end
    				local itemInfo = MRPShared.Items(fromItemData.name:lower())
    				AddItem(OtherPlayer, itemInfo["name"], fromAmount, toSlot, fromItemData.info)
    			end
    		else
                TriggerClientEvent('chat:addMessage', src, {
                    template = '<div class="chat-message nonemergency">{0}</div>',
                    args = {"Item doesn\'t exist??"}
                })
    		end
        end)
	elseif MRPShared.SplitStr(fromInventory, "-")[1] == "trunk" then
		local plate = MRPShared.SplitStr(fromInventory, "-")[2]
		local fromItemData = Trunks[plate].items[fromSlot]
		local fromAmount = tonumber(fromAmount) ~= nil and tonumber(fromAmount) or fromItemData.amount
		if fromItemData ~= nil and fromItemData.amount >= fromAmount then
			local itemInfo = MRPShared.Items(fromItemData.name:lower())
			if toInventory == "player" or toInventory == "hotbar" then
                GetItemBySlot(Player, toSlot, function(toItemData)
    				RemoveFromTrunk(plate, fromSlot, itemInfo["name"], fromAmount)
    				if toItemData ~= nil then
    					local itemInfo = MRPShared.Items(toItemData.name:lower())
    					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
    					if toItemData.name ~= fromItemData.name then
    						RemoveItem(Player, toItemData.name, toAmount, toSlot)
    						AddToTrunk(plate, fromSlot, toSlot, itemInfo["name"], toAmount, toItemData.info)
    						--TriggerEvent("qb-log:server:CreateLog", "trunk", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** with item; name: **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** plate: *" .. plate .. "*")
    					--else
    						--TriggerEvent("qb-log:server:CreateLog", "trunk", "Stacked Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) stacked item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** from plate: *" .. plate .. "*")
    					end
    				--else
    					--TriggerEvent("qb-log:server:CreateLog", "trunk", "Received Item", "green", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) reveived item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount.. "** plate: *" .. plate .. "*")
    				end
    				AddItem(Player, fromItemData.name, fromAmount, toSlot, fromItemData.info)
                end)
			else
				local toItemData = Trunks[plate].items[toSlot]
				RemoveFromTrunk(plate, fromSlot, itemInfo["name"], fromAmount)
				--Player.PlayerData.items[toSlot] = fromItemData
				if toItemData ~= nil then
					local itemInfo = MRPShared.Items(toItemData.name:lower())
					--Player.PlayerData.items[fromSlot] = toItemData
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						local itemInfo = MRPShared.Items(toItemData.name:lower())
						RemoveFromTrunk(plate, toSlot, itemInfo["name"], toAmount)
						AddToTrunk(plate, fromSlot, toSlot, itemInfo["name"], toAmount, toItemData.info)
					end
				else
					--Player.PlayerData.items[fromSlot] = nil
				end
				local itemInfo = MRPShared.Items(fromItemData.name:lower())
				AddToTrunk(plate, toSlot, fromSlot, itemInfo["name"], fromAmount, fromItemData.info)
			end
		else
            TriggerClientEvent('chat:addMessage', src, {
                template = '<div class="chat-message nonemergency">{0}</div>',
                args = {"Item doesn\'t exist??"}
            })
		end
	elseif MRPShared.SplitStr(fromInventory, "-")[1] == "glovebox" then
		local plate = MRPShared.SplitStr(fromInventory, "-")[2]
		local fromItemData = Gloveboxes[plate].items[fromSlot]
		local fromAmount = tonumber(fromAmount) ~= nil and tonumber(fromAmount) or fromItemData.amount
		if fromItemData ~= nil and fromItemData.amount >= fromAmount then
			local itemInfo = MRPShared.Items(fromItemData.name:lower())
			if toInventory == "player" or toInventory == "hotbar" then
                GetItemBySlot(Player, toSlot, function(toItemData)
                    RemoveFromGlovebox(plate, fromSlot, itemInfo["name"], fromAmount)
    				if toItemData ~= nil then
    					local itemInfo = MRPShared.Items(toItemData.name:lower())
    					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
    					if toItemData.name ~= fromItemData.name then
    						RemoveItem(Player, toItemData.name, toAmount, toSlot)
    						AddToGlovebox(plate, fromSlot, toSlot, itemInfo["name"], toAmount, toItemData.info)
    						--TriggerEvent("qb-log:server:CreateLog", "glovebox", "Swapped", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src..")* swapped item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** with item; name: **"..itemInfo["name"].."**, amount: **" .. toAmount .. "** plate: *" .. plate .. "*")
    					--else
    						--TriggerEvent("qb-log:server:CreateLog", "glovebox", "Stacked Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) stacked item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** from plate: *" .. plate .. "*")
    					end
    				--else
    					--TriggerEvent("qb-log:server:CreateLog", "glovebox", "Received Item", "green", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) reveived item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount.. "** plate: *" .. plate .. "*")
    				end
    				AddItem(Player, fromItemData.name, fromAmount, toSlot, fromItemData.info)
                end)
			else
				local toItemData = Gloveboxes[plate].items[toSlot]
				RemoveFromGlovebox(plate, fromSlot, itemInfo["name"], fromAmount)
				--Player.PlayerData.items[toSlot] = fromItemData
				if toItemData ~= nil then
					local itemInfo = MRPShared.Items(toItemData.name:lower())
					--Player.PlayerData.items[fromSlot] = toItemData
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						local itemInfo = MRPShared.Items(toItemData.name:lower())
						RemoveFromGlovebox(plate, toSlot, itemInfo["name"], toAmount)
						AddToGlovebox(plate, fromSlot, toSlot, itemInfo["name"], toAmount, toItemData.info)
					end
				else
					--Player.PlayerData.items[fromSlot] = nil
				end
				local itemInfo = MRPShared.Items(fromItemData.name:lower())
				AddToGlovebox(plate, toSlot, fromSlot, itemInfo["name"], fromAmount, fromItemData.info)
			end
		else
            TriggerClientEvent('chat:addMessage', src, {
                template = '<div class="chat-message nonemergency">{0}</div>',
                args = {"Item doesn\'t exist??"}
            })
		end
	elseif MRPShared.SplitStr(fromInventory, "-")[1] == "stash" then
		local stashId = MRPShared.SplitStr(fromInventory, "-")[2]
		local fromItemData = Stashes[stashId].items[fromSlot]
		local fromAmount = tonumber(fromAmount) ~= nil and tonumber(fromAmount) or fromItemData.amount
		if fromItemData ~= nil and fromItemData.amount >= fromAmount then
			local itemInfo = MRPShared.Items(fromItemData.name:lower())
			if toInventory == "player" or toInventory == "hotbar" then
				GetItemBySlot(Player, toSlot, function(toItemData)
                    RemoveFromStash(stashId, fromSlot, itemInfo["name"], fromAmount)
    				if toItemData ~= nil then
    					local itemInfo = MRPShared.Items(toItemData.name:lower())
    					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
    					if toItemData.name ~= fromItemData.name then
    						RemoveItem(Player, toItemData.name, toAmount, toSlot)
    						AddToStash(stashId, fromSlot, toSlot, itemInfo["name"], toAmount, toItemData.info)
    						TriggerEvent("qb-log:server:CreateLog", "stash", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** with item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount .. "** stash: *" .. stashId .. "*")
    					--else
    						--TriggerEvent("qb-log:server:CreateLog", "stash", "Stacked Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) stacked item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** from stash: *" .. stashId .. "*")
    					end
    				--else
    					--TriggerEvent("qb-log:server:CreateLog", "stash", "Received Item", "green", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) reveived item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount.. "** stash: *" .. stashId .. "*")
    				end
    				SaveStashItems(stashId, Stashes[stashId].items)
    				AddItem(Player, fromItemData.name, fromAmount, toSlot, fromItemData.info)
                end)
			else
				local toItemData = Stashes[stashId].items[toSlot]
				RemoveFromStash(stashId, fromSlot, itemInfo["name"], fromAmount)
				--Player.PlayerData.items[toSlot] = fromItemData
				if toItemData ~= nil then
					local itemInfo = MRPShared.Items(toItemData.name:lower())
					--Player.PlayerData.items[fromSlot] = toItemData
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						local itemInfo = MRPShared.Items(toItemData.name:lower())
						RemoveFromStash(stashId, toSlot, itemInfo["name"], toAmount)
						AddToStash(stashId, fromSlot, toSlot, itemInfo["name"], toAmount, toItemData.info)
					end
				else
					--Player.PlayerData.items[fromSlot] = nil
				end
				local itemInfo = MRPShared.Items(fromItemData.name:lower())
				AddToStash(stashId, toSlot, fromSlot, itemInfo["name"], fromAmount, fromItemData.info)
			end
		else
            TriggerClientEvent('chat:addMessage', src, {
                template = '<div class="chat-message nonemergency">{0}</div>',
                args = {"Item doesn\'t exist??"}
            })
		end
	--[[elseif MRPShared.SplitStr(fromInventory, "-")[1] == "traphouse" then
		local traphouseId = MRPShared.SplitStr(fromInventory, "-")[2]
		local fromItemData = exports['qb-traphouse']:GetInventoryData(traphouseId, fromSlot)
		local fromAmount = tonumber(fromAmount) ~= nil and tonumber(fromAmount) or fromItemData.amount
		if fromItemData ~= nil and fromItemData.amount >= fromAmount then
			local itemInfo = MRPShared.Items(fromItemData.name:lower())
			if toInventory == "player" or toInventory == "hotbar" then
				local toItemData = Player.Functions.GetItemBySlot(toSlot)
				exports['qb-traphouse']:RemoveHouseItem(traphouseId, fromSlot, itemInfo["name"], fromAmount)
				if toItemData ~= nil then
					local itemInfo = MRPShared.Items(toItemData.name:lower())
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						Player.Functions.RemoveItem(toItemData.name, toAmount, toSlot)
						exports['qb-traphouse']:AddHouseItem(traphouseId, fromSlot, itemInfo["name"], toAmount, toItemData.info, src)
						TriggerEvent("qb-log:server:CreateLog", "stash", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** with item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount .. "** stash: *" .. traphouseId .. "*")
					else
						TriggerEvent("qb-log:server:CreateLog", "stash", "Stacked Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) stacked item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** from stash: *" .. traphouseId .. "*")
					end
				else
					TriggerEvent("qb-log:server:CreateLog", "stash", "Received Item", "green", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) reveived item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount.. "** stash: *" .. traphouseId .. "*")
				end
				Player.Functions.AddItem(fromItemData.name, fromAmount, toSlot, fromItemData.info)
			else
				local toItemData = exports['qb-traphouse']:GetInventoryData(traphouseId, toSlot)
				exports['qb-traphouse']:RemoveHouseItem(traphouseId, fromSlot, itemInfo["name"], fromAmount)
				if toItemData ~= nil then
					local itemInfo = MRPShared.Items(toItemData.name:lower())
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						local itemInfo = MRPShared.Items(toItemData.name:lower())
						exports['qb-traphouse']:RemoveHouseItem(traphouseId, toSlot, itemInfo["name"], toAmount)
						exports['qb-traphouse']:AddHouseItem(traphouseId, fromSlot, itemInfo["name"], toAmount, toItemData.info, src)
					end
				end
				local itemInfo = MRPShared.Items(fromItemData.name:lower())
				exports['qb-traphouse']:AddHouseItem(traphouseId, toSlot, itemInfo["name"], fromAmount, fromItemData.info, src)
			end
		else
			TriggerClientEvent("QBCore:Notify", src, "Item doesn't exist??", "error")
		end]]--
	elseif MRPShared.SplitStr(fromInventory, "-")[1] == "itemshop" then
		local shopType = MRPShared.SplitStr(fromInventory, "-")[2]
		local itemData = ShopItems[shopType].items[fromSlot]
		local itemInfo = MRPShared.Items(itemData.name:lower())
		local bankBalance = Player.stats.cash
		local price = tonumber((itemData.price*fromAmount))

		if MRPShared.SplitStr(shopType, "_")[1] == "Dealer" then
			if MRPShared.SplitStr(itemData.name, "_")[1] == "weapon" then
				price = tonumber(itemData.price)
                if bankBalance >= price then
                    TriggerEvent('mrp:bankin:server:pay:cash', src, price)
					itemData.info.serie = tostring(Config.RandomInt(2) .. Config.RandomStr(3) .. Config.RandomInt(1) .. Config.RandomStr(2) .. Config.RandomInt(3) .. Config.RandomStr(4))
					AddItem(Player, itemData.name, 1, toSlot, itemData.info)
					--TriggerClientEvent('qb-drugs:client:updateDealerItems', src, itemData, 1)
                    TriggerClientEvent('chat:addMessage', src, {
                        template = '<div class="chat-message nonemergency">{0}</div>',
                        args = {itemInfo["label"] .. " bought!"}
                    })
					--TriggerEvent("qb-log:server:CreateLog", "dealers", "Dealer item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)
				else
                    TriggerClientEvent('chat:addMessage', src, {
                        template = '<div class="chat-message nonemergency">{0}</div>',
                        args = {"You don\'t have enough cash.. you poor"}
                    })
				end
			else
				if bankBalance >= price then
                    TriggerEvent('mrp:bankin:server:pay:cash', src, price)
					AddItem(Player, itemData.name, fromAmount, toSlot, itemData.info)
					--TriggerClientEvent('qb-drugs:client:updateDealerItems', src, itemData, fromAmount)
                    TriggerClientEvent('chat:addMessage', src, {
                        template = '<div class="chat-message nonemergency">{0}</div>',
                        args = {itemInfo["label"] .. " bought!"}
                    })
					--TriggerEvent("qb-log:server:CreateLog", "dealers", "Dealer item gekocht", "green", "**"..GetPlayerName(src) .. "** heeft een " .. itemInfo["label"] .. " gekocht voor $"..price)
				else
                    TriggerClientEvent('chat:addMessage', src, {
                        template = '<div class="chat-message nonemergency">{0}</div>',
                        args = {"You don\'t have enough cash.. you poor"}
                    })
				end
			end
		elseif MRPShared.SplitStr(shopType, "_")[1] == "Itemshop" then
			if bankBalance >= price then
                TriggerEvent('mrp:bankin:server:pay:cash', src, price)
				AddItem(Player, itemData.name, fromAmount, toSlot, itemData.info)
				--TriggerClientEvent('qb-shops:client:UpdateShop', src, MRPShared.SplitStr(shopType, "_")[2], itemData, fromAmount)
                TriggerClientEvent('chat:addMessage', src, {
                    template = '<div class="chat-message nonemergency">{0}</div>',
                    args = {itemInfo["label"] .. " bought!"}
                })
				--TriggerEvent("qb-log:server:CreateLog", "shops", "Shop item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)

--Uncomment The stuff below if you want it so stuff likes shops will take from your bank account if you dont have enough cash on hand

			--elseif bankBalance >= price then
			--	Player.Functions.RemoveMoney("bank", price, "itemshop-bought-item")
			--	Player.Functions.AddItem(itemData.name, fromAmount, toSlot, itemData.info)
			--	TriggerClientEvent('qb-shops:client:UpdateShop', src, MRPShared.SplitStr(shopType, "_")[2], itemData, fromAmount)
			--	TriggerClientEvent('QBCore:Notify', src, itemInfo["label"] .. " bought!", "success")
			--	TriggerEvent("qb-log:server:CreateLog", "shops", "Shop item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)
			else
                TriggerClientEvent('chat:addMessage', src, {
                    template = '<div class="chat-message nonemergency">{0}</div>',
                    args = {"You don\'t have enough cash.. you poor"}
                })
			end
		else
			if bankBalance >= price then
                TriggerEvent('mrp:bankin:server:pay:cash', src, price)
				AddItem(Player, itemData.name, fromAmount, toSlot, itemData.info)
                TriggerClientEvent('chat:addMessage', src, {
                    template = '<div class="chat-message nonemergency">{0}</div>',
                    args = {itemInfo["label"] .. " bought!"}
                })
				--TriggerEvent("qb-log:server:CreateLog", "shops", "Shop item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)

--Uncomment The stuff below if you want it so stuff likes shops will take from your bank account if you dont have enough cash on hand

			--elseif bankBalance >= price then
			--	Player.Functions.RemoveMoney("bank", price, "unkown-itemshop-bought-item")
			--	Player.Functions.AddItem(itemData.name, fromAmount, toSlot, itemData.info)
			--	TriggerClientEvent('QBCore:Notify', src, itemInfo["label"] .. " bought!", "success")
			--	TriggerEvent("qb-log:server:CreateLog", "shops", "Shop item bought", "green", "**"..GetPlayerName(src) .. "** bought a " .. itemInfo["label"] .. " for $"..price)
			else
                TriggerClientEvent('chat:addMessage', src, {
                    template = '<div class="chat-message nonemergency">{0}</div>',
                    args = {"You don\'t have enough cash.. you poor"}
                })
			end
		end
	elseif fromInventory == "crafting" then
		local itemData = Config.CraftingItems[fromSlot]
		if hasCraftItems(src, itemData.costs, fromAmount) then
			TriggerClientEvent("inventory:client:CraftItems", src, itemData.name, itemData.costs, fromAmount, toSlot, itemData.points)
		else
			TriggerClientEvent("inventory:client:UpdatePlayerInventory", src, true)
            TriggerClientEvent('chat:addMessage', src, {
                template = '<div class="chat-message nonemergency">{0}</div>',
                args = {"You don't have the right items.."}
            })
		end
	elseif fromInventory == "attachment_crafting" then
		local itemData = Config.AttachmentCrafting["items"][fromSlot]
		if hasCraftItems(src, itemData.costs, fromAmount) then
			TriggerClientEvent("inventory:client:CraftAttachment", src, itemData.name, itemData.costs, fromAmount, toSlot, itemData.points)
		else
			TriggerClientEvent("inventory:client:UpdatePlayerInventory", src, true)
            TriggerClientEvent('chat:addMessage', src, {
                template = '<div class="chat-message nonemergency">{0}</div>',
                args = {"You don't have the right items.."}
            })
		end
	else
		-- drop
		fromInventory = tonumber(fromInventory)
		local fromItemData = Drops[fromInventory].items[fromSlot]
		local fromAmount = tonumber(fromAmount) ~= nil and tonumber(fromAmount) or fromItemData.amount
		if fromItemData ~= nil and fromItemData.amount >= fromAmount then
			local itemInfo = MRPShared.Items(fromItemData.name:lower())
			if toInventory == "player" or toInventory == "hotbar" then
				GetItemBySlot(Player, toSlot, function(toItemData)
                    RemoveFromDrop(fromInventory, fromSlot, itemInfo["name"], fromAmount)
    				if toItemData ~= nil then
    					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
    					if toItemData.name ~= fromItemData.name then
    						RemoveItem(Player, toItemData.name, toAmount, toSlot)
    						AddToDrop(fromInventory, toSlot, itemInfo["name"], toAmount, toItemData.info)
    						--[[if itemInfo["name"] == "radio" then
    							TriggerClientEvent('qb-radio:onRadioDrop', src)
    						end
    						TriggerEvent("qb-log:server:CreateLog", "drop", "Swapped Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) swapped item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** with item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount .. "** - dropid: *" .. fromInventory .. "*")]]--
    					--else
    						--TriggerEvent("qb-log:server:CreateLog", "drop", "Stacked Item", "orange", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) stacked item; name: **"..toItemData.name.."**, amount: **" .. toAmount .. "** - from dropid: *" .. fromInventory .. "*")
    					end
    				--else
    					--TriggerEvent("qb-log:server:CreateLog", "drop", "Received Item", "green", "**".. GetPlayerName(src) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..src.."*) reveived item; name: **"..fromItemData.name.."**, amount: **" .. fromAmount.. "** -  dropid: *" .. fromInventory .. "*")
    				end
    				AddItem(Player, fromItemData.name, fromAmount, toSlot, fromItemData.info)
                end)
			else
				toInventory = tonumber(toInventory)
				local toItemData = Drops[toInventory].items[toSlot]
				RemoveFromDrop(fromInventory, fromSlot, itemInfo["name"], fromAmount)
				--Player.PlayerData.items[toSlot] = fromItemData
				if toItemData ~= nil then
					local itemInfo = MRPShared.Items(toItemData.name:lower())
					--Player.PlayerData.items[fromSlot] = toItemData
					local toAmount = tonumber(toAmount) ~= nil and tonumber(toAmount) or toItemData.amount
					if toItemData.name ~= fromItemData.name then
						local itemInfo = MRPShared.Items(toItemData.name:lower())
						RemoveFromDrop(toInventory, toSlot, itemInfo["name"], toAmount)
						AddToDrop(fromInventory, fromSlot, itemInfo["name"], toAmount, toItemData.info)
						--[[if itemInfo["name"] == "radio" then
							TriggerClientEvent('qb-radio:onRadioDrop', src)
						end]]--
					end
				--else
					--Player.PlayerData.items[fromSlot] = nil
				end
				local itemInfo = MRPShared.Items(fromItemData.name:lower())
				AddToDrop(toInventory, toSlot, itemInfo["name"], fromAmount, fromItemData.info)
				--[[if itemInfo["name"] == "radio" then
					TriggerClientEvent('qb-radio:onRadioDrop', src)
				end]]--
			end
		else
            TriggerClientEvent('chat:addMessage', src, {
                template = '<div class="chat-message nonemergency">{0}</div>',
                args = {"Item doesn't exist??"}
            })
		end
	end
end)

function hasCraftItems(source, CostItems, amount)
	local Player = MRP_SERVER.getSpawnedCharacter(source)
	for k, v in pairs(CostItems) do
        local item = GetItemByName(Player, k)
		if item ~= nil then
			if item.amount < (v * amount) then
				return false
			end
		else
			return false
		end
	end
	return true
end

function IsVehicleOwned(src, plate)
	local val = false
    
    local p = promise.new()
    
    plate = MRPShared.Trim(plate)

    local char = MRP_SERVER.getSpawnedCharacter(src)

    local query = {
        plate = plate
    }

    MRP_SERVER.read('vehicle', query, function(vehicle)
        if vehicle ~= nil and MRP_SERVER.isObjectIDEqual(vehicle.owner, char._id) then
            val = true
        end
        p:resolve(true)
    end)
    
    Citizen.Await(p)

	return val
end

local function escape_str(s)
	local in_char  = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
	local out_char = {'\\', '"', '/',  'b',  'f',  'n',  'r',  't'}
	for i, c in ipairs(in_char) do
	  s = s:gsub(c, '\\' .. out_char[i])
	end
	return s
end

-- Shop Items
function SetupShopItems(shop, shopItems)
	local items = {}
	if shopItems ~= nil and next(shopItems) ~= nil then
		for k, item in pairs(shopItems) do
			local itemInfo = MRPShared.Items(item.name:lower())
			items[item.slot] = {
				name = itemInfo["name"],
				amount = tonumber(item.amount),
				info = item.info ~= nil and item.info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				price = item.price,
				image = itemInfo["image"],
				slot = item.slot,
			}
		end
	end
	return items
end

-- Stash Items
function GetStashItems(stashId)
	local items = {}
    
    local p = promise.new()
    
    MRP_SERVER.read('inventory', {owner=stashId}, function(inventory)
        local result = {}
        
        if inventory ~= nil then
            result = inventory.items
        end
        
        if result[1] ~= nil then
			for k, item in pairs(result) do
				local itemInfo = MRPShared.Items(item.name:lower())
				items[item.slot] = {
					name = itemInfo["name"],
					amount = tonumber(item.amount),
					info = json.decode(item.info) ~= nil and json.decode(item.info) or "",
					label = itemInfo["label"],
					description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
					weight = itemInfo["weight"], 
					type = itemInfo["type"], 
					unique = itemInfo["unique"], 
					useable = itemInfo["useable"], 
					image = itemInfo["image"],
					slot = item.slot,
				}
			end
		end
        
        p:resolve(true)
    end)
    
    Citizen.Await(p)
    
	return items
end

function SaveStashItems(stashId, items)
	if Stashes[stashId].label ~= "Stash-None" then
		if items ~= nil then
			for slot, item in pairs(items) do
				item.description = nil
			end
            
            local inventory = {
                owner = stashId,
                items = items
            }
            
            MRP_SERVER.update('inventory', inventory, {owner = stashId}, {upsert=true}, function(res)
                Stashes[stashId].isOpen = false
            end)
		end
	end
end

function AddToStash(stashId, slot, otherslot, itemName, amount, info)
	local amount = tonumber(amount)
	local ItemData = MRPShared.Items(itemName)
	if not ItemData.unique then
		if Stashes[stashId].items[slot] ~= nil and Stashes[stashId].items[slot].name == itemName then
			Stashes[stashId].items[slot].amount = Stashes[stashId].items[slot].amount + amount
		else
			local itemInfo = MRPShared.Items(itemName:lower())
			Stashes[stashId].items[slot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = slot,
			}
		end
	else
		if Stashes[stashId].items[slot] ~= nil and Stashes[stashId].items[slot].name == itemName then
			local itemInfo = MRPShared.Items(itemName:lower())
			Stashes[stashId].items[otherslot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = otherslot,
			}
		else
			local itemInfo = MRPShared.Items(itemName:lower())
			Stashes[stashId].items[slot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = slot,
			}
		end
	end
end

function RemoveFromStash(stashId, slot, itemName, amount)
	local amount = tonumber(amount)
	if Stashes[stashId].items[slot] ~= nil and Stashes[stashId].items[slot].name == itemName then
		if Stashes[stashId].items[slot].amount > amount then
			Stashes[stashId].items[slot].amount = Stashes[stashId].items[slot].amount - amount
		else
			Stashes[stashId].items[slot] = nil
			if next(Stashes[stashId].items) == nil then
				Stashes[stashId].items = {}
			end
		end
	else
		Stashes[stashId].items[slot] = nil
		if Stashes[stashId].items == nil then
			Stashes[stashId].items[slot] = nil
		end
	end
end

-- Trunk items
function GetOwnedVehicleItems(plate)
	local items = {}
    
    plate = MRPShared.Trim(plate)
    
    local p = promise.new()
    
    MRP_SERVER.read('inventory', {owner=plate}, function(inventory)
        local result = {}
        
        if inventory ~= nil then
            result = inventory.items
        end
        
        if result[1] ~= nil then
			for k, item in pairs(result) do
				local itemInfo = MRPShared.Items(item.name:lower())
				items[item.slot] = {
					name = itemInfo["name"],
					amount = tonumber(item.amount),
					info = json.decode(item.info) ~= nil and json.decode(item.info) or "",
					label = itemInfo["label"],
					description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
					weight = itemInfo["weight"], 
					type = itemInfo["type"], 
					unique = itemInfo["unique"], 
					useable = itemInfo["useable"], 
					image = itemInfo["image"],
					slot = item.slot,
				}
			end
		end
        
        p:resolve(true)
    end)
    
    Citizen.Await(p)
    
    if Trunks[plate] == nil then
        Trunks[plate] = {}
    end
    
    Trunks[plate].items = items
	
	return items
end

function SaveOwnedVehicleItems(plate, items)
	if Trunks[plate].label ~= "Trunk-None" then
		if items ~= nil then
			for slot, item in pairs(items) do
				item.description = nil
			end
            
            plate = MRPShared.Trim(plate)
            
            local inventory = {
                owner = plate,
                items = items
            }
            
            MRP_SERVER.update('inventory', inventory, {owner = plate}, {upsert=true}, function(res)
                if Trunks[plate] ~= nil then
                    Trunks[plate].isOpen = false
                end
            end)
		end
	end
end

function AddToTrunk(plate, slot, otherslot, itemName, amount, info)
	local amount = tonumber(amount)
	local ItemData = MRPShared.Items(itemName)

	if not ItemData.unique then
		if Trunks[plate].items[slot] ~= nil and Trunks[plate].items[slot].name == itemName then
			Trunks[plate].items[slot].amount = Trunks[plate].items[slot].amount + amount
		else
			local itemInfo = MRPShared.Items(itemName:lower())
			Trunks[plate].items[slot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = slot,
			}
		end
	else
		if Trunks[plate].items[slot] ~= nil and Trunks[plate].items[slot].name == itemName then
			local itemInfo = MRPShared.Items(itemName:lower())
			Trunks[plate].items[otherslot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = otherslot,
			}
		else
			local itemInfo = MRPShared.Items(itemName:lower())
			Trunks[plate].items[slot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = slot,
			}
		end
	end
end

function RemoveFromTrunk(plate, slot, itemName, amount)
	if Trunks[plate].items[slot] ~= nil and Trunks[plate].items[slot].name == itemName then
		if Trunks[plate].items[slot].amount > amount then
			Trunks[plate].items[slot].amount = Trunks[plate].items[slot].amount - amount
		else
			Trunks[plate].items[slot] = nil
			if next(Trunks[plate].items) == nil then
				Trunks[plate].items = {}
			end
		end
	else
		Trunks[plate].items[slot]= nil
		if Trunks[plate].items == nil then
			Trunks[plate].items[slot] = nil
		end
	end
end

-- Glovebox items
function GetOwnedVehicleGloveboxItems(plate)
	local items = {}
    
    plate = MRPShared.Trim(plate)
    
    local p = promise.new()
    
    MRP_SERVER.read('inventory', {owner=plate.."-GLOVEBOX"}, function(inventory)
        local result = {}
        
        if inventory ~= nil then
            result = inventory.items
        end
        
        if result[1] ~= nil then
            for k, item in pairs(result) do
				local itemInfo = MRPShared.Items(item.name:lower())
				items[item.slot] = {
					name = itemInfo["name"],
					amount = tonumber(item.amount),
					info = json.decode(item.info) ~= nil and json.decode(item.info) or "",
					label = itemInfo["label"],
					description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
					weight = itemInfo["weight"], 
					type = itemInfo["type"], 
					unique = itemInfo["unique"], 
					useable = itemInfo["useable"], 
					image = itemInfo["image"],
					slot = item.slot,
				}
			end
		end
        
        p:resolve(true)
    end)
    
    Citizen.Await(p)
    
    if Gloveboxes[plate] == nil then
        Gloveboxes[plate] = {}
    end
    
    Gloveboxes[plate].items = items
    
	return items
end

function SaveOwnedGloveboxItems(plate, items)
	if Gloveboxes[plate].label ~= "Glovebox-None" then
		if items ~= nil then
			for slot, item in pairs(items) do
				item.description = nil
			end
            
            plate = MRPShared.Trim(plate)
            
            local owner = plate .. "-GLOVEBOX"
            
            local inventory = {
                owner = owner,
                items = items
            }
            
            MRP_SERVER.update('inventory', inventory, {owner = owner}, {upsert=true}, function(res)
                if Gloveboxes[plate] ~= nil then
                    Gloveboxes[plate].isOpen = false
                end
            end)
		end
	end
end

function AddToGlovebox(plate, slot, otherslot, itemName, amount, info)
	local amount = tonumber(amount)
	local ItemData = MRPShared.Items(itemName)

	if not ItemData.unique then
		if Gloveboxes[plate].items[slot] ~= nil and Gloveboxes[plate].items[slot].name == itemName then
			Gloveboxes[plate].items[slot].amount = Gloveboxes[plate].items[slot].amount + amount
		else
			local itemInfo = MRPShared.Items(itemName:lower())
			Gloveboxes[plate].items[slot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = slot,
			}
		end
	else
		if Gloveboxes[plate].items[slot] ~= nil and Gloveboxes[plate].items[slot].name == itemName then
			local itemInfo = MRPShared.Items(itemName:lower())
			Gloveboxes[plate].items[otherslot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = otherslot,
			}
		else
			local itemInfo = MRPShared.Items(itemName:lower())
			Gloveboxes[plate].items[slot] = {
				name = itemInfo["name"],
				amount = amount,
				info = info ~= nil and info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
				weight = itemInfo["weight"], 
				type = itemInfo["type"], 
				unique = itemInfo["unique"], 
				useable = itemInfo["useable"], 
				image = itemInfo["image"],
				slot = slot,
			}
		end
	end
end

function RemoveFromGlovebox(plate, slot, itemName, amount)
	if Gloveboxes[plate].items[slot] ~= nil and Gloveboxes[plate].items[slot].name == itemName then
		if Gloveboxes[plate].items[slot].amount > amount then
			Gloveboxes[plate].items[slot].amount = Gloveboxes[plate].items[slot].amount - amount
		else
			Gloveboxes[plate].items[slot] = nil
			if next(Gloveboxes[plate].items) == nil then
				Gloveboxes[plate].items = {}
			end
		end
	else
		Gloveboxes[plate].items[slot]= nil
		if Gloveboxes[plate].items == nil then
			Gloveboxes[plate].items[slot] = nil
		end
	end
end

-- Drop items
function AddToDrop(dropId, slot, itemName, amount, info)
	local amount = tonumber(amount)
	if Drops[dropId].items[slot] ~= nil and Drops[dropId].items[slot].name == itemName then
		Drops[dropId].items[slot].amount = Drops[dropId].items[slot].amount + amount
	else
		local itemInfo = MRPShared.Items(itemName:lower())
		Drops[dropId].items[slot] = {
			name = itemInfo["name"],
			amount = amount,
			info = info ~= nil and info or "",
			label = itemInfo["label"],
			description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
			weight = itemInfo["weight"], 
			type = itemInfo["type"], 
			unique = itemInfo["unique"], 
			useable = itemInfo["useable"], 
			image = itemInfo["image"],
			slot = slot,
			id = dropId,
		}
	end
end

function RemoveFromDrop(dropId, slot, itemName, amount)
	if Drops[dropId].items[slot] ~= nil and Drops[dropId].items[slot].name == itemName then
		if Drops[dropId].items[slot].amount > amount then
			Drops[dropId].items[slot].amount = Drops[dropId].items[slot].amount - amount
		else
			Drops[dropId].items[slot] = nil
			if next(Drops[dropId].items) == nil then
				Drops[dropId].items = {}
				--TriggerClientEvent("inventory:client:RemoveDropItem", -1, dropId)
			end
		end
	else
		Drops[dropId].items[slot] = nil
		if Drops[dropId].items == nil then
			Drops[dropId].items[slot] = nil
			--TriggerClientEvent("inventory:client:RemoveDropItem", -1, dropId)
		end
	end
end

function CreateDropId()
	if Drops ~= nil then
		local id = math.random(10000, 99999)
		local dropid = id
		while Drops[dropid] ~= nil do
			id = math.random(10000, 99999)
			dropid = id
		end
		return dropid
	else
		local id = math.random(10000, 99999)
		local dropid = id
		return dropid
	end
end

function CreateNewDrop(source, fromSlot, toSlot, itemAmount)
	local Player = MRP_SERVER.getSpawnedCharacter(source)
	GetItemBySlot(Player, fromSlot, function(itemData)
        local coords = GetEntityCoords(GetPlayerPed(source))
    	RemoveItem(Player, itemData.name, itemAmount, itemData.slot)
    	TriggerClientEvent("inventory:client:CheckWeapon", source, itemData.name)
    	local itemInfo = MRPShared.Items(itemData.name:lower())
    	local dropId = CreateDropId()
    	Drops[dropId] = {}
    	Drops[dropId].items = {}
    
    	Drops[dropId].items[toSlot] = {
    		name = itemInfo["name"],
    		amount = itemAmount,
    		info = itemData.info ~= nil and itemData.info or "",
    		label = itemInfo["label"],
    		description = itemInfo["description"] ~= nil and itemInfo["description"] or "",
    		weight = itemInfo["weight"], 
    		type = itemInfo["type"], 
    		unique = itemInfo["unique"], 
    		useable = itemInfo["useable"], 
    		image = itemInfo["image"],
    		slot = toSlot,
    		id = dropId,
    	}
    	--TriggerEvent("qb-log:server:CreateLog", "drop", "New Item Drop", "red", "**".. GetPlayerName(source) .. "** (citizenid: *"..Player.PlayerData.citizenid.."* | id: *"..source.."*) dropped new item; name: **"..itemData.name.."**, amount: **" .. itemAmount .. "**")
    	TriggerClientEvent("inventory:client:DropItemAnim", source)
    	TriggerClientEvent("inventory:client:AddDropItem", -1, dropId, source, coords)
    	--[[if itemData.name:lower() == "radio" then
    		TriggerClientEvent('qb-radio:onRadioDrop', source)
    	end]]--
    end)
end

RegisterCommand('resetinv', function(source, args, rawCommand)
    local invType = args[1]:lower()
	table.remove(args, 1)
	local invId = table.concat(args, " ")
	if invType ~= nil and invId ~= nil then 
		if invType == "trunk" then
			if Trunks[invId] ~= nil then 
				Trunks[invId].isOpen = false
			end
		elseif invType == "glovebox" then
			if Gloveboxes[invId] ~= nil then 
				Gloveboxes[invId].isOpen = false
			end
		elseif invType == "stash" then
			if Stashes[invId] ~= nil then 
				Stashes[invId].isOpen = false
			end
		else
            TriggerClientEvent('chat:addMessage', source, {
                template = '<div class="chat-message nonemergency">{0}</div>',
                args = {"Not a valid type.."}
            })
		end
	else
        TriggerClientEvent('chat:addMessage', source, {
            template = '<div class="chat-message nonemergency">{0}</div>',
            args = {"Args not filled out correctly.."}
        })
	end
end, false) --TODO unrestricted for now

RegisterCommand('trunkpos', function(source, args, rawCommand)
	TriggerClientEvent("inventory:client:ShowTrunkPos", source)
end, false)

RegisterCommand("rob", function(source, args, rawCommand)
	TriggerClientEvent("police:client:RobPlayer", source)
end)

RegisterCommand("giveitem", function(source, args, rawCommand)
	local Player = MRP_SERVER.getSpawnedCharacter(tonumber(args[1]))
	local amount = tonumber(args[3])
	local itemData = MRPShared.Items(tostring(args[2]):lower())
	if Player ~= nil then
		if amount > 0 then
			if itemData ~= nil then
				-- check iteminfo
				local info = {}
				if itemData["name"] == "id_card" then
					info.citizenid = Player.stateId
					info.firstname = Player.name
					info.lastname = Player.surname
					--info.birthdate = Player.birthday
					info.gender = Player.sex
				elseif itemData["type"] == "weapon" then
					amount = 1
					info.serie = tostring(Config.RandomInt(2) .. Config.RandomStr(3) .. Config.RandomInt(1) .. Config.RandomStr(2) .. Config.RandomInt(3) .. Config.RandomStr(4))
				elseif itemData["name"] == "harness" then
					info.uses = 20
				elseif itemData["name"] == "markedbills" then
					info.worth = math.random(5000, 10000)
				--elseif itemData["name"] == "labkey" then
					--info.lab = exports["qb-methlab"]:GenerateRandomLab()
				elseif itemData["name"] == "printerdocument" then
					info.url = "https://cdn.discordapp.com/attachments/645995539208470549/707609551733522482/image0.png"
				end

                AddItem(Player, itemData["name"], amount, false, info)
                TriggerClientEvent('chat:addMessage', source, {
                    template = '<div class="chat-message nonemergency">{0}</div>',
                    args = {"You Have Given " ..GetPlayerName(tonumber(args[1])).." "..amount.." "..itemData["name"].. ""}
                })
			else
                TriggerClientEvent('chat:addMessage', source, {
                    template = '<div class="chat-message nonemergency">{0}</div>',
                    args = {"Item Does Not Exist"}
                })
			end
		else
            TriggerClientEvent('chat:addMessage', source, {
                template = '<div class="chat-message nonemergency">{0}</div>',
                args = {"Invalid Amount"}
            })
		end
	else
        TriggerClientEvent('chat:addMessage', source, {
            template = '<div class="chat-message nonemergency">{0}</div>',
            args = {"Invalid Player ID"}
        })
	end
end, false) --TODO unrestricted for now

RegisterCommand("randomitems", function(source, args, rawCommand)
	local Player = MRP_SERVER.getSpawnedCharacter(source)
	local filteredItems = {}
	for k, v in pairs(MRPShared.Items) do
		if MRPShared.Items(k)["type"] ~= "weapon" then
			table.insert(filteredItems, v)
		end
	end
	for i = 1, 10, 1 do
		local randitem = filteredItems[math.random(1, #filteredItems)]
		local amount = math.random(1, 10)
		if randitem["unique"] then
			amount = 1
		end
		AddItem(Player, randitem["name"], amount)
		TriggerClientEvent('inventory:client:ItemBox', source, MRPShared.Items(randitem["name"]), 'add')
        Citizen.Wait(500)
	end
end, false) --TODO unrestricted for now

-- TODO useables
--[[QBCore.Functions.CreateUseableItem("snowball", function(source, item)
	local Player = QBCore.Functions.GetPlayer(source)
	local itemData = Player.Functions.GetItemBySlot(item.slot)
	if Player.Functions.GetItemBySlot(item.slot) ~= nil then
        TriggerClientEvent("inventory:client:UseSnowball", source, itemData.amount)
    end
end)

QBCore.Functions.CreateUseableItem("driver_license", function(source, item)
	for k, v in pairs(QBCore.Functions.GetPlayers()) do
		local character = QBCore.Functions.GetPlayer(source)
		local PlayerPed = GetPlayerPed(source)
		local TargetPed = GetPlayerPed(v)
		local dist = #(GetEntityCoords(PlayerPed) - GetEntityCoords(TargetPed))
		if dist < 3.0 then
			TriggerClientEvent('chat:addMessage', v,  {
				template = '<div class="chat-message advert"><div class="chat-message-body"><strong>{0}:</strong><br><br> <strong>First Name:</strong> {1} <br><strong>Last Name:</strong> {2} <br><strong>Birth Date:</strong> {3} <br><strong>Licenses:</strong> {4}</div></div>',
				args = {'Drivers License', character.PlayerData.charinfo.firstname, character.PlayerData.charinfo.lastname, character.PlayerData.charinfo.birthdate, character.PlayerData.charinfo.type}
			})
		end
	end
end)

QBCore.Functions.CreateUseableItem("id_card", function(source, item)
	for k, v in pairs(QBCore.Functions.GetPlayers()) do
		local character = QBCore.Functions.GetPlayer(source)
		local PlayerPed = GetPlayerPed(source)
		local TargetPed = GetPlayerPed(v)
		local dist = #(GetEntityCoords(PlayerPed) - GetEntityCoords(TargetPed))
		if dist < 3.0 then
			TriggerClientEvent('chat:addMessage', v,  {
				template = '<div class="chat-message advert"><div class="chat-message-body"><strong>{0}:</strong><br><br> <strong>Civ ID:</strong> {1} <br><strong>First Name:</strong> {2} <br><strong>Last Name:</strong> {3} <br><strong>Birthdate:</strong> {4} <br><strong>Gender:</strong> {5} <br><strong>Nationality:</strong> {6}</div></div>',
				args = {'ID Card', character.PlayerData.citizenid, character.PlayerData.charinfo.firstname, character.PlayerData.charinfo.lastname, character.PlayerData.charinfo.birthdate, character.PlayerData.charinfo.gender, character.PlayerData.charinfo.nationality}
			})
		end
	end
end)]]--