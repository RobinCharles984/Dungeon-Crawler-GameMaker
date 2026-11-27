enum HUD_STATE { EXPLORE, COMBAT, INVENTORY }

// Troca estado e controla abertura/fechamento automatico da gaveta
function hud_change_state(_hud, _new_state) {
    with (_hud) {
        if (hud_state == _new_state || is_animating) exit;

        if (_new_state == HUD_STATE.INVENTORY) {
            return_state          = hud_state;
            was_minimized_pre_inv = is_minimized;
        }

        var _came_from_min = (min_progress > 0.5);
        previous_hud_state = hud_state;
        hud_state          = _new_state;
        show_item_options  = false;
        show_skill_wheel   = false;
        reading_file       = undefined;

        if (_new_state == HUD_STATE.COMBAT || _new_state == HUD_STATE.INVENTORY) {
            is_minimized = false;
        } else if (_new_state == HUD_STATE.EXPLORE) {
            is_minimized = (previous_hud_state == HUD_STATE.INVENTORY) ? was_minimized_pre_inv : true;
        }

        if (_came_from_min) { anim_progress = 1; is_animating = false; }
        else                { anim_progress = 0; is_animating = true;  }
    }
}

// Dimensoes base do painel inferior
function hud_get_layout() {
    var _w  = display_get_gui_width();
    var _h  = display_get_gui_height();
    var _pw = _w / 1.15;
    var _ph = _h / 3;
    return { sw: _w, sh: _h, pw: _pw, ph: _ph, px: (_w - _pw) / 2, py: _h - _ph };
}

// Y atual interpolado entre aberto (0) e minimizado (1)
function hud_get_panel_y(_lay) {
    var _min_y = _lay.sh - (_lay.ph * min_peek_ratio);
    var _t     = clamp(min_progress, 0, 1);
    var _ease  = _t * _t * (3 - 2 * _t);
    return lerp(_lay.py, _min_y, _ease);
}

// Retorna retangulo exato de um slot (c, r) mapeado na matriz 8x3 do Spr_Inventory_Background
function hud_inv_get_slot_rect(_px, _py, _pw, _ph, _c, _r) {
    var _raw_x1 = _px + _pw * inv_col_bounds[_c];
    var _raw_x2 = _px + _pw * inv_col_bounds[_c + 1];
    var _raw_y1 = _py + _ph * inv_row_bounds[_r];
    var _raw_y2 = _py + _ph * inv_row_bounds[_r + 1];

    // Recuo interno para nunca cobrir as linhas desenhadas no sprite
    var _pad_x = max(4, (_raw_x2 - _raw_x1) * 0.08);
    var _pad_y = max(4, (_raw_y2 - _raw_y1) * 0.10);

    return {
        x1: _raw_x1 + _pad_x,
        y1: _raw_y1 + _pad_y,
        x2: _raw_x2 - _pad_x,
        y2: _raw_y2 - _pad_y
    };
}

// Atualiza gaveta, atalhos [I]/[ESC] e drag & drop (Contexto: Obj_HUD)
function hud_step() {
    var _dt = min(delta_time / 1000000, 0.05);

    var _target = is_minimized ? 1 : 0;
    if (min_progress < _target) min_progress = min(_target, min_progress + min_speed * _dt);
    if (min_progress > _target) min_progress = max(_target, min_progress - min_speed * _dt);

    if (is_animating) {
        anim_progress = min(1, anim_progress + anim_speed);
        if (anim_progress >= 1) is_animating = false;
    }

    // [ESC] fecha arquivo aberto ou sai do inventario
    if (keyboard_check_pressed(vk_escape)) {
        if (reading_file != undefined)            reading_file = undefined;
        else if (hud_state == HUD_STATE.INVENTORY) hud_change_state(id, return_state);
    }

    // [I] alterna inventario
    if (keyboard_check_pressed(ord("I")) && !is_animating) {
        if (hud_state == HUD_STATE.INVENTORY)    hud_change_state(id, return_state);
        else if (hud_state == HUD_STATE.EXPLORE) hud_change_state(id, HUD_STATE.INVENTORY);
    }

    // Drag & drop alinhado a matriz exata do sprite
    if (mouse_check_button_released(mb_left) && drag_slot != -1) {
        if (hud_state == HUD_STATE.INVENTORY && min_progress < 0.1) {
            var _lay   = hud_get_layout();
            var _cur_y = hud_get_panel_y(_lay);
            var _mx    = device_mouse_x_to_gui(0);
            var _my    = device_mouse_y_to_gui(0);
            var _hit   = -1;

            for (var r = 0; r < inv_rows && _hit == -1; r++) {
                for (var c = 0; c < inv_cols; c++) {
                    var _rc = hud_inv_get_slot_rect(_lay.px, _cur_y, _lay.pw, _lay.ph, c, r);
                    if (point_in_rectangle(_mx, _my, _rc.x1, _rc.y1, _rc.x2, _rc.y2)) {
                        _hit = r * inv_cols + c;
                        break;
                    }
                }
            }

            if (_hit != -1 && _hit != drag_slot) {
                var _tmp = inv_grid[_hit];
                inv_grid[_hit]      = inv_grid[drag_slot];
                inv_grid[drag_slot] = _tmp;
                selected_slot       = _hit;
            }
        }
        drag_slot = -1;
    }
}

// Orquestrador do Draw GUI (Contexto: Obj_HUD)
function hud_draw_gui() {
    if (!instance_exists(Obj_Player)) exit;
    d3d_set_fog(false, c_black, 1, 1);

    hover_tooltip = undefined; // Limpa tooltip do frame anterior

    var _lay   = hud_get_layout();
    var _cur_y = hud_get_panel_y(_lay);
    var _shk   = (hud_state == HUD_STATE.COMBAT && instance_exists(Obj_Battle))
        ? battle_vfx_get_shake(Obj_Battle)
        : { x: 0, y: 0 };

    hud_draw_side_buttons(_lay, _cur_y);

    if (!is_animating) {
        hud_draw_panel(hud_state, _lay.px + _shk.x, _cur_y + _shk.y, _lay.pw, _lay.ph);
    } else {
        hud_draw_panel(previous_hud_state, _lay.px, _cur_y, _lay.pw, _lay.ph);
        var _slide_y = lerp(_lay.sh, _cur_y, ease_out_cubic(anim_progress));
        hud_draw_panel(hud_state, _lay.px, _slide_y, _lay.pw, _lay.ph);
    }

    if (hud_state != HUD_STATE.INVENTORY) {
        hud_draw_toggle_arrow(_lay, _cur_y + _shk.y);
    }

    if (min_progress > 0.25) {
        hud_draw_mini_bars(_lay, _cur_y + _shk.y);
    }

    // Icone seguindo mouse durante drag & drop
    if (drag_slot != -1 && inv_grid[drag_slot] != undefined && mouse_check_button(mb_left)) {
        var _mx = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);
        draw_sprite_stretched(inv_grid[drag_slot].sprite, 0, _mx - 22, _my - 22, 44, 44);
    }

    if (variable_global_exists("show_minimap") && global.show_minimap) {
        hud_draw_minimap();
    }

    if (hud_state == HUD_STATE.COMBAT && instance_exists(Obj_Battle)) {
        battle_vfx_draw(Obj_Battle);
    }

    // Modal de leitura de arquivos de lore
    if (reading_file != undefined) {
        hud_draw_file_reader(_lay);
    }

    // Tooltip sempre por cima de todo o HUD
    ui_draw_tooltip(hover_tooltip);
    ui_draw_brightness_overlay();
}

// Aba da setinha no topo do HUD
function hud_draw_toggle_arrow(_lay, _cur_y) {
    var _tw = 58, _th = 22;
    var _cx = _lay.px + (_lay.pw * 0.5);
    var _x1 = _cx - (_tw * 0.5), _y1 = _cur_y - _th;
    var _x2 = _cx + (_tw * 0.5), _y2 = _cur_y;

    var _mx    = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);
    var _hover = point_in_rectangle(_mx, _my, _x1, _y1, _x2, _y2);
    var _top   = _hover ? make_color_rgb(70, 56, 42) : make_color_rgb(32, 25, 20);
    var _brd   = _hover ? c_yellow : make_color_rgb(155, 130, 95);
    var _col   = _hover ? c_yellow : c_white;

    draw_rectangle_color(_x1, _y1, _x2, _y2, _top, _top, c_black, c_black, false);
    draw_rectangle_color(_x1, _y1, _x2, _y2, _brd, _brd, _brd, _brd, true);

    var _mid_y = (_y1 + _y2) * 0.5;
    if (is_minimized) draw_triangle_color(_cx, _mid_y - 5, _cx - 8, _mid_y + 5, _cx + 8, _mid_y + 5, _col, _col, _col, false);
    else              draw_triangle_color(_cx, _mid_y + 5, _cx - 8, _mid_y - 5, _cx + 8, _mid_y - 5, _col, _col, _col, false);

    if (_hover && mouse_check_button_pressed(mb_left)) {
        is_minimized = !is_minimized;
        if (is_minimized) { show_skill_wheel = false; show_item_options = false; }
    }
}

// Barras compactas de HP e MP acima da faixa minimizada
function hud_draw_mini_bars(_lay, _cur_y) {
    var _p     = Obj_Player.stats;
    var _alpha = clamp((min_progress - 0.25) / 0.75, 0, 1);

    var _cx    = _lay.px + (_lay.pw * 0.5);
    var _bar_w = clamp(_lay.pw * 0.19, 135, 220);
    var _bar_h = 18;
    var _gap   = 42;
    var _by    = _cur_y - _bar_h - 3;

    draw_set_alpha(_alpha);
    ui_draw_bar(_cx - _gap - _bar_w, _by, _bar_w, _bar_h, _p.life, _p.life_max, c_red,  c_maroon, "HP: " + string(_p.life) + "/" + string(_p.life_max));
    ui_draw_bar(_cx + _gap,          _by, _bar_w, _bar_h, _p.mp,   _p.mp_max,   c_blue, c_navy,   "MP: " + string(_p.mp)   + "/" + string(_p.mp_max));
    draw_set_alpha(1.0);
}

function hud_draw_side_buttons(_lay, _cur_y) {
    if (_cur_y > _lay.sh - 40) exit;

    var _sw = 105, _sh = 34;
    var _sx = min(_lay.px + _lay.pw + 10, _lay.sw - _sw - 5);
    var _y1 = _cur_y + 14;

    if (ui_draw_button(_sx, _y1, _sx + _sw, _y1 + _sh, "Config", c_dkgray, c_white)) {
        show_debug_message("Abrir Configuracoes");
    }
    if (ui_draw_button(_sx, _y1 + _sh + 10, _sx + _sw, _y1 + _sh * 2 + 10, "Desistir", c_maroon, c_white)) {
        game_restart();
    }
}

function hud_draw_panel(_state, _px, _py, _pw, _ph) {
    var _bg = (_state == HUD_STATE.COMBAT) ? bg_combat : ((_state == HUD_STATE.INVENTORY) ? bg_inventory : bg_explore);
    draw_sprite_stretched(_bg, 0, _px, _py, _pw, _ph);

    if (min_progress > 0.75) exit;

    switch (_state) {
        case HUD_STATE.EXPLORE:   hud_draw_explore(_px, _py, _pw, _ph); break;
        case HUD_STATE.COMBAT:    hud_draw_combat(_px, _py, _pw, _ph); break;
        case HUD_STATE.INVENTORY: hud_draw_inventory(_px, _py, _pw, _ph); break;
    }
}

// =====================================================================
// 1. MODO EXPLORAR: Personagem | Atributos | Skills | Equipamentos
// =====================================================================
function hud_draw_explore(_px, _py, _pw, _ph) {
    var _p = Obj_Player.stats;
    inv_ensure_equipped(_p);

    var _mx  = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);
    var _pad = 14, _gap = 10;
    var _iy  = _py + _pad;
    var _ih  = _ph - (_pad * 2);
    var _uw  = _pw - (_pad * 2) - (_gap * 3); // Largura util dividida em 4 cartoes

    var _w1 = _uw * 0.33; // Personagem + Barras
    var _w2 = _uw * 0.14; // Atributos
    var _w3 = _uw * 0.26; // Skills
    var _w4 = _uw * 0.27; // Equipamentos + Inventario

    var _x1 = _px + _pad;
    var _x2 = _x1 + _w1 + _gap;
    var _x3 = _x2 + _w2 + _gap;
    var _x4 = _x3 + _w3 + _gap;

    // --- CARTAO 1: PERSONAGEM E BARRAS ---
    ui_draw_card(_x1, _iy, _x1 + _w1, _iy + _ih);
    var _port = clamp(_ih - 24, 58, 92);
    draw_sprite_stretched(_p.portrait, 0, _x1 + 10, _iy + 12, _port, _port);
    draw_rectangle_color(_x1 + 10, _iy + 12, _x1 + 10 + _port, _iy + 12 + _port, make_color_rgb(175, 145, 95), make_color_rgb(175, 145, 95), make_color_rgb(175, 145, 95), make_color_rgb(175, 145, 95), true);

    var _tx = _x1 + 18 + _port;
    var _bw = (_x1 + _w1 - 10) - _tx;
    draw_text_color(_tx, _iy + 10, _p.name + " (" + _p.class_name + ")", c_white, c_white, c_white, c_white, 1);
    draw_text_color(_tx, _iy + 28, "Lvl " + string(_p.level), c_yellow, c_yellow, c_yellow, c_yellow, 1);

    var _m_col = _p.is_mantra ? c_aqua : c_gray;
    draw_text_color(_tx + 54, _iy + 28, _p.is_mantra ? "[MANTRA]" : "[SEM MANTRA]", _m_col, _m_col, _m_col, _m_col, 1);

    var _by = _iy + 48, _bh = 17;
    ui_draw_bar(_tx, _by,            _bw, _bh, _p.life, _p.life_max, c_red,  c_maroon, "HP: "  + string(_p.life) + "/" + string(_p.life_max));
    ui_draw_bar(_tx, _by + _bh + 5,  _bw, _bh, _p.mp,   _p.mp_max,   c_blue, c_navy,   "MP: "  + string(_p.mp)   + "/" + string(_p.mp_max));
    ui_draw_bar(_tx, _by + (_bh + 5) * 2, _bw, _bh, _p.xp, _p.xp_next, c_lime, c_green, "EXP: " + string(_p.xp) + "/" + string(_p.xp_next));

    // --- CARTAO 2: ATRIBUTOS ---
    ui_draw_card(_x2, _iy, _x2 + _w2, _iy + _ih, "STATUS", c_yellow);
    var _sy = _iy + 28, _sp = max(18, (_ih - 34) / 5);
    draw_text_color(_x2 + 8, _sy,           "ATK: "  + string(_p.attack),      c_orange, c_orange, c_orange, c_orange, 1);
    draw_text_color(_x2 + 8, _sy + _sp,     "DEF: "  + string(_p.defense),     c_aqua,   c_aqua,   c_aqua,   c_aqua,   1);
    draw_text_color(_x2 + 8, _sy + _sp * 2, "MAG: "  + string(_p.magic),       c_fuchsia,c_fuchsia,c_fuchsia,c_fuchsia,1);
    draw_text_color(_x2 + 8, _sy + _sp * 3, "CRIT: " + string(_p.crit_chance) + "%", c_yellow, c_yellow, c_yellow, c_yellow, 1);
    draw_text_color(_x2 + 8, _sy + _sp * 4, "DANO: +" + string(_p.crit_rate)  + "%", c_ltgray, c_ltgray, c_ltgray, c_ltgray, 1);

    // --- CARTAO 3: SKILLS (hover mostra descricao completa) ---
    ui_draw_card(_x3, _iy, _x3 + _w3, _iy + _ih, "SKILLS (passe o mouse)", c_yellow);
    var _n_sk  = array_length(_p.skills);
    var _sk_y0 = _iy + 28;
    var _sk_h  = min(26, (_ih - 36) / max(1, _n_sk) - 4);

    for (var s = 0; s < _n_sk; s++) {
        var _sk  = _p.skills[s];
        var _rx1 = _x3 + 8, _rx2 = _x3 + _w3 - 8;
        var _ry1 = _sk_y0 + s * (_sk_h + 4);
        var _ry2 = _ry1 + _sk_h;

        var _hov = point_in_rectangle(_mx, _my, _rx1, _ry1, _rx2, _ry2);
        var _bg  = _hov ? make_color_rgb(58, 46, 32) : make_color_rgb(28, 22, 18);
        var _brd = _hov ? c_yellow : make_color_rgb(95, 76, 54);

        draw_rectangle_color(_rx1, _ry1, _rx2, _ry2, _bg, _bg, c_black, c_black, false);
        draw_rectangle_color(_rx1, _ry1, _rx2, _ry2, _brd, _brd, _brd, _brd, true);

        // Nome a esquerda, custo de MP a direita
        draw_set_valign(fa_middle);
        draw_text_color(_rx1 + 6, (_ry1 + _ry2) * 0.5, _sk.name, _hov ? c_yellow : c_white, _hov ? c_yellow : c_white, _hov ? c_yellow : c_white, _hov ? c_yellow : c_white, 1);
        draw_set_halign(fa_right);
        draw_text_color(_rx2 - 6, (_ry1 + _ry2) * 0.5, string(_sk.mp) + " MP", c_aqua, c_aqua, c_aqua, c_aqua, 1);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);

        if (_hov) {
            hover_tooltip = {
                title: _sk.name,
                sub:   "Custo: " + string(_sk.mp) + " MP",
                desc:  _sk.desc,
                col:   c_yellow
            };
        }
    }

    // --- CARTAO 4: EQUIPAMENTOS ATIVOS + BOTAO INVENTARIO ---
    ui_draw_card(_x4, _iy, _x4 + _w4, _iy + _ih, "EQUIPADO", c_yellow);

    var _eq_defs = [
        { key: "weapon",    label: "Arma" },
        { key: "armor",     label: "Armadura" },
        { key: "accessory", label: "Acessorio" }
    ];

    var _btn_h  = 28;
    var _eq_top = _iy + 28;
    var _eq_h   = min(26, (_ih - 38 - _btn_h) / 3 - 4);

    for (var e = 0; e < 3; e++) {
        var _def  = _eq_defs[e];
        var _item = _p.equipped[$ _def.key];
        var _ex1  = _x4 + 8, _ex2 = _x4 + _w4 - 8;
        var _ey1  = _eq_top + e * (_eq_h + 4);
        var _ey2  = _ey1 + _eq_h;

        var _hov = point_in_rectangle(_mx, _my, _ex1, _ey1, _ex2, _ey2);
        var _bg  = _hov ? make_color_rgb(56, 44, 30) : make_color_rgb(26, 20, 16);
        var _brd = (_item != undefined) ? ui_get_rarity_color(_item.rarity) : make_color_rgb(80, 66, 50);
        if (_hov) _brd = c_yellow;

        draw_rectangle_color(_ex1, _ey1, _ex2, _ey2, _bg, _bg, c_black, c_black, false);
        draw_rectangle_color(_ex1, _ey1, _ex2, _ey2, _brd, _brd, _brd, _brd, true);

        draw_set_valign(fa_middle);
        var _mid = (_ey1 + _ey2) * 0.5;
        if (_item != undefined) {
            var _ico = _eq_h - 6;
            draw_sprite_stretched(_item.sprite, 0, _ex1 + 4, _ey1 + 3, _ico, _ico);
            var _rcol = ui_get_rarity_color(_item.rarity);
            draw_text_color(_ex1 + _ico + 10, _mid, _item.name, _rcol, _rcol, _rcol, _rcol, 1);

            if (_hov) {
                var _st = inv_get_item_stats_line(_item);
                hover_tooltip = {
                    title: _item.name + " [" + _def.label + "]",
                    sub:   _st != "" ? _st : _def.label,
                    desc:  _item.desc + "\n(Clique para desequipar)",
                    col:   _rcol
                };
                if (mouse_check_button_pressed(mb_left)) inv_unequip_slot(id, _def.key);
            }
        } else {
            draw_text_color(_ex1 + 8, _mid, _def.label + ": Vazio", c_gray, c_gray, c_gray, c_gray, 1);
        }
        draw_set_valign(fa_top);
    }

    // Botao Inventario fixado na base do Cartao 4
    var _inv_y2 = _iy + _ih - 6;
    if (ui_draw_button(_x4 + 8, _inv_y2 - _btn_h, _x4 + _w4 - 8, _inv_y2, "Inventario [I]", c_dkgray, c_yellow)) {
        hud_change_state(id, HUD_STATE.INVENTORY);
    }
}

// =====================================================================
// 2. MODO COMBATE (com visual unificado de cartoes)
// =====================================================================
function hud_draw_combat(_px, _py, _pw, _ph) {
    if (!instance_exists(Obj_Battle)) exit;
    var _b = Obj_Battle;
    var _p = Obj_Player.stats;

    // Coluna esquerda: historico de combate
    var _lx = _px + 16, _ly = _py + 14, _lw = (_pw * 0.44) - 22, _lh = _ph - 28;
    ui_draw_card(_lx, _ly, _lx + _lw, _ly + _lh, "HISTORICO DA BATALHA", c_yellow);

    for (var m = 0; m < array_length(_b.log_messages); m++) {
        draw_text_ext_color(_lx + 10, _ly + 28 + (m * 18), _b.log_messages[m], 16, _lw - 20, c_white, c_white, c_white, c_white, 1);
    }

    // Coluna direita: status e acoes
    var _ax   = _lx + _lw + 12;
    var _ay   = _py + 14;
    var _aw   = (_px + _pw - 16) - _ax;
    var _half = (_aw - 10) / 2;

    ui_draw_card(_ax, _ay, _ax + _aw, _ay + _lh);

    // Cartao do jogador (pisca em vermelho ao levar dano)
    var _in_x    = _ax + 10, _in_y = _ay + 10;
    var _in_w    = _aw - 20;
    var _in_half = (_in_w - 12) / 2;
    var _p_blink = battle_vfx_player_is_blinking(_b);
    var _p_tint  = _p_blink ? c_red : c_white;

    draw_sprite_stretched_ext(_p.portrait, 0, _in_x, _in_y, 50, 50, _p_tint, _p_blink ? 0.65 : 1.0);
    draw_rectangle_color(_in_x, _in_y, _in_x + 50, _in_y + 50, _p_blink ? c_red : make_color_rgb(175, 145, 95), _p_blink ? c_red : make_color_rgb(175, 145, 95), _p_blink ? c_red : make_color_rgb(175, 145, 95), _p_blink ? c_red : make_color_rgb(175, 145, 95), true);

    var _pbx = _in_x + 56, _pbw = _in_half - 56;
    ui_draw_bar(_pbx, _in_y + 2,  _pbw, 17, _p.life, _p.life_max, c_red,  c_maroon, "HP " + string(_p.life) + "/" + string(_p.life_max));
    ui_draw_bar(_pbx, _in_y + 23, _pbw, 17, _p.mp,   _p.mp_max,   c_blue, c_navy,   "MP " + string(_p.mp)   + "/" + string(_p.mp_max));

    // Tags de buffs + estados (DoTs) do JOGADOR
    var _p_tags = "";
    if (_b.player_defending)      _p_tags += "[DEF] ";
    if (_b.buff_armor_turns > 0)  _p_tags += "[BLIND:" + string(_b.buff_armor_turns)  + "] ";
    if (_b.buff_forged_turns > 0) _p_tags += "[FORJ:"  + string(_b.buff_forged_turns) + "] ";
    _p_tags += status_get_tags_string(_b.player_status);
    if (_p_tags != "") draw_text_color(_pbx, _in_y + 42, _p_tags, c_aqua, c_aqua, c_aqua, c_aqua, 1);

    // Cartao do inimigo
    var _ex = _in_x + _in_half + 12;
    draw_text_color(_ex, _in_y, _b.enemy_name, c_yellow, c_yellow, c_yellow, c_yellow, 1);
    ui_draw_bar(_ex, _in_y + 23, _in_half, 17, _b.enemy_hp, _b.enemy_hp_max, c_red, c_maroon, "HP " + string(_b.enemy_hp) + "/" + string(_b.enemy_hp_max));

    // Tags de guarda + estados (DoTs) do INIMIGO
    var _e_tags = _b.enemy_defending ? "[GUARDA] " : "";
    _e_tags += status_get_tags_string(_b.enemy_status);
    if (_e_tags != "") draw_text_color(_ex, _in_y + 42, _e_tags, c_orange, c_orange, c_orange, c_orange, 1);

    // Area de acoes
    var _act_top = _in_y + 60;

    if (_b.state == BATTLE_STATE.VICTORY) {
        if (ui_draw_button(_in_x, _act_top + 10, _in_x + _in_w, _act_top + 52, "CONCLUIR BATALHA", c_dkgray, c_lime)) {
            global.active_enemy = noone;
            instance_destroy(_b);
            hud_change_state(id, HUD_STATE.EXPLORE);
        }
    } else if (_b.state == BATTLE_STATE.DEFEAT) {
        if (ui_draw_button(_in_x, _act_top + 10, _in_x + _in_w, _act_top + 52, "VOLTAR AO MENU", c_maroon, c_white)) {
            instance_destroy(_b);
            room_goto(Room_MainMenu);
        }
    } else if (_b.state == BATTLE_STATE.PLAYER_TURN) {
        var _bw  = (_in_w - 10) / 2, _bh = 28;
        var _b1y = _act_top;
        var _b2y = _b1y + 34;

        if (ui_draw_button(_in_x,            _b1y, _in_x + _bw,  _b1y + _bh, "Atacar",      c_dkgray, c_white))  battle_player_attack(_b);
        if (ui_draw_button(_in_x + _bw + 10, _b1y, _in_x + _in_w,_b1y + _bh, "Defender",    c_dkgray, c_white))  battle_player_defend(_b);
        if (ui_draw_button(_in_x,            _b2y, _in_x + _bw,  _b2y + _bh, "Habilidades", c_dkgray, c_yellow)) { show_skill_wheel = !show_skill_wheel; show_item_options = false; }
        if (ui_draw_button(_in_x + _bw + 10, _b2y, _in_x + _in_w,_b2y + _bh, "Usar Item",   c_dkgray, c_aqua))   hud_change_state(id, HUD_STATE.INVENTORY);
        if (ui_draw_button(_in_x,       _b2y + 34, _in_x + _in_w,_b2y + 58,  "Fugir",       c_maroon, c_white))  battle_player_flee(_b);

        if (show_skill_wheel) {
            var _n_sk = array_length(_p.skills);
            var _skw  = 290, _skh = 38 + (_n_sk * 28);
            var _sky  = _py - _skh - 10;
            var _mx   = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);

            ui_draw_card(_in_x, _sky, _in_x + _skw, _sky + _skh, "HABILIDADES", c_yellow);
            for (var s = 0; s < _n_sk; s++) {
                var _sk  = _p.skills[s];
                var _sby = _sky + 28 + (s * 28);
                var _col = (_p.mp >= _sk.mp) ? c_yellow : c_gray;

                if (point_in_rectangle(_mx, _my, _in_x + 8, _sby, _in_x + _skw - 8, _sby + 24)) {
                    hover_tooltip = { title: _sk.name, sub: "Custo: " + string(_sk.mp) + " MP", desc: _sk.desc, col: c_yellow };
                }
                if (ui_draw_button(_in_x + 8, _sby, _in_x + _skw - 8, _sby + 24, _sk.name + " (" + string(_sk.mp) + " MP)", c_dkgray, _col)) {
                    battle_player_skill(_b, _sk);
                    show_skill_wheel = false;
                }
            }
        }
    } else {
        var _wait_txt = "TURNO DE " + string_upper(_b.enemy_name) + "...";
        if (_b.state == BATTLE_STATE.COMBO_WAIT)                                                _wait_txt = "EXECUTANDO COMBO...";
        else if (_b.state == BATTLE_STATE.WAIT_ROUND_END || _b.state == BATTLE_STATE.ROUND_END) _wait_txt = "EFEITOS DO ROUND...";

        ui_draw_card(_in_x, _act_top + 12, _in_x + _in_w, _act_top + 52);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_text_color(_in_x + _in_w * 0.5, _act_top + 32, _wait_txt, c_yellow, c_yellow, c_yellow, c_yellow, 1);
        draw_set_halign(fa_left); draw_set_valign(fa_top);
    }
}

// =====================================================================
// 3. MODO INVENTARIO: Alinhado exatamente a matriz 8x3 da imagem
// =====================================================================
function hud_draw_inventory(_px, _py, _pw, _ph) {
    var _mx    = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);
    var _click = mouse_check_button_pressed(mb_left);

    // Barra superior externa (nao tampa nenhuma das 24 celulas do sprite)
    var _hdr_h = 30;
    var _hdr_y = _py - _hdr_h - 2;
    ui_draw_card(_px, _hdr_y, _px + _pw, _py - 2);

    var _used = 0;
    for (var k = 0; k < array_length(inv_grid); k++) if (inv_grid[k] != undefined) _used++;
    draw_text_color(_px + 12, _hdr_y + 7, "INVENTARIO (" + string(_used) + "/" + string(inv_cols * inv_rows) + ")", c_yellow, c_yellow, c_yellow, c_yellow, 1);

    if (ui_draw_button(_px + _pw - 110, _hdr_y + 3, _px + _pw - 6, _py - 5, "Voltar [I]", c_dkgray, c_white)) {
        hud_change_state(id, return_state);
    }

    // Grade 8x3 mapeada nas celulas da arte
    var _sel_rect = undefined;
    for (var r = 0; r < inv_rows; r++) {
        for (var c = 0; c < inv_cols; c++) {
            var _idx  = r * inv_cols + c;
            var _rc   = hud_inv_get_slot_rect(_px, _py, _pw, _ph, c, r);
            var _item = inv_grid[_idx];
            var _hov  = point_in_rectangle(_mx, _my, _rc.x1, _rc.y1, _rc.x2, _rc.y2);

            if (_idx == selected_slot) _sel_rect = _rc;

            // Realce de hover ou slot selecionado
            if (_hov || (show_item_options && _idx == selected_slot)) {
                draw_set_alpha(_hov ? 0.28 : 0.20);
                draw_rectangle_color(_rc.x1, _rc.y1, _rc.x2, _rc.y2, c_yellow, c_yellow, c_yellow, c_yellow, false);
                draw_set_alpha(1.0);
                draw_rectangle_color(_rc.x1, _rc.y1, _rc.x2, _rc.y2, c_yellow, c_yellow, c_yellow, c_yellow, true);
            }

            // Desenha o item centralizado na celula + indicador de raridade
            if (_item != undefined && drag_slot != _idx) {
                var _cw   = _rc.x2 - _rc.x1;
                var _ch   = _rc.y2 - _rc.y1;
                var _sz   = min(_cw, _ch) - 6;
                var _ix   = _rc.x1 + (_cw - _sz) * 0.5;
                var _iy   = _rc.y1 + (_ch - _sz) * 0.5;
                var _rcol = ui_get_rarity_color(_item[$ "rarity"] ?? RARITY.COMMON);

                draw_sprite_stretched(_item.sprite, 0, _ix, _iy, _sz, _sz);
                // Pequeno marcador de raridade no canto da celula
                draw_rectangle_color(_rc.x1 + 2, _rc.y1 + 2, _rc.x1 + 7, _rc.y1 + 7, _rcol, _rcol, _rcol, _rcol, false);
            }

            // Tooltip no hover
            if (_hov && _item != undefined && drag_slot == -1) {
                var _rcol = ui_get_rarity_color(_item[$ "rarity"] ?? RARITY.COMMON);
                hover_tooltip = {
                    title: _item.name,
                    sub:   inv_get_item_stats_line(_item),
                    desc:  _item.desc,
                    col:   _rcol
                };
            }

            // Clique seleciona e inicia drag
            if (_click && _hov) {
                if (_item != undefined) {
                    selected_slot     = _idx;
                    show_item_options = true;
                    drag_slot         = _idx;
                } else {
                    show_item_options = false;
                }
            }
        }
    }

    // Menu flutuante de acoes (posicionado ACIMA do inventario, nunca tampando os slots)
    if (show_item_options && selected_slot != -1 && inv_grid[selected_slot] != undefined) {
        var _sel = inv_grid[selected_slot];
        var _mw  = 240, _mh = 76;
        var _anchor_x = (_sel_rect != undefined) ? _sel_rect.x1 : (_px + 20);
        var _mx1 = clamp(_anchor_x, _px, _px + _pw - _mw);
        var _my1 = _hdr_y - _mh - 6;

        ui_draw_card(_mx1, _my1, _mx1 + _mw, _my1 + _mh, _sel.name, ui_get_rarity_color(_sel[$ "rarity"] ?? RARITY.COMMON));

        var _is_equip = (_sel.type == ITEM_TYPE.WEAPON || _sel.type == ITEM_TYPE.EQUIPMENT);
        var _is_file  = (_sel.type == ITEM_TYPE.FILE);
        var _lbl      = _is_equip ? "Equipar" : (_is_file ? "Ler" : "Usar");

        if (ui_draw_button(_mx1 + 10, _my1 + 34, _mx1 + 115, _my1 + 64, _lbl, c_dkgray, c_yellow)) {
            if (_is_file) {
                reading_file = _sel;
            } else if (_is_equip) {
                inv_equip_from_slot(id, selected_slot);
            } else if (return_state == HUD_STATE.COMBAT && instance_exists(Obj_Battle)) {
                battle_player_item(Obj_Battle, selected_slot);
                hud_change_state(id, HUD_STATE.COMBAT);
            } else {
                inv_use_item_explore(id, selected_slot);
            }
            show_item_options = false;
        }

        if (ui_draw_button(_mx1 + 125, _my1 + 34, _mx1 + _mw - 10, _my1 + 64, "Descartar", c_maroon, c_white)) {
            inv_grid[selected_slot] = undefined;
            show_item_options       = false;
        }
    }
}

// Janela simples de leitura para itens do tipo FILE
function hud_draw_file_reader(_lay) {
    var _fw = 460, _fh = 220;
    var _fx = (_lay.sw - _fw) * 0.5;
    var _fy = (_lay.sh - _fh) * 0.35;

    ui_draw_card(_fx, _fy, _fx + _fw, _fy + _fh, reading_file.name, c_yellow);
    draw_text_ext_color(_fx + 14, _fy + 34, reading_file.content, 18, _fw - 28, c_white, c_white, c_white, c_white, 1);

    if (ui_draw_button(_fx + _fw - 110, _fy + _fh - 38, _fx + _fw - 12, _fy + _fh - 10, "Fechar", c_dkgray, c_white)) {
        reading_file = undefined;
    }
}

function hud_draw_minimap() {
    if (!instance_exists(Obj_Builder) || !ds_exists(Obj_Builder.grid, ds_type_grid)) exit;

    var _sc = 3, _ox = 20, _oy = 20;
    var _gw = ds_grid_width(Obj_Builder.grid);
    var _gh = ds_grid_height(Obj_Builder.grid);

    draw_set_alpha(0.8);
    draw_rectangle_color(_ox - 2, _oy - 2, _ox + _gw * _sc + 2, _oy + _gh * _sc + 2, c_black, c_black, c_black, c_black, false);
    draw_set_alpha(1.0);
    draw_rectangle_color(_ox - 2, _oy - 2, _ox + _gw * _sc + 2, _oy + _gh * _sc + 2, c_white, c_white, c_white, c_white, true);

    for (var _yy = 0; _yy < _gh; _yy++) {
        for (var _xx = 0; _xx < _gw; _xx++) {
            var _cell = Obj_Builder.grid[# _xx, _yy];
            if (_cell == Obj_Builder.CELL_VOID) continue;

            var _col = c_dkgray;
            if (_cell == Obj_Builder.CELL_FLOOR) {
                var _b = Obj_Builder.biome_grid[# _xx, _yy];
                if (_b == BIOME.SEWER)        _col = make_color_rgb(30, 80, 30);
                else if (_b == BIOME.CAVE)    _col = make_color_rgb(90, 50, 20);
                else if (_b == BIOME.DUNGEON) _col = make_color_rgb(60, 30, 80);
            }
            var _cx = _ox + _xx * _sc, _cy = _oy + _yy * _sc;
            draw_rectangle_color(_cx, _cy, _cx + _sc - 1, _cy + _sc - 1, _col, _col, _col, _col, false);
        }
    }

    var _cw = Obj_Builder.cell_width, _ch = Obj_Builder.cell_height;
    with (Obj_Enemy) {
        if (!is_dead) {
            var _ex = _ox + (x div _cw) * _sc, _ey = _oy + (y div _ch) * _sc;
            draw_rectangle_color(_ex, _ey, _ex + _sc - 1, _ey + _sc - 1, c_red, c_red, c_red, c_red, false);
        }
    }
    if (instance_exists(Obj_Player)) {
        var _px = _ox + (Obj_Player.x div _cw) * _sc, _py = _oy + (Obj_Player.y div _ch) * _sc;
        draw_rectangle_color(_px, _py, _px + _sc - 1, _py + _sc - 1, c_yellow, c_yellow, c_yellow, c_yellow, false);
    }
    if (instance_exists(Obj_Exit)) {
        var _xx = _ox + (Obj_Exit.x div _cw) * _sc, _xy = _oy + (Obj_Exit.y div _ch) * _sc;
        draw_rectangle_color(_xx, _xy, _xx + _sc - 1, _xy + _sc - 1, c_white, c_white, c_white, c_white, false);
    }
}