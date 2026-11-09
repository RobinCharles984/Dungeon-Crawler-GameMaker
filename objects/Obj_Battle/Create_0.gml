/// Evento Create de Obj_Battle

enum BATTLE_STATE {
    PLAYER_TURN,
    ENEMY_TURN,
    WAITING,
    VICTORY,
    DEFEAT
}

state = BATTLE_STATE.PLAYER_TURN;

// -------------------------------------------------------------
// RESOLUÇÃO E TRATAMENTO SEGURO DOS DADOS DO INIMIGO
// -------------------------------------------------------------
var _data = undefined;

if (variable_instance_exists(id, "enemies") && enemies != undefined) {
    if (is_struct(enemies)) {
        // Recebeu o struct de estatísticas diretamente
        _data = enemies;
    } else if (typeof(enemies) == "ref" || is_numeric(enemies)) {
        // Recebeu o ID da instância do Obj_Enemy; extrai o struct interno dele
        if (instance_exists(enemies) && variable_instance_exists(enemies, "enemy_data")) {
            _data = enemies.enemy_data;
        }
    }
}

// Fallback de segurança se os dados falharem
if (_data == undefined) {
    if (!variable_global_exists("enemies")) init_enemies();
    _data = global.enemies[ENEMY.SLIME];
}

// Atribuição com validações seguras ($ e ??)
enemy_data_ref    = _data;
enemy_name        = _data[$ "name"] ?? "Inimigo";
enemy_hp_max      = _data[$ "life"] ?? 10;
enemy_hp          = enemy_hp_max;
enemy_attack      = _data[$ "attack"] ?? 3;
enemy_defense     = _data[$ "defense"] ?? 0;
enemy_magic       = _data[$ "magic"] ?? 0;
enemy_crit_chance = _data[$ "crit_chance"] ?? 5;
enemy_crit_rate   = _data[$ "crit_rate"] ?? 50;
enemy_xp          = _data[$ "xp"] ?? 5;
enemy_tex         = _data[$ "enemy_tex"] ?? sprite_get_texture(Spr_Player, 0);

// Modificadores de Guarda (Defesa)
player_defending = false;
enemy_defending  = false;

// HISTÓRICO DE BATALHA (LOG)
log_messages  = [];
max_log_lines = 8;

function add_log(_text) {
    array_push(log_messages, _text);
    if (array_length(log_messages) > max_log_lines) {
        array_delete(log_messages, 0, 1);
    }
}

add_log("Um " + enemy_name + " apareceu!");

victory_loot = [];
xp_gained    = 0;



// -------------------------------------------------------------
// CÁLCULO DE DANO COM FATOR DE CRÍTICO E DEFESA
// -------------------------------------------------------------
function calc_damage(_atk, _def, _crit_chance, _crit_rate, _is_defending) {
    var _base_dmg = max(1, _atk - (_def / 2));
    
    // Teste de Acerto Crítico
    var _is_crit = (random(100) < _crit_chance);
    if (_is_crit) {
        _base_dmg *= (1 + (_crit_rate / 100));
    }
    
    // Redução de 50% se o alvo estiver defendendo
    if (_is_defending) _base_dmg = max(1, _base_dmg * 0.5);

    return { damage: round(_base_dmg), is_crit: _is_crit };
}

// -------------------------------------------------------------
// AÇÕES DO JOGADOR
// -------------------------------------------------------------
function player_attack() {
    if (state != BATTLE_STATE.PLAYER_TURN) exit;
    player_defending = false;

    var _p = Obj_Player.stats;
    var _res = calc_damage(_p.attack, enemy_defense, _p.crit_chance, _p.crit_rate, enemy_defending);

    enemy_hp = max(0, enemy_hp - _res.damage);
    
    var _msg = _p.name + " atacou causa " + string(_res.damage) + " de dano!";
    if (_res.is_crit) _msg += " (CRÍTICO!)";
    add_log(_msg);

    check_battle_end();
}

function player_defend() {
    if (state != BATTLE_STATE.PLAYER_TURN) exit;
    player_defending = true;
    
    var _p = Obj_Player.stats;
    add_log(_p.name + " assumiu posição de defesa!");
    
    state = BATTLE_STATE.ENEMY_TURN;
}

function player_use_skill(_skill) {
    if (state != BATTLE_STATE.PLAYER_TURN) exit;
    var _p = Obj_Player.stats;

    if (_p.mp < _skill.mp) {
        add_log("MP insuficiente para " + _skill.name + "!");
        exit;
    }

    _p.mp -= _skill.mp;
    player_defending = false;

    var _res = calc_damage(_p.magic + (_skill[$ "power"] ?? 5), enemy_defense, _p.crit_chance, _p.crit_rate, enemy_defending);
    enemy_hp = max(0, enemy_hp - _res.damage);

    add_log(_p.name + " usou " + _skill.name + " causando " + string(_res.damage) + " de dano!");
    check_battle_end();
}

function player_use_item(_slot_idx) {
    if (state != BATTLE_STATE.PLAYER_TURN) exit;
    if (!instance_exists(Obj_HUD)) exit;

    var _item = Obj_HUD.inv_grid[_slot_idx];
    if (_item == undefined || _item.type != ITEM_TYPE.CONSUMABLE) {
        add_log("Este item não pode ser usado em batalha!");
        exit;
    }

    var _p = Obj_Player.stats;
    player_defending = false;

    if (_item.hp_rec > 0) {
        _p.life = min(_p.life_max, _p.life + _item.hp_rec);
        add_log(_p.name + " usou " + _item.name + " e recuperou " + string(_item.hp_rec) + " HP!");
    }
    if (_item.mp_rec > 0) {
        _p.mp = min(_p.mp_max, _p.mp + _item.mp_rec);
        add_log(_p.name + " usou " + _item.name + " e recuperou " + string(_item.mp_rec) + " MP!");
    }

    // Consome o item do inventário
    Obj_HUD.inv_grid[_slot_idx] = undefined;
    
    state = BATTLE_STATE.ENEMY_TURN;
}

// -------------------------------------------------------------
// CHECAGEM DE FIM DE COMBATE
// -------------------------------------------------------------
function check_battle_end() {
    if (enemy_hp <= 0) {
        state = BATTLE_STATE.VICTORY;
        add_log("--- VITÓRIA! ---");
        add_log("Você derrotou " + enemy_name + "!");
        
        // Sorteia Drops e XP
        xp_gained = enemy_xp;
        Obj_Player.stats.xp += xp_gained;
        add_log("Ganhou " + string(xp_gained) + " de XP!");

        if (script_exists(asset_get_index("generate_loot"))) {
            victory_loot = generate_loot(enemy_data_ref);
            for (var i = 0; i < array_length(victory_loot); i++) {
                var _drop = victory_loot[i];
                add_log("Dropou: " + _drop.name);
                
                // Adiciona ao primeiro slot livre do inventário
                for (var s = 0; s < array_length(Obj_HUD.inv_grid); s++) {
                    if (Obj_HUD.inv_grid[s] == undefined) {
                        Obj_HUD.inv_grid[s] = _drop;
                        break;
                    }
                }
            }
        }
    } else {
        state = BATTLE_STATE.ENEMY_TURN;
    }
}