/// Evento Step de Obj_Battle

if (state == BATTLE_STATE.ENEMY_TURN) {
    if (!instance_exists(Obj_Player)) exit;
    var _p = Obj_Player.stats;

    enemy_defending = false;

    // IA Simples do Inimigo: 70% Atacar, 30% Defender
    var _choice = random(100);

    if (_choice < 70) {
        // Ataque do Inimigo
        var _res = calc_damage(enemy_attack, _p.defense, enemy_crit_chance, enemy_crit_rate, player_defending);
        _p.life = max(0, _p.life - _res.damage);

        var _msg = enemy_name + " atacou e causou " + string(_res.damage) + " de dano!";
        if (_res.is_crit) _msg += " (CRÍTICO!)";
        add_log(_msg);
    } else {
        // Defesa do Inimigo
        enemy_defending = true;
        add_log(enemy_name + " está em guarda!");
    }

    // Checa se o Jogador Morreu
    if (_p.life <= 0) {
        state = BATTLE_STATE.DEFEAT;
        add_log("--- VOCÊ FOI DERROTADO! ---");
    } else {
        state = BATTLE_STATE.PLAYER_TURN;
    }
}