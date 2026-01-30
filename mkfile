
all:V: board.stl

&.stl: orrery.scad
	openscad-nightly -D mything='"'$stem'"' -o $target $prereq
