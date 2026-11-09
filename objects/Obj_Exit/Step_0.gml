/// Evento Step de Obj_Exit

if (instance_exists(Obj_Player) && instance_exists(Obj_Builder)) {
    var _cw = Obj_Builder.cell_width;
    var _ch = Obj_Builder.cell_height;

    var _px = Obj_Player.x div _cw;
    var _py = Obj_Player.y div _ch;
    var _ex = x div _cw;
    var _ey = y div _ch;

    // Se pisou exatamente na célula da saída
    if (_px == _ex && _py == _ey) {
        // Limpa instâncias pendentes e volta ao menu principal
        if (instance_exists(Obj_Battle)) instance_destroy(Obj_Battle);
        room_goto(Room_MainMenu);
    }
}