local VORPcore = exports.vorp_core:GetCore()
local KnownBackpacks = {}

local function trackBackpack(id)
    if not id then return end
    KnownBackpacks[tostring(id)] = true
end

local function extractIds(src)
    local steamId, discordId = 'unbekannt', 'unbekannt'
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:find('steam:') == 1 then
            steamId = id
        elseif id:find('discord:') == 1 then
            discordId = id
        end
    end
    return steamId, discordId
end

local function getPlayerName(src)
    local user = VORPcore.getUser(src)
    local char = user and user.getUsedCharacter or nil
    local firstname = char and char.firstname or 'Unbekannt'
    local lastname = char and char.lastname or ''
    return (firstname .. ' ' .. lastname):gsub('%s+$', '')
end

local function buildLog(action, who, steamId, discordId, extraLines)
    local lines = {
        '🎯 **Aktion:** ' .. action,
        '👤 **Spieler:** **' .. who .. '**',
        '🌐 **Steam:** `' .. steamId .. '`',
        '💬 **Discord:** `' .. discordId .. '`',
    }
    if extraLines then
        for _, l in ipairs(extraLines) do
            lines[#lines + 1] = l
        end
    end
    lines[#lines + 1] = '🕒 **Zeit:** ' .. os.date('%Y-%m-%d %H:%M:%S')
    return table.concat(lines, '\n')
end

local function sendWebhook(msg, colorOverride)
    if not Config.WebHook then return end
    if not Config.WHLink or Config.WHLink == '' then return end
    VORPcore.AddWebhook(
        Config.WHTitle or 'Rucksack Log',
        Config.WHLink,
        msg,
        colorOverride or Config.WHColor or 16711680,
        Config.WHName or 'Rucksack',
        Config.WHLogo,
        Config.WHFooterLogo,
        Config.WHAvatar
    )
end

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
        trackBackpack(BackpackID)
        local who = getPlayerName(src)
        local steamId, discordId = extractIds(src)
        sendWebhook(buildLog('Rucksack erstellt (klein)', who, steamId, discordId, {
            '🎒 **ID:** `' .. BackpackID .. '`',
            '📦 **Modell:** ' .. Config.SmallModel,
            '📏 **Limit:** ' .. Config.SmallInventory
        }), 65280)
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
        trackBackpack(BackpackID)
        local who = getPlayerName(src)
        local steamId, discordId = extractIds(src)
        sendWebhook(buildLog('Rucksack erstellt (groß)', who, steamId, discordId, {
            '🎒 **ID:** `' .. BackpackID .. '`',
            '📦 **Modell:** ' .. Config.BigModel,
            '📏 **Limit:** ' .. Config.BigInventory
        }), 65280)
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
            trackBackpack(DataBackpackID)
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

AddEventHandler('vorp_inventory:Server:OnItemMovedToCustomInventory', function(item, invId, src)
    if not invId or not item then return end
    if not KnownBackpacks[tostring(invId)] then return end
    local who = getPlayerName(src)
    local steamId, discordId = extractIds(src)
    local amount = item.amount or item.count or 0
    local name = item.name or item.label or 'Unbekanntes Item'
    sendWebhook(buildLog('legt Item in Rucksack', who, steamId, discordId, {
        '📦 **Item:** **' .. name .. '** x' .. amount,
        '🎒 **Rucksack:** `' .. invId .. '`'
    }), 65280)
end)

AddEventHandler('vorp_inventory:Server:OnItemTakenFromCustomInventory', function(item, invId, src)
    if not invId or not item then return end
    if not KnownBackpacks[tostring(invId)] then return end
    local who = getPlayerName(src)
    local steamId, discordId = extractIds(src)
    local amount = item.amount or item.count or 0
    local name = item.name or item.label or 'Unbekanntes Item'
    sendWebhook(buildLog('nimmt Item aus Rucksack', who, steamId, discordId, {
        '📦 **Item:** **' .. name .. '** x' .. amount,
        '🎒 **Rucksack:** `' .. invId .. '`'
    }), 16711680)
end)

AddEventHandler('vorp_inventory:Server:OnItemRemoved', function(data, source)
    if not data then return end
    local itemName = data.name or data.item
    if itemName ~= Config.BackpackItem then return end
    local who = getPlayerName(source)
    local steamId, discordId = extractIds(source)
    local amount = data.count or data.amount or 0
    local backpackId = (data.metadata and (data.metadata.backpackid or data.metadata.id)) or 'unbekannt'
    sendWebhook(buildLog('Rucksack weggeworfen/entfernt', who, steamId, discordId, {
        '🎒 **ID:** `' .. backpackId .. '`',
        '📦 **Anzahl:** x' .. amount
    }), 16753920)
end)

AddEventHandler('vorp_inventory:Server:OnItemCreated', function(data, source)
    if not data then return end
    local itemName = data.name or data.item
    if itemName ~= Config.BackpackItem then return end
    local who = getPlayerName(source)
    local steamId, discordId = extractIds(source)
    local amount = data.count or data.amount or 0
    local backpackId = (data.metadata and (data.metadata.backpackid or data.metadata.id)) or 'unbekannt'
    trackBackpack(backpackId)
    sendWebhook(buildLog('Rucksack aufgehoben/erhalten', who, steamId, discordId, {
        '🎒 **ID:** `' .. backpackId .. '`',
        '📦 **Anzahl:** x' .. amount
    }), 255)
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
