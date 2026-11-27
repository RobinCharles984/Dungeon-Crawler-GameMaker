/// Step_0.gml
if (!instance_exists(Obj_Player) || !instance_exists(Obj_Builder)) exit;

var _cw = Obj_Builder.cell_width, _ch = Obj_Builder.cell_height;
if ((Obj_Player.x div _cw) == (x div _cw) && (Obj_Player.y div _ch) == (y div _ch)) {
    if (instance_exists(Obj_Battle)) instance_destroy(Obj_Battle);
    room_goto(Room_MainMenu);
}