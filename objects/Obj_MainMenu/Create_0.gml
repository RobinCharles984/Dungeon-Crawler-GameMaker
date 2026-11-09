// --- ESTADOS DO MENU ---
enum MENU_STATE {
    MAIN,
    CHAR_SELECT,
    CONFIG
}

menu_state = MENU_STATE.MAIN;

// --- CONFIGURAÇÕES GLOBAIS (Persistentes) ---
if (!variable_global_exists("vol_music"))   global.vol_music   = 80; // 0 a 100
if (!variable_global_exists("vol_sfx"))     global.vol_sfx     = 80; // 0 a 100
if (!variable_global_exists("brightness"))  global.brightness  = 100; // 0 a 200 (100 = Normal)

// Ajusta o ganho mestre de áudio com base nos valores
audio_master_gain(global.vol_music / 100);

// --- CRIAÇÃO DE PERSONAGEM ---
input_name = "Condenado";
typing_name = false;

// Definição das classes disponíveis para seleção
classes_list = [
    { id: "warrior", name: "Agressivo", portrait: Spr_Portrait_Agressive, desc: "Melhor com armas brancas." },
	{ id: "rogue",   name: "Lançador",    portrait: Spr_Portrait_Thrower, desc: "Melhor com armas de longo alcance e arremessáveis." },
    { id: "mage",    name: "Invocador",      portrait: Spr_Portrait_Summoner, desc: "Melhor com equipamentos mágicos." }
];

selected_class_idx = 0;

// --- MÉTODO AUXILIAR DE BOTÕES LEGÍVEIS ---
draw_ui_button = function(_bx1, _by1, _bx2, _by2, _text, _bg_col, _txt_col) {
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    var _hover = point_in_rectangle(_mx, _my, _bx1, _by1, _bx2, _by2);
    var _color = _hover ? merge_color(_bg_col, c_white, 0.25) : _bg_col;
    
    draw_rectangle_color(_bx1, _by1, _bx2, _by2, _color, _color, c_black, c_black, false);
    draw_rectangle_color(_bx1, _by1, _bx2, _by2, c_white, c_white, c_white, c_white, true);
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_color((_bx1 + _bx2) / 2, (_by1 + _by2) / 2, _text, _txt_col, _txt_col, _txt_col, _txt_col, 1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    
    return (_hover && mouse_check_button_pressed(mb_left));
};