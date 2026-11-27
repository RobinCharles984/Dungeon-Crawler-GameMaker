// Inicializa estado de VFX dentro da instancia de Obj_Battle
function battle_vfx_init() {
    vfx_texts        = []; // Array de textos flutuantes ativos
    vfx_player_flash = 0;  // Tempo restante do piscar de dano do jogador (s)
    vfx_shake_timer  = 0;  // Tempo restante do tremor da UI (s)
    vfx_shake_mag    = 0;  // Intensidade do tremor em pixels
}

// Dispara flash vermelho + tremor quando o jogador leva dano
function battle_vfx_trigger_player_hit(_b, _is_crit = false) {
    with (_b) {
        vfx_player_flash = 0.45;
        vfx_shake_timer  = _is_crit ? 0.28 : 0.18;
        vfx_shake_mag    = _is_crit ? 10 : 6;
    }
}

// Cria um texto de dano/status com impacto e duracao de 0.5s
// _target: "enemy" (centro da tela 3D) ou "player" (area do retrato/HUD)
function battle_vfx_spawn_text(_b, _text, _col, _target = "enemy", _is_crit = false) {
    var _lay = hud_get_layout();
    var _x   = (_target == "enemy") ? (_lay.sw * 0.5) : (_lay.px + _lay.pw * 0.55);
    var _y   = (_target == "enemy") ? (_lay.sh * 0.34) : (_lay.py + 35);

    array_push(_b.vfx_texts, {
        text:        _text,
        col:         _col,
        x:           _x + irandom_range(-28, 28), // Deslocamento evita sobreposicao em combos
        y:           _y + irandom_range(-10, 10),
        vy:          _is_crit ? -150 : -115,      // Impulso inicial para cima (px/s)
        timer:       0,
        duration:    0.5,                         // Meio segundo exato
        scale_base:  _is_crit ? 1.85 : 1.35,
        scale_start: _is_crit ? 3.20 : 2.35       // Overshoot do efeito de impacto
    });
}

// Atualiza todos os VFX de combate (chamado no battle_step)
function battle_vfx_step(_b, _dt) {
    with (_b) {
        if (vfx_player_flash > 0) vfx_player_flash = max(0, vfx_player_flash - _dt);
        if (vfx_shake_timer  > 0) vfx_shake_timer  = max(0, vfx_shake_timer  - _dt);

        for (var i = array_length(vfx_texts) - 1; i >= 0; i--) {
            var _f = vfx_texts[i];
            _f.timer += _dt;
            _f.y     += _f.vy * _dt;
            _f.vy    *= power(0.06, _dt); // Desaceleracao suave

            if (_f.timer >= _f.duration) array_delete(vfx_texts, i, 1);
        }
    }
}

// Retorna true nos frames em que o retrato do jogador deve piscar em vermelho
function battle_vfx_player_is_blinking(_b) {
    return (_b.vfx_player_flash > 0) && (floor(_b.vfx_player_flash * 22) mod 2 == 1);
}

// Retorna offset {x, y} do tremor atual
function battle_vfx_get_shake(_b) {
    if (_b.vfx_shake_timer <= 0) return { x: 0, y: 0 };
    var _m = _b.vfx_shake_mag * (_b.vfx_shake_timer / 0.25);
    return { x: random_range(-_m, _m), y: random_range(-_m, _m) };
}

// Desenha vinheta de dano do jogador e textos flutuantes (chamado no Draw GUI)
function battle_vfx_draw(_b) {
    var _sw = display_get_gui_width();
    var _sh = display_get_gui_height();

    // 1. Flash vermelho nas bordas da tela quando o jogador leva dano
    if (_b.vfx_player_flash > 0) {
        var _a = (_b.vfx_player_flash / 0.45) * 0.35;
        if (battle_vfx_player_is_blinking(_b)) _a *= 1.4;
        draw_set_alpha(clamp(_a, 0, 0.55));
        draw_rectangle_color(0, 0, _sw, _sh, c_red, c_red, c_maroon, c_maroon, false);
        draw_set_alpha(1.0);
    }

    // 2. Textos flutuantes com impacto + contorno preto + fade out em 0.5s
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    for (var i = 0; i < array_length(_b.vfx_texts); i++) {
        var _f = _b.vfx_texts[i];
        var _t = clamp(_f.timer / _f.duration, 0, 1);

        // Efeito de impacto nos primeiros 25% do tempo (escala grande -> normal)
        var _sc = (_t < 0.25)
            ? lerp(_f.scale_start, _f.scale_base, ease_out_cubic(_t / 0.25))
            : _f.scale_base;

        // Fade suave ate 0 em 0.5s
        var _alpha = clamp(1 - power(_t, 1.4), 0, 1);

        // Contorno preto para leitura limpa sobre o 3D
        draw_text_transformed_color(_f.x + 2, _f.y + 2, _f.text, _sc, _sc, 0, c_black, c_black, c_black, c_black, _alpha);
        draw_text_transformed_color(_f.x - 1, _f.y - 1, _f.text, _sc, _sc, 0, c_black, c_black, c_black, c_black, _alpha);
        // Texto principal
        draw_text_transformed_color(_f.x, _f.y, _f.text, _sc, _sc, 0, _f.col, _f.col, _f.col, _f.col, _alpha);
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}