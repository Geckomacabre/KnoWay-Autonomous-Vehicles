-- ==============================
-- KnoWay: driverless robotaxis in ambient traffic
-- ==============================
-- Every player runs this, so the rules below keep that safe on a multiplayer
-- server:
--   * a car is only swapped by the game that OWNS it (NetworkHasControlOfEntity),
--     so two players never both delete and replace the same car;
--   * only ambient traffic is touched: no mission/script vehicles, no parked
--     cars, nothing with a player or a passenger in it, road classes only;
--   * the cap counts every KnoWay this game can see, not just ones it made,
--     so it is shared by the area rather than multiplied per player;
--   * spawned cars are handed back to the engine (SetEntityAsNoLongerNeeded)
--     so they despawn like normal traffic instead of piling up.

local DRIVER_STATE = 'knowayDriver'

local function LoadModel(model)
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local deadline = GetGameTimer() + 10000
    while not HasModelLoaded(model) do
        if GetGameTimer() > deadline then return false end
        Wait(0)
    end
    return true
end

-- ==============================
-- LOOK (also used by um_gigs for its Ryde Me AI pickup)
-- ==============================
--- Paint, livery and grille -- what makes a vivanite2 read as a KnoWay.
--- Locks are separate (see ApplyLocks) because a robotaxi you actually
--- booked has to let you in.
---@param vehicle number
local function StyleVehicle(vehicle)
    if Config.isOnlyWhiteKnoWay then
        SetVehicleColours(vehicle, 111, 111) -- 111 = metallic white
        SetVehicleExtraColours(vehicle, 111, 156)
        SetVehicleDashboardColour(vehicle, 111)
        SetVehicleInteriorColour(vehicle, 111)
    else
        local prim = math.random(0, 159)
        local sec = math.random(0, 159)
        SetVehicleColours(vehicle, prim, sec)
        SetVehicleExtraColours(vehicle, math.random(0, 159), 156)
        SetVehicleDashboardColour(vehicle, prim)
        SetVehicleInteriorColour(vehicle, sec)
    end

    SetVehicleModKit(vehicle, 0)
    SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false) -- best engine
    SetVehicleMod(vehicle, 48, Config.LIVERY_INDEX, false)
    SetVehicleMod(vehicle, 6, Config.GRILLE_MOD, false)
end

exports('styleVehicle', StyleVehicle)
exports('getModel', function() return Config.VEHICLE_MODEL end)

local function ApplyLocks(vehicle)
    if Config.isAlwaysLocked then
        SetVehicleDoorsLocked(vehicle, 2)
        -- Lock state 2 on its own still lets a player smash the window and
        -- carjack it. This stops players getting in at all.
        SetVehicleDoorsLockedForAllPlayers(vehicle, true)
    else
        SetVehicleDoorsLocked(vehicle, 1)
    end
end

--- Hides a driver ped and stops it reacting to anything. Also re-applied by
--- housekeeping whenever this game takes ownership of an existing KnoWay
--- driver, in case migration drops any of it.
local function MakeDriverInvisible(ped)
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)
    SetEntityCollision(ped, false, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedKeepTask(ped, true)
end

local function CreateInvisibleDriver(vehicle)
    local ped = CreatePedInsideVehicle(vehicle, 26, Config.DRIVER_MODEL, -1, true, false)
    if ped == 0 then return 0 end

    MakeDriverInvisible(ped)
    SetDriverAbility(ped, 1.0)
    SetDriverAggressiveness(ped, 0.0)
    TaskVehicleDriveWander(ped, vehicle, 20.0, 786603) -- ~45 mph, law-abiding

    Entity(ped).state:set(DRIVER_STATE, true, true)
    return ped
end

-- ==============================
-- ELIGIBILITY
-- ==============================
local function HasOnlyAnAmbientDriver(veh)
    local driver = GetPedInVehicleSeat(veh, -1)
    if driver == 0 or IsPedAPlayer(driver) then return false end
    if GetVehicleNumberOfPassengers(veh) > 0 then return false end
    return true
end

local function CanSwap(veh, myPos)
    if not DoesEntityExist(veh) then return false end
    if GetEntityModel(veh) == Config.VEHICLE_MODEL then return false end
    if IsEntityAMissionEntity(veh) then return false end            -- script/job/player-owned vehicles
    if not NetworkGetEntityIsNetworked(veh) then return false end
    if not NetworkHasControlOfEntity(veh) then return false end     -- someone else's game owns it
    if not Config.ALLOWED_CLASSES[GetVehicleClass(veh)] then return false end
    if not HasOnlyAnAmbientDriver(veh) then return false end
    if IsEntityOnScreen(veh) then return false end
    if #(GetEntityCoords(veh) - myPos) < Config.MIN_SWAP_DISTANCE then return false end
    return true
end

-- ==============================
-- SWAP
-- ==============================
local function Swap(veh)
    local coords = GetEntityCoords(veh)
    local heading = GetEntityHeading(veh)
    local speed = GetEntitySpeed(veh)

    local driver = GetPedInVehicleSeat(veh, -1)
    if driver ~= 0 then
        SetEntityAsMissionEntity(driver, true, true)
        DeleteEntity(driver)
    end
    SetEntityAsMissionEntity(veh, true, true)
    DeleteEntity(veh)

    local newVeh = CreateVehicle(Config.VEHICLE_MODEL, coords.x, coords.y, coords.z, heading, true, false)
    if newVeh == 0 then return end

    SetVehicleOnGroundProperly(newVeh)
    StyleVehicle(newVeh)
    ApplyLocks(newVeh)

    local ped = CreateInvisibleDriver(newVeh)
    if ped == 0 then
        DeleteEntity(newVeh)
        return
    end

    -- Keep the car moving at the speed the one it replaced was going, so it
    -- does not stall in the lane.
    SetVehicleForwardSpeed(newVeh, speed)

    -- Hand both back to the population system so they despawn like normal
    -- traffic once nobody is near them.
    SetEntityAsNoLongerNeeded(newVeh)
    SetEntityAsNoLongerNeeded(ped)
end

-- ==============================
-- HOUSEKEEPING
-- ==============================
--- Runs over KnoWays this game owns: deletes ones that are far away, deletes
--- invisible drivers that ended up outside a car (otherwise they wander the
--- pavement as invisible ghosts), and re-hides any driver whose ownership
--- just moved to us.
local function Housekeep(myPos)
    for _, ped in ipairs(GetGamePool('CPed')) do
        if NetworkHasControlOfEntity(ped) and Entity(ped).state[DRIVER_STATE] then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh == 0 or #(GetEntityCoords(ped) - myPos) > Config.DESPAWN_DISTANCE then
                if veh ~= 0 and NetworkHasControlOfEntity(veh) then
                    SetEntityAsMissionEntity(veh, true, true)
                    DeleteEntity(veh)
                end
                SetEntityAsMissionEntity(ped, true, true)
                DeleteEntity(ped)
            elseif IsEntityVisible(ped) then
                MakeDriverInvisible(ped)
            end
        end
    end
end

local function CountNearbyKnoWays()
    local count = 0
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if GetEntityModel(veh) == Config.VEHICLE_MODEL then count = count + 1 end
    end
    return count
end

-- ==============================
-- MAIN LOOP
-- ==============================
CreateThread(function()
    if not IsModelInCdimage(Config.VEHICLE_MODEL) or not IsModelInCdimage(Config.DRIVER_MODEL) then
        print('^1[knoway] vivanite2 (or the driver model) is not in this game build -- KnoWay traffic disabled.^7')
        return
    end
    if not LoadModel(Config.VEHICLE_MODEL) or not LoadModel(Config.DRIVER_MODEL) then
        print('^1[knoway] could not load models -- KnoWay traffic disabled.^7')
        return
    end

    while true do
        Wait(Config.CHECK_INTERVAL)

        local myPos = GetEntityCoords(PlayerPedId())
        Housekeep(myPos)

        if CountNearbyKnoWays() < Config.MAX_ACTIVE then
            for _, veh in ipairs(GetGamePool('CVehicle')) do
                if math.random() < Config.SPAWN_CHANCE and CanSwap(veh, myPos) then
                    Swap(veh)
                    break -- one per check, so KnoWays trickle in instead of appearing all at once
                end
            end
        end
    end
end)
