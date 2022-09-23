burgercraft = {}

function burgercraft.setExperience(player, xp)
    if player then
        player:get_meta():set_string("BC_XP", xp)
    end
end

function burgercraft.getExperience(player)
    if player then
        return player:get_meta():get("BC_XP") or 0
    end
end
