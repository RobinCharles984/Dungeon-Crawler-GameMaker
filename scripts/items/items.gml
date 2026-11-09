// --- ENUMS E CONSTRUTORES ---
enum ITEM_TYPE {
    CONSUMABLE,
    WEAPON,
    EQUIPMENT,
    FILE
}

enum EQUIP_TYPE {
    ARMOR,
    ACCESSORY
}

enum RARITY {
    COMMON,
    UNCOMMON,
    RARE,
    SPECIAL
}

enum KEY_TYPE {
    NONE,
    NORMAL_CHEST,
    SPECIAL_CHEST
}

// Construtores
function item_consumable(_id, _name, _desc, _rarity, _hp, _mp, _key_type, _sprite) {
    return { id: _id, type: ITEM_TYPE.CONSUMABLE, name: _name, desc: _desc, rarity: _rarity, hp_rec: _hp, mp_rec: _mp, key_type: _key_type, sprite: _sprite };
}

function item_weapon(_id, _name, _desc, _rarity, _atk, _mag, _def, _crit, _special, _sprite) {
    return { id: _id, type: ITEM_TYPE.WEAPON, name: _name, desc: _desc, rarity: _rarity, attack: _atk, magic: _mag, defense: _def, crit_chance: _crit, special_effect: _special, sprite: _sprite };
}

function item_equip(_id, _name, _desc, _rarity, _equip_type, _def, _mag, _atk, _sprite) {
    return { id: _id, type: ITEM_TYPE.EQUIPMENT, equip_type: _equip_type, name: _name, desc: _desc, rarity: _rarity, defense: _def, magic: _mag, attack: _atk, sprite: _sprite };
}

function item_file(_id, _name, _desc, _content, _sprite) {
    return { id: _id, type: ITEM_TYPE.FILE, name: _name, desc: _desc, content: _content, sprite: _sprite };
}


// --- INICIALIZAÇÃO DOS ITENS E DOS POOLS DAS 7 CATEGORIAS ---
function init_items() {
    global.items = {};
    global.files_archive = []; // Histórico permanente de arquivos lidos

    // 1. Poções de Vida (potion_heal)
    global.items[$ "pot_heal_small"]  = item_consumable("pot_heal_small", "Poção de Vida P", "Recupera 15 HP.", RARITY.COMMON, 15, 0, KEY_TYPE.NONE, Spr_Player);
    global.items[$ "pot_heal_large"]  = item_consumable("pot_heal_large", "Poção de Vida G", "Recupera 45 HP.", RARITY.UNCOMMON, 45, 0, KEY_TYPE.NONE, Spr_Player);

    // 2. Poções de Mana (potion_mana)
    global.items[$ "pot_mana_small"]  = item_consumable("pot_mana_small", "Poção de Mana P", "Recupera 20 MP.", RARITY.COMMON, 0, 20, KEY_TYPE.NONE, Spr_Player);
    global.items[$ "pot_mana_large"]  = item_consumable("pot_mana_large", "Poção de Mana G", "Recupera 50 MP.", RARITY.UNCOMMON, 0, 50, KEY_TYPE.NONE, Spr_Player);

    // 3. Chaves (key)
    global.items[$ "key_chest"]       = item_consumable("key_chest", "Chave de Baú", "Abre baús trancados.", RARITY.UNCOMMON, 0, 0, KEY_TYPE.NORMAL_CHEST, Spr_Player);

    // 4. Arquivos Normais (file)
    global.items[$ "file_sewer_note"] = item_file("file_sewer_note", "Bilhete Úmido", "Encontrado nos esgotos.", "Eles vêm da água quando a poça estagna...", Spr_Player);

    // 5. Arquivos Especiais (file_special)
    global.items[$ "file_boss_diary"] = item_file("file_boss_diary", "Relatório Proibido", "Documento antigo.", "O Mantra consome a carne dos que não são Escolhidos.", Spr_Player);

    // 6. Equipamentos Normais (equip)
    global.items[$ "sword_iron"]      = item_weapon("sword_iron", "Espada de Ferro", "Arma básica.", RARITY.COMMON, 6, 0, 1, 5, "none", Spr_Player);
    global.items[$ "armor_leather"]   = item_equip("armor_leather", "Couraça de Couro", "Proteção leve.", RARITY.COMMON, EQUIP_TYPE.ARMOR, 3, 0, 0, Spr_Player);

    // 7. Equipamentos Especiais (equip_special)
    global.items[$ "staff_mantra"]    = item_weapon("staff_mantra", "Cajado do Mantra", "Corta custo de MP.", RARITY.SPECIAL, 2, 14, 0, 15, "mp_cut", Spr_Player);
    global.items[$ "ring_crit"]       = item_equip("ring_crit", "Anel do Garrador", "Aumenta chance de crítico.", RARITY.RARE, EQUIP_TYPE.ACCESSORY, 0, 0, 3, Spr_Player);


    // --- GRUPOS DE DROPS MAPEADOS PARA AS SUAS VARIÁVEIS DO ENEMIES.GML ---
    global.item_pools = {
        potion_heal:   ["pot_heal_small", "pot_heal_large"],
        potion_mana:   ["pot_mana_small", "pot_mana_large"],
        key:           ["key_chest"],
        file:          ["file_sewer_note"],
        file_special:  ["file_boss_diary"],
        equip:         ["sword_iron", "armor_leather"],
        equip_special: ["staff_mantra", "ring_crit"]
    };
}

/// @desc Processa todas as chances de drop de uma struct de inimigo/baú e retorna um array com os itens sorteados
/// @param {Struct} _drop_data A struct do inimigo (ex: global.enemies[ENEMY.DESGRACA])
/// @return {Array} Array de structs de itens dropados
function generate_loot(_drop_data) {
    if (!variable_global_exists("items")) init_items();

    var _dropped_items = [];

    // Mapeia os campos do seu script para os pools de itens
    var _categories = [
        { chance: _drop_data.potion_heal_drop_chance,   pool: "potion_heal" },
        { chance: _drop_data.potion_mana_drop_chance,   pool: "potion_mana" },
        { chance: _drop_data.key_drop_chance,           pool: "key" },
        { chance: _drop_data.file_drop_chance,          pool: "file" },
        { chance: _drop_data.file_special_drop_chance,  pool: "file_special" },
        { chance: _drop_data.equip_drop_chance,         pool: "equip" },
        { chance: _drop_data.equip_special_drop_chance, pool: "equip_special" }
    ];

    // Testa cada uma das 7 porcentagens de drop do inimigo
    for (var i = 0; i < array_length(_categories); i++) {
        var _cat = _categories[i];
        
        // Trata valores especiais como 'infinity' (Fagulha) ou sorteios comuns de 0 a 100
        var _passed = false;
        if (_cat.chance == infinity) {
            _passed = true;
        } else if (_cat.chance > 0) {
            _passed = (random(100) < _cat.chance);
        }

        // Se passou no teste de porcentagem, escolhe um item aleatório daquela categoria
        if (_passed) {
            var _item_list = global.item_pools[$ _cat.pool];
            if (array_length(_item_list) > 0) {
                var _chosen_id = _item_list[irandom(array_length(_item_list) - 1)];
                array_push(_dropped_items, global.items[$ _chosen_id]);
            }
        }
    }

    return _dropped_items;
}

function init_chests() {
    global.chests = {};

    // Baú Comum
    global.chests[$ "chest_normal"] = {
        potion_heal_drop_chance: 60,
        potion_mana_drop_chance: 40,
        key_drop_chance: 20,
        file_drop_chance: 15,
        file_special_drop_chance: 0,
        equip_drop_chance: 35,
        equip_special_drop_chance: 0
    };

    // Baú Especial
    global.chests[$ "chest_special"] = {
        potion_heal_drop_chance: 100,
        potion_mana_drop_chance: 100,
        key_drop_chance: 50,
        file_drop_chance: 50,
        file_special_drop_chance: 40,
        equip_drop_chance: 80,
        equip_special_drop_chance: 30
    };
}