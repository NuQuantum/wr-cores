
# make -f Makefile > /dev/null 2>&1
vsim -L unisim work.main -novopt 

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do wave.do
run 10us
wave zoomfull
radix -hex

