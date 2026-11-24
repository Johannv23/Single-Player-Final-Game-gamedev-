// Limb game - by Johann Varghese, Owen and team

// move a value toward a target by a fixed amount, without overshooting
function approach(_start, _end, _amount) {
    if (_start < _end) return min(_start + _amount, _end);
    return max(_start - _amount, _end);
}

// ---- debug hitboxes (press B in game to toggle) ----
global.show_hitboxes = false;   // script globals run once at game start, before any Create event

function draw_hitbox(_col) {
    if (!global.show_hitboxes) return;
    draw_set_color(_col);
    draw_set_alpha(0.25);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, false);
    draw_set_alpha(1);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);
    draw_set_color(c_white);
}

// Sub-pixel movement + pixel-step collision against obj_wall (the professor's move_collide).
// Needs hsp, vsp, x_rem, y_rem set in Create. The fractional part of the speed is carried to
// the next frame, so 1.5 px/frame moves 1, 2, 1, 2... and the instance always sits on whole pixels.
function move_collide() {
    var tx = hsp + x_rem, ty = vsp + y_rem;
    var mx = floor(abs(tx)) * sign(tx), my = floor(abs(ty)) * sign(ty);
    x_rem = tx - mx;
    y_rem = ty - my;
    repeat (abs(mx)) {
        if (place_meeting(x + sign(mx), y, obj_wall)) { hsp = 0; x_rem = 0; break; }
        x += sign(mx);
    }
    repeat (abs(my)) {
        if (place_meeting(x, y + sign(my), obj_wall)) { vsp = 0; y_rem = 0; break; }
        y += sign(my);
    }
}
