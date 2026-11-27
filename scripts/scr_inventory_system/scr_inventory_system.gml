// Garante que o struct de equipamentos exista mesmo em saves/instancias antigas
function inv_ensure_equipped(_p) {
    if (!variable_struct_exists(_p, "equipped")) {
        _p.equipped = { weapon: undefined, armor: undefined, accessory: undefined };
    }
}

// Soma (_sign = 1) ou remove (_sign = -1) os bonus de um equipamento nos stats do jogador
function inv_apply_item_stats(_p, _item, _sign) {
    if (_item == undefined) exit;
    _p.attack      += (_item[$ "attack"]      ?? 0) * _sign;
    _p.defense     += (_item[$ "defense"]     ?? 0) * _sign;
    _p.magic       += (_item[$ "magic"]       ?? 0) * _sign;
    _p.crit_chance += (_item[$ "crit_chance"] ?? 0) * _sign;
}

// Retorna o nome do slot ("weapon", "armor" ou "accessory") correspondente ao item
function inv_get_equip_slot_key(_item) {
    if (_item.type == ITEM_TYPE.WEAPON) return "weapon";
    if (_item.type == ITEM_TYPE.EQUIPMENT) {
        return (_item[$ "equip_type"] == EQUIP_TYPE.ARMOR) ? "armor" : "accessory";
    }
    return undefined;
}

// Equipa um item do inventario (troca com o que ja estava equipado)
function inv_equip_from_slot(_hud, _slot_idx) {
    var _item = _hud.inv_grid[_slot_idx];
    if (_item == undefined) exit;

    var _key = inv_get_equip_slot_key(_item);
    if (_key == undefined) exit;

    var _p = Obj_Player.stats;
    inv_ensure_equipped(_p);

    var _old = _p.equipped[$ _key];
    if (_old != undefined) inv_apply_item_stats(_p, _old, -1);

    _p.equipped[$ _key]      = _item;
    _hud.inv_grid[_slot_idx] = _old;
    inv_apply_item_stats(_p, _item, 1);
}

// Desequipa um slot ativo e devolve ao primeiro espaco livre do inventario
function inv_unequip_slot(_hud, _key) {
    var _p = Obj_Player.stats;
    inv_ensure_equipped(_p);

    var _item = _p.equipped[$ _key];
    if (_item == undefined) exit;

    for (var i = 0; i < array_length(_hud.inv_grid); i++) {
        if (_hud.inv_grid[i] == undefined) {
            inv_apply_item_stats(_p, _item, -1);
            _hud.inv_grid[i]    = _item;
            _p.equipped[$ _key] = undefined;
            return true;
        }
    }
    return false; // Inventario cheio
}

// Consome pocao fora de combate (no combate, usa battle_player_item)
function inv_use_item_explore(_hud, _slot_idx) {
    var _item = _hud.inv_grid[_slot_idx];
    if (_item == undefined || _item.type != ITEM_TYPE.CONSUMABLE) exit;

    var _hp = _item[$ "hp_rec"] ?? 0;
    var _mp = _item[$ "mp_rec"] ?? 0;
    if (_hp <= 0 && _mp <= 0) exit; // Chaves nao sao consumidas pelo menu

    var _p = Obj_Player.stats;
    if (_hp > 0) _p.life = min(_p.life_max, _p.life + _hp);
    if (_mp > 0) _p.mp   = min(_p.mp_max,   _p.mp   + _mp);

    _hud.inv_grid[_slot_idx] = undefined;
}

// Monta string compacta de bonus/efeitos para o tooltip do item
function inv_get_item_stats_line(_item) {
    var _parts = [];
    if ((_item[$ "attack"]      ?? 0) != 0) array_push(_parts, "+" + string(_item.attack)      + " ATK");
    if ((_item[$ "defense"]     ?? 0) != 0) array_push(_parts, "+" + string(_item.defense)     + " DEF");
    if ((_item[$ "magic"]       ?? 0) != 0) array_push(_parts, "+" + string(_item.magic)       + " MAG");
    if ((_item[$ "crit_chance"] ?? 0) != 0) array_push(_parts, "+" + string(_item.crit_chance) + "% CRIT");
    if ((_item[$ "hp_rec"]      ?? 0) >  0) array_push(_parts, "+" + string(_item.hp_rec)      + " HP");
    if ((_item[$ "mp_rec"]      ?? 0) >  0) array_push(_parts, "+" + string(_item.mp_rec)      + " MP");

    var _out = "";
    for (var i = 0; i < array_length(_parts); i++) {
        _out += (i > 0 ? "  |  " : "") + _parts[i];
    }
    return _out;
}