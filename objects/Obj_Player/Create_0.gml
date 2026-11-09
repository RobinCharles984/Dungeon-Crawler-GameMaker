// Initialize the player
z = 24;
dir = 0;
depth = 0

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

// Inicializa o banco de classes caso ainda não tenha sido rodado
init_classes();

// Cria os dados do jogador (Aqui você passa a classe escolhida e o nome)
var _start_name  = variable_global_exists("player_start_name") ? global.player_start_name : "Herói";
var _start_class = variable_global_exists("player_start_class") ? global.player_start_class : 0; // Padrão: 0 (Guerreiro)

// Cria a struct de stats do jogador com a classe e nome escolhidos no Menu Principal
stats = create_player(_start_class, _start_name);

// Fugir
// Variáveis do Estado de Fuga / Recuo
is_fleeing     = false;
flee_target_x = x;
flee_target_y = y;
flee_speed    = 4; // Velocidade do deslizamento de recuo

global.show_minimap = false;