// Mesmo padrão do enemies.gml: enum + init_*() que preenche um array global de structs.

enum CLASS {
    AGRESSIVO,
    LANCADOR,
    INVOCADOR
}

// Define qual atributo a skill usa para calcular o dano
enum SKILL_STAT {
    NONE,   // Buff, fuga ou status puro (sem dano direto)
    ATTACK, // Escala com Attack (inclui equipamentos e buff Forjado)
    MAGIC   // Escala com Magic (inclui equipamentos)
}

// Configura um DoT/estado para anexar em qualquer skill
function skill_status(_status, _chance, _turns_min, _turns_max = _turns_min, _dmg = undefined) {
    return {
        status:    _status,
        chance:    _chance,
        turns_min: _turns_min,
        turns_max: _turns_max,
        dmg:       _dmg
    };
}

// Construtor de skill com escalonamento de dano (Attack / Magic) e DoTs
function skill(_name, _mp, _desc, _stat = SKILL_STAT.NONE, _mult = 0, _statuses = [], _color = c_white) {
    return {
        name:     _name,
        mp:       _mp,
        desc:     _desc,
        stat:     _stat,
        mult:     _mult,
        statuses: _statuses,
        color:    _color
    };
}

function init_classes() {
    global.classes = [];

    // ---------------- AGRESSIVO ----------------
    global.classes[CLASS.AGRESSIVO] = {
        // Info
        name: "Agressivo",
        description: "Foco em combate corpo a corpo. Corpo forte, aguenta mais pancadas, mas sofre com cortes e não tem um dos melhores golpes.\nUm bom escudo, ou alguém que dura bastante.",
        best_with: "Armas brancas",
		player_portrait: Spr_Portrait_Agressive,

        // Stats iniciais (mesmos nomes do enemies: life, attack, crit_chance, crit_rate, xp)
        life: 32,
        mp: 50,
        xp: 0,
        attack: 12,
        defense: 3,
        magic: 0,
        crit_chance: 5,
        crit_rate: 40,
		base_xp: 75,
		hp_gain: 8, mp_gain: 5, atk_gain: 2, def_gain: 3, mag_gain: 0,

        // Mantra
        mantra_chance: 15,
        mantra_cost_mult: 0.5,   // multiplicador no custo de MP das skills padrão se for Mantra

        // Skills
        skills: [
        skill("Concussão", 30, "Causa 1.50*Attack de dano, podendo deixar o inimigo Nocauteado.",
            SKILL_STAT.ATTACK, 1.50, [skill_status(STATUS.STUN, 50, 1)]),
        skill("Blindagem", 45, "Duplica a defesa do usuário por 3 rounds.")
    ],
    mantra_skills: [
        skill("Escolhido", 20, "Foge da batalha, indo para um lugar aleatório das Masmorras."),
        skill("Forjado",   25, "Attack 1.15x maior por 2 rounds.")
    ]
    };

    // ---------------- LANÇADOR ----------------
    global.classes[CLASS.LANCADOR] = {
        name: "Lançador",
        description: "Excelente à longa distância. Menos resistente, mas sempre dá o golpe final.",
        best_with: "Armas de longo alcance e arremessáveis",
		player_portrait: Spr_Portrait_Thrower,

        life: 23,
        mp: 45,
        xp: 0,
        attack: 17,
        defense: 1,
        magic: 0,
        crit_chance: 20,
        crit_rate: 60,
		base_xp: 50,
		hp_gain: 3, mp_gain: 3, atk_gain: 5, def_gain: 2, mag_gain: 0,

        mantra_chance: 10,
        mantra_cost_mult: 1,     // o doc não cita desconto para o Lançador

        skills: [
        skill("Perfuração", 20, "Causa 1.70*Attack de dano, com 50% de chance de causar Sangramento por 3 rounds.",
            SKILL_STAT.ATTACK, 1.70, [skill_status(STATUS.BLEED, 50, 3)]),
        skill("Head Shot",  30, "Tenta um acerto certeiro (15%). Se acertar, o inimigo morre.")
    ],
    mantra_skills: [
        skill("Preciso",   40, "Ataca 3x seguidas, não importa o estado.",
            SKILL_STAT.ATTACK, 1.00),
        skill("Impreciso", 35, "Inimigo fica Desnorteado por 1-4 rounds.",
            SKILL_STAT.NONE, 0, [skill_status(STATUS.DISORIENTED, 100, 1, 4)])
    ]
    };

    // ---------------- INVOCADOR ----------------
    global.classes[CLASS.INVOCADOR] = {
        name: "Invocador",
        description: "Nasceu com o dom, domina o mantra sem esforço. Menos resistente, mas com feitiços na manga. Cuidado com a Mana.",
        best_with: "Equipamentos mágicos",
		player_portrait: Spr_Portrait_Summoner,

        life: 20,
        mp: 100,
        xp: 0,
        attack: 0,
        defense: 0,
        magic: 15,
        crit_chance: 15,
        crit_rate: 80,
		base_xp: 100,
		hp_gain: 1, mp_gain: 10, atk_gain: 0, def_gain: 0, mag_gain: 5,

        mantra_chance: 100,
        mantra_cost_mult: 1,     // Fogo/Gelo já custam 0 MP, então o desconto não muda nada

        skills: [
        skill("Fogo", 0, "Causa 2*Magic de dano, com 67% de chance de causar Incêndio.",
            SKILL_STAT.MAGIC, 2.00, [skill_status(STATUS.BURN, 67, 2)], c_orange),
        skill("Gelo", 0, "Causa 1.45*Magic de dano, com 80% de chance de deixar Congelado.",
            SKILL_STAT.MAGIC, 1.45, [skill_status(STATUS.FROZEN, 80, 2, 3)], c_aqua)
    ],
    mantra_skills: [
        skill("Sectum",      20, "Causa Sangramento no alvo por 2-5 rounds.",
            SKILL_STAT.NONE, 0, [skill_status(STATUS.BLEED, 100, 2, 5)]),
        skill("Invisibilis", 25, "Alvo fica Desnorteado por 3-6 rounds.",
            SKILL_STAT.NONE, 0, [skill_status(STATUS.DISORIENTED, 100, 3, 6)])
    ]
    };
}

/// @desc Cria o struct do player a partir da classe escolhida. Sorteia o Mantra aqui.
/// @param {Real} _class_id  valor do enum CLASS
/// @param {String} _name    nome digitado
function create_player(_class_id, _name) {
    if (!variable_global_exists("classes")) init_classes();

    var _c = global.classes[_class_id];
    var _is_mantra = (random(100) < _c.mantra_chance);
    var _mult = _is_mantra ? _c.mantra_cost_mult : 1;
	
	var _initial_level = 1;
    var _base_xp = _c[$ "base_xp"] ?? 100;
	
	// FÓRMULA: XP_next = Base * (Level ^ 1.5)
    var _xp_next = round(_base_xp * power(_initial_level, 1.5));

    var _skills = [];
    for (var i = 0; i < array_length(_c.skills); i++) {
        var _s = _c.skills[i];
        array_push(_skills, {
            name:     _s.name,
            mp:       ceil(_s.mp * _mult),
            desc:     _s.desc,
            stat:     _s.stat,
            mult:     _s.mult,
            statuses: _s.statuses,
            color:    _s.color
        });
    }
    if (_is_mantra) {
        for (var j = 0; j < array_length(_c.mantra_skills); j++) {
            var _m = _c.mantra_skills[j];
            array_push(_skills, {
                name:     _m.name,
                mp:       _m.mp,
                desc:     _m.desc,
                stat:     _m.stat,
                mult:     _m.mult,
                statuses: _m.statuses,
                color:    _m.color
            });
        }
    }

    return {
        name: _name,
        class_id: _class_id,
        class_name: _c.name,
        portrait: _c.player_portrait, 
        is_mantra: _is_mantra,
        level: 1,
		
		// SISTEMA DE EXPERIÊNCIA
        base_xp: _base_xp,
        xp: 0,
        xp_next: _xp_next,

        life: _c.life,  life_max: _c.life,
        mp: _c.mp,      mp_max: _c.mp,
        xp: _c.xp,
        attack: _c.attack,
        defense: _c.defense,
        magic: _c.magic,
        crit_chance: _c.crit_chance,
        crit_rate: _c.crit_rate,
		
		// GANHOS DE ATRIBUTOS POR LEVEL UP
        hp_gain:  _c[$ "hp_gain"]  ?? 5,
        mp_gain:  _c[$ "mp_gain"]  ?? 5,
        atk_gain: _c[$ "atk_gain"] ?? 2,
        def_gain: _c[$ "def_gain"] ?? 1,
        mag_gain: _c[$ "mag_gain"] ?? 1,

        skills: _skills,

        // Slots de equipamento ativos
        equipped: {
            weapon:    undefined,
            armor:     undefined,
            accessory: undefined
        }
    };
}

/// @desc Adiciona XP ao jogador e processa a elevação de nível
/// @param {Real} _amount Quantidade de experiência recebida
function player_gain_xp(_amount) {
    if (!instance_exists(Obj_Player)) exit;
    var _p = Obj_Player.stats;

    _p.xp += _amount;

    // Loop para processar acúmulos que sobem mais de 1 nível de uma vez
    while (_p.xp >= _p.xp_next) {
        // Deduz a meta cumprida mantendo o excesso de XP
        _p.xp -= _p.xp_next;
        _p.level += 1;

        // FÓRMULA: XP_next = Base * (Level ^ 1.5)
        _p.xp_next = round(_p.base_xp * power(_p.level, 1.5));

        // Incrementa os atributos da classe
        _p.life_max += _p.hp_gain;
        _p.life      = _p.life_max; // Restaura HP totalmente ao subir de nível
        
        _p.mp_max   += _p.mp_gain;
        _p.mp        = _p.mp_max;   // Restaura MP totalmente ao subir de nível

        _p.attack   += _p.atk_gain;
        _p.defense  += _p.def_gain;
        _p.magic    += _p.mag_gain;

        // Notificação de Level Up no log da batalha (se ativo)
        if (instance_exists(Obj_Battle)) {
            Obj_Battle.add_log("--- LEVEL UP! ---");
            Obj_Battle.add_log(_p.name + " subiu para o Nível " + string(_p.level) + "!");
        }
    }
}