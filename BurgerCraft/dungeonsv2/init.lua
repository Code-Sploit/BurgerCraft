local dungeons = {
    spawn = {x=9000,y=9000,z=9000},
    currentMap = ""
}

local dungeon_maps = {
    {schem = "dungeon_cs_1.mts", mobPositions = {
        {x = 9019, y = 9002, z = 9026},
        {x = 9060, y = 9002, z = 9012}
    }}
}

function dungeons.createDungeon()
    local map = dungeon_maps[math.random(#dungeon_maps)]

    local schematic       = minetest.get_worldpath() .. "/schems/" .. map.schem
    local rotation        = 0
    local force_placement = true

    minetest.place_schematic(dungeons.spawn, schematic, rotation, _, force_placement)

    dungeons.currentMap = map
end

function dungeons.removeDungeon()
    local schematic       = minetest.get_worldpath() .. "/schems/" .. "dungeon_cs_1_air.mts"
    local rotation        = 0
    local force_placement = true

    minetest.place_schematic(dungeons.spawn, schematic, rotation, _, force_placement)
end

function dungeons.startDungeon(player)
    player:set_pos(dungeons.spawn)
end
--[[
minetest.register_globalstep(function(dtime)
    for _, obj in pairs(minetest.get_objects_inside_radius(dungeons.spawn, 100)) do
        if not obj._dungeonObject then
            obj:remove()
        end
    end
end)
]]

local timerMobSpawner = 0

minetest.register_globalstep(function(dtime)
    timerMobSpawner = timerMobSpawner + dtime

    if timerMobSpawner < 2 or dungeons.currentMap == "" then
        return
    end

    local randomPos = dungeons.currentMap.mobPositions[math.random(#dungeons.currentMap.mobPositions)]

    minetest.add_entity(randomPos, "mobs_mc:iron_golem")

    timerMobSpawner = 0
end)

minetest.register_chatcommand("dungeon", {
    func = function(name, param)
        local player = minetest.get_player_by_name(name)

        if param == "start" then
            dungeons.createDungeon()
        else
            dungeons.removeDungeon()
        end
    end
})
