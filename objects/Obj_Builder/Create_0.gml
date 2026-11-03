/// Evento Create de Obj_Builder
init_biomes();

cell_width = 64;
cell_height = 64;

CELL_FLOOR = -5;
CELL_WALL  = -6;
CELL_VOID  = -7;

// 1. MAPA GIGANTE (65x65 Células = 4160x4160 Pixels em 3D)
var _grid_w = 65; 
var _grid_h = 65;

room_width = _grid_w * cell_width;
room_height = _grid_h * cell_height;

grid       = ds_grid_create(_grid_w, _grid_h);
biome_grid = ds_grid_create(_grid_w, _grid_h);

ds_grid_set_region(grid, 0, 0, _grid_w - 1, _grid_h - 1, CELL_VOID);

randomize();

// 2. BIOMAS DA RUN (Sorteia de 1 a 3 biomas)
var _available_biomes = [BIOME.SEWER, BIOME.CAVE, BIOME.DUNGEON];
var _num_biomes_in_run = irandom_range(1, 3);
var _run_biomes = [];

for (var i = 0; i < _num_biomes_in_run; i++) {
    var _rand_idx = irandom(array_length(_available_biomes) - 1);
    array_push(_run_biomes, _available_biomes[_rand_idx]);
    array_delete(_available_biomes, _rand_idx, 1);
}

// 3. META RÍGIDA DE TAMANHO POR BIOMA
var _target_floors_per_biome = 350; // Cada bioma terá EXATAMENTE 350 blocos de chão
var _total_target_floors = _target_floors_per_biome * _num_biomes_in_run;

// Listas para guardar todas as posições de chão escavadas (Evita travamentos)
var _floor_list_x = [];
var _floor_list_y = [];

// Ponto de início no centro da grade
var _cx = 1 + 2 * (_grid_w div 4);
var _cy = 1 + 2 * (_grid_h div 4);

var _player_start_x = _cx;
var _player_start_y = _cy;

// Cava o primeiro bloco (Spawn)
grid[# _cx, _cy] = CELL_FLOOR;
biome_grid[# _cx, _cy] = _run_biomes[0];
array_push(_floor_list_x, _cx);
array_push(_floor_list_y, _cy);

var _carved_count = 1;
var _cdir = irandom(3);

// Loop de Escavação Garantida
while (_carved_count < _total_target_floors) {
    // Define o bioma atual baseado em quantos blocos NOVOS foram criados
    var _biome_idx = min((_carved_count - 1) div _target_floors_per_biome, _num_biomes_in_run - 1);
    var _active_biome = _run_biomes[_biome_idx];

    var _xdir = lengthdir_x(1, _cdir * 90);
    var _ydir = lengthdir_y(1, _cdir * 90);

    var _next_x = _cx + (_xdir * 2);
    var _next_y = _cy + (_ydir * 2);

    // Se estiver dentro da área jogável
    if (_next_x >= 2 && _next_x < _grid_w - 2 && _next_y >= 2 && _next_y < _grid_h - 2) {
        var _mid_x = _cx + _xdir;
        var _mid_y = _cy + _ydir;

        // Cava o bloco intermediário se for vazio
        if (grid[# _mid_x, _mid_y] == CELL_VOID) {
            grid[# _mid_x, _mid_y] = CELL_FLOOR;
            biome_grid[# _mid_x, _mid_y] = _active_biome;
            array_push(_floor_list_x, _mid_x);
            array_push(_floor_list_y, _mid_y);
			var _enemy_entity = instance_create_layer(0, 0, "Instances", Obj_Enemy_Test);
            _carved_count++;
        }

        // Cava o bloco de destino se for vazio
        _cx = _next_x;
        _cy = _next_y;

        if (grid[# _cx, _cy] == CELL_VOID) {
            grid[# _cx, _cy] = CELL_FLOOR;
            biome_grid[# _cx, _cy] = _active_biome;
            array_push(_floor_list_x, _cx);
            array_push(_floor_list_y, _cy);
            _carved_count++;
        }

        // Chance de virar 90 graus
        if (irandom(2) == 0) {
            _cdir = (_cdir + choose(-1, 1) + 4) mod 4;
        }
    } else {
        // TELEPORTE ANTI-BLOQUEIO: Se bateu na borda, salta para um chão existente e cria uma nova ramificação
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

// 6. INSTANCIAÇÃO DO CHÃO/TETO E SPAWN DO JOGADOR
var _ceil_floor = instance_create_layer(0, 0, "Instances", Obj_Ceil_Floor);
_ceil_floor.builder_ref = id;

instance_create_layer(_player_start_x * cell_width + (cell_width / 2), _player_start_y * cell_height + (cell_height / 2), "Instances", Obj_Player);