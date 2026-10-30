// Draw the projection
dir = lerp(dir, target_dir, .1);
x = lerp(x, target_x, .1);
y = lerp(y, target_y, .1);

var vect_x = lengthdir_x(64, dir);
var vect_y = lengthdir_y(64, dir);

// Set the projection
d3d_set_projection(x, y, z, x+vect_x, y+vect_y, z, 0, 0, -1);

// Fog
d3d_set_fog(true, current_fog_color, current_fog_start, current_fog_end)