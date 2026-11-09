// Bloqueia qualquer movimentação ou rotação se não estiver no modo de exploração
if (instance_exists(Obj_HUD)) {
    if (Obj_HUD.hud_state != HUD_STATE.EXPLORE) {
        exit; // Interrompe o evento Step aqui (o jogador fica imóvel)
    }
}

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

// Se estiver em combate, apenas interpola a visão em direção ao inimigo antes de travar totalmente
if (instance_exists(Obj_HUD)) {
    if (Obj_HUD.hud_state == HUD_STATE.COMBAT) {
        if (variable_instance_exists(id, "target_combat_dir")) {
            // Gira suavemente a câmera até alinhar com a direção do inimigo
            var _diff = angle_difference(target_combat_dir, dir);
            dir += _diff * 0.15; 
        }
        exit; // Impede movimentação
    }
}

/// Evento Step do Obj_Player

// Se estiver executando o recuo de fuga, desliza até a célula de trás e trava os controles
if (is_fleeing) {
    // Aproxima X e Y suavemente em direção ao destino de fuga
    if (x < flee_target_x) x = min(x + flee_speed, flee_target_x);
    if (x > flee_target_x) x = max(x - flee_speed, flee_target_x);
    if (y < flee_target_y) y = min(y + flee_speed, flee_target_y);
    if (y > flee_target_y) y = max(y - flee_speed, flee_target_y);

    // Sincroniza as variáveis de controle da grade do próprio Player (se houver)
    if (variable_instance_exists(id, "target_x")) target_x = x;
    if (variable_instance_exists(id, "target_y")) target_y = y;

    // Quando o jogador atingir a coordenada exata da célula de trás, encerra o recuo
    if (x == flee_target_x && y == flee_target_y) {
        is_fleeing = false;
    }

    exit; // Trava o controle normal do jogador enquanto estiver deslizando
}

// Bloqueia movimentação em menus/batalha
if (instance_exists(Obj_HUD) && Obj_HUD.hud_state != HUD_STATE.EXPLORE) {
    exit;
}

if(keyboard_check_pressed(ord("R")))	room_restart();
if(keyboard_check_pressed(ord("M")))	global.show_minimap = !global.show_minimap;