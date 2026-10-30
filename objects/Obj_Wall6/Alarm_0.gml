/// Move and make tiles
if _dir = 0
x += width;

if _dir = 1
y -= width;

if _dir = 2
x -= width;

if _dir = 3
y += width;

instance_create_depth(x, y, 0, Obj_Wall);
_dir = irandom(3)
alarm[0] = 5;