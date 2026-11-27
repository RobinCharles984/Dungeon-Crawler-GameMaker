// Verifica se o jogador esta em celula ortogonal adjacente e inicia batalha (Contexto: Obj_Enemy)
function enemy_check_encounter() {
    if (is_dead || !instance_exists(Obj_Player) || !instance_exists(Obj_HUD)) exit;
    if (Obj_HUD.hud_state != HUD_STATE.EXPLORE || Obj_Player.is_fleeing) exit;

    var _cw = Obj_Builder.cell_width, _ch = Obj_Builder.cell_height;
    var _ex = x div _cw, _ey = y div _ch;
    var _px = Obj_Player.x div _cw, _py = Obj_Player.y div _ch;

    var _aligned = (_ex == _px) || (_ey == _py);
    var _dist    = abs(_ex - _px) + abs(_ey - _py);

    if (_aligned && _dist == 1) {
        // Vira a camera do jogador para encarar o inimigo
        var _snap = (round(point_direction(Obj_Player.x, Obj_Player.y, x, y) / 90) * 90 + 360) mod 360;
        Obj_Player.target_dir = _snap;

        global.active_enemy = id;
        hud_change_state(Obj_HUD, HUD_STATE.COMBAT);
        NewEncounter(enemy_data);
    }
}

// Aciona o piscar de dano no sprite 3D do inimigo
function enemy_trigger_hit_flash(_enemy, _duration = 0.40) {
    if (!instance_exists(_enemy)) exit;
    _enemy.hit_flash_timer = _duration;
}

// Alterna cor/opacidade durante o flash e restaura ao terminar (Contexto: Obj_Enemy)
function enemy_update_vfx() {
    if (hit_flash_timer <= 0) exit;

    hit_flash_timer = max(0, hit_flash_timer - min(delta_time / 1000000, 0.05));

    if (hit_flash_timer <= 0) {
        image_blend = c_white;
        image_alpha = 1;
    } else {
        var _blink  = (floor(hit_flash_timer * 24) mod 2 == 1);
        image_blend = _blink ? c_red : c_white;
        image_alpha = _blink ? 0.55 : 1.0;
    }
}