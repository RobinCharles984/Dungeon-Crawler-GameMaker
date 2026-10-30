/// Draw the wall
var _tex = global.biomes[biome_type].wall_tex;
d3d_draw_block(x, y, 0, x+wall_w, y+wall_h, wall_w, _tex, 1, 1);