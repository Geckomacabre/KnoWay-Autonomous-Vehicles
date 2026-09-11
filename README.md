This script add the KnoWay Autonomous Vehicles from GTA Online to YOUR FiveM server!

Some of the ambient traffic around players gets swapped for white KnoWay robotaxis
(vivanite2) with an invisible driver, just like GTA Online.

YOU MUST HAVE THIS IN YOUR SERVER FOR THE VEHICLE MODEL!
https://github.com/lkid73/SafeHouseInTheHills

Installation

    Copy the KnoWay folder from this repo into your resources folder
    Add "ensure KnoWay" to your server.cfg

What's new in 2.0

    Multiplayer safe: a car is only swapped by the player whose game owns it,
    so two players never fight over the same car
    The KnoWay limit is shared by everyone in an area instead of being
    per player, so more players no longer means more KnoWays
    Only ordinary AI traffic gets swapped. Parked cars, player cars, job and
    mission vehicles, cars with passengers, bikes, trucks, emergency vehicles,
    boats, aircraft and trains are left alone
    Cars are only swapped out of sight and at least 60m away, so nobody sees
    a car turn into a KnoWay
    KnoWays despawn like normal traffic instead of piling up
    Locked KnoWays can't be carjacked by smashing a window
    Invisible drivers that end up outside a car get cleaned up
    If the vivanite2 model is missing, the script prints one warning and
    turns itself off instead of breaking

Config (config.lua)

    SPAWN_CHANCE       odds an eligible car gets swapped on each check
    CHECK_INTERVAL     how often to check, in ms
    MAX_ACTIVE         max KnoWays in an area
    MIN_SWAP_DISTANCE  only swap cars at least this far away
    DESPAWN_DISTANCE   delete KnoWays you own past this distance
    ALLOWED_CLASSES    which vehicle classes can become a KnoWay
    isOnlyWhiteKnoWay  all white, or random colours
    isAlwaysLocked     stop players getting in
    LIVERY_INDEX / GRILLE_MOD   the look

Exports (for other scripts, e.g. a rideshare app spawning its own KnoWay)

    exports['KnoWay']:styleVehicle(vehicle)   -- paint, livery and grille
    exports['KnoWay']:getModel()              -- the vehicle model hash

Use your resource's folder name in exports[...] if you renamed it.
