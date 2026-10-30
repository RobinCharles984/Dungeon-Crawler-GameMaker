enum BIOME {
    SEWER,
    CAVE,
    DUNGEON
}

function init_biomes() {
    global.biomes = [];

    // 0. ESGOTOS
    global.biomes[BIOME.SEWER] = {
        wall_tex:   sprite_get_texture(Spr_Sewer_Wall, 0),
        floor_tex:  sprite_get_texture(Spr_Sewer_Floor, 0),
        ceil_tex:   sprite_get_texture(Spr_Sewer_Ceiling, 0),
        fog_color:  make_color_rgb(15, 35, 20), // Verde escuro tóxico
        fog_start:  12,
        fog_end:    160
    };

    // 1. CAVERNAS
    global.biomes[BIOME.CAVE] = {
        wall_tex:   sprite_get_texture(Spr_Cave_Wall, 0),
        floor_tex:  sprite_get_texture(Spr_Cave_Floor, 0),
        ceil_tex:   sprite_get_texture(Spr_Cave_Ceiling, 0),
        fog_color:  c_black, // Marrom terroso escuro
        fog_start:  8,
        fog_end:    128
    };

    // 2. CALABOUÇOS
    global.biomes[BIOME.DUNGEON] = {
        wall_tex:   sprite_get_texture(Spr_Dungeon_Wall, 0),
        floor_tex:  sprite_get_texture(Spr_Dungeon_Floor, 0),
        ceil_tex:   sprite_get_texture(Spr_Dungeon_Ceiling, 0),
        fog_color:  make_color_rgb(80, 80, 80),                    // Breu total
        fog_start:  32,
        fog_end:    256
    };
}