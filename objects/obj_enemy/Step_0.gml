// Limb game - by Johann Varghese, Owen and team

if (hit_flash > 0) hit_flash -= 1;
if (!instance_exists(obj_player)) exit;

var tx = obj_player.x, ty = obj_player.y;

// ---- follow a path around walls, re-planned about twice a second ----
path_t -= 1;
if (path_t <= 0 && obj_game.grid != -1) {
    path_t = 25 + irandom(10);
    path_ok = mp_grid_path(obj_game.grid, mypath, x, y, obj_player.x, obj_player.y, true);
    path_i = 1;
}
if (path_ok && path_i < path_get_number(mypath)) {
    tx = path_get_point_x(mypath, path_i);
    ty = path_get_point_y(mypath, path_i);
    if (point_distance(x, y, tx, ty) < 6) path_i += 1;
}

var dir = point_direction(x, y, tx, ty);
var mx = lengthdir_x(move_speed, dir);
var my = lengthdir_y(move_speed, dir);
if (!place_meeting(x + mx, y, obj_wall)) x += mx;
if (!place_meeting(x, y + my, obj_wall)) y += my;

// touching the player hurts (the player has a short grace period after each hit)
if (place_meeting(x, y, obj_player) && obj_player.invuln <= 0) {
    obj_player.hp -= touch_damage;
    obj_player.invuln = 40;
    obj_player.hurt_flash = 12;
}

depth = -bbox_bottom;
