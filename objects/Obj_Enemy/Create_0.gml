/// Create_0.gml
if (!variable_global_exists("enemies")) init_enemies();
if (!variable_instance_exists(id, "enemy_type") || enemy_type == undefined) enemy_type = ENEMY.SLIME;
hit_flash_timer = 0;

enemy_data = global.enemies[enemy_type] ?? global.enemies[ENEMY.SLIME];

sprite_index = Spr_Enemy;
sprite_dead  = Spr_Enemy_Dead;
depth        = -10;
is_dead      = false;