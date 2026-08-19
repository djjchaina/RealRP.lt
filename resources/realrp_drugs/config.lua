Config = {}

Config.Debug = false

Config.Items = {
    raw = 'rrp_raw',
    processed = 'rrp_processed',
    packaged = 'rrp_packaged'
}

Config.Zones = {
    gather = {
        {
            coords = vector3(2200.0, 5575.0, 53.8),
            radius = 3.0,
            label = 'Rinkti zaliava'
        },
        {
            coords = vector3(1700.0, 4920.0, 42.1),
            radius = 3.0,
            label = 'Rinkti zaliava'
        }
    },

    process = {
        {
            coords = vector3(1200.0, -1400.0, 35.0),
            radius = 2.5,
            label = 'Perdirbti zaliava'
        }
    },

    package = {
        {
            coords = vector3(1250.0, -1400.0, 35.0),
            radius = 2.5,
            label = 'Supakuoti produkta'
        }
    },

    sell = {
        {
            coords = vector3(-1500.0, -300.0, 49.0),
            radius = 2.5,
            label = 'Parduoti produkta'
        }
    }
}

Config.Collect = {
    duration = 7000,
    minAmount = 1,
    maxAmount = 3,
    cooldown = 30
}

Config.Process = {
    duration = 9000,
    requiredAmount = 2,
    outputMin = 1,
    outputMax = 2,
    cooldown = 45
}

Config.Package = {
    duration = 5000,
    requiredAmount = 1,
    outputAmount = 1,
    cooldown = 20
}

Config.Sell = {
    duration = 6000,
    priceMin = 750,
    priceMax = 1300,
    cooldown = 60,
    minCopsOnline = 0
}

Config.Police = {
    job = 'police',

    alertChance = 25,

    blip = {
        sprite = 161,
        color = 1,
        scale = 1.0,
        duration = 45
    }
}

Config.Validation = {
    maxDistance = 6.0
}

Config.Text = {
    gathering = 'Renkate zaliava...',
    processing = 'Perdirbate zaliava...',
    packaging = 'Pakuojate produkta...',
    selling = 'Parduodate produkta...',

    cancelled = 'Veiksmas nutrauktas.',
    alreadyDoing = 'Jau atliekate veiksma.',
    notEnoughItems = 'Neturite pakankamai reikiamu daiktu.',
    inventoryFull = 'Inventoriuje nepakanka vietos.',
    tooFar = 'Esate per toli.',
    cooldown = 'Turite palaukti %s sek.',
    sold = 'Pardavete produkta uz $%s.',
    policeAlert = 'Gautas pranesimas apie itartina veikla.'
}

Config.Animations = {
    gather = {
        dict = 'amb@world_human_gardener_plant@idle_a',
        clip = 'idle_a'
    },

    process = {
        dict = 'anim@amb@business@weed@weed_processing',
        clip = 'process'
    },

    package = {
        dict = 'anim@amb@business@weed@weed_processing',
        clip = 'process'
    },

    sell = {
        dict = 'mp_ped_interaction',
        clip = 'handshake_guy_a'
    }
}