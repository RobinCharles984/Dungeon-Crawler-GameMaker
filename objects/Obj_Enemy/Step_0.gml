/// Evento Step do Obj_Enemy

// 1. SE O INIMIGO JÁ FOI DERROTADO, IGNORA QUALQUER LÓGICA
if (is_dead) exit;

if (instance_exists(Obj_Player) && instance_exists(Obj_HUD)) {
    var _player_fleeing = variable_instance_exists(Obj_Player, "is_fleeing") && Obj_Player.is_fleeing;

    if (Obj_HUD.hud_state == HUD_STATE.EXPLORE && !_player_fleeing) {
        
        var _cw = Obj_Builder.cell_width;
        var _ch = Obj_Builder.cell_height;

        var _ex = x div _cw;
        var _ey = y div _ch;
        var _px = Obj_Player.x div _cw;
        var _py = Obj_Player.y div _ch;

        var _is_aligned = (_ex == _px) || (_ey == _py);
        var _dist_grid  = abs(_ex - _px) + abs(_ey - _py);

        if (_is_aligned && _dist_grid == 1) {
            
            // Trava o olhar do jogador para o inimigo
            var _raw_dir = point_direction(Obj_Player.x, Obj_Player.y, x, y);
            var _snap_dir = (round(_raw_dir / 90) * 90) mod 360;
            if (_snap_dir < 0) _snap_dir += 360;

            Obj_Player.dir = _snap_dir;
            if (variable_instance_exists(Obj_Player, "target_dir")) {
                Obj_Player.target_dir = _snap_dir;
            }

            // Define o background pelo bioma
            var _gx = Obj_Player.x div _cw;
            var _gy = Obj_Player.y div _ch;
            var _current_biome = Obj_Builder.biome_grid[# _gx, _gy];

            var _bg = Spr_Battle_Background;
            if (_current_biome == BIOME.SEWER)   _bg = Spr_Explore_Background;
            if (_current_biome == BIOME.CAVE)    _bg = Spr_Battle_Background;
            if (_current_biome == BIOME.DUNGEON) _bg = Spr_Inventory_Background;

            // -------------------------------------------------------------
            // ESSENCIAL: SALVA O ID DESTE INIMIGO ESPECÍFICO NA GLOBAL
            // -------------------------------------------------------------
            global.active_enemy = id;

            // Transição de HUD e início do encontro
            Obj_HUD.change_hud_state(HUD_STATE.COMBAT);
            NewEncounter(enemy_data, _bg);
        }
    }
}