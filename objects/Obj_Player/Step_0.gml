move_player();

// Changing fog by biome
if (instance_exists(Obj_Builder)) {
    var _gx = x div Obj_Builder.cell_width;
    var _gy = y div Obj_Builder.cell_height;
    
    // Verifica se está dentro dos limites do grid
    if (_gx >= 0 && _gx < ds_grid_width(Obj_Builder.biome_grid) &&
        _gy >= 0 && _gy < ds_grid_height(Obj_Builder.biome_grid)) {
        
        var _standing_biome = Obj_Builder.biome_grid[# _gx, _gy];
        var _target_data    = global.biomes[_standing_biome];
        
        // Suaviza a transição de cores e distâncias (0.05 = taxa de transição)
        current_fog_color = merge_color(current_fog_color, _target_data.fog_color, 0.05);
        current_fog_start = lerp(current_fog_start, _target_data.fog_start, 0.05);
        current_fog_end   = lerp(current_fog_end, _target_data.fog_end, 0.05);
    }
}