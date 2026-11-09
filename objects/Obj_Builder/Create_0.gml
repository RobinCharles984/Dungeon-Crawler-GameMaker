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

// 5. CONSTRUÇÃO DO VERTEX BUFFER DAS PAREDES (BATCHING 3D)
// Formato de vértice 3D: Posição (X,Y,Z) + Normal + Cor + Textura (UV)
format = undefined;
if (format == undefined) {
    vertex_format_begin();
    vertex_format_add_position_3d();
    vertex_format_add_color();
    vertex_format_add_textcoord();
    format = vertex_format_end();
}

// Cria um buffer para cada bioma
wall_vbuf = [];
wall_vbuf[BIOME.SEWER]   = vertex_create_buffer();
wall_vbuf[BIOME.CAVE]    = vertex_create_buffer();
wall_vbuf[BIOME.DUNGEON] = vertex_create_buffer();

for (var b = 0; b < 3; b++) {
    vertex_begin(wall_vbuf[b], format);
}

// Helper interno para adicionar uma face 3D (Quad) ao buffer
var _add_face = function(_vbuf, _x1,_y1,_z1, _x2,_y2,_z2, _x3,_y3,_z3, _x4,_y4,_z4) {
    // Triângulo 1
    vertex_position_3d(_vbuf, _x1, _y1, _z1); vertex_color(_vbuf, c_white, 1); vertex_texcoord(_vbuf, 0, 0);
    vertex_position_3d(_vbuf, _x2, _y2, _z2); vertex_color(_vbuf, c_white, 1); vertex_texcoord(_vbuf, 1, 0);
    vertex_position_3d(_vbuf, _x3, _y3, _z3); vertex_color(_vbuf, c_white, 1); vertex_texcoord(_vbuf, 1, 1);
    // Triângulo 2
    vertex_position_3d(_vbuf, _x1, _y1, _z1); vertex_color(_vbuf, c_white, 1); vertex_texcoord(_vbuf, 0, 0);
    vertex_position_3d(_vbuf, _x3, _y3, _z3); vertex_color(_vbuf, c_white, 1); vertex_texcoord(_vbuf, 1, 1);
    vertex_position_3d(_vbuf, _x4, _y4, _z4); vertex_color(_vbuf, c_white, 1); vertex_texcoord(_vbuf, 0, 1);
};

// Varia por todo o grid criando os cubos 3D das paredes
for (var _yy = 0; _yy < _grid_h; _yy++) {
    for (var _xx = 0; _xx < _grid_w; _xx++) {
        if (grid[# _xx, _yy] == CELL_WALL) {
            var _b = biome_grid[# _xx, _yy];
            var _v = wall_vbuf[_b];

            var _x1 = _xx * cell_width;
            var _y1 = _yy * cell_height;
            var _x2 = _x1 + cell_width;
            var _y2 = _y1 + cell_height;
            var _z1 = 0;
            var _z2 = 64; // Altura da parede

            // Frente, Trás, Esquerda, Direita e Topo do bloco
            _add_face(_v, _x1, _y1, _z2,  _x2, _y1, _z2,  _x2, _y1, _z1,  _x1, _y1, _z1); // Face Norte
            _add_face(_v, _x2, _y2, _z2,  _x1, _y2, _z2,  _x1, _y2, _z1,  _x2, _y2, _z1); // Face Sul
            _add_face(_v, _x1, _y2, _z2,  _x1, _y1, _z2,  _x1, _y1, _z1,  _x1, _y2, _z1); // Face Oeste
            _add_face(_v, _x2, _y1, _z2,  _x2, _y2, _z2,  _x2, _y2, _z1,  _x2, _y1, _z1); // Face Leste
        }
    }
}

// Finaliza a gravação dos buffers
for (var b = 0; b < 3; b++) {
    vertex_end(wall_vbuf[b]);
    vertex_freeze(wall_vbuf[b]); // Envia direto para a memória VRAM da GPU para performance máxima
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

// 8. SPAWN PROCEDURAL DIVERSIFICADO POR BIOMA
if (!variable_global_exists("enemies")) init_enemies();

var _gw = ds_grid_width(grid);
var _gh = ds_grid_height(grid);

// 1. Coleta todos os chãos válidos longe do spawn do player e da saída
var _valid_floor_cells = [];

for (var _yy = 0; _yy < _gh; _yy++) {
    for (var _xx = 0; _xx < _gw; _xx++) {
        if (grid[# _xx, _yy] == CELL_FLOOR) {
            if (point_distance(_xx, _yy, _player_start_x, _player_start_y) > 4 && (_xx != _exit_gx || _yy != _exit_gy)) {
                array_push(_valid_floor_cells, { x: _xx, y: _yy, biome: biome_grid[# _xx, _yy] });
            }
        }
    }
}

// Embaralha as posições de chão
_valid_floor_cells = array_shuffle(_valid_floor_cells);

// 2. Define a quantidade total de inimigos na dungeon (ex: 45 a 60 inimigos espalhados)
var _total_spawns = min(irandom_range(45, 60), array_length(_valid_floor_cells));

for (var s = 0; s < _total_spawns; s++) {
    var _cell = _valid_floor_cells[s];
    var _cell_biome = _cell.biome;

    // Filtra todos os inimigos cadastrados em global.enemies que aceitam o bioma desta célula
    var _compatible_enemies = [];

    for (var e = 0; e < array_length(global.enemies); e++) {
        var _edata = global.enemies[e];
        if (_edata == undefined) continue;

        if (variable_struct_exists(_edata, "allowed_biomes") && is_array(_edata.allowed_biomes)) {
            for (var b = 0; b < array_length(_edata.allowed_biomes); b++) {
                if (_edata.allowed_biomes[b] == _cell_biome) {
                    array_push(_compatible_enemies, e); // Armazena o índice do Enum ENEMY
                    break;
                }
            }
        }
    }

    // Sorteia um dos inimigos compatíveis com o bioma atual
    var _chosen_type = ENEMY.SLIME;
    if (array_length(_compatible_enemies) > 0) {
        _compatible_enemies = array_shuffle(_compatible_enemies);
        _chosen_type = _compatible_enemies[0];
    }

    // Instancia o inimigo na posição 3D enviando o tipo sorteado
    var _real_x = _cell.x * cell_width + (cell_width / 2);
    var _real_y = _cell.y * cell_height + (cell_height / 2);

    var _inst = instance_create_layer(_real_x, _real_y, "Instances", Obj_Enemy, { enemy_type: _chosen_type });
    _inst.depth = -10;
}