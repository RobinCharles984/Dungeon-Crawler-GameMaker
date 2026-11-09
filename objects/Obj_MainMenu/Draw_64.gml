/// Evento Draw GUI de Obj_MainMenu

var _sw = display_get_gui_width();
var _sh = display_get_gui_height();

var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _click = mouse_check_button_pressed(mb_left);

// -------------------------------------------------------------
// TITULO DO JOGO
// -------------------------------------------------------------
draw_set_halign(fa_center);
draw_text_transformed(_sw / 2, 40, "CRAWLING IN MY SKIN", 2, 2, 0);
draw_set_halign(fa_left);

switch (menu_state) {
    
    // =========================================================
    // 1. TELA PRINCIPAL (PLAY, CONFIG, SAIR)
    // =========================================================
    case MENU_STATE.MAIN:
        var _bw = 220;
        var _bh = 45;
        var _bx = (_sw - _bw) / 2;
        var _by_start = _sh / 2 - 40;

        // Botão Jogar
        if (draw_ui_button(_bx, _by_start, _bx + _bw, _by_start + _bh, "JOGAR", c_dkgray, c_yellow)) {
            keyboard_string = input_name;
            menu_state = MENU_STATE.CHAR_SELECT;
        }

        // Botão Configurações
        if (draw_ui_button(_bx, _by_start + 65, _bx + _bw, _by_start + 65 + _bh, "CONFIGURAÇÕES", c_dkgray, c_white)) {
            menu_state = MENU_STATE.CONFIG;
        }

        // Botão Sair
        if (draw_ui_button(_bx, _by_start + 130, _bx + _bw, _by_start + 130 + _bh, "SAIR", c_maroon, c_white)) {
            game_end();
        }
        break;

    // =========================================================
    // 2. SELEÇÃO DE CLASSE E NOME DO PERSONAGEM
    // =========================================================
    case MENU_STATE.CHAR_SELECT:
        var _panel_w = 500;
        var _panel_h = 320;
        var _px = (_sw - _panel_w) / 2;
        var _py = (_sh - _panel_h) / 2;

        // Fundo do Painel
        draw_rectangle_color(_px, _py, _px + _panel_w, _py + _panel_h, c_black, c_black, c_dkgray, c_dkgray, false);
        draw_rectangle_color(_px, _py, _px + _panel_w, _py + _panel_h, c_white, c_white, c_white, c_white, true);

        draw_text(_px + 20, _py + 20, "CRIAÇÃO DE PERSONAGEM");

        // A) CAMPO DE NOME
        draw_text(_px + 20, _py + 60, "Nome:");
        var _input_x1 = _px + 80;
        var _input_y1 = _py + 55;
        var _input_x2 = _px + 300;
        var _input_y2 = _py + 85;

        var _box_col = typing_name ? c_navy : c_black;
        draw_rectangle_color(_input_x1, _input_y1, _input_x2, _input_y2, _box_col, _box_col, _box_col, _box_col, false);
        draw_rectangle_color(_input_x1, _input_y1, _input_x2, _input_y2, c_white, c_white, c_white, c_white, true);
        
        var _cursor = (typing_name && (current_time % 1000 < 500)) ? "|" : "";
        draw_text(_input_x1 + 10, _input_y1 + 5, input_name + _cursor);

        if (_click && point_in_rectangle(_mx, _my, _input_x1, _input_y1, _input_x2, _input_y2)) {
            typing_name = true;
            keyboard_string = input_name;
        } else if (_click) {
            typing_name = false;
        }

        // B) SELETOR DE CLASSE
        var _cls = classes_list[selected_class_idx];
        
        draw_text(_px + 20, _py + 110, "Classe:");
        
        // Botão Anterior (<)
        if (draw_ui_button(_px + 80, _py + 105, _px + 110, _py + 135, "<", c_dkgray, c_white)) {
            selected_class_idx = (selected_class_idx - 1 + array_length(classes_list)) mod array_length(classes_list);
        }

        // Nome da Classe Selecionada
        draw_set_halign(fa_center);
        draw_text_color(_px + 190, _py + 112, _cls.name, c_yellow, c_yellow, c_yellow, c_yellow, 1);
        draw_set_halign(fa_left);

        // Botão Próximo (>)
        if (draw_ui_button(_px + 270, _py + 105, _px + 300, _py + 135, ">", c_dkgray, c_white)) {
            selected_class_idx = (selected_class_idx + 1) mod array_length(classes_list);
        }

        // Retrato e Descrição da Classe
        draw_sprite_stretched(_cls.portrait, 0, _px + 330, _py + 55, 120, 120);
        draw_rectangle_color(_px + 330, _py + 55, _px + 450, _py + 175, c_white, c_white, c_white, c_white, true);
        
        draw_text_ext(_px + 20, _py + 155, _cls.desc, 18, 290);

        // C) BOTÕES INICIAR / VOLTAR
        if (draw_ui_button(_px + 40, _py + _panel_h - 55, _px + 220, _py + _panel_h - 15, "INICIAR JOGO", c_dkgray, c_lime)) {
		    // Guarda o nome e o ÍNDICE NUMÉRICO (0, 1, 2) da classe escolhida
		    global.player_start_name  = (input_name == "") ? "Herói" : input_name;
		    global.player_start_class = selected_class_idx; // Envia 0, 1 ou 2 em vez de texto!

		    room_goto(Room_3D); // Nome da sua room principal
		}

        if (draw_ui_button(_px + 280, _py + _panel_h - 55, _px + 460, _py + _panel_h - 15, "VOLTAR", c_dkgray, c_white)) {
            menu_state = MENU_STATE.MAIN;
        }
        break;

    // =========================================================
    // 3. TELA DE CONFIGURAÇÕES (BRILHO, MÚSICA, SFX)
    // =========================================================
    case MENU_STATE.CONFIG:
        var _panel_w = 460;
        var _panel_h = 300;
        var _px = (_sw - _panel_w) / 2;
        var _py = (_sh - _panel_h) / 2;

        draw_rectangle_color(_px, _py, _px + _panel_w, _py + _panel_h, c_black, c_black, c_dkgray, c_dkgray, false);
        draw_rectangle_color(_px, _py, _px + _panel_w, _py + _panel_h, c_white, c_white, c_white, c_white, true);

        draw_text(_px + 20, _py + 20, "CONFIGURAÇÕES DE ÁUDIO E VÍDEO");

        // A) MÚSICA
        draw_text(_px + 30, _py + 70, "Música: " + string(global.vol_music) + "%");
        if (draw_ui_button(_px + 240, _py + 65, _px + 280, _py + 95, "-", c_dkgray, c_white)) {
            global.vol_music = clamp(global.vol_music - 10, 0, 100);
            audio_master_gain(global.vol_music / 100);
        }
        if (draw_ui_button(_px + 290, _py + 65, _px + 330, _py + 95, "+", c_dkgray, c_white)) {
            global.vol_music = clamp(global.vol_music + 10, 0, 100);
            audio_master_gain(global.vol_music / 100);
        }

        // B) EFEITOS (SFX)
        draw_text(_px + 30, _py + 120, "Efeitos SFX: " + string(global.vol_sfx) + "%");
        if (draw_ui_button(_px + 240, _py + 115, _px + 280, _py + 145, "-", c_dkgray, c_white)) {
            global.vol_sfx = clamp(global.vol_sfx - 10, 0, 100);
        }
        if (draw_ui_button(_px + 290, _py + 115, _px + 330, _py + 145, "+", c_dkgray, c_white)) {
            global.vol_sfx = clamp(global.vol_sfx + 10, 0, 100);
        }

        // C) BRILHO
        draw_text(_px + 30, _py + 170, "Brilho: " + string(global.brightness) + "%");
        if (draw_ui_button(_px + 240, _py + 165, _px + 280, _py + 195, "-", c_dkgray, c_white)) {
            global.brightness = clamp(global.brightness - 10, 50, 150);
        }
        if (draw_ui_button(_px + 290, _py + 165, _px + 330, _py + 195, "+", c_dkgray, c_white)) {
            global.brightness = clamp(global.brightness + 10, 50, 150);
        }

        // Botão Voltar
        if (draw_ui_button(_px + 140, _py + _panel_h - 50, _px + 320, _py + _panel_h - 15, "VOLTAR", c_dkgray, c_white)) {
            menu_state = MENU_STATE.MAIN;
        }
        break;
}

// --- OVERLAY GLOBAL DE AJUSTE DE BRILHO ---
if (variable_global_exists("brightness") && global.brightness != 100) {
    var _sw = display_get_gui_width();
    var _sh = display_get_gui_height();

    if (global.brightness < 100) {
        // Para brilho menor que 100%, desenha um rect preto semitransparente
        var _alpha = (100 - global.brightness) / 100 * 0.7;
        draw_set_alpha(_alpha);
        draw_rectangle_color(0, 0, _sw, _sh, c_black, c_black, c_black, c_black, false);
    } else {
        // Para brilho maior que 100%, desenha um rect branco semitransparente
        var _alpha = (global.brightness - 100) / 100 * 0.4;
        draw_set_alpha(_alpha);
        draw_rectangle_color(0, 0, _sw, _sh, c_white, c_white, c_white, c_white, false);
    }
    draw_set_alpha(1.0);
}// --- OVERLAY GLOBAL DE AJUSTE DE BRILHO ---
if (variable_global_exists("brightness") && global.brightness != 100) {
    var _sw = display_get_gui_width();
    var _sh = display_get_gui_height();

    if (global.brightness < 100) {
        // Para brilho menor que 100%, desenha um rect preto semitransparente
        var _alpha = (100 - global.brightness) / 100 * 0.7;
        draw_set_alpha(_alpha);
        draw_rectangle_color(0, 0, _sw, _sh, c_black, c_black, c_black, c_black, false);
    } else {
        // Para brilho maior que 100%, desenha um rect branco semitransparente
        var _alpha = (global.brightness - 100) / 100 * 0.4;
        draw_set_alpha(_alpha);
        draw_rectangle_color(0, 0, _sw, _sh, c_white, c_white, c_white, c_white, false);
    }
    draw_set_alpha(1.0);
}// --- OVERLAY GLOBAL DE AJUSTE DE BRILHO ---
if (variable_global_exists("brightness") && global.brightness != 100) {
    var _sw = display_get_gui_width();
    var _sh = display_get_gui_height();

    if (global.brightness < 100) {
        // Para brilho menor que 100%, desenha um rect preto semitransparente
        var _alpha = (100 - global.brightness) / 100 * 0.7;
        draw_set_alpha(_alpha);
        draw_rectangle_color(0, 0, _sw, _sh, c_black, c_black, c_black, c_black, false);
    } else {
        // Para brilho maior que 100%, desenha um rect branco semitransparente
        var _alpha = (global.brightness - 100) / 100 * 0.4;
        draw_set_alpha(_alpha);
        draw_rectangle_color(0, 0, _sw, _sh, c_white, c_white, c_white, c_white, false);
    }
    draw_set_alpha(1.0);
}