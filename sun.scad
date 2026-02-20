



include <BOSL2/std.scad>


// Stylized Sun (2D)
// - center disk diameter = 15mm (default)
// - rays are curvy + tapered using a chain-of-circles hull method

$fn = 96;

// ---- Helpers ----
function lerp(a,b,t) = a + (b-a)*t;

// A single curvy tapered ray pointing along +X from the disk edge.
// Built as a sequence of hull() segments between circles placed on a wavy path.
module curvy_ray_2d(base_r=7.5, ray_len=7.0, base_w=3.0, tip_w=1.2,
                    amp=1.6, phase=0.0, samples=18)
{
    // local: disk center at origin, ray starts at x=base_r and ends at x=base_r+ray_len
    for (i = [0 : samples-1]) {
        t0 = i/(samples-1);
        t1 = (i+1)/(samples-1);

        x0 = base_r + ray_len*t0;
        x1 = base_r + ray_len*t1;

        // Smooth "S" / wavy centerline.  sin(pi*t) keeps endpoints on-axis (y=0).
        y0 = amp * sin(180*t0 + phase) * sin(180*t0);
        y1 = amp * sin(180*t1 + phase) * sin(180*t1);

        // taper width; optional slight bulge near base by raising exponent
        w0 = lerp(base_w, tip_w, pow(t0, 0.9));
        w1 = lerp(base_w, tip_w, pow(t1, 0.9));

        hull() {
            translate([x0, y0]) circle(d=w0);
            translate([x1, y1]) circle(d=w1);
        }
    }
}

// The sun: disk + alternating long/short curvy rays
module stylized_sun_2d(disk_d=15,
                      rays=12,
                      long_len=8.5, short_len=5.8,
                      long_base_w=3.2, short_base_w=2.6,
                      tip_w=1.1,
                      long_amp=1.9, short_amp=1.3,
                      samples=18,
                      ray_twist_deg=0)   // small global twist if desired
{
    base_r = disk_d/2;

    union() {
        // Center disk
        circle(d=disk_d);

        // Rays
        for (k = [0 : rays-1]) {
            ang = 360*k/rays + ray_twist_deg;

            // alternate long/short like many icon suns
            is_long = (k % 2 == 0);

            rotate(ang)
                curvy_ray_2d(
                    base_r   = base_r,
                    ray_len  = is_long ? long_len : short_len,
                    base_w   = is_long ? long_base_w : short_base_w,
                    tip_w    = tip_w,
                    amp      = is_long ? long_amp : short_amp,
                    phase    = is_long ? 0 : 35,   // offset phase to vary silhouette
                    samples  = samples
                );
        }
    }
}

// ---- Example usage (2D) ----
//stylized_sun_2d(
//    disk_d=15,
//    rays=12,
//    long_len=9.0,
//    short_len=6.0,
//    long_base_w=3.4,
//    short_base_w=2.6,
//    tip_w=1.1,
//    long_amp=2.1,
//    short_amp=1.4,
//    samples=20,
//    ray_twist_deg=0
//);

// If you want a quick 3D token:
//linear_extrude(height=1.6) stylized_sun_2d();

sun_hole_diameter = 4;   // mm
board_thickness = 10;  // mm (accommodates deeper grooves + solid base)

sun_thickness = 5;

module sun() {
  linear_extrude(sun_thickness)
    stylized_sun_2d();
  cyl(d=sun_hole_diameter-0.5, h = sun_thickness + 0.8*board_thickness,
      chamfer2 = 1.5, anchor=BOTTOM);
}

sun();


// Knobs you’ll likely tweak
// 
// rays: try 10–14 to match the feel of your reference.
// 
// long_len / short_len: ray lengths.
// 
// long_amp / short_amp: “curliness” (larger = more swoop).
// 
// phase: offsets the wiggle pattern; leaving long at 0 and short at ~30–60° makes them look less uniform.
// 
// base_w / tip_w: chunkiness / taper.
