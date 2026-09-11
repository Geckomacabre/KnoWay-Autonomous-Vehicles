Config = {}

-- The KnoWay robotaxi. Checked with IsModelInCdimage at startup -- if this
-- game build does not have it, the resource logs once and does nothing.
Config.VEHICLE_MODEL = `vivanite2`
Config.DRIVER_MODEL = `a_m_y_business_01`

-- Livery (mod slot 48) and grille (mod slot 6), 0-based. Not verified against
-- the model's real mod list -- change these if the KnoWay decal is on a
-- different livery index.
Config.LIVERY_INDEX = 0
Config.GRILLE_MOD = 0

Config.isOnlyWhiteKnoWay = true -- true = all white, false = random colours
Config.isAlwaysLocked = true    -- true = players cannot get in (not even by smashing a window)

-- Odds each eligible car gets swapped on a check. At most one swap per check.
Config.SPAWN_CHANCE = 0.15
Config.CHECK_INTERVAL = 2000 -- ms

-- Cap on KnoWays in the area around you, counting every KnoWay your game can
-- see -- including ones another player's game spawned. The cap is shared by
-- everyone in the same area, so it does not multiply with the player count.
Config.MAX_ACTIVE = 12

-- Only ever swap a car that is out of sight and at least this far away, so
-- nobody watches a car turn into a different car.
Config.MIN_SWAP_DISTANCE = 60.0

-- KnoWays further than this from you get deleted if your game owns them.
-- Backup for the normal traffic cleanup, which should remove them first.
Config.DESPAWN_DISTANCE = 450.0

-- Vehicle classes (GET_VEHICLE_CLASS) allowed to become a KnoWay. Ordinary
-- road cars only: no bikes, trucks, service/emergency/military vehicles,
-- boats, aircraft or trains.
Config.ALLOWED_CLASSES = {
    [0] = true,  -- Compact
    [1] = true,  -- Sedan
    [2] = true,  -- SUV
    [3] = true,  -- Coupe
    [4] = true,  -- Muscle
    [5] = true,  -- Sports Classic
    [6] = true,  -- Sports
    [7] = true,  -- Super
    [9] = true,  -- Off-road
    [12] = true, -- Van
}
