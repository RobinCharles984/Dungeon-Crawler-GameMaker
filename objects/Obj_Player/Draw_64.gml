var _height = display_get_gui_height();
var _width = display_get_gui_width();

var _sprite_w = _width / 1.15;
var _sprite_h = _height / 3; // Defina a altura desejada aqui (ex: metade da tela)

// O X correto divide a sobra da tela por 2
var _x = (_width - _sprite_w) / 2;

// O Y correto faz a base do sprite encostar no fundo da tela
var _y = _height - _sprite_h;

draw_sprite_stretched(Spr_Cave_Ceiling, 0, _x, _y, _sprite_w, _sprite_h);

d3d_set_fog(false, c_black, 1, 10)

depth = 0