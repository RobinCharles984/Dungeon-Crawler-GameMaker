var _n = array_length(global.classes);

// Trocar de classe
if (keyboard_check_pressed(vk_right)) selected = (selected + 1) mod _n;
if (keyboard_check_pressed(vk_left))  selected = (selected - 1 + _n) mod _n;

// Nome (keyboard_string acumula o que o jogador digita)
if (string_length(keyboard_string) > name_max) {
    keyboard_string = string_copy(keyboard_string, 1, name_max);
}
player_name = keyboard_string;

// Confirmar: precisa ter pelo menos 1 caractere que não seja espaço
var _name_ok = string_length(string_replace_all(player_name, " ", "")) > 0;
if (keyboard_check_pressed(vk_enter) && _name_ok) {
    global.player = create_player(selected, player_name);  // sorteia o Mantra aqui
    room_goto(Room_3D);
}
