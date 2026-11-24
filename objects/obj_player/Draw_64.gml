// Limb game - by Johann Varghese, Owen and team

// health bar, top left (GUI coordinates: 1280x704 screen)
draw_set_color(c_black);
draw_rectangle(16, 16, 216, 32, false);
draw_set_color(make_color_rgb(200, 50, 50));
draw_rectangle(18, 18, 18 + 196 * (hp / max_hp), 30, false);
draw_set_color(c_white);
