// WTF people

// low tray uses 36g of filament

include <BOSL2/std.scad>

$fa = 2;    // minimum angle (fine resolution)
$fs = 0.4;  // minimum size (fine resolution)

epsilon = 0.001;
layer_height = 0.2;

inch = 25.4;

function bigger(d) = [d.x+2*epsilon, d.y+2*epsilon, d.z+2*epsilon];

function polar(r, a) = [r*cos(a), r*sin(a)];

module ngon(n, radius, apothem) {
  angle = 360 / (2 * n);
  r = radius != undef ? radius : apothem / cos(angle);
  polygon([for (i = [angle:2*angle:360]) polar(r, i)]);
}


wall = 1.6;
floor = 1.6;

dieside = 15.6;
dieroom = 0.6;
diewellside = dieside + dieroom;
diewelldepth = 0.3 * diewellside;
diceblock = [2*wall+dieroom+dieside, 3*wall+2*(dieroom+dieside), floor+diewelldepth];

dicetheta = 15;



octagon = [25.5, 4, 25.5];
row_count = 5;
row_sep = 2;

display = [5 * octagon.x + 4 * row_sep, octagon.y, 17]; // excludes walls
tray = [display.x, max(28,(diceblock.y-2*wall)*cos(dicetheta)), 7];

theta = 65;

front_display_z = floor + tray.z + (diceblock.y-wall)*sin(dicetheta);

text_thickness = wall/2;

front = wall;

block = [display.x + 2*wall,
         front + tray.y + 2 * (display.y * sin(theta) + display.z * cos(theta)) + wall,
         front_display_z + 2 * (display.z * sin(theta))
         ];

lip = [display.x, 1, 4];



module die() {
  side = dieside;
  cube([side,side,side]);
}

module negadie() {
  side = dieside + dieroom;
  cube([side,side,side]);
}

module simpledice() {
  difference() {
    cube(diceblock);
    translate([wall, wall, floor]) {
      negadie();
      translate([0, diewellside+wall, 0])
        negadie();
    }
  }
}

module dice() {
  base = [diceblock.x, diceblock.y * cos(dicetheta), 100];
  difference() {
    cube([diceblock.x, diceblock.y * cos(dicetheta), 100]);
    translate([-epsilon,-epsilon,tray.z+floor-wall *sin(dicetheta)])
      rotate([dicetheta,0,0])
      cube(bigger([diceblock.x, 100, 100]));
    translate([wall,wall + diewelldepth*sin(dicetheta),diceblock.z-0.3*dieside])
      rotate([dicetheta,0,0]) {
      negadie();
      translate([0,diewellside+wall,0])
        negadie();
    }
  }
}

module letter(s) {
  translate([0,text_thickness,0.15*tray.z])
  rotate([90,0,0])
  linear_extrude(text_thickness)
    text(s, size = 0.8 * tray.z, font="Arial Bold", halign="center");
}




module octowell() {
  apothem = octagon.x / 2;
  translate([0,0,apothem]) {
    rotate([90,0,0])
      linear_extrude(octagon.y)
      ngon(8, apothem = apothem);
    cube([2 * apothem, octagon.y, 5 * apothem], anchor = BOTTOM+BACK);
  }
}

module octowells() {
  for (i=[octagon.x/2:row_sep + octagon.x:block.x])
    translate([i, display.y, 0])
    octowell();
}

module negdisplay() {
  thick = 2 * block.y;
  rotate([theta-90, 0, 0]) {
    translate([0,-thick,0]) 
      cube([display.x, thick, block.z]);
    translate([0,-epsilon,0])
    octowells();
  }      
}

card_thickness = 0.6;
card_bezel = 4;

module label_rack() {
  fd_z = front_display_z;
  difference() {
    cube([2*wall + 3*inch, wall, fd_z - floor], anchor=BOTTOM+BACK);
    translate([0,epsilon,0])
    cube([3*inch, card_thickness + 2 *epsilon, 2 * fd_z], anchor=BOTTOM+BACK);
    translate([0,-epsilon,0])
    cube(bigger([3*inch-2*card_bezel, wall, 2 * fd_z]), anchor=BOTTOM+BACK);
  }
}

  

display_vector = // from front of one display to front of next
  [0,display.z * cos(theta) + display.y * sin(theta), display.z * sin(theta)];

module main() {
  fd_y = front + tray.y; // + display.y * sin(theta);
  fd_z = front_display_z;
  difference() {
    union() {
      difference() {
        cube(block, center=false);
        translate([wall, front, floor]) // tray well
          cube(tray, center=false);
        translate([-epsilon,-epsilon,floor+tray.z-epsilon]) // shorten walls
                                                            // around well
          cube([block.x + 2 * epsilon, tray.y + front + epsilon, block.z]);
        translate([wall, fd_y, fd_z]) { // wells for display
          negdisplay();
          translate(display_vector)
            negdisplay();
       }
       translate([0, fd_y, fd_z]) // slant side walls of displays
         rotate([theta-90,0,0])
         translate([-epsilon,-fd_y,-epsilon])
         cube([block.x + 2 * epsilon, fd_y, block.z]);
      }
      translate([wall-epsilon, fd_y, fd_z]) { // lips
        rotate([theta-90, 0, 0])
        cube(bigger(lip), anchor=LEFT+FRONT+BOTTOM);
        translate(display_vector)
          rotate([theta-90, 0, 0])
          cube(bigger(lip), anchor=LEFT+FRONT+BOTTOM);
      }
      dice();
      translate([block.x - diceblock.x, 0, 0])
        dice();
    }
    translate([wall+diewellside/2,-epsilon,0])
      letter("W");
    translate([block.x-(wall+diewellside/2),-epsilon,0])
      letter("B");
    translate([block.x/2, tray.y-epsilon, fd_z]) {
      cylinder(d=17,h=wall/cos(theta)+1,orient=BACK);
      cube([17,wall/cos(theta)+1,17],anchor=BOTTOM+FRONT);
    }      
  }
  translate([block.x/2, front+tray.y, floor])
    label_rack();
}



main();


//translate([0,0,50]) negdisplay();



//negdisplay();



