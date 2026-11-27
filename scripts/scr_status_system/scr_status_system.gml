// =====================================================================
// SISTEMA DE ESTADOS (DoTs) E PRECISAO GLOBAL
// =====================================================================
#macro BATTLE_BASE_MISS_CHANCE       10 // Chance padrao de errar golpes (%)
#macro BATTLE_DISORIENTED_MISS_BONUS 45 // Soma de erro quando Desnorteado (%)

enum STATUS {
    BURN,        // Incendio: dano alto em poucos rounds (fim do round)
    FROZEN,      // Congelado: dano sempre que fizer uma acao
    STUN,        // Nocauteado: sem acao por X rounds
    BLEED,       // Sangramento: dano menor em mais rounds (fim do round)
    DISORIENTED, // Desnorteado: aumenta chance de errar golpes
    COUNT
}

// Cria tabela de estados zerada (usada tanto no jogador quanto no inimigo)
function status_create_container() {
    var _arr = array_create(STATUS.COUNT);
    for (var i = 0; i < STATUS.COUNT; i++) {
        _arr[i] = { turns: 0, dmg: 0, skip_tick: false };
    }
    return _arr;
}

// Retorna o container, nome e HP maximo do lado informado ("player" ou "enemy")
function status_get_side(_b, _side) {
    if (_side == "player") {
        return {
            container: _b.player_status,
            name:      Obj_Player.stats.name,
            hp_max:    Obj_Player.stats.life_max
        };
    }
    return {
        container: _b.enemy_status,
        name:      _b.enemy_name,
        hp_max:    _b.enemy_hp_max
    };
}

// Calcula dano padrao de cada DoT com base no HP maximo do alvo
function status_default_damage(_status, _hp_max) {
    switch (_status) {
        case STATUS.BURN:   return clamp(round(_hp_max * 0.15), 4, 24); // Maior dano, menos rounds
        case STATUS.BLEED:  return clamp(round(_hp_max * 0.06), 2, 10); // Menor dano, mais rounds
        case STATUS.FROZEN: return clamp(round(_hp_max * 0.08), 3, 14); // Dano por acao
        default:            return 0;
    }
}

// Metadados visuais (rotulo, tag curta da HUD e cor)
function status_get_info(_status) {
    switch (_status) {
        case STATUS.BURN:        return { name: "Incendio",    tag: "INC",  col: c_orange };
        case STATUS.FROZEN:      return { name: "Congelado",   tag: "CONG", col: c_aqua };
        case STATUS.STUN:        return { name: "Nocauteado",  tag: "NOC",  col: c_yellow };
        case STATUS.BLEED:       return { name: "Sangramento", tag: "SANG", col: c_red };
        case STATUS.DISORIENTED: return { name: "Desnorteado", tag: "DESN", col: c_fuchsia };
    }
    return { name: "Estado", tag: "EST", col: c_white };
}

// Aplica um estado em "player" ou "enemy" (se ja ativo, preserva maior duracao/dano)
function status_apply(_b, _side, _status, _turns, _dmg = undefined) {
    var _s    = status_get_side(_b, _side);
    var _slot = _s.container[_status];
    var _info = status_get_info(_status);
    var _has_dmg = (_dmg != undefined && _dmg != pointer_null && _dmg > 0);
    var _val     = _has_dmg ? _dmg : status_default_damage(_status, _s.hp_max);

    _slot.turns = max(_slot.turns, _turns);
    _slot.dmg   = max(_slot.dmg,   _val);

    // Se aplicado no jogador durante o turno inimigo, evita perder 1 turno antes de agir
    if (_side == "player" && (_status == STATUS.FROZEN || _status == STATUS.DISORIENTED)) {
        _slot.skip_tick = true;
    }

    battle_vfx_spawn_text(_b, string_upper(_info.name) + "!", _info.col, _side, false);
    battle_add_log(_b, _s.name + " sofreu " + _info.name + " (" + string(_turns) + "t)!");
}

// Testa erro global de golpes (10% base + 45% se Desnorteado)
function status_roll_miss(_b, _attacker_side, _target_side, _ignore_miss = false) {
    if (_ignore_miss) return false;

    var _att   = status_get_side(_b, _attacker_side);
    var _dazed = (_att.container[STATUS.DISORIENTED].turns > 0);
    var _chance = BATTLE_BASE_MISS_CHANCE + (_dazed ? BATTLE_DISORIENTED_MISS_BONUS : 0);

    if (random(100) < _chance) {
        battle_vfx_spawn_text(_b, "ERROU!", c_ltgray, _target_side, false);
        var _reason = _dazed ? " (Desnorteado)" : "";
        battle_add_log(_b, _att.name + " errou o golpe" + _reason + "!");
        return true;
    }
    return false;
}

// Dispara dano de CONGELADO sempre que o lado realiza uma acao; retorna true se morreu
function status_trigger_on_action(_b, _side) {
    var _s    = status_get_side(_b, _side);
    var _slot = _s.container[STATUS.FROZEN];
    if (_slot.turns <= 0) return false;

    var _dmg = max(1, _slot.dmg);
    if (_side == "player") {
        battle_damage_player(_b, _dmg, false, c_aqua);
        battle_add_log(_b, _s.name + " sofreu -" + string(_dmg) + " HP por agir Congelado!");
        if (Obj_Player.stats.life <= 0) { battle_trigger_defeat(_b); return true; }
    } else {
        battle_damage_enemy(_b, _dmg, false, c_aqua);
        battle_add_log(_b, _s.name + " sofreu -" + string(_dmg) + " HP por agir Congelado!");
        if (_b.enemy_hp <= 0) {
            battle_check_end(_b);
            return true;
        }
    }
    return false;
}

// Verifica se algum dos lados possui DoT de fim de round ativo (usado para ritmo da pausa)
function status_has_end_round_dots(_b) {
    return (_b.enemy_status[STATUS.BURN].turns   > 0 || _b.enemy_status[STATUS.BLEED].turns  > 0 ||
            _b.player_status[STATUS.BURN].turns  > 0 || _b.player_status[STATUS.BLEED].turns > 0);
}

// Processa DoTs de fim de round (Incendio + Sangramento) e reduz duracao dos estados
// Retorna true se a batalha terminou (vitoria ou derrota)
function status_process_round_end(_b) {
    var _sides = ["enemy", "player"];

    for (var s = 0; s < 2; s++) {
        var _side = _sides[s];
        var _info = status_get_side(_b, _side);
        var _cont = _info.container;

        // 1. INCENDIO (alto dano, menos rounds)
        if (_cont[STATUS.BURN].turns > 0) {
            var _bdmg = max(1, _cont[STATUS.BURN].dmg);
            _cont[STATUS.BURN].turns--;
            if (_side == "enemy") battle_damage_enemy(_b, _bdmg, false, c_orange);
            else                  battle_damage_player(_b, _bdmg, false, c_orange);
            battle_add_log(_b, _info.name + " queimou (-" + string(_bdmg) + " HP)!");
        }

        // Checa morte apos Incendio antes de aplicar Sangramento
        if (_side == "enemy"  && _b.enemy_hp <= 0)          { battle_check_end(_b); return true; }
        if (_side == "player" && Obj_Player.stats.life <= 0) { battle_trigger_defeat(_b); return true; }

        // 2. SANGRAMENTO (menor dano, mais rounds)
        if (_cont[STATUS.BLEED].turns > 0) {
            var _sdmg = max(1, _cont[STATUS.BLEED].dmg);
            _cont[STATUS.BLEED].turns--;
            if (_side == "enemy") battle_damage_enemy(_b, _sdmg, false, c_red);
            else                  battle_damage_player(_b, _sdmg, false, c_red);
            battle_add_log(_b, _info.name + " sangrou (-" + string(_sdmg) + " HP)!");
        }

        if (_side == "enemy"  && _b.enemy_hp <= 0)          { battle_check_end(_b); return true; }
        if (_side == "player" && Obj_Player.stats.life <= 0) { battle_trigger_defeat(_b); return true; }

        // 3. Decrementa estados de duracao por round (CONGELADO e DESNORTEADO)
        // (STUN decrementa apenas quando o turno e realmente pulado)
        var _timed = [STATUS.FROZEN, STATUS.DISORIENTED];
        for (var t = 0; t < 2; t++) {
            var _st = _cont[_timed[t]];
            if (_st.turns > 0) {
                if (_st.skip_tick) _st.skip_tick = false;
                else               _st.turns--;
            }
        }
    }
    return false;
}

// Monta a string de tags para exibir na HUD (ex: "[INC:2] [SANG:4] ")
function status_get_tags_string(_container) {
    var _out = "";
    for (var i = 0; i < STATUS.COUNT; i++) {
        if (_container[i].turns > 0) {
            var _inf = status_get_info(i);
            _out += "[" + _inf.tag + ":" + string(_container[i].turns) + "] ";
        }
    }
    return _out;
}