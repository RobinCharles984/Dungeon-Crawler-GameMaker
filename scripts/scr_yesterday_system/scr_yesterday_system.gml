#macro YESTERDAY_SAVE_FILE "yesterday_ghost.json"

// Carrega o ultimo personagem morto do disco para a memoria global
function yesterday_load() {
    if (variable_global_exists("yesterday_ghost") && is_struct(global.yesterday_ghost)) {
        return global.yesterday_ghost;
    }
    if (!file_exists(YESTERDAY_SAVE_FILE)) {
        global.yesterday_ghost = undefined;
        return undefined;
    }

    var _f   = file_text_open_read(YESTERDAY_SAVE_FILE);
    var _raw = "";
    while (!file_text_eof(_f)) {
        _raw += file_text_readln(_f);
    }
    file_text_close(_f);

    try {
        global.yesterday_ghost = json_parse(_raw);
    } catch (_e) {
        global.yesterday_ghost = undefined;
    }
    return global.yesterday_ghost;
}

// Retorna true se ja existe algum personagem morto salvo
function yesterday_has_ghost() {
    return (yesterday_load() != undefined);
}

// Retorna o sprite da classe do ultimo personagem morto
function yesterday_get_sprite() {
    if (!variable_global_exists("classes")) init_classes();
    var _g = yesterday_load();
    if (_g == undefined) return Spr_Enemy;

    var _cls_id = clamp(_g.class_id, 0, array_length(global.classes) - 1);
    var _cls    = global.classes[_cls_id];
    return _cls[$ "world_sprite"] ?? _cls.player_portrait;
}

// Salva foto completa do personagem atual no momento da morte (stats, skills, itens e estados)
function yesterday_save_from_battle(_b) {
    if (!instance_exists(Obj_Player)) exit;
    var _p = Obj_Player.stats;
    inv_ensure_equipped(_p);

    // Serializa IDs dos itens equipados
    var _eq_ids = {
        weapon:    (_p.equipped.weapon    != undefined) ? _p.equipped.weapon.id    : "",
        armor:     (_p.equipped.armor     != undefined) ? _p.equipped.armor.id     : "",
        accessory: (_p.equipped.accessory != undefined) ? _p.equipped.accessory.id : ""
    };

    // Serializa IDs dos itens do inventario
    var _inv_ids = [];
    if (instance_exists(Obj_HUD)) {
        for (var i = 0; i < array_length(Obj_HUD.inv_grid); i++) {
            if (Obj_HUD.inv_grid[i] != undefined) array_push(_inv_ids, Obj_HUD.inv_grid[i].id);
        }
    }

    // Serializa os estados/DoTs ativos no jogador ao morrer
    var _st_snap = [];
    for (var s = 0; s < STATUS.COUNT; s++) {
        array_push(_st_snap, {
            turns: _b.player_status[s].turns,
            dmg:   _b.player_status[s].dmg
        });
    }

    // Serializa skills (troca undefined por -1 para evitar pointer_null no JSON)
    var _sk_snap = [];
    for (var k = 0; k < array_length(_p.skills); k++) {
        var _sk  = _p.skills[k];
        var _sts = [];
        var _src = _sk[$ "statuses"] ?? [];
        for (var j = 0; j < array_length(_src); j++) {
            array_push(_sts, {
                status:    _src[j].status,
                chance:    _src[j].chance,
                turns_min: _src[j].turns_min,
                turns_max: _src[j].turns_max,
                dmg:       (_src[j].dmg == undefined) ? -1 : _src[j].dmg
            });
        }
        array_push(_sk_snap, {
            name:     _sk.name,
            mp:       _sk.mp,
            desc:     _sk.desc,
            stat:     _sk[$ "stat"]  ?? SKILL_STAT.NONE,
            mult:     _sk[$ "mult"]  ?? 0,
            color:    _sk[$ "color"] ?? c_white,
            statuses: _sts
        });
    }

    var _ghost = {
        name:          _p.name,
        class_id:      _p.class_id,
        class_name:    _p.class_name,
        level:         _p.level,
        is_mantra:     _p.is_mantra,
        life_max:      _p.life_max,
        mp_max:        _p.mp_max,
        attack:        _p.attack,
        defense:       _p.defense,
        magic:         _p.magic,
        crit_chance:   _p.crit_chance,
        crit_rate:     _p.crit_rate,
        skills:        _sk_snap,
        equipped_ids:  _eq_ids,
        inventory_ids: _inv_ids,
        statuses:      _st_snap
    };

    global.yesterday_ghost = _ghost;

    var _f = file_text_open_write(YESTERDAY_SAVE_FILE);
    file_text_write_string(_f, json_stringify(_ghost));
    file_text_close(_f);
}

// Injeta stats, skills, itens e estados do ultimo morto no Obj_Battle
function yesterday_apply_to_battle(_b) {
    if (!variable_global_exists("items")) init_items();
    var _g = yesterday_load();

    // Fallback: se testado sem nenhuma morte anterior, espelha o jogador atual
    if (_g == undefined && instance_exists(Obj_Player)) {
        yesterday_save_from_battle(_b);
        _g = global.yesterday_ghost;
    }
    if (_g == undefined) exit;

    with (_b) {
        enemy_name        = "O de Ontem (" + _g.name + ")";
        enemy_hp_max      = max(1, _g.life_max);
        enemy_hp          = enemy_hp_max;
        enemy_mp_max      = _g.mp_max;
        enemy_mp          = enemy_mp_max;
        enemy_attack      = _g.attack;
        enemy_defense     = _g.defense;
        enemy_magic       = _g.magic;
        enemy_crit_chance = _g.crit_chance;
        enemy_crit_rate   = _g.crit_rate;
        enemy_skills      = _g.skills;

        // Reconstroi inventario de consumiveis/itens do morto
        enemy_inventory = [];
        for (var i = 0; i < array_length(_g.inventory_ids); i++) {
            var _it = global.items[$ _g.inventory_ids[i]];
            if (_it != undefined) array_push(enemy_inventory, _it);
        }

        // Reconstroi equipamentos do morto (para drop na vitoria)
        enemy_equipped = [];
        var _keys = ["weapon", "armor", "accessory"];
        for (var k = 0; k < 3; k++) {
            var _eid = _g.equipped_ids[$ _keys[k]] ?? "";
            if (_eid != "" && variable_struct_exists(global.items, _eid)) {
                array_push(enemy_equipped, global.items[$ _eid]);
            }
        }

        // Replica exatamente os estados/DoTs que o personagem tinha ao morrer
        for (var s = 0; s < min(STATUS.COUNT, array_length(_g.statuses)); s++) {
            enemy_status[s].turns = _g.statuses[s].turns;
            enemy_status[s].dmg   = _g.statuses[s].dmg;
        }
    }
}

// IA do O de Ontem: usa pocoes do proprio inventario, skills da classe e ataques
function yesterday_take_turn(_b) {
    with (_b) {
        // 1. Se HP < 45%, tenta beber pocao de vida do proprio inventario
        if (enemy_hp < enemy_hp_max * 0.45) {
            for (var i = 0; i < array_length(enemy_inventory); i++) {
                var _it = enemy_inventory[i];
                if (_it.type == ITEM_TYPE.CONSUMABLE && (_it[$ "hp_rec"] ?? 0) > 0) {
                    enemy_hp = min(enemy_hp_max, enemy_hp + _it.hp_rec);
                    array_delete(enemy_inventory, i, 1);
                    battle_vfx_spawn_text(id, "+" + string(_it.hp_rec) + " HP", c_lime, "enemy", false);
                    battle_add_log(id, enemy_name + " usou " + _it.name + " (+" + string(_it.hp_rec) + " HP)!");
                    exit;
                }
            }
        }

        // 2. Se MP baixo, tenta beber pocao de mana
        if (enemy_mp < enemy_mp_max * 0.25) {
            for (var i = 0; i < array_length(enemy_inventory); i++) {
                var _it = enemy_inventory[i];
                if (_it.type == ITEM_TYPE.CONSUMABLE && (_it[$ "mp_rec"] ?? 0) > 0) {
                    enemy_mp = min(enemy_mp_max, enemy_mp + _it.mp_rec);
                    array_delete(enemy_inventory, i, 1);
                    battle_vfx_spawn_text(id, "+" + string(_it.mp_rec) + " MP", c_aqua, "enemy", false);
                    battle_add_log(id, enemy_name + " usou " + _it.name + " (+" + string(_it.mp_rec) + " MP)!");
                    exit;
                }
            }
        }

        // 3. Filtra skills utilizaveis (exclui Escolhido para nao fugir de si mesmo)
        var _usable = [];
        for (var s = 0; s < array_length(enemy_skills); s++) {
            var _sk = enemy_skills[s];
            if (_sk.name != "Escolhido" && enemy_mp >= _sk.mp) array_push(_usable, _sk);
        }

        // Invocador (ATK 0) prioriza skills; outras classes alternam entre skill e ataque
        var _skill_chance = (enemy_attack <= 0) ? 90 : 55;
        if (array_length(_usable) > 0 && random(100) < _skill_chance) {
            var _chosen = _usable[irandom(array_length(_usable) - 1)];
            yesterday_cast_skill(id, _chosen);
            exit;
        }

        // 4. Ataque basico ou guarda
        if (random(100) < 75) {
            if (!status_roll_miss(id, "enemy", "player")) {
                var _res = battle_calc_damage(battle_get_enemy_atk(id), battle_get_player_def(id), enemy_crit_chance, enemy_crit_rate, player_defending);
                battle_damage_player(id, _res.damage, _res.is_crit);
                battle_add_log(id, enemy_name + " atacou (" + string(_res.damage) + " de dano)!" + (_res.is_crit ? " (CRITICO!)" : ""));
            }
        } else {
            enemy_defending = true;
            battle_vfx_spawn_text(id, "GUARDA!", c_ltgray, "enemy", false);
            battle_add_log(id, enemy_name + " assumiu guarda!");
        }
    }
}

// Executa uma skill do morto contra o jogador atual
function yesterday_cast_skill(_b, _sk) {
    with (_b) {
        enemy_mp = max(0, enemy_mp - _sk.mp);
        var _atk = battle_get_enemy_atk(id);
        var _mag = enemy_magic;
        var _def = battle_get_player_def(id);

        switch (_sk.name) {
            case "Blindagem":
                enemy_buff_armor_turns = 3;
                battle_vfx_spawn_text(id, "DEF x2!", c_aqua, "enemy", false);
                battle_add_log(id, enemy_name + " ativou Blindagem!");
                break;

            case "Forjado":
                enemy_buff_forged_turns = 2;
                battle_vfx_spawn_text(id, "ATK +15%!", c_orange, "enemy", false);
                battle_add_log(id, enemy_name + " ativou Forjado!");
                break;

            case "Head Shot":
                if (random(100) < 15) {
                    battle_damage_player(id, Obj_Player.stats.life, true, c_yellow);
                    battle_vfx_spawn_text(id, "HEAD SHOT!", c_yellow, "player", true);
                    battle_add_log(id, enemy_name + " acertou um HEAD SHOT!");
                } else {
                    battle_vfx_spawn_text(id, "ERROU!", c_ltgray, "player", false);
                    battle_add_log(id, enemy_name + " errou o Head Shot!");
                }
                break;

            case "Preciso":
                var _res = battle_calc_damage(_atk, _def, enemy_crit_chance, enemy_crit_rate, player_defending);
                battle_damage_player(id, _res.damage, _res.is_crit);
                battle_add_log(id, enemy_name + " disparou Preciso [1/3] (" + string(_res.damage) + " de dano)!");
                if (Obj_Player.stats.life > 0) {
                    combo_side      = "enemy";
                    combo_skill     = _sk;
                    combo_hits_left = 2;
                    combo_timer     = 0.22;
                    state           = BATTLE_STATE.COMBO_WAIT;
                }
                break;

            default:
                var _stat = _sk[$ "stat"] ?? SKILL_STAT.NONE;
                var _mult = _sk[$ "mult"] ?? 0;

                if (_stat != SKILL_STAT.NONE && _mult > 0) {
                    if (status_roll_miss(id, "enemy", "player")) exit;
                    var _pwr = (_stat == SKILL_STAT.ATTACK) ? round(_atk * _mult) : round(_mag * _mult);
                    var _res = battle_calc_damage(_pwr, _def, enemy_crit_chance, enemy_crit_rate, player_defending);

                    battle_damage_player(id, _res.damage, _res.is_crit, _sk[$ "color"]);
                    battle_add_log(id, enemy_name + " usou " + _sk.name + " (" + string(_res.damage) + " de dano)!" + (_res.is_crit ? " (CRITICO!)" : ""));
                    if (Obj_Player.stats.life > 0) battle_apply_skill_statuses(id, _sk, "player");
                } else {
                    battle_apply_skill_statuses(id, _sk, "player");
                }
                break;
        }
    }
}

// Devolve equipamentos e itens restantes do morto ao inventario do jogador na vitoria
function yesterday_grant_loot(_b) {
    var _drops = [];
    for (var i = 0; i < array_length(_b.enemy_equipped);  i++) array_push(_drops, _b.enemy_equipped[i]);
    for (var j = 0; j < array_length(_b.enemy_inventory); j++) array_push(_drops, _b.enemy_inventory[j]);

    for (var d = 0; d < array_length(_drops); d++) {
        var _item = _drops[d];
        for (var s = 0; s < array_length(Obj_HUD.inv_grid); s++) {
            if (Obj_HUD.inv_grid[s] == undefined) {
                Obj_HUD.inv_grid[s] = _item;
                battle_add_log(_b, "Recuperou: " + _item.name);
                break;
            }
        }
    }
}