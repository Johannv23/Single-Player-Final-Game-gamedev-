// Limb game - by Johann Varghese, Owen and team

// ---- first frame: pathfinding grid (16px cells, blocked wherever a wall, cover or door is) + spawn queue ----
if (first_frame) {
    first_frame = false;
    grid = mp_grid_create(0, 0, ceil(room_width / 16), ceil(room_height / 16), 16, 16);
    mp_grid_add_instances(grid, obj_wall, false);

    // every spawn point gets one enemy: left half = fire, right half = water
    with (obj_spawn) {
        array_push(other.pending, { x: x, y: y, obj: (x < room_width / 2) ? obj_enemy_fire : obj_enemy_water, t: other.warn_frames });
    }
    scheduled = true;
}

// ---- debug keys ----
if (keyboard_check_pressed(ord("R"))) room_restart();
if (keyboard_check_pressed(ord("B"))) global.show_hitboxes = !global.show_hitboxes;
if (keyboard_check_pressed(ord("L"))) with (obj_lighting) enabled = !enabled;
if (keyboard_check_pressed(ord("K"))) with (obj_enemy) take_damage(999);     // test: kill everything to open the door

// ---- spawn warnings count down, then the enemy appears ----
for (var i = array_length(pending) - 1; i >= 0; i--) {
    var p = pending[i];
    p.t -= 1;
    if (p.t <= 0 && instance_number(obj_enemy) >= max_alive) p.t = 1;   // full: wait for a free slot
    if (p.t <= 0) {
        instance_create_layer(p.x, p.y, "Instances", p.obj);
        array_delete(pending, i, 1);
    }
}

// ---- room clear: everything spawned and dead -> doors open ----
if (scheduled && !cleared && array_length(pending) == 0 && instance_number(obj_enemy) == 0) {
    cleared = true;
    with (obj_door) open_door();
}
