AddCSLuaFile()

-- https://steamcommunity.com/sharedfiles/filedetails/?id=481440358
WORKSHOP_ID = "481440358"

if SERVER then

	-- if the plugin is installed on the server, tell the clients to install it as well
	resource.AddWorkshop(WORKSHOP_ID)

end

if CLIENT then
	-------- Init --------

	---- Constants ----

	local MAX_AIR_TIME_SECONDS = 8				-- found somewhere in Source™ Code
	local MAX_NUMBER_OF_BUBBLES_TO_DRAW = 9		-- chosen by experimentation: the timing and size of the bubbles both fit

	local BUBBLE_TEXTURE = surface.GetTextureID("bubble")
	local BUBBLE_TEXTURE_SIZE_PIXELS = surface.GetTextureSize(BUBBLE_TEXTURE)	-- assume the texture is square

	---- Defaults ----

	-- (0,0) is the top left corner of the screen
	-- the positions are hardcoded for a 1920x1080 screen and positioned over the basic HUD (garrysmod\gamemodes\terrortown\gamemode\cl_hud.lua)
	local X_POSITION_SCALED_DEFAULT = 0.005		-- distance to left screen edge as a factor of the screen size
	local Y_POSITION_SCALED_DEFAULT = 0.855		-- distance to top screen edge as a factor of the screen size

	local BUBBLE_MARGIN_PIXELS_DEFAULT = 4
	local BUBBLE_SIZE_FACTOR_DEFAULT = 3

	---- Settings ----

	local x_position_factor = X_POSITION_SCALED_DEFAULT
	local y_position_factor = Y_POSITION_SCALED_DEFAULT
	local bubble_margin_pixels = BUBBLE_MARGIN_PIXELS_DEFAULT
	local bubble_size_factor = BUBBLE_SIZE_FACTOR_DEFAULT

	------------------------Functions--------------------------

	local function get_bubble_offset_pixels()
		return bubble_margin_pixels + BUBBLE_TEXTURE_SIZE_PIXELS*bubble_size_factor	-- offset between each bubble texture
	end

	local function draw_bubbles(number_of_bubbles)
		-- re-calculate every frame, in case the settings slider has been changed (TODO: instead fire a hook?)
		bubble_size_pixels = BUBBLE_TEXTURE_SIZE_PIXELS*bubble_size_factor

		-- set full color spectrum
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetTexture(BUBBLE_TEXTURE)

		for i=0, number_of_bubbles-1, 1 do
			x_coordinate = x_position_factor*ScrW() + i*get_bubble_offset_pixels()
			y_coordinate = y_position_factor*ScrH()
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

	local function save_settings()
		local save_data = {x_position_factor, y_position_factor, bubble_size_factor, bubble_margin_pixels}
		if not file.Exists(file_location, "DATA") then
			file.CreateDir("drowning_indicator")
		end	
		local temp_data = string.Implode(";", save_data)
		file.Write(file_location, temp_data)
	end

	local function load_settings()
		if file.Exists(file_location, "DATA") then 
			local load_data = file.Read(file_location)
			load_data = string.Explode(";", load_data)
			x_position_factor = tonumber(load_data[1])
			y_position_factor = tonumber(load_data[2])
			bubble_size_factor = tonumber(load_data[3])
			bubble_margin_pixels = tonumber(load_data[4])
		end
	end

	--------------------------------Settings Tab-------------------------------

	local function show_preview(_bool)
		if _bool then
			hook.Add("HUDPaint", "drowning_indicator_preview", function()
				draw_bubbles(MAX_NUMBER_OF_BUBBLES_TO_DRAW)
			end)
		else
			hook.Remove("HUDPaint", "drowning_indicator_preview")
		end
	end

	local function create_slider(text, min, max, current_value, default, decimals, on_change)
		local slider = vgui.Create("DNumSlider")
		slider:SetText(text)
		slider:SetMin(min)
		slider:SetMax(max)
		slider:SetValue(current_value)
		slider:SetDefaultValue(default)
		slider:SetDecimals(decimals)
		slider.OnValueChanged = on_change
		return slider
	end

	local function add_settings_tab()
		hook.Add("TTTSettingsTabs", "drowning_indicator_settings", function(dtabs)
			local settings_panel = vgui.Create("DPanel", dtabs)
			settings_panel:StretchToParent(0, 0, 0, 0)
			settings_panel:SetPaintBackground(false)
			dtabs:AddSheet("Drowning Indicator", settings_panel, "bubble.vtf", false, false, "Adjust the position and size of the HUD")

			--parent_frame = settings_panel:GetParent():GetParent()

			local settings_form = vgui.Create("DForm", settings_panel)
			settings_form:StretchToParent(10, 10, 10, 10)
			settings_form:SetSpacing(10)
			settings_form:SetName("HUD Settings")

			local debug_button = vgui.Create("DCheckBoxLabel")
			debug_button:SetText("Show preview")
			debug_button:SetValue(button_enabled)
			function debug_button:OnChange(button_is_checked) 
				show_preview(button_is_checked)
			end

			local x_pos_slider = create_slider("X Position", 0, 1, x_position_factor, X_POSITION_SCALED_DEFAULT, 3, function(p, value)
				x_position_factor = value
			end)

			local y_pos_slider = create_slider("Y Postion", 0, 1, y_position_factor, Y_POSITION_SCALED_DEFAULT, 3, function(p, value)
				y_position_factor = value
			end)

			local bubble_size_slider = create_slider("Texture Size", 1, 10, bubble_size_factor, BUBBLE_SIZE_FACTOR_DEFAULT, 0, function(p, value)
				bubble_size_factor = math.floor(value)
			end)

			local bubble_margin_slider = create_slider("Texture Offset", 0, 30, bubble_margin_pixels, BUBBLE_MARGIN_PIXELS_DEFAULT, 0, function(p, value)
				bubble_margin_pixels = math.floor(value)
			end)

			local reset_button = vgui.Create("DButton")
			reset_button:SetText("Load defaults")
			reset_button.DoClick = function() 
				x_pos_slider:SetValue(X_POSITION_SCALED_DEFAULT)
				y_pos_slider:SetValue(Y_POSITION_SCALED_DEFAULT)
				bubble_size_slider:SetValue(BUBBLE_SIZE_FACTOR_DEFAULT)
				bubble_margin_slider:SetValue(BUBBLE_MARGIN_PIXELS_DEFAULT)
			end

			local save_button = vgui.Create("DButton")
			save_button:SetText("Save settings")
			save_button.DoClick = save_settings

			settings_panel:GetParent():GetParent().OnClose = function()
				show_preview(false)
			end

			settings_form:AddItem(debug_button)
			settings_form:AddItem(x_pos_slider)
			settings_form:AddItem(y_pos_slider)
			settings_form:AddItem(bubble_size_slider)
			settings_form:AddItem(bubble_margin_slider)
			settings_form:AddItem(reset_button)
			settings_form:AddItem(save_button)
		end)
	end

	----------------------------------Main-----------------------------------

	-- console commands for testing: 
	-- ttt_debug_preventwin 1; ttt_firstpreptime 0; ttt_preptime_seconds 0; ttt_posttime_seconds 0; ttt_minimum_players 1

	hook.Add("InitPostEntity", "drowning_indicator_start", function()
		if gmod.GetGamemode().ThisClass == "gamemode_terrortown" then

			load_settings()
			add_settings_tab()
			-- call the function to draw the indicator every frame when the ui is being drawn
			hook.Add("HUDPaint", "drowning_indicator_draw_ui", on_draw_ui)

			print("[Info|TTT Drowning Indicator] Made by Moe for the gmod-networks.net community :)")
			print("[Info|TTT Drowning Indicator] Loaded successfully.")
		end
	end)

end