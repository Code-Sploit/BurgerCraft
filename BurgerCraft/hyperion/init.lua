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

function applyScroll(item, scroll)
	local metaData = item:get_meta()

	metaData:set_string("HYPERION_SCROLL_APPLIED_" .. string.upper(scroll), "1")
end

function getHypAbilities(item)
	local metaData   = item:get_meta()
	local abilities  = {
		["implosion"]     = tonumber(metaData:get("HYPERION_SCROLL_APPLIED_IMPLOSION")),
		["shadow_warp"]   = tonumber(metaData:get("HYPERION_SCROLL_APPLIED_SHADOW_WARP")),
		["wither_shield"] = tonumber(metaData:get("HYPERION_SCROLL_APPLIED_WITHER_SHIELD"))
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
    stackable = false,
    stack_max = 1,
    groups = {tool=1},
    _mcl_toollike_wield = true,

    on_place = function(itemstack, placer, pointed_thing)
		local abilities = getHypAbilities(itemstack)

		minetest.log(itemstack:get_meta():get("HYPERION_SCROLL_APPLIED_IMPLOSION"))

		for ability in pairs(abilities) do
			minetest.log(ability)
		end

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

		for ability in pairs(abilities) do
			minetest.log(ability)
		end

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
	stackable = false,
	stack_max = 1,
	groups = {tool=1},
	_mcl_toollike_wield = true
})

minetest.register_craftitem("hyperion:shadow_warp", {
	inventory_image = "shadow_warp.png",
	description = "Shadow Warp Scroll",
	stackable = false,
	stack_max = 1,
	groups = {tool=1},
	_mcl_toollike_wield = true
})

minetest.register_craftitem("hyperion:wither_shield", {
	inventory_image = "wither_shield.png",
	description = "Wither Shield Scroll",
	stackable = false,
	stack_max = 1,
	groups = {tool=1},
	_mcl_toollike_wield = true
})

-- TEMP CHAT CMD

minetest.register_chatcommand("applyscrolls", {
	func = function(name, param)
		local player    = minetest.get_player_by_name(name)
		local held_item = player:get_wielded_item()

		applyScroll(held_item, "implosion")
		applyScroll(held_item, "wither_shield")
		applyScroll(held_item, "shadow_warp")
	end
})
