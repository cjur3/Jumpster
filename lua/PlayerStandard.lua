if not jump_mod then
    return
end

local _debug = false
local _f_PlayerStandard_get_input = PlayerStandard._get_input

local _trigger_jump = false
local _btn_jump_press_time = 0
local _jump_is_charging = false
local _number_of_jumps = 0

function logDebug(msg)
    if _debug then
        log(msg)
    end
end

function calculate_pressed_percentage(start_time, end_time, max_time)
    local pressed_time = end_time - start_time
    if pressed_time > max_time then
        return 1
    else
        return pressed_time / max_time
    end
end

function calculate_final_multiplicator(min, max, percentage)
    return min + (max - min) * percentage
end

function PlayerStandard:_get_input(t, ...)
    local _result = _f_PlayerStandard_get_input(self, t, ...)
    local _original_jumping = jump_mod._data.original_jumping or false

    if not _original_jumping and t and type(t) == "number" and t > 0 then
        local _pressed = self._controller:get_any_input_pressed()
        local _released = self._controller:get_any_input_released()
        local _btn_jump_pressed = _pressed and self._controller:get_input_pressed("jump")
        local _btn_jump_released = _released and self._controller:get_input_released("jump")
        local _btn_run_pressed = _pressed and self._controller:get_input_pressed("run")

        local _max_amount_of_jumps = (jump_mod._data.jump_style or 2) - 1
        local _full_charge_feedback = jump_mod._data.full_charge_feedback and true
        local _dash = jump_mod._data.dash or true
        local _jump_charged_sound_number = jump_mod._data.jump_charged_sound or 1
        local _jump_charged_sound = jump_mod._sounds[_jump_charged_sound_number] or "Whoosh_SFX_01"

        if _btn_jump_pressed and not _btn_jump_released then
            _btn_jump_press_time = t
            _jump_is_charging = true
        end

        if _btn_jump_released then
            _jump_is_charging = false
        end

        if _full_charge_feedback and _jump_is_charging and calculate_pressed_percentage(_btn_jump_press_time, t, 3) == 1 then
            _jump_is_charging = false
            jump_mod:playSound(_jump_charged_sound)
        end

        if _dash and self._state_data.meleeing and _btn_run_pressed then
            self:_start_action_dash(t)
        end

        if not self:in_air() and (_btn_jump_pressed or _btn_jump_released) then
            _number_of_jumps = 0
        end

        if _btn_jump_released and _number_of_jumps < _max_amount_of_jumps then
            _number_of_jumps = _number_of_jumps + 1
            _trigger_jump = true
        end
    end

    return _result
end

local _f_PlayerStandard_check_action_jump = PlayerStandard._check_action_jump

function PlayerStandard:_check_action_jump(t, input)
    local _original_jumping = jump_mod._data.original_jumping or false
    if not _original_jumping then
        self:_check_action_jump_new(t, input)
    else
        _f_PlayerStandard_check_action_jump(self, t, input)
    end
end

function PlayerStandard:_start_action_dash(t)
    local _dash_stamina_drain = jump_mod._data.dash_stamina_drain or 50
    if _dash_stamina_drain <= self._unit:movement()._stamina and self._move_dir then
        local _dash_sound_number = jump_mod._data.dash_sound or 1
        local _dash_sound = jump_mod._sounds[_dash_sound_number] or "Whoosh_SFX_01"

        local action_start_data = {}
        action_start_data.jump_vel_z = tweak_data.player.movement_state.standard.movement.jump_velocity.z * 0.05
        action_start_data.jump_vel_xy = tweak_data.player.movement_state.standard.movement.jump_velocity.xy["run"] * 5

        self._unit:movement():subtract_stamina(_dash_stamina_drain)
        jump_mod:playSound(_dash_sound)
        self:_start_action_jump(t, action_start_data)
    end
end

function PlayerStandard:_check_action_jump_new(t, input)
    local _jumping_multiplicator = jump_mod._data.jump_height_multiplicator or 1.2
    local _jump_range = jump_mod._data.jump_range or 0.5
    local _jump_height_max_multiplicator = jump_mod._data.jump_height_max_multiplicator or 1.5

    local new_action

    if _trigger_jump and not self._unit:movement():is_stamina_drained() then

        _trigger_jump = false
        local action_forbidden = false
        action_forbidden = action_forbidden or self._unit:base():stats_screen_visible() or self:_interacting() or
                               self:_on_zipline() or self:_does_deploying_limit_movement() or self:_is_using_bipod()
        if not action_forbidden then
            if self._state_data.ducking then
                self:_interupt_action_ducking(t)
            else
                if self._state_data.on_ladder then
                    self:_interupt_action_ladder(t)
                end
                local action_start_data = {}
                action_start_data.jump_vel_z = tweak_data.player.movement_state.standard.movement.jump_velocity.z

                local _pressed_percentage = calculate_pressed_percentage(_btn_jump_press_time, t, 3)

                local _calculated_jumping_multiplicator = calculate_final_multiplicator(_jumping_multiplicator,
                                                              _jump_height_max_multiplicator, _pressed_percentage)

                if self._move_dir then
                    action_start_data =
                        self:calculate_jump_range(t, _pressed_percentage, action_start_data, _jump_range)
                end

                if _calculated_jumping_multiplicator > _jump_height_max_multiplicator then
                    _calculated_jumping_multiplicator = _jump_height_max_multiplicator
                end

                if self._unit:movement():is_above_stamina_threshold() then
                    local _stamina_drain_for_jumps = jump_mod._data.stamina_drain or 15
                    local _stamina_drain = _stamina_drain_for_jumps * _calculated_jumping_multiplicator

                    logDebug("Stamina drain: " .. _stamina_drain)

                    if _stamina_drain > self._unit:movement()._stamina then
                        _calculated_jumping_multiplicator = self._unit:movement()._stamina / _stamina_drain_for_jumps
                        logDebug("Stamina drain too high adjusting jump multiplicator: " .. _calculated_jumping_multiplicator)
                    end

                    action_start_data.jump_vel_z = action_start_data.jump_vel_z * _calculated_jumping_multiplicator
                    
                    if action_start_data.jump_vel_xy then
                        action_start_data.jump_vel_xy = action_start_data.jump_vel_xy * _calculated_jumping_multiplicator
                    end

                    self._unit:movement():subtract_stamina(_stamina_drain)

                    new_action = self:_start_action_jump(t, action_start_data)
                end
            end
        end
    end
    return new_action
end

function PlayerStandard:calculate_jump_range(t, _pressed_percentage, action_start_data, _jump_range)
    local is_running = self._running and self._unit:movement():is_above_stamina_threshold() and t -
                           self._start_running_t > 0.4
    local jump_vel_xy = tweak_data.player.movement_state.standard.movement.jump_velocity.xy[is_running and "run" or
                            "walk"]

    action_start_data.jump_vel_xy = jump_vel_xy * (1 + _pressed_percentage * (_jump_range - 1))

    return action_start_data
end
