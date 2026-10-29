// Draw the projection
var vect_x = lengthdir_x(32, dir);
var vect_y = lengthdir_y(32, dir);

// Set the projection
d3d_set_projection(x, y, z, x+vect_x, y+vect_y, z, 0, 0, 1);