local ESX = exports['es_extended']:getSharedObject()

local cooldowns = {}
local activeActions = {}

local function getTime()
    return os.time()
end

local function getPlayer(source)
    return ESX.GetPlayerFromId(source)
end

local function getZone(zoneType, zoneId)
    if not Config.Zones[zoneType] then
        return nil
    end

    return Config.Zones[zoneType][zoneId]
end

local function distance(coords, zoneCoords)
    local dx = coords.x - zoneCoords.x
    local dy = coords.y - zoneCoords.y
    local dz = coords.z - zoneCoords.z

    return math.sqrt(
        dx * dx +
        dy * dy +
        dz * dz
    )
end

local function isNearZone(coords, zone)
    if not zone or not zone.coords then
        return false
    end

    return distance(coords, zone.coords) <=
        (zone.radius + Config.Validation.maxDistance)
end

local function getCooldown(source, action)
    cooldowns[source] = cooldowns[source] or {}

    return cooldowns[source][action] or 0
end

local function setCooldown(source, action, seconds)
    cooldowns[source] = cooldowns[source] or {}

    cooldowns[source][action] =
        getTime() + seconds
end

local function getRemainingCooldown(source, action)
    local cooldown = getCooldown(source, action)

    if cooldown <= getTime() then
        return 0
    end

    return cooldown - getTime()
end

local function notify(source, message, type)
    TriggerClientEvent(
        'realrp_drugs:client:notify',
        source,
        message,
        type
    )
end

local function getItemCount(source, item)
    if not item then
        return 0
    end

    local count = exports.ox_inventory:Search(
        source,
        'count',
        item
    )

    return tonumber(count) or 0
end

local function canCarry(source, item, amount)
    if not item or amount <= 0 then
        return false
    end

    return exports.ox_inventory:CanCarryItem(
        source,
        item,
        amount
    )
end

local function addItem(source, item, amount)
    if not canCarry(source, item, amount) then
        return false
    end

    local success = exports.ox_inventory:AddItem(
        source,
        item,
        amount
    )

    return success == true
end

local function removeItem(source, item, amount)
    if getItemCount(source, item) < amount then
        return false
    end

    local success = exports.ox_inventory:RemoveItem(
        source,
        item,
        amount
    )

    return success == true
end

local function getPoliceCount()
    local count = 0

    for _, playerId in ipairs(ESX.GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(playerId)

        if xPlayer and xPlayer.job then
            if xPlayer.job.name == Config.Police.job then
                count = count + 1
            end
        end
    end

    return count
end

local function policeAlert(coords)
    if math.random(1, 100) > Config.Police.alertChance then
        return
    end

    for _, playerId in ipairs(ESX.GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(playerId)

        if xPlayer and xPlayer.job then
            if xPlayer.job.name == Config.Police.job then

                TriggerClientEvent(
                    'realrp_drugs:client:policeAlert',
                    playerId,
                    {
                        coords = coords,
                        message = Config.Text.policeAlert
                    }
                )
            end
        end
    end
end

local function isValidAction(action)
    return action == 'gather'
        or action == 'process'
        or action == 'package'
        or action == 'sell'
end

ESX.RegisterServerCallback(
    'realrp_drugs:canStart',
    function(source, cb, action, zoneType, zoneId, coords)

        if not isValidAction(action) then
            cb(false, 'Neteisingas veiksmas.')
            return
        end

        if activeActions[source] then
            cb(false, 'Jau atliekate veiksmą.')
            return
        end

        local zone = getZone(
            zoneType,
            zoneId
        )

        if not zone then
            cb(false, 'Neteisinga zona.')
            return
        end

        if not coords then
            cb(false, 'Nepavyko nustatyti jūsų pozicijos.')
            return
        end

        if not isNearZone(coords, zone) then
            cb(false, Config.Text.tooFar)
            return
        end

        local cooldown = getRemainingCooldown(
            source,
            action
        )

        if cooldown > 0 then
            cb(
                false,
                Config.Text.cooldown:format(cooldown)
            )
            return
        end

        if action == 'process' then
            local required =
                Config.Process.requiredAmount

            if getItemCount(
                source,
                Config.Items.raw
            ) < required then

                cb(
                    false,
                    Config.Text.notEnoughItems
                )

                return
            end

        elseif action == 'package' then
            local required =
                Config.Package.requiredAmount

            if getItemCount(
                source,
                Config.Items.processed
            ) < required then

                cb(
                    false,
                    Config.Text.notEnoughItems
                )

                return
            end

        elseif action == 'sell' then
            local requiredItem =
                Config.Items.packaged

            if getItemCount(
                source,
                requiredItem
            ) < 1 then

                cb(
                    false,
                    Config.Text.notEnoughItems
                )

                return
            end

            local police =
                getPoliceCount()

            if police <
                Config.Sell.minCopsOnline then

                cb(
                    false,
                    'Nepakanka policijos pareigūnų.'
                )

                return
            end
        end

        activeActions[source] = true

        cb(true)
    end
)

RegisterNetEvent(
    'realrp_drugs:completeAction',
    function(
        action,
        zoneType,
        zoneId,
        coords
    )

        local source = source

        if not activeActions[source] then
            return
        end

        activeActions[source] = nil

        if not isValidAction(action) then
            return
        end

        local zone = getZone(
            zoneType,
            zoneId
        )

        if not zone or not coords then
            return
        end

        if not isNearZone(
            coords,
            zone
        ) then

            notify(
                source,
                Config.Text.tooFar,
                'error'
            )

            return
        end

        local cooldown =
            getRemainingCooldown(
                source,
                action
            )

        if cooldown > 0 then
            return
        end

        if action == 'gather' then

            local amount = math.random(
                Config.Collect.minAmount,
                Config.Collect.maxAmount
            )

            if not canCarry(
                source,
                Config.Items.raw,
                amount
            ) then

                notify(
                    source,
                    Config.Text.inventoryFull,
                    'error'
                )

                return
            end

            if addItem(
                source,
                Config.Items.raw,
                amount
            ) then

                setCooldown(
                    source,
                    action,
                    Config.Collect.cooldown
                )

                notify(
                    source,
                    ('Gavote %s zaliavos.'):format(amount),
                    'success'
                )

                policeAlert(coords)
            end

        elseif action == 'process' then

            local required =
                Config.Process.requiredAmount

            if not removeItem(
                source,
                Config.Items.raw,
                required
            ) then

                notify(
                    source,
                    Config.Text.notEnoughItems,
                    'error'
                )

                return
            end

            local amount = math.random(
                Config.Process.outputMin,
                Config.Process.outputMax
            )

            if not addItem(
                source,
                Config.Items.processed,
                amount
            ) then

                addItem(
                    source,
                    Config.Items.raw,
                    required
                )

                notify(
                    source,
                    Config.Text.inventoryFull,
                    'error'
                )

                return
            end

            setCooldown(
                source,
                action,
                Config.Process.cooldown
            )

            notify(
                source,
                ('Gavote %s perdirbto produkto.'):format(amount),
                'success'
            )

            policeAlert(coords)

        elseif action == 'package' then

            local required =
                Config.Package.requiredAmount

            if not removeItem(
                source,
                Config.Items.processed,
                required
            ) then

                notify(
                    source,
                    Config.Text.notEnoughItems,
                    'error'
                )

                return
            end

            local amount =
                Config.Package.outputAmount

            if not addItem(
                source,
                Config.Items.packaged,
                amount
            ) then

                addItem(
                    source,
                    Config.Items.processed,
                    required
                )

                notify(
                    source,
                    Config.Text.inventoryFull,
                    'error'
                )

                return
            end

            setCooldown(
                source,
                action,
                Config.Package.cooldown
            )

            notify(
                source,
                ('Supakavote %s produkto.'):format(amount),
                'success'
            )

            policeAlert(coords)

        elseif action == 'sell' then

            local item =
                Config.Items.packaged

            if not removeItem(
                source,
                item,
                1
            ) then

                notify(
                    source,
                    Config.Text.notEnoughItems,
                    'error'
                )

                return
            end

            local price = math.random(
                Config.Sell.priceMin,
                Config.Sell.priceMax
            )

            local xPlayer =
                getPlayer(source)

            if not xPlayer then
                return
            end

            xPlayer.addAccountMoney(
                'money',
                price
            )

            setCooldown(
                source,
                action,
                Config.Sell.cooldown
            )

            notify(
                source,
                Config.Text.sold:format(price),
                'success'
            )

            policeAlert(coords)
        end
    end
)

RegisterNetEvent(
    'realrp_drugs:actionCancelled',
    function(action)
        local source = source

        activeActions[source] = nil
    end
)

AddEventHandler(
    'playerDropped',
    function()
        local source = source

        cooldowns[source] = nil
        activeActions[source] = nil
    end
)