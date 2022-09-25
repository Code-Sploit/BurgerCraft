local bc_dungeons = {
    players_in_dungeon = {},
    active = 0,
    loot_table = {
        {itemstring = "hyperion:handle",                  weight = 1},
        {itemstring = "hyperion:ancient_rubble",          weight = 3},
        {itemstring = "mcl_core:obsidian",                weight = 10},
        {itemstring = "mcl_end:end_stone",                weight = 10},
        {itemstring = "mcl_deepslate:deepslate_chiseled", weight = 8},
        {itemstring = "mcl_core:coalblock",               weight = 12},
        {itemstring = "mcl_core:crying_obsidian",         weight = 6},
        {itemstring = "",                                 weight = 8}
    }
}

local coords = {x=9000,y=9000,z=9000}
local timer = 0

minetest.register_globalstep(function(dtime)
    timer = timer + dtime

    -- Check if dungeon active
    if bc_dungeons.active == 0 then
        return
    end

    for _,player in pairs(bc_dungeons.players_in_dungeon) do
        -- Check for deaths
        local pos = minetest.get_player_by_name(player):get_pos()

        if pos.y < 8990 then
            -- Player died
	    bc_dungeons.dungeonFailed(player)

	    bc_dungeons.active = 0

            return
        end
    end
end)

function bc_dungeons.calculateLoot(score)
    local new_array = {}
    local loot      = {}
    
    for _,item in pairs(bc_dungeons.loot_table) do
        local weight  = item.weight
        local itemstr = item.itemstring

        for i=0,weight do
            table.insert(new_array, itemstr)
        end
    end

    local loot_count = score / 100

    for i=0,loot_count do
        table.insert(loot, new_array[math.random(#new_array)])
    end

    return loot
end

function bc_dungeons.calculateDungeonScore(data, completion)
	local totalScore = 100

	if data.secrets then
		totalScore = totalScore + data.secrets
	end

	if data.tier then
		totalScore = totalScore + (data.tier * 10)
	end

	if completion == 0 then
		return totalScore / 100
	else
		return totalScore
	end
end

function bc_dungeons.dungeonFailed(player)
	minetest.chat_send_player(player, "You failed the dungeon!")
	minetest.chat_send_player(player, "You received 1% of full completion XP")

	local playerobj = minetest.get_player_by_name(player)

	local gainedExp = bc_dungeons.calculateDungeonScore({}, 0)
	local oldExp 	= burgercraft.getExperience(playerobj)
	local newExp	= oldExp + gainedExp

	burgercraft.setExperience(playerobj, newExp)

	-- Deactivate the dungeon
	bc_dungeons.active = 0
end

function bc_dungeons.dungeonCompleted(player)
	minetest.chat_send_player(player:get_player_name(), "You completed the dungeon!")
	minetest.chat_send_player(player:get_player_name(), "You received 100% of full completion XP")

	local gainedExp = bc_dungeons.calculateDungeonScore({}, true)
	local oldExp	= burgercraft.getExperience(player)
	local newExp	= oldExp + gainedExp

	burgercraft.setExperience(player, newExp)

	-- Deactivate the dungeon
	bc_dungeons.active = 0

    -- Do loottable stuff
    local loot = bc_dungeons.calculateLoot(100)
    local inv = player:get_inventory()

    for _,item in pairs(loot) do
        inv:add_item("main", item)
    end
end

function bc_dungeons.checkDungeonStatus(player)
	local pos = player:get_pos()

	if pos.y < 8990 then
		return 0
	else
		return 1
	end
end

function bc_dungeons.startDungeon(player)
    -- Start spawning 
    local pos = player:get_pos()
    local position_str = pos.x .. "," .. pos.y .. "," .. pos.z

    -- Wait until 2Minutes passed (10 seconds in alpha)
    minetest.after(10, function()
	    local completed = bc_dungeons.checkDungeonStatus(player)

	    if completed == 1 and bc_dungeons.active == 1 then
		    bc_dungeons.dungeonCompleted(player)
	    end

	    bc_dungeons.active = 0
    end)
end

function bc_dungeons.addDungeonPlayer(name)
    table.insert(bc_dungeons.players_in_dungeon, name)
end

function bc_dungeons.removeDungeonPlayer(name)
    table.remove(bc_dungeons.players_in_dungeon, name)
end

minetest.register_chatcommand("startdungeon", {
    func = function(name, param)
        if bc_dungeons.active == 1 then
            minetest.chat_send_player(name, "Dungeon in use!")
        end

        local player = minetest.get_player_by_name(name)

        minetest.chat_send_player(name, "Starting your dungeon in 3 seconds!")

	if bc_dungeons.active == 1 then
		minetest.chat_send_player(name, "Sorry someone else is already using the dungeon!")
		return
	end

        minetest.after(3, function()
            player:set_pos(coords)

            bc_dungeons.active = 1

            bc_dungeons.addDungeonPlayer(name)

            -- Start the dungeon
            bc_dungeons.startDungeon(player)
       end)
    end
})
