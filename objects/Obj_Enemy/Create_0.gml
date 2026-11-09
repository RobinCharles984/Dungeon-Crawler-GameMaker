/// Evento Create do Obj_Enemy

if (!variable_instance_exists(id, "enemy_type")) {
    enemy_type = ENEMY.SLIME;
}

if (!variable_global_exists("enemies")) init_enemies();

enemy_data = global.enemies[enemy_type];

// -------------------------------------------------------------
// CORREÇÃO VISUAL: Atribui o sprite para o d3d_billboard() desenhar
// -------------------------------------------------------------
sprite_index = Spr_Enemy; // Atribua aqui o seu sprite do inimigo
enemy_sprite = sprite_index;

target_x   = x;
target_y   = y;
dir        = 0;
target_dir = 0;
depth = -10001;

// Alcance de 48px (menor que 1 bloco de 64px para não puxar de muito longe)
agro   = 128; 
mspeed = 0.5;

// --- ESTADO DE DERROTA ---
is_dead     = false;
sprite_dead = Spr_Enemy_Dead;

show_debug_message("-> [SPAWN ENEMY] Tipo: " + string(enemy_type) + " em Pos Real X: " + string(x) + " Y: " + string(y) + " | Sprite: " + sprite_get_name(sprite_index));