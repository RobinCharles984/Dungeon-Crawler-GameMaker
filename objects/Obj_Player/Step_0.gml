/// Step_0.gml
// Atalhos globais de debug
if (keyboard_check_pressed(ord("R"))) room_restart();
if (keyboard_check_pressed(ord("M"))) global.show_minimap = !global.show_minimap;

// Fuga tem prioridade sobre controles
if (player_update_flee()) exit;

// Trava movimentacao fora do modo de exploracao
if (instance_exists(Obj_HUD) && Obj_HUD.hud_state != HUD_STATE.EXPLORE) exit;

player_handle_movement();
player_update_fog();