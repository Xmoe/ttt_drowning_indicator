AddCSLuaFile()

if SERVER then
	
	resource.AddWorkshop( "481440358" ) --sicherstellen, dass das die richtige ID ist!

end

if CLIENT then

	-----------------------------Init--------------------------
	local air_time = 8					  --Wie viele Sekunden der Spieler keinen Schaden nimmt

	local bubble_distance = 4			--Abstand zwischen Blasen
	local size_multiplier = 3
	local render_size = 8                --Wie groß die Textur gerendert wird
	local bubble_offset = bubble_distance + render_size*size_multiplier  --Eigentliches Offset für den ABstand zwischen den Blasen
	local render_x = 0.005       --Wie weit vom linken Bildschrimrand die (erste) Textur gerendert wird
	local render_y = 0.855      --Auf welcher Höhe die (erste) Textur gerendert wird //-100 habe ich aus \SteamApps\common\GarrysMod\garrysmod\gamemodes\terrortown\gamemode\cl_hud.lua kopiert. Das anderes beides ist das Offset für die Blasen
	local bubble_texture = surface.GetTextureID("bubble")  --die eigentliche Textur

	local time_offset = -11 --diese Variable sorgt dafür, dass nachdem die letzte Luftblase verschwunden ist man nicht sofort Schaden bekommt. -11 ist ein sehr gut geeigneter Wert.
	 
	local function simulate_drowning()   --Kopie des serverseitigen Verhaltens der drowning Variable
	  if LocalPlayer():WaterLevel() == 3 then     --Wenn der Spieler im Wasser ist
		if not drowning then            --und die Variable noch nicht gesetzt wurde
		  drowning = CurTime() + air_time  --gib dem Spieler einen Zeitpunkt in der Zukunft, an dem er ertrinkt (normalerweise 8 Sekunden)
		end
	  else
		drowning = nil  --Wenn der Spieler nicht mehr im Wasser ist, dann brauch er auch nicht zu ertrinken
	  end
	end
	 
	local function get_air_level()    --errechnet wie viel Luft der Spieler noch hat.
	  if drowning then   --wenn der Spieler unter Wasser ist
		return (drowning - CurTime()) * (100/air_time) --eigentliche Berechnung
	  else
		return nil   --Wenn der Spieler nicht ertrinkt, dann hat die Variable auch keinen Wert
	  end
	end
	
	local function render_bubbles(amount)
		surface.SetDrawColor( 255, 255, 255, 255 ) --die Textur soll mit vollem Farbspektrum gerendert werden
		surface.SetTexture(bubble_texture) --lade die Textur in den Buffer   
		i = 0
		while i < amount do
			surface.DrawTexturedRect( render_x * ScrW() + i*bubble_offset, render_y * ScrH(), render_size*size_multiplier, render_size*size_multiplier ) --male jede Blase mit ihrem jeweiligen offset
			i = i + 1
		end
	end
	
	local function draw_indicator()
		hook.Add("HUDPaint", "drowning_indicator_main", function() --jeden Frame wird dieser COdeblock ausgeführt
			simulate_drowning()
			local air_level = get_air_level() --Variable berechnen
			
			if air_level && air_level > 0 && not LocalPlayer():IsSpec() then --Falls der Spieler unter Wasser ist und noch lebt
				amount_of_bubbles = (air_level+time_offset)/10 --setze die Anzahl der Blasen entsprechend der übrigen Luft
				render_bubbles(amount_of_bubbles)
			end
		end)
	end
	 
	-----------------------Saving & Loading Settings------------------------
	
	local file_location = "drowning_indicator/settings.txt"
	
	local function save_options()
		local save_data = {render_x,render_y,size_multiplier,bubble_distance}
		if not file.Exists(file_location, "DATA") then
			file.CreateDir("drowning_indicator")
		end	
		local temp_data = string.Implode(";",save_data)
		file.Write(file_location,temp_data)
		print("Saved drowning indicator settings!")
	end

	local function load_options()
		if file.Exists(file_location, "DATA") then 
			local load_data = file.Read(file_location)
			load_data = string.Explode(";", load_data)
			render_x = tonumber(load_data[1])
			render_y = tonumber(load_data[2])
			size_multiplier = tonumber(load_data[3])
			bubble_distance = tonumber(load_data[4])
			bubble_offset = bubble_distance + render_size*size_multiplier
		end
	end
	
	local function delete_options()
		file.Delete(file_location)
	end
	
	--------------------------------Settings Tab-------------------------------
	
	local button_enabled = false	//because OnChange always returns true, regardless of the value. Stupid bug
	
	local function preview_enable()
		hook.Add("HUDPaint", "drowning_indicator_preview", function()
			render_bubbles(9)
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

	local function create_slider(text,min,max,default,decimals,on_change)
		local slider = vgui.Create( "DNumSlider" )
		slider:SetText( text )
		slider:SetMin( min )
		slider:SetMax( max )
		slider:SetValue( default )
		slider:SetDecimals( decimals )
		slider.OnValueChanged = on_change
		return slider
	end

	local function add_settings_tab()
		hook.Add("TTTSettingsTabs", "drowning_settings", function(dtabs)	
			local settings_panel = vgui.Create( "DPanel",dtabs )
			settings_panel:StretchToParent(0,0,0,0)
			settings_panel:SetPaintBackground(false)
			dtabs:AddSheet( "Drowning Indicator", settings_panel, "bubble.vtf", false, false, "Adjust the position and size of the hud")
			
			settings_panel:GetParent():GetParent().OnClose = function()
				preview_disable()
				button_enabled = false
			end
			
			//parent_frame = settings_panel:GetParent():GetParent()
			
			local settings_form = vgui.Create( "DForm", settings_panel )
			settings_form:StretchToParent(10,10,10,10)
			settings_form:SetSpacing( 10 )
			settings_form:SetName( "HUD Settings" )
			
			local debug_button = vgui.Create( "DCheckBoxLabel" )
			debug_button:SetText("Enable preview rendering?")
			debug_button:SetValue(button_enabled)
			debug_button.OnChange = preview_toggle
			
			local x_pos_slider = create_slider("X Position",0,1,render_x,3,function(p,value)
				render_x = value
			end)
			local y_pos_slider = create_slider("Y Postion",0,1,render_y,3,function(p,value)
				render_y = value
			end)
			local bubble_size = create_slider("Texture Size",1,10,size_multiplier,0,function(p,value)
				size_multiplier = math.floor(value) 
				bubble_offset = bubble_distance + render_size*size_multiplier
			end)
			local bubble_distance = create_slider("Texture Offset",0,30,bubble_distance,0,function(p,value)
				bubble_distance = math.floor(value)
				bubble_offset = bubble_distance + render_size*size_multiplier
			end)
			
			local save_button = vgui.Create("DButton")
			save_button:SetText("Save settings")
			save_button.DoClick = save_options
			
			local reset_button = vgui.Create("DButton")
			reset_button:SetText("Reset settings. This applies after rejoining the server.")
			reset_button.DoClick = delete_options
			
			settings_form:AddItem( debug_button )
			settings_form:AddItem( x_pos_slider )
			settings_form:AddItem( y_pos_slider )
			settings_form:AddItem( bubble_size )
			settings_form:AddItem( bubble_distance )
			settings_form:AddItem( save_button )
			settings_form:AddItem( reset_button )
		end)
	end
	
	----------------------------------Main-----------------------------------
	local function main()
		load_options()
		draw_indicator()
		add_settings_tab()
	end
	
	hook.Add( "InitPostEntity", "drowning_indicator_start", function()
		if gmod.GetGamemode().Name == "Trouble in Terrorist Town" then
			print("[LOADED] TTT Drowning Indicator by Moe for the gmod-networks.net community.")
			main()
		end
	end)

end