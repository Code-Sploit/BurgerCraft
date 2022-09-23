local bc_dungeons = {
    players_in_dungeon = {},
    active = 0
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

            return
        end
    end
end)

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
	minetest.chat_send_player(player:get_player_name(), "You failed the dungeon!")
	minetest.chat_send_player(player:get_player_name(), "You received 1% of full completion XP")

	local gainedExp = bc_dungeons.calculateDungeonScore({}, false)
	local oldExp 	= burgercraft.getExperience(player)
	local newExp	= oldExp + gainedExp

	burgercraft.setExperience(player, newExp)

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

	    if completed == 1 then
		    bc_dungeons.dungeonCompleted(player)
	    end
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

        minetest.after(3, function()
            player:set_pos(coords)

            bc_dungeons.active = 1

            bc_dungeons.addDungeonPlayer(name)

            -- Start the dungeon
            bc_dungeons.startDungeon(player)
       end)
    end
})
