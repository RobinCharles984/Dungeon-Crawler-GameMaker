// Gira a câmera
if (keyboard_check(vk_left)) dir += 3;
if (keyboard_check(vk_right)) dir -= 3;

// Anda pra frente e pra trás
if (keyboard_check(vk_up)) {
    x += dcos(dir) * 2;
    y -= dsin(dir) * 2;
}
if (keyboard_check(vk_down)) {
    x -= dcos(dir) * 2;
    y += dsin(dir) * 2;
}