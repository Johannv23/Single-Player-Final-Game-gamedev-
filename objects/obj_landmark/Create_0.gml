// Limb game - by Johann Varghese, Owen and team

// Tall landmark: a solid block that also gives off light (see obj_lighting).
// Left half of the room = fire brazier (orange), right half = water pool (blue).
event_inherited();
element = (x < room_width / 2) ? "fire" : "water";
