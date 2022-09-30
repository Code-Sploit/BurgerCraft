local dungeons = {
    lootTable = {
        -- HYPERION MATERIALS
        {itemstring = "hyperion:handle",                  weight   = 1},
        {itemstring = "hyperion:ancient_rubble",          weight   = 3},
        {itemstring = "hyperion:altar_shard",		  	  weight   = 8},
        
        -- RANDOM LOOT
        {itemstring = "mcl_core:obsidian",                weight   = 10},
        {itemstring = "mcl_end:end_stone",                weight   = 10},
        {itemstring = "mcl_deepslate:deepslate_chiseled", weight   = 8},
        {itemstring = "mcl_core:coalblock",               weight   = 12},
        {itemstring = "mcl_core:crying_obsidian",         weight   = 6},
        -- SCROLLS
        {itemstring = "hyperion:wither_shield",			  weight   = 2},
        {itemstring = "hyperion:shadow_warp",			  weight   = 2},
        {itemstring = "hyperion:implosion",				  weight   = 2},

        -- NOTHING L+BOZO
        {itemstring = "",                                 weight   = 8}
    },

    spawn = {x=9000,y=9000,z=9000},
    currentMap = ""
}

local dungeon_maps = {
    {schem = "dungeon_cs_1.mts",
    
    mobPositions = {
        {x = 9019, y = 9002, z = 9026},
        {x = 9060, y = 9002, z = 9012}
    },
    
    spawnPosition = {
        x = 9075, y = 9003, z = 9039
    }
}}

function dungeons.startDungeon(player)
    local pos = dungeons.currentMap.spawnPosition

    player:set_pos(pos)
end

function dungeons.createDungeon(player)
    local map = dungeon_maps[math.random(#dungeon_maps)]

    local schematic       = minetest.get_worldpath() .. "/schems/" .. map.schem
    local rotation        = 0
    local force_placement = true

    minetest.place_schematic(dungeons.spawn, schematic, rotation, _, force_placement)

    dungeons.currentMap = map

    dungeons.startDungeon(player)
end

function dungeons.removeDungeon()
    local schematic       = minetest.get_worldpath() .. "/schems/" .. "dungeon_cs_1_air.mts"
    local rotation        = 0
    local force_placement = true

    minetest.place_schematic(dungeons.spawn, schematic, rotation, _, force_placement)
end

function dungeons.lootDungeon()
    local pool = {}
    local loot = {}
    
    for _,item in pairs(dungeons.lootTable) do
        local weight  = item.weight
        local itemstr = item.itemstring

        for i=1,weight do
            table.insert(pool, itemstr)
        end
    end

    local loot_count = 1 -- TODO: Make lootcount calculated by score

    for i=1,loot_count do
        table.insert(loot, pool[math.random(#pool)])
    end

    return loot
end

function dungeons.onDungeonEnd(player)
    local loot = dungeons.lootDungeon()

    local inventory = player:get_inventory()

    for _, item in pairs(loot) do
        inventory:add_item("main", item)
    end

    player:set_pos({x = 0, y = 30, z = 0})
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

    if timerMobSpawner < 3 then
        return
    end

    if dungeons.currentMap == "" then
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
            dungeons.createDungeon(player)
        else
            dungeons.onDungeonEnd(player)
        end
    end
})
