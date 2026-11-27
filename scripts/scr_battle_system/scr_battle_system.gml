enum BATTLE_STATE {
    PLAYER_TURN,
    COMBO_WAIT,     // Intervalo entre golpes multiplos (Preciso)
    WAIT_ENEMY,     // Pausa antes do turno inimigo
    ENEMY_TURN,
    WAIT_ROUND_END, // Pausa breve antes dos DoTs de fim de round
    ROUND_END,      // Aplica Incendio/Sangramento e atualiza duracoes
    WAIT_PLAYER,    // Pausa antes de devolver o turno ao jogador
    VICTORY,
    DEFEAT
}

function NewEncounter(_enemy_data) {
    if (instance_exists(Obj_Battle)) instance_destroy(Obj_Battle);
    return instance_create_layer(0, 0, "Instances", Obj_Battle, { enemies: _enemy_data });
}

// Inicializa batalha, estados de ambos os lados e VFX (Contexto: Obj_Battle)
function battle_init() {
    state      = BATTLE_STATE.PLAYER_TURN;
    turn_timer = 0;

    var _data = undefined;
    enemy_type = ENEMY.SLIME;

    if (variable_global_exists("active_enemy") && instance_exists(global.active_enemy)) {
        _data      = global.active_enemy.enemy_data;
        enemy_type = global.active_enemy.enemy_type;
    } else if (variable_instance_exists(id, "enemies") && is_struct(enemies)) {
        _data = enemies;
    }
    if (_data == undefined) {
        if (!variable_global_exists("enemies")) init_enemies();
        _data = global.enemies[ENEMY.SLIME];
    }

    is_flame     = (enemy_type == ENEMY.FLAME);
    is_yesterday = (enemy_type == ENEMY.ME);

    enemy_data_ref    = _data;
    enemy_name        = _data[$ "name"]        ?? "Inimigo";
    enemy_hp_max      = max(1, is_infinity(_data[$ "life"] ?? 10) ? 9999 : (_data[$ "life"] ?? 10));
    enemy_hp          = enemy_hp_max;
    enemy_mp_max      = 0;
    enemy_mp          = 0;
    enemy_attack      = is_infinity(_data[$ "attack"] ?? 3) ? 999 : (_data[$ "attack"] ?? 3);
    enemy_defense     = _data[$ "defense"]     ?? 0;
    enemy_magic       = _data[$ "magic"]       ?? 0;
    enemy_crit_chance = is_infinity(_data[$ "crit_chance"] ?? 5)  ? 100 : (_data[$ "crit_chance"] ?? 5);
    enemy_crit_rate   = is_infinity(_data[$ "crit_rate"]   ?? 50) ? 100 : (_data[$ "crit_rate"]   ?? 50);
    enemy_xp          = _data[$ "xp"]          ?? 5;
    enemy_status_hits = _data[$ "status_on_hit"] ?? [];

    // Dados extras usados pelo O de Ontem
    enemy_skills            = [];
    enemy_inventory         = [];
    enemy_equipped          = [];
    enemy_buff_armor_turns  = 0;
    enemy_buff_forged_turns = 0;

    player_defending  = false;
    enemy_defending   = false;
    buff_armor_turns  = 0;
    buff_forged_turns = 0;

    player_status = status_create_container();
    enemy_status  = status_create_container();

    combo_side      = "player";
    combo_skill     = undefined;
    combo_hits_left = 0;
    combo_timer     = 0;

    log_messages  = [];
    max_log_lines = 8;
    victory_loot  = [];
    xp_gained     = 0;

    add_log = function(_text) { battle_add_log(id, _text); };
    battle_vfx_init();

    // Sobrescreve com os dados completos do ultimo personagem morto
    if (is_yesterday) yesterday_apply_to_battle(id);

    battle_add_log(id, "Um " + enemy_name + " apareceu!");
    if (is_flame) battle_add_log(id, "O calor e insuportavel... nada comum parece feri-lo!");
}

function battle_add_log(_b, _text) {
    with (_b) {
        array_push(log_messages, _text);
        show_debug_message("[BATTLE] " + _text);
        if (array_length(log_messages) > max_log_lines) array_delete(log_messages, 0, 1);
    }
}

function battle_get_player_atk(_b) {
    var _atk = Obj_Player.stats.attack;
    return (_b.buff_forged_turns > 0) ? round(_atk * 1.15) : _atk;
}

function battle_get_player_def(_b) {
    var _def = Obj_Player.stats.defense;
    return (_b.buff_armor_turns > 0) ? (_def * 2) : _def;
}

function battle_calc_damage(_atk, _def, _crit_chance, _crit_rate, _is_defending) {
    var _dmg  = max(1, _atk - (_def / 2));
    var _crit = (random(100) < _crit_chance);
    if (_crit) _dmg *= (1 + (_crit_rate / 100));
    if (_is_defending) _dmg = max(1, _dmg * 0.5);
    return { damage: round(_dmg), is_crit: _crit };
}

function battle_damage_enemy(_b, _dmg, _is_crit = false, _col = undefined, _prefix = "-") {
    with (_b) {
        enemy_hp = max(0, enemy_hp - _dmg);
        enemy_trigger_hit_flash(global.active_enemy, _is_crit ? 0.50 : 0.38);

        var _c   = (_col != undefined) ? _col : (_is_crit ? c_yellow : c_white);
        var _txt = _prefix + string(_dmg) + (_is_crit ? "!" : "");
        battle_vfx_spawn_text(id, _txt, _c, "enemy", _is_crit);
    }
}

function battle_damage_player(_b, _dmg, _is_crit = false, _col = undefined) {
    var _p = Obj_Player.stats;
    _p.life = max(0, _p.life - _dmg);

    battle_vfx_trigger_player_hit(_b, _is_crit);
    var _c   = (_col != undefined) ? _col : (_is_crit ? c_orange : c_red);
    var _txt = "-" + string(_dmg) + (_is_crit ? "!" : "");
    battle_vfx_spawn_text(_b, _txt, _c, "player", _is_crit);
}

// --- ACOES DO JOGADOR ---

function battle_player_attack(_b) {
    with (_b) {
        if (state != BATTLE_STATE.PLAYER_TURN) exit;
		if (is_flame) { battle_flame_kill_player(id, "Seu golpe atravessou o Fagulha e voce virou cinzas!"); exit; }
        if (status_trigger_on_action(id, "player")) exit; // Dano de Congelado ao agir
        player_defending = false;

        // Teste de erro global (+ bonus se Desnorteado)
        if (status_roll_miss(id, "player", "enemy")) {
            state = BATTLE_STATE.WAIT_ENEMY; turn_timer = 0.60;
            exit;
        }

        var _p   = Obj_Player.stats;
        var _res = battle_calc_damage(battle_get_player_atk(id), enemy_defense, _p.crit_chance, _p.crit_rate, enemy_defending);

        battle_damage_enemy(id, _res.damage, _res.is_crit);
        battle_add_log(id, _p.name + " causou " + string(_res.damage) + " de dano!" + (_res.is_crit ? " (CRITICO!)" : ""));
        battle_check_end(id);
    }
}

function battle_player_defend(_b) {
    with (_b) {
        if (state != BATTLE_STATE.PLAYER_TURN) exit;
		if (is_flame) { battle_flame_kill_player(id, "Nenhuma guarda detem o Fagulha! Voce foi incinerado!"); exit; }
        if (status_trigger_on_action(id, "player")) exit;

        player_defending = true;
        battle_vfx_spawn_text(id, "DEFESA!", c_aqua, "player", false);
        battle_add_log(id, Obj_Player.stats.name + " assumiu guarda!");
        state      = BATTLE_STATE.WAIT_ENEMY;
        turn_timer = 0.55;
    }
}

function battle_player_item(_b, _slot_idx) {
    with (_b) {
        if (state != BATTLE_STATE.PLAYER_TURN || !instance_exists(Obj_HUD)) exit;
        var _item = Obj_HUD.inv_grid[_slot_idx];
        if (_item == undefined) exit;

        // UNICA FORMA DE DERROTAR O FAGULHA: Pote de Fume
        if (_item.id == "pot_fume") {
            if (is_flame) {
                Obj_HUD.inv_grid[_slot_idx] = undefined;
                enemy_hp = 0;
                enemy_trigger_hit_flash(global.active_enemy, 0.55);
                battle_vfx_spawn_text(id, "ABAFADO!", c_ltgray, "enemy", true);
                battle_add_log(id, "Voce abriu o Pote de Fume e sufocou o Fagulha!");
                battle_check_end(id);
            } else {
                battle_add_log(id, "O Pote de Fume nao tem efeito contra " + enemy_name + ".");
            }
            exit;
        }

        // Qualquer outro item contra o Fagulha nao o detem
        if (is_flame) {
            battle_flame_kill_player(id, "Voce hesitou com o item errado e o Fagulha o incinerou!");
            exit;
        }

        var _hp = _item[$ "hp_rec"] ?? 0;
        var _mp = _item[$ "mp_rec"] ?? 0;
        if (_item.type != ITEM_TYPE.CONSUMABLE || (_hp <= 0 && _mp <= 0)) {
            battle_add_log(id, "Este item nao pode ser usado em batalha!");
            exit;
        }

        if (status_trigger_on_action(id, "player")) exit;

        var _p = Obj_Player.stats;
        player_defending = false;

        if (_hp > 0) {
            _p.life = min(_p.life_max, _p.life + _hp);
            battle_vfx_spawn_text(id, "+" + string(_hp) + " HP", c_lime, "player", false);
            battle_add_log(id, _p.name + " recuperou " + string(_hp) + " HP!");
        }
        if (_mp > 0) {
            _p.mp = min(_p.mp_max, _p.mp + _mp);
            battle_vfx_spawn_text(id, "+" + string(_mp) + " MP", c_aqua, "player", false);
            battle_add_log(id, _p.name + " recuperou " + string(_mp) + " MP!");
        }

        Obj_HUD.inv_grid[_slot_idx] = undefined;
        state      = BATTLE_STATE.WAIT_ENEMY;
        turn_timer = 0.55;
    }
}

function battle_player_flee(_b) {
    var _cw = Obj_Builder.cell_width, _ch = Obj_Builder.cell_height;
    var _px = Obj_Player.x div _cw,   _py = Obj_Player.y div _ch;
    var _ex = instance_exists(global.active_enemy) ? (global.active_enemy.x div _cw) : -99;
    var _ey = instance_exists(global.active_enemy) ? (global.active_enemy.y div _ch) : -99;

    var _base_back = (round(Obj_Player.dir / 90) * 90 + 180) mod 360;
    var _angles    = [_base_back, (_base_back + 90) mod 360, (_base_back + 270) mod 360];
	
	if (_b.is_flame) { battle_flame_kill_player(_b, "Nao ha como fugir do Fagulha! Ele o alcancou e incinerou!"); exit; }

    for (var i = 0; i < 3; i++) {
        var _tx = _px + round(lengthdir_x(1, _angles[i]));
        var _ty = _py + round(lengthdir_y(1, _angles[i]));
        if (Obj_Builder.grid[# _tx, _ty] == Obj_Builder.CELL_FLOOR && (_tx != _ex || _ty != _ey)) {
            Obj_Player.flee_target_x = _tx * _cw + (_cw / 2);
            Obj_Player.flee_target_y = _ty * _ch + (_ch / 2);
            Obj_Player.is_fleeing    = true;
            break;
        }
    }

    global.active_enemy = noone;
    instance_destroy(_b);
    hud_change_state(Obj_HUD, HUD_STATE.EXPLORE);
}

function battle_teleport_escape(_b) {
    var _gw = ds_grid_width(Obj_Builder.grid), _gh = ds_grid_height(Obj_Builder.grid);
    var _cw = Obj_Builder.cell_width, _ch = Obj_Builder.cell_height;

    for (var tries = 0; tries < 200; tries++) {
        var _rx = irandom(_gw - 1), _ry = irandom(_gh - 1);
        if (Obj_Builder.grid[# _rx, _ry] == Obj_Builder.CELL_FLOOR) {
            var _wx = _rx * _cw + (_cw / 2), _wy = _ry * _ch + (_ch / 2);
            Obj_Player.x        = _wx; Obj_Player.y        = _wy;
            Obj_Player.target_x = _wx; Obj_Player.target_y = _wy;
            break;
        }
    }

    global.active_enemy = noone;
    instance_destroy(_b);
    hud_change_state(Obj_HUD, HUD_STATE.EXPLORE);
}

// Aplica possiveis estados configurados em enemies.gml quando o inimigo acerta o golpe
function battle_enemy_roll_statuses(_b) {
    var _list = _b.enemy_status_hits;
    if (!is_array(_list)) exit;

    for (var i = 0; i < array_length(_list); i++) {
        var _st = _list[i];
        if (random(100) < _st.chance) {
            status_apply(_b, "player", _st.status, _st.turns, _st[$ "dmg"]);
        }
    }
}

// --- LOOP DE TURNOS, PAUSAS E FIM DE ROUND ---

function battle_step(_b) {
    var _dt = min(delta_time / 1000000, 0.05);
    battle_vfx_step(_b, _dt);

    with (_b) {
        switch (state) {
            case BATTLE_STATE.COMBO_WAIT:
                combo_timer -= _dt;
                if (combo_timer <= 0) {
                    var _hit = 4 - combo_hits_left;
                    if (combo_side == "enemy") {
                        var _res = battle_calc_damage(battle_get_enemy_atk(id), battle_get_player_def(id), enemy_crit_chance, enemy_crit_rate, player_defending);
                        battle_damage_player(id, _res.damage, _res.is_crit);
                        battle_add_log(id, enemy_name + " - Preciso [" + string(_hit) + "/3] (" + string(_res.damage) + " de dano)!");
                        combo_hits_left--;
                        if (Obj_Player.stats.life <= 0) { battle_trigger_defeat(id); exit; }
                        if (combo_hits_left <= 0) {
                            state = status_has_end_round_dots(id) ? BATTLE_STATE.WAIT_ROUND_END : BATTLE_STATE.ROUND_END;
                            turn_timer = 0.45;
                        } else combo_timer = 0.22;
                    } else {
                        var _p   = Obj_Player.stats;
                        var _pwr = (combo_skill != undefined) ? battle_get_skill_power(id, combo_skill) : battle_get_player_atk(id);
                        var _res = battle_calc_damage(_pwr, battle_get_enemy_def(id), _p.crit_chance, _p.crit_rate, enemy_defending);
                        battle_damage_enemy(id, _res.damage, _res.is_crit);
                        battle_add_log(id, "Preciso [" + string(_hit) + "/3] causou " + string(_res.damage) + " de dano!");
                        combo_hits_left--;
                        if (enemy_hp <= 0 || combo_hits_left <= 0) battle_check_end(id);
                        else combo_timer = 0.22;
                    }
                }
                break;

            case BATTLE_STATE.WAIT_ENEMY:
                turn_timer -= _dt;
                if (turn_timer <= 0) state = BATTLE_STATE.ENEMY_TURN;
                break;

            case BATTLE_STATE.ENEMY_TURN:
                if (!instance_exists(Obj_Player)) exit;
                enemy_defending = false;

                if (is_flame) {
                    battle_flame_kill_player(id, "O Fagulha consumiu tudo ao seu redor!");
                    exit;
                }

                if (enemy_status[STATUS.STUN].turns > 0) {
                    enemy_status[STATUS.STUN].turns--;
                    battle_vfx_spawn_text(id, "NOCAUTEADO!", c_yellow, "enemy", false);
                    battle_add_log(id, enemy_name + " esta Nocauteado e perdeu o turno!");
                } else {
                    if (status_trigger_on_action(id, "enemy")) exit;

                    if (is_yesterday) {
                        yesterday_take_turn(id);
                        if (state == BATTLE_STATE.COMBO_WAIT) exit; // Aguarda combo terminar
                    } else if (random(100) < 70) {
                        if (!status_roll_miss(id, "enemy", "player")) {
                            var _res = battle_calc_damage(battle_get_enemy_atk(id), battle_get_player_def(id), enemy_crit_chance, enemy_crit_rate, player_defending);
                            battle_damage_player(id, _res.damage, _res.is_crit);
                            battle_add_log(id, enemy_name + " causou " + string(_res.damage) + " de dano!" + (_res.is_crit ? " (CRITICO!)" : ""));
                            if (Obj_Player.stats.life > 0) battle_enemy_roll_statuses(id);
                        }
                    } else {
                        enemy_defending = true;
                        battle_vfx_spawn_text(id, "GUARDA!", c_ltgray, "enemy", false);
                        battle_add_log(id, enemy_name + " esta em guarda!");
                    }
                }

                if (Obj_Player.stats.life <= 0) {
                    battle_trigger_defeat(id);
                } else if (status_has_end_round_dots(id)) {
                    state      = BATTLE_STATE.WAIT_ROUND_END;
                    turn_timer = 0.45;
                } else {
                    state = BATTLE_STATE.ROUND_END;
                }
                break;

            case BATTLE_STATE.WAIT_ROUND_END:
                turn_timer -= _dt;
                if (turn_timer <= 0) state = BATTLE_STATE.ROUND_END;
                break;

            // Fim do round: aplica Incendio e Sangramento + atualiza buffs e duracoes
            case BATTLE_STATE.ROUND_END:
                var _had_dots = status_has_end_round_dots(id);
                if (status_process_round_end(id)) exit;

                player_defending = false;
                if (buff_armor_turns        > 0) buff_armor_turns--;
                if (buff_forged_turns       > 0) buff_forged_turns--;
                if (enemy_buff_armor_turns  > 0) enemy_buff_armor_turns--;
                if (enemy_buff_forged_turns > 0) enemy_buff_forged_turns--;

                state      = BATTLE_STATE.WAIT_PLAYER;
                turn_timer = _had_dots ? 0.55 : 0.45;
                break;

            case BATTLE_STATE.WAIT_PLAYER:
                turn_timer -= _dt;
                if (turn_timer <= 0) {
                    // Se o jogador estiver Nocauteado, pula o turno dele automaticamente
                    if (player_status[STATUS.STUN].turns > 0) {
                        player_status[STATUS.STUN].turns--;
                        battle_vfx_spawn_text(id, "NOCAUTEADO!", c_yellow, "player", false);
                        battle_add_log(id, Obj_Player.stats.name + " esta Nocauteado e perdeu o turno!");
                        state      = BATTLE_STATE.WAIT_ENEMY;
                        turn_timer = 0.85;
                    } else {
                        state = BATTLE_STATE.PLAYER_TURN;
                    }
                }
                break;
        }
    }
}

function battle_check_end(_b) {
    with (_b) {
        if (enemy_hp > 0) {
            state      = BATTLE_STATE.WAIT_ENEMY;
            turn_timer = 0.65;
            exit;
        }

        state = BATTLE_STATE.VICTORY;

        if (variable_global_exists("active_enemy") && instance_exists(global.active_enemy)) {
            with (global.active_enemy) {
                is_dead = true;
                if (sprite_exists(sprite_dead)) sprite_index = sprite_dead;
            }
        }

        battle_add_log(id, "--- VITORIA! ---");
        battle_add_log(id, "Derrotou " + enemy_name + " (+" + string(enemy_xp) + " XP)!");
        xp_gained = enemy_xp;
        player_gain_xp(xp_gained);
		
		if (is_yesterday) {
            yesterday_grant_loot(id);
        }

        victory_loot = generate_loot(enemy_data_ref);
        for (var i = 0; i < array_length(victory_loot); i++) {
            var _drop = victory_loot[i];
            battle_add_log(id, "Dropou: " + _drop.name);
            for (var s = 0; s < array_length(Obj_HUD.inv_grid); s++) {
                if (Obj_HUD.inv_grid[s] == undefined) { Obj_HUD.inv_grid[s] = _drop; break; }
            }
        }
    }
}

// Calcula o poder bruto da skill com base no atributo configurado (Attack ou Magic)
function battle_get_skill_power(_b, _skill) {
    var _stat = _skill[$ "stat"] ?? SKILL_STAT.NONE;
    var _mult = _skill[$ "mult"] ?? 0;

    if (_stat == SKILL_STAT.ATTACK) return round(battle_get_player_atk(_b) * _mult);
    if (_stat == SKILL_STAT.MAGIC)  return round(Obj_Player.stats.magic * _mult);
    return 0;
}

// Aplica todos os estados/DoTs definidos na struct da skill em characters.gml
function battle_apply_skill_statuses(_b, _skill, _target_side = "enemy") {
    var _list = _skill[$ "statuses"];
    if (!is_array(_list)) exit;

    for (var i = 0; i < array_length(_list); i++) {
        var _st = _list[i];
        if (random(100) < _st.chance) {
            var _turns = irandom_range(_st.turns_min, _st.turns_max);
            status_apply(_b, _target_side, _st.status, _turns, _st.dmg);
        }
    }
}

function battle_player_skill(_b, _skill) {
    with (_b) {
        if (state != BATTLE_STATE.PLAYER_TURN) exit;
		if (is_flame) { battle_flame_kill_player(id, "O Fagulha devorou sua habilidade e reduziu voce a cinzas!"); exit; }
        var _p = Obj_Player.stats;

        if (_p.mp < _skill.mp) {
            battle_add_log(id, "MP insuficiente para " + _skill.name + "!");
            exit;
        }

        _p.mp -= _skill.mp;
        player_defending = false;

        // Dano de Congelado sempre que o jogador agir
        if (status_trigger_on_action(id, "player")) exit;

        switch (_skill.name) {
            // --- MECANICAS ESPECIAIS ---
            case "Blindagem":
                buff_armor_turns = 3;
                battle_vfx_spawn_text(id, "DEF x2!", c_aqua, "player", false);
                battle_add_log(id, _p.name + " ativou Blindagem (DEF dobrada por 3 rounds)!");
                state = BATTLE_STATE.WAIT_ENEMY; turn_timer = 0.55;
                break;

            case "Forjado":
                buff_forged_turns = 2;
                battle_vfx_spawn_text(id, "ATK +15%!", c_orange, "player", false);
                battle_add_log(id, _p.name + " ativou Forjado (ATK 1.15x por 2 rounds)!");
                state = BATTLE_STATE.WAIT_ENEMY; turn_timer = 0.55;
                break;

            case "Escolhido":
                battle_teleport_escape(id);
                exit;

            case "Head Shot":
                if (random(100) < 15) {
                    battle_damage_enemy(id, enemy_hp, true, c_yellow);
                    battle_vfx_spawn_text(id, "HEAD SHOT!", c_yellow, "enemy", true);
                    battle_add_log(id, "HEAD SHOT! Abate instantaneo em " + enemy_name + "!");
                    battle_check_end(id);
                } else {
                    battle_vfx_spawn_text(id, "ERROU!", c_ltgray, "enemy", false);
                    battle_add_log(id, _p.name + " errou o Head Shot!");
                    state = BATTLE_STATE.WAIT_ENEMY; turn_timer = 0.60;
                }
                break;

            case "Preciso":
                // 3 golpes seguidos usando o atributo/mult da skill, ignorando erro
                var _pwr = battle_get_skill_power(id, _skill);
                var _res = battle_calc_damage(_pwr, enemy_defense, _p.crit_chance, _p.crit_rate, enemy_defending);
                battle_damage_enemy(id, _res.damage, _res.is_crit, _skill[$ "color"]);
                battle_add_log(id, _p.name + " disparou Preciso [1/3] (" + string(_res.damage) + " de dano)!");

                if (enemy_hp <= 0) {
                    battle_check_end(id);
                } else {
                    combo_skill     = _skill;
                    combo_hits_left = 2;
                    combo_timer     = 0.22;
                    state           = BATTLE_STATE.COMBO_WAIT;
                }
                break;

            // --- TODAS AS SKILLS DE DANO (ATTACK/MAGIC) E/OU STATUS ---
            default:
                var _stat = _skill[$ "stat"] ?? SKILL_STAT.NONE;
                var _mult = _skill[$ "mult"] ?? 0;

                if (_stat != SKILL_STAT.NONE && _mult > 0) {
                    if (status_roll_miss(id, "player", "enemy")) {
                        state = BATTLE_STATE.WAIT_ENEMY; turn_timer = 0.60;
                        exit;
                    }

                    var _pwr = battle_get_skill_power(id, _skill);
                    var _res = battle_calc_damage(_pwr, enemy_defense, _p.crit_chance, _p.crit_rate, enemy_defending);
                    var _col = _res.is_crit ? c_yellow : (_skill[$ "color"] ?? c_white);

                    battle_damage_enemy(id, _res.damage, _res.is_crit, _col);
                    battle_add_log(id, _p.name + " usou " + _skill.name + " (" + string(_res.damage) + " de dano)!" + (_res.is_crit ? " (CRITICO!)" : ""));

                    if (enemy_hp > 0) battle_apply_skill_statuses(id, _skill);
                    battle_check_end(id);
                } else {
                    // Skill de status puro (Impreciso, Sectum, Invisibilis, etc.)
                    battle_apply_skill_statuses(id, _skill);
                    state = BATTLE_STATE.WAIT_ENEMY; turn_timer = 0.55;
                }
                break;
        }
    }
}

// --- ADICIONE ESTES HELPERS EM scr_battle_system.gml ---

// Centraliza derrota e registra o personagem morto como o proximo "O de Ontem"
function battle_trigger_defeat(_b) {
    with (_b) {
        if (state == BATTLE_STATE.DEFEAT) exit;
        state = BATTLE_STATE.DEFEAT;
        yesterday_save_from_battle(id);
        battle_add_log(id, "--- VOCE FOI DERROTADO! ---");
    }
}

// Morte instantanea causada pelo Fagulha (qualquer acao que nao seja Pote de Fume)
function battle_flame_kill_player(_b, _msg) {
    with (_b) {
        if (instance_exists(Obj_Player)) {
            battle_damage_player(id, max(999, Obj_Player.stats.life), true, c_orange);
        }
        battle_vfx_spawn_text(id, "INCINERADO!", c_orange, "player", true);
        battle_add_log(id, _msg);
        battle_trigger_defeat(id);
    }
}

function battle_get_enemy_atk(_b) {
    return (_b.enemy_buff_forged_turns > 0) ? round(_b.enemy_attack * 1.15) : _b.enemy_attack;
}

function battle_get_enemy_def(_b) {
    return (_b.enemy_buff_armor_turns > 0) ? (_b.enemy_defense * 2) : _b.enemy_defense;
}