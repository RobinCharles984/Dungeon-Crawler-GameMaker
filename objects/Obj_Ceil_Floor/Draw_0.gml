/// Draw the ceiling and floor
//d3d_draw_floor(0, 0, 32, room_width, room_height, 32, ceil_tex, hrep, vrep);

//d3d_draw_floor(0, 0, 0, room_width, room_height, 0, floor_tex, hrep, vrep);

if (!instance_exists(builder_ref)) exit;

var _grid       = builder_ref.grid;
var _biome_grid = builder_ref.biome_grid;
var _cw         = builder_ref.cell_width;
var _ch         = builder_ref.cell_height;

var _w = ds_grid_width(_grid);
var _h = ds_grid_height(_grid);

for (var _gy = 0; _gy < _h; _gy++) {
    for (var _gx = 0; _gx < _w; _gx++) {
        // Desenha chão e teto em posições que são chão (CELL_FLOOR)
        if (_grid[# _gx, _gy] == builder_ref.CELL_FLOOR) {
            var _b = _biome_grid[# _gx, _gy];
            var _f_tex = global.biomes[_b].floor_tex;
            var _c_tex = global.biomes[_b].ceil_tex;

            var _x1 = _gx * _cw;
            var _y1 = _gy * _ch;
            var _x2 = _x1 + _cw;
            var _y2 = _y1 + _ch;

            // Chão no Z = 0
            d3d_draw_floor(_x1, _y1, 0, _x2, _y2, 0, _f_tex, 1, 1);
            
            // Teto no Z = 64
            d3d_draw_floor(_x1, _y1, _cw, _x2, _y2, _cw, _c_tex, 1, 1);
        }
    }
}