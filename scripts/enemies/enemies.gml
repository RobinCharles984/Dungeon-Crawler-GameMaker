enum ENEMY {
    SLIME,
    RAT,
    BODY,
	DESGRACA,
	GARRADOR,
	ACUDE,
	ALEIJADO,
	UNCLE,
	FLAME,
	GUARD,
	MANTRA,
	ME
}

function init_enemies() {
    global.enemies = [];

    // Açude
    global.enemies[ENEMY.ACUDE] = {
		// Stats
		enemy_tex: sprite_get_texture(Spr_Player, 0),
		life: 14,
		attack: 7,
		crit_chance: 8,
		crit_rate: 100,
		xp: 12,
		
		// Drops
		potion_heal_drop_chance: 60,
		potion_mana_drop_chance: 50,
		key_drop_chance: 15,
		file_drop_chance: 5,
		file_special_drop_chance: 1,
		equip_drop_chance: 45,
		equip_special_drop_chance: 0,
		
		// Spawn
		spawn_chance: 30,
		spawn_min: 0,
		spawwn_max: 10
    };
	
	// Aleijado
    global.enemies[ENEMY.ALEIJADO] = {
		// Stats
		enemy_tex: sprite_get_texture(Spr_Player, 0),
		life: 7,
		attack: 5,
		crit_chance: 5,
		crit_rate: 40,
		xp: 8,
		
		// Drops
		potion_heal_drop_chance: 30,
		potion_mana_drop_chance: 30,
		key_drop_chance: 30,
		file_drop_chance: 30,
		file_special_drop_chance: 30,
		equip_drop_chance: 30,
		equip_special_drop_chance: 0,
		
		// Spawn
		spawn_chance: 30,
		spawn_min: 0,
		spawwn_max: 10
    };

	// Corpo Pútrido
    global.enemies[ENEMY.BODY] = {
		// Stats
		enemy_tex: sprite_get_texture(Spr_Player, 0),
		life: 20,
		attack: 5,
		crit_chance: 8,
		crit_rate: 67,
		xp: 5,
		
		// Drops
		potion_heal_drop_chance: 80,
		potion_mana_drop_chance: 60,
		key_drop_chance: 20,
		file_drop_chance: 5,
		file_special_drop_chance: 1,
		equip_drop_chance: 25,
		equip_special_drop_chance: 0,
		
		// Spawn
		spawn_chance: 30,
		spawn_min: 0,
		spawwn_max: 10
    };
	
	// Desgraça Ambulante
	global.enemies[ENEMY.DESGRACA] = {
		// Stats
		enemy_tex: sprite_get_texture(Spr_Player, 0),
		life: 140,
		attack: 2,
		crit_chance: 15,
		crit_rate: 40,
		xp: 89,
		
		// Drops
		potion_heal_drop_chance: 70,
		potion_mana_drop_chance: 0,
		key_drop_chance: 35,
		file_drop_chance: 100,
		file_special_drop_chance: 25,
		equip_drop_chance: 55,
		equip_special_drop_chance: 10,
		
		// Spawn
		spawn_chance: 30,
		spawn_min: 0,
		spawwn_max: 1
    };
	
	// Fagulha
	global.enemies[ENEMY.FLAME] = {
		// Stats
		enemy_tex: sprite_get_texture(Spr_Player, 0),
		life: infinity,
		attack: infinity,
		crit_chance: infinity,
		crit_rate: infinity,
		xp: 40,
		
		// Drops
		potion_heal_drop_chance: 100,
		potion_mana_drop_chance: 100,
		key_drop_chance: 100,
		file_drop_chance: 100,
		file_special_drop_chance: 100,
		equip_drop_chance: 100,
		equip_special_drop_chance: 100,
		
		// Spawn
		spawn_chance: 30,
		spawn_min: 0,
		spawwn_max: 10
    };
	
	// Garrador
	global.enemies[ENEMY.GARRADOR] = {
		// Stats
		enemy_tex: sprite_get_texture(Spr_Player, 0),
		life: 5,
		attack: 3,
		crit_chance: 18,
		crit_rate: 50,
		xp: 3,
		
		// Drops
		potion_heal_drop_chance: 30,
		potion_mana_drop_chance: 30,
		key_drop_chance: 5,
		file_drop_chance: 5,
		file_special_drop_chance: 1,
		equip_drop_chance: 0,
		equip_special_drop_chance: 0,
		
		// Spawn
		spawn_chance: 30,
		spawn_min: 0,
		spawwn_max: 10
    };
	
	// Lambe Botas
	global.enemies[ENEMY.GUARD] = {
		// Stats
		enemy_tex: sprite_get_texture(Spr_Player, 0),
		life: 16,
		attack: 8,
		crit_chance: 12,
		crit_rate: 40,
		xp: 15,
		
		// Drops
		potion_heal_drop_chance: 20,
		potion_mana_drop_chance: 20,
		key_drop_chance: 5,
		file_drop_chance: 10,
		file_special_drop_chance: 5,
		equip_drop_chance: 20,
		equip_special_drop_chance: 5,
		
		// Spawn
		spawn_chance: 30,
		spawn_min: 0,
		spawwn_max: 10
    };
	
	// Menus Mantra
	global.enemies[ENEMY.MANTRA] = {
		// Stats
		enemy_tex: sprite_get_texture(Spr_Player, 0),
		life: 8,
		attack: 4,
		crit_chance: 6,
		crit_rate: 66,
		xp: 6,
		
		// Drops
		potion_heal_drop_chance: 42,
		potion_mana_drop_chance: 66,
		key_drop_chance: 8,
		file_drop_chance: 9,
		file_special_drop_chance: 0,
		equip_drop_chance: 0,
		equip_special_drop_chance: 0,
		
		// Spawn
		spawn_chance: 30,
		spawn_min: 0,
		spawwn_max: 10
    };
	
	// O de Ontem ///////////// A SER FEITO
	global.enemies[ENEMY.ME] = {
		// Stats
		enemy_tex: sprite_get_texture(Spr_Player, 0),
		life: 0,
		attack: 0,
		crit_chance: 0,
		crit_rate: 0,
		xp: 150,
		
		// Drops
		potion_heal_drop_chance: 50,
		potion_mana_drop_chance: 50,
		key_drop_chance: 50,
		file_drop_chance: 100,
		file_special_drop_chance: 50,
		equip_drop_chance: 50,
		equip_special_drop_chance: 1,
		
		// Spawn
		spawn_chance: 30,
		spawn_min: 0,
		spawwn_max: 1
    };
	
	// Rato Mutante
	global.enemies[ENEMY.RAT] = {
		// Stats
		enemy_tex: sprite_get_texture(Spr_Player, 0),
		life: 7,
		attack: 5,
		crit_chance: 8,
		crit_rate: 100,
		xp: 7,
		
		// Drops
		potion_heal_drop_chance: 40,
		potion_mana_drop_chance: 50,
		key_drop_chance: 10,
		file_drop_chance: 5,
		file_special_drop_chance: 1,
		equip_drop_chance: 0,
		equip_special_drop_chance: 0,
		
		// Spawn
		spawn_chance: 30,
		spawn_min: 0,
		spawwn_max: 10
    };
	
	// Slme
	global.enemies[ENEMY.SLIME] = {
		// Stats
		enemy_tex: sprite_get_texture(Spr_Player, 0),
		life: 10,
		attack: 3,
		crit_chance: 5,
		crit_rate: 80,
		xp: 5,
		
		// Drops
		potion_heal_drop_chance: 50,
		potion_mana_drop_chance: 40,
		key_drop_chance: 10,
		file_drop_chance: 5,
		file_special_drop_chance: 1,
		equip_drop_chance: 0,
		equip_special_drop_chance: 0,
		
		// Spawn
		spawn_chance: 30,
		spawn_min: 0,
		spawwn_max: 10
    };
	
	// Titio Rosa
	global.enemies[ENEMY.UNCLE] = {
		// Stats
		enemy_tex: sprite_get_texture(Spr_Player, 0),
		life: 180,
		attack: 15,
		crit_chance: 0,
		crit_rate: 0,
		xp: 100,
		
		// Drops
		potion_heal_drop_chance: 0,
		potion_mana_drop_chance: 70,
		key_drop_chance: 35,
		file_drop_chance: 100,
		file_special_drop_chance: 35,
		equip_drop_chance: 50,
		equip_special_drop_chance: 10,
		
		// Spawn
		spawn_chance: 30,
		spawn_min: 0,
		spawwn_max: 1
    };
}