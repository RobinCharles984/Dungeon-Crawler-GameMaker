function NewEncounter(_enemies, _bg)
{
	instance_create_depth(
		camera_get_view_x(view_camera[0]),
		camera_get_view_y(view_camera[0]),
		10001,
		Obj_Battle,
		{enemies: _enemies, creator: id, battleBackground: _bg}
		);	
}