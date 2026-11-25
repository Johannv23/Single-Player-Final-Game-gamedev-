// Limb game - by Johann Varghese, Owen and team

// ---- tuning (the camera shows 640x352 at 2x, so 1 world pixel = 2 screen pixels) ----
max_speed = 2.5;        // pixels per frame at full speed
accel     = 0.4;        // how fast we speed up (~6 frames to full speed)
fric      = 0.35;       // how fast we slow down with no input

// ---- state ----
hsp = 0;                // horizontal speed
vsp = 0;                // vertical speed
x_rem = 0;              // sub-pixel remainders carried by move_collide()
y_rem = 0;
facing = 6;             // 0-7, one step per 45 degrees: 0 right, 2 up, 4 left, 6 down

max_hp = 100;
hp = max_hp;
invuln = 0;             // frames of grace after a hit
hurt_flash = 0;

// the 32x32 box is the collision mask and the art
mask_index = spr_box;

//limb prototype (no body visuals yet)
limbs_init(self);
