// Mesmo padrão do enemies.gml: enum + init_*() que preenche um array global de structs.

enum CLASS {
    AGRESSIVO,
    LANCADOR,
    INVOCADOR
}

// Atalho para montar uma skill (mantém o init_classes legível)
function skill(_name, _mp, _desc) {
    return { name: _name, mp: _mp, desc: _desc };
}

function init_classes() {
    global.classes = [];

    // ---------------- AGRESSIVO ----------------
    global.classes[CLASS.AGRESSIVO] = {
        // Info
        name: "Agressivo",
        description: "Foco em combate corpo a corpo. Corpo forte, aguenta mais pancadas, mas sofre com cortes e não tem um dos melhores golpes.\nUm bom escudo, ou alguém que dura bastante.",
        best_with: "Armas brancas",

        // Stats iniciais (mesmos nomes do enemies: life, attack, crit_chance, crit_rate, xp)
        life: 32,
        mp: 50,
        xp: 0,
        attack: 12,
        defense: 3,
        magic: 0,
        crit_chance: 5,
        crit_rate: 40,

        // Mantra
        mantra_chance: 15,
        mantra_cost_mult: 0.5,   // multiplicador no custo de MP das skills padrão se for Mantra

        // Skills
        skills: [
            skill("Concussão", 30, "Causa 1.50*Attack de dano, podendo deixar o inimigo Nocauteado."),
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

        life: 23,
        mp: 45,
        xp: 0,
        attack: 17,
        defense: 1,
        magic: 0,
        crit_chance: 20,
        crit_rate: 60,

        mantra_chance: 10,
        mantra_cost_mult: 1,     // o doc não cita desconto para o Lançador

        skills: [
            skill("Perfuração", 20, "Causa 1.70*Attack de dano, com 50% de chance de causar Sangramento por 3 rounds."),
            skill("Head Shot",  30, "Tenta um acerto certeiro (15%). Se acertar, o inimigo morre.")
        ],
        mantra_skills: [
            skill("Preciso",   40, "Ataca 3x seguidas, não importa o estado."),
            skill("Impreciso", 35, "Inimigo fica Impreciso (erra os ataques) por 1-4 rounds.")
        ]
    };

    // ---------------- INVOCADOR ----------------
    global.classes[CLASS.INVOCADOR] = {
        name: "Invocador",
        description: "Nasceu com o dom, domina o mantra sem esforço. Menos resistente, mas com feitiços na manga. Cuidado com a Mana.",
        best_with: "Equipamentos mágicos",

        life: 20,
        mp: 100,
        xp: 0,
        attack: 0,
        defense: 0,
        magic: 15,
        crit_chance: 15,
        crit_rate: 80,

        mantra_chance: 100,
        mantra_cost_mult: 1,     // Fogo/Gelo já custam 0 MP, então o desconto não muda nada

        skills: [
            skill("Fogo", 0, "Causa 2*Magic de dano, com 67% de chance de causar Incêndio."),
            skill("Gelo", 0, "Causa 1.45*Magic de dano, com 80% de chance de deixar Nocauteado.")
        ],
        mantra_skills: [
            skill("Sectum",     20, "Causa Sangramento no alvo por 2-5 rounds."),
            skill("Invisibilis", 25, "Alvo fica Impreciso (erra os ataques) por 3-6 rounds.")
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

    // Skills padrão (com custo ajustado se Mantra) + skills de Mantra
    var _skills = [];
    for (var i = 0; i < array_length(_c.skills); i++) {
        var _s = _c.skills[i];
        array_push(_skills, { name: _s.name, mp: ceil(_s.mp * _mult), desc: _s.desc });
    }
    if (_is_mantra) {
        for (var j = 0; j < array_length(_c.mantra_skills); j++) {
            var _m = _c.mantra_skills[j];
            array_push(_skills, { name: _m.name, mp: _m.mp, desc: _m.desc });
        }
    }

    return {
        name: _name,
        class_id: _class_id,
        class_name: _c.name,
        is_mantra: _is_mantra,
        level: 1,

        life: _c.life,  life_max: _c.life,
        mp: _c.mp,      mp_max: _c.mp,
        xp: _c.xp,
        attack: _c.attack,
        defense: _c.defense,
        magic: _c.magic,
        crit_chance: _c.crit_chance,
        crit_rate: _c.crit_rate,

        skills: _skills
    };
}