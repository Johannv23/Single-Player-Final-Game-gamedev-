//FOR PROTOTYPE - subject to change
//(remove / replace, inventory, etc.)
//limbs_on = has all four limbs, no visuals for player yet
function limbs_init(p) {
    p.limbs_on = false;
    p.base_max_speed = p.max_speed;

    p.tentacle_cd = 0;
	p.tentacle_active = 0;
	p.tentacle_aim = 0;
	p.tentacle_swing_max = 20;//how fast tentacle swings
	p.tentacle_draw = 0;

    p.wizard_cd = 0;
    p.spring_timer = 0;
    p.spring_dir = 0;
    p.hedgehog_mult = 1.35;

    // filled each Step for Draw (sync with hit)
    p.tentacle_draw = 0;
}

function limbs_prototype_grant(p) {
    p.limbs_on = true;
    p.max_speed = p.base_max_speed * p.hedgehog_mult;
    // if you use GUI icons:
    p.limb_arm_l = true;
    p.limb_arm_r = true;
    p.limb_leg_l = true;
    p.limb_leg_r = true;
}

//mouse aim in room space
function limbs_aim_dir(p){
	return point_direction(p.x,p.y,mouse_x,mouse_y);
}

//main call for limb actives
function limbs_step(p) {
    if (!p.limbs_on) return;

    p.tentacle_draw = p.tentacle_active;

    if (p.tentacle_cd > 0) p.tentacle_cd -= 1;

    if (p.tentacle_active > 0) {
        limbs_tentacle_swing(p, false, p.tentacle_active);
        p.tentacle_active -= 1;
    }

    if (p.wizard_cd > 0) p.wizard_cd -= 1;

    if (keyboard_check_pressed(ord("Q")) && p.tentacle_cd <= 0 && p.tentacle_active <= 0) {
        p.tentacle_aim = limbs_aim_dir(p);
        p.tentacle_active = p.tentacle_swing_max;
        p.tentacle_cd = 20;
        p.tentacle_draw = p.tentacle_active;
    }

    if (keyboard_check_pressed(ord("E")) && p.wizard_cd <= 0) {
        p.wizard_cd = 14;
        var dir = limbs_aim_dir(p);
        var ox = 14;
        var proj = instance_create_depth(
            p.x + lengthdir_x(ox, dir),
            p.y + lengthdir_y(ox, dir),
            p.depth - 2,
            obj_proj_wizard
        );
        proj.direction = dir;
        proj.speed = 5;
        proj.damage = 14;
    }

    if (keyboard_check_pressed(ord("Z")) && p.spring_timer <= 0) {
        limbs_spring_start(p);
    }
}
//call at start of lpayer step,
function limbs_spring_step(p){
	if(p.spring_timer <=0) return false;
	
	p.invuln = max(p.invuln, p.spring_timer);
	var sp = 5;
	var dx = lengthdir_x(sp, p.spring_dir);
	var dy = lengthdir_y(sp, p.spring_dir);
	
	//tiny arc feel, extra vertical nudge from SINE for small animated leap
	var arc = sin((p.spring_total - p.spring_timer) / p.spring_total * pi) * 2;
	dx += lengthdir_x(arc, p.spring_dir - 90);
	dy += lengthdir_y(arc, p.spring_dir - 90);
	
	if(!place_meeting(p.x + dx, p.y, obj_wall)) p.x += dx;
	if(!place_meeting(p.x, p.y + dy, obj_wall)) p.y += dy;
	
	p.spring_timer -= 1;
	return true;
}

function limbs_spring_start(p) {
    var ix = keyboard_check(ord("D")) - keyboard_check(ord("A"));
    var iy = keyboard_check(ord("S")) - keyboard_check(ord("W"));
    var dir = p.facing * 45;
    if (ix != 0 || iy != 0) {
        dir = point_direction(0, 0, ix, iy);
    }
    p.spring_dir = dir;
    p.spring_total = 22;
    p.spring_timer = p.spring_total;
    p.hsp = 0;
    p.vsp = 0;
}

//draw sprite
function limbs_tentacle_swing(p, do_draw, frames_left) {
    if (!p.limbs_on || frames_left <= 0) return;
    var prog = 1 - frames_left / p.tentacle_swing_max;
    var swing_ang = p.tentacle_aim - prog * 180; 

    var ax = p.x;
    var ay = p.y;

    var sc = 1.25;
    var reach = 50 * sc;
    var hit_rad = 26 * sc;

    var draw_ang = swing_ang + 90;

    if (do_draw) {
        draw_sprite_ext(spr_arm_tentacle, 0, ax, ay, sc, sc, draw_ang, c_white, 1);
        return;
    }

    var hx = ax + lengthdir_x(reach, swing_ang);
    var hy = ay + lengthdir_y(reach, swing_ang);
    with (obj_enemy) {
        if (point_distance(x, y, hx, hy) < hit_rad) take_damage(16);
    }
}

function limbs_draw_help() {
    var gh = display_get_gui_height();
    var pad = 16;
    var line_h = 18;
    draw_set_halign(fa_left);
    draw_set_valign(fa_bottom);
    draw_set_color(c_white);
    draw_text(pad, gh - pad, "PROTOTYPE: P = get all limbs");
    draw_text(pad, gh - pad - line_h, "Q tentacle  E wizard  Z spring  hedgehog = faster walk");
    if (limbs_on) {
        draw_set_color(make_color_rgb(140, 255, 140));
        draw_text(pad, gh - pad - line_h * 2, "Limbs equipped");
    }
    draw_set_valign(fa_top); // reset if other GUI draw expects default
}



	