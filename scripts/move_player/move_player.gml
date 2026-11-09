// Os recursos de script mudaram para a v2.3.0; veja
// https://help.yoyogames.com/hc/en-us/articles/360005277377 para obter mais informações
function move_player(){
	var up = keyboard_check_pressed(vk_up);
	var down = keyboard_check_pressed(vk_down);
	var left = keyboard_check_pressed(vk_left);
	var right = keyboard_check_pressed(vk_right);

	if (up)
	{
	    // Move Forward
    
	    var vect_x = lengthdir_x(32, target_dir);
	    var vect_y = lengthdir_y(32, target_dir);
		
	    var _target_gx = vect_x div Obj_Builder.cell_width;
		var _target_gy = vect_y div Obj_Builder.cell_height;
    
	    // Move Forward
	    if (Obj_Builder.grid[# _target_gx, _target_gy] != Obj_Builder.CELL_WALL)
	    {
	        target_x += vect_x;
	        target_y += vect_y;
	    }
	}
	if (down)
	{
	    // Move Backwards
    
	    var vect_x = lengthdir_x(32, target_dir);
	    var vect_y = lengthdir_y(32, target_dir);
		
		var _target_gx = vect_x div Obj_Builder.cell_width;
		var _target_gy = vect_y div Obj_Builder.cell_height;
    
	    // Move Forward
	    if (Obj_Builder.grid[# _target_gx, _target_gy] != Obj_Builder.CELL_WALL)
	    {
	        target_x -= vect_x;
	        target_y -= vect_y;
	    }
	}
	if (left)
	{
	    // Turn Left
	    target_dir -= 90;
	}
	if (right)
	{
	    // Turn Right
	    target_dir += 90;
	}
}