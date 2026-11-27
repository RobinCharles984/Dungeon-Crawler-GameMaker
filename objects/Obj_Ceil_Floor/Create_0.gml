/// Create_0.gml
floor_vbuf = undefined;
ceil_vbuf  = undefined;

if (variable_instance_exists(id, "builder_ref") && instance_exists(builder_ref)) {
    var _m     = dungeon_build_floor_ceil_buffers(builder_ref);
    floor_vbuf = _m.floor_vbuf;
    ceil_vbuf  = _m.ceil_vbuf;
}