// Movimento com passo configuravel e colisao com margem (Contexto: Obj_Player)
function player_handle_movement() {
    if (!instance_exists(Obj_Builder)) exit;

    var _cw = Obj_Builder.cell_width, _ch = Obj_Builder.cell_height;
    var _gw = ds_grid_width(Obj_Builder.grid), _gh = ds_grid_height(Obj_Builder.grid);

    var _step_size = 32; // Tamanho do passo em px (64 = 1 bloco, 32 = meio bloco, 16 = 1/4)
    var _margin    = 12; // Folga das paredes/quinas para evitar clipping da camera

    var _up    = keyboard_check_pressed(vk_up)    || keyboard_check_pressed(ord("W"));
    var _down  = keyboard_check_pressed(vk_down)  || keyboard_check_pressed(ord("S"));
    var _left  = keyboard_check_pressed(vk_left)  || keyboard_check_pressed(ord("A"));
    var _right = keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"));

    if (_left)  target_dir -= 90;
    if (_right) target_dir += 90;

    var _move_sign = _up - _down;
    if (_move_sign != 0) {
        var _nx = target_x + round(lengthdir_x(_step_size * _move_sign, target_dir));
        var _ny = target_y + round(lengthdir_y(_step_size * _move_sign, target_dir));

        // Checa os 4 cantos ao redor do destino para impedir clipping em paredes e quinas
        var _c1x = floor((_nx - _margin) / _cw), _c1y = floor((_ny - _margin) / _ch);
        var _c2x = floor((_nx + _margin) / _cw), _c2y = floor((_ny + _margin) / _ch);

        var _can_move =
            (_c1x >= 0 && _c2x < _gw && _c1y >= 0 && _c2y < _gh) &&
            (Obj_Builder.grid[# _c1x, _c1y] == Obj_Builder.CELL_FLOOR) &&
            (Obj_Builder.grid[# _c2x, _c1y] == Obj_Builder.CELL_FLOOR) &&
            (Obj_Builder.grid[# _c1x, _c2y] == Obj_Builder.CELL_FLOOR) &&
            (Obj_Builder.grid[# _c2x, _c2y] == Obj_Builder.CELL_FLOOR);

        if (_can_move) {
            target_x = _nx;
            target_y = _ny;
        }
    }
}

// Desliza o jogador ate a celula de fuga; retorna true enquanto estiver recuando (Contexto: Obj_Player)
function player_update_flee() {
    if (!is_fleeing) return false;

    if (x < flee_target_x) x = min(x + flee_speed, flee_target_x);
    if (x > flee_target_x) x = max(x - flee_speed, flee_target_x);
    if (y < flee_target_y) y = min(y + flee_speed, flee_target_y);
    if (y > flee_target_y) y = max(y - flee_speed, flee_target_y);

    target_x = x;
    target_y = y;

    if (x == flee_target_x && y == flee_target_y) is_fleeing = false;
    return true;
}

// Interpola cor e alcance do fog conforme o bioma atual (Contexto: Obj_Player)
function player_update_fog() {
    if (!instance_exists(Obj_Builder)) exit;

    var _gx = x div Obj_Builder.cell_width;
    var _gy = y div Obj_Builder.cell_height;

    if (_gx >= 0 && _gx < ds_grid_width(Obj_Builder.biome_grid) &&
        _gy >= 0 && _gy < ds_grid_height(Obj_Builder.biome_grid)) {
        var _b = global.biomes[Obj_Builder.biome_grid[# _gx, _gy]];
        current_fog_color = merge_color(current_fog_color, _b.fog_color, 0.05);
        current_fog_start = lerp(current_fog_start, _b.fog_start, 0.05);
        current_fog_end   = lerp(current_fog_end,   _b.fog_end,   0.05);
    }
}

// Interpola transform e aplica a camera 3D (Contexto: Obj_Player)
function player_update_camera() {
    dir += angle_difference(target_dir, dir) * 0.15;
    x    = lerp(x, target_x, 0.15);
    y    = lerp(y, target_y, 0.15);

    var _vx = lengthdir_x(64, dir);
    var _vy = lengthdir_y(64, dir);
    d3d_set_projection(x, y, z, x + _vx, y + _vy, z, 0, 0, -1);
    d3d_set_fog(true, current_fog_color, current_fog_start, current_fog_end);
}