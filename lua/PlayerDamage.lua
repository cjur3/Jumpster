if not jump_mod then
    return
end

local damage_fall_original = PlayerDamage.damage_fall

function PlayerDamage:damage_fall(data)
    if not jump_mod._data.fall_damage and not jump_mod._data.original_jumping then
        local height_limit = 300
        if data.height < height_limit then
            return false
        end

        self._unit:sound():play("player_hit")
        managers.environment_controller:hit_feedback_down()
        
        return true
    else
        return damage_fall_original(self, data)
    end
end
