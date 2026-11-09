function NewEncounter(_enemy_data, _bg) {
    if (instance_exists(Obj_Battle)) instance_destroy(Obj_Battle);
    
    // Envia { enemies: _enemy_data } dentro do instance_create_layer
    // para que a struct chegue ANTES do evento Create do Obj_Battle rodar!
    var _b = instance_create_layer(0, 0, "Instances", Obj_Battle, { enemies: _enemy_data });
    return _b;
}