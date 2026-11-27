/// Create_0.gml
z = 24;
dir = 0;
depth = 0;
target_dir = dir;
target_x   = x;
target_y   = y;

draw_set_color(c_white);
d3d_start();

// Fog inicial
current_fog_color = make_color_rgb(27, 3, 59);
current_fog_start = 32;
current_fog_end   = 256;

// Stats pela classe escolhida no menu
init_classes();
var _name  = variable_global_exists("player_start_name")  ? global.player_start_name  : "Heroi";
var _class = variable_global_exists("player_start_class") ? global.player_start_class : 0;
stats      = create_player(_class, _name);

// Estado de fuga e minimapa
is_fleeing    = false;
flee_target_x = x;
flee_target_y = y;
flee_speed    = 4;
global.show_minimap = false;