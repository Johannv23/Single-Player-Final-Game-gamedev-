// Limb game - by Johann Varghese, Owen and team

//prototype - P grants player all 4 limbs, remove later
if(keyboard_check_pressed(ord("P"))) limbs_prototype_grant(self);

//Spring (Z) overrides normal walk for short invuln arc
if(limbs_spring_step(self)) {
	if (invuln > 0) invuln -= 1;
	if (hurt_flash > 0) hurt_flash -=1;
	depth = -bbox_bottom;
	limbs_step(self)
	exit;
}



// ---- input: WASD ----
var ix = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var iy = keyboard_check(ord("S")) - keyboard_check(ord("W"));

// normalize so diagonals aren't faster
var len = point_distance(0, 0, ix, iy);
if (len > 0) {
    ix /= len;
    iy /= len;
    facing = round(point_direction(0, 0, ix, iy) / 45) mod 8;
}

// accelerate toward the target velocity, or apply friction when no key is held
hsp = approach(hsp, ix * max_speed, (ix != 0) ? accel : fric);
vsp = approach(vsp, iy * max_speed, (iy != 0) ? accel : fric);

move_collide();

if (invuln > 0) invuln -= 1;
if (hurt_flash > 0) hurt_flash -= 1;
depth = -bbox_bottom;       // walk behind tall props, in front of short ones

limbs_step(self);
