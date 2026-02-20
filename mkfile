
all:V: orrboard.stl orrery.pdf pop-stl

POPS=peasant pariah artisan merchant gentry

pop-stl:V: ${POPS:%=pop%.stl}

orr&.stl: orrery.scad
	openscad-nightly -D mything='"'$stem'"' -o $target $prereq

pop&.stl: populace.scad popdimens.scad octagon.scad
	openscad-nightly -D mything='"'$stem'"' -o $target populace.scad

orrery.tex:D: orrery.scad make-labels.lua
	./make-labels.lua -o $target orrery.scad

&.pdf: &.tex
	latex-batch -xe $stem

sun.stl:D: sun.scad
 	openscad-nightly -o $target $prereq

popdimens.scad:D: populace.pdf mkfile
	grep diameter= populace.log | sort -u | lua -e "
	for l in io.lines() do
          local base, rest = assert(l:match('^(%a+): (.*)'))
          for assignment in rest:gmatch '[^, ]+' do
            io.stdout:write(base, '_', assignment, ';', '\\n')
          end
        end" > $target

