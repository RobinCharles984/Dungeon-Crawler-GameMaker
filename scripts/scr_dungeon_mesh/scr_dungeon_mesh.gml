// Formato de vertice compartilhado entre paredes, chao e teto
function dungeon_get_vertex_format() {
    static _fmt = undefined;
    if (_fmt == undefined) {
        vertex_format_begin();
        vertex_format_add_position_3d();
        vertex_format_add_color();
        vertex_format_add_texcoord();
        _fmt = vertex_format_end();
    }
    return _fmt;
}

// Helper interno: grava 1 quad (2 triangulos) no vertex buffer
function dungeon_add_quad(_vb, _x1,_y1,_z1, _x2,_y2,_z2, _x3,_y3,_z3, _x4,_y4,_z4) {
    vertex_position_3d(_vb, _x1, _y1, _z1); vertex_color(_vb, c_white, 1); vertex_texcoord(_vb, 0, 0);
    vertex_position_3d(_vb, _x2, _y2, _z2); vertex_color(_vb, c_white, 1); vertex_texcoord(_vb, 1, 0);
    vertex_position_3d(_vb, _x3, _y3, _z3); vertex_color(_vb, c_white, 1); vertex_texcoord(_vb, 1, 1);

    vertex_position_3d(_vb, _x1, _y1, _z1); vertex_color(_vb, c_white, 1); vertex_texcoord(_vb, 0, 0);
    vertex_position_3d(_vb, _x3, _y3, _z3); vertex_color(_vb, c_white, 1); vertex_texcoord(_vb, 1, 1);
    vertex_position_3d(_vb, _x4, _y4, _z4); vertex_color(_vb, c_white, 1); vertex_texcoord(_vb, 0, 1);
}

// Cria e congela 3 buffers de parede (1 por bioma)
function dungeon_build_wall_buffers(_builder) {
    var _fmt = dungeon_get_vertex_format();
    var _bufs = [vertex_create_buffer(), vertex_create_buffer(), vertex_create_buffer()];
    for (var b = 0; b < 3; b++) vertex_begin(_bufs[b], _fmt);

    var _gw = ds_grid_width(_builder.grid), _gh = ds_grid_height(_builder.grid);
    var _cw = _builder.cell_width, _ch = _builder.cell_height;

    for (var _yy = 0; _yy < _gh; _yy++) {
        for (var _xx = 0; _xx < _gw; _xx++) {
            if (_builder.grid[# _xx, _yy] != _builder.CELL_WALL) continue;

            var _v  = _bufs[_builder.biome_grid[# _xx, _yy]];
            var _x1 = _xx * _cw, _y1 = _yy * _ch;
            var _x2 = _x1 + _cw, _y2 = _y1 + _ch;

            // 4 faces verticais do bloco
            dungeon_add_quad(_v, _x1,_y1,64, _x2,_y1,64, _x2,_y1,0, _x1,_y1,0);
            dungeon_add_quad(_v, _x2,_y2,64, _x1,_y2,64, _x1,_y2,0, _x2,_y2,0);
            dungeon_add_quad(_v, _x1,_y2,64, _x1,_y1,64, _x1,_y1,0, _x1,_y2,0);
            dungeon_add_quad(_v, _x2,_y1,64, _x2,_y2,64, _x2,_y2,0, _x2,_y1,0);
        }
    }

    for (var b = 0; b < 3; b++) {
        vertex_end(_bufs[b]);
        if (vertex_get_number(_bufs[b]) > 0) vertex_freeze(_bufs[b]);
    }
    return _bufs;
}

// Cria e congela buffers de chao e teto (1 por bioma cada)
function dungeon_build_floor_ceil_buffers(_builder) {
    var _fmt   = dungeon_get_vertex_format();
    var _floor = [vertex_create_buffer(), vertex_create_buffer(), vertex_create_buffer()];
    var _ceil  = [vertex_create_buffer(), vertex_create_buffer(), vertex_create_buffer()];

    for (var b = 0; b < 3; b++) {
        vertex_begin(_floor[b], _fmt);
        vertex_begin(_ceil[b],  _fmt);
    }

    var _gw = ds_grid_width(_builder.grid), _gh = ds_grid_height(_builder.grid);
    var _cw = _builder.cell_width, _ch = _builder.cell_height;

    for (var _yy = 0; _yy < _gh; _yy++) {
        for (var _xx = 0; _xx < _gw; _xx++) {
            if (_builder.grid[# _xx, _yy] != _builder.CELL_FLOOR) continue;

            var _b  = _builder.biome_grid[# _xx, _yy];
            var _x1 = _xx * _cw, _y1 = _yy * _ch;
            var _x2 = _x1 + _cw, _y2 = _y1 + _ch;

            dungeon_add_quad(_floor[_b], _x1,_y1,0,   _x2,_y1,0,   _x2,_y2,0,   _x1,_y2,0);
            dungeon_add_quad(_ceil[_b],  _x1,_y1,_cw, _x2,_y1,_cw, _x2,_y2,_cw, _x1,_y2,_cw);
        }
    }

    for (var b = 0; b < 3; b++) {
        vertex_end(_floor[b]);
        if (vertex_get_number(_floor[b]) > 0) vertex_freeze(_floor[b]);

        vertex_end(_ceil[b]);
        if (vertex_get_number(_ceil[b]) > 0) vertex_freeze(_ceil[b]);
    }
    return { floor_vbuf: _floor, ceil_vbuf: _ceil };
}

// Submete um array de 3 buffers usando a chave de textura de global.biomes ("wall_tex", "floor_tex", "ceil_tex")
function dungeon_submit_biome_buffers(_bufs, _tex_key) {
    gpu_set_ztestenable(true);
    gpu_set_zwriteenable(true);
    gpu_set_cullmode(cull_noculling);

    for (var b = 0; b < 3; b++) {
        if (vertex_get_number(_bufs[b]) > 0) {
            vertex_submit(_bufs[b], pr_trianglelist, global.biomes[b][$ _tex_key]);
        }
    }
}

// Libera array de buffers da VRAM (chamado no CleanUp)
function dungeon_free_buffers(_bufs) {
    if (!is_array(_bufs)) exit;
    for (var b = 0; b < array_length(_bufs); b++) {
        if (_bufs[b] != undefined) vertex_delete_buffer(_bufs[b]);
    }
}