/// Evento Draw de Obj_Builder

if (variable_instance_exists(id, "wall_vbuf")) {
    gpu_set_ztestenable(true);
    gpu_set_zwriteenable(true);
    gpu_set_cullmode(cull_noculling);

    // Renderiza cada bioma com sua respectiva textura em 1 única chamada à GPU
    var _tex_sewer   = sprite_get_texture(Spr_Sewer_Wall, 0);   // Ajuste para o nome do seu sprite
    var _tex_cave    = sprite_get_texture(Spr_Cave_Wall, 0);    // Ajuste para o nome do seu sprite
    var _tex_dungeon = sprite_get_texture(Spr_Dungeon_Wall, 0); // Ajuste para o nome do seu sprite

    vertex_submit(wall_vbuf[BIOME.SEWER],   pr_trianglelist, _tex_sewer);
    vertex_submit(wall_vbuf[BIOME.CAVE],    pr_trianglelist, _tex_cave);
    vertex_submit(wall_vbuf[BIOME.DUNGEON], pr_trianglelist, _tex_dungeon);
}