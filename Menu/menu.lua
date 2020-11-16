jump_mod = jump_mod or {}
jump_mod._path = ModPath
jump_mod._data_path = SavePath .. "jump_mod.txt"
jump_mod._data = {}

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
    LocalizationManager:load_localization_file( jump_mod._path .. "loc/en.json" )
end)

Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_jump_mod", function(menu_manager)
    add_boolean_callback("fall_damage_callback", "fall_damage")
    add_boolean_callback("full_charge_feedback_callback", "full_charge_feedback")
    add_callback("jump_style_callback", "jump_style")
    add_callback("jump_range_callback", "jump_range")
    add_callback("jump_height_multiplicator_callback", "jump_height_multiplicator")
    add_callback("jump_height_max_multiplicator_callback", "jump_height_max_multiplicator")


    jump_mod:Load()
    MenuHelper:LoadFromJsonFile(jump_mod._path .. "Menu/menu.json", jump_mod, jump_mod._data)
end)