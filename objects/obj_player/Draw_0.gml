// Limb game - by Johann Varghese, Owen and team

// shadow on the ground
draw_set_color(c_black);
draw_set_alpha(0.3);
draw_ellipse(x - 14, bbox_bottom - 6, x + 14, bbox_bottom + 2, false);
draw_set_alpha(1);
draw_set_color(c_white);

draw_sprite_ext(spr_box, 0, x, y, 1, 1, 0, (hurt_flash > 0) ? c_red : c_white, 1);

// eyes slide toward the facing direction so you can read which way the box looks
var ex = lengthdir_x(5, facing * 45), ey = lengthdir_y(5, facing * 45);
draw_set_color(make_color_rgb(28, 27, 38));
draw_rectangle(x - 9 + ex, y - 6 + ey, x - 5 + ex, y + ey, false);
draw_rectangle(x + 5 + ex, y - 6 + ey, x + 9 + ex, y + ey, false);
draw_set_color(c_white);
draw_hitbox(c_lime);
