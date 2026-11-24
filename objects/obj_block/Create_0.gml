// Limb game - by Johann Varghese, Owen and team

// Cover block. Child of obj_wall, so the player and enemies collide with its footprint.
// The art pass paints a prop over it (the "Props" layer), so the block itself is invisible.
event_inherited();
depth = -bbox_bottom;
