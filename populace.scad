// gray: peasant
// silver: merchant
// gold: gentry
// red: pariah
// black: artisan

include <BOSL2/std.scad>

include <popdimens.scad>

// include <octagon.scad>

epsilon = 0.001;

slotsize=1.0; // empirical, about the thickeess of a fold
slop=1;
thickness = slotsize + 2; // 1mm on each side of slot

function polar(r, a) = [r*cos(a), r*sin(a)];

function outline(r) =
  [[0,0]
   , polar(r,45)
   , polar(r/cos(22.5),45+22.5)
   , polar(r/cos(22.5),135-22.5)
   , polar(r,135)
   ]      
;

module holder(width, height, diameter, bezel=2) {
  center = [(width+slop)/2+bezel, thickness/2, height/2+bezel];
  radius = diameter/2;

  intersection() {
    difference() {
      cube([width+slop+2*bezel, thickness, height+2*bezel]);
      translate([bezel, (thickness-slotsize)/2, bezel])
        cube([width+slop, slotsize, height+bezel+epsilon]);
      translate([(width+slop)/2 + bezel, thickness/2, height/2+bezel])
        cylinder(d=diameter, h=2*thickness, orient=BACK, anchor=CENTER);

      translate([0,thickness,0])
        translate(center)
        rotate([90,0,0])
        linear_extrude(2*thickness)
        polygon(outline(radius));
    }
    translate([(width+slop)/2+bezel, 0, (width+slop)/2+bezel])
      cube([width+slop+2*bezel, 2*thickness, height+slop+2*bezel], orient=TOP+RIGHT,anchor=CENTER);

  }
}

module peasant () {
  for (i=[1:15]) {
    translate([30 * floor(i/5) ,10 * (i % 5),0])
      holder(peasant_width, peasant_height, peasant_diameter);
  }
}

module pariah () {
  for (i=[1:5]) {
    translate([0,10 * i,0])
      holder(pariah_width, pariah_height, pariah_diameter);
  }
}

module artisan () {
  for (i=[1:3]) {
    translate([0,10 * i,0])
      holder(artisan_width, artisan_height, artisan_diameter);
  }
}

module merchant () {
  for (i=[1:2]) {
    translate([0,10 * i,0])
      holder(merchant_width, merchant_height, merchant_diameter);
  }
}

module gentry () {
  translate([0,i,0])
    holder(gentry_width, gentry_height, gentry_diameter);
}



mything = "merchant";

module render(part = "nothing") {
  if (part == "peasant") {
    peasant();
  } else if (part == "pariah") {
    pariah();
  } else if (part == "artisan") {
    artisan();
  } else if (part == "merchant") {
    merchant();
  } else if (part == "gentry") {
    gentry();
  } 
}

render(mything);


