/// Create_0.gml
init_biomes();

cell_width  = 64;
cell_height = 64;
CELL_FLOOR  = -5;
CELL_WALL   = -6;
CELL_VOID   = -7;

// 1. Gera mapa e malha de paredes
var _pts  = dungeon_generate_grid(105, 105, 750);
wall_vbuf = dungeon_build_wall_buffers(id);

// 2. Spawna chao/teto, jogador, saida e inimigos
instance_create_layer(0, 0, "Instances", Obj_Ceil_Floor, { builder_ref: id });
instance_create_layer(_pts.start_x * cell_width + 32, _pts.start_y * cell_height + 32, "Instances", Obj_Player);

var _exit = instance_create_layer(_pts.exit_x * cell_width + 32, _pts.exit_y * cell_height + 32, "Instances", Obj_Exit);
_exit.depth = -10;

var _free_cells = dungeon_collect_free_cells(_pts.start_x, _pts.start_y, _pts.exit_x, _pts.exit_y);
dungeon_spawn_enemies(_free_cells);
dungeon_spawn_props(_free_cells);