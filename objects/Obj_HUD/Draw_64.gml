if (!instance_exists(Obj_Player)) exit;

var _p = Obj_Player.stats;

var _height = display_get_gui_height();
var _width  = display_get_gui_width();

var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
var _click = mouse_check_button_pressed(mb_left);

var _sprite_w = _width / 1.15;
var _sprite_h = _height / 3;
var _x        = (_width - _sprite_w) / 2;
var _target_y = _height - _sprite_h;

d3d_set_fog(false, c_black, 1, 1);

// -------------------------------------------------------------
// A) BOTÕES GERAIS NA LATERAL DA HUD (DIREITA)
// -------------------------------------------------------------
var _side_w = 110;
var _side_h = 36;
var _side_x = _x + _sprite_w + 10; // Posiciona na lateral externa direita da HUD

// Impede que o botão saia da tela em resoluções menores
if (_side_x + _side_w > _width) _side_x = _width - _side_w - 5;

// 1. Configurações
var _cfg_y = _target_y + 15;
if (draw_ui_button(_side_x, _cfg_y, _side_x + _side_w, _cfg_y + _side_h, "Config", c_dkgray, c_white)) {
    show_debug_message("Abrir Configurações");
}

// 2. Desistir
var _give_y = _cfg_y + _side_h + 10;
if (draw_ui_button(_side_x, _give_y, _side_x + _side_w, _give_y + _side_h, "Desistir", c_maroon, c_white)) {
    game_restart();
}


// -------------------------------------------------------------
// B) DESENHO DOS PAINÉIS DE CADA ESTADO
// -------------------------------------------------------------
var _draw_hud_panel = function(_state, _px, _py, _pw, _ph) {
    var _p = Obj_Player.stats;
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    var _click = mouse_check_button_pressed(mb_left);

    // Background do Estado
    var _bg_sprite = bg_explore;
    switch (_state) {
        case HUD_STATE.EXPLORE:   _bg_sprite = bg_explore; break;
        case HUD_STATE.COMBAT:    _bg_sprite = bg_combat; break;
        case HUD_STATE.INVENTORY: _bg_sprite = bg_inventory; break;
    }
    draw_sprite_stretched(_bg_sprite, 0, _px, _py, _pw, _ph);

    switch (_state) {
        
        // --- 1. MODO EXPLORAR (STATS COMPLETOS) ---
		case HUD_STATE.EXPLORE:
		    // A) Foto do Personagem (88x88px)
		    var _port_size = 88;
		    draw_sprite_stretched(_p.portrait, 0, _px + 20, _py + 20, _port_size, _port_size);
		    draw_rectangle_color(_px + 20, _py + 20, _px + 20 + _port_size, _py + 20 + _port_size, c_black, c_black, c_black, c_black, true);

		    // B) Nome, Classe, Nível e Indicador de Mantra
		    var _text_x = _px + 120;
		    var _name_str = _p.name + " (" + _p.class_name + ")";
		    draw_text_transformed(_text_x, _py + 16, _name_str, 1.1, 1.1, 0);

		    // Exibe o nível e se o personagem despertou Mantra
		    var _lvl_str = "Lvl " + string(_p.level);
		    draw_text_color(_text_x, _py + 38, _lvl_str, c_yellow, c_yellow, c_yellow, c_yellow, 1);

		    var _mantra_str = _p.is_mantra ? "[MANTRA]" : "[SEM MANTRA]";
		    var _mantra_col = _p.is_mantra ? c_aqua : c_dkgray;
		    draw_text_color(_text_x + 55, _py + 38, _mantra_str, _mantra_col, _mantra_col, _mantra_col, _mantra_col, 1);

		    // C) Barras Principais (HP, MP e EXP)
		    var _bar_w = 200;
		    var _bar_h = 16;
		    var _hp_y  = _py + 58;

		    // 1. Barra de HP
		    draw_rectangle_color(_text_x, _hp_y, _text_x + _bar_w, _hp_y + _bar_h, c_black, c_black, c_black, c_black, false);
		    draw_rectangle_color(_text_x, _hp_y, _text_x + (_bar_w * clamp(_p.life / _p.life_max, 0, 1)), _hp_y + _bar_h, c_red, c_red, c_maroon, c_maroon, false);
		    draw_rectangle_color(_text_x, _hp_y, _text_x + _bar_w, _hp_y + _bar_h, c_white, c_white, c_white, c_white, true);
		    draw_text(_text_x + 6, _hp_y + 1, "HP: " + string(_p.life) + "/" + string(_p.life_max));

		    // 2. Barra de MP
		    var _mp_y = _hp_y + _bar_h + 4;
		    draw_rectangle_color(_text_x, _mp_y, _text_x + _bar_w, _mp_y + _bar_h, c_black, c_black, c_black, c_black, false);
		    draw_rectangle_color(_text_x, _mp_y, _text_x + (_bar_w * clamp(_p.mp / _p.mp_max, 0, 1)), _mp_y + _bar_h, c_blue, c_blue, c_navy, c_navy, false);
		    draw_rectangle_color(_text_x, _mp_y, _text_x + _bar_w, _mp_y + _bar_h, c_white, c_white, c_white, c_white, true);
		    draw_text(_text_x + 6, _mp_y + 1, "MP: " + string(_p.mp) + "/" + string(_p.mp_max));

		    // 3. Barra de EXP (Calcula próximo nível com base em 100 * lvl)
		    var _xp_next = _p.level * 100;
		    var _xp_y = _mp_y + _bar_h + 4;
		    draw_rectangle_color(_text_x, _xp_y, _text_x + _bar_w, _xp_y + _bar_h, c_black, c_black, c_black, c_black, false);
		    draw_rectangle_color(_text_x, _xp_y, _text_x + (_bar_w * clamp(_p.xp / _xp_next, 0, 1)), _xp_y + _bar_h, c_lime, c_lime, c_green, c_green, false);
		    draw_rectangle_color(_text_x, _xp_y, _text_x + _bar_w, _xp_y + _bar_h, c_white, c_white, c_white, c_white, true);
		    draw_text(_text_x + 6, _xp_y + 1, "EXP: " + string(_p.xp) + "/" + string(_xp_next));

		    // D) Grid de Atributos de Combate (Centro/Direita do Painel)
		    var _stat_x1 = _text_x + _bar_w + 30;
		    var _stat_x2 = _stat_x1 + 100;
    
		    // Coluna 1: Status Base
		    draw_text(_stat_x1, _py + 20, "ATK: " + string(_p.attack));
		    draw_text(_stat_x1, _py + 48, "DEF: " + string(_p.defense));
		    draw_text(_stat_x1, _py + 76, "MAG: " + string(_p.magic));

		    // Coluna 2: Status Críticos
		    draw_text(_stat_x2, _py + 20, "Crit %: " + string(_p.crit_chance) + "%");
		    draw_text(_stat_x2, _py + 48, "Crit Rate: " + string(_p.crit_rate) + "%");

		    // E) Botão do Inventário (Canto Direito)
		    var _inv_bx1 = _px + _pw - 155;
		    var _inv_by1 = _py + 35;
		    if (draw_ui_button(_inv_bx1, _inv_by1, _inv_bx1 + 135, _inv_by1 + 45, "Inventário [I]", c_dkgray, c_yellow)) {
		        change_hud_state(HUD_STATE.INVENTORY);
		    }
		    break;

       // --- 2. MODO COMBATE (DIVIDIDO EM DUAS COLUNAS) ---
		case HUD_STATE.COMBAT:
		    if (!instance_exists(Obj_Battle)) break;
		    var _b = Obj_Battle;

		    // ---------------------------------------------------------
		    // LADO ESQUERDO: HISTÓRICO DE COMBATE (LOGS)
		    // ---------------------------------------------------------
		    var _log_x = _px + 20;
		    var _log_y = _py + 15;
		    var _log_w = (_pw / 2) - 30;
		    var _log_h = _ph - 30;

		    // Painel do Log
		    draw_rectangle_color(_log_x, _log_y, _log_x + _log_w, _log_y + _log_h, c_black, c_black, c_black, c_black, false);
		    draw_rectangle_color(_log_x, _log_y, _log_x + _log_w, _log_y + _log_h, c_white, c_white, c_white, c_white, true);

		    draw_text_color(_log_x + 10, _log_y + 8, "HISTÓRICO DA BATALHA", c_yellow, c_yellow, c_yellow, c_yellow, 1);
		    draw_line_color(_log_x + 10, _log_y + 26, _log_x + _log_w - 10, _log_y + 26, c_white, c_white);

		    // Renderiza cada mensagem da lista
		    for (var m = 0; m < array_length(_b.log_messages); m++) {
		        draw_text_ext_color(_log_x + 10, _log_y + 32 + (m * 18), _b.log_messages[m], 16, _log_w - 20, c_white, c_white, c_white, c_white, 1);
		    }

		    // ---------------------------------------------------------
		    // LADO DIREITO: STATUS DO INIMIGO E PAINEL DE AÇÕES
		    // ---------------------------------------------------------
		    var _act_x = _px + (_pw / 2) + 10;
		    var _act_y = _py + 15;
		    var _act_w = (_pw / 2) - 30;

		    // Status do Inimigo (Nome e Barra de HP)
		    draw_text_transformed(_act_x, _act_y, _b.enemy_name, 1.1, 1.1, 0);

		    var _e_bar_w = _act_w;
		    var _e_bar_h = 16;
		    var _e_hp_y  = _act_y + 25;
		    draw_rectangle_color(_act_x, _e_hp_y, _act_x + _e_bar_w, _e_hp_y + _e_bar_h, c_black, c_black, c_black, c_black, false);
		    draw_rectangle_color(_act_x, _e_hp_y, _act_x + (_e_bar_w * clamp(_b.enemy_hp / _b.enemy_hp_max, 0, 1)), _e_hp_y + _e_bar_h, c_red, c_red, c_maroon, c_maroon, false);
		    draw_rectangle_color(_act_x, _e_hp_y, _act_x + _e_bar_w, _e_hp_y + _e_bar_h, c_white, c_white, c_white, c_white, true);
		    draw_text(_act_x + 6, _e_hp_y + 1, "HP Inimigo: " + string(_b.enemy_hp) + "/" + string(_b.enemy_hp_max));

		    // A) SE A BATALHA TERMINOU (VITÓRIA OU DERROTA)
		    if (_b.state == BATTLE_STATE.VICTORY) {
			    if (draw_ui_button(_act_x, _act_y + 70, _act_x + _act_w, _act_y + 115, "CONCLUIR BATALHA", c_dkgray, c_lime)) {
        
			        // Aplica o estado de morto na instância gravada em global.active_enemy
			        if (variable_global_exists("active_enemy") && instance_exists(global.active_enemy)) {
			            with (global.active_enemy) {
			                is_dead = true;
                
			                // Se houver um sprite de cadáver válido, substitui o sprite_index
			                if (variable_instance_exists(id, "sprite_dead") && sprite_exists(sprite_dead)) {
			                    sprite_index = sprite_dead;
			                }
			            }
			            // Limpa a variável global
			            global.active_enemy = noone;
			        }

			        instance_destroy(_b);
			        change_hud_state(HUD_STATE.EXPLORE);
			    }
			}
		    else if (_b.state == BATTLE_STATE.DEFEAT) {
		        if (draw_ui_button(_act_x, _act_y + 70, _act_x + _act_w, _act_y + 115, "VOLTAR AO MENU", c_maroon, c_white)) {
		            instance_destroy(_b);
		            room_goto(rm_main_menu); // Nome da room do seu Menu Principal
		        }
		    } 
		    // B) TURNO DO JOGADOR (BOTÕES DE AÇÃO)
		    else if (_b.state == BATTLE_STATE.PLAYER_TURN) {
		        var _bw = (_act_w - 10) / 2;
		        var _bh = 32;
		        var _b1_y = _act_y + 55;
		        var _b2_y = _b1_y + 38;

		        // 1. Botão Atacar
		        if (draw_ui_button(_act_x, _b1_y, _act_x + _bw, _b1_y + _bh, "Atacar", c_dkgray, c_white)) {
		            _b.player_attack();
		        }

		        // 2. Botão Defender
		        if (draw_ui_button(_act_x + _bw + 10, _b1_y, _act_x + (_bw * 2) + 10, _b1_y + _bh, "Defender", c_dkgray, c_white)) {
		            _b.player_defend();
		        }

		        // 3. Botão Habilidades (Abre Roda/Submenu)
		        if (draw_ui_button(_act_x, _b2_y, _act_x + _bw, _b2_y + _bh, "Habilidades", c_dkgray, c_yellow)) {
		            show_skill_wheel = !show_skill_wheel;
		            show_item_options = false;
		        }

		        // 4. Botão Usar Item (Abre Inventário Rápido)
		        if (draw_ui_button(_act_x + _bw + 10, _b2_y, _act_x + (_bw * 2) + 10, _b2_y + _bh, "Usar Item", c_dkgray, c_aqua)) {
		            change_hud_state(HUD_STATE.INVENTORY);
		        }

		        // 5. Botão Fugir
		        if (draw_ui_button(_act_x, _b2_y + 38, _act_x + _act_w, _b2_y + 38 + 26, "Fugir", c_maroon, c_white)) {
		            // Executa o recuo de fuga
		            var _cw = Obj_Builder.cell_width;
		            var _ch = Obj_Builder.cell_height;
		            var _back_dir = (round(Obj_Player.dir / 90) * 90 + 180) mod 360;
		            var _target_gx = (Obj_Player.x div _cw) + round(lengthdir_x(1, _back_dir));
		            var _target_gy = (Obj_Player.y div _ch) + round(lengthdir_y(1, _back_dir));

		            if (Obj_Builder.grid[# _target_gx, _target_gy] == Obj_Builder.CELL_FLOOR) {
		                Obj_Player.flee_target_x = _target_gx * _cw + (_cw / 2);
		                Obj_Player.flee_target_y = _target_gy * _ch + (_ch / 2);
		                Obj_Player.is_fleeing    = true;
		            }
		            instance_destroy(_b);
		            change_hud_state(HUD_STATE.EXPLORE);
		        }

		        // --- SUBMENU DE HABILIDADES ---
		        if (show_skill_wheel) {
		            var _sk_w = 220;
		            var _sk_x = _act_x;
		            var _sk_y = _py - 120;
            
		            draw_rectangle_color(_sk_x, _sk_y, _sk_x + _sk_w, _sk_y + 110, c_black, c_black, c_dkgray, c_dkgray, false);
		            draw_rectangle_color(_sk_x, _sk_y, _sk_x + _sk_w, _sk_y + 110, c_white, c_white, c_white, c_white, true);
		            draw_text(_sk_x + 10, _sk_y + 8, "SELECIONE A HABILIDADE:");

		            for (var s = 0; s < array_length(_p.skills); s++) {
		                var _sk = _p.skills[s];
		                var _sk_btn_y = _sk_y + 30 + (s * 26);
		                if (draw_ui_button(_sk_x + 10, _sk_btn_y, _sk_x + _sk_w - 10, _sk_btn_y + 22, _sk.name + " (" + string(_sk.mp) + " MP)", c_dkgray, c_yellow)) {
		                    _b.player_use_skill(_sk);
		                    show_skill_wheel = false;
		                }
		            }
		        }
		    }
		    break;

        // --- 3. MODO INVENTÁRIO (ALINHADO AO SPRITE) ---
        case HUD_STATE.INVENTORY:
            draw_text(_px + 20, _py + 15, "INVENTÁRIO");

            // Matriz 4x4 calculada com base nos offsets do Create
            for (var r = 0; r < inv_rows; r++) {
                for (var c = 0; c < inv_cols; c++) {
                    var _idx = r * inv_cols + c;
                    
                    var _sx = _px + inv_offset_x + c * (inv_cell_w + inv_space_x);
                    var _sy = _py + inv_offset_y + r * (inv_cell_h + inv_space_y);

                    // Desenha o fundo escuro opcional (se inv_draw_slot_bg for true)
                    if (inv_draw_slot_bg) {
                        draw_rectangle_color(_sx, _sy, _sx + inv_cell_w, _sy + inv_cell_h, c_dkgray, c_dkgray, c_black, c_black, false);
                    }

                    // Destaque ao passar o mouse por cima do slot da arte
                    if (point_in_rectangle(_mx, _my, _sx, _sy, _sx + inv_cell_w, _sy + inv_cell_h)) {
                        draw_set_alpha(0.3);
                        draw_rectangle_color(_sx, _sy, _sx + inv_cell_w, _sy + inv_cell_h, c_yellow, c_yellow, c_yellow, c_yellow, false);
                        draw_set_alpha(1.0);
                    }

                    // Desenha o item no slot
                    var _item = inv_grid[_idx];
                    if (_item != undefined && drag_slot != _idx) {
                        var _icon_size = min(inv_cell_w, inv_cell_h) - 8;
                        draw_sprite_stretched(_item.sprite, 0, _sx + (inv_cell_w - _icon_size) / 2, _sy + (inv_cell_h - _icon_size) / 2, _icon_size, _icon_size);
                    }

                    // Clique no Slot
                    if (_click && point_in_rectangle(_mx, _my, _sx, _sy, _sx + inv_cell_w, _sy + inv_cell_h)) {
                        if (_item != undefined) {
                            selected_slot     = _idx;
                            show_item_options = true;
                            drag_slot         = _idx;
                        }
                    }
                }
            }

            // Submenu de Opções do Item
            if (show_item_options && selected_slot != -1 && inv_grid[selected_slot] != undefined) {
                var _sel_item = inv_grid[selected_slot];
                var _menu_x   = _px + 20;
                var _menu_y   = _py + 45;

                draw_rectangle_color(_menu_x, _menu_y, _menu_x + 220, _menu_y + 110, c_black, c_black, c_dkgray, c_dkgray, false);
                draw_rectangle_color(_menu_x, _menu_y, _menu_x + 220, _menu_y + 110, c_white, c_white, c_white, c_white, true);
                
                draw_text(_menu_x + 10, _menu_y + 8, _sel_item.name);
                draw_text_ext(_menu_x + 10, _menu_y + 26, _sel_item.desc, 14, 200);

                var _btn_label = (_sel_item.type == "equip") ? "[Equipar]" : "[Usar]";
                if (draw_ui_button(_menu_x + 10, _menu_y + 75, _menu_x + 90, _menu_y + 98, _btn_label, c_dkgray, c_yellow)) {
                    show_debug_message("Ação: " + _btn_label + " " + _sel_item.name);
                    show_item_options = false;
                }

                if (draw_ui_button(_menu_x + 110, _menu_y + 75, _menu_x + 200, _menu_y + 98, "[Descartar]", c_maroon, c_white)) {
                    inv_grid[selected_slot] = undefined;
                    show_item_options = false;
                }
            }

            // Botão Voltar
            var _back_bx1 = _px + 20;
            var _back_by1 = _py + _ph - 45;
            if (draw_ui_button(_back_bx1, _back_by1, _back_bx1 + 100, _back_by1 + 35, "Voltar", c_dkgray, c_white)) {
                change_hud_state(return_state);
            }
            break;
    }
};


// -------------------------------------------------------------
// C) EXECUÇÃO DA ANIMAÇÃO E RENDERIZAÇÃO
// -------------------------------------------------------------
if (!is_animating) {
    _draw_hud_panel(hud_state, _x, _target_y, _sprite_w, _sprite_h);
} else {
    _draw_hud_panel(previous_hud_state, _x, _target_y, _sprite_w, _sprite_h);
    var _eased = ease_out_cubic(anim_progress);
    var _slide_y = lerp(_height, _target_y, _eased);
    _draw_hud_panel(hud_state, _x, _slide_y, _sprite_w, _sprite_h);
}


// -------------------------------------------------------------
// D) ITEM ARRASTADO (DRAG & DROP)
// -------------------------------------------------------------
if (drag_slot != -1 && inv_grid[drag_slot] != undefined && mouse_check_button(mb_left)) {
    var _drag_item = inv_grid[drag_slot];
    draw_sprite_stretched(_drag_item.sprite, 0, _mx - 20, _my - 20, 40, 40);
}

// -------------------------------------------------------------
// MINIMAPA DE TESTES (PAREDES, JOGADOR E INIMIGOS)
// -------------------------------------------------------------
if (instance_exists(Obj_Builder) && ds_exists(Obj_Builder.grid, ds_type_grid)) {
    var _scale = 3;  // Tamanho de cada bloco da grade em pixels na tela
    var _off_x = 20; // Posição X na tela
    var _off_y = 20; // Posição Y na tela

    var _gw = ds_grid_width(Obj_Builder.grid);
    var _gh = ds_grid_height(Obj_Builder.grid);

    // 1. Moldura do Minimapa
    draw_set_alpha(0.8);
    draw_rectangle_color(_off_x - 2, _off_y - 2, _off_x + (_gw * _scale) + 2, _off_y + (_gh * _scale) + 2, c_black, c_black, c_black, c_black, false);
    draw_set_alpha(1.0);
    draw_rectangle_color(_off_x - 2, _off_y - 2, _off_x + (_gw * _scale) + 2, _off_y + (_gh * _scale) + 2, c_white, c_white, c_white, c_white, true);

    // 2. Renderização da Grade (Paredes e Biomas)
    for (var _yy = 0; _yy < _gh; _yy++) {
        for (var _xx = 0; _xx < _gw; _xx++) {
            var _cell = Obj_Builder.grid[# _xx, _yy];
            var _cx   = _off_x + (_xx * _scale);
            var _cy   = _off_y + (_yy * _scale);

            if (_cell == Obj_Builder.CELL_WALL) {
                // Paredes em cinza escuro
                draw_rectangle_color(_cx, _cy, _cx + _scale - 1, _cy + _scale - 1, c_dkgray, c_dkgray, c_dkgray, c_dkgray, false);
            } else if (_cell == Obj_Builder.CELL_FLOOR) {
                // Cor do chão baseada no bioma local
                var _b = Obj_Builder.biome_grid[# _xx, _yy];
                var _b_color = c_gray;
                if (_b == BIOME.SEWER)   _b_color = make_color_rgb(30, 80, 30);  // Verde (Esgoto)
                if (_b == BIOME.CAVE)    _b_color = make_color_rgb(90, 50, 20);  // Marrom (Caverna)
                if (_b == BIOME.DUNGEON) _b_color = make_color_rgb(60, 30, 80);  // Roxo (Calabouço)

                draw_rectangle_color(_cx, _cy, _cx + _scale - 1, _cy + _scale - 1, _b_color, _b_color, _b_color, _b_color, false);
            }
        }
    }

    // 3. Renderização dos Inimigos (Pontos Vermelhos)
    with (Obj_Enemy) {
        var _ex  = x div Obj_Builder.cell_width;
        var _ey  = y div Obj_Builder.cell_height;
        var _ecx = _off_x + (_ex * _scale);
        var _ecy = _off_y + (_ey * _scale);

        draw_rectangle_color(_ecx, _ecy, _ecx + _scale - 1, _ecy + _scale - 1, c_red, c_red, c_red, c_red, false);
    }

    // 4. Renderização do Jogador (Ponto Amarelo)
    if (instance_exists(Obj_Player)) {
        var _px  = Obj_Player.x div Obj_Builder.cell_width;
        var _py  = Obj_Player.y div Obj_Builder.cell_height;
        var _pcx = _off_x + (_px * _scale);
        var _pcy = _off_y + (_py * _scale);

        draw_rectangle_color(_pcx, _pcy, _pcx + _scale - 1, _pcy + _scale - 1, c_yellow, c_yellow, c_yellow, c_yellow, false);
    }
	
	if (instance_exists(Obj_Exit)) {
        var _px  = Obj_Exit.x div Obj_Builder.cell_width;
        var _py  = Obj_Exit.y div Obj_Builder.cell_height;
        var _pcx = _off_x + (_px * _scale);
        var _pcy = _off_y + (_py * _scale);

        draw_rectangle_color(_pcx, _pcy, _pcx + _scale - 1, _pcy + _scale - 1, c_white, c_white, c_white, c_white, false);
    }
}