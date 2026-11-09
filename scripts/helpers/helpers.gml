/// @desc Desacelera suavemente no final (Excelente para placas de UI)
function ease_out_cubic(t) {
    t = clamp(t, 0, 1);
    return 1 - power(1 - t, 3);
}

/// @desc Acelera no início e desacelera no final (Curva em S clássica)
function smoothstep(t) {
    t = clamp(t, 0, 1);
    return t * t * (3 - 2 * t);
}