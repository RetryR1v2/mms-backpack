local VORPcore = exports.vorp_core:GetCore()

-----------------------------------------------------------------------
-- version checker
-----------------------------------------------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'

    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/RetryR1v2/mms-backpack/main/version.txt', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')

        if not text then 
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return 
        end

      
        if text == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('Current Version: %s'):format(currentVersion))
            versionCheckPrint('success', ('Latest Version: %s'):format(text))
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(text))
        end
    end)
end



exports.vorp_inventory:registerUsableItem(Config.BuyBackpackSmall, function(data)
    local src = data.source
    local CanCarry = exports.vorp_inventory:canCarryItem(src, Config.BackpackItem, 1)
    if CanCarry then
        local BackpackID = GetUniqueID()
        Wait(1000)
        MySQL.insert('INSERT INTO `mms_backpack` (backpackid,backpackmodel,inventorylimit) VALUES (?,?,?)',
        {BackpackID,Config.SmallModel,Config.SmallInventory}, function()end)
        exports.vorp_inventory:subItem(src, Config.BuyBackpackSmall, 1, {})
        exports.vorp_inventory:addItem(src, Config.BackpackItem, 1, { description = _U('BackPackID') .. BackpackID, backpackid =  BackpackID })
    end
end)

exports.vorp_inventory:registerUsableItem(Config.BuyBackpackBig, function(data)
    local src = data.source
    local CanCarry = exports.vorp_inventory:canCarryItem(src, Config.BackpackItem, 1)
    if CanCarry then
        local BackpackID = GetUniqueID()
        Wait(1000)
        MySQL.insert('INSERT INTO `mms_backpack` (backpackid,backpackmodel,inventorylimit) VALUES (?,?,?)',
        {BackpackID,Config.BigModel,Config.BigInventory}, function()end)
        exports.vorp_inventory:subItem(src, Config.BuyBackpackBig, 1, {})
        exports.vorp_inventory:addItem(src, Config.BackpackItem, 1, { description = _U('BackPackID') .. BackpackID, backpackid = BackpackID })
    end
end)

exports.vorp_inventory:registerUsableItem(Config.BackpackItem, function(data)
    local src = data.source
    local Character = VORPcore.getUser(src).getUsedCharacter
    local BackPack = exports.vorp_inventory:getItem(src, Config.BackpackItem)
    local BackPackMeta =  BackPack['metadata']
    local BackpackID = BackPackMeta.backpackid
    local result = MySQL.query.await("SELECT * FROM mms_backpack WHERE backpackid=@backpackid", { ["backpackid"] = BackpackID})
        if #result > 0 then
            local BackpackLimit = result[1].inventorylimit
            local DataBackpackID = result[1].backpackid
            local isregistred = exports.vorp_inventory:isCustomInventoryRegistered(DataBackpackID)
            if isregistred then
                exports.vorp_inventory:closeInventory(src, DataBackpackId)
                exports.vorp_inventory:openInventory(src, DataBackpackID)
            else
                exports.vorp_inventory:registerInventory(
                {
                    id = DataBackpackID,
                    name = Config.BackpackName,
                    limit = BackpackLimit,
                    acceptWeapons = true,
                    shared = true,
                    ignoreItemStackLimit = true,
                })
                exports.vorp_inventory:openInventory(src, DataBackpackID)
                isregistred = exports.vorp_inventory:isCustomInventoryRegistered(DataBackpackID)
            end
        else
            VORPcore.NotifyRightTip(src, _U('NoDatabaseFound'), 4000)
        end
end)

function GetUniqueID()
    local FoundUnique = false
    while not FoundUnique do
        Wait(50)
        local RandomID = math.random(11111,999999)
        local BackpackID = math.random(11111,999999)
        local result = MySQL.query.await("SELECT * FROM mms_backpack WHERE backpackid=@backpackid", { ["backpackid"] = BackpackID})
        if #result > 0 then
            FoundUnique = false
        else
            FoundUnique = true
        end
        if FoundUnique then
            return BackpackID
        end
    end
end

RegisterServerEvent('mms-backpack:server:CheckBackpack',function()
    local src = source
    local HasBackpack = exports.vorp_inventory:getItemCount(src, nil, Config.BackpackItem,nil)
    if HasBackpack > 0 then
        local BackPack = exports.vorp_inventory:getItem(src, Config.BackpackItem)
        local BackPackMeta =  BackPack['metadata']
        local BackpackID = BackPackMeta.backpackid
        local result = MySQL.query.await("SELECT * FROM mms_backpack WHERE backpackid=@backpackid", { ["backpackid"] = BackpackID})
            if #result > 0 then
                local BackpackModel = result[1].backpackmodel
                TriggerClientEvent('mms-backpack:client:HasBackpack',src,BackpackModel)
            else
                VORPcore.NotifyRightTip(src, _U('NoDatabaseFound'), 4000)
            end
    elseif HasBackpack <= 0 then
        TriggerClientEvent('mms-backpack:client:HasNoBackpack',src)
    end
end)

--------------------------------------------------------------------------------------------------
-- start version check
--------------------------------------------------------------------------------------------------
CheckVersion()