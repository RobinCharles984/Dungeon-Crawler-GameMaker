// 1. Atualização do tempo de animação da placa
if (is_animating) {
    anim_progress += anim_speed;
    if (anim_progress >= 1) {
        anim_progress = 1;
        is_animating  = false;
    }
}

// 2. Coordenadas do mouse na GUI
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);

// 3. Lógica de Soltar o Item Arrastado (Drag & Drop)
if (mouse_check_button_released(mb_left) && drag_slot != -1) {
    var _height   = display_get_gui_height();
    var _width    = display_get_gui_width();
    var _sprite_w = _width / 1.15;
    var _sprite_h = _height / 3;
    var _x        = (_width - _sprite_w) / 2;
    var _target_y = _height - _sprite_h;

    var _slot_size = 48;
    var _padding   = 8;
    var _grid_x    = _x + _sprite_w - (_slot_size + _padding) * inv_cols - 20;
    var _grid_y    = _target_y + 20;

    var _target_slot = -1;

    // Identifica se o mouse foi solto sobre algum slot válido da matriz
    for (var r = 0; r < inv_rows; r++) {
        for (var c = 0; c < inv_cols; c++) {
            var _sx = _grid_x + c * (_slot_size + _padding);
            var _sy = _grid_y + r * (_slot_size + _padding);
            
            if (_mx >= _sx && _mx <= _sx + _slot_size && _my >= _sy && _my <= _sy + _slot_size) {
                _target_slot = r * inv_cols + c;
                break;
            }
        }
    }

    // Troca as posições dos itens se soltou num slot válido
    if (_target_slot != -1 && _target_slot != drag_slot) {
        var _temp = inv_grid[_target_slot];
        inv_grid[_target_slot] = inv_grid[drag_slot];
        inv_grid[drag_slot] = _temp;
    }

    drag_slot = -1; // Reseta o estado de arrasto
}