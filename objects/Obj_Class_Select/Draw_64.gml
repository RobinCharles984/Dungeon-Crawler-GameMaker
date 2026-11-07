var _w = display_get_gui_width();
var _h = display_get_gui_height();
var _c = global.classes[selected];

draw_set_color(c_white);
draw_set_halign(fa_center);
draw_set_valign(fa_top);

// Título e seletor
draw_text(_w / 2, 20, "ESCOLHA SUA CLASSE");
draw_text(_w / 2, 60, "<  " + _c.name + "  >");

// Descrição
draw_text_ext(_w / 2, 100, _c.description, 20, _w * 0.8);
draw_text(_w / 2, 190, "Melhor com: " + _c.best_with);

// Stats (coluna esquerda) e skills (coluna direita)
draw_set_halign(fa_left);
var _lx = _w * 0.15;
var _rx = _w * 0.5;
var _y  = 240;

draw_text(_lx, _y,       "HP: " + string(_c.life));
draw_text(_lx, _y + 24,  "MP: " + string(_c.mp));
draw_text(_lx, _y + 48,  "Attack: " + string(_c.attack));
draw_text(_lx, _y + 72,  "Defense: " + string(_c.defense));
draw_text(_lx, _y + 96,  "Magic: " + string(_c.magic));
draw_text(_lx, _y + 120, "Crit: " + string(_c.crit_chance) + "% (x" + string(_c.crit_rate) + "%)");
draw_text(_lx, _y + 144, "Chance de Mantra: " + string(_c.mantra_chance) + "%");

draw_text(_rx, _y, "Skills:");
for (var i = 0; i < array_length(_c.skills); i++) {
    var _s = _c.skills[i];
    draw_text_ext(_rx, _y + 24 + i * 48, _s.name + " (" + string(_s.mp) + " MP): " + _s.desc, 18, _w * 0.4);
}

// Nome
draw_set_halign(fa_center);
draw_text(_w / 2, _h - 100, "Nome: " + player_name + ((current_time div 500) mod 2 ? "_" : ""));
draw_text(_w / 2, _h - 60, "Enter para começar");

// Reset (outros objetos assumem o padrão)
draw_set_halign(fa_left);
