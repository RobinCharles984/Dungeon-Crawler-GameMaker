// --- ESTADOS DA HUD ---
enum HUD_STATE {
    EXPLORE,
    COMBAT,
    INVENTORY
}

bg_explore   = Spr_Explore_Background;
bg_combat    = Spr_Battle_Background;
bg_inventory = Spr_Inventory_Background;

hud_state          = HUD_STATE.EXPLORE;
previous_hud_state = HUD_STATE.EXPLORE;
return_state       = HUD_STATE.EXPLORE;

is_animating  = false;
anim_progress = 1;
anim_speed    = 0.05;

// --- INVENTÁRIO (Matriz 4x4 Alinhada ao Sprite) ---
inv_cols = 8;
inv_rows = 3;
inv_grid = array_create(inv_cols * inv_rows, undefined);

// -------------------------------------------------------------
// AJUSTE ESTES VALORES PARA ENCAIXAR PERFEITAMENTE NO SEU SPRITE:
// -------------------------------------------------------------
inv_offset_x     = 140; // Distância da borda esquerda do HUD até a 1ª coluna
inv_offset_y     = 35;  // Distância do topo do HUD até a 1ª linha
inv_cell_w       = 115; // Largura de cada célula no seu sprite
inv_cell_h       = 52;  // Altura de cada célula no seu sprite
inv_space_x      = 12;  // Espaço horizontal entre células
inv_space_y      = 10;  // Espaço vertical entre células
inv_draw_slot_bg = false; // 'false' esconde os blocos pretos e usa o fundo do seu Sprite!

// Itens de Teste
inv_grid[0] = { name: "Poção de Vida", sprite: Spr_Player, desc: "Recupera 50 HP.", type: "use" };
inv_grid[1] = { name: "Espada de Ferro", sprite: Spr_Player, desc: "Aumenta o Ataque em +5.", type: "equip" };

drag_slot         = -1;
selected_slot     = -1;
show_item_options = false;
show_skill_wheel  = false;

function change_hud_state(_new_state) {
    if (hud_state == _new_state || is_animating) exit;
    if (_new_state == HUD_STATE.INVENTORY) return_state = hud_state;
    
    previous_hud_state = hud_state;
    hud_state          = _new_state;
    anim_progress      = 0;
    is_animating       = true;
    show_item_options  = false;
    show_skill_wheel   = false;
}

function ease_out_cubic(t) {
    t = clamp(t, 0, 1);
    return 1 - power(1 - t, 3);
}


// -------------------------------------------------------------
// FUNÇÃO AUXILIAR: DESENHA BOTÕES CUSTOMIZADOS E LEGÍVEIS
// -------------------------------------------------------------
draw_ui_button = function(_bx1, _by1, _bx2, _by2, _text, _bg_col, _txt_col) {
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    var _hover = point_in_rectangle(_mx, _my, _bx1, _by1, _bx2, _by2);
    var _color = _hover ? merge_color(_bg_col, c_white, 0.25) : _bg_col;
    
    // Fundo do Botão
    draw_rectangle_color(_bx1, _by1, _bx2, _by2, _color, _color, c_black, c_black, false);
    // Borda
    draw_rectangle_color(_bx1, _by1, _bx2, _by2, c_white, c_white, c_white, c_white, true);
    
    // Texto Centralizado
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_color((_bx1 + _bx2) / 2, (_by1 + _by2) / 2, _text, _txt_col, _txt_col, _txt_col, _txt_col, 1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    
    return (_hover && mouse_check_button_pressed(mb_left));
};

if (!variable_global_exists("active_enemy")) {
    global.active_enemy = noone;
}