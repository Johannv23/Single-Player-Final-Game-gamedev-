// Limb game - by Johann Varghese, Owen and team

// Maw door (Cursed Land). Locked: dim red glow in the mouth. Open: warm light that pulses.
var cx = (x1 + x2) / 2;
draw_sprite_ext(spr_rock3_1, 0, cx, y2 + 16, 1, 1, 0, merge_color(make_color_rgb(150, 140, 150), c_white, glow), 1);

var pulse = 0.85 + 0.15 * sin(current_time / 250);
gpu_set_blendmode(bm_add);
draw_set_color(merge_color(make_color_rgb(110, 10, 10), make_color_rgb(255, 190, 90), glow));
draw_set_alpha((0.35 + 0.5 * glow) * pulse);
draw_ellipse(cx - 12, y2 - 28, cx + 12, y2 - 6, false);
draw_set_alpha(0.25 * glow * pulse);
draw_ellipse(cx - 22, y2 - 38, cx + 22, y2 + 2, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(c_white);
