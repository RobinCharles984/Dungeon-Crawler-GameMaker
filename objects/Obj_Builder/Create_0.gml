/// Evento Create de Obj_Builder
init_biomes();

cell_width = 64;
cell_height = 64;

CELL_FLOOR = -5;
CELL_WALL  = -6;
CELL_VOID  = -7;

// 1. MAPA EXPANDIDO (105x105 Células = 6720x6720 Pixels em 3D)
var _grid_w = 105; 
var _grid_h = 105;

room_width = _grid_w * cell_width;
room_height = _grid_h * cell_height;

grid       = ds_grid_create(_grid_w, _grid_h);
biome_grid = ds_grid_create(_grid_w, _grid_h);

ds_grid_set_region(grid, 0, 0, _grid_w - 1, _grid_h - 1, CELL_VOID);

randomize();

// 2. GARANTE TODOS OS 3 BIOMAS EM ORDEM EMBARALHADA
var _run_biomes = array_shuffle([BIOME.SEWER, BIOME.CAVE, BIOME.DUNGEON]);
var _num_biomes_in_run = array_length(_run_biomes);

// 3. META AUMENTADA: 750 BLOCOS POR BIOMA (Total de 2250 células escavadas)
var _target_floors_per_biome = 750;
var _total_target_floors = _target_floors_per_biome * _num_biomes_in_run;

var _floor_list_x = [];
var _floor_list_y = [];

// Ponto de início no centro da grade
var _cx = _grid_w div 2;
var _cy = _grid_h div 2;

var _player_start_x = _cx;
var _player_start_y = _cy;

// Cava o Spawn
grid[# _cx, _cy] = CELL_FLOOR;
biome_grid[# _cx, _cy] = _run_biomes[0];
array_push(_floor_list_x, _cx);
array_push(_floor_list_y, _cy);

var _carved_count = 1;
var _cdir = irandom(3);

// Loop de Escavação Garantida
while (_carved_count < _total_target_floors) {
    var _biome_idx = min((_carved_count - 1) div _target_floors_per_biome, _num_biomes_in_run - 1);
    var _active_biome = _run_biomes[_biome_idx];

    var _xdir = lengthdir_x(1, _cdir * 90);
    var _ydir = lengthdir_y(1, _cdir * 90);

    var _next_x = _cx + (_xdir * 2);
    var _next_y = _cy + (_ydir * 2);

    if (_next_x >= 2 && _next_x < _grid_w - 2 && _next_y >= 2 && _next_y < _grid_h - 2) {
        var _mid_x = _cx + _xdir;
        var _mid_y = _cy + _ydir;

        if (grid[# _mid_x, _mid_y] == CELL_VOID) {
            grid[# _mid_x, _mid_y] = CELL_FLOOR;
            biome_grid[# _mid_x, _mid_y] = _active_biome;
            array_push(_floor_list_x, _mid_x);
            array_push(_floor_list_y, _mid_y);
            _carved_count++;
        }

        _cx = _next_x;
        _cy = _next_y;

        if (grid[# _cx, _cy] == CELL_VOID) {
            grid[# _cx, _cy] = CELL_FLOOR;
            biome_grid[# _cx, _cy] = _active_biome;
            array_push(_floor_list_x, _cx);
            array_push(_floor_list_y, _cy);
            _carved_count++;
        }

        if (irandom(2) == 0) {
            _cdir = (_cdir + choose(-1, 1) + 4) mod 4;
        }
    } else {
        var _rand_pos = irandom(array_length(_floor_list_x) - 1);
        _cx = _floor_list_x[_rand_pos];
        _cy = _floor_list_y[_rand_pos];
        _cdir = irandom(3);
    }
}

// 4. CONSTRUÇÃO DAS PAREDES
for (var _yy = 0; _yy < _grid_h; _yy++) {
    for (var _xx = 0; _xx < _grid_w; _xx++) {
        if (grid[# _xx, _yy] == CELL_VOID) {
            var _dirs = [[1,0], [-1,0], [0,1], [0,-1]];
            for (var d = 0; d < 4; d++) {
                var _nx = _xx + _dirs[d][0];
                var _ny = _yy + _dirs[d][1];
                if (_nx >= 0 && _nx < _grid_w && _ny >= 0 && _ny < _grid_h) {
                    if (grid[# _nx, _ny] == CELL_FLOOR) {
                        grid[# _xx, _yy] = CELL_WALL;
                        biome_grid[# _xx, _yy] = biome_grid[# _nx, _ny];
                        break;
                    }
                }
            }
        }
    }
}

// 5. INSTANCIAÇÃO DAS PAREDES 3D
for (var _yy = 0; _yy < _grid_h; _yy++) {
    for (var _xx = 0; _xx < _grid_w; _xx++) {
        if (grid[# _xx, _yy] == CELL_WALL) {
            var _wall = instance_create_layer(_xx * cell_width, _yy * cell_height, "Instances", Obj_Wall);
            _wall.biome_type = biome_grid[# _xx, _yy];
        }
    }
}

// 6. CHÃO/TETO E PLAYER
var _ceil_floor = instance_create_layer(0, 0, "Instances", Obj_Ceil_Floor);
_ceil_floor.builder_ref = id;

instance_create_layer(_player_start_x * cell_width + (cell_width / 2), _player_start_y * cell_height + (cell_height / 2), "Instances", Obj_Player);

// 7. POSICIONAMENTO DA SAÍDA NA CÉLULA MAIS DISTANTE
var _max_dist = -1;
var _exit_gx = _player_start_x;
var _exit_gy = _player_start_y;

for (var i = 0; i < array_length(_floor_list_x); i++) {
    var _fx = _floor_list_x[i];
    var _fy = _floor_list_y[i];
    var _d  = point_distance(_player_start_x, _player_start_y, _fx, _fy);

    if (_d > _max_dist) {
        _max_dist = _d;
        _exit_gx  = _fx;
        _exit_gy  = _fy;
    }
}

var _exit_real_x = _exit_gx * cell_width + (cell_width / 2);
var _exit_real_y = _exit_gy * cell_height + (cell_height / 2);
var _exit_inst   = instance_create_layer(_exit_real_x, _exit_real_y, "Instances", Obj_Exit);
_exit_inst.depth = -10;

// 8. SPAWN DE INIMIGOS ESCALADO E GARANTIDO
if (!variable_global_exists("enemies")) init_enemies();

var _biome_cells = [];
_biome_cells[BIOME.SEWER]   = [];
_biome_cells[BIOME.CAVE]    = [];
_biome_cells[BIOME.DUNGEON] = [];

for (var _yy = 0; _yy < _grid_h; _yy++) {
    for (var _xx = 0; _xx < _grid_w; _xx++) {
        if (grid[# _xx, _yy] == CELL_FLOOR) {
            // Não spawna colado no player (raio de 4 blocos) nem na célula da saída
            if (point_distance(_xx, _yy, _player_start_x, _player_start_y) > 4 && (_xx != _exit_gx || _yy != _exit_gy)) {
                var _b = biome_grid[# _xx, _yy];
                array_push(_biome_cells[_b], { x: _xx, y: _yy });
            }
        }
    }
}

var _total_enemy_types = array_length(global.enemies);

for (var i = 0; i < _total_enemy_types; i++) {
    var _e = global.enemies[i];
    if (_e == undefined) continue;

    var _max_val = _e[$ "spawwn_max"] ?? _e[$ "spawn_max"] ?? 5;
    // Multiplica a quantidade proporcionalmente ao tamanho gigante do mapa
    var _amount = irandom_range(_e.spawn_min * 2, _max_val * 3);

    var _valid_cells = [];
    if (variable_struct_exists(_e, "allowed_biomes")) {
        for (var b = 0; b < array_length(_e.allowed_biomes); b++) {
            var _target_biome = _e.allowed_biomes[b];
            var _cells_in_b   = _biome_cells[_target_biome];
            for (var c = 0; c < array_length(_cells_in_b); c++) {
                array_push(_valid_cells, _cells_in_b[c]);
            }
        }
    }

    var _available_count = array_length(_valid_cells);
    if (_available_count > 0) {
        _valid_cells = array_shuffle(_valid_cells);
        var _to_spawn = min(_amount, _available_count);

        for (var s = 0; s < _to_spawn; s++) {
            var _pos    = _valid_cells[s];
            var _real_x = _pos.x * cell_width + (cell_width / 2);
            var _real_y = _pos.y * cell_height + (cell_height / 2);

            var _inst   = instance_create_layer(_real_x, _real_y, "Instances", Obj_Enemy, { enemy_type: i });
            _inst.depth = -10;
        }
    }
}