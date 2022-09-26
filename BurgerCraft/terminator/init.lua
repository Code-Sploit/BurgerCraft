minetest.register_craftitem("terminator:terminator", {
    description = "Terminator",
    inventory_image = "terminator.png",
    stack_max = 1,
    groups = {tool=1},
    _mcl_toollike_wield = true,

    on_secondary_use = function(itemstack, player, pointed_thing)
        local playerpos = player:get_pos()
        local dir       = player:get_look_dir()
        local yaw       = player:get_look_horizontal()

        local damage = 10
        local power = 68

        local arrow_itemstring = "mcl_bows:arrow"

        local is_critical = true
        
		mcl_bows_s.shoot_arrow_crossbow(arrow_itemstring, {x=playerpos.x,y=playerpos.y+1.5,z=playerpos.z}, {x=dir.x, y=dir.y, z=dir.z + .2}, yaw, player, power, damage, is_critical, false)
		mcl_bows_s.shoot_arrow_crossbow(arrow_itemstring, {x=playerpos.x,y=playerpos.y+1.5,z=playerpos.z}, {x=dir.x, y=dir.y, z=dir.z - .2}, yaw, player, power, damage, is_critical, false)
		mcl_bows_s.shoot_arrow_crossbow(arrow_itemstring, {x=playerpos.x,y=playerpos.y+1.5,z=playerpos.z}, dir, yaw, player, power, damage, is_critical, false)
    end
})
