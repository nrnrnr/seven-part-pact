// Orrery Game Board for "Seven Part Pact"
// 3D-printable board with concentric planet tracks and sun peg.
// Print each part separately; paste paper overlays for zodiac labels.
//
// Cross-section of tracks and planet arcs is an irregular pentagon:
//   flat top, vertical sides, two angled sides closing downward.
//
// Set render_part in the customizer to choose which piece to export.

include <BOSL2/std.scad>

/* [Render Control] */
// Which part to render for STL export
render_part = "board"; // [board, venus, mercury, mars, jupiter, saturn, sun, assembly]

/* [Board Dimensions] */
board_diameter = 210;  // mm
board_thickness = 8;   // mm

/* [Tolerance - gap per side between planet and track] */
tolerance = 0.2;  // mm; adjust for your printer

/* [Planet Arc Spans (months; 1 month = 30 degrees)] */
venus_span   = 5;
mercury_span = 6;
mars_span    = 2;
jupiter_span = 2;
saturn_span  = 1;

/* [Sun Peg] */
sun_hole_diameter = 5;   // mm
sun_hole_depth   = 5;    // mm
sun_peg_above    = 8;    // mm peg extends above board surface

/* [Layout] */
zodiac_ring_width  = 17; // mm - radial width of outer zodiac ring
center_void_radius = 18; // mm - solid center disc radius
wall_thickness     = 2;  // mm - radial wall between adjacent tracks

/* [Pentagon Cross-Section] */
pent_vertical_height = 3;    // mm - vertical-wall portion of pentagon
pent_angled_height   = 2;    // mm - angled-closing portion of pentagon
pent_bottom_fraction = 0.45; // bottom width as fraction of top width

/* [Resolution] */
circle_fn = 360;

// ---- Derived constants ----

board_radius   = board_diameter / 2;
num_tracks     = 5;
num_months     = 12;
month_angle    = 360 / num_months;  // 30 degrees

zodiac_inner_r   = board_radius - zodiac_ring_width;
track_region     = zodiac_inner_r - center_void_radius;
total_wall_space = (num_tracks + 1) * wall_thickness;
groove_width     = (track_region - total_wall_space) / num_tracks;
groove_depth     = pent_vertical_height + pent_angled_height;

pent_bottom_width = groove_width * pent_bottom_fraction;

// Track center radii (index 0 = outermost = Saturn)
function track_cr(i) =
    zodiac_inner_r - wall_thickness - groove_width / 2
    - i * (groove_width + wall_thickness);

saturn_r  = track_cr(0);
jupiter_r = track_cr(1);
mars_r    = track_cr(2);
mercury_r = track_cr(3);
venus_r   = track_cr(4);

// Sun hole radial position: centered in zodiac ring
sun_hole_r = zodiac_inner_r + zodiac_ring_width / 2;

// ---- Pentagon profiles (2D, for rotate_extrude) ----

// Track groove profile: full-size pentagon at given radius.
// y=0 is the board top surface; groove extends into -y.
module groove_profile_2d(radius) {
    hw  = groove_width / 2;
    hbw = pent_bottom_width / 2;
    vh  = pent_vertical_height;
    ah  = pent_angled_height;
    translate([radius, 0])
        polygon([
            [-hw,  0],
            [ hw,  0],
            [ hw,  -vh],
            [ hbw, -(vh + ah)],
            [-hbw, -(vh + ah)],
            [-hw,  -vh]
        ]);
}

// Planet arc profile: reduced by tolerance so it slides freely.
// Width narrowed by tolerance per side; height shortened by tolerance
// at bottom so the arc doesn't bottom out in the groove.
module planet_profile_2d(radius) {
    t   = tolerance;
    hw  = groove_width / 2 - t;
    hbw = pent_bottom_width / 2 - t;
    vh  = pent_vertical_height;
    ah  = pent_angled_height - t;
    translate([radius, 0])
        polygon([
            [-hw,  0],
            [ hw,  0],
            [ hw,  -vh],
            [ hbw, -(vh + ah)],
            [-hbw, -(vh + ah)],
            [-hw,  -vh]
        ]);
}

// ---- Board ----

module board() {
    difference() {
        // Solid base disc
        cyl(h = board_thickness, r = board_radius,
            anchor = BOTTOM, $fn = circle_fn);

        // Cut pentagon-shaped track grooves from top surface
        translate([0, 0, board_thickness])
            for (i = [0 : num_tracks - 1])
                rotate_extrude($fn = circle_fn)
                    groove_profile_2d(track_cr(i));

        // Sun peg holes: one centered in each month sector
        for (m = [0 : num_months - 1]) {
            angle = m * month_angle + month_angle / 2;
            rotate([0, 0, angle])
                translate([sun_hole_r, 0, board_thickness - sun_hole_depth])
                    cyl(h = sun_hole_depth + 0.1, d = sun_hole_diameter,
                        anchor = BOTTOM, $fn = 32);
        }
    }
}

// ---- Planet arcs ----

// Planet arc: pentagon cross-section swept through an arc.
// Oriented for display (top at z=0, extends downward).
// For printing, the slicer can reorient as needed.
module planet_arc(radius, span_months) {
    arc_angle = span_months * month_angle;
    planet_h = pent_vertical_height + pent_angled_height - tolerance;
    // Place bottom on build plate: translate so bottom is at z=0
    translate([0, 0, planet_h])
        rotate_extrude(angle = arc_angle, $fn = circle_fn)
            planet_profile_2d(radius);
}

// ---- Sun peg ----

// Sun peg: cylinder with a rounded top, fits into the sun holes.
module sun_peg() {
    peg_d = sun_hole_diameter - 2 * tolerance;
    peg_r = peg_d / 2;
    total_h = sun_hole_depth + sun_peg_above;
    union() {
        // Cylindrical shaft
        cyl(h = total_h, d = peg_d, anchor = BOTTOM, $fn = 32);
        // Rounded cap
        translate([0, 0, total_h])
            sphere(r = peg_r, $fn = 32);
    }
}

// ---- Render selected part ----

if (render_part == "board") {
    board();
}
else if (render_part == "venus") {
    planet_arc(venus_r, venus_span);
}
else if (render_part == "mercury") {
    planet_arc(mercury_r, mercury_span);
}
else if (render_part == "mars") {
    planet_arc(mars_r, mars_span);
}
else if (render_part == "jupiter") {
    planet_arc(jupiter_r, jupiter_span);
}
else if (render_part == "saturn") {
    planet_arc(saturn_r, saturn_span);
}
else if (render_part == "sun") {
    sun_peg();
}
else if (render_part == "assembly") {
    // Visualization: board with all planets in arbitrary positions
    color("burlywood") board();
    translate([0, 0, board_thickness]) {
        color("green")       planet_arc(venus_r,   venus_span);
        color("mediumpurple") rotate([0, 0, 60])
                             planet_arc(mercury_r, mercury_span);
        color("crimson")     rotate([0, 0, 150])
                             planet_arc(mars_r,    mars_span);
        color("orange")      rotate([0, 0, 30])
                             planet_arc(jupiter_r, jupiter_span);
        color("slategray")   rotate([0, 0, 210])
                             planet_arc(saturn_r,  saturn_span);
        // Sun peg in one of the holes (month 0)
        color("gold")
            rotate([0, 0, month_angle / 2])
                translate([sun_hole_r, 0, -sun_hole_depth])
                    sun_peg();
    }
}
