-- TODO: Find a way to display tasks to the player

minetest.register_chatcommand("showexp", {
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local exp    = burgercraft.getExperience(player)

        minetest.chat_send_player(name, "Your current xp is: " .. exp)
    end,
})

minetest.register_chatcommand("addexp", {
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        local old_exp = burgercraft.getExperience(player)
        local new_exp = old_exp + 10

        burgercraft.setExperience(player, new_exp)
    end
})