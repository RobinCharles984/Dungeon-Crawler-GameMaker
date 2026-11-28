// Inicializa uma instancia de Obj_Prop (Contexto: Obj_Prop)
function prop_init() {
    if (!variable_global_exists("props")) init_props();
    if (!variable_instance_exists(id, "prop_type") || prop_type == undefined) {
        prop_type = PROP.CORPSE;
    }

    prop_data    = global.props[prop_type] ?? global.props[PROP.CORPSE];
    sprite_index = prop_data.sprite_closed;
    depth        = -10;
    is_opened    = false;
}

// Retorna o nome da chave exigida para textos de UI
function prop_get_key_name(_key_type) {
    if (_key_type == KEY_TYPE.NORMAL_CHEST)  return "Chave Normal";
    if (_key_type == KEY_TYPE.SPECIAL_CHEST) return "Chave Especial";
    return "";
}

// Procura uma chave compativel no inventario; retorna indice do slot ou -1
function prop_find_key_slot(_hud, _key_type) {
    if (_key_type == KEY_TYPE.NONE) return -2; // Nao precisa de chave

    for (var i = 0; i < array_length(_hud.inv_grid); i++) {
        var _it = _hud.inv_grid[i];
        if (_it != undefined && _it.type == ITEM_TYPE.CONSUMABLE && (_it[$ "key_type"] ?? KEY_TYPE.NONE) == _key_type) {
            return i;
        }
    }
    return -1;
}

// Conta espacos livres no inventario
function prop_count_free_slots(_hud) {
    var _free = 0;
    for (var i = 0; i < array_length(_hud.inv_grid); i++) {
        if (_hud.inv_grid[i] == undefined) _free++;
    }
    return _free;
}

// Verifica alcance (compativel com passo de 32px) e garante que nao ha parede no meio
function prop_in_range(_prop) {
    if (!instance_exists(Obj_Player) || !instance_exists(Obj_Builder)) return false;
    if (_prop.is_opened) return false;
    if (point_distance(_prop.x, _prop.y, Obj_Player.x, Obj_Player.y) > 74) return false;

    var _cw = Obj_Builder.cell_width, _ch = Obj_Builder.cell_height;
    var _mx = ((_prop.x + Obj_Player.x) * 0.5) div _cw;
    var _my = ((_prop.y + Obj_Player.y) * 0.5) div _ch;

    if (_mx < 0 || _mx >= ds_grid_width(Obj_Builder.grid) || _my < 0 || _my >= ds_grid_height(Obj_Builder.grid)) {
        return false;
    }
    return (Obj_Builder.grid[# _mx, _my] == Obj_Builder.CELL_FLOOR);
}

// Detecta o prop mais proximo e dispara a abertura na tecla [E] (Contexto: Obj_HUD)
function prop_update_interaction() {
    nearby_prop = noone;

    if (hud_state != HUD_STATE.EXPLORE || !instance_exists(Obj_Player) || Obj_Player.is_fleeing) exit;

    var _best      = noone;
    var _best_dist = 99999;

    with (Obj_Prop) {
        if (prop_in_range(id)) {
            var _d = point_distance(x, y, Obj_Player.x, Obj_Player.y);
            if (_d < _best_dist) {
                _best_dist = _d;
                _best      = id;
            }
        }
    }

    nearby_prop = _best;

    if (nearby_prop != noone && keyboard_check_pressed(ord("E"))) {
        prop_try_open(id, nearby_prop);
    }
}

// Valida inventario e chave, consome a chave e entrega o loot
function prop_try_open(_hud, _prop) {
    var _data = _prop.prop_data;
    var _req  = _data.required_key;

    // 1. Verifica se ha chave compativel
    var _key_slot = prop_find_key_slot(_hud, _req);
    if (_key_slot == -1) {
        hud_add_toast(_data.name + " trancado! Requer " + prop_get_key_name(_req) + ".", c_red);
        exit;
    }

    // 2. Evita gastar chave com inventario 100% cheio
    var _free = prop_count_free_slots(_hud);
    if (_free == 0 && _req == KEY_TYPE.NONE) {
        hud_add_toast("Inventario cheio! Libere espaco antes de vasculhar.", c_orange);
        exit;
    }

    // 3. Consome a chave (libera o proprio slot dela caso o inventario estivesse cheio)
    if (_key_slot >= 0) {
        var _key_name = _hud.inv_grid[_key_slot].name;
        _hud.inv_grid[_key_slot] = undefined;
        hud_add_toast("Usou " + _key_name + " para abrir " + _data.name + ".", c_aqua);
    }

    // 4. Marca como aberto e muda aparencia 3D
    _prop.is_opened    = true;
    _prop.sprite_index = _data.sprite_open;
    _prop.image_blend  = c_gray;

    // 5. Sorteia loot respeitando min_drops
    var _loot = generate_loot(_data);
    var _min  = _data[$ "min_drops"] ?? 0;

    var _tries = 0;
    while (array_length(_loot) < _min && _tries < 10) {
        var _extra = generate_loot(_data);
        for (var e = 0; e < array_length(_extra) && array_length(_loot) < _min; e++) {
            array_push(_loot, _extra[e]);
        }
        _tries++;
    }

    // Fallback de seguranca caso as chances estejam muito baixas
    if (array_length(_loot) < _min) {
        if (!variable_global_exists("items")) init_items();
        array_push(_loot, global.items[$ "pot_heal_small"]);
    }

    if (array_length(_loot) == 0) {
        hud_add_toast(_data.name + " estava vazio.", c_ltgray);
        exit;
    }

    // 6. Entrega os itens nos slots livres
    var _lost = 0;
    for (var i = 0; i < array_length(_loot); i++) {
        var _item   = _loot[i];
        var _stored = false;

        for (var s = 0; s < array_length(_hud.inv_grid); s++) {
            if (_hud.inv_grid[s] == undefined) {
                _hud.inv_grid[s] = _item;
                _stored          = true;
                hud_add_toast("+ " + _item.name, ui_get_rarity_color(_item[$ "rarity"] ?? RARITY.COMMON));
                break;
            }
        }
        if (!_stored) _lost++;
    }

    if (_lost > 0) {
        hud_add_toast("Inventario cheio! " + string(_lost) + " item(ns) ficaram para tras.", c_orange);
    }
}