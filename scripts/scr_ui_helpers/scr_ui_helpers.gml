function ease_out_cubic(_t) {
    _t = clamp(_t, 0, 1);
    return 1 - power(1 - _t, 3);
}

// Cor de destaque por raridade do item
function ui_get_rarity_color(_rarity) {
    switch (_rarity) {
        case RARITY.UNCOMMON: return make_color_rgb(100, 220, 120);
        case RARITY.RARE:     return make_color_rgb(90,  180, 255);
        case RARITY.SPECIAL:  return make_color_rgb(255, 195, 70);
        default:              return make_color_rgb(220, 220, 220);
    }
}

// Cartao escuro semitransparente com borda dupla (usado nas secoes do HUD)
function ui_draw_card(_x1, _y1, _x2, _y2, _title = "", _accent = c_yellow) {
    var _bg_top = make_color_rgb(20, 16, 14);
    var _bg_bot = make_color_rgb(10, 8, 8);
    var _border = make_color_rgb(120, 95, 65);

    draw_set_alpha(0.84);
    draw_rectangle_color(_x1, _y1, _x2, _y2, _bg_top, _bg_top, _bg_bot, _bg_bot, false);
    draw_set_alpha(1.0);

    draw_rectangle_color(_x1, _y1, _x2, _y2, _border, _border, _border, _border, true);
    draw_rectangle_color(_x1 + 1, _y1 + 1, _x2 - 1, _y2 - 1, c_black, c_black, c_black, c_black, true);

    if (_title != "") {
        draw_text_color(_x1 + 8, _y1 + 5, _title, _accent, _accent, _accent, _accent, 1);
        draw_line_color(_x1 + 6, _y1 + 22, _x2 - 6, _y1 + 22, _border, _border);
    }
}

// Botao estilizado com borda metalica e brilho no hover; retorna true no clique
function ui_draw_button(_x1, _y1, _x2, _y2, _text, _bg_col, _txt_col) {
    var _mx    = device_mouse_x_to_gui(0);
    var _my    = device_mouse_y_to_gui(0);
    var _hover = point_in_rectangle(_mx, _my, _x1, _y1, _x2, _y2);

    var _top = _hover ? merge_color(_bg_col, c_white, 0.22) : merge_color(_bg_col, c_black, 0.15);
    var _bot = merge_color(_bg_col, c_black, 0.65);
    var _brd = _hover ? c_yellow : make_color_rgb(155, 130, 95);

    draw_rectangle_color(_x1, _y1, _x2, _y2, _top, _top, _bot, _bot, false);
    draw_rectangle_color(_x1, _y1, _x2, _y2, _brd, _brd, _brd, _brd, true);

    var _cx = (_x1 + _x2) * 0.5, _cy = (_y1 + _y2) * 0.5;
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    // Sombra sutil do texto
    draw_text_color(_cx + 1, _cy + 1, _text, c_black, c_black, c_black, c_black, 0.8);
    draw_text_color(_cx,     _cy,     _text, _txt_col, _txt_col, _txt_col, _txt_col, 1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    return (_hover && mouse_check_button_pressed(mb_left));
}

// Barra de progresso com brilho superior e texto com sombra
function ui_draw_bar(_x, _y, _w, _h, _val, _max, _col_top, _col_bot, _label) {
    var _ratio  = (_max > 0) ? clamp(_val / _max, 0, 1) : 0;
    var _fill_w = _w * _ratio;
    var _border = make_color_rgb(150, 125, 90);

    // Fundo escuro
    draw_rectangle_color(_x, _y, _x + _w, _y + _h, c_black, c_black, make_color_rgb(24, 20, 20), make_color_rgb(24, 20, 20), false);

    // Preenchimento + brilho sutil na metade de cima
    if (_fill_w > 1) {
        draw_rectangle_color(_x + 1, _y + 1, _x + _fill_w - 1, _y + _h - 1, _col_top, _col_top, _col_bot, _col_bot, false);
        draw_set_alpha(0.18);
        draw_rectangle_color(_x + 1, _y + 1, _x + _fill_w - 1, _y + (_h * 0.45), c_white, c_white, c_white, c_white, false);
        draw_set_alpha(1.0);
    }

    draw_rectangle_color(_x, _y, _x + _w, _y + _h, _border, _border, _border, _border, true);

    draw_text_color(_x + 7, _y + 2, _label, c_black, c_black, c_black, c_black, 0.85);
    draw_text_color(_x + 6, _y + 1, _label, c_white, c_white, c_white, c_white, 1);
}

// Tooltip flutuante com ajuste automatico para nunca cortar na borda da tela
// _tip = { title, sub, desc, col }
function ui_draw_tooltip(_tip) {
    if (_tip == undefined) exit;

    var _sw  = display_get_gui_width();
    var _sh  = display_get_gui_height();
    var _mx  = device_mouse_x_to_gui(0);
    var _my  = device_mouse_y_to_gui(0);

    var _tw  = 270;
    var _pad = 10;
    var _has_sub = ((_tip[$ "sub"] ?? "") != "");
    var _desc_h  = string_height_ext(_tip.desc, 15, _tw - (_pad * 2));
    var _th      = _pad * 2 + 22 + (_has_sub ? 18 : 0) + _desc_h + 6;

    // Posiciona acima do mouse e trava dentro da tela
    var _tx = clamp(_mx + 14, 8, _sw - _tw - 8);
    var _ty = clamp(_my - _th - 12, 8, _sh - _th - 8);

    var _col = _tip[$ "col"] ?? c_yellow;
    var _brd = make_color_rgb(175, 145, 95);

    draw_set_alpha(0.95);
    draw_rectangle_color(_tx, _ty, _tx + _tw, _ty + _th, make_color_rgb(16, 13, 12), make_color_rgb(16, 13, 12), make_color_rgb(8, 7, 7), make_color_rgb(8, 7, 7), false);
    draw_set_alpha(1.0);
    draw_rectangle_color(_tx, _ty, _tx + _tw, _ty + _th, _brd, _brd, _brd, _brd, true);

    var _cy = _ty + _pad;
    draw_text_color(_tx + _pad, _cy, _tip.title, _col, _col, _col, _col, 1);
    _cy += 20;

    if (_has_sub) {
        draw_text_color(_tx + _pad, _cy, _tip.sub, c_aqua, c_aqua, c_aqua, c_aqua, 1);
        _cy += 18;
    }

    draw_line_color(_tx + _pad, _cy, _tx + _tw - _pad, _cy, make_color_rgb(80, 68, 52), make_color_rgb(80, 68, 52));
    _cy += 6;
    draw_text_ext_color(_tx + _pad, _cy, _tip.desc, 15, _tw - (_pad * 2), c_ltgray, c_ltgray, c_ltgray, c_ltgray, 1);
}

// Filtro global de brilho
function ui_draw_brightness_overlay() {
    if (!variable_global_exists("brightness") || global.brightness == 100) exit;

    var _sw = display_get_gui_width();
    var _sh = display_get_gui_height();

    if (global.brightness < 100) {
        draw_set_alpha((100 - global.brightness) / 100 * 0.7);
        draw_rectangle_color(0, 0, _sw, _sh, c_black, c_black, c_black, c_black, false);
    } else {
        draw_set_alpha((global.brightness - 100) / 100 * 0.4);
        draw_rectangle_color(0, 0, _sw, _sh, c_white, c_white, c_white, c_white, false);
    }
    draw_set_alpha(1.0);
}