
all:V: board.stl orrery.pdf

&.stl: orrery.scad
	openscad-nightly -D mything='"'$stem'"' -o $target $prereq

orrery.tex:D: orrery.scad make-labels.lua
	./make-labels.lua -o $target orrery.scad

&.pdf: &.tex
	latex-batch -xe $stem
