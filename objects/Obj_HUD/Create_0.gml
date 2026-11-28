/// Create_0.gml de Obj_HUD
bg_explore   = Spr_Explore_Background;
bg_combat    = Spr_Battle_Background;
bg_inventory = Spr_Inventory_Background;

hud_state          = HUD_STATE.EXPLORE;
previous_hud_state = HUD_STATE.EXPLORE;
return_state       = HUD_STATE.EXPLORE;
is_animating       = false;
anim_progress      = 1;
anim_speed         = 0.05;

// Gaveta minimizavel (comeca minimizada em 8% da altura)
is_minimized          = true;
was_minimized_pre_inv = true;
min_progress          = 1;
min_speed             = 6.0;
min_peek_ratio        = 0.08;

// Matriz 8x3 mapeada em coordenadas normalizadas (0..1) do Spr_Inventory_Background
inv_cols       = 8;
inv_rows       = 3;
inv_grid       = array_create(inv_cols * inv_rows, undefined);
inv_col_bounds = [0.025, 0.157, 0.289, 0.398, 0.518, 0.648, 0.786, 0.892, 0.978];
inv_row_bounds = [0.040, 0.340, 0.660, 0.960];

drag_slot         = -1;
selected_slot     = -1;
show_item_options = false;
show_skill_wheel  = false;
hover_tooltip     = undefined; // Tooltip desenhado por cima de tudo
reading_file      = undefined; // Arquivo de lore aberto para leitura

// Itens iniciais de teste usando items.gml
nearby_prop    = noone;
toast_messages = [];

if (!variable_global_exists("items")) init_items();
inv_grid[0] = global.items[$ "pot_heal_small"];
inv_grid[1] = global.items[$ "sword_iron"];
inv_grid[2] = global.items[$ "armor_leather"];
inv_grid[3] = global.items[$ "ring_crit"];
inv_grid[4] = global.items[$ "key_chest"];
inv_grid[5] = global.items[$ "key_special"];
inv_grid[6] = global.items[$ "pot_fume"];

if (!variable_global_exists("active_enemy")) global.active_enemy = noone;