// Limb game - by Johann Varghese, Owen and team

draw_set_color(c_black);
draw_set_alpha(0.3);
draw_ellipse(x - 11, bbox_bottom - 5, x + 11, bbox_bottom + 2, false);
draw_set_alpha(1);
draw_set_color(c_white);
draw_sprite_ext(spr_enemy_box, 0, x, y, 1, 1, 0, (hit_flash > 0) ? c_white : col, 1);
draw_hitbox(c_red);
