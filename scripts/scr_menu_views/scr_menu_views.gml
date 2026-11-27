enum MENU_STATE { MAIN, CHAR_SELECT, CONFIG }

// Captura digitacao do nome do personagem (Contexto: Obj_MainMenu)
function menu_handle_typing() {
    if (menu_state != MENU_STATE.CHAR_SELECT || !typing_name) exit;

    if (string_length(keyboard_string) <= 12) {
        input_name = keyboard_string;
    } else {
        keyboard_string = input_name;
    }

    if (keyboard_check_pressed(vk_enter)) typing_name = false;
}

// Despacha a tela ativa do menu (Contexto: Obj_MainMenu)
function menu_draw_gui() {
    var _sw = display_get_gui_width();
    var _sh = display_get_gui_height();

    draw_set_halign(fa_center);
    draw_text_transformed(_sw / 2, 40, "CRAWLING IN MY SKIN", 2, 2, 0);
    draw_set_halign(fa_left);

    switch (menu_state) {
        case MENU_STATE.MAIN:        menu_draw_main(_sw, _sh); break;
        case MENU_STATE.CHAR_SELECT: menu_draw_char_select(_sw, _sh); break;
        case MENU_STATE.CONFIG:      menu_draw_config(_sw, _sh); break;
    }

    ui_draw_brightness_overlay();
}

function menu_draw_main(_sw, _sh) {
    var _bw = 220, _bh = 45;
    var _bx = (_sw - _bw) / 2;
    var _by = _sh / 2 - 40;

    if (ui_draw_button(_bx, _by,       _bx + _bw, _by + _bh,       "JOGAR",         c_dkgray, c_yellow)) {
        keyboard_string = input_name;
        menu_state = MENU_STATE.CHAR_SELECT;
    }
    if (ui_draw_button(_bx, _by + 65,  _bx + _bw, _by + 65 + _bh,  "CONFIGURACOES", c_dkgray, c_white)) {
        menu_state = MENU_STATE.CONFIG;
    }
    if (ui_draw_button(_bx, _by + 130, _bx + _bw, _by + 130 + _bh, "SAIR",          c_maroon, c_white)) {
        game_end();
    }
}

function menu_draw_char_select(_sw, _sh) {
    var _mx = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);
    var _click = mouse_check_button_pressed(mb_left);
    var _pw = 500, _ph = 320;
    var _px = (_sw - _pw) / 2, _py = (_sh - _ph) / 2;

    draw_rectangle_color(_px, _py, _px + _pw, _py + _ph, c_black, c_black, c_dkgray, c_dkgray, false);
    draw_rectangle_color(_px, _py, _px + _pw, _py + _ph, c_white, c_white, c_white, c_white, true);
    draw_text(_px + 20, _py + 20, "CRIACAO DE PERSONAGEM");

    // Campo de nome
    draw_text(_px + 20, _py + 60, "Nome:");
    var _ix1 = _px + 80, _iy1 = _py + 55, _ix2 = _px + 300, _iy2 = _py + 85;
    var _box_col = typing_name ? c_navy : c_black;
    draw_rectangle_color(_ix1, _iy1, _ix2, _iy2, _box_col, _box_col, _box_col, _box_col, false);
    draw_rectangle_color(_ix1, _iy1, _ix2, _iy2, c_white, c_white, c_white, c_white, true);

    var _cursor = (typing_name && (current_time % 1000 < 500)) ? "|" : "";
    draw_text(_ix1 + 10, _iy1 + 5, input_name + _cursor);

    if (_click) {
        typing_name = point_in_rectangle(_mx, _my, _ix1, _iy1, _ix2, _iy2);
        if (typing_name) keyboard_string = input_name;
    }

    // Seletor de classe
    var _cls = classes_list[selected_class_idx];
    var _len = array_length(classes_list);
    draw_text(_px + 20, _py + 110, "Classe:");

    if (ui_draw_button(_px + 80,  _py + 105, _px + 110, _py + 135, "<", c_dkgray, c_white)) {
        selected_class_idx = (selected_class_idx - 1 + _len) mod _len;
    }
    draw_set_halign(fa_center);
    draw_text_color(_px + 190, _py + 112, _cls.name, c_yellow, c_yellow, c_yellow, c_yellow, 1);
    draw_set_halign(fa_left);

    if (ui_draw_button(_px + 270, _py + 105, _px + 300, _py + 135, ">", c_dkgray, c_white)) {
        selected_class_idx = (selected_class_idx + 1) mod _len;
    }

    // Retrato e descricao
    draw_sprite_stretched(_cls.portrait, 0, _px + 330, _py + 55, 120, 120);
    draw_rectangle_color(_px + 330, _py + 55, _px + 450, _py + 175, c_white, c_white, c_white, c_white, true);
    draw_text_ext(_px + 20, _py + 155, _cls.desc, 18, 290);

    // Iniciar / Voltar
    if (ui_draw_button(_px + 40, _py + _ph - 55, _px + 220, _py + _ph - 15, "INICIAR JOGO", c_dkgray, c_lime)) {
        global.player_start_name  = (input_name == "") ? "Heroi" : input_name;
        global.player_start_class = selected_class_idx;
        room_goto(Room_3D);
    }
    if (ui_draw_button(_px + 280, _py + _ph - 55, _px + 460, _py + _ph - 15, "VOLTAR", c_dkgray, c_white)) {
        menu_state = MENU_STATE.MAIN;
    }
}

function menu_draw_config(_sw, _sh) {
    var _pw = 460, _ph = 300;
    var _px = (_sw - _pw) / 2, _py = (_sh - _ph) / 2;

    draw_rectangle_color(_px, _py, _px + _pw, _py + _ph, c_black, c_black, c_dkgray, c_dkgray, false);
    draw_rectangle_color(_px, _py, _px + _pw, _py + _ph, c_white, c_white, c_white, c_white, true);
    draw_text(_px + 20, _py + 20, "CONFIGURACOES DE AUDIO E VIDEO");

    // Musica
    draw_text(_px + 30, _py + 70, "Musica: " + string(global.vol_music) + "%");
    if (ui_draw_button(_px + 240, _py + 65, _px + 280, _py + 95, "-", c_dkgray, c_white)) {
        global.vol_music = clamp(global.vol_music - 10, 0, 100);
        audio_master_gain(global.vol_music / 100);
    }
    if (ui_draw_button(_px + 290, _py + 65, _px + 330, _py + 95, "+", c_dkgray, c_white)) {
        global.vol_music = clamp(global.vol_music + 10, 0, 100);
        audio_master_gain(global.vol_music / 100);
    }

    // SFX
    draw_text(_px + 30, _py + 120, "Efeitos SFX: " + string(global.vol_sfx) + "%");
    if (ui_draw_button(_px + 240, _py + 115, _px + 280, _py + 145, "-", c_dkgray, c_white)) {
        global.vol_sfx = clamp(global.vol_sfx - 10, 0, 100);
    }
    if (ui_draw_button(_px + 290, _py + 115, _px + 330, _py + 145, "+", c_dkgray, c_white)) {
        global.vol_sfx = clamp(global.vol_sfx + 10, 0, 100);
    }

    // Brilho
    draw_text(_px + 30, _py + 170, "Brilho: " + string(global.brightness) + "%");
    if (ui_draw_button(_px + 240, _py + 165, _px + 280, _py + 195, "-", c_dkgray, c_white)) {
        global.brightness = clamp(global.brightness - 10, 50, 150);
    }
    if (ui_draw_button(_px + 290, _py + 165, _px + 330, _py + 195, "+", c_dkgray, c_white)) {
        global.brightness = clamp(global.brightness + 10, 50, 150);
    }

    if (ui_draw_button(_px + 140, _py + _ph - 50, _px + 320, _py + _ph - 15, "VOLTAR", c_dkgray, c_white)) {
        menu_state = MENU_STATE.MAIN;
    }
}