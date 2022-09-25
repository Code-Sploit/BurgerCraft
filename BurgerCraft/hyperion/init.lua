local function find(name, word)
    return string.match(name, word)
end

local function implode(placer)
    local radius = placer and 7 or 1
--    mcl_explosions.explode(placer:get_pos(), radius, {drop_chance=0}, placer)
    local pos = placer:get_pos()

    for _,obj in pairs(minetest.get_objects_inside_radius(pos, 6)) do
        if not obj:is_player() then
            local name = obj:get_luaentity().name

            if not find(name, "sign") and not find(name, "painting") and not find(name, "banner") then
                obj:remove()
            end
        end
    end
end

local function heal(placer)
	local hyp_last_healed = placer:get_meta():get("hyperion_last_healed") or 0

	if os.clock() - hyp_last_healed >= 10 or hyp_last_healed == 0 then
		placer:set_hp(placer:get_hp()+10)
	
		local time = os.clock()
		local player_meta = placer:get_meta():set_string("hyperion_last_healed", time)
	end
end

local function tpplayer(placer, pointing, pointed_thing)
    local pos = placer:get_pos()
    local look_dir = placer:get_look_dir()
    local distance = 5

    local new_pos = {}

    if not look_dir.x == 0 then
        new_pos = {x=pos.x+distance,y=pos.y,z=pos.z}
    end

    local pos_in_front = {x=pos.x+(look_dir.x * distance),y=pos.y+(look_dir.y * distance),z=pos.z+(look_dir.z * distance)}

    if not pointing then
      local closest_node = nil

      local raycast = minetest.raycast(vector.add(vector.add(pos, vector.new(0, 1.4, 0)), look_dir), vector.add(pos, vector.multiply(look_dir, distance)), true, false)

      for hitpoint in raycast do
        if hitpoint.type == "node" then
          if not closest_node or closest_node and vector.distance(pos, vector.offset(hitpoint.under, 0, 1, 0)) < vector.distance(pos, closest_node) then
            closest_node=vector.offset(hitpoint.under, 0, 1, 0)
          end
        end
      end

      if closest_node then
        local pos = vector.add(closest_node, vector.multiply(look_dir, -1))

        placer:set_pos(pos)
      else
        placer:set_pos(pos_in_front)
      end
    end

    if pointing then
      local pos = {x=pointed_thing.above.x, y=pointed_thing.above.y, z=pointed_thing.above.z}

      placer:set_pos(pos)
    end
end

function getHypAbilities(item)
	local metaData   = item:get_meta()

	local abilities  = {
		["implosion"]     = tonumber(metaData:get("implosion")),
		["shadow_warp"]   = tonumber(metaData:get("shadow_warp")),
		["wither_shield"] = tonumber(metaData:get("wither_shield"))
	}

	return abilities
end

minetest.register_craftitem("hyperion:ancient_rubble", {
	inventory_image = "ancient_rubble.png",
	description = "Ancient Rubble",
	stack_max = 16
})

minetest.register_craftitem("hyperion:handle", {
	inventory_image = "handle.png",
	description = "Handle",
	stack_max = 1
})

minetest.register_craftitem("hyperion:hyperion", {
    inventory_image = "hyperion.png",
    description = "Hyperion",
    stack_max = 1,
    groups = {tool=1},
    _mcl_toollike_wield = true,
	_hyperion_altar_index = 1,

    on_place = function(itemstack, placer, pointed_thing)
		local abilities = getHypAbilities(itemstack)

		if abilities.implosion == 1 then
			implode(placer)
		end

		if abilities.wither_shield == 1 then
			heal(placer)
		end

		if abilities.shadow_warp == 1 then
			tpplayer(placer, true, pointed_thing)
		end

	    minetest.sound_play("implosion", {gain=1})
    end,

    on_secondary_use = function(itemstack, placer, pointed_thing)
		local abilities = getHypAbilities(itemstack)

		if abilities.implosion == 1 then
			implode(placer)
		end

		if abilities.wither_shield == 1 then
			heal(placer)
		end

		if abilities.shadow_warp == 1 then
			tpplayer(placer, false, pointed_thing)
		end

	    minetest.sound_play("implosion", {gain=1})
    end,
})

minetest.register_craft({
	output = "hyperion:hyperion",
	recipe = {
		{"mcl_core:diamond", "mcl_core:diamond", "mcl_core:diamond"},
		{"hyperion:ancient_rubble", "mcl_core:diamond", "hyperion:ancient_rubble"},
		{"mcl_core:emerald", "hyperion:handle", "mcl_core:emerald"}
	}
})

-- SCROLLS

minetest.register_craftitem("hyperion:implosion", {
	inventory_image = "implosion.png",
	description = "Implosion Scroll",
	
	stack_max = 1,
	groups = {tool=1},
	_mcl_toollike_wield = true,
	_hyperion_altar_index = 2,
	_hyperion_scroll = "implosion"
})

minetest.register_craftitem("hyperion:shadow_warp", {
	inventory_image = "shadow_warp.png",
	description = "Shadow Warp Scroll",
	stack_max = 1,
	groups = {tool=1},
	_mcl_toollike_wield = true,
	_hyperion_altar_index = 2,
	_hyperion_scroll = "shadow_warp"
})

minetest.register_craftitem("hyperion:wither_shield", {
	inventory_image = "wither_shield.png",
	description = "Wither Shield Scroll",
	stack_max = 1,
	groups = {tool=1},
	_mcl_toollike_wield = true,
	_hyperion_altar_index = 2,
	_hyperion_scroll = "wither_shield"
})

minetest.register_craftitem("hyperion:altar_shard", {
	inventory_image = "altar_shard.png",
	description = "Altar Shard",
	stack_max = 64
})

minetest.register_node("hyperion:altar", {
	description = "Hyperion Altar",
	stack_max = 1,
	tiles = {"altar_top.png", "altar_base.png", "altar_side.png"},
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -6 / 16, -8 / 16, -6 / 16, 6 / 16, -4 / 16, 6 / 16 },
			{ -5 / 16, -4 / 16, -4 / 16, 5 / 16, -3 / 16, 4 / 16 },
			{ -4 / 16, -3 / 16, -2 / 16, 4 / 16, 2 / 16, 2 / 16 },
			{ -8 / 16, 2 / 16, -5 / 16, 8 / 16, 8 / 16, 5 / 16 },
		}
	},

	on_construct = function(pos)
		local meta 			= minetest.get_meta(pos)
		local inv 			= meta:get_inventory()

		inv:set_size("input", 2)
		inv:set_size("output", 1)

		local altarFormspec = "size[9,8.75]"..
			"background[-0.19,-0.25;9.41,9.49;mcl_anvils_inventory.png]"..
			"label[0,4.0;"..minetest.formspec_escape(minetest.colorize("#313131", "Inventory")).."]"..
			"list[current_player;main;0,4.5;9,3;9]"..
			mcl_formspec.get_itemslot_bg(0,4.5,9,3)..
			"list[current_player;main;0,7.74;9,1;]"..
			mcl_formspec.get_itemslot_bg(0,7.74,9,1)..
			"list[context;input;1,2.5;1,1;]"..
			mcl_formspec.get_itemslot_bg(1,2.5,1,1)..
			"list[context;input;4,2.5;1,1;1]"..
			mcl_formspec.get_itemslot_bg(4,2.5,1,1)..
			"list[context;output;8,2.5;1,1;]"..
			mcl_formspec.get_itemslot_bg(8,2.5,1,1)..
			"label[3,0.1;"..minetest.formspec_escape(minetest.colorize("#313131", "Add Scroll")).."]"..
			"listring[context;output]"..
			"listring[current_player;main]"..
			"listring[context;input]"..
			"listring[current_player;main]"

		meta:set_string("formspec", altarFormspec)
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
	
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		return stack:get_count()
	end,
	
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname == "output" then
			return 0
		end

		local def = stack:get_definition()

		if not def then
			return 0
		end

		if index ~= def._hyperion_altar_index then
			return 0
		end

		return stack:get_count()
	end,

	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		local inv = minetest.get_meta(pos):get_inventory()
		inv:set_stack("output", 1, ItemStack())

		local hyp    = inv:get_stack("input", 1)
		local scroll = inv:get_stack("input", 2)

		if hyp:is_empty() or scroll:is_empty() then
			return
		end

		local scrollDef = scroll:get_definition()

		if not scrollDef or not scrollDef._hyperion_scroll then
			return
		end

		local hypMeta = hyp:get_meta()
		local scrollMeta = scroll:get_meta()

		if hypMeta:get(scrollDef._hyperion_scroll) then
			return
		end

		hypMeta:set_string(scrollDef._hyperion_scroll, "1")
		
		inv:set_stack("output", 1, hyp)
	end,

	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		local inv = minetest.get_meta(pos):get_inventory()

		if listname == "output" then
			inv:set_stack("input", 1, ItemStack())
			inv:set_stack("input", 2, ItemStack())
		else
			inv:set_stack("output", 1, ItemStack())
		end
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local meta = minetest.get_meta(pos)
		local meta2 = meta:to_table()

		meta:from_table(oldmetadata)

		local inv = meta:get_inventory()

		for i = 1, 2 do
			local stack = inv:get_stack("input", i)
			if not stack:is_empty() then
				local p = {x=pos.x+math.random(0, 10)/10-0.5, y=pos.y, z=pos.z+math.random(0, 10)/10-0.5}
				minetest.add_item(p, stack)
			end
		end
	
		meta:from_table(meta2)
	end,
})

minetest.register_craft({
	output = "hyperion:altar",
	recipe = {
		{"mcl_core:iron_ingot", "mcl_core:diamond", "mcl_core:iron_ingot"},
		{"mcl_core:diamond", "hyperion:altar_shard", "mcl_core:diamond"},
		{"mcl_core:iron_ingot", "mcl_core:diamond", "mcl_core:iron_ingot"}
	}
})
