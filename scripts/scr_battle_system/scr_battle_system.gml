enum BATTLE_STATE {
    PLAYER_TURN,
    COMBO_WAIT,  // Intervalo entre golpes multiplos (skill Preciso)
    WAIT_ENEMY,  // Pausa apos acao do jogador antes do inimigo agir
    ENEMY_TURN,
    WAIT_PLAYER, // Pausa apos acao do inimigo antes de liberar botoes
    VICTORY,
    DEFEAT
}

function NewEncounter(_enemy_data) {
    if (instance_exists(Obj_Battle)) instance_destroy(Obj_Battle);
    return instance_create_layer(0, 0, "Instances", Obj_Battle, { enemies: _enemy_data });
}

// Inicializa batalha, status e VFX (Contexto: Obj_Battle)
function battle_init() {
    state      = BATTLE_STATE.PLAYER_TURN;
    turn_timer = 0;

    // Resolve dados do inimigo ativo
    var _data = undefined;
    if (variable_global_exists("active_enemy") && instance_exists(global.active_enemy)) {
        _data = global.active_enemy.enemy_data;
    } else if (variable_instance_exists(id, "enemies") && is_struct(enemies)) {
        _data = enemies;
    }
    if (_data == undefined) {
        if (!variable_global_exists("enemies")) init_enemies();
        _data = global.enemies[ENEMY.SLIME];
    }

    enemy_data_ref    = _data;
    enemy_name        = _data[$ "name"]        ?? "Inimigo";
    enemy_hp_max      = max(1, is_infinity(_data[$ "life"] ?? 10) ? 9999 : (_data[$ "life"] ?? 10));
    enemy_hp          = enemy_hp_max;
    enemy_attack      = is_infinity(_data[$ "attack"] ?? 3) ? 999 : (_data[$ "attack"] ?? 3);
    enemy_defense     = _data[$ "defense"]     ?? 0;
    enemy_magic       = _data[$ "magic"]       ?? 0;
    enemy_crit_chance = is_infinity(_data[$ "crit_chance"] ?? 5)  ? 100 : (_data[$ "crit_chance"] ?? 5);
    enemy_crit_rate   = is_infinity(_data[$ "crit_rate"]   ?? 50) ? 100 : (_data[$ "crit_rate"]   ?? 50);
    enemy_xp          = _data[$ "xp"]          ?? 5;

    // Defesa e buffs do jogador
    player_defending  = false;
    buff_armor_turns  = 0; // Blindagem: 2x DEF
    buff_forged_turns = 0; // Forjado: 1.15x ATK

    // Defesa e debuffs do inimigo
    enemy_defending        = false;
    enemy_stun_turns       = 0; // Nocauteado (pula turno)
    enemy_inaccurate_turns = 0; // Impreciso (erra ataques)
    enemy_bleed_turns      = 0; // Sangramento (dano por turno)
    enemy_bleed_dmg        = 0;
    enemy_burn_turns       = 0; // Incendio (dano por turno)
    enemy_burn_dmg         = 0;

    // Controle de combo (Preciso: 3 ataques seguidos)
    combo_hits_left = 0;
    combo_timer     = 0;

    // Log e recompensas
    log_messages  = [];
    max_log_lines = 8;
    victory_loot  = [];
    xp_gained     = 0;

    // Compatibilidade com player_gain_xp() em characters.gml
    add_log = function(_text) { battle_add_log(id, _text); };

    battle_vfx_init();
    battle_add_log(id, "Um " + enemy_name + " apareceu!");
}

function battle_add_log(_b, _text) {
    with (_b) {
        array_push(log_messages, _text);
        show_debug_message("[BATTLE] " + _text);
        if (array_length(log_messages) > max_log_lines) array_delete(log_messages, 0, 1);
    }
}

// Helpers de atributos efetivos com buffs aplicados
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

// Aplica dano ao inimigo + piscar 3D + texto flutuante
function battle_damage_enemy(_b, _dmg, _is_crit = false, _col = undefined, _prefix = "-") {
    with (_b) {
        enemy_hp = max(0, enemy_hp - _dmg);
        enemy_trigger_hit_flash(global.active_enemy, _is_crit ? 0.50 : 0.38);

        var _c   = (_col != undefined) ? _col : (_is_crit ? c_yellow : c_white);
        var _txt = _prefix + string(_dmg) + (_is_crit ? "!" : "");
        battle_vfx_spawn_text(id, _txt, _c, "enemy", _is_crit);
    }
}

// Aplica dano ao jogador + flash/tremor + texto flutuante
function battle_damage_player(_b, _dmg, _is_crit = false) {
    var _p = Obj_Player.stats;
    _p.life = max(0, _p.life - _dmg);

    battle_vfx_trigger_player_hit(_b, _is_crit);
    var _txt = "-" + string(_dmg) + (_is_crit ? "!" : "");
    battle_vfx_spawn_text(_b, _txt, _is_crit ? c_orange : c_red, "player", _is_crit);
}

// --- ACOES DO JOGADOR ---

function battle_player_attack(_b) {
    with (_b) {
        if (state != BATTLE_STATE.PLAYER_TURN) exit;
        player_defending = false;

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
        player_defending = true;
        battle_vfx_spawn_text(id, "DEFESA!", c_aqua, "player", false);
        battle_add_log(id, Obj_Player.stats.name + " assumiu guarda!");
        state      = BATTLE_STATE.WAIT_ENEMY;
        turn_timer = 0.55;
    }
}

function battle_player_skill(_b, _skill) {
    with (_b) {
        if (state != BATTLE_STATE.PLAYER_TURN) exit;
        var _p = Obj_Player.stats;

        if (_p.mp < _skill.mp) {
            battle_add_log(id, "MP insuficiente para " + _skill.name + "!");
            exit;
        }
        _p.mp -= _skill.mp;
        player_defending = false;

        var _atk = battle_get_player_atk(id);
        var _mag = _p.magic;

        switch (_skill.name) {
            // --- AGRESSIVO ---
            case "Concussão": case "Concussao":
                var _res = battle_calc_damage(round(_atk * 1.50), enemy_defense, _p.crit_chance, _p.crit_rate, enemy_defending);
                battle_damage_enemy(id, _res.damage, _res.is_crit);
                battle_add_log(id, _p.name + " usou Concussao (" + string(_res.damage) + " de dano)!");
                if (enemy_hp > 0 && random(100) < 45) {
                    enemy_stun_turns = max(enemy_stun_turns, 1);
                    battle_vfx_spawn_text(id, "NOCAUTEADO!", c_yellow, "enemy", false);
                    battle_add_log(id, enemy_name + " ficou Nocauteado!");
                }
                battle_check_end(id);
                break;

            case "Blindagem":
                buff_armor_turns = 3;
                battle_vfx_spawn_text(id, "DEF x2!", c_aqua, "player", false);
                battle_add_log(id, _p.name + " ativou Blindagem (DEF dobrada por 3 turnos)!");
                state = BATTLE_STATE.WAIT_ENEMY; turn_timer = 0.55;
                break;

            case "Escolhido":
                battle_teleport_escape(id);
                exit;

            case "Forjado":
                buff_forged_turns = 2;
                battle_vfx_spawn_text(id, "ATK +15%!", c_orange, "player", false);
                battle_add_log(id, _p.name + " ativou Forjado (ATK 1.15x por 2 turnos)!");
                state = BATTLE_STATE.WAIT_ENEMY; turn_timer = 0.55;
                break;

            // --- LANCADOR ---
            case "Perfuração": case "Perfuracao":
                var _res = battle_calc_damage(round(_atk * 1.70), enemy_defense, _p.crit_chance, _p.crit_rate, enemy_defending);
                battle_damage_enemy(id, _res.damage, _res.is_crit);
                battle_add_log(id, _p.name + " usou Perfuracao (" + string(_res.damage) + " de dano)!");
                if (enemy_hp > 0 && random(100) < 50) {
                    enemy_bleed_turns = 3;
                    enemy_bleed_dmg   = clamp(round(enemy_hp_max * 0.10), 2, 15);
                    battle_vfx_spawn_text(id, "SANGRANDO!", c_red, "enemy", false);
                    battle_add_log(id, enemy_name + " esta Sangrando por 3 turnos!");
                }
                battle_check_end(id);
                break;

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
                // Primeiro golpe imediato + 2 golpes em fila (COMBO_WAIT)
                var _res = battle_calc_damage(_atk, enemy_defense, _p.crit_chance, _p.crit_rate, enemy_defending);
                battle_damage_enemy(id, _res.damage, _res.is_crit);
                battle_add_log(id, _p.name + " disparou Preciso [1/3] (" + string(_res.damage) + " de dano)!");
                if (enemy_hp <= 0) {
                    battle_check_end(id);
                } else {
                    combo_hits_left = 2;
                    combo_timer     = 0.22;
                    state           = BATTLE_STATE.COMBO_WAIT;
                }
                break;

            case "Impreciso":
                var _dur = irandom_range(1, 4);
                enemy_inaccurate_turns = max(enemy_inaccurate_turns, _dur);
                battle_vfx_spawn_text(id, "IMPRECISO!", c_fuchsia, "enemy", false);
                battle_add_log(id, enemy_name + " ficou Impreciso por " + string(_dur) + " turnos!");
                state = BATTLE_STATE.WAIT_ENEMY; turn_timer = 0.55;
                break;

            // --- INVOCADOR ---
            case "Fogo":
                var _res = battle_calc_damage(round(_mag * 2.0), enemy_defense, _p.crit_chance, _p.crit_rate, enemy_defending);
                battle_damage_enemy(id, _res.damage, _res.is_crit, c_orange);
                battle_add_log(id, _p.name + " lancou Fogo (" + string(_res.damage) + " de dano)!");
                if (enemy_hp > 0 && random(100) < 67) {
                    enemy_burn_turns = 3;
                    enemy_burn_dmg   = max(2, round(_mag * 0.35));
                    battle_vfx_spawn_text(id, "INCENDIO!", c_orange, "enemy", false);
                    battle_add_log(id, enemy_name + " pegou fogo!");
                }
                battle_check_end(id);
                break;

            case "Gelo":
                var _res = battle_calc_damage(round(_mag * 1.45), enemy_defense, _p.crit_chance, _p.crit_rate, enemy_defending);
                battle_damage_enemy(id, _res.damage, _res.is_crit, c_aqua);
                battle_add_log(id, _p.name + " lancou Gelo (" + string(_res.damage) + " de dano)!");
                if (enemy_hp > 0 && random(100) < 80) {
                    enemy_stun_turns = max(enemy_stun_turns, 1);
                    battle_vfx_spawn_text(id, "NOCAUTEADO!", c_aqua, "enemy", false);
                    battle_add_log(id, enemy_name + " foi congelado/Nocauteado!");
                }
                battle_check_end(id);
                break;

            case "Sectum":
                var _dur = irandom_range(2, 5);
                enemy_bleed_turns = max(enemy_bleed_turns, _dur);
                enemy_bleed_dmg   = clamp(round(enemy_hp_max * 0.12), 3, 18);
                battle_vfx_spawn_text(id, "SANGRANDO!", c_red, "enemy", false);
                battle_add_log(id, "Sectum causou Sangramento por " + string(_dur) + " turnos!");
                state = BATTLE_STATE.WAIT_ENEMY; turn_timer = 0.55;
                break;

            case "Invisibilis":
                var _dur = irandom_range(3, 6);
                enemy_inaccurate_turns = max(enemy_inaccurate_turns, _dur);
                battle_vfx_spawn_text(id, "INVISIVEL!", c_aqua, "player", false);
                battle_add_log(id, enemy_name + " ficou Impreciso por " + string(_dur) + " turnos!");
                state = BATTLE_STATE.WAIT_ENEMY; turn_timer = 0.55;
                break;

            // Fallback generico
            default:
                var _res = battle_calc_damage(_mag + 5, enemy_defense, _p.crit_chance, _p.crit_rate, enemy_defending);
                battle_damage_enemy(id, _res.damage, _res.is_crit);
                battle_add_log(id, _p.name + " usou " + _skill.name + " (" + string(_res.damage) + " de dano)!");
                battle_check_end(id);
                break;
        }
    }
}

function battle_player_item(_b, _slot_idx) {
    with (_b) {
        if (state != BATTLE_STATE.PLAYER_TURN || !instance_exists(Obj_HUD)) exit;
        var _item = Obj_HUD.inv_grid[_slot_idx];
        if (_item == undefined || _item.type != ITEM_TYPE.CONSUMABLE) {
            battle_add_log(id, "Item nao utilizavel em batalha!");
            exit;
        }

        var _p = Obj_Player.stats;
        player_defending = false;

        if ((_item[$ "hp_rec"] ?? 0) > 0) {
            _p.life = min(_p.life_max, _p.life + _item.hp_rec);
            battle_vfx_spawn_text(id, "+" + string(_item.hp_rec) + " HP", c_lime, "player", false);
            battle_add_log(id, _p.name + " recuperou " + string(_item.hp_rec) + " HP!");
        }
        if ((_item[$ "mp_rec"] ?? 0) > 0) {
            _p.mp = min(_p.mp_max, _p.mp + _item.mp_rec);
            battle_vfx_spawn_text(id, "+" + string(_item.mp_rec) + " MP", c_aqua, "player", false);
            battle_add_log(id, _p.name + " recuperou " + string(_item.mp_rec) + " MP!");
        }

        Obj_HUD.inv_grid[_slot_idx] = undefined;
        state      = BATTLE_STATE.WAIT_ENEMY;
        turn_timer = 0.55;
    }
}

// Fuga segura: tenta recuar para tras; se houver parede, usa outra celula livre longe do inimigo
function battle_player_flee(_b) {
    var _cw = Obj_Builder.cell_width, _ch = Obj_Builder.cell_height;
    var _px = Obj_Player.x div _cw,   _py = Obj_Player.y div _ch;
    var _ex = instance_exists(global.active_enemy) ? (global.active_enemy.x div _cw) : -99;
    var _ey = instance_exists(global.active_enemy) ? (global.active_enemy.y div _ch) : -99;

    var _base_back = (round(Obj_Player.dir / 90) * 90 + 180) mod 360;
    var _angles    = [_base_back, (_base_back + 90) mod 360, (_base_back + 270) mod 360];

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

// Teleporte da skill Mantra "Escolhido" para celula aleatoria segura
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

// --- LOOP DE TURNOS E PAUSAS (chamado no Step de Obj_Battle) ---

function battle_step(_b) {
    var _dt = min(delta_time / 1000000, 0.05);
    battle_vfx_step(_b, _dt);

    with (_b) {
        switch (state) {
            // Golpes extras do combo "Preciso"
            case BATTLE_STATE.COMBO_WAIT:
                combo_timer -= _dt;
                if (combo_timer <= 0) {
                    var _p   = Obj_Player.stats;
                    var _hit = 4 - combo_hits_left;
                    var _res = battle_calc_damage(battle_get_player_atk(id), enemy_defense, _p.crit_chance, _p.crit_rate, enemy_defending);

                    battle_damage_enemy(id, _res.damage, _res.is_crit);
                    battle_add_log(id, "Preciso [" + string(_hit) + "/3] causou " + string(_res.damage) + " de dano!");
                    combo_hits_left--;

                    if (enemy_hp <= 0 || combo_hits_left <= 0) {
                        battle_check_end(id);
                    } else {
                        combo_timer = 0.22;
                    }
                }
                break;

            // Pausa antes do inimigo agir
            case BATTLE_STATE.WAIT_ENEMY:
                turn_timer -= _dt;
                if (turn_timer <= 0) state = BATTLE_STATE.ENEMY_TURN;
                break;

            // Execucao do turno do inimigo (DoTs -> Stun -> Acao)
            case BATTLE_STATE.ENEMY_TURN:
                if (!instance_exists(Obj_Player)) exit;
                enemy_defending = false;

                // 1. Aplica dano por turno (Sangramento e Incendio)
                if (enemy_bleed_turns > 0) {
                    enemy_bleed_turns--;
                    battle_damage_enemy(id, enemy_bleed_dmg, false, c_red);
                    battle_add_log(id, enemy_name + " sangrou (-" + string(enemy_bleed_dmg) + " HP)!");
                    if (enemy_hp <= 0) { battle_check_end(id); exit; }
                }
                if (enemy_burn_turns > 0) {
                    enemy_burn_turns--;
                    battle_damage_enemy(id, enemy_burn_dmg, false, c_orange);
                    battle_add_log(id, enemy_name + " queimou (-" + string(enemy_burn_dmg) + " HP)!");
                    if (enemy_hp <= 0) { battle_check_end(id); exit; }
                }

                // 2. Verifica Nocauteado (pula acao)
                if (enemy_stun_turns > 0) {
                    enemy_stun_turns--;
                    battle_vfx_spawn_text(id, "NOCAUTEADO!", c_yellow, "enemy", false);
                    battle_add_log(id, enemy_name + " esta Nocauteado e perdeu o turno!");
                } else if (random(100) < 70) {
                    // 3. Verifica Impreciso (erra o ataque)
                    if (enemy_inaccurate_turns > 0) {
                        enemy_inaccurate_turns--;
                        battle_vfx_spawn_text(id, "ERROU!", c_ltgray, "player", false);
                        battle_add_log(id, enemy_name + " esta Impreciso e errou o ataque!");
                    } else {
                        var _res = battle_calc_damage(enemy_attack, battle_get_player_def(id), enemy_crit_chance, enemy_crit_rate, player_defending);
                        battle_damage_player(id, _res.damage, _res.is_crit);
                        battle_add_log(id, enemy_name + " causou " + string(_res.damage) + " de dano!" + (_res.is_crit ? " (CRITICO!)" : ""));
                    }
                } else {
                    if (enemy_inaccurate_turns > 0) enemy_inaccurate_turns--;
                    enemy_defending = true;
                    battle_vfx_spawn_text(id, "GUARDA!", c_ltgray, "enemy", false);
                    battle_add_log(id, enemy_name + " esta em guarda!");
                }

                // 4. Checa derrota ou pausa antes de devolver o turno
                if (Obj_Player.stats.life <= 0) {
                    state = BATTLE_STATE.DEFEAT;
                    battle_add_log(id, "--- VOCE FOI DERROTADO! ---");
                } else {
                    state      = BATTLE_STATE.WAIT_PLAYER;
                    turn_timer = 0.50;
                }
                break;

            // Pausa apos turno inimigo; atualiza duracao de buffs do jogador
            case BATTLE_STATE.WAIT_PLAYER:
                turn_timer -= _dt;
                if (turn_timer <= 0) {
                    player_defending = false;
                    if (buff_armor_turns  > 0) buff_armor_turns--;
                    if (buff_forged_turns > 0) buff_forged_turns--;
                    state = BATTLE_STATE.PLAYER_TURN;
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

        // Troca imediata do sprite 3D para cadaver
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