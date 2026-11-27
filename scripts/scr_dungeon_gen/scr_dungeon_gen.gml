// Escava o labirinto, preenche paredes e retorna pontos-chave (Contexto: Obj_Builder)
function dungeon_generate_grid(_grid_w, _grid_h, _floors_per_biome) {
    room_width  = _grid_w * cell_width;
    room_height = _grid_h * cell_height;

    grid       = ds_grid_create(_grid_w, _grid_h);
    biome_grid = ds_grid_create(_grid_w, _grid_h);
    ds_grid_set_region(grid, 0, 0, _grid_w - 1, _grid_h - 1, CELL_VOID);

    randomize();
    var _run_biomes   = array_shuffle([BIOME.SEWER, BIOME.CAVE, BIOME.DUNGEON]);
    var _num_biomes   = array_length(_run_biomes);
    var _total_target = _floors_per_biome * _num_biomes;

    var _floor_x = [], _floor_y = [];
    var _cx = _grid_w div 2, _cy = _grid_h div 2;
    var _start_x = _cx, _start_y = _cy;

    // Celula inicial
    grid[# _cx, _cy]       = CELL_FLOOR;
    biome_grid[# _cx, _cy] = _run_biomes[0];
    array_push(_floor_x, _cx);
    array_push(_floor_y, _cy);

    var _carved = 1, _cdir = irandom(3);

    // Random walker com salto anti-bloqueio
    while (_carved < _total_target) {
        var _b_idx  = min((_carved - 1) div _floors_per_biome, _num_biomes - 1);
        var _biome  = _run_biomes[_b_idx];
        var _xdir   = round(lengthdir_x(1, _cdir * 90));
        var _ydir   = round(lengthdir_y(1, _cdir * 90));
        var _next_x = _cx + (_xdir * 2);
        var _next_y = _cy + (_ydir * 2);

        if (_next_x >= 2 && _next_x < _grid_w - 2 && _next_y >= 2 && _next_y < _grid_h - 2) {
            var _mx = _cx + _xdir, _my = _cy + _ydir;
            if (grid[# _mx, _my] == CELL_VOID) {
                grid[# _mx, _my] = CELL_FLOOR; biome_grid[# _mx, _my] = _biome;
                array_push(_floor_x, _mx); array_push(_floor_y, _my);
                _carved++;
            }
            _cx = _next_x; _cy = _next_y;
            if (grid[# _cx, _cy] == CELL_VOID) {
                grid[# _cx, _cy] = CELL_FLOOR; biome_grid[# _cx, _cy] = _biome;
                array_push(_floor_x, _cx); array_push(_floor_y, _cy);
                _carved++;
            }
            if (irandom(2) == 0) _cdir = (_cdir + choose(-1, 1) + 4) mod 4;
        } else {
            var _r = irandom(array_length(_floor_x) - 1);
            _cx = _floor_x[_r]; _cy = _floor_y[_r];
            _cdir = irandom(3);
        }
    }

    // Marca celulas VOID vizinhas ao chao como WALL
    var _dirs = [[1,0], [-1,0], [0,1], [0,-1]];
    for (var _yy = 0; _yy < _grid_h; _yy++) {
        for (var _xx = 0; _xx < _grid_w; _xx++) {
            if (grid[# _xx, _yy] != CELL_VOID) continue;
            for (var d = 0; d < 4; d++) {
                var _nx = _xx + _dirs[d][0], _ny = _yy + _dirs[d][1];
                if (_nx >= 0 && _nx < _grid_w && _ny >= 0 && _ny < _grid_h && grid[# _nx, _ny] == CELL_FLOOR) {
                    grid[# _xx, _yy]       = CELL_WALL;
                    biome_grid[# _xx, _yy] = biome_grid[# _nx, _ny];
                    break;
                }
            }
        }
    }

    // Encontra a celula de chao mais distante do spawn para a saida
    var _max_d = -1, _exit_x = _start_x, _exit_y = _start_y;
    for (var i = 0; i < array_length(_floor_x); i++) {
        var _d = point_distance(_start_x, _start_y, _floor_x[i], _floor_y[i]);
        if (_d > _max_d) { _max_d = _d; _exit_x = _floor_x[i]; _exit_y = _floor_y[i]; }
    }

    return { start_x: _start_x, start_y: _start_y, exit_x: _exit_x, exit_y: _exit_y };
}

// Instancia inimigos compativeis com o bioma de cada celula (Contexto: Obj_Builder)
function dungeon_spawn_enemies(_start_x, _start_y, _exit_x, _exit_y, _min_total, _max_total) {
    if (!variable_global_exists("enemies")) init_enemies();

    var _gw = ds_grid_width(grid), _gh = ds_grid_height(grid);
    var _floors = [];

    for (var _yy = 0; _yy < _gh; _yy++) {
        for (var _xx = 0; _xx < _gw; _xx++) {
            if (grid[# _xx, _yy] == CELL_FLOOR && point_distance(_xx, _yy, _start_x, _start_y) > 4 && (_xx != _exit_x || _yy != _exit_y)) {
                array_push(_floors, { x: _xx, y: _yy, biome: biome_grid[# _xx, _yy] });
            }
        }
    }

    _floors = array_shuffle(_floors);
    var _total = min(irandom_range(_min_total, _max_total), array_length(_floors));

    for (var s = 0; s < _total; s++) {
        var _c = _floors[s];
        var _pool = [];

        for (var e = 0; e < array_length(global.enemies); e++) {
            var _ed = global.enemies[e];
            if (_ed == undefined || !variable_struct_exists(_ed, "allowed_biomes")) continue;
            if (array_contains(_ed.allowed_biomes, _c.biome)) array_push(_pool, e);
        }

        var _type = (array_length(_pool) > 0) ? _pool[irandom(array_length(_pool) - 1)] : ENEMY.SLIME;
        var _rx   = _c.x * cell_width + (cell_width / 2);
        var _ry   = _c.y * cell_height + (cell_height / 2);

        var _inst = instance_create_layer(_rx, _ry, "Instances", Obj_Enemy, { enemy_type: _type });
        _inst.depth = -10;
    }
}