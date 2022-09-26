local bc_dungeons = {
    players_in_dungeon = {},
    active = 0,
    loot_table = {
		-- HYPERION MATERIALS
        {itemstring = "hyperion:handle",                  weight   = 1,		rarity = 1},
        {itemstring = "hyperion:ancient_rubble",          weight   = 3,		rarity = 3},
		{itemstring = "hyperion:altar_shard",		  	  weight   = 5,		rarity = 5},
		
		-- RANDOM LOOT
        {itemstring = "mcl_core:obsidian",                weight   = 10,	rarity = 10},
        {itemstring = "mcl_end:end_stone",                weight   = 10,	rarity = 10},
        {itemstring = "mcl_deepslate:deepslate_chiseled", weight   = 8,		rarity = 8},
        {itemstring = "mcl_core:coalblock",               weight   = 12,	rarity = 12},
        {itemstring = "mcl_core:crying_obsidian",         weight   = 6,		rarity = 6},
		-- SCROLLS
		{itemstring = "hyperion:wither_shield",			  weight   = 2,		rarity = 2},
		{itemstring = "hyperion:shadow_warp",			  weight   = 2,		rarity = 2},
		{itemstring = "hyperion:implosion",				  weight   = 2,		rarity = 2}

		-- NOTHING L+BOZO
        {itemstring = "",                                 weight   = 8,		rarity = 8}
    },
	tiers = {
		{name = "basic",								  scoreMul = 1},
		{name = "advanced",								  scoreMul = 1.5},
		{name = "hard",									  scoreMul = 2},
		{name = "insane",								  scoreMul = 2.5},
		{name = "extreme",								  scoreMul = 3}
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

local etime = 0

minetest.register_globalstep(function(dtime)
	etime = etime + dtime

	if etime < 1 then
		return
	end

	if bc_dungeons.active == 0 then
		return
	end

	local old_player = ""

	for _,player in pairs(bc_dungeons.players_in_dungeon) do
		local player = minetest.get_player_by_name(player)
		local pos	 = player:get_pos()

		local tnt_pos = {x=pos.x + math.random(3), y=pos.y + 4, z=pos.z + math.random(3)}

		if player:get_player_name() == old_player then
			return
		end

		old_player = player:get_player_name()

		minetest.add_entity(pos, "mobs_mc:iron_golem")
		minetest.add_entity(tnt_pos, "mcl_tnt:tnt")
	end

	etime = 0
end)

function bc_dungeons.clearDungeon()
	for _,obj in pairs(minetest.get_objects_inside_radius(coords, 20)) do
		obj:remove()
	end
end

function bc_dungeons.getTierScore(tier)
	for _,tdata in pairs(bc_dungeons.tiers) do
		local scoreMul = tdata.scoreMul

		if tdata.name == tier then
			return scoreMul
		end
	end
end

function bc_dungeons.calculateLoot(score, tier)
    local pool = {}
    local loot = {}
    
    for _,item in pairs(bc_dungeons.loot_table) do
        local weight  = item.weight
        local itemstr = item.itemstring
		local rarity  = item.rarity

		-- Apply tier score boost
		local scoreMul = bc_dungeons.getTierScore(tier)

        for i=1,weight do
            table.insert(pool, itemstr)
        end
    end

    local loot_count = score / 100

    for i=1,loot_count do
        table.insert(loot, pool[math.random(#pool)])
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

	bc_dungeons.clearDungeon()
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

	bc_dungeons.clearDungeon()
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
