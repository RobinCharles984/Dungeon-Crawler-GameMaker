/// Create_0.gml
menu_state = MENU_STATE.MAIN;

// Configuracoes globais persistentes
if (!variable_global_exists("vol_music"))  global.vol_music  = 80;
if (!variable_global_exists("vol_sfx"))    global.vol_sfx    = 80;
if (!variable_global_exists("brightness")) global.brightness = 100;
audio_master_gain(global.vol_music / 100);

// Criacao de personagem
input_name         = "Condenado";
typing_name        = false;
selected_class_idx = 0;

classes_list = [
    { id: CLASS.AGRESSIVO, name: "Agressivo", portrait: Spr_Portrait_Agressive, desc: "Melhor com armas brancas." },
    { id: CLASS.LANCADOR,  name: "Lancador",  portrait: Spr_Portrait_Thrower,   desc: "Melhor com armas de longo alcance e arremessaveis." },
    { id: CLASS.INVOCADOR, name: "Invocador", portrait: Spr_Portrait_Summoner,  desc: "Melhor com equipamentos magicos." }
];