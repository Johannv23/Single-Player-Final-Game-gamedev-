// Limb game - by Johann Varghese, Owen and team

glow = lerp(glow, is_open ? 1 : 0, 0.08);

// walk into an open door -> next room (for now: restart this one)
if (is_open && collision_rectangle(x1, y1, x2, y2 - 8, obj_player, false, true) != noone) {
    room_restart();
}
