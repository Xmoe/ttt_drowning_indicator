AddCSLuaFile()

-- https://steamcommunity.com/sharedfiles/filedetails/?id=481440358
WORKSHOP_ID = "481440358"

if SERVER then

	-- if the plugin is installed on the server, tell the clients to install it as well
	resource.AddWorkshop(WORKSHOP_ID)

end

if CLIENT then

	-----------------------------Init--------------------------

	local MAX_AIR_TIME_SECONDS = 8
	local MAX_NUMBER_OF_BUBBLES_TO_DRAW = 9		-- chosen by experimentation: the timing and size of the bubbles both fit

	local BUBBLE_DISTANCE_PIXELS = 4
	local BUBBLE_TEXTURE_SIZE_PIXELS = 8		-- the texture is 8 by 8 pixels big
	local SCALING_FACTOR = 3
	local BUBBLE_OFFSET_PIXELS = BUBBLE_DISTANCE_PIXELS + BUBBLE_TEXTURE_SIZE_PIXELS*SCALING_FACTOR	-- offset between each bubble texture

	-- (0,0) is the top left corner of the screen
	-- the positions are hardcoded for a 1920x1080 screen and positioned over the basic HUD (garrysmod\gamemodes\terrortown\gamemode\cl_hud.lua)
	local X_POSITION_SCALED = 0.005				-- distance to left screen edge as a factor of the screen size
	local Y_POSITION_SCALED = 0.855				-- distance to top screen edge as a factor of the screen size

	local BUBBLE_TEXTURE = surface.GetTextureID("bubble")

	------------------------Functions--------------------------

	local function draw_bubbles(number_of_bubbles)
		-- re-calculate every frame, in case the settings slider has been changed (TODO: instead fire a hook?)
		bubble_size_pixels = BUBBLE_TEXTURE_SIZE_PIXELS*SCALING_FACTOR

		-- set full color spectrum
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetTexture(BUBBLE_TEXTURE)

		for i=0, number_of_bubbles-1, 1 do
			x_coordinate = X_POSITION_SCALED*ScrW() + i*BUBBLE_OFFSET_PIXELS
			y_coordinate = Y_POSITION_SCALED*ScrH()
			surface.DrawTexturedRect(x_coordinate, y_coordinate, bubble_size_pixels, bubble_size_pixels)
		end
	end

	local function on_draw_ui()
		is_player_diving = (LocalPlayer():WaterLevel() == 3)
		is_player_spectator = LocalPlayer():IsSpec()

		if is_player_diving and not is_player_spectator then

			-- this is only executed if the player was not diving the frame before
			if not diving_timestamp then
				diving_timestamp = CurTime()
			end

			diving_time_seconds = CurTime() - diving_timestamp

			-- percentage scaled up to number between 0 and 99
			percentage_of_air = (MAX_AIR_TIME_SECONDS - diving_time_seconds) * 100 / MAX_AIR_TIME_SECONDS -1 -- subtract 1 to avoid rare cases of drawing one bubble to many for one frame

			-- add 1 to MAX_NUMBER_OF_BUBBLES_TO_DRAW as a "fake" bubble to add a delay before taking damage after no more bubbles are being drawn
			number_of_bubbles = math.floor(percentage_of_air / (MAX_NUMBER_OF_BUBBLES_TO_DRAW+1))

			draw_bubbles(number_of_bubbles)
		else
			-- if the player is no longer diving, reset the timestamp and number_of_bubbles
			diving_timestamp = nil
			number_of_bubbles = 0
		end
	end

	------------------Saving & Loading Settings----------------

	local file_location = "drowning_indicator/settings.txt"

	local function save_options()
		local save_data = {X_POSITION_SCALED, Y_POSITION_SCALED, SCALING_FACTOR, BUBBLE_DISTANCE_PIXELS}
		if not file.Exists(file_location, "DATA") then
			file.CreateDir("drowning_indicator")
		end	
		local temp_data = string.Implode(";", save_data)
		file.Write(file_location, temp_data)
		print("[Info|TTT Drowning Indicator] Saved drowning indicator settings.")
	end

	local function load_options()
		if file.Exists(file_location, "DATA") then 
			local load_data = file.Read(file_location)
			load_data = string.Explode(";", load_data)
			X_POSITION_SCALED = tonumber(load_data[1])
			Y_POSITION_SCALED = tonumber(load_data[2])
			SCALING_FACTOR = tonumber(load_data[3])
			BUBBLE_DISTANCE_PIXELS = tonumber(load_data[4])
			BUBBLE_OFFSET_PIXELS = BUBBLE_DISTANCE_PIXELS + BUBBLE_TEXTURE_SIZE_PIXELS*SCALING_FACTOR
		end
	end

	local function delete_options()
		file.Delete(file_location)
	end

	--------------------------------Settings Tab-------------------------------

	local button_enabled = false	-- because OnChange always returns true, regardless of the value. Stupid bug

	local function preview_enable()
		hook.Add("HUDPaint", "drowning_indicator_preview", function()
			draw_bubbles(MAX_NUMBER_OF_BUBBLES_TO_DRAW)
		end)
	end

	local function preview_disable()
		hook.Remove("HUDPaint", "drowning_indicator_preview")
	end

	local function preview_toggle(_bool)
		button_enabled = not button_enabled
		if button_enabled then
			preview_enable()
		else
			preview_disable()
		end
	end

	local function create_slider(text, min, max, default, decimals, on_change)
		local slider = vgui.Create( "DNumSlider" )
		slider:SetText(text)
		slider:SetMin(min)
		slider:SetMax(max)
		slider:SetValue(default)
		slider:SetDecimals(decimals)
		slider.OnValueChanged = on_change
		return slider
	end

	local function add_settings_tab()
		hook.Add("TTTSettingsTabs", "drowning_indicator_settings", function(dtabs)
			local settings_panel = vgui.Create("DPanel", dtabs)
			settings_panel:StretchToParent(0, 0, 0, 0)
			settings_panel:SetPaintBackground(false)
			dtabs:AddSheet("Drowning Indicator", settings_panel, "bubble.vtf", false, false, "Adjust the position and size of the hud")

			settings_panel:GetParent():GetParent().OnClose = function()
				preview_disable()
				button_enabled = false
			end

			--parent_frame = settings_panel:GetParent():GetParent()

			local settings_form = vgui.Create("DForm", settings_panel)
			settings_form:StretchToParent(10, 10, 10, 10)
			settings_form:SetSpacing(10)
			settings_form:SetName("HUD Settings")

			local debug_button = vgui.Create("DCheckBoxLabel")
			debug_button:SetText("Show preview")
			debug_button:SetValue(button_enabled)
			debug_button.OnChange = preview_toggle

			local x_pos_slider = create_slider("X Position", 0, 1, X_POSITION_SCALED, 3, function(p, value)
				X_POSITION_SCALED = value
			end)

			local y_pos_slider = create_slider("Y Postion", 0, 1, Y_POSITION_SCALED, 3, function(p, value)
				Y_POSITION_SCALED = value
			end)

			local bubble_size_slider = create_slider("Texture Size", 1, 10, SCALING_FACTOR, 0, function(p, value)
				SCALING_FACTOR = math.floor(value)
				BUBBLE_OFFSET_PIXELS = BUBBLE_DISTANCE_PIXELS + BUBBLE_TEXTURE_SIZE_PIXELS*SCALING_FACTOR
			end)

			local bubble_distance_slider = create_slider("Texture Offset", 0, 30, BUBBLE_DISTANCE_PIXELS, 0, function(p, value)
				BUBBLE_DISTANCE_PIXELS = math.floor(value)
				BUBBLE_OFFSET_PIXELS = BUBBLE_DISTANCE_PIXELS + BUBBLE_TEXTURE_SIZE_PIXELS*SCALING_FACTOR
			end)

			local save_button = vgui.Create("DButton")
			save_button:SetText("Save settings")
			save_button.DoClick = save_options

			local reset_button = vgui.Create("DButton")
			reset_button:SetText("Reset settings. This applies after rejoining the server.")
			reset_button.DoClick = delete_options

			settings_form:AddItem(debug_button)
			settings_form:AddItem(x_pos_slider)
			settings_form:AddItem(y_pos_slider)
			settings_form:AddItem(bubble_size_slider)
			settings_form:AddItem(bubble_distance_slider)
			settings_form:AddItem(save_button)
			settings_form:AddItem(reset_button)
		end)
	end

	----------------------------------Main-----------------------------------

	-- console commands for testing: 
	-- ttt_debug_preventwin 1; ttt_firstpreptime 0; ttt_preptime_seconds 0; ttt_posttime_seconds 0; ttt_minimum_players 1

	hook.Add("InitPostEntity", "drowning_indicator_start", function()
		if gmod.GetGamemode().ThisClass == "gamemode_terrortown" then

			load_options()
			-- call the function to draw the indicator every frame when the ui is being drawn
			hook.Add("HUDPaint", "drowning_indicator_draw_ui", on_draw_ui)
			add_settings_tab()

			print("[Info|TTT Drowning Indicator] Made by Moe for the gmod-networks.net community :)")
			print("[Info|TTT Drowning Indicator] Loaded successfully.")
		end
	end)

end