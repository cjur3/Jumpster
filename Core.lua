jump_mod = jump_mod or {}
jump_mod._path = ModPath
jump_mod._data_path = SavePath .. "jump_mod.txt"
jump_mod._data = {}

jump_mod._sounds = {"Whoosh_SFX_01", "Whoosh_SFX_02", "Whoosh_SFX_03", "Whoosh_SFX_04", "Whoosh_SFX_05",
                    "Whoosh_SFX_06", "Whoosh_SFX_07", "Whoosh_SFX_08", "Whoosh_SFX_09", "Whoosh_SFX_10",
                    "Whoosh_SFX_11", "Whoosh_SFX_12", "Whoosh_SFX_13", "Whoosh_SFX_14", "Whoosh_SFX_15",
                    "Whoosh_SFX_16", "Whoosh_SFX_17", "Whoosh_SFX_18", "Whoosh_SFX_19", "Whoosh_SFX_20",
                    "Whoosh_SFX_21", "Whoosh_SFX_22", "Whoosh_SFX_23", "Whoosh_SFX_24", "Whoosh_SFX_25", "Whoosh_SFX_26"}

function jump_mod:Save()
    local file = io.open(self._data_path, "w+")
    if file then
        file:write(json.encode(self._data))
        file:close()
    end
end

function jump_mod:Load()
    local file = io.open(self._data_path, "r")
    if file then
        self._data = json.decode(file:read("*all"))
        file:close()
    else
        log("No previous save found. Creating new using default values")
        local default_file = io.open(self._path .. "Menu/default_values.json")
        if default_file then
            self._data = json.decode(default_file:read("*all"))
            self:Save()
        end
    end
end

function jump_mod:playSound(id)
    local peer = managers.network and managers.network:session():peer(i) or nil
    if (peer and peer == managers.network:session():local_peer()) or Global.game_settings.single_player then
        local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
        if hud and hud.panel then
            if PackageManager:has(Idstring("movie"), Idstring(id)) then
                if alive(hud.panel:child("ids_" .. id)) then
                    hud.panel:remove(hud.panel:child("ids_" .. id))
                end
                local volume = managers.user:get_setting("sfx_volume")
                local percentage = (volume - tweak_data.menu.MIN_SFX_VOLUME) /
                                       (tweak_data.menu.MAX_SFX_VOLUME - tweak_data.menu.MIN_SFX_VOLUME)
                hud.panel:video({
                    name = "ids_" .. id,
                    video = id,
                    visible = false,
                    loop = false
                }):set_volume_gain(math.min(percentage * 3, 1))
            end
        end
    end
end

if not jump_mod.setup then
    jump_mod:Load()
    jump_mod.setup = true
    log("Jump Mod loaded")
end

function add_boolean_callback(callbackName, valueName)
    MenuCallbackHandler[callbackName] = function(self, item)
        jump_mod._data[valueName] = (item:value() == "on")
        jump_mod:Save()
    end
end

function add_callback(callbackName, valueName)
    MenuCallbackHandler[callbackName] = function(self, item)
        jump_mod._data[valueName] = item:value()
        jump_mod:Save()
    end
end

Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_JumpModHook", function(loc)
    LocalizationManager:load_localization_file(jump_mod._path .. "loc/en.json")
end)

Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_jump_mod", function(menu_manager)
    add_boolean_callback("fall_damage_callback", "fall_damage")
    add_boolean_callback("full_charge_feedback_callback", "full_charge_feedback")
    add_boolean_callback("dash_callback", "dash_feedback")
    add_callback("jump_style_callback", "jump_style")
    add_callback("jump_range_callback", "jump_range")
    add_callback("jump_height_multiplicator_callback", "jump_height_multiplicator")
    add_callback("jump_height_max_multiplicator_callback", "jump_height_max_multiplicator")
    add_callback("dash_sound_callback", "dash_sound")
    add_callback("stamina_drain_callback", "stamina_drain")
    add_callback("dash_stamina_drain_callback", "dash_stamina_drain")
    add_callback("jump_charged_sound_callback", "jump_charged_sound")
    

    jump_mod:Load()
    MenuHelper:LoadFromJsonFile(jump_mod._path .. "Menu/menu.json", jump_mod, jump_mod._data)
end)
