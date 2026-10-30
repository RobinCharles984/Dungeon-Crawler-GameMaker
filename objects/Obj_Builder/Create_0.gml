/// Evento Create de Obj_Builder
init_biomes(); // Inicializa as texturas e cores

cell_width = 64;
cell_height = 64;

CELL_FLOOR = -5;
CELL_WALL  = -6;
CELL_VOID  = -7;

room_width = 4096;
room_height = 4096;

var _width  = room_width div cell_width;
var _height = room_height div cell_height;

// Grades do mapa
grid       = ds_grid_create(_width, _height);
biome_grid = ds_grid_create(_width, _height);

ds_grid_set_region(grid, 0, 0, _width - 1, _height - 1, CELL_VOID);

randomize();

// 1. Define quantos e quais biomas existirão NESSA RUN (1, 2 ou 3)
var _available_biomes = [BIOME.SEWER, BIOME.CAVE, BIOME.DUNGEON];
var _num_biomes_in_run = irandom_range(1, 3);
var _run_biomes = [];

for (var i = 0; i < _num_biomes_in_run; i++) {
    var _rand_idx = irandom(array_length(_available_biomes) - 1);
    array_push(_run_biomes, _available_biomes[_rand_idx]);
    array_delete(_available_biomes, _rand_idx, 1);
}

// Bioma inicial
var _current_biome = _run_biomes[irandom(array_length(_run_biomes) - 1)];

// 2. Random Walker
var _cx = _width div 2;
var _cy = _height div 2;
var _cdir = irandom(3);

grid[# _cx, _cy] = CELL_FLOOR;
biome_grid[# _cx, _cy] = _current_biome;

var _odds = 1;

repeat(400) {
    // A cada ~120 passos, tem chance de mudar para outro bioma da run
    if (irandom(120) == 0) {
        _current_biome = _run_biomes[irandom(array_length(_run_biomes) - 1)];
    }

    var _xdir = lengthdir_x(1, _cdir * 90);
    var _ydir = lengthdir_y(1, _cdir * 90);
    
    _cx = clamp(_cx + _xdir, 1, _width - 2);
    _cy = clamp(_cy + _ydir, 1, _height - 2);
    
    grid[# _cx, _cy] = CELL_FLOOR;
    biome_grid[# _cx, _cy] = _current_biome;
    
    if (irandom(_odds) == _odds) {
        _cdir = irandom(3);
    }
}

// 3. Define as Paredes e herda o bioma do chão vizinho
for (var _yy = 1; _yy < _height - 1; _yy++) {
    for (var _xx = 1; _xx < _width - 1; _xx++) {
        if (grid[# _xx, _yy] == CELL_FLOOR) {
            var _b = biome_grid[# _xx, _yy];
            
            var _dirs = [[1,0], [-1,0], [0,1], [0,-1]];
            for (var d = 0; d < 4; d++) {
                var _nx = _xx + _dirs[d][0];
                var _ny = _yy + _dirs[d][1];
                if (grid[# _nx, _ny] != CELL_FLOOR) {
                    grid[# _nx, _ny] = CELL_WALL;
                    biome_grid[# _nx, _ny] = _b;
                }
            }
        }
    }
}

// 4. Instancia Paredes passando o bioma correto
for (var _yy = 0; _yy < _height; _yy++) {
    for (var _xx = 0; _xx < _width; _xx++) {
        if (grid[# _xx, _yy] == CELL_WALL) {
            var _wall = instance_create_layer(_xx * cell_width, _yy * cell_height, "Instances", Obj_Wall);
            _wall.biome_type = biome_grid[# _xx, _yy];
        }
    }
}

// 5. Instancia Chão/Teto e Jogador
var _spawn_x = (room_width div 2);
var _spawn_y = (room_height div 2);

var _ceil_floor = instance_create_layer(_spawn_x, _spawn_y, "Instances", Obj_Ceil_Floor);
_ceil_floor.builder_ref = id; // Passa a referência do builder para desenhar o chão por célula

instance_create_layer(_spawn_x + (cell_width / 2), _spawn_y + (cell_height / 2), "Instances", Obj_Player);