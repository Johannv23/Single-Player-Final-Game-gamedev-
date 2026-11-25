// Move
x += lengthdir_x(speed, direction);
y += lengthdir_y(speed, direction);
life -= 1;

if (life <= 0) instance_destroy();
if (place_meeting(x, y, obj_wall)) instance_destroy();

// Hit test from the PROJECTILE (not with obj_enemy)
var hit = instance_place(x, y, obj_enemy);
if (hit != noone) {
    hit.take_damage(damage);
    instance_destroy();
}