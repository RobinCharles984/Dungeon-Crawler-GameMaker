// Initialize the player
z = 24;
dir = 0;

// Create target variables for movement
target_dir = dir;
target_x = x;
target_y = y;

// Set the default color to white
draw_set_color(c_white);

//Start 3D drawing
d3d_start();

// Set the fog
current_fog_color = make_color_rgb(27, 3, 59)
current_fog_start = 32;
current_fog_end   = 256;