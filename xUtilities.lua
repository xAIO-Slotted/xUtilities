local name = "xUtils"
local version = "0.1.2"

local add_nav = menu.get_main_window():push_navigation(name + " " + version, 10000)
local navigation = menu.get_main_window():find_navigation(name + " " + version)

-- Sections
local safety_sec = navigation:add_section("Safety")
local vision_sec = navigation:add_section("Vision")
local misc_sec = navigation:add_section("Misc")
local humanizer_sec = navigation:add_section("Humanizer")

-- Safety
local anti_wall_flash = safety_sec:checkbox("stop flash fails", g_config:add_bool(true, "anti_wall_flash"))
local anti_short_flash = safety_sec:checkbox("auto extend flash", g_config:add_bool(true, "anti_short_flash"))
local safe_flash_key = safety_sec:slider_int("Flash key [DEFAULT: U, 85]:", g_config:add_int(85, "safe_flash_key"), 0, 179, 1)

-- Misc
local anti_lantern = misc_sec:checkbox("place wards on lantern", g_config:add_bool(true, "anti_lantern"))

function circlePoints(from, distance, quality)
  local points = {}
  for i = 1, quality do
      local angle = i * 2 * math.pi / quality
      local point = vec3:new(from.x + distance * math.cos(angle), from.y + distance * math.sin(angle), from.z)
      table.insert(points, point)
  end
  return points
end

function zero(v)
  return v.x == 0 and v.y == 0 and v.z == 0
end

function modules.safeFlashing()

  if g_input:is_key_pressed(safe_flash_key:get_value()) then

    local spell_book = g_local:get_spell_book()

    local slot = e_spell_slot.d

    if not spell_book:get_spell_slot(e_spell_slot.d):get_name() == "SummonerFlash" then
      slot = e_spell_slot.f
    end
    
    local fail = g_navgrid:is_wall(g_input:get_cursor_position_game())  or g_navgrid:is_building(g_input:get_cursor_position_game())
      
    if spell_book:get_spell_slot(slot):get_name() == "SummonerFlash" then
      
      local dis = math.min(400, g_local.position:dist_to(g_input:get_cursor_position_game()))
      if anti_short_flash:get_value() and not fail and dis <= 399 then
        g_input:cast_spell(slot, g_local.position:extend(g_local.position:extend(g_input:get_cursor_position_game(), dis), 400))
        return
      end

      if anti_wall_flash:get_value() and fail then

        local inWall = true
        local impossible = false
        local closest = math.huge
        local walkPos = vec3:new(0,0,0)
        local flashPos = vec3:new(0,0,0)
        local cursor = g_input:get_cursor_position_game()

        for i = 40, 400, 40 do

          local points = circlePoints(cursor, i, 360)

          for _, point in ipairs(points) do
              if not g_navgrid:is_wall(point) and not g_navgrid:is_building(point) then
                  impossible = true
                  local pointDist = g_local.position:dist_to(point)

                  if zero(walkPos) and cursor:dist_to(point) < closest then
                      closest = cursor:dist_to(point)
                      inWall = false
                      flashPos = point
                  end

                  if pointDist < dis and (zero(walkPos) or g_local.position:dist_to(walkPos) > g_local.position:dist_to(point)) then
                      inWall = true
                      walkPos = point
                  end
              end
            end
            if impossible then break end
          end

          if inWall and not zero(walkPos) then
            g_input:issue_order_move(walkPos)
            return

          elseif not zero(flashPos) then
            g_input:cast_spell(slot, flashPos)
            return

          end
        end
      else
        print("xUtils: Unable to safe-flash without flash.")
        return
      end
  end
end

function modules.lantern()

  if anti_lantern:get_value() then
		local control_ward_slot = e_spell_slot.item4
		objects = features.entity_list:ally_uncategorized() -- TODO: change back to: enemy_uncategorized()
		for _, minion in ipairs(objects) do
			if minion.is_enemy and minion:dist_to(g_local.position) <= 600 and minion.object_name == "ThreshLantern" then
				g_input:cast_spell(control_ward_slot, vec3:new(minion.position.x, minion.position.y, minion.position.z))
        break
			end
		end
	end

end

cheat.on("features.run", function()

  modules.safeFlashing()
  modules.lantern()
  
end)

cheat.on("renderer.draw", function()

  if g_local.position == nil then
  end

end)