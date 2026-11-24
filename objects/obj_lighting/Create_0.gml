// Limb game - by Johann Varghese, Owen and team

// Lighting: the room is drawn, then multiplied by a light map.
// The light map is the ambient colour plus soft additive circles (player, landmarks, enemies, crystals, doors).
// Created by obj_game. Press L to toggle.
depth = -15000;                                // after every world object, before the GUI
surf = -1;
enabled = true;
ambient = make_color_rgb(78,70,100);         // cold blue cave light

col_fire  = make_color_rgb(200, 100, 35);
col_water = make_color_rgb(50, 120, 210);

lights_built = false;                          // props are found on the first Draw, once they all exist
lights = [];                                   // { x, y, r, col, flick }
