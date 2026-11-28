// Escava o labirinto, distribui biomas em territorios continuos e posiciona a saida (Contexto: Obj_Builder)
function dungeon_generate_grid(_grid_w, _grid_h, _floors_per_biome) {
    room_width  = _grid_w * cell_width;
    room_height = _grid_h * cell_height;

    grid       = ds_grid_create(_grid_w, _grid_h);
    biome_grid = ds_grid_create(_grid_w, _grid_h);
    ds_grid_set_region(grid,       0, 0, _grid_w - 1, _grid_h - 1, CELL_VOID);
    ds_grid_set_region(biome_grid, 0, 0, _grid_w - 1, _grid_h - 1, -1);

    randomize();

    // --- 1. ESCAVACAO DA GEOMETRIA (Tamanho total fixo, independente da qtd de biomas) ---
    var _total_target = _floors_per_biome * 3;
    var _floor_x = [], _floor_y = [];
    var _cx = _grid_w div 2, _cy = _grid_h div 2;
    var _start_x = _cx, _start_y = _cy;

    grid[# _cx, _cy] = CELL_FLOOR;
    array_push(_floor_x, _cx);
    array_push(_floor_y, _cy);

    var _carved = 1, _cdir = irandom(3);
    while (_carved < _total_target) {
        var _xdir   = round(lengthdir_x(1, _cdir * 90));
        var _ydir   = round(lengthdir_y(1, _cdir * 90));
        var _next_x = _cx + (_xdir * 2);
        var _next_y = _cy + (_ydir * 2);

        if (_next_x >= 2 && _next_x < _grid_w - 2 && _next_y >= 2 && _next_y < _grid_h - 2) {
            var _mx = _cx + _xdir, _my = _cy + _ydir;
            if (grid[# _mx, _my] == CELL_VOID) {
                grid[# _mx, _my] = CELL_FLOOR;
                array_push(_floor_x, _mx); array_push(_floor_y, _my);
                _carved++;
            }
            _cx = _next_x; _cy = _next_y;
            if (grid[# _cx, _cy] == CELL_VOID) {
                grid[# _cx, _cy] = CELL_FLOOR;
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

    // --- 2. COMPOSICAO DE BIOMAS DA RUN (Ajuste as porcentagens aqui) ---
    var _chance_1_biome = 20; // 20%: mapa inteiro de 1 bioma
    var _chance_2_biome = 40; // 40%: 2 biomas (restante 40% = todos os 3)
    var _chance_repeat  = 45; // Chance de um bioma anterior reaparecer em outra ponta

    var _roll = random(100);
    var _biome_count = (_roll < _chance_1_biome) ? 1 : ((_roll < _chance_1_biome + _chance_2_biome) ? 2 : 3);

    var _all_biomes = array_shuffle([BIOME.SEWER, BIOME.CAVE, BIOME.DUNGEON]);
    var _zone_biomes = [];
    for (var i = 0; i < _biome_count; i++) {
        array_push(_zone_biomes, _all_biomes[i]);
    }

    // Opcionalmente cria uma zona extra repetindo um bioma anterior (ex: A -> B -> A ou A -> B -> C -> A)
    if (_biome_count >= 2 && random(100) < _chance_repeat) {
        // Evita repetir o ultimo bioma da sequencia para nao apenas fundir os dois
        var _repeat_idx = irandom(_biome_count - 2);
        array_push(_zone_biomes, _zone_biomes[_repeat_idx]);
    }

    // --- 3. PINTURA DE BIOMAS POR TERRITORIOS CONTINUOS ---
    dungeon_paint_biome_territories(_floor_x, _floor_y, _zone_biomes);

    // --- 4. CONSTRUCAO DAS PAREDES (Herda o bioma majoritario dos chaos vizinhos) ---
    var _dirs = [[1,0], [-1,0], [0,1], [0,-1]];
    for (var _yy = 0; _yy < _grid_h; _yy++) {
        for (var _xx = 0; _xx < _grid_w; _xx++) {
            if (grid[# _xx, _yy] != CELL_VOID) continue;

            var _votes = [0, 0, 0];
            var _adj_floor = false;

            for (var d = 0; d < 4; d++) {
                var _nx = _xx + _dirs[d][0], _ny = _yy + _dirs[d][1];
                if (_nx >= 0 && _nx < _grid_w && _ny >= 0 && _ny < _grid_h && grid[# _nx, _ny] == CELL_FLOOR) {
                    var _nb = biome_grid[# _nx, _ny];
                    if (_nb >= 0 && _nb < 3) _votes[_nb]++;
                    _adj_floor = true;
                }
            }

            if (_adj_floor) {
                var _best_b = 0;
                if (_votes[1] > _votes[_best_b]) _best_b = 1;
                if (_votes[2] > _votes[_best_b]) _best_b = 2;

                grid[# _xx, _yy]       = CELL_WALL;
                biome_grid[# _xx, _yy] = _best_b;
            }
        }
    }

    // --- 5. SAIDA NA CELULA MAIS DISTANTE DO SPAWN ---
    var _max_d = -1, _exit_x = _start_x, _exit_y = _start_y;
    for (var i = 0; i < array_length(_floor_x); i++) {
        var _d = point_distance(_start_x, _start_y, _floor_x[i], _floor_y[i]);
        if (_d > _max_d) { _max_d = _d; _exit_x = _floor_x[i]; _exit_y = _floor_y[i]; }
    }

    show_debug_message("[DUNGEON BIOMES] Zonas na run: " + string(_zone_biomes));
    return { start_x: _start_x, start_y: _start_y, exit_x: _exit_x, exit_y: _exit_y };
}

// Distribui os biomas em grandes regioes conectadas usando Farthest-Point Seeds + Multi-Source BFS
function dungeon_paint_biome_territories(_floor_x, _floor_y, _zone_biomes) {
    var _n_floors = array_length(_floor_x);
    var _n_zones  = array_length(_zone_biomes);
    var _gw       = ds_grid_width(grid);
    var _gh       = ds_grid_height(grid);

    // Caso 1: run de bioma unico (preenche tudo direto)
    if (_n_zones == 1) {
        var _b0 = _zone_biomes[0];
        for (var i = 0; i < _n_floors; i++) {
            biome_grid[# _floor_x[i], _floor_y[i]] = _b0;
        }
        exit;
    }

    // Caso 2 ou mais zonas: escolhe sementes bem espacadas pelo mapa
    var _seeds = [];

    // Semente 0: ponto mais distante de uma celula aleatoria (ancora em uma extremidade do mapa)
    var _ref_idx = irandom(_n_floors - 1);
    var _ref_x   = _floor_x[_ref_idx], _ref_y = _floor_y[_ref_idx];
    var _best_i  = 0, _best_d = -1;
    for (var i = 0; i < _n_floors; i++) {
        var _d = point_distance(_ref_x, _ref_y, _floor_x[i], _floor_y[i]);
        if (_d > _best_d) { _best_d = _d; _best_i = i; }
    }
    array_push(_seeds, { x: _floor_x[_best_i], y: _floor_y[_best_i], dist: 0 });

    // Demais sementes: Farthest-Point Sampling (maximiza a distancia ate todas as sementes anteriores)
    for (var z = 1; z < _n_zones; z++) {
        var _far_i = 0, _far_min_d = -1;
        for (var i = 0; i < _n_floors; i++) {
            var _fx = _floor_x[i], _fy = _floor_y[i];
            var _min_d = 999999;
            for (var s = 0; s < array_length(_seeds); s++) {
                var _d = point_distance(_fx, _fy, _seeds[s].x, _seeds[s].y);
                if (_d < _min_d) _min_d = _d;
            }
            if (_min_d > _far_min_d) { _far_min_d = _min_d; _far_i = i; }
        }
        var _sx = _floor_x[_far_i], _sy = _floor_y[_far_i];
        var _d0 = point_distance(_seeds[0].x, _seeds[0].y, _sx, _sy);
        array_push(_seeds, { x: _sx, y: _sy, dist: _d0 });
    }

    // Ordena sementes da extremidade inicial ate a oposta (garante sequencia A -> B -> C ou A -> B -> A)
    array_sort(_seeds, function(_a, _b) { return _a.dist - _b.dist; });

    // Inicializa filas de expansao (1 por zona)
    var _queues = array_create(_n_zones);
    var _heads  = array_create(_n_zones, 0);
    for (var z = 0; z < _n_zones; z++) {
        var _sx = _seeds[z].x, _sy = _seeds[z].y;
        biome_grid[# _sx, _sy] = _zone_biomes[z];
        _queues[z] = [[_sx, _sy]];
    }

    // Expansao simultanea pelos corredores (BFS organico: 1 a 2 passos por ciclo por zona)
    var _dirs   = [[1,0], [-1,0], [0,1], [0,-1]];
    var _active = true;

    while (_active) {
        _active = false;
        for (var z = 0; z < _n_zones; z++) {
            var _q = _queues[z];
            var _budget = irandom_range(1, 2);

            while (_budget > 0 && _heads[z] < array_length(_q)) {
                _active = true;
                var _pos = _q[_heads[z]];
                _heads[z]++;
                _budget--;

                var _order = array_shuffle([0, 1, 2, 3]);
                for (var k = 0; k < 4; k++) {
                    var _d  = _dirs[_order[k]];
                    var _nx = _pos[0] + _d[0];
                    var _ny = _pos[1] + _d[1];

                    if (_nx >= 0 && _nx < _gw && _ny >= 0 && _ny < _gh &&
                        grid[# _nx, _ny] == CELL_FLOOR && biome_grid[# _nx, _ny] == -1) {
                        biome_grid[# _nx, _ny] = _zone_biomes[z];
                        array_push(_q, [_nx, _ny]);
                    }
                }
            }
        }
    }

    // Fallback de seguranca + limpeza de pontas isoladas de 1 celula nas fronteiras
    for (var i = 0; i < _n_floors; i++) {
        var _fx = _floor_x[i], _fy = _floor_y[i];
        if (biome_grid[# _fx, _fy] == -1) biome_grid[# _fx, _fy] = _zone_biomes[0];
    }

    for (var i = 0; i < _n_floors; i++) {
        var _fx = _floor_x[i], _fy = _floor_y[i];
        var _cur = biome_grid[# _fx, _fy];
        var _votes = [0, 0, 0];

        for (var d = 0; d < 4; d++) {
            var _nx = _fx + _dirs[d][0], _ny = _fy + _dirs[d][1];
            if (_nx >= 0 && _nx < _gw && _ny >= 0 && _ny < _gh && grid[# _nx, _ny] == CELL_FLOOR) {
                var _nb = biome_grid[# _nx, _ny];
                if (_nb >= 0 && _nb < 3) _votes[_nb]++;
            }
        }
        // Se 3 ou 4 vizinhos sao de outro bioma, absorve a ponta para limpar a fronteira
        for (var b = 0; b < 3; b++) {
            if (b != _cur && _votes[b] >= 3) {
                biome_grid[# _fx, _fy] = b;
                break;
            }
        }
    }
}

// Instancia inimigos compativeis com o bioma de cada celula (Contexto: Obj_Builder)
// Coleta e embaralha todas as celulas livres separadas por bioma (compartilhada entre inimigos e props)
function dungeon_collect_free_cells(_start_x, _start_y, _exit_x, _exit_y) {
    var _gw = ds_grid_width(grid), _gh = ds_grid_height(grid);
    var _cells_by_biome = [[], [], []]; // 0: SEWER, 1: CAVE, 2: DUNGEON

    for (var _yy = 0; _yy < _gh; _yy++) {
        for (var _xx = 0; _xx < _gw; _xx++) {
            if (grid[# _xx, _yy] == CELL_FLOOR &&
                point_distance(_xx, _yy, _start_x, _start_y) > 4 &&
                (_xx != _exit_x || _yy != _exit_y)) {
                array_push(_cells_by_biome[biome_grid[# _xx, _yy]], { x: _xx, y: _yy });
            }
        }
    }
    for (var b = 0; b < 3; b++) _cells_by_biome[b] = array_shuffle(_cells_by_biome[b]);
    return _cells_by_biome;
}

// Popula inimigos obedecendo allowed_biomes, spawn_min, spawn_max e spawn_chance
function dungeon_spawn_enemies(_cells_by_biome) {
    if (!variable_global_exists("enemies")) init_enemies();
    yesterday_load();

    var _total = 0;
    show_debug_message("=== [DUNGEON SPAWN: INIMIGOS] ===");

    for (var e = 0; e < array_length(global.enemies); e++) {
        var _ed = global.enemies[e];
        if (_ed == undefined || !variable_struct_exists(_ed, "allowed_biomes")) continue;

        if (e == ENEMY.ME && !yesterday_has_ghost()) {
            show_debug_message("  " + _ed.name + ": 0 (sem morto salvo)");
            continue;
        }

        var _max    = max(0, _ed[$ "spawn_max"] ?? _ed[$ "spawwn_max"] ?? 0);
        var _min    = clamp(_ed[$ "spawn_min"] ?? 0, 0, _max);
        var _chance = clamp(_ed[$ "spawn_chance"] ?? 0, 0, 100);

        var _target = _min;
        for (var k = _min; k < _max; k++) {
            if (_chance >= 100 || (_chance > 0 && random(100) < _chance)) _target++;
        }

        var _spawned = 0;
        for (var n = 0; n < _target; n++) {
            var _avail = [];
            for (var i = 0; i < array_length(_ed.allowed_biomes); i++) {
                var _bi = _ed.allowed_biomes[i];
                if (_bi >= 0 && _bi < 3 && array_length(_cells_by_biome[_bi]) > 0) array_push(_avail, _bi);
            }
            if (array_length(_avail) == 0) break;

            var _cell = array_pop(_cells_by_biome[_avail[irandom(array_length(_avail) - 1)]]);
            var _inst = instance_create_layer(_cell.x * cell_width + 32, _cell.y * cell_height + 32, "Instances", Obj_Enemy, { enemy_type: e });
            _inst.depth = -10;
            _spawned++;
            _total++;
        }
        show_debug_message("  " + _ed.name + ": " + string(_spawned));
    }
    show_debug_message("=== TOTAL INIMIGOS: " + string(_total) + " ===");
}

// Popula itens de cenario (Baus e Corpos) usando o mesmo pool exclusivo de celulas livres
function dungeon_spawn_props(_cells_by_biome) {
    if (!variable_global_exists("props")) init_props();

    var _total = 0;
    show_debug_message("=== [DUNGEON SPAWN: CENARIO] ===");

    for (var p = 0; p < array_length(global.props); p++) {
        var _pd = global.props[p];
        if (_pd == undefined || !variable_struct_exists(_pd, "allowed_biomes")) continue;

        var _max    = max(0, _pd[$ "spawn_max"] ?? 0);
        var _min    = clamp(_pd[$ "spawn_min"] ?? 0, 0, _max);
        var _chance = clamp(_pd[$ "spawn_chance"] ?? 0, 0, 100);

        var _target = _min;
        for (var k = _min; k < _max; k++) {
            if (_chance >= 100 || (_chance > 0 && random(100) < _chance)) _target++;
        }

        var _spawned = 0;
        for (var n = 0; n < _target; n++) {
            var _avail = [];
            for (var i = 0; i < array_length(_pd.allowed_biomes); i++) {
                var _bi = _pd.allowed_biomes[i];
                if (_bi >= 0 && _bi < 3 && array_length(_cells_by_biome[_bi]) > 0) array_push(_avail, _bi);
            }
            if (array_length(_avail) == 0) break;

            var _cell = array_pop(_cells_by_biome[_avail[irandom(array_length(_avail) - 1)]]);
            var _inst = instance_create_layer(_cell.x * cell_width + 32, _cell.y * cell_height + 32, "Instances", Obj_Prop, { prop_type: p });
            _inst.depth = -10;
            _spawned++;
            _total++;
        }
        show_debug_message("  " + _pd.name + ": " + string(_spawned) + " (min:" + string(_min) + " max:" + string(_max) + " chance:" + string(_chance) + "%)");
    }
    show_debug_message("=== TOTAL CENARIO: " + string(_total) + " ===");
}