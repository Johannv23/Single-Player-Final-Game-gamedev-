// Limb game - by Johann Varghese, Owen and team

if (!enabled) exit;

// crystals (green) from the props obj_game made; found once
if (!lights_built) {
    lights_built = true;
    with (obj_prop) {
        if (string_pos("many_eyes", sprite_get_name(sprite_index)) > 0)
            array_push(other.lights, { x: x, y: y - 14, r: 70, col: make_color_rgb(80, 170, 110), flick: random(100) });
    }
}

var cam = view_camera[0];
var cx = camera_get_view_x(cam), cy = camera_get_view_y(cam);
var cw = camera_get_view_width(cam), ch = camera_get_view_height(cam);
if (!surface_exists(surf)) surf = surface_create(cw, ch);

// ---- build the light map
surface_set_target(surf);
draw_clear(ambient);
gpu_set_blendmode(bm_add);
draw_set_circle_precision(32);

// player: a warm pool around them
with (obj_player) draw_circle_colour(x - cx, y - cy, 120, make_color_rgb(150, 135, 115), c_black, false);

// crystals, with a slow flicker
for (var i = 0; i < array_length(lights); i++) {
    var L = lights[i];
    var k = 0.9 + 0.1 * sin(current_time / 400 + L.flick);
    draw_circle_colour(L.x - cx, L.y - cy, L.r * k, L.col, c_black, false);
}

// landmarks: fire on the left (fast orange flicker), water on the right (slow blue shimmer)
with (obj_landmark) {
    var fire = (element == "fire");
    var k = 0.95 + 0.05 * sin(current_time / 400 + x);
    var lc = other.col_water;
    if (fire) {
        k = 0.9 + 0.1 * sin(current_time / 90 + x) + 0.05 * sin(current_time / 37);
        lc = other.col_fire;
    }
    draw_circle_colour((bbox_left + bbox_right) / 2 - cx, bbox_top - 6 - cy, 135 * k, lc, c_black, false);
}

// enemies carry their element's colour, so you can tell fire from water in the dark
with (obj_enemy) {
    var c = make_color_rgb(90, 90, 90);
    if (element == "fire") c = other.col_fire;
    else if (element == "water") c = other.col_water;
    draw_circle_colour(x - cx, y - cy, 58, c, c_black, false);
}

// doors: dim red while locked, bright gold when open
with (obj_door) {
    var c = merge_color(make_color_rgb(70, 10, 10), make_color_rgb(255, 190, 100), glow);
    draw_circle_colour((x1 + x2) / 2 - cx, y2 - 14 - cy, 60 + 50 * glow, c, c_black, false);
}

// spawn warnings glow red so you can spot them in the dark
if (instance_exists(obj_game)) {
    for (var i = 0; i < array_length(obj_game.pending); i++) {
        var p = obj_game.pending[i];
        if (p.t <= obj_game.warn_frames) draw_circle_colour(p.x - cx, p.y - cy, 40, make_color_rgb(140, 20, 20), c_black, false);
    }
}

gpu_set_blendmode(bm_normal);
draw_set_circle_precision(24);
surface_reset_target();

// ---- multiply the world by it
gpu_set_blendmode_ext(bm_dest_colour, bm_zero);
draw_surface(surf, cx, cy);
gpu_set_blendmode(bm_normal);
