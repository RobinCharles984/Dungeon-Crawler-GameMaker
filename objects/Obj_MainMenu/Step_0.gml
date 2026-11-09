/// Evento Step de Obj_MainMenu

if (menu_state == MENU_STATE.CHAR_SELECT && typing_name) {
    // Captura os caracteres digitados no teclado
    if (string_length(keyboard_string) <= 12) {
        input_name = keyboard_string;
    } else {
        keyboard_string = input_name;
    }

    // Pressionar ENTER confirma o nome
    if (keyboard_check_pressed(vk_enter)) {
        typing_name = false;
    }
}/// Evento Step de Obj_MainMenu

if (menu_state == MENU_STATE.CHAR_SELECT && typing_name) {
    // Captura os caracteres digitados no teclado
    if (string_length(keyboard_string) <= 12) {
        input_name = keyboard_string;
    } else {
        keyboard_string = input_name;
    }

    // Pressionar ENTER confirma o nome
    if (keyboard_check_pressed(vk_enter)) {
        typing_name = false;
    }
}