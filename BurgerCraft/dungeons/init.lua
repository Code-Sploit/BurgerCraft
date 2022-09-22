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
            return
        end

        if timer >= 5 then
            minetest.add_entity(pos, "mobs_mc:iron_golem")
        end
    end
end)

function bc_dungeons.startDungeon(player)
    -- Start spawning 
    local pos = player:get_pos()
    local position_str = pos.x .. "," .. pos.y .. "," .. pos.z

    minetest.add_entity(pos, "mobs_mc:iron_golem")
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