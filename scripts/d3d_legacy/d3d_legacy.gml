function d3d_start() {
    gpu_set_ztestenable(true);
    gpu_set_zwriteenable(true);
    gpu_set_cullmode(cull_noculling);
	gpu_set_texrepeat(true);

    // Cria o formato 3D global necessário para o GMS2 desenhar as paredes
    vertex_format_begin();
    vertex_format_add_position_3d();
    vertex_format_add_texcoord();
    vertex_format_add_colour();
    global.d3d_format = vertex_format_end();
}

function d3d_set_projection(xfrom, yfrom, zfrom, xto, yto, zto, xup, yup, zup) {
    var _view = matrix_build_lookat(xfrom, yfrom, zfrom, xto, yto, zto, xup, yup, zup);
    var _proj = matrix_build_projection_perspective_fov(60, window_get_width() / window_get_height(), 1, 32000);
    camera_set_view_mat(view_camera[0], _view);
    camera_set_proj_mat(view_camera[0], _proj);
    camera_apply(view_camera[0]);
}

function d3d_set_fog(enable, color = c_black, start_dist = 1, end_dist = 300) {
    gpu_set_fog(enable, color, start_dist, end_dist);
}

function d3d_draw_wall(x1, y1, z1, x2, y2, z2, tex, hrepeat = 1, vrepeat = 1) {
    var _vb = vertex_create_buffer();
    vertex_begin(_vb, global.d3d_format);

    var _h = hrepeat;
    var _v = vrepeat;

    // Triângulo 1 (Metade da parede)
    vertex_position_3d(_vb, x1, y1, z2); vertex_texcoord(_vb, 0, 0);  vertex_colour(_vb, c_white, 1);
    vertex_position_3d(_vb, x2, y2, z2); vertex_texcoord(_vb, _h, 0); vertex_colour(_vb, c_white, 1);
    vertex_position_3d(_vb, x1, y1, z1); vertex_texcoord(_vb, 0, _v); vertex_colour(_vb, c_white, 1);

    // Triângulo 2 (Outra metade da parede)
    vertex_position_3d(_vb, x2, y2, z2); vertex_texcoord(_vb, _h, 0);  vertex_colour(_vb, c_white, 1);
    vertex_position_3d(_vb, x2, y2, z1); vertex_texcoord(_vb, _h, _v); vertex_colour(_vb, c_white, 1);
    vertex_position_3d(_vb, x1, y1, z1); vertex_texcoord(_vb, 0, _v);  vertex_colour(_vb, c_white, 1);

    vertex_end(_vb);
    vertex_submit(_vb, pr_trianglelist, tex);
    vertex_delete_buffer(_vb);
}

function d3d_draw_floor(x1, y1, z1, x2, y2, z2, tex, hrepeat = 1, vrepeat = 1) {
    var _vb = vertex_create_buffer();
    vertex_begin(_vb, global.d3d_format);

    var _h = hrepeat;
    var _v = vrepeat;

    // Triângulo 1 (Metade do chão)
    vertex_position_3d(_vb, x1, y1, z1); vertex_texcoord(_vb, 0, 0);  vertex_colour(_vb, c_white, 1);
    vertex_position_3d(_vb, x2, y1, z1); vertex_texcoord(_vb, _h, 0); vertex_colour(_vb, c_white, 1);
    vertex_position_3d(_vb, x2, y2, z2); vertex_texcoord(_vb, _h, _v); vertex_colour(_vb, c_white, 1);

    // Triângulo 2 (Outra metade do chão)
    vertex_position_3d(_vb, x1, y1, z1); vertex_texcoord(_vb, 0, 0);  vertex_colour(_vb, c_white, 1);
    vertex_position_3d(_vb, x2, y2, z2); vertex_texcoord(_vb, _h, _v); vertex_colour(_vb, c_white, 1);
    vertex_position_3d(_vb, x1, y2, z2); vertex_texcoord(_vb, 0, _v); vertex_colour(_vb, c_white, 1);

    vertex_end(_vb);
    vertex_submit(_vb, pr_trianglelist, tex);
    vertex_delete_buffer(_vb);
}

function d3d_draw_block(x1, y1, z1, x2, y2, z2, tex, hrepeats = 1, vrepeats = 1) {
    var _vb = vertex_create_buffer();
    vertex_begin(_vb, global.d3d_format);

    var _h = hrepeats;
    var _v = vrepeats;

    // Helper interno para desenhar retângulos 3D (quads)
    var _add_quad = function(_b, _px1, _py1, _pz1, _px2, _py2, _pz2, _px3, _py3, _pz3, _px4, _py4, _pz4, _u_rep, _v_rep) {
        vertex_position_3d(_b, _px1, _py1, _pz1); vertex_texcoord(_b, 0, 0);      vertex_colour(_b, c_white, 1);
        vertex_position_3d(_b, _px2, _py2, _pz2); vertex_texcoord(_b, _u_rep, 0);  vertex_colour(_b, c_white, 1);
        vertex_position_3d(_b, _px3, _py3, _pz3); vertex_texcoord(_b, _u_rep, _v_rep); vertex_colour(_b, c_white, 1);

        vertex_position_3d(_b, _px1, _py1, _pz1); vertex_texcoord(_b, 0, 0);      vertex_colour(_b, c_white, 1);
        vertex_position_3d(_b, _px3, _py3, _pz3); vertex_texcoord(_b, _u_rep, _v_rep); vertex_colour(_b, c_white, 1);
        vertex_position_3d(_b, _px4, _py4, _pz4); vertex_texcoord(_b, 0, _v_rep);  vertex_colour(_b, c_white, 1);
    };

    // 1. Frente (Y1)
    _add_quad(_vb, x1, y1, z2,  x2, y1, z2,  x2, y1, z1,  x1, y1, z1, _h, _v);
    // 2. Trás (Y2)
    _add_quad(_vb, x2, y2, z2,  x1, y2, z2,  x1, y2, z1,  x2, y2, z1, _h, _v);
    // 3. Esquerda (X1)
    _add_quad(_vb, x1, y2, z2,  x1, y1, z2,  x1, y1, z1,  x1, y2, z1, _h, _v);
    // 4. Direita (X2)
    _add_quad(_vb, x2, y1, z2,  x2, y2, z2,  x2, y2, z1,  x2, y1, z1, _h, _v);
    // 5. Teto (Z2)
    _add_quad(_vb, x1, y1, z2,  x2, y1, z2,  x2, y2, z2,  x1, y2, z2, _h, _v);
    // 6. Chão (Z1)
    _add_quad(_vb, x1, y2, z1,  x2, y2, z1,  x2, y1, z1,  x1, y1, z1, _h, _v);

    vertex_end(_vb);
    vertex_submit(_vb, pr_trianglelist, tex);
    vertex_delete_buffer(_vb);
}