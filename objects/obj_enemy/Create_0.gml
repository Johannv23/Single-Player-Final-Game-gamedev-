// Limb game - by Johann Varghese, Owen and team

// Base enemy. Movement is the sword game's: chase the player along an mp_grid path so enemies
// don't get stuck behind walls. Children (fire / water) only change element and colour.
move_speed = 1.0;
max_hp = 30;
hp = max_hp;
dead = false;
element = "none";                   // "fire" or "water": obj_lighting gives each its own glow
col = c_white;                      // body colour (the sprite is white and tinted)
hit_flash = 0;
touch_damage = 10;

mask_index = spr_enemy_box;

// path following (grid is built by obj_game on its first frame)
mypath = path_add();
path_ok = false;
path_i = 1;
path_t = irandom(20);

function take_damage(_d) {
    hp -= _d;
    hit_flash = 6;
    if (hp <= 0) instance_destroy();
}
