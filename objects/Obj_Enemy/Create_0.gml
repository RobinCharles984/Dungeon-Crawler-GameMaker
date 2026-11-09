/// Evento Create do Obj_Enemy

if (!variable_global_exists("enemies")) init_enemies();

// Só atribui SLIME se NENHUM tipo foi enviado na criação
if (!variable_instance_exists(id, "enemy_type") || enemy_type == undefined) {
    enemy_type = ENEMY.SLIME;
}

// Carrega a struct com os atributos reais do tipo sorteado
enemy_data = global.enemies[enemy_type];

if (enemy_data == undefined) {
    enemy_type = ENEMY.SLIME;
    enemy_data = global.enemies[ENEMY.SLIME];
}

sprite_index = Spr_Enemy;
sprite_dead  = Spr_Enemy_Dead;
enemy_sprite = sprite_index;

target_x   = x;
target_y   = y;
dir        = 0;
target_dir = 0;
depth      = -10;

agro    = 128;
mspeed  = 0.5;
is_dead = false;

// Imprime no Output do GameMaker qual inimigo acabou de ser gerado
show_debug_message("-> [ENEMY SPAWN] Tipo: " + string(enemy_type) + " | Nome: " + string(enemy_data.name));