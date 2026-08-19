local ESX = exports['es_extended']:getSharedObject()

local isBusy = false
local targets = {}

local function notify(message, type)
    lib.notify({
        description = message,
        type = type or 'inform'
    })
end

local function getZone(zoneType, zoneId)
    if not Config.Zones[zoneType] then
        return nil
    end

    return Config.Zones[zoneType][zoneId]
end

local function playAnimation(animation)
    if not animation then
        return
    end

    lib.requestAnimDict(animation.dict)

    TaskPlayAnim(
        PlayerPedId(),
        animation.dict,
        animation.clip,
        8.0,
        -8.0,
        -1,
        49,
        0.0,
        false,
        false,
        false
    )
end

local function stopAnimation(animation)
    if not animation then
        return
    end

    StopAnimTask(
        PlayerPedId(),
        animation.dict,
        animation.clip,
        1.0
    )
end

local function startAction(action, zoneType, zoneId)
    if isBusy then
        notify(Config.Text.alreadyDoing, 'error')
        return
    end

    local zone = getZone(zoneType, zoneId)

    if not zone then
        notify('Neteisinga zona.', 'error')
        return
    end

    isBusy = true

    ESX.TriggerServerCallback(
        'realrp_drugs:canStart',
        function(allowed, message)
            if not allowed then
                isBusy = false
                notify(message or 'Veiksmo atlikti negalima.', 'error')
                return
            end

            local duration
            local label
            local animation

            if action == 'gather' then
                duration = Config.Collect.duration
                label = Config.Text.gathering
                animation = Config.Animations.gather

            elseif action == 'process' then
                duration = Config.Process.duration
                label = Config.Text.processing
                animation = Config.Animations.process

            elseif action == 'package' then
                duration = Config.Package.duration
                label = Config.Text.packaging
                animation = Config.Animations.package

            elseif action == 'sell' then
                duration = Config.Sell.duration
                label = Config.Text.selling
                animation = Config.Animations.sell

            else
                isBusy = false
                notify('Neteisingas veiksmas.', 'error')
                return
            end

            playAnimation(animation)

            local completed = lib.progressBar({
                duration = duration,
                label = label,
                useWhileDead = false,
                canCancel = true,
                disable = {
                    move = true,
                    car = true,
                    combat = true
                }
            })

            stopAnimation(animation)

            if completed then
                local coords = GetEntityCoords(PlayerPedId())

                TriggerServerEvent(
                    'realrp_drugs:completeAction',
                    action,
                    zoneType,
                    zoneId,
                    {
                        x = coords.x,
                        y = coords.y,
                        z = coords.z
                    }
                )
            else
                TriggerServerEvent(
                    'realrp_drugs:actionCancelled',
                    action
                )

                notify(Config.Text.cancelled, 'error')
            end

            isBusy = false
        end,
        action,
        zoneType,
        zoneId,
        {
            x = GetEntityCoords(PlayerPedId()).x,
            y = GetEntityCoords(PlayerPedId()).y,
            z = GetEntityCoords(PlayerPedId()).z
        }
    )
end

local function createTarget(zoneType, zoneId, zone, action, icon, label)
    local targetName = ('realrp_drugs_%s_%s_%s'):format(
        zoneType,
        zoneId,
        action
    )

    local targetId = exports.ox_target:addSphereZone({
        coords = zone.coords,
        radius = zone.radius,
        debug = Config.Debug,

        options = {
            {
                name = targetName,
                icon = icon,
                label = label,

                onSelect = function()
                    startAction(
                        action,
                        zoneType,
                        zoneId
                    )
                end
            }
        }
    })

    targets[#targets + 1] = targetId
end

local function createTargets()
    for id, zone in ipairs(Config.Zones.gather) do
        createTarget(
            'gather',
            id,
            zone,
            'gather',
            'fas fa-seedling',
            zone.label
        )
    end

    for id, zone in ipairs(Config.Zones.process) do
        createTarget(
            'process',
            id,
            zone,
            'process',
            'fas fa-flask',
            zone.label
        )
    end

    for id, zone in ipairs(Config.Zones.package) do
        createTarget(
            'package',
            id,
            zone,
            'package',
            'fas fa-box',
            zone.label
        )
    end

    for id, zone in ipairs(Config.Zones.sell) do
        createTarget(
            'sell',
            id,
            zone,
            'sell',
            'fas fa-hand-holding-dollar',
            zone.label
        )
    end
end

RegisterNetEvent(
    'realrp_drugs:client:notify',
    function(message, type)
        notify(message, type)
    end
)

RegisterNetEvent(
    'realrp_drugs:client:policeAlert',
    function(data)
        if not data or not data.coords then
            return
        end

        notify(
            data.message or Config.Text.policeAlert,
            'warning'
        )

        local blip = AddBlipForRadius(
            data.coords.x,
            data.coords.y,
            data.coords.z,
            100.0
        )

        SetBlipColour(blip, Config.Police.blip.color)
        SetBlipAlpha(blip, 120)

        CreateThread(function()
            Wait(Config.Police.blip.duration * 1000)

            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end)
    end
)

CreateThread(function()
    while not ESX do
        Wait(100)
    end

    while not lib do
        Wait(100)
    end

    while GetResourceState('ox_target') ~= 'started' do
        Wait(1000)
    end

    Wait(1000)

    createTargets()
end)

AddEventHandler(
    'onResourceStop',
    function(resource)
        if resource ~= GetCurrentResourceName() then
            return
        end

        for _, targetId in ipairs(targets) do
            pcall(function()
                exports.ox_target:removeZone(targetId)
            end)
        end
    end
)