// Limb game - by Johann Varghese, Owen and team

// Room controller: props, pathfinding grid, spawning, door, debug keys.

// Props are painted as sprites on the "Props" asset layer by _tools/build_room.py.
// At room start each one becomes a solid-footprint, depth-sorted obj_prop (same trick as the sword game).
var lay = layer_get_id("Props");
if (lay != -1) {
    var els = layer_get_all_elements(lay);
    for (var i = 0; i < array_length(els); i++) {
        var el = els[i];
        if (layer_get_element_type(el) != layerelementtype_sprite) continue;
        // the struct sets these before obj_prop's Create runs, so its depth uses the right mask
        instance_create_layer(layer_sprite_get_x(el), layer_sprite_get_y(el), "Instances", obj_prop, {
            sprite_index: layer_sprite_get_sprite(el),
            image_index:  layer_sprite_get_index(el),
            image_xscale: layer_sprite_get_xscale(el),
            image_yscale: layer_sprite_get_yscale(el),
            image_blend:  layer_sprite_get_blend(el)
        });
        layer_sprite_destroy(el);
    }
}

first_frame = true;     // other objects don't exist yet during Create, so room setup waits for the first Step
grid = -1;              // pathfinding grid for enemies

warn_frames = 45;       // red warning ring before an enemy appears
pending = [];           // { x, y, obj, t }
max_alive = 5;
scheduled = false;
cleared = false;

// lighting overlay (created last)
instance_create_depth(0, 0, -15000, obj_lighting);
