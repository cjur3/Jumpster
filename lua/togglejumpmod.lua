if not jump_mod then
    return
end

jump_mod._data.original_jumping = not jump_mod._data.original_jumping
jump_mod:Save()