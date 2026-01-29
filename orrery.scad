// Orrery Game Board for "Seven Part Pact"
// 3D-printable board with concentric planet tracks and sun peg.
// Print each part separately; paste paper overlays for zodiac labels.
//
// Cross-section of tracks and planet arcs is an irregular pentagon:
//   flat top, vertical sides, two angled sides closing downward.
//
// Set render_part in the customizer to choose which piece to export.

include <BOSL2/std.scad>

epsilon = 0.001;

/* [Board Dimensions] */
board_diameter = 210;  // mm
board_thickness = 10;  // mm (accommodates deeper grooves + solid base)

function scaled(distance) = distance * board_diameter / 194;

/* [Tolerance - gap per side between planet and track] */
tolerance = 0.3;  // mm; adjust for your printer

/* [Planet Arc Spans (months; 1 month = 30 degrees)] */
mercury_span = 3.5;
venus_span   = 2.5;
mars_span    = 1.75;
jupiter_span = 0.75;
saturn_span  = 1/3;

/* [Sun Peg] */
sun_hole_diameter = 4;   // mm
sun_hole_depth   = 2 * board_thickness;    // mm
sun_peg_above    = 8;    // mm peg extends above board surface

/* [Layout] */
zodiac_ring_width  = scaled(23);
                         // mm - radial width of outer zodiac ring
center_void_radius = scaled(15.5); // mm - solid center disc radius
wall_thickness     = 1;  // mm - radial wall between adjacent tracks

/* [Pentagon Cross-Section] */
// Groove depth doubled for deeper tracks; steeper angled sides
pent_vertical_height = 2;    // mm - vertical-wall portion of pentagon
pent_angled_height   = 5;    // mm - angled-closing portion of pentagon
pent_bottom_fraction = 0.40; // bottom width as fraction of top width (steeper sides)

/* [Planet Protrusion] */
// Planet arc top rises this far above the board surface
planet_protrusion = 1.6;  // mm

/* [Incised Lines] */
// V-groove lines marking month boundaries in grooves and on zodiac ring.
// depth controls the size of the 45°-rotated cuboid (and thus V width and depth).
line_depth = 1.2;  // mm - cuboid side length; V cuts to depth/sqrt(2)
small_line_factor = 0.65;

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
venus_r   = track_cr(3);
mercury_r = track_cr(4);
zodiac_r  = zodiac_inner_r + zodiac_ring_width / 2 - wall_thickness/2;

// Sun hole radial position: centered in zodiac ring
sun_hole_r = board_radius - 2 - sun_hole_diameter / 2;

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
// Extends above y=0 (board surface) by planet_protrusion.
module planet_profile_2d(radius) {
    t   = tolerance;
    hw  = groove_width / 2 - t;
    hbw = pent_bottom_width / 2 - t;
    vh  = pent_vertical_height;
    ah  = pent_angled_height - t;
    pp  = planet_protrusion;
    // y=0 is the board surface; planet extends above and below
    translate([radius, 0])
        polygon([
            [-hw,  pp],
            [ hw,  pp],
            [ hw,  -vh],
            [ hbw, -(vh + ah)],
            [-hbw, -(vh + ah)],
            [-hw,  -vh]
        ]);
}

// ---- Incised V-groove lines ----

// Places n V-groove lines evenly around a circle at given radius.
// Lines are radial cuts (along the radius direction).
//   radius:  center radius of the circle of lines
//   length:  radial extent of each line (default: groove_width)
//   depths:  list of depths to cycle through (default: [line_depth])
//   n:       number of lines around the circle (default: 12)
//   offset:  angular offset in degrees (default: 0)
//   surface_z: z coordinate of the surface being incised
//              (default: board top, i.e., board_thickness)
//
// V-shape is a cuboid rotated 45° around its long (radial) axis.
module incised_lines(radius,
                     n = 12,
                     length = pent_bottom_width,
                     depths = [1], 
                     offset = 0,
                     surface_z = board_thickness - groove_depth) {
    angle_step = 360 / n;
    for (i = [0 : n - 1]) {
        d = line_depth * depths[i % len(depths)];  // cycle through depth list
        rotate([0, 0, offset + i * angle_step])
            translate([radius, 0, surface_z])
                // Rotate cuboid 45° around X (radial axis) for V-groove
                rotate([45, 0, 0])
                    cuboid([length, 1.414 * d, 1.414 * d]);
    }
}

// ---- Board ----

module board() {
    difference() {
        // Solid base disc
        cyl(h = board_thickness, r = board_radius,
            anchor = BOTTOM, $fn = circle_fn);

        // niche for moon thing
        translate([0,0,board_thickness + epsilon])
          cyl(h = 2, r = center_void_radius - 1, anchor = TOP, $fn = circle_fn);

        // Cut pentagon-shaped track grooves from top surface
        translate([0, 0, board_thickness + epsilon])
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

        incised_lines(mercury_r, 24, depths=[1,small_line_factor]);
        incised_lines(venus_r,   24, depths=[1,small_line_factor]);
        incised_lines(mars_r,    48, depths=[1,small_line_factor,small_line_factor,small_line_factor]);
        incised_lines(jupiter_r, 48, depths=[1,small_line_factor,small_line_factor,small_line_factor]);
        incised_lines(saturn_r,  36, depths=[small_line_factor], offset=5);
        incised_lines(zodiac_r,  12, depths=[1], surface_z = board_thickness,
                      length = zodiac_ring_width);


//        for (i = [1 : num_tracks - 1])
//            incised_lines(track_cr(i), depths = [line_depth],
//                          surface_z = groove_surface);
//
//        // Mid-month lines in all groove floors (shifted by half a month).
//        // For Saturn (index 0) these are its only lines.
//        for (i = [0 : num_tracks - 1])
//            incised_lines(track_cr(i), depths = [line_depth],
//                          offset = month_angle / 2,
//                          surface_z = groove_surface);
//
//        // Twelve radial divider lines on the zodiac ring surface
//        incised_lines(zodiac_inner_r + zodiac_ring_width / 2,
//                      length = zodiac_ring_width);
    }
}

// ---- Planet arcs ----

// Planet arc: pentagon cross-section swept through an arc.
// Planet protrudes above the board surface by planet_protrusion.
// For standalone rendering, bottom is placed on build plate (z=0).
module planet_arc(radius, span_months, incised_per_year = 24) {
    arc_angle = span_months * month_angle;
    // Total height: protrusion above surface + groove portion below surface
    below_surface = pent_vertical_height + pent_angled_height - tolerance;
    // Place bottom on build plate: translate so bottom is at z=0
    translate([0, 0, below_surface])
        rotate_extrude(angle = arc_angle, $fn = circle_fn)
            planet_profile_2d(radius);

    intersection() {
      incised_lines(radius, n = incised_per_year, depths=[small_line_factor*0.8], surface_z = 0,
                    length = 0.9 * pent_bottom_width);
      rotate_extrude(angle = arc_angle, $fn = circle_fn)
        translate([radius,0])
          polygon([ [10,10], [-10, 10], [-10, -10], [10, -10]]);
    }
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

// ---- Individual planet modules ----

module mercury() { planet_arc(mercury_r, mercury_span, 24); }
module venus()   { planet_arc(venus_r,   venus_span,   24); }
module mars()    { planet_arc(mars_r,    mars_span,    48); }
module jupiter() { planet_arc(jupiter_r, jupiter_span, 48); }
module saturn()  { planet_arc(saturn_r,  saturn_span,  36); }

// ---- Render selected part ----

module render(part = "board") {
  if (part == "board") {
      board();
  }
  else if (part == "venus")   { venus(); }
  else if (part == "mercury") { mercury(); }
  else if (part == "mars")    { mars(); }
  else if (part == "jupiter") { jupiter(); }
  else if (part == "saturn")  { saturn(); }
  else if (part == "sun") {
      sun_peg();
  }
  else if (part == "assembly") {
      // Visualization: board with all planets in arbitrary positions
      color("gray") board();
      // Planets sit in grooves; their z=0 (bottom) aligns with groove bottom
      translate([0, 0, board_thickness - groove_depth]) {
          color("green")        venus();
          color("mediumpurple") rotate([0, 0, 60])  mercury();
          color("crimson")      rotate([0, 0, 150]) mars();
          color("orange")       rotate([0, 0, 30])  jupiter();
          color("slategray")    rotate([0, 0, 215]) saturn();
          // Sun peg in one of the holes (month 0)
          color("gold")
              rotate([0, 0, month_angle / 2])
                  translate([sun_hole_r, 0, groove_depth - sun_hole_depth])
                      sun_peg();
      }
  } else if (part == "slice") {
    intersection() {
      board();
      cuboid(p1=[-200,-10,-1],p2=[200,10,board_thickness+1]);
    }
  }
}

mything = "assembly";

render(mything);
