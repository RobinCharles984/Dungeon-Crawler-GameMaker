enum PROP {
    CHEST_NORMAL,
    CHEST_SPECIAL,
    CORPSE
}

function init_props() {
    global.props = [];

    // 1. BAU NORMAL (abre somente com Chave Normal, dropa itens normais)
    global.props[PROP.CHEST_NORMAL] = {
        name:           "Bau Normal",
        action_label:   "Abrir",
        allowed_biomes: [BIOME.SEWER, BIOME.CAVE, BIOME.DUNGEON],
        required_key:   KEY_TYPE.NORMAL_CHEST,
        sprite_closed:  Spr_Exit,       // Troque pelo sprite de bau normal fechado
        sprite_open:    Spr_Enemy_Dead, // Troque pelo sprite de bau normal aberto
        min_drops:      1,              // Garante ao menos 1 item ao gastar chave

        // Drops (apenas itens normais)
        potion_heal_drop_chance:   65,
        potion_mana_drop_chance:   45,
        key_drop_chance:           20,
        file_drop_chance:          20,
        file_special_drop_chance:  0,
        equip_drop_chance:         45,
        equip_special_drop_chance: 0,

        // Spawn procedural
        spawn_chance: 45,
        spawn_min:    3,
        spawn_max:    8
    };

    // 2. BAU ESPECIAL (abre somente com Chave Especial, dropa itens normais e especiais)
    global.props[PROP.CHEST_SPECIAL] = {
        name:           "Bau Especial",
        action_label:   "Abrir",
        allowed_biomes: [BIOME.CAVE, BIOME.DUNGEON],
        required_key:   KEY_TYPE.SPECIAL_CHEST,
        sprite_closed:  Spr_Exit,       // Troque pelo sprite de bau especial fechado
        sprite_open:    Spr_Enemy_Dead, // Troque pelo sprite de bau especial aberto
        min_drops:      2,              // Garante ao menos 2 itens ao gastar chave especial

        // Drops (normais e especiais)
        potion_heal_drop_chance:   80,
        potion_mana_drop_chance:   80,
        key_drop_chance:           30,
        file_drop_chance:          40,
        file_special_drop_chance:  50,
        equip_drop_chance:         70,
        equip_special_drop_chance: 65,

        // Spawn procedural
        spawn_chance: 35,
        spawn_min:    1,
        spawn_max:    4
    };

    // 3. CORPO (sem chave, dropa itens normais ou especiais)
    global.props[PROP.CORPSE] = {
        name:           "Corpo",
        action_label:   "Vasculhar",
        allowed_biomes: [BIOME.SEWER, BIOME.CAVE, BIOME.DUNGEON],
        required_key:   KEY_TYPE.NONE,
        sprite_closed:  Spr_Enemy_Dead, // Troque pelo sprite de corpo intacto
        sprite_open:    Spr_Enemy_Dead, // Troque pelo sprite de corpo vasculhado
        min_drops:      1,

        // Drops (normais ou especiais)
        potion_heal_drop_chance:   50,
        potion_mana_drop_chance:   40,
        key_drop_chance:           35, // Boa fonte de chaves para abrir os baus
        file_drop_chance:          35,
        file_special_drop_chance:  15,
        equip_drop_chance:         35,
        equip_special_drop_chance: 15,

        // Spawn procedural
        spawn_chance: 40,
        spawn_min:    4,
        spawn_max:    10
    };
}