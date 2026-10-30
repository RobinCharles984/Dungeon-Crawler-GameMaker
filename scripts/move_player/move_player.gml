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
    
	    // Move Forward
	    if (!place_meeting(target_x+vect_x, target_y+vect_y, Obj_Wall))
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
    
	    // Move Forward
	    if (!place_meeting(target_x-vect_x, target_y-vect_y, Obj_Wall))
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