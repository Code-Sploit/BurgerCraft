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
        {itemstring = "",                                 weight   = 6}
    },

    spawn = {x=9000,y=9000,z=9000},
    lootRoom = {x=9008, y=9003, z=9008},
    
    lootRoomPositions = {
        {x=9003, y=9002, z=9003},
        {x=9013, y=9002, z=9003},
        {x=9013, y=9002, z=9013},
        {x=9003, y=9002, z=9013}
    },
    
    score = 0,
    players = {},
    currentMap = ""
}

local formspec_dungeon_secret_chest =   "size[9,9]"..
                                        "label[3.5,0;"..minetest.formspec_escape(minetest.colorize("#313131", "Secret Chest")) .. "]" ..
                                        
                                        mcl_formspec.get_itemslot_bg(4,1.5,1,1) ..
                                        
                                        "list[context;secret;4,1.5;9,3;]" ..
                                        "label[0,4.0;".. minetest.formspec_escape(minetest.colorize("#313131", "Inventory")) .. "]" ..
                                        "list[current_player;main;0,4.5;9,3;9]"..
                                        
                                        mcl_formspec.get_itemslot_bg(0,4.5,9,3)..
                                        
                                        "list[current_player;main;0,7.74;9,1;]"..
                                        
                                        mcl_formspec.get_itemslot_bg(0,7.74,9,1)

local formspec_dungeon_loot_chest   =   "size[9,9]"..
                                        "label[3.5,0;"..minetest.formspec_escape(minetest.colorize("#313131", "Loot Chest")) .. "]" ..
                                        
                                        mcl_formspec.get_itemslot_bg(4,1.5,1,1) ..
                                        
                                        "list[context;loot;4,1.5;9,3;]" ..
                                        "label[0,4.0;".. minetest.formspec_escape(minetest.colorize("#313131", "Inventory")) .. "]" ..
                                        "list[current_player;main;0,4.5;9,3;9]"..
                                        
                                        mcl_formspec.get_itemslot_bg(0,4.5,9,3)..
                                        
                                        "list[current_player;main;0,7.74;9,1;]"..
                                        
                                        mcl_formspec.get_itemslot_bg(0,7.74,9,1)

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

function dungeons.positionEqual(pos1, pos2)
    if pos1.x == pos2.x and pos1.y == pos2.y and pos1.z == pos2.z then
        return 1
    else
        return 0
    end
end

function dungeons.activityCheck()
    if next(dungeons.players) == nil then
        return 0
    else
        return 1
    end
end

function dungeons.startDungeon(player)
    if not dungeons.currentMap.schem == "" then
        return
    end

    local pos = dungeons.currentMap.spawnPosition

    player:set_pos(pos)

    table.insert(dungeons.players, player:get_player_name())
end

function dungeons.createDungeon(player)
    if not dungeons.currentMap.schem == "" then
        return
    end

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

    for _, obj in pairs(minetest.get_objects_inside_radius(dungeons.spawn, 100)) do
        obj:remove()
    end

    minetest.place_schematic(dungeons.spawn, schematic, rotation, _, force_placement)
end

function dungeons.lootDungeon()
    local pool = {}
    local loot = {}

    local score = dungeons.score
    
    for _,item in pairs(dungeons.lootTable) do
        local weight  = item.weight
        local itemstr = item.itemstring

        if score > 200 then
            if weight < 5 then
                weight = weight + 1
            else
                weight = weight - 1
            end

        elseif score > 250 then
            if weight < 5 then
                weight = weight + 2
            else
                weight = weight - 1
            end
        end

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

function dungeons.onDungeonEnd(player, failed)
    if dungeons.currentMap == "" then
        return
    end

    dungeons.removeDungeon()
    dungeons.createLootRoom()

    player:set_pos(dungeons.lootRoom)

    local score = dungeons.score

    if score < 0 then
        score = "D"
    elseif score < 200 and score >= 0 then
        score = "B"
    elseif score >= 200 and score < 250 then
        score = "A"
    elseif score >= 250 then
        score = "S"
    end

    if failed == 0 then
        minetest.chat_send_player(player:get_player_name(), "You completed the dungeon with " .. score .. " rank!")
    else
        minetest.chat_send_player(player:get_player_name(), "You failed the dungeon with " .. score .. " rank!")
    end

    dungeons.score = 0
    dungeons.currentMap = ""
end

function dungeons.createLootRoom()
    local score = dungeons.score

    -- First generate the room at spawn

    local schematic       = minetest.get_worldpath() .. "/schems/loot_room.mts"
    local rotation        = 0
    local force_placement = true

    minetest.place_schematic(dungeons.spawn, schematic, rotation, _, force_placement)

    -- Now place chests
    for _, position in pairs(dungeons.lootRoomPositions) do
        local loot = dungeons.lootDungeon()

        minetest.set_node(position, {name="dungeonsv2:loot_chest"})

        local nodeMeta = minetest.get_meta(position)
        local nodeInv  = nodeMeta:get_inventory()

        for _, item in pairs(loot) do
            nodeInv:set_stack("loot", 1, item)
        end
    end
end

function dungeons.increaseDungeonScore(score)
    -- score < 0 total score is D rank
    -- 0   - 200 total score is B rank
    -- 200 - 250 total score is A rank
    -- 250 - _   total score is S rank

    dungeons.score = dungeons.score + score
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

    if timerMobSpawner < 1 then
        return
    end

    if dungeons.currentMap == "" then
        return
    end

    local randomPos = dungeons.currentMap.mobPositions[math.random(#dungeons.currentMap.mobPositions)]

    minetest.add_entity(randomPos, "mobs_mc:iron_golem")

    timerMobSpawner = 0
end)

minetest.register_globalstep(function(dtime)
    if dungeons.currentMap == "" then
        return
    end

    for _, player in pairs(dungeons.players) do
        local player = minetest.get_player_by_name(player)

        if player:get_pos().y < 9000 then
            dungeons.onDungeonEnd(player, 1)
        end
    end
end)

minetest.register_chatcommand("dungeon", {
    func = function(name, param)
        local player = minetest.get_player_by_name(name)

        if param == "start" then
            if dungeons.activityCheck() == 0 then
                dungeons.createDungeon(player)
            end
        else
            dungeons.onDungeonEnd(player, 0)
        end
    end
})

minetest.register_node("dungeonsv2:secret_chest", {
    name = "Secret Chest",
    mesh = "secret_chest.obj",
    use_texture_alpha = minetest.features.use_texture_alpha_string_modes and "opaque" or false,
    paramtype = "light",
    paramtype2 = "facedir",
    stack_max = 64,
    groups = {deco_block=1},

    tiles = {
        "secret_chest_top.png",
        "secret_chest_top.png",
        "secret_chest_top.png",
        "secret_chest_top.png", 
        "secret_chest_top.png",
        "secret_chest_front.png"
    },

    on_construct = function(pos)
		local meta 			= minetest.get_meta(pos)
		local inv 			= meta:get_inventory()

		inv:set_size("secret", 1)
        inv:set_stack("secret", 1, "mcl_core:diamond")

		meta:set_string("formspec", formspec_dungeon_secret_chest)
	end,

    on_rightclick = function(pos, node, clicker)
        local meta = minetest.get_meta(pos)
        local inv  = meta:get_inventory()

        if inv:is_empty("secret") then
            minetest.chat_send_player(clicker:get_player_name(), "You have already found this secret!")
        else
            dungeons.increaseDungeonScore(10)
        end
    end,

    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
	
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        local inv    = minetest.get_meta(pos):get_inventory()
        local stackd = stack

        inv:set_stack("secret", 1, ItemStack())

        -- Clear all the other chests
        for _, position in pairs(dungeons.lootRoomPositions) do
            minetest.set_node(position, {name="air"})
        end

		return stackd:get_count()
	end,
    	
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        return 0
	end,
})

minetest.register_node("dungeonsv2:loot_chest", {
    name = "Loot Chest",
    mesh = "secret_chest.obj",
    use_texture_alpha = minetest.features.use_texture_alpha_string_modes and "opaque" or false,
    paramtype = "light",
    paramtype2 = "facedir",
    stack_max = 64,
    groups = {deco_block=1},

    tiles = {
        "secret_chest_top.png",
        "secret_chest_top.png",
        "secret_chest_top.png",
        "secret_chest_top.png", 
        "secret_chest_top.png",
        "secret_chest_front.png"
    },

    on_construct = function(pos)
		local meta 			= minetest.get_meta(pos)
		local inv 			= meta:get_inventory()

		inv:set_size("loot", 1)

		meta:set_string("formspec", formspec_dungeon_loot_chest)
	end,

    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
	
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        local inv    = minetest.get_meta(pos):get_inventory()

        for _, position in pairs(dungeons.lootRoomPositions) do
            if dungeons.positionEqual(pos, position) == 0 then
                minetest.set_node(position, {name="air"})
            end
        end

		return stack:get_count()
	end,
    	
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        return 0
	end,
})
